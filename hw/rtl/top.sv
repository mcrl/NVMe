
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
  input host_rstn,
  // ---- PL DDR4 (4 GB DDR4-2400, J19 300 MHz ref) ----
  input  c0_sys_clk_p,
  input  c0_sys_clk_n,
  output [16:0] c0_ddr4_adr,
  output [1:0]  c0_ddr4_ba,
  output [0:0]  c0_ddr4_bg,
  output [0:0]  c0_ddr4_cke,
  output [0:0]  c0_ddr4_odt,
  output [0:0]  c0_ddr4_cs_n,
  output        c0_ddr4_act_n,
  output [0:0]  c0_ddr4_ck_t,
  output [0:0]  c0_ddr4_ck_c,
  output        c0_ddr4_reset_n,
  inout  [71:0] c0_ddr4_dq,
  inout  [8:0]  c0_ddr4_dqs_t,
  inout  [8:0]  c0_ddr4_dqs_c,
  inout  [8:0]  c0_ddr4_dm_dbi_n
  );

  // PL DDR4 data path: user clock + cal + AXI between the ddr4_test wrapper and the kernel/nvme_driver
  logic        ddr4_ui_clk, ddr4_ui_rst, ddr4_cal_done, ddr4_cp_rstn;
  logic [31:0] m_ddr4_awaddr; logic [7:0] m_ddr4_awlen; logic m_ddr4_awvalid, m_ddr4_awready;
  logic [255:0] m_ddr4_wdata; logic m_ddr4_wlast, m_ddr4_wvalid, m_ddr4_wready;
  logic [1:0]  m_ddr4_bresp; logic m_ddr4_bvalid, m_ddr4_bready;
  logic [31:0] m_ddr4_araddr; logic [7:0] m_ddr4_arlen; logic m_ddr4_arvalid, m_ddr4_arready;
  logic [255:0] m_ddr4_rdata; logic m_ddr4_rlast, m_ddr4_rvalid, m_ddr4_rready; logic [1:0] m_ddr4_rresp;
  assign ddr4_cp_rstn = ddr4_cal_done & ~ddr4_ui_rst;   // copy engine runs only after calibration
  

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
  logic [19:0]host_bram_addr;
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
    .cp_clk(ddr4_ui_clk), .cp_rstn(ddr4_cp_rstn), .cal_done_raw(ddr4_cal_done),
    .ddr4_awaddr(m_ddr4_awaddr), .ddr4_awlen(m_ddr4_awlen), .ddr4_awvalid(m_ddr4_awvalid), .ddr4_awready(m_ddr4_awready),
    .ddr4_wdata(m_ddr4_wdata), .ddr4_wlast(m_ddr4_wlast), .ddr4_wvalid(m_ddr4_wvalid), .ddr4_wready(m_ddr4_wready),
    .ddr4_bresp(m_ddr4_bresp), .ddr4_bvalid(m_ddr4_bvalid), .ddr4_bready(m_ddr4_bready),
    .ddr4_araddr(m_ddr4_araddr), .ddr4_arlen(m_ddr4_arlen), .ddr4_arvalid(m_ddr4_arvalid), .ddr4_arready(m_ddr4_arready),
    .ddr4_rdata(m_ddr4_rdata), .ddr4_rlast(m_ddr4_rlast), .ddr4_rvalid(m_ddr4_rvalid), .ddr4_rready(m_ddr4_rready),
    .ddr4_rresp(m_ddr4_rresp),
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

  // ---- PL DDR4 wrapper: IP + AXI slave driven by nvme_driver's ddr4_engine master ----
  ddr4_test ddr4_test_i (
    .sys_clk_p (c0_sys_clk_p), .sys_clk_n (c0_sys_clk_n), .rstn (host_rstn),
    .ui_clk (ddr4_ui_clk), .ui_rst (ddr4_ui_rst), .cal_done (ddr4_cal_done),
    .s_awaddr(m_ddr4_awaddr), .s_awlen(m_ddr4_awlen), .s_awvalid(m_ddr4_awvalid), .s_awready(m_ddr4_awready),
    .s_wdata(m_ddr4_wdata), .s_wlast(m_ddr4_wlast), .s_wvalid(m_ddr4_wvalid), .s_wready(m_ddr4_wready),
    .s_bresp(m_ddr4_bresp), .s_bvalid(m_ddr4_bvalid), .s_bready(m_ddr4_bready),
    .s_araddr(m_ddr4_araddr), .s_arlen(m_ddr4_arlen), .s_arvalid(m_ddr4_arvalid), .s_arready(m_ddr4_arready),
    .s_rdata(m_ddr4_rdata), .s_rlast(m_ddr4_rlast), .s_rvalid(m_ddr4_rvalid), .s_rready(m_ddr4_rready), .s_rresp(m_ddr4_rresp),
    .c0_ddr4_adr(c0_ddr4_adr), .c0_ddr4_ba(c0_ddr4_ba), .c0_ddr4_bg(c0_ddr4_bg),
    .c0_ddr4_cke(c0_ddr4_cke), .c0_ddr4_odt(c0_ddr4_odt), .c0_ddr4_cs_n(c0_ddr4_cs_n),
    .c0_ddr4_act_n(c0_ddr4_act_n), .c0_ddr4_ck_t(c0_ddr4_ck_t), .c0_ddr4_ck_c(c0_ddr4_ck_c),
    .c0_ddr4_reset_n(c0_ddr4_reset_n), .c0_ddr4_dq(c0_ddr4_dq),
    .c0_ddr4_dqs_t(c0_ddr4_dqs_t), .c0_ddr4_dqs_c(c0_ddr4_dqs_c), .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n)
  );

endmodule
