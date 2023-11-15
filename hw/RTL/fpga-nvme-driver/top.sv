
module top(
  input [3:0]oculink_0a_mgt_rxn,
  input [3:0]oculink_0a_mgt_rxp,
  output [3:0]oculink_0a_mgt_txn,
  output [3:0]oculink_0a_mgt_txp,
  input [0:0]oculink_0a_ref_clk_n,
  input [0:0]oculink_0a_ref_clk_p,
  output oculink_0a_rstn,
  input [15:0]host_mgt_rxn,
  input [15:0]host_mgt_rxp,
  output [15:0]host_mgt_txn,
  output [15:0]host_mgt_txp,
  input [0:0]host_ref_clk_n,
  input [0:0]host_ref_clk_p,
  input host_rstn
  );
  

  // oculink 0a axi interface
  logic oculink_0a_axi_aclk;
  logic oculink_0a_axi_rstn;
  logic [31:0]oculink_0a_m_axi_araddr;
  logic [1:0]oculink_0a_m_axi_arburst;
  logic [3:0]oculink_0a_m_axi_arcache;
  logic [3:0]oculink_0a_m_axi_arid;
  logic [7:0]oculink_0a_m_axi_arlen;
  logic oculink_0a_m_axi_arlock;
  logic [2:0]oculink_0a_m_axi_arprot;
  logic oculink_0a_m_axi_arready;
  logic [2:0]oculink_0a_m_axi_arsize;
  logic oculink_0a_m_axi_arvalid;
  logic [31:0]oculink_0a_m_axi_awaddr;
  logic [1:0]oculink_0a_m_axi_awburst;
  logic [3:0]oculink_0a_m_axi_awcache;
  logic [3:0]oculink_0a_m_axi_awid;
  logic [7:0]oculink_0a_m_axi_awlen;
  logic oculink_0a_m_axi_awlock;
  logic [2:0]oculink_0a_m_axi_awprot;
  logic oculink_0a_m_axi_awready;
  logic [2:0]oculink_0a_m_axi_awsize;
  logic oculink_0a_m_axi_awvalid;
  logic [3:0]oculink_0a_m_axi_bid;
  logic oculink_0a_m_axi_bready;
  logic [1:0]oculink_0a_m_axi_bresp;
  logic oculink_0a_m_axi_bvalid;
  logic [255:0]oculink_0a_m_axi_rdata;
  logic [3:0]oculink_0a_m_axi_rid;
  logic oculink_0a_m_axi_rlast;
  logic oculink_0a_m_axi_rready;
  logic [1:0]oculink_0a_m_axi_rresp;
  logic oculink_0a_m_axi_rvalid;
  logic [255:0]oculink_0a_m_axi_wdata;
  logic oculink_0a_m_axi_wlast;
  logic oculink_0a_m_axi_wready;
  logic [31:0]oculink_0a_m_axi_wstrb;
  logic oculink_0a_m_axi_wvalid;
  logic [31:0]oculink_0a_s_axi_araddr;
  logic [1:0]oculink_0a_s_axi_arburst;
  logic [3:0]oculink_0a_s_axi_arid;
  logic [7:0]oculink_0a_s_axi_arlen;
  logic oculink_0a_s_axi_arready;
  logic [3:0]oculink_0a_s_axi_arregion;
  logic [2:0]oculink_0a_s_axi_arsize;
  logic oculink_0a_s_axi_arvalid;
  logic [31:0]oculink_0a_s_axi_awaddr;
  logic [1:0]oculink_0a_s_axi_awburst;
  logic [3:0]oculink_0a_s_axi_awid;
  logic [7:0]oculink_0a_s_axi_awlen;
  logic oculink_0a_s_axi_awready;
  logic [3:0]oculink_0a_s_axi_awregion;
  logic [2:0]oculink_0a_s_axi_awsize;
  logic oculink_0a_s_axi_awvalid;
  logic [3:0]oculink_0a_s_axi_bid;
  logic oculink_0a_s_axi_bready;
  logic [1:0]oculink_0a_s_axi_bresp;
  logic oculink_0a_s_axi_bvalid;
  logic [255:0]oculink_0a_s_axi_rdata;
  logic [3:0]oculink_0a_s_axi_rid;
  logic oculink_0a_s_axi_rlast;
  logic oculink_0a_s_axi_rready;
  logic [1:0]oculink_0a_s_axi_rresp;
  logic oculink_0a_s_axi_rvalid;
  logic [255:0]oculink_0a_s_axi_wdata;
  logic oculink_0a_s_axi_wlast;
  logic oculink_0a_s_axi_wready;
  logic [31:0]oculink_0a_s_axi_wstrb;
  logic oculink_0a_s_axi_wvalid;

  // host bram interfaces
  logic host_axi_rstn;
  logic [15:0]host_bram_addr;
  logic host_bram_clk;
  logic [31:0]host_bram_din;
  logic [31:0]host_bram_dout;
  logic host_bram_en;
  logic host_bram_rst;
  logic [3:0]host_bram_we;

  // host xdma bd send oculink reset signal
  assign oculink_0a_rstn = host_axi_rstn;

  host_xdma_bd_wrapper host_xdma_bd_wrapper_i(
    .host_mgt_rxn(host_mgt_rxn),
    .host_mgt_rxp(host_mgt_rxp),
    .host_mgt_txn(host_mgt_txn),
    .host_mgt_txp(host_mgt_txp),
    .host_ref_clk_n(host_ref_clk_n),
    .host_ref_clk_p(host_ref_clk_p),
    .host_rstn(host_rstn),
    .host_bram_addr(host_bram_addr),
    .host_bram_clk(host_bram_clk),
    .host_bram_din(host_bram_din),
    .host_bram_dout(host_bram_dout),
    .host_bram_en(host_bram_en),
    .host_bram_rst(host_bram_rst),
    .host_bram_we(host_bram_we),
    .host_axi_rstn(host_axi_rstn)
  );

  oculink_0a_bd_wrapper oculink_0a_bd_wrapper_i(
    .oculink_0a_mgt_rxn(oculink_0a_mgt_rxn),
    .oculink_0a_mgt_rxp(oculink_0a_mgt_rxp),
    .oculink_0a_mgt_txn(oculink_0a_mgt_txn),
    .oculink_0a_mgt_txp(oculink_0a_mgt_txp),
    .oculink_0a_ref_clk_n(oculink_0a_ref_clk_n),
    .oculink_0a_ref_clk_p(oculink_0a_ref_clk_p),
    .oculink_0a_rstn(host_axi_rstn),  // host send reset signal into oculink bd
    .oculink_0a_axi_rstn(oculink_0a_axi_rstn),
    .oculink_0a_axi_aclk(oculink_0a_axi_aclk),
    .oculink_0a_m_axi_araddr(oculink_0a_m_axi_araddr),
    .oculink_0a_m_axi_arburst(oculink_0a_m_axi_arburst),
    .oculink_0a_m_axi_arcache(oculink_0a_m_axi_arcache),
    .oculink_0a_m_axi_arid(oculink_0a_m_axi_arid),
    .oculink_0a_m_axi_arlen(oculink_0a_m_axi_arlen),
    .oculink_0a_m_axi_arlock(oculink_0a_m_axi_arlock),
    .oculink_0a_m_axi_arprot(oculink_0a_m_axi_arprot),
    .oculink_0a_m_axi_arready(oculink_0a_m_axi_arready),
    .oculink_0a_m_axi_arsize(oculink_0a_m_axi_arsize),
    .oculink_0a_m_axi_arvalid(oculink_0a_m_axi_arvalid),
    .oculink_0a_m_axi_awaddr(oculink_0a_m_axi_awaddr),
    .oculink_0a_m_axi_awburst(oculink_0a_m_axi_awburst),
    .oculink_0a_m_axi_awcache(oculink_0a_m_axi_awcache),
    .oculink_0a_m_axi_awid(oculink_0a_m_axi_awid),
    .oculink_0a_m_axi_awlen(oculink_0a_m_axi_awlen),
    .oculink_0a_m_axi_awlock(oculink_0a_m_axi_awlock),
    .oculink_0a_m_axi_awprot(oculink_0a_m_axi_awprot),
    .oculink_0a_m_axi_awready(oculink_0a_m_axi_awready),
    .oculink_0a_m_axi_awsize(oculink_0a_m_axi_awsize),
    .oculink_0a_m_axi_awvalid(oculink_0a_m_axi_awvalid),
    .oculink_0a_m_axi_bid(oculink_0a_m_axi_bid),
    .oculink_0a_m_axi_bready(oculink_0a_m_axi_bready),
    .oculink_0a_m_axi_bresp(oculink_0a_m_axi_bresp),
    .oculink_0a_m_axi_bvalid(oculink_0a_m_axi_bvalid),
    .oculink_0a_m_axi_rdata(oculink_0a_m_axi_rdata),
    .oculink_0a_m_axi_rid(oculink_0a_m_axi_rid),
    .oculink_0a_m_axi_rlast(oculink_0a_m_axi_rlast),
    .oculink_0a_m_axi_rready(oculink_0a_m_axi_rready),
    .oculink_0a_m_axi_rresp(oculink_0a_m_axi_rresp),
    .oculink_0a_m_axi_rvalid(oculink_0a_m_axi_rvalid),
    .oculink_0a_m_axi_wdata(oculink_0a_m_axi_wdata),
    .oculink_0a_m_axi_wlast(oculink_0a_m_axi_wlast),
    .oculink_0a_m_axi_wready(oculink_0a_m_axi_wready),
    .oculink_0a_m_axi_wstrb(oculink_0a_m_axi_wstrb),
    .oculink_0a_m_axi_wvalid(oculink_0a_m_axi_wvalid),
    .oculink_0a_s_axi_araddr(oculink_0a_s_axi_araddr),
    .oculink_0a_s_axi_arburst(oculink_0a_s_axi_arburst),
    .oculink_0a_s_axi_arlen(oculink_0a_s_axi_arlen),
    .oculink_0a_s_axi_arready(oculink_0a_s_axi_arready),
    .oculink_0a_s_axi_arsize(oculink_0a_s_axi_arsize),
    .oculink_0a_s_axi_arvalid(oculink_0a_s_axi_arvalid),
    .oculink_0a_s_axi_awaddr(oculink_0a_s_axi_awaddr),
    .oculink_0a_s_axi_awburst(oculink_0a_s_axi_awburst),
    .oculink_0a_s_axi_awlen(oculink_0a_s_axi_awlen),
    .oculink_0a_s_axi_awready(oculink_0a_s_axi_awready),
    .oculink_0a_s_axi_awsize(oculink_0a_s_axi_awsize),
    .oculink_0a_s_axi_awvalid(oculink_0a_s_axi_awvalid),
    .oculink_0a_s_axi_bready(oculink_0a_s_axi_bready),
    .oculink_0a_s_axi_bresp(oculink_0a_s_axi_bresp),
    .oculink_0a_s_axi_bvalid(oculink_0a_s_axi_bvalid),
    .oculink_0a_s_axi_rdata(oculink_0a_s_axi_rdata),
    .oculink_0a_s_axi_rlast(oculink_0a_s_axi_rlast),
    .oculink_0a_s_axi_rready(oculink_0a_s_axi_rready),
    .oculink_0a_s_axi_rresp(oculink_0a_s_axi_rresp),
    .oculink_0a_s_axi_rvalid(oculink_0a_s_axi_rvalid),
    .oculink_0a_s_axi_wdata(oculink_0a_s_axi_wdata),
    .oculink_0a_s_axi_wlast(oculink_0a_s_axi_wlast),
    .oculink_0a_s_axi_wready(oculink_0a_s_axi_wready),
    .oculink_0a_s_axi_wstrb(oculink_0a_s_axi_wstrb),
    .oculink_0a_s_axi_wvalid(oculink_0a_s_axi_wvalid),
    .oculink_0a_s_axi_arcache(oculink_0a_s_axi_arcache),
    .oculink_0a_s_axi_arlock(oculink_0a_s_axi_arlock),
    .oculink_0a_s_axi_arprot(oculink_0a_s_axi_arprot),
    .oculink_0a_s_axi_arqos(oculink_0a_s_axi_arqos),
    .oculink_0a_s_axi_awcache(oculink_0a_s_axi_awcache),
    .oculink_0a_s_axi_awlock(oculink_0a_s_axi_awlock),
    .oculink_0a_s_axi_awprot(oculink_0a_s_axi_awprot),
    .oculink_0a_s_axi_awqos(oculink_0a_s_axi_awqos)
  );

  kernel kernel_i(
    .host_bram_addr(host_bram_addr),
    .host_bram_clk(host_bram_clk),
    .host_bram_din(host_bram_din),
    .host_bram_dout(host_bram_dout),
    .host_bram_en(host_bram_en),
    .host_bram_rst(host_bram_rst),
    .host_bram_we(host_bram_we),
    .oculink_0a_axi_rstn(oculink_0a_axi_rstn),
    .oculink_0a_axi_aclk(oculink_0a_axi_aclk),
    .oculink_0a_m_axi_araddr(oculink_0a_m_axi_araddr),
    .oculink_0a_m_axi_arburst(oculink_0a_m_axi_arburst),
    .oculink_0a_m_axi_arcache(oculink_0a_m_axi_arcache),
    .oculink_0a_m_axi_arid(oculink_0a_m_axi_arid),
    .oculink_0a_m_axi_arlen(oculink_0a_m_axi_arlen),
    .oculink_0a_m_axi_arlock(oculink_0a_m_axi_arlock),
    .oculink_0a_m_axi_arprot(oculink_0a_m_axi_arprot),
    .oculink_0a_m_axi_arready(oculink_0a_m_axi_arready),
    .oculink_0a_m_axi_arsize(oculink_0a_m_axi_arsize),
    .oculink_0a_m_axi_arvalid(oculink_0a_m_axi_arvalid),
    .oculink_0a_m_axi_awaddr(oculink_0a_m_axi_awaddr),
    .oculink_0a_m_axi_awburst(oculink_0a_m_axi_awburst),
    .oculink_0a_m_axi_awcache(oculink_0a_m_axi_awcache),
    .oculink_0a_m_axi_awid(oculink_0a_m_axi_awid),
    .oculink_0a_m_axi_awlen(oculink_0a_m_axi_awlen),
    .oculink_0a_m_axi_awlock(oculink_0a_m_axi_awlock),
    .oculink_0a_m_axi_awprot(oculink_0a_m_axi_awprot),
    .oculink_0a_m_axi_awready(oculink_0a_m_axi_awready),
    .oculink_0a_m_axi_awsize(oculink_0a_m_axi_awsize),
    .oculink_0a_m_axi_awvalid(oculink_0a_m_axi_awvalid),
    .oculink_0a_m_axi_bid(oculink_0a_m_axi_bid),
    .oculink_0a_m_axi_bready(oculink_0a_m_axi_bready),
    .oculink_0a_m_axi_bresp(oculink_0a_m_axi_bresp),
    .oculink_0a_m_axi_bvalid(oculink_0a_m_axi_bvalid),
    .oculink_0a_m_axi_rdata(oculink_0a_m_axi_rdata),
    .oculink_0a_m_axi_rid(oculink_0a_m_axi_rid),
    .oculink_0a_m_axi_rlast(oculink_0a_m_axi_rlast),
    .oculink_0a_m_axi_rready(oculink_0a_m_axi_rready),
    .oculink_0a_m_axi_rresp(oculink_0a_m_axi_rresp),
    .oculink_0a_m_axi_rvalid(oculink_0a_m_axi_rvalid),
    .oculink_0a_m_axi_wdata(oculink_0a_m_axi_wdata),
    .oculink_0a_m_axi_wlast(oculink_0a_m_axi_wlast),
    .oculink_0a_m_axi_wready(oculink_0a_m_axi_wready),
    .oculink_0a_m_axi_wstrb(oculink_0a_m_axi_wstrb),
    .oculink_0a_m_axi_wvalid(oculink_0a_m_axi_wvalid),
    .oculink_0a_s_axi_araddr(oculink_0a_s_axi_araddr),
    .oculink_0a_s_axi_arburst(oculink_0a_s_axi_arburst),
    .oculink_0a_s_axi_arlen(oculink_0a_s_axi_arlen),
    .oculink_0a_s_axi_arready(oculink_0a_s_axi_arready),
    .oculink_0a_s_axi_arregion(oculink_0a_s_axi_arregion),
    .oculink_0a_s_axi_arsize(oculink_0a_s_axi_arsize),
    .oculink_0a_s_axi_arvalid(oculink_0a_s_axi_arvalid),
    .oculink_0a_s_axi_awaddr(oculink_0a_s_axi_awaddr),
    .oculink_0a_s_axi_awburst(oculink_0a_s_axi_awburst),
    .oculink_0a_s_axi_awlen(oculink_0a_s_axi_awlen),
    .oculink_0a_s_axi_awready(oculink_0a_s_axi_awready),
    .oculink_0a_s_axi_awregion(oculink_0a_s_axi_awregion),
    .oculink_0a_s_axi_awsize(oculink_0a_s_axi_awsize),
    .oculink_0a_s_axi_awvalid(oculink_0a_s_axi_awvalid),
    .oculink_0a_s_axi_bready(oculink_0a_s_axi_bready),
    .oculink_0a_s_axi_bresp(oculink_0a_s_axi_bresp),
    .oculink_0a_s_axi_bvalid(oculink_0a_s_axi_bvalid),
    .oculink_0a_s_axi_rdata(oculink_0a_s_axi_rdata),
    .oculink_0a_s_axi_rlast(oculink_0a_s_axi_rlast),
    .oculink_0a_s_axi_rready(oculink_0a_s_axi_rready),
    .oculink_0a_s_axi_rresp(oculink_0a_s_axi_rresp),
    .oculink_0a_s_axi_rvalid(oculink_0a_s_axi_rvalid),
    .oculink_0a_s_axi_wdata(oculink_0a_s_axi_wdata),
    .oculink_0a_s_axi_wlast(oculink_0a_s_axi_wlast),
    .oculink_0a_s_axi_wready(oculink_0a_s_axi_wready),
    .oculink_0a_s_axi_wstrb(oculink_0a_s_axi_wstrb),
    .oculink_0a_s_axi_wvalid(oculink_0a_s_axi_wvalid)
  );

endmodule
