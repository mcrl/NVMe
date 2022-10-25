// I/O Completion Queue

module user_icq#(
  // AXIS Parameters
  parameter       AXI4_RC_TUSER_WIDTH = 75,
  parameter       C_DATA_WIDTH        = 128,
  parameter       KEEP_WIDTH          = C_DATA_WIDTH / 32
)(
  input user_clk,
  input user_reset,
  input user_lnk_up,

  input [C_DATA_WIDTH-1:0]        wr_m_axis_rc_tdata,
  input   [KEEP_WIDTH-1:0]        wr_m_axis_rc_tkeep,
  input                           wr_m_axis_rc_tlast,
  input                           wr_m_axis_rc_tvalid,
  input [AXI4_RC_TUSER_WIDTH-1:0] wr_m_axis_rc_tuser,

  output [C_DATA_WIDTH-1:0]         rd_m_axis_rc_tdata,
  output   [KEEP_WIDTH-1:0]         rd_m_axis_rc_tkeep,
  output                            rd_m_axis_rc_tlast,
  output                            rd_m_axis_rc_tvalid,
  output [AXI4_RC_TUSER_WIDTH-1:0]  rd_m_axis_rc_tuser,

  output icq_full
);

  // Write & Read
  wire [207:0]  icq_din;
  wire          icq_push;
  wire [207:0]  icq_dout;
  wire          icq_pop;
  //wire          icq_full;
  wire          icq_empty;
  wire          icq_valid;

  assign icq_din =  {
                      wr_m_axis_rc_tdata, // 128-bit [207:80]
                      wr_m_axis_rc_tkeep, //   4-bit [79:76]
                      wr_m_axis_rc_tlast, //   1-bit [75:75]
                      wr_m_axis_rc_tuser  //  75-bit [74:0]
                    };

  assign icq_push = wr_m_axis_rc_tvalid && !icq_full;

  assign rd_m_axis_rc_tdata = icq_dout[207:80];
  assign rd_m_axis_rc_tkeep = icq_dout[79:76];
  assign rd_m_axis_rc_tlast = icq_dout[75];
  assign rd_m_axis_rc_tuser = icq_dout[74:0];
  assign rd_m_axis_rc_tvalid = icq_valid;

  assign icq_pop = !icq_empty;

  // FIFO
  icq_fifo icq_fifo_inst (
    .clk(user_clk),                  // input wire clk
    .srst(user_reset),                // input wire srst

    // Write (enq)
    .din(icq_din),                  // input wire [207 : 0] din
    .wr_en(icq_push),              // input wire wr_en
    .full(icq_full),                // output wire full

    // Read (deq)
    .rd_en(icq_pop),              // input wire rd_en
    .dout(icq_dout),                // output wire [207 : 0] dout
    .empty(icq_empty),              // output wire empty
    .valid(icq_valid),              // output wire valid

    .wr_rst_busy(),  // output wire wr_rst_busy
    .rd_rst_busy()  // output wire rd_rst_busy
  );

endmodule