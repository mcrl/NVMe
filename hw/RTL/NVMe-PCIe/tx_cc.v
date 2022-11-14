// Completer completion module

module tx_cc #(
  parameter        AXI4_CC_TUSER_WIDTH            = 33,
  parameter        C_DATA_WIDTH                   = 128,            
  parameter KEEP_WIDTH                            = C_DATA_WIDTH / 32
) (
  // System Interface
  input wire                user_clk,
  input wire                user_reset,
  input wire                user_lnk_up,

  // PCIe IP Interface
  output reg                    [C_DATA_WIDTH-1:0]     s_axis_cc_tdata,
  output reg             [AXI4_CC_TUSER_WIDTH-1:0]     s_axis_cc_tuser,
  output reg                                           s_axis_cc_tlast,
  output reg                      [KEEP_WIDTH-1:0]     s_axis_cc_tkeep,
  output reg                                           s_axis_cc_tvalid,
  input wire                                [3:0]     s_axis_cc_tready,

  // Controller Interface
  input send_cmd,
  output reg send_cmd_done
);


  localparam [63:0] BAR0 = 64'h0000_0010_8000_0000;

  localparam [15:0] REQUESTER_ID = 16'h4508;
  localparam [15:0] COMPLETER_ID = 16'h0000;

  localparam [3:0] ST_IDLE        = 4'd0;  
  localparam [3:0] ST_CMD_DES     = 4'd1;
  localparam [3:0] ST_CMD_DW1_4   = 4'd2;
  localparam [3:0] ST_CMD_DW5_8   = 4'd3;
  localparam [3:0] ST_CMD_DW9_12  = 4'd4;
  localparam [3:0] ST_CMD_DW13_15 = 4'd5;
  localparam [3:0] ST_CMD_DONE    = 4'd6;

  reg [3:0] cc_state;


  reg                   [C_DATA_WIDTH-1:0]     s_axis_cc_tdata_d;
  reg                     [KEEP_WIDTH-1:0]     s_axis_cc_tkeep_d;
  reg            [AXI4_CC_TUSER_WIDTH-1:0]     s_axis_cc_tuser_d;
  reg                                          s_axis_cc_tlast_d;
  reg                                          s_axis_cc_tvalid_d;


  // State Machine
  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      cc_state <= ST_IDLE;
      send_cmd_done <= 1'b0;
    end
    else begin
      if(s_axis_cc_tready) begin
        case(cc_state)
          ST_IDLE: begin
            send_cmd_done <= 1'b0;
            if(send_cmd) cc_state <= ST_CMD_DES;
          end

          ST_CMD_DES: begin
            cc_state <= ST_CMD_DW1_4;
          end

          ST_CMD_DW1_4: begin
            cc_state <= ST_CMD_DW5_8;
          end

          ST_CMD_DW5_8: begin
            cc_state <= ST_CMD_DW9_12;
          end

          ST_CMD_DW9_12: begin
            cc_state <= ST_CMD_DW13_15;
          end

          ST_CMD_DW13_15: begin
            cc_state <= ST_CMD_DONE;
          end

          ST_CMD_DONE: begin
            cc_state <= ST_IDLE;
            send_cmd_done <= 1'b1;
          end
        endcase
      end // if s_axis_cc_tready
    end
  end



  //-------------------------------------------------------
  // Completer Completion Encoder
  //-------------------------------------------------------

  // Pipelined
  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      s_axis_cc_tdata <= 'd0;
      s_axis_cc_tkeep <= 'd0;
      s_axis_cc_tuser <= 'd0;
      s_axis_cc_tlast <= 'd0;
      s_axis_cc_tvalid <= 'd0;
    end
    else begin
      s_axis_cc_tdata <= s_axis_cc_tdata_d;
      s_axis_cc_tkeep <= s_axis_cc_tkeep_d;
      s_axis_cc_tuser <= s_axis_cc_tuser_d;
      s_axis_cc_tlast <= s_axis_cc_tlast_d;
      s_axis_cc_tvalid <= s_axis_cc_tvalid_d;
    end
  end



  always@(*) begin
    if(user_reset || !user_lnk_up) begin
      s_axis_cc_tdata_d = {C_DATA_WIDTH{1'b0}};
      s_axis_cc_tvalid_d = 1'b0;
      s_axis_cc_tkeep_d = 4'b0000;
      s_axis_cc_tlast_d = 1'b0;
      s_axis_cc_tuser_d = {AXI4_CC_TUSER_WIDTH{1'b0}};
    end
    else begin
      case(cc_state)

        ST_CMD_DES: begin
          if(s_axis_cc_tready) begin
            s_axis_cc_tdata_d = {
                                // DW0
                                16'h0, // Command Identifier
                                4'h0,     // PDST
                                4'h0,     // FUSE
                                8'h06,    // Opcode

                                // DESC2
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'd1,   // Requester ID Enable
                                COMPLETER_ID,
                                8'd0,   // Tag

                                // DESC1
                                REQUESTER_ID,
                                1'b0,   // Reserved
                                1'b0,   // Poisoned Completion
                                3'h0,   // Completion Status
                                11'd16, // Dword Count

                                // DESC0
                                2'b0,   // Reserved
                                1'b0,   // Locked Read Completion
                                13'd64, // Byte Count
                                6'h0,   // Reserved
                                2'b0,   // Address Type
                                1'b0,   // Reserved
                                7'h0    // Address [6:0]
                              };
            s_axis_cc_tvalid_d = 1'b1;
            s_axis_cc_tkeep_d = 4'b1111;
            s_axis_cc_tlast_d = 1'b0;
            s_axis_cc_tuser_d = {
                                32'd0,  // parity
                                1'b0    // discontinue
                              };
          end
        end

        ST_CMD_DW1_4: begin
          if(s_axis_cc_tready) begin
            s_axis_cc_tdata_d = {
                                  // MPTR0 (Metadata Pointer)
                                  32'h0,

                                  // Reserved
                                  64'h0,

                                  // NSID
                                  32'h0 
                                };
            s_axis_cc_tvalid_d = 1'b1;
            s_axis_cc_tkeep_d = 4'b1111;
            s_axis_cc_tlast_d = 1'b0;
            s_axis_cc_tuser_d = {AXI4_CC_TUSER_WIDTH{1'b0}};
          end
        end

        ST_CMD_DW5_8: begin
          if(s_axis_cc_tready) begin
            s_axis_cc_tdata_d = { 
                                  // PRP2-0
                                  32'h0,

                                  // PRP1
                                  64'h0000_1000_0000_0000,

                                  // MPTR1 (Metadata Pointer)
                                  32'h0
                                };
            s_axis_cc_tvalid_d = 1'b1;
            s_axis_cc_tkeep_d = 4'b1111;
            s_axis_cc_tlast_d = 1'b0;
            s_axis_cc_tuser_d = {AXI4_CC_TUSER_WIDTH{1'b0}};
          end
        end

        ST_CMD_DW9_12: begin
          if(s_axis_cc_tready) begin
            s_axis_cc_tdata_d = {
                                  // DW12
                                  32'h0,

                                  // DW11
                                  //32'h0,
                                  8'h0,   // Command Set Identifier (CSI)
                                  8'h0,   // Reserved
                                  16'h0,  // CNS Specific Identifier

                                  // DW10
                                  //32'h0,
                                  16'h0,  // Controller Identifier (CNTID)
                                  8'h0,   // Reserved
                                  8'h1,   // Controller or Namespace Structure (CNS)
                                  
                                  // PRP2-1
                                  32'h0
                                };
            s_axis_cc_tvalid_d = 1'b1;
            s_axis_cc_tkeep_d = 4'b1111;
            s_axis_cc_tlast_d = 1'b0;
            s_axis_cc_tuser_d = {AXI4_CC_TUSER_WIDTH{1'b0}};
          end
        end

        ST_CMD_DW13_15: begin
          if(s_axis_cc_tready) begin
            s_axis_cc_tdata_d = {
                                  // DW16 (not used)
                                  32'h0,

                                  // DW15
                                  32'h0,

                                  // DW14
                                  25'h0,  // Reserved
                                  7'h0,   // UUID Index

                                  // DW13
                                  32'h0
                                };
            s_axis_cc_tvalid_d = 1'b1;
            s_axis_cc_tkeep_d = 4'b0111;
            s_axis_cc_tlast_d = 1'b1;
            s_axis_cc_tuser_d = {AXI4_CC_TUSER_WIDTH{1'b0}};
          end
        end

        default: begin
          s_axis_cc_tdata_d = {C_DATA_WIDTH{1'b0}};
          s_axis_cc_tvalid_d = 1'b0;
          s_axis_cc_tkeep_d = 4'b0000;
          s_axis_cc_tlast_d = 1'b0;
          s_axis_cc_tuser_d = {AXI4_CC_TUSER_WIDTH{1'b0}};
        end

      endcase
    end
  end



endmodule