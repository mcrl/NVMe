// host is 32b AXIL from the host
// HP(High Performance) is 128b AXI4 to the NVMe driver
// * 48b address to cover 256TiB
module kernel_wrapper #(
  parameter HOST_ADDR_WIDTH = 32,
  parameter HOST_DATA_WIDTH = 32,
  parameter HP_ADDR_WIDTH = 48,
  parameter HP_DATA_WIDTH = 128
) (
  input wire clk,
  input wire rstn,
  output wire driver_rstn,

  // AXIL slave
  input  wire [HOST_ADDR_WIDTH-1:0]   host_awaddr,
  input  wire [HOST_DATA_WIDTH-1:0]   host_wdata,
  input  wire [HOST_DATA_WIDTH/8-1:0] host_wstrb,
  input  wire [HOST_ADDR_WIDTH-1:0]   host_araddr,
  output wire [HOST_DATA_WIDTH-1:0]   host_rdata,
  input  wire       host_awvalid,
  output wire       host_awready,
  input  wire       host_wvalid,
  output wire       host_wready,
  output wire [1:0] host_bresp,
  output wire       host_bvalid,
  input  wire       host_bready,
  input  wire       host_arvalid,
  output wire       host_arready,
  output wire [1:0] host_rresp,
  output wire       host_rvalid,
  input  wire       host_rready,

  // AXIB master
  output wire [HP_ADDR_WIDTH-1:0]   hp_awaddr,
  output wire [HP_DATA_WIDTH-1:0]   hp_wdata,
  output wire [HP_DATA_WIDTH/8-1:0] hp_wstrb,
  output wire [HP_ADDR_WIDTH-1:0]   hp_araddr,
  input  wire [HP_DATA_WIDTH-1:0]   hp_rdata,
  output wire [7:0] hp_awlen,
  output wire [2:0] hp_awsize,
  output wire [1:0] hp_awburst,
  output wire       hp_awvalid,
  input  wire       hp_awready,
  output wire       hp_wlast,
  output wire       hp_wvalid,
  input  wire       hp_wready,
  input  wire [1:0] hp_bresp,
  input  wire       hp_bvalid,
  output wire       hp_bready,
  output wire [7:0] hp_arlen,
  output wire [2:0] hp_arsize,
  output wire [1:0] hp_arburst,
  output wire       hp_arvalid,
  input  wire       hp_arready,
  input  wire [1:0] hp_rresp,
  input  wire       hp_rlast,
  input  wire       hp_rvalid,
  output wire       hp_rready
);

kernel #(
  .HOST_ADDR_WIDTH(HOST_ADDR_WIDTH),
  .HOST_DATA_WIDTH(HOST_DATA_WIDTH),
  .HP_ADDR_WIDTH(HP_ADDR_WIDTH),
  .HP_DATA_WIDTH(HP_DATA_WIDTH),
  .LP_ADDR_WIDTH(LP_ADDR_WIDTH),
  .LP_DATA_WIDTH(LP_DATA_WIDTH)
) kernel_inst (
  .clk(clk),
  .rstn(rstn),
  .driver_rstn(driver_rstn),
  .host_awaddr  (host_awaddr),
  .host_wdata   (host_wdata),
  .host_wstrb   (host_wstrb),
  .host_araddr  (host_araddr),
  .host_rdata   (host_rdata),
  .host_awvalid (host_awvalid),
  .host_awready (host_awready),
  .host_wvalid  (host_wvalid),
  .host_wready  (host_wready),
  .host_bresp   (host_bresp),
  .host_bvalid  (host_bvalid),
  .host_bready  (host_bready),
  .host_arvalid (host_arvalid),
  .host_arready (host_arready),
  .host_rresp   (host_rresp),
  .host_rvalid  (host_rvalid),
  .host_rready  (host_rready),
  .hp_awid    (hp_awid),
  .hp_awaddr  (hp_awaddr),
  .hp_wdata   (hp_wdata),
  .hp_wstrb   (hp_wstrb),
  .hp_bid     (hp_bid),
  .hp_arid    (hp_arid),
  .hp_araddr  (hp_araddr),
  .hp_rid     (hp_rid),
  .hp_rdata   (hp_rdata),
  .hp_awlen   (hp_awlen),
  .hp_awsize  (hp_awsize),
  .hp_awburst (hp_awburst),
  .hp_awvalid (hp_awvalid),
  .hp_awready (hp_awready),
  .hp_wlast   (hp_wlast),
  .hp_wvalid  (hp_wvalid),
  .hp_wready  (hp_wready),
  .hp_bresp   (hp_bresp),
  .hp_bvalid  (hp_bvalid),
  .hp_bready  (hp_bready),
  .hp_arlen   (hp_arlen),
  .hp_arsize  (hp_arsize),
  .hp_arburst (hp_arburst),
  .hp_arvalid (hp_arvalid),
  .hp_arready (hp_arready),
  .hp_rresp   (hp_rresp),
  .hp_rlast   (hp_rlast),
  .hp_rvalid  (hp_rvalid),
  .hp_rready  (hp_rready)
);

endmodule