module fifo_bp #(
  parameter DATA_WIDTH,
  parameter LOG2_DEPTH
) (
  input logic clk,
  input logic rstn,
  output logic rvalid,
  output logic [DATA_WIDTH - 1 : 0] rdata,
  input logic rready,
  input logic wvalid,
  input logic [DATA_WIDTH - 1 : 0] wdata,
  output logic wready
);

  // Backpressure by wready

  logic rd_rst_busy, wr_rst_busy, empty, full, rd_en, wr_en, rst, wr_clk;
  logic [DATA_WIDTH - 1 : 0] din, dout;

  always_comb begin
    rst = ~rstn;
    rd_en = ~rst & ~rd_rst_busy & ~wr_rst_busy & ~empty & rready;
    wr_en = ~rst & ~rd_rst_busy & ~wr_rst_busy & wvalid & wready;
    wr_clk = clk;
    din = wdata;
    rvalid = ~empty;
    rdata = dout;
    wready = ~full;
  end

  xpm_fifo_sync #(
    .CASCADE_HEIGHT(0),
    .DOUT_RESET_VALUE("0"),
    .ECC_MODE("no_ecc"),
    .FIFO_MEMORY_TYPE("auto"),
    .FIFO_READ_LATENCY(0), // fwft should use 0
    .FIFO_WRITE_DEPTH(2 ** LOG2_DEPTH), // num entries
    .FULL_RESET_VALUE(0),
    .PROG_EMPTY_THRESH(10),
    .PROG_FULL_THRESH(10),
    .RD_DATA_COUNT_WIDTH(1),
    .READ_DATA_WIDTH(DATA_WIDTH), // read width
    .READ_MODE("fwft"), // use fwft mode
    .SIM_ASSERT_CHK(0),
    .USE_ADV_FEATURES("0000"), // disable all advanced features
    .WAKEUP_TIME(0),
    .WRITE_DATA_WIDTH(DATA_WIDTH), // write width
    .WR_DATA_COUNT_WIDTH(1)
  ) xpm_fifo_sync_inst (
      .almost_empty(),
      .almost_full(),
      .data_valid(),
      .dbiterr(),
      .dout(dout),
      .empty(empty),
      .full(full),
      .overflow(),
      .prog_empty(),
      .prog_full(),
      .rd_data_count(),
      .rd_rst_busy(rd_rst_busy),
      .sbiterr(),
      .underflow(),
      .wr_ack(),
      .wr_data_count(),
      .wr_rst_busy(wr_rst_busy),
      .din(din),
      .injectdbiterr(),
      .injectsbiterr(),
      .rd_en(rd_en),
      .rst(rst),
      .sleep(),
      .wr_clk(wr_clk),
      .wr_en(wr_en)
   );

endmodule