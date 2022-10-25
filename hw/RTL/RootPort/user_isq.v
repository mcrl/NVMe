// I/O Submission Queue

module user_isq#(
  // AXIS Parameters
  parameter       AXI4_RQ_TUSER_WIDTH = 62,
  parameter       C_DATA_WIDTH        = 128,
  parameter       KEEP_WIDTH          = C_DATA_WIDTH / 32
)(
  input user_clk,
  input user_reset,
  input user_lnk_up,

  // AXIS from PCIe IP
  input                             s_axis_rq_tready,

  // AXIS from Encoder
  input [C_DATA_WIDTH-1:0]          wr_s_axis_rq_tdata,
  input   [KEEP_WIDTH-1:0]          wr_s_axis_rq_tkeep,
  input                             wr_s_axis_rq_tlast,
  input                             wr_s_axis_rq_tvalid,
  input [AXI4_RQ_TUSER_WIDTH-1:0]   wr_s_axis_rq_tuser,

  // AXIS to PCIe IP
  output [C_DATA_WIDTH-1:0]         rd_s_axis_rq_tdata,
  output   [KEEP_WIDTH-1:0]         rd_s_axis_rq_tkeep,
  output                            rd_s_axis_rq_tlast,
  output                            rd_s_axis_rq_tvalid,
  output [AXI4_RQ_TUSER_WIDTH-1:0]  rd_s_axis_rq_tuser
);


  // Write & Read
  wire [194:0]  isq_din;
  wire          isq_push;
  wire [194:0]  isq_dout;
  wire          isq_pop;
  wire          isq_full;
  wire          isq_empty;
  wire          isq_valid;

  assign isq_din = {
                wr_s_axis_rq_tdata, // 128-bit [194:67]
                wr_s_axis_rq_tkeep, //   4-bit [66:63]
                wr_s_axis_rq_tlast, //   1-bit [62:62]
                wr_s_axis_rq_tuser  //  62-bit [61:0]
              };

  assign isq_push = wr_s_axis_rq_tvalid && !isq_full;
  
  assign rd_s_axis_rq_tdata = isq_dout[194:67];
  assign rd_s_axis_rq_tkeep = isq_dout[66:63];
  assign rd_s_axis_rq_tlast = isq_dout[62];
  assign rd_s_axis_rq_tuser = isq_dout[61:0];
  assign rd_s_axis_rq_tvalid = isq_valid;
   
  assign isq_pop = s_axis_rq_tready && !isq_empty && user_lnk_up;


  // FIFO
  isq_fifo isq_fifo_inst (
    .clk(user_clk),                  // input wire clk
    .srst(user_reset),                // input wire srst
    
    // Write (enq)
    .din(isq_din),                  // input wire [194 : 0] din
    .wr_en(isq_push),              // input wire wr_en
    .full(isq_full),                // output wire full

    // Read (deq)
    .rd_en(isq_pop),              // input wire rd_en
    .dout(isq_dout),                // output wire [194 : 0] dout
    .empty(isq_empty),              // output wire empty
    .valid(isq_valid),              // output wire valid
    
    // Unused
    .wr_rst_busy(),             // output wire wr_rst_busy
    .rd_rst_busy()              // output wire rd_rst_busy
);  

endmodule