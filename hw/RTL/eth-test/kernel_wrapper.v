module kernel_wrapper #(
  parameter HOST_ADDR_WIDTH = 21,
  parameter HOST_DATA_WIDTH = 32,
  parameter CMAC_DATA_WIDTH = 512
) (
  input wire clk,
  input wire rstn,

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

  // AXIS master for cmac
  output wire [CMAC_DATA_WIDTH-1:0]   m_tdata,
  output wire [CMAC_DATA_WIDTH/8-1:0] m_tkeep,
  output wire m_tvalid,
  input  wire m_tready,
  output wire m_tlast,
  output wire m_tuser,

  // AXIS slave for cmac
  input wire [CMAC_DATA_WIDTH-1:0]   s_tdata,
  input wire [CMAC_DATA_WIDTH/8-1:0] s_tkeep,
  input wire s_tvalid,
  input wire s_tlast,
  input wire s_tuser
);

kernel #(
  .HOST_ADDR_WIDTH(HOST_ADDR_WIDTH),
  .HOST_DATA_WIDTH(HOST_DATA_WIDTH),
  .CMAC_DATA_WIDTH(CMAC_DATA_WIDTH)
) kernel_inst (
  .clk(clk),
  .rstn(rstn),
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
  .m_tdata(m_tdata),
  .m_tkeep(m_tkeep),
  .m_tvalid(m_tvalid),
  .m_tready(m_tready),
  .m_tlast(m_tlast),
  .m_tuser(m_tuser),
  .s_tdata(s_tdata),
  .s_tkeep(s_tkeep),
  .s_tvalid(s_tvalid),
  .s_tlast(s_tlast),
  .s_tuser(s_tuser)
);

endmodule