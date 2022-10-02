module pcie_tlp_decoder #(
    parameter AXIS_DATA_WIDTH = 64
)(
  input   wire user_clk,
  input   wire user_reset,
  input   wire user_lnk_up,

  output  reg [2:0]   cpl_status,
  output  reg [10:0]  cpl_dword_count,
  output  reg [12:0]  cpl_byte_count,
  output  reg         cpl_req_completed,

  output  reg         recv_data,

  input   wire [63 : 0]   m_axis_rc_tdata,
  input   wire [1 : 0]    m_axis_rc_tkeep,
  input   wire            m_axis_rc_tlast,
  output  wire            m_axis_rc_tready,
  input   wire [74 : 0]   m_axis_rc_tuser,
  input   wire            m_axis_rc_tvalid
);

  assign m_axis_rc_tready = 1'b1;

  localparam  STATE_IDLE          = 4'd0;
  localparam  STATE_RECV          = 4'd1;

	reg [3:0]   dec_state;
  reg [31:0]  dec_recv_dw [1024];
  reg         dec_des_recv_done;

  // FSM
  always@(posedge user_clk) begin
    if(user_reset) begin
      dec_state <= STATE_IDLE;

      recv_data <= 1'b0;
    end else begin
      case(dec_state)
        STATE_IDLE: begin
          recv_data <= 1'b0;
          if(m_axis_rc_tvalid && user_lnk_up) begin
            dec_state <= STATE_RECV;
          end
        end
        STATE_RECV: begin
          if(m_axis_rc_tvalid && m_axis_rc_tlast && user_lnk_up) begin
            dec_state <= STATE_IDLE;
            recv_data <= 1'b1;
          end
        end

      endcase
    end
  end
/*
  reg [9:0] dw_count;

  always@(*) begin
    if(user_reset) begin
      cpl_status = 3'd0;
      cpl_dword_count = 11'd0;
      cpl_byte_count = 13'd0;
      cpl_req_completed = 1'b0;
      dec_des_recv_done = 1'b0;
      dw_count = 10'd0;
    end else begin
      case(dec_state)
        STATE_IDLE: begin
          if(m_axis_rc_tvalid) begin
            cpl_status      = m_axis_rc_tdata[45:43];
            cpl_dword_count = m_axis_rc_tdata[42:32];
            cpl_byte_count  = m_axis_rc_tdata[28:16];
            cpl_req_completed = m_axis_rc_tdata[30];
          end
        end
        STATE_RECV: begin
          if(m_axis_rc_tvalid) begin
            if(dec_des_recv_done) begin
              dec_recv_dw[dw_count]   = m_axis_rc_tdata[31:0];
              dec_recv_dw[dw_count+1] = m_axis_rc_tdata[63:32];
              dw_count = dw_count + 10'd2;
            end 
            else begin
              dec_des_recv_done = 1'b1;
              if(m_axis_rc_tkeep == 2'b11) begin
                dec_recv_dw[0] = m_axis_rc_tdata[63:32];
                dw_count = dw_count + 10'd1;
              end 
            end
          end
        end

        default: begin
          dw_count = 10'd0;
          dec_des_recv_done = 1'b0;
        end
      endcase
    end
  end
*/

endmodule