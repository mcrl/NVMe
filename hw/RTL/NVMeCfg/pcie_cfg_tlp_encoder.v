
(* DowngradeIPIdentifiedWarnings = "yes" *)
module pcie_cfg_tlp_encoder #(
    parameter [15:0] REQUESTER_ID = 16'h10EE,
    parameter AXI4_RQ_TUSER_WIDTH = 62,
    parameter C_DATA_WIDTH        = 128,
    parameter KEEP_WIDTH          = C_DATA_WIDTH / 32 
  )
  (
    input wire          user_clk,
    input wire          reset,

    // Tx mux interface
    input                                 pg_s_axis_rq_tready,
    output reg [C_DATA_WIDTH-1:0]         pg_s_axis_rq_tdata,
    output reg [KEEP_WIDTH-1:0]           pg_s_axis_rq_tkeep,
    output reg [AXI4_RQ_TUSER_WIDTH-1:0]  pg_s_axis_rq_tuser,
    output reg                            pg_s_axis_rq_tlast,
    output reg                            pg_s_axis_rq_tvalid,

    // Controller interface
    input wire [1:0]    pkt_type,  
    input wire [1:0]    pkt_func_num,
    input wire [9:0]    pkt_reg_num,
    input wire [3:0]    pkt_1dw_be,
    input wire [2:0]    pkt_msg_routing,
    input wire [7:0]    pkt_msg_code,
    input wire [31:0]   pkt_data,
    input wire          pkt_start,
    output reg          pkt_done
  );

  // Encodings for pkt_type
  localparam [1:0] TYPE_CFGRD = 2'b00;
  localparam [1:0] TYPE_CFGWR = 2'b01;
  localparam [1:0] TYPE_MSG   = 2'b10;
  localparam [1:0] TYPE_MSGD  = 2'b11;

  localparam [2:0] ST_IDLE   = 3'd0;
  localparam [2:0] ST_CFG0   = 3'd1;
  localparam [2:0] ST_CFG1   = 3'd2;
  localparam [2:0] ST_CFG2   = 3'd3;
  localparam [2:0] ST_MSG0   = 3'd4;
  localparam [2:0] ST_MSG1   = 3'd5;
  localparam [2:0] ST_MSG2   = 3'd6;

  reg [2:0]  pkt_state;

  // State-machine and controller hand-shake
  // ST_IDLE : wait for Controller to request TLP transmission
  // ST_CFG0 : First 2 QW's (4 dwords) of a CfgRd0 or CfgWr0 TLP
  // ST_CFG1 : Last 2 QW's (4 dwords) of a CfgWr0 TLP
  // ST_MSG0 : First 2 QW's of a Msg or MsgD TLP
  // ST_MSG1 : Third QW of MsgD TLP

  always @(posedge user_clk) begin
    if (reset) begin
      pkt_state          <= ST_IDLE;
      pkt_done           <= 1'b0;
    end 
    else begin
      case (pkt_state)
        ST_IDLE: begin
          pkt_done       <= 1'b0;

          if (pkt_start) begin
            if (pkt_type == TYPE_CFGRD || pkt_type == TYPE_CFGWR) begin
              pkt_state  <= ST_CFG0;
            end 
            else begin
              pkt_state  <= ST_CFG0;
            end
          end
        end // ST_IDLE

        ST_CFG0: begin
          if (pg_s_axis_rq_tready) begin
            if (pkt_type == TYPE_CFGWR) begin
                pkt_state    <= ST_CFG1;
            end 
            else begin
                pkt_state    <= ST_IDLE;
                pkt_done     <= 1'b1;
            end
          end
        end // ST_CFG0

        ST_CFG1: begin
          if (pg_s_axis_rq_tready) begin
            pkt_state    <= ST_IDLE;
            pkt_done     <= 1'b1;
          end
        end // ST_CFG1

        ST_MSG0: begin
          if (pg_s_axis_rq_tready) begin
            if (pkt_type == TYPE_MSGD) begin
              pkt_state    <= ST_MSG1;
            end 
            else begin
              pkt_state    <= ST_IDLE;
              pkt_done     <= 1'b1;
            end
          end
        end // ST_MSG0

        ST_MSG1: begin : beat_2_MSG
          if (pg_s_axis_rq_tready) begin
              pkt_state    <= ST_IDLE;
              pkt_done     <= 1'b1;
          end
        end // ST_MSG1

        default: begin
          pkt_state      <= ST_IDLE;
        end // default case
      endcase
    end
  end


  always @* begin
    case (pkt_state)
      ST_CFG0: begin
        pg_s_axis_rq_tlast = (pkt_type == TYPE_CFGWR) ? 1'b0 : 1'b1;
        pg_s_axis_rq_tuser = {32'b0,
                                4'b1010,      // Seq Number
                                8'h00,        // TPH Steering Tag
                                1'b0,         // TPH indirect Tag Enable
                                2'b0,         // TPH Type
                                1'b0,         // TPH Present
                                1'b0,         // Discontinue
                                3'b000,       // Byte Lane number in case of Address Aligned mode
                                4'b0,         //last_dw_be_,    // Last BE of the Read Data
                                pkt_1dw_be};  //first_dw_be_ }; // First BE of the Read Data

        pg_s_axis_rq_tdata = {
                                1'b0,   // Force ECRC
                                3'b0,   // Attribute
                                3'b0,   // TC
                                1'b0,   // RID
                                8'h01,         // Bus #            \
                                5'b00000,      // Device #         |  Completer ID
                                1'b0,          // Function # (Hi)  |
                                pkt_func_num,  // Function # (Lo)  /
                                8'b0,   // Tag

                                16'h00AF,//REQUESTER_ID, //
                                1'b0,
                              (pkt_type == TYPE_CFGRD) ? 4'b1000 : 4'b1010, // Req Type
                              11'd1,
                              32'b0,
                              16'b0,
                                4'b0,
                                pkt_reg_num,    // Ext Reg Number, Register Number
                                2'b00           // Reserved
                                };
        pg_s_axis_rq_tkeep  = {KEEP_WIDTH{1'b1}};
        pg_s_axis_rq_tvalid = 1'b1;
      end // ST_CFG0

      ST_CFG1: begin
        pg_s_axis_rq_tdata = {32'b0,
                              32'b0,
                              32'b0,
                              pkt_data[31:24], 
                              pkt_data[23:16], 
                              pkt_data[15: 8], 
                              pkt_data[ 7: 0] 
                              };
        pg_s_axis_rq_tkeep  = 4'b1;
        pg_s_axis_rq_tvalid = 1'b1;
        pg_s_axis_rq_tlast  = 1'b1;
        pg_s_axis_rq_tuser = {AXI4_RQ_TUSER_WIDTH{1'b0}};
      end // ST_CFG1

      ST_MSG0: begin
        pg_s_axis_rq_tlast  = (pkt_type == TYPE_MSGD) ? 1'b0 : 1'b1;
        pg_s_axis_rq_tuser = {32'b0,
                                4'b1010,      // Seq Number
                                8'h00,        // TPH Steering Tag
                                1'b0,         // TPH indirect Tag Enable
                                2'b0,         // TPH Type
                                1'b0,         // TPH Present
                                1'b0,         // Discontinue
                                3'b000,       // Byte Lane number in case of Address Aligned mode
                                4'b0,         // last_dw_be_,     Last BE of the Read Data
                                4'b0};        // first_dw_be_ };  First BE of the Read Data

        pg_s_axis_rq_tdata = { 1'b0,   // Force ECRC
                                3'b0,   // Attribute
                                3'b0,   // TC
                                1'b0,   // RID
                                5'b0,   // rsvd
                                pkt_msg_routing,                         // Msg Routing
                                pkt_msg_code,                            // Message Code
                                8'b0,   // Tag

                                REQUESTER_ID, //
                                1'b0,
                                4'b1100,  // Req Type
                                (pkt_type == TYPE_MSGD) ? 11'd1 : 11'd0,     // Length

                                64'h0 }; // Addr[31:2], Reserved, Addr[63:32]

        pg_s_axis_rq_tkeep  = {KEEP_WIDTH{1'b1}};
        pg_s_axis_rq_tvalid = 1'b1;
      end // ST_MSG0

      ST_MSG1: begin
        pg_s_axis_rq_tlast  = 1'b1;
        pg_s_axis_rq_tuser = {AXI4_RQ_TUSER_WIDTH{1'b0}};
        pg_s_axis_rq_tdata  = {96'h0000_0000, pkt_data}; // Data, don't-care
        pg_s_axis_rq_tkeep  = 4'b1;
        pg_s_axis_rq_tvalid = 1'b1;
      end // ST_MSG1

      default: begin
        // No TLP active
        pg_s_axis_rq_tlast  = 1'b0;
        pg_s_axis_rq_tuser = {AXI4_RQ_TUSER_WIDTH{1'b0}};
        pg_s_axis_rq_tdata  = {C_DATA_WIDTH{1'b0}};
        pg_s_axis_rq_tkeep  = {KEEP_WIDTH{1'b0}};
        pg_s_axis_rq_tvalid = 1'b0;
      end // default case
    endcase
  end


endmodule
