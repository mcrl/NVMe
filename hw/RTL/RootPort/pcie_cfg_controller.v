
(* DowngradeIPIdentifiedWarnings = "yes" *)
module pcie_cfg_controller #(
    // Configurator Parameters
    parameter ROM_FILE             = "pcie_cfg_rom.data",   // Location of configuration rom data file
    parameter ROM_SIZE             = 26,                    // Number of entries in configuration rom
    parameter ROM_ADDR_WIDTH      = (ROM_SIZE-1 < 2  )  ? 1 :
                                    (ROM_SIZE-1 < 4  )  ? 2 :
                                    (ROM_SIZE-1 < 8  )  ? 3 :
                                    (ROM_SIZE-1 < 16 )  ? 4 :
                                    (ROM_SIZE-1 < 32 )  ? 5 :
                                                          6
  )
  (
    input wire          user_clk,
    input wire          reset,
    input wire          start_config,
    output reg          finished_config,
    output reg          failed_config,

    // Packet Generator interface
    output reg [1:0]    pkt_type, 
    output reg [1:0]    pkt_func_num,
    output reg [9:0]    pkt_reg_num,
    output reg [3:0]    pkt_1dw_be,
    output reg [2:0]    pkt_msg_routing,
    output reg [7:0]    pkt_msg_code,
    output reg [31:0]   pkt_data,
    output reg          pkt_start,
    input wire          pkt_done,

    // Tx Mux and Completion Decoder interface
    output reg          config_mode,
    input wire          config_mode_active,
    input wire          cpl_sc,
    input wire          cpl_ur,
    input wire          cpl_crs,
    input wire          cpl_ca,
    input wire [31:0]   cpl_data,
    input wire          cpl_mismatch,

    output reg [2:0]                ctl_state,
    output reg [ROM_ADDR_WIDTH-1:0] ctl_addr,
    output reg [31:0]               ctl_data,
    output reg                      ctl_last_cfg,
    output reg                      ctl_skip_cpl
  );

  // pkt_type
  localparam [1:0] TYPE_CFGRD = 2'b00;
  localparam [1:0] TYPE_CFGWR = 2'b01;
  localparam [1:0] TYPE_MSG   = 2'b10;
  localparam [1:0] TYPE_MSGD  = 2'b11;

  // State encodings
  localparam [2:0] ST_IDLE     = 3'd0;
  localparam [2:0] ST_WAIT_CFG = 3'd1;
  localparam [2:0] ST_READ1    = 3'd2;
  localparam [2:0] ST_READ2    = 3'd3;
  localparam [2:0] ST_WAIT_PKT = 3'd4;
  localparam [2:0] ST_WAIT_CPL = 3'd5;
  localparam [2:0] ST_DONE     = 3'd6;

  // Bit-slicing constants for ROM output data
  localparam       PKT_TYPE_HI        = 17;
  localparam       PKT_TYPE_LO        = 16;
  localparam       PKT_FUNC_NUM_HI    = 15;
  localparam       PKT_FUNC_NUM_LO    = 14;
  localparam       PKT_REG_NUM_HI     = 13;
  localparam       PKT_REG_NUM_LO     = 4;
  localparam       PKT_1DW_BE_HI      = 3;
  localparam       PKT_1DW_BE_LO      = 0;
  localparam       PKT_MSG_ROUTING_HI = 10; // Overlaps with REG_NUM/1DW_BE
  localparam       PKT_MSG_ROUTING_LO = 8;  // Overlaps with REG_NUM/1DW_BE
  localparam       PKT_MSG_CODE_HI    = 7;  // Overlaps with REG_NUM/1DW_BE
  localparam       PKT_MSG_CODE_LO    = 0;  // Overlaps with REG_NUM/1DW_BE
  localparam       PKT_DATA_HI        = 31;
  localparam       PKT_DATA_LO        = 0;


  reg [31:0]               ctl_rom [0:ROM_SIZE-1];


  // Determine when the last ROM address is being read
  always @(posedge user_clk) begin
    if (reset) begin
      ctl_last_cfg    <= 1'b0;
    end else begin
      if (ctl_addr == (ROM_SIZE-1)) begin
        ctl_last_cfg  <= 1'b1;
      end else if (start_config) begin
        ctl_last_cfg  <= 1'b0;
      end
    end
  end

  // Determine whether or not to expect a completion from the current TLP
  // ctl_skip_cpt == 1 : Don't wait for a completion for a message TLP
  // cpl_skip_cpt == 0 : All other TLP types get completions
  always @(posedge user_clk) begin
    if (reset) begin
      ctl_skip_cpl    <= 1'b0;
    end 
    else begin
      if (pkt_start) begin
        if (pkt_type == TYPE_MSG || pkt_type == TYPE_MSGD) begin
          ctl_skip_cpl  <= 1'b1;
        end else begin
          ctl_skip_cpl  <= 1'b0;
        end
      end
    end
  end


  // Controller state-machine
  // ST_IDLE : Waiting for user to request configuration to begin
  // ST_WAIT_CFG : Waiting for Tx Mux to indicate no active user packets
  // ST_READ1 : Capture TLP header information from ROM
  // ST_READ2 : Capture TLP data from ROM
  // ST_WAIT_PKT : Wait for TLP to be transmitted
  // ST_WAIT_CPL : Wait for completion to be received (if necessary)
  // ST_DONE : Configuration has commpleted
  
  always@(posedge user_clk) begin
    if(reset) begin
      ctl_state       <= ST_IDLE;
    end
    else begin
      case (ctl_state)
        ST_IDLE: begin
          if (start_config) begin
            ctl_state      <= ST_WAIT_CFG;
          end
        end // ST_IDLE

        ST_WAIT_CFG: begin
          if (config_mode_active) begin
            ctl_state        <= ST_READ1;
          end
        end // ST_WAIT_CFG

        ST_READ1: begin
          ctl_state        <= ST_READ2;
        end // ST_READ1

        ST_READ2: begin
          ctl_state        <= ST_WAIT_PKT;
        end // ST_READ2

        ST_WAIT_PKT: begin
          if (pkt_done) begin
            ctl_state      <= ST_WAIT_CPL;
          end
        end // ST_WAIT_PKT

        ST_WAIT_CPL: begin
          if (cpl_sc || ctl_skip_cpl) begin
            if (ctl_last_cfg) begin
              ctl_state       <= ST_DONE;
            end else begin
              ctl_state       <= ST_READ1;
            end
          end 
          
          else if (cpl_crs) begin
            ctl_state         <= ST_WAIT_PKT;
          end 
          
          else if (cpl_ur || cpl_ca || cpl_mismatch) begin
            ctl_state         <= ST_DONE;
          end
        end // ST_WAIT_CPL

        ST_DONE: begin
          if (start_config) begin
            ctl_state         <= ST_WAIT_CFG;
          end 
        end // ST_DONE
      endcase
    end
  end



  // Datapath
  always @(posedge user_clk) begin
    if (reset) begin
      config_mode     <= 1'b1;
      finished_config <= 1'b0;
      failed_config   <= 1'b0;
      pkt_start       <= 1'b0;
      pkt_type        <= 2'd0;
      pkt_func_num    <= 2'd0;
      pkt_reg_num     <= 10'd0;
      pkt_1dw_be      <= 4'd0;
      pkt_msg_routing <= 3'd0;
      pkt_msg_code    <= 8'd0;
      pkt_data        <= 32'd0;

      ctl_addr        <= {ROM_ADDR_WIDTH{1'b0}};
    end else begin
      case (ctl_state)
        ST_IDLE: begin
          // Don't allow user packets until config completes
          config_mode      <= 1'b1;
          finished_config  <= 1'b0;
          failed_config    <= 1'b0;
          pkt_start        <= 1'b0;
        end // ST_IDLE

        ST_WAIT_CFG: begin
          // Start reading from ROM
          if (config_mode_active) begin
            ctl_addr         <= ctl_addr + 1'b1;
          end
        end // ST_WAIT_CFG

        ST_READ1: begin
          pkt_type         <= ctl_data[PKT_TYPE_HI:PKT_TYPE_LO];
          pkt_func_num     <= ctl_data[PKT_FUNC_NUM_HI:PKT_FUNC_NUM_LO];
          pkt_reg_num      <= ctl_data[PKT_REG_NUM_HI:PKT_REG_NUM_LO];
          pkt_1dw_be       <= ctl_data[PKT_1DW_BE_HI:PKT_1DW_BE_LO];
          pkt_msg_routing  <= ctl_data[PKT_MSG_ROUTING_HI:PKT_MSG_ROUTING_LO];
          pkt_msg_code     <= ctl_data[PKT_MSG_CODE_HI:PKT_MSG_CODE_LO];

          ctl_addr         <= ctl_addr + 1'b1;
        end // ST_READ1

        ST_READ2: begin
          pkt_data         <= ctl_data[PKT_DATA_HI:PKT_DATA_LO];
          pkt_start        <= 1'b1; // start TLP transmission
        end // ST_READ2

        ST_WAIT_PKT: begin
          pkt_start        <= 1'b0;
        end // ST_WAIT_PKT

        ST_WAIT_CPL: begin

          // If a Completion with Successful Completion status is received, or if a completion isn't expected
          if (cpl_sc || ctl_skip_cpl) begin

            // If this is the last step of configuration, configuration was completed successfully - go to DONE state with good status
            if (ctl_last_cfg) begin
              finished_config <= 1'b1;
            end 

            // Otherwise, begin the next TLP
            else begin
              ctl_addr        <= ctl_addr + 1'b1;
            end
          end 

          // If a Completion with Configuration Retry status is received, retransmit the current TLP
          else if (cpl_crs) begin
            pkt_start         <= 1'b1;
          end 
          
          // If a Completion with Unsupported Request or Completer Abort
          // status is received, or the Requester ID doesn't match,
          // configuration failed - go to DONE state with bad status
          else if (cpl_ur || cpl_ca || cpl_mismatch) begin
            finished_config   <= 1'b1;
            failed_config     <= 1'b1;
          end
        end // ST_WAIT_CPL

        ST_DONE: begin
          ctl_addr            <= {ROM_ADDR_WIDTH{1'b0}};

          if (start_config) begin
            config_mode       <= 1'b1;
            finished_config   <= 1'b0;
            failed_config     <= 1'b0;
          end 
          else begin
            config_mode       <= 1'b0;
          end
        end // ST_DONE
      endcase
    end
  end


  // ROM data
  always @(posedge user_clk) begin  // No reset for a ROM
    ctl_data <= ctl_rom[ctl_addr];
  end
  initial begin
    $readmemb(ROM_FILE, ctl_rom, 0, ROM_SIZE-1);
  end




endmodule // cgator_controller

