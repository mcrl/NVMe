
(* DowngradeIPIdentifiedWarnings = "yes" *)
module user_controller
  #(
    parameter           TCQ = 1,  // for simulation

    // BAR A settings
    parameter           BAR_A_ENABLED = 1,
    parameter           BAR_A_64BIT = 0,
    parameter           BAR_A_IO = 0,
    parameter [31:0]    BAR_A_BASE = 32'h1000_0000, // Base Address 
    parameter           BAR_A_SIZE = 1024           // Size in DW
  )
  (
    input wire          user_clk,
    input wire          reset,
    input wire          user_lnk_up,

    // Control configuration process
    output reg          start_config,
    input wire          finished_config,
    input wire          failed_config,

    // Packet generator interface
    output reg [2:0]    tx_type,  
    output reg [7:0]    tx_tag,
    output reg [63:0]   tx_addr,
    output reg [31:0]   tx_data,
    output reg          tx_start,
    input wire          tx_done,

    // Checker interface
    output reg          rx_type, 
    output wire [7:0]   rx_tag,
    output reg [31:0]   rx_data,
    input wire          rx_success,
    input wire          rx_fail,

    // for Debugging
    input wire [11:0]   addr_offset
  );

  // TLP type encoding for tx_type
  localparam [2:0] TX_TYPE_MEMRD32 = 3'b000;
  localparam [2:0] TX_TYPE_MEMWR32 = 3'b001;
  localparam [2:0] TX_TYPE_MEMRD64 = 3'b010;
  localparam [2:0] TX_TYPE_MEMWR64 = 3'b011;

  // TLP type encoding for rx_type 
  localparam       RX_TYPE_CPL     = 1'b0;  // without Data
  localparam       RX_TYPE_CPLD    = 1'b1;  // with Data

  // States
  localparam [3:0] ST_WAIT_CFG      = 4'd0;
  localparam [3:0] ST_WRITE         = 4'd1;
  localparam [3:0] ST_WRITE_WAIT    = 4'd2;
  localparam [3:0] ST_READ          = 4'd3;
  localparam [3:0] ST_READ_WAIT     = 4'd4;
  localparam [3:0] ST_READ_CPL_WAIT = 4'd5;
  localparam [3:0] ST_DONE          = 4'd6;
  localparam [3:0] ST_ERROR         = 4'd7;
  localparam [3:0] ST_TESTDONE      = 4'd8;

  reg [3:0]    ctl_state;


  // Start Configurator after link comes up
  reg          user_lnk_up_q;
  reg          user_lnk_up_q2;

  always @(posedge user_clk) begin
    if (reset) begin
      user_lnk_up_q  <= 1'b0;
      user_lnk_up_q2 <= 1'b0;
      start_config   <= 1'b0;
    end 
    else begin
      user_lnk_up_q  <= user_lnk_up;
      user_lnk_up_q2 <= user_lnk_up_q;
      start_config   <= (!user_lnk_up_q2 && user_lnk_up_q);
    end
  end

  // Regs for addr test (debug)
  reg        test_done;
  reg [11:0] test_count;
  reg [11:0] err_count;

  always @(posedge user_clk) begin
    if(reset || !user_lnk_up) begin
      test_done   <= 1'b0;
      test_count  <= 12'h0;
      err_count   <= 12'h0;
    end
    else begin
      case(ctl_state)        
        ST_DONE, ST_ERROR: begin
          if(test_count == 12'hfff) begin
            test_done <= 1'b1;
          end
          else begin
            test_count  <= test_count + 12'd1;
            test_done   <= 1'b0;
          end
          if(ctl_state == ST_ERROR) begin 
            err_count <= err_count + 12'd1;
          end
        end
      endcase
    end
  end


  // Controller state-machine
  // ST_WAIT_CFG      : Wait for Configurator to finish configuring the Endpoint
  // ST_WRITE         : Transmit write TLP to Endpoint 
  // ST_WRITE_WAIT    : Wait for write TLP to be transmitted
  // ST_READ          : Send a read TLP to Endpoint 
  // ST_READ_WAIT     : Wait for read TLP to be transmitted
  // ST_READ_CPL_WAIT : Wait for completion to be returned
  // ST_DONE          : Test passed successfully. Wait for restart to be requested
  // ST_ERROR         : Test failed. Wait for restart to be requested

  always @(posedge user_clk) begin
    if (reset || !user_lnk_up) begin
      ctl_state       <= ST_WAIT_CFG; // Link going down causes PIO master state machine to restart
    end 
    else begin
      case (ctl_state)

        ST_WAIT_CFG: begin
          if (failed_config) begin
            ctl_state      <= ST_ERROR;
          end 
          else if (finished_config) begin
            ctl_state      <= ST_WRITE;
          end
        end // ST_WAIT_CFG

        ST_WRITE: begin
          ctl_state        <= ST_WRITE_WAIT;
        end // ST_WRITE

        ST_WRITE_WAIT: begin
          if (tx_done) begin
            ctl_state    <= ST_READ;
          end
        end // ST_WRITE_WAIT

        ST_READ: begin
          ctl_state        <= ST_READ_WAIT;
        end // ST_READ

        ST_READ_WAIT: begin
          if (tx_done) begin
            ctl_state      <= ST_READ_CPL_WAIT;
          end
        end // ST_WRITE_WAIT

        ST_READ_CPL_WAIT: begin
          // If there was something wrong with the completion, finish with an error condition
          if (rx_fail) begin
            ctl_state      <= ST_ERROR;
          end 

          // If completion was good and targeted aperture was the last one enabled, finish with a success condition
          else if (rx_success) begin
              ctl_state    <= ST_DONE;
          end
        end // ST_READ_CPL_WAIT

        ST_DONE: begin
          // Unless all tests for address are done, go to ST_WRITE
          if(!test_done) ctl_state <= ST_WRITE;
          else ctl_state <= ST_TESTDONE;
        end // ST_DONE

        ST_ERROR: begin
          // Unless all tests for address are done, go to ST_WRITE
          if(!test_done) ctl_state <= ST_WRITE;
          else ctl_state <= ST_TESTDONE;
        end // ST_ERROR

        ST_TESTDONE: begin
          // TODO : do nothing cuz tests are done
        end
      endcase
    end
  end




  // Generate outputs to packet generator and checker
  always @(posedge user_clk) begin
    if (reset) begin
      tx_type          <= 3'b000;
      tx_addr          <= 64'd0;
      tx_data          <= 32'd0;
      tx_tag           <= 8'd0;
      tx_start         <= 1'b0;
      rx_type          <= 1'b0;
      rx_data          <= 32'd0;
    end 
    else begin
      // New control information is latched out only in these two states
      if (ctl_state == ST_WRITE || ctl_state == ST_READ) begin
        tx_type    <= (ctl_state == ST_WRITE) ? TX_TYPE_MEMWR32 : TX_TYPE_MEMRD32;
        tx_data    <= 32'h1234_5678;
        tx_addr    <= BAR_A_BASE + {18'h0, test_count, 2'b00};
        rx_type    <= (ctl_state == ST_READ) ? RX_TYPE_CPLD : RX_TYPE_CPL;
        rx_data    <= 32'h1234_5678;
        tx_tag     <= tx_tag + 1'b1;  // Tag is incremented for each TLP sent
        tx_start   <= 1'b1; 
      end
      else begin
        tx_start   <= 1'b0; 
      end
    end
  end

  // tx_tag and rx_tag are always the same
  assign rx_tag = tx_tag;



endmodule 