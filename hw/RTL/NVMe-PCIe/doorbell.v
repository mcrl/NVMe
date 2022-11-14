// Write SQ tail doorbell or CQ head doorbell module

module doorbell #(
  parameter        AXI4_RQ_TUSER_WIDTH    = 62,
  parameter        C_DATA_WIDTH           = 128,
  parameter        KEEP_WIDTH             = C_DATA_WIDTH / 32
) (

  // System Interface
  
  input                 user_clk,
  input                 user_reset,
  input                 user_lnk_up,

  // Controller Interface

  input         write_sqtdbl,
  input [63:0]  sqt_addr,
  input         write_cqhdbl,
  input [63:0]  cqh_addr,
  output reg    write_sqtdbl_done,
  output reg    write_cqhdbl_done,

  // PCIe Arbiter AXIS Interface

  output reg        [C_DATA_WIDTH-1:0]  s_axis_rq_tdata,
  output reg [AXI4_RQ_TUSER_WIDTH-1:0]  s_axis_rq_tuser,
  output reg          [KEEP_WIDTH-1:0]  s_axis_rq_tkeep,
  output reg                            s_axis_rq_tlast,
  output reg                            s_axis_rq_tvalid,
  input                     [3:0]       s_axis_rq_tready,

  // for Debugging
  output reg [3:0] db_state,
  output reg is_sq
);

  `include "constants.h"
  
  localparam [3:0] ST_IDLE = 4'd0;  // Wait for write doorbell signal from controller
  localparam [3:0] ST_DB_WRITE1 = 4'd1;
  localparam [3:0] ST_DB_WRITE2 = 4'd2;
  localparam [3:0] ST_DB_DONE   = 4'd3;

/*
  reg [3:0] db_state;
  reg is_sq;
*/

  reg                   [C_DATA_WIDTH-1:0]     s_axis_rq_tdata_d;
  reg                     [KEEP_WIDTH-1:0]     s_axis_rq_tkeep_d;
  reg            [AXI4_RQ_TUSER_WIDTH-1:0]     s_axis_rq_tuser_d;
  reg                                          s_axis_rq_tlast_d;
  reg                                          s_axis_rq_tvalid_d;
  reg                                          write_sqtdbl_done_d;
  reg                                          write_cqhdbl_done_d;



  // Doorbell State Machine
  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      db_state <= ST_IDLE;
    end
    else begin
      if(s_axis_rq_tready) begin
        case(db_state)
          ST_IDLE: begin
            if(write_sqtdbl) db_state <= ST_DB_WRITE1;
          end

          ST_DB_WRITE1: begin
            db_state <= ST_DB_WRITE2;
          end

          ST_DB_WRITE2: begin
            db_state <= ST_DB_DONE;
          end

          ST_DB_DONE: begin
            db_state <= ST_IDLE;
          end

        endcase
      end // if s_axis_rq_tready
    end
  end



  //-------------------------------------------------------
  // Requester reQuest Encoder
  //-------------------------------------------------------

  // Pipelined
  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      s_axis_rq_tdata <= 'd0;
      s_axis_rq_tkeep <= 'd0;
      s_axis_rq_tuser <= 'd0;
      s_axis_rq_tlast <= 'd0;
      s_axis_rq_tvalid <= 'd0;
      write_sqtdbl_done <= 'd0;
    end
    else begin
      s_axis_rq_tdata <= s_axis_rq_tdata_d;
      s_axis_rq_tkeep <= s_axis_rq_tkeep_d;
      s_axis_rq_tuser <= s_axis_rq_tuser_d;
      s_axis_rq_tlast <= s_axis_rq_tlast_d;
      s_axis_rq_tvalid <= s_axis_rq_tvalid_d;
      write_sqtdbl_done <= write_sqtdbl_done_d;
    end
  end


  always@(*) begin
    if(user_reset || !user_lnk_up) begin
      s_axis_rq_tdata_d = {C_DATA_WIDTH{1'b0}};
      s_axis_rq_tvalid_d = 1'b0;
      s_axis_rq_tkeep_d = 4'b0000;
      s_axis_rq_tlast_d = 1'b0;
      s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
      write_sqtdbl_done_d = 'd0;
    end
    else begin
      case(db_state)

        ST_DB_WRITE1: begin
          if(s_axis_rq_tready) begin
            s_axis_rq_tdata_d = {
                                1'b0,   // Force ECRC
                                3'd0,   // Attr
                                3'd0,   // TC
                                1'd0,   // Requester ID Enable
                                16'd0,  // Completer ID
                                8'd0,   // Tag
                                16'd0,  // Requester ID
                                1'd0,   // Poisoned Request
                                4'b0001,   // Req Type Memory Write 
                                11'd1,  // Dword count
                                BAR0[63:2] + SQT_OFFSET[63:2],
                                2'd0    // Reserved
                              };
            s_axis_rq_tvalid_d = 1'b1;
            s_axis_rq_tkeep_d = 4'b1111;
            s_axis_rq_tlast_d = 1'b0;
            s_axis_rq_tuser_d = {
                                2'b0,     // seq_num[5:4]
                                32'd0,    // parity
                                4'd0,     // seq_num[3:0]
                                8'd0,     // tph_st_tag
                                1'b0,     // tph_indirect_tag_en
                                2'd0,     // tph_type   
                                1'b0,     // tph_present
                                1'b0,     // discontinue
                                3'd0,     // addr_offset
                                4'b0000,  // last be
                                4'b1111   // first be 
                              };
          end
        end

        ST_DB_WRITE2: begin
          if(s_axis_rq_tready) begin
            s_axis_rq_tdata_d = {
                                  64'd0, 
                                  32'h0,
                                  sqt_addr[31:0]
                                };
            s_axis_rq_tvalid_d = 1'b1;
            s_axis_rq_tkeep_d = 4'b0001;
            s_axis_rq_tlast_d = 1'b1;
            s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};

            write_sqtdbl_done_d = 1'b1;
          end
        end

        default: begin
          s_axis_rq_tdata_d = {C_DATA_WIDTH{1'b0}};
          s_axis_rq_tvalid_d = 1'b0;
          s_axis_rq_tkeep_d = 4'b0000;
          s_axis_rq_tlast_d = 1'b0;
          s_axis_rq_tuser_d = {AXI4_RQ_TUSER_WIDTH{1'b0}};
          write_sqtdbl_done_d = 'd0;
        end

      endcase
    end
  end

endmodule