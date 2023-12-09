
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
  
  wire oculink_0a_axi_aclk;

  // oculink axi master interface
  wire [31:0]oculink_0a_m_axi_araddr;
  wire [1:0]oculink_0a_m_axi_arburst;
  wire [3:0]oculink_0a_m_axi_arcache;
  wire [3:0]oculink_0a_m_axi_arid;
  wire [7:0]oculink_0a_m_axi_arlen;
  wire oculink_0a_m_axi_arlock;
  wire [2:0]oculink_0a_m_axi_arprot;
  wire oculink_0a_m_axi_arready;
  wire [2:0]oculink_0a_m_axi_arsize;
  wire oculink_0a_m_axi_arvalid;
  wire [31:0]oculink_0a_m_axi_awaddr;
  wire [1:0]oculink_0a_m_axi_awburst;
  wire [3:0]oculink_0a_m_axi_awcache;
  wire [3:0]oculink_0a_m_axi_awid;
  wire [7:0]oculink_0a_m_axi_awlen;
  wire oculink_0a_m_axi_awlock;
  wire [2:0]oculink_0a_m_axi_awprot;
  wire oculink_0a_m_axi_awready;
  wire [2:0]oculink_0a_m_axi_awsize;
  wire oculink_0a_m_axi_awvalid;
  wire [3:0]oculink_0a_m_axi_bid;
  wire oculink_0a_m_axi_bready;
  wire [1:0]oculink_0a_m_axi_bresp;
  wire oculink_0a_m_axi_bvalid;
  wire [255:0]oculink_0a_m_axi_rdata;
  wire [3:0]oculink_0a_m_axi_rid;
  wire oculink_0a_m_axi_rlast;
  wire oculink_0a_m_axi_rready;
  wire [1:0]oculink_0a_m_axi_rresp;
  wire oculink_0a_m_axi_rvalid;
  wire [255:0]oculink_0a_m_axi_wdata;
  wire oculink_0a_m_axi_wlast;
  wire oculink_0a_m_axi_wready;
  wire [31:0]oculink_0a_m_axi_wstrb;
  wire oculink_0a_m_axi_wvalid;

  // oculink axi slave interface
  wire [31:0]oculink_0a_s_axi_araddr;
  wire [1:0]oculink_0a_s_axi_arburst;
  wire [3:0]oculink_0a_s_axi_arid;
  wire [7:0]oculink_0a_s_axi_arlen;
  wire oculink_0a_s_axi_arready;
  wire [3:0]oculink_0a_s_axi_arregion;
  wire [2:0]oculink_0a_s_axi_arsize;
  wire oculink_0a_s_axi_arvalid;

  wire [31:0]oculink_0a_s_axi_awaddr;
  wire [1:0]oculink_0a_s_axi_awburst;
  wire [3:0]oculink_0a_s_axi_awid;
  wire [7:0]oculink_0a_s_axi_awlen;
  wire oculink_0a_s_axi_awready;
  wire [3:0]oculink_0a_s_axi_awregion;
  wire [2:0]oculink_0a_s_axi_awsize;
  wire oculink_0a_s_axi_awvalid;

  wire [3:0]oculink_0a_s_axi_bid;
  wire oculink_0a_s_axi_bready;
  wire [1:0]oculink_0a_s_axi_bresp;
  wire oculink_0a_s_axi_bvalid;

  wire [255:0]oculink_0a_s_axi_rdata;
  wire [3:0]oculink_0a_s_axi_rid;
  wire oculink_0a_s_axi_rlast;
  wire oculink_0a_s_axi_rready;
  wire [1:0]oculink_0a_s_axi_rresp;
  wire oculink_0a_s_axi_rvalid;
  
  wire [255:0]oculink_0a_s_axi_wdata;
  wire oculink_0a_s_axi_wlast;
  wire oculink_0a_s_axi_wready;
  wire [31:0]oculink_0a_s_axi_wstrb;
  wire oculink_0a_s_axi_wvalid;

  // host bram interface
  logic [15:0]host_bram_addr;
  logic host_bram_clk;
  logic [31:0]host_bram_din;
  logic [31:0]host_bram_dout;
  logic host_bram_en;
  logic host_bram_rst;
  logic [3:0]host_bram_we;

  // default settings
  logic [3:0]oculink_0a_s_axi_arcache;
  logic [0:0]oculink_0a_s_axi_arlock;
  logic [2:0]oculink_0a_s_axi_arprot;
  logic [3:0]oculink_0a_s_axi_arqos;
  logic [3:0]oculink_0a_s_axi_awcache;
  logic [0:0]oculink_0a_s_axi_awlock;
  logic [2:0]oculink_0a_s_axi_awprot;
  logic [3:0]oculink_0a_s_axi_awqos;
  always_comb begin
      oculink_0a_s_axi_arcache = 0;
      oculink_0a_s_axi_arlock = 0;
      oculink_0a_s_axi_arprot = 0;
      oculink_0a_s_axi_arqos = 0;
      oculink_0a_s_axi_awcache = 0;
      oculink_0a_s_axi_awlock = 0;
      oculink_0a_s_axi_awprot = 0;
      oculink_0a_s_axi_awqos = 0; 
  end

  oculink_bd_wrapper oculink_bd_wrapper_i(
    .oculink_0a_mgt_rxn(oculink_0a_mgt_rxn),
    .oculink_0a_mgt_rxp(oculink_0a_mgt_rxp),
    .oculink_0a_mgt_txn(oculink_0a_mgt_txn),
    .oculink_0a_mgt_txp(oculink_0a_mgt_txp),
    .oculink_0a_ref_clk_n(oculink_0a_ref_clk_n),
    .oculink_0a_ref_clk_p(oculink_0a_ref_clk_p),
    .oculink_0a_rstn(oculink_0a_rstn),
    .host_mgt_rxn(host_mgt_rxn),
    .host_mgt_rxp(host_mgt_rxp),
    .host_mgt_txn(host_mgt_txn),
    .host_mgt_txp(host_mgt_txp),
    .host_ref_clk_n(host_ref_clk_n),
    .host_ref_clk_p(host_ref_clk_p),
    .host_rstn(host_rstn),
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
    .host_bram_addr(host_bram_addr),
    .host_bram_clk(host_bram_clk),
    .host_bram_din(host_bram_din),
    .host_bram_dout(host_bram_dout),
    .host_bram_en(host_bram_en),
    .host_bram_rst(host_bram_rst),
    .host_bram_we(host_bram_we),
    .oculink_0a_s_axi_araddr(oculink_0a_s_axi_araddr),
    .oculink_0a_s_axi_arburst(oculink_0a_s_axi_arburst),
    .oculink_0a_s_axi_arid(oculink_0a_s_axi_arid),
    .oculink_0a_s_axi_arlen(oculink_0a_s_axi_arlen),
    .oculink_0a_s_axi_arready(oculink_0a_s_axi_arready),
    // .oculink_0a_s_axi_arregion(oculink_0a_s_axi_arregion),
    .oculink_0a_s_axi_arsize(oculink_0a_s_axi_arsize),
    .oculink_0a_s_axi_arvalid(oculink_0a_s_axi_arvalid),
    .oculink_0a_s_axi_awaddr(oculink_0a_s_axi_awaddr),
    .oculink_0a_s_axi_awburst(oculink_0a_s_axi_awburst),
    .oculink_0a_s_axi_awid(oculink_0a_s_axi_awid),
    .oculink_0a_s_axi_awlen(oculink_0a_s_axi_awlen),
    .oculink_0a_s_axi_awready(oculink_0a_s_axi_awready),
    // .oculink_0a_s_axi_awregion(oculink_0a_s_axi_awregion),
    .oculink_0a_s_axi_awsize(oculink_0a_s_axi_awsize),
    .oculink_0a_s_axi_awvalid(oculink_0a_s_axi_awvalid),
    .oculink_0a_s_axi_bid(oculink_0a_s_axi_bid),
    .oculink_0a_s_axi_bready(oculink_0a_s_axi_bready),
    .oculink_0a_s_axi_bresp(oculink_0a_s_axi_bresp),
    .oculink_0a_s_axi_bvalid(oculink_0a_s_axi_bvalid),
    .oculink_0a_s_axi_rdata(oculink_0a_s_axi_rdata),
    .oculink_0a_s_axi_rid(oculink_0a_s_axi_rid),
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
    .oculink_0a_rstn(oculink_0a_rstn),
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
    .host_bram_addr(host_bram_addr),
    .host_bram_clk(host_bram_clk),
    .host_bram_din(host_bram_din),
    .host_bram_dout(host_bram_dout),
    .host_bram_en(host_bram_en),
    .host_bram_rst(host_bram_rst),
    .host_bram_we(host_bram_we),
    .oculink_0a_s_axi_araddr(oculink_0a_s_axi_araddr),
    .oculink_0a_s_axi_arburst(oculink_0a_s_axi_arburst),
    .oculink_0a_s_axi_arid(oculink_0a_s_axi_arid),
    .oculink_0a_s_axi_arlen(oculink_0a_s_axi_arlen),
    .oculink_0a_s_axi_arready(oculink_0a_s_axi_arready),
    .oculink_0a_s_axi_arregion(oculink_0a_s_axi_arregion),
    .oculink_0a_s_axi_arsize(oculink_0a_s_axi_arsize),
    .oculink_0a_s_axi_arvalid(oculink_0a_s_axi_arvalid),
    .oculink_0a_s_axi_awaddr(oculink_0a_s_axi_awaddr),
    .oculink_0a_s_axi_awburst(oculink_0a_s_axi_awburst),
    .oculink_0a_s_axi_awid(oculink_0a_s_axi_awid),
    .oculink_0a_s_axi_awlen(oculink_0a_s_axi_awlen),
    .oculink_0a_s_axi_awready(oculink_0a_s_axi_awready),
    .oculink_0a_s_axi_awregion(oculink_0a_s_axi_awregion),
    .oculink_0a_s_axi_awsize(oculink_0a_s_axi_awsize),
    .oculink_0a_s_axi_awvalid(oculink_0a_s_axi_awvalid),
    .oculink_0a_s_axi_bid(oculink_0a_s_axi_bid),
    .oculink_0a_s_axi_bready(oculink_0a_s_axi_bready),
    .oculink_0a_s_axi_bresp(oculink_0a_s_axi_bresp),
    .oculink_0a_s_axi_bvalid(oculink_0a_s_axi_bvalid),
    .oculink_0a_s_axi_rdata(oculink_0a_s_axi_rdata),
    .oculink_0a_s_axi_rid(oculink_0a_s_axi_rid),
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
