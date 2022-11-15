module top (
  input logic [15:0] pcie_mgt_rxn,
  input logic [15:0] pcie_mgt_rxp,
  output logic [15:0] pcie_mgt_txn,
  output logic [15:0] pcie_mgt_txp,
  input logic pcie_perstn,
  input logic pcie_refclk_clk_n,
  input logic pcie_refclk_clk_p,
  input logic [3:0] ocu0_data_rxn;
  input logic [3:0] ocu0_data_rxp;
  output logic [3:0] ocu0_data_txn;
  output logic [3:0] ocu0_data_txp;
);

// 250MHz clk region from host PCIe IP
logic usr_clk;
logic usr_rstn;

// oculink PCIe IP share the same clk and rstn with host PCIe IP
logic ocu0_refclk_clk_n;
logic ocu0_refclk_clk_p;
logic ocu0_rstn;
assign ocu0_refclk_clk_n = pcie_refclk_clk_n;
assign ocu0_refclk_clk_p = pcie_refclk_clk_p;
assign ocu0_rstn = pcie_perstn;

// host -> kernel bram interface
logic [14:0] host_bram_addr;
logic host_bram_clk;
logic [31:0] host_bram_din;
logic [31:0] host_bram_dout;
logic host_bram_en;
logic host_bram_rst;
logic [3:0] host_bram_we;

// oculink -> kernel aximm
logic [63:0]ocu0_master_araddr;
logic [1:0]ocu0_master_arburst;
logic [3:0]ocu0_master_arcache;
logic [3:0]ocu0_master_arid;
logic [7:0]ocu0_master_arlen;
logic [0:0]ocu0_master_arlock;
logic [2:0]ocu0_master_arprot;
logic [3:0]ocu0_master_arqos;
logic ocu0_master_arready;
logic [3:0]ocu0_master_arregion;
logic [2:0]ocu0_master_arsize;
logic ocu0_master_arvalid;
logic [63:0]ocu0_master_awaddr;
logic [1:0]ocu0_master_awburst;
logic [3:0]ocu0_master_awcache;
logic [3:0]ocu0_master_awid;
logic [7:0]ocu0_master_awlen;
logic [0:0]ocu0_master_awlock;
logic [2:0]ocu0_master_awprot;
logic [3:0]ocu0_master_awqos;
logic ocu0_master_awready;
logic [3:0]ocu0_master_awregion;
logic [2:0]ocu0_master_awsize;
logic ocu0_master_awvalid;
logic [3:0]ocu0_master_bid;
logic ocu0_master_bready;
logic [1:0]ocu0_master_bresp;
logic ocu0_master_bvalid;
logic [127:0]ocu0_master_rdata;
logic [3:0]ocu0_master_rid;
logic ocu0_master_rlast;
logic ocu0_master_rready;
logic [1:0]ocu0_master_rresp;
logic ocu0_master_rvalid;
logic [127:0]ocu0_master_wdata;
logic ocu0_master_wlast;
logic ocu0_master_wready;
logic [15:0]ocu0_master_wstrb;
logic ocu0_master_wvalid;

// kernel -> oculink aximm
logic [63:0]ocu0_slave_araddr;
logic [1:0]ocu0_slave_arburst;
logic [3:0]ocu0_slave_arcache;
logic [3:0]ocu0_slave_arid;
logic [7:0]ocu0_slave_arlen;
logic [0:0]ocu0_slave_arlock;
logic [2:0]ocu0_slave_arprot;
logic [3:0]ocu0_slave_arqos;
logic ocu0_slave_arready;
logic [3:0]ocu0_slave_arregion;
logic [2:0]ocu0_slave_arsize;
logic ocu0_slave_arvalid;
logic [63:0]ocu0_slave_awaddr;
logic [1:0]ocu0_slave_awburst;
logic [3:0]ocu0_slave_awcache;
logic [3:0]ocu0_slave_awid;
logic [7:0]ocu0_slave_awlen;
logic [0:0]ocu0_slave_awlock;
logic [2:0]ocu0_slave_awprot;
logic [3:0]ocu0_slave_awqos;
logic ocu0_slave_awready;
logic [3:0]ocu0_slave_awregion;
logic [2:0]ocu0_slave_awsize;
logic ocu0_slave_awvalid;
logic [3:0]ocu0_slave_bid;
logic ocu0_slave_bready;
logic [1:0]ocu0_slave_bresp;
logic ocu0_slave_bvalid;
logic [127:0]ocu0_slave_rdata;
logic [3:0]ocu0_slave_rid;
logic ocu0_slave_rlast;
logic ocu0_slave_rready;
logic [1:0]ocu0_slave_rresp;
logic ocu0_slave_rvalid;
logic [127:0]ocu0_slave_wdata;
logic ocu0_slave_wlast;
logic ocu0_slave_wready;
logic [15:0]ocu0_slave_wstrb;
logic ocu0_slave_wvalid;

bd0 bd0_inst (
  .usr_clk(usr_clk),
  .usr_rstn(usr_rstn),
  .host_bram_addr(host_bram_addr),
  .host_bram_clk(host_bram_clk),
  .host_bram_din(host_bram_din),
  .host_bram_dout(host_bram_dout),
  .host_bram_en(host_bram_en),
  .host_bram_rst(host_bram_rst),
  .host_bram_we(host_bram_we),
  .pcie_mgt_rxn(pcie_mgt_rxn),
  .pcie_mgt_rxp(pcie_mgt_rxp),
  .pcie_mgt_txn(pcie_mgt_txn),
  .pcie_mgt_txp(pcie_mgt_txp),
  .pcie_perstn(pcie_perstn),
  .pcie_refclk_clk_n(pcie_refclk_clk_n),
  .pcie_refclk_clk_p(pcie_refclk_clk_p),
  .ocu0_data_rxn(ocu0_data_rxn),
  .ocu0_data_rxp(ocu0_data_rxp),
  .ocu0_data_txn(ocu0_data_txn),
  .ocu0_data_txp(ocu0_data_txp),
  .ocu0_master_araddr(ocu0_master_araddr),
  .ocu0_master_arburst(ocu0_master_arburst),
  .ocu0_master_arcache(ocu0_master_arcache),
  .ocu0_master_arid(ocu0_master_arid),
  .ocu0_master_arlen(ocu0_master_arlen),
  .ocu0_master_arlock(ocu0_master_arlock),
  .ocu0_master_arprot(ocu0_master_arprot),
  .ocu0_master_arqos(ocu0_master_arqos),
  .ocu0_master_arready(ocu0_master_arready),
  .ocu0_master_arregion(ocu0_master_arregion),
  .ocu0_master_arsize(ocu0_master_arsize),
  .ocu0_master_arvalid(ocu0_master_arvalid),
  .ocu0_master_awaddr(ocu0_master_awaddr),
  .ocu0_master_awburst(ocu0_master_awburst),
  .ocu0_master_awcache(ocu0_master_awcache),
  .ocu0_master_awid(ocu0_master_awid),
  .ocu0_master_awlen(ocu0_master_awlen),
  .ocu0_master_awlock(ocu0_master_awlock),
  .ocu0_master_awprot(ocu0_master_awprot),
  .ocu0_master_awqos(ocu0_master_awqos),
  .ocu0_master_awready(ocu0_master_awready),
  .ocu0_master_awregion(ocu0_master_awregion),
  .ocu0_master_awsize(ocu0_master_awsize),
  .ocu0_master_awvalid(ocu0_master_awvalid),
  .ocu0_master_bid(ocu0_master_bid),
  .ocu0_master_bready(ocu0_master_bready),
  .ocu0_master_bresp(ocu0_master_bresp),
  .ocu0_master_bvalid(ocu0_master_bvalid),
  .ocu0_master_rdata(ocu0_master_rdata),
  .ocu0_master_rid(ocu0_master_rid),
  .ocu0_master_rlast(ocu0_master_rlast),
  .ocu0_master_rready(ocu0_master_rready),
  .ocu0_master_rresp(ocu0_master_rresp),
  .ocu0_master_rvalid(ocu0_master_rvalid),
  .ocu0_master_wdata(ocu0_master_wdata),
  .ocu0_master_wlast(ocu0_master_wlast),
  .ocu0_master_wready(ocu0_master_wready),
  .ocu0_master_wstrb(ocu0_master_wstrb),
  .ocu0_master_wvalid(ocu0_master_wvalid),
  .ocu0_refclk_clk_n(ocu0_refclk_clk_n),
  .ocu0_refclk_clk_p(ocu0_refclk_clk_p),
  .ocu0_rstn(ocu0_rstn),
  .ocu0_slave_araddr(ocu0_slave_araddr),
  .ocu0_slave_arburst(ocu0_slave_arburst),
  .ocu0_slave_arcache(ocu0_slave_arcache),
  .ocu0_slave_arid(ocu0_slave_arid),
  .ocu0_slave_arlen(ocu0_slave_arlen),
  .ocu0_slave_arlock(ocu0_slave_arlock),
  .ocu0_slave_arprot(ocu0_slave_arprot),
  .ocu0_slave_arqos(ocu0_slave_arqos),
  .ocu0_slave_arready(ocu0_slave_arready),
  .ocu0_slave_arregion(ocu0_slave_arregion),
  .ocu0_slave_arsize(ocu0_slave_arsize),
  .ocu0_slave_arvalid(ocu0_slave_arvalid),
  .ocu0_slave_awaddr(ocu0_slave_awaddr),
  .ocu0_slave_awburst(ocu0_slave_awburst),
  .ocu0_slave_awcache(ocu0_slave_awcache),
  .ocu0_slave_awid(ocu0_slave_awid),
  .ocu0_slave_awlen(ocu0_slave_awlen),
  .ocu0_slave_awlock(ocu0_slave_awlock),
  .ocu0_slave_awprot(ocu0_slave_awprot),
  .ocu0_slave_awqos(ocu0_slave_awqos),
  .ocu0_slave_awready(ocu0_slave_awready),
  .ocu0_slave_awregion(ocu0_slave_awregion),
  .ocu0_slave_awsize(ocu0_slave_awsize),
  .ocu0_slave_awvalid(ocu0_slave_awvalid),
  .ocu0_slave_bid(ocu0_slave_bid),
  .ocu0_slave_bready(ocu0_slave_bready),
  .ocu0_slave_bresp(ocu0_slave_bresp),
  .ocu0_slave_bvalid(ocu0_slave_bvalid),
  .ocu0_slave_rdata(ocu0_slave_rdata),
  .ocu0_slave_rid(ocu0_slave_rid),
  .ocu0_slave_rlast(ocu0_slave_rlast),
  .ocu0_slave_rready(ocu0_slave_rready),
  .ocu0_slave_rresp(ocu0_slave_rresp),
  .ocu0_slave_rvalid(ocu0_slave_rvalid),
  .ocu0_slave_wdata(ocu0_slave_wdata),
  .ocu0_slave_wlast(ocu0_slave_wlast),
  .ocu0_slave_wready(ocu0_slave_wready),
  .ocu0_slave_wstrb(ocu0_slave_wstrb),
  .ocu0_slave_wvalid(ocu0_slave_wvalid)
);

kernel kernel_inst (
  .clk(usr_clk),
  .rstn(usr_rstn),
  .host_addr(host_bram_addr),
  .host_clk(host_bram_clk),
  .host_din(host_bram_din),
  .host_dout(host_bram_dout),
  .host_en(host_bram_en),
  .host_rst(host_bram_rst),
  .host_we(host_bram_we),
  .o2k_araddr(ocu0_master_araddr),
  .o2k_arburst(ocu0_master_arburst),
  .o2k_arcache(ocu0_master_arcache),
  .o2k_arid(ocu0_master_arid),
  .o2k_arlen(ocu0_master_arlen),
  .o2k_arlock(ocu0_master_arlock),
  .o2k_arprot(ocu0_master_arprot),
  .o2k_arqos(ocu0_master_arqos),
  .o2k_arready(ocu0_master_arready),
  .o2k_arregion(ocu0_master_arregion),
  .o2k_arsize(ocu0_master_arsize),
  .o2k_arvalid(ocu0_master_arvalid),
  .o2k_awaddr(ocu0_master_awaddr),
  .o2k_awburst(ocu0_master_awburst),
  .o2k_awcache(ocu0_master_awcache),
  .o2k_awid(ocu0_master_awid),
  .o2k_awlen(ocu0_master_awlen),
  .o2k_awlock(ocu0_master_awlock),
  .o2k_awprot(ocu0_master_awprot),
  .o2k_awqos(ocu0_master_awqos),
  .o2k_awready(ocu0_master_awready),
  .o2k_awregion(ocu0_master_awregion),
  .o2k_awsize(ocu0_master_awsize),
  .o2k_awvalid(ocu0_master_awvalid),
  .o2k_bid(ocu0_master_bid),
  .o2k_bready(ocu0_master_bready),
  .o2k_bresp(ocu0_master_bresp),
  .o2k_bvalid(ocu0_master_bvalid),
  .o2k_rdata(ocu0_master_rdata),
  .o2k_rid(ocu0_master_rid),
  .o2k_rlast(ocu0_master_rlast),
  .o2k_rready(ocu0_master_rready),
  .o2k_rresp(ocu0_master_rresp),
  .o2k_rvalid(ocu0_master_rvalid),
  .o2k_wdata(ocu0_master_wdata),
  .o2k_wlast(ocu0_master_wlast),
  .o2k_wready(ocu0_master_wready),
  .o2k_wstrb(ocu0_master_wstrb),
  .o2k_wvalid(ocu0_master_wvalid),
  .k2o_araddr(ocu0_slave_araddr),
  .k2o_arburst(ocu0_slave_arburst),
  .k2o_arcache(ocu0_slave_arcache),
  .k2o_arid(ocu0_slave_arid),
  .k2o_arlen(ocu0_slave_arlen),
  .k2o_arlock(ocu0_slave_arlock),
  .k2o_arprot(ocu0_slave_arprot),
  .k2o_arqos(ocu0_slave_arqos),
  .k2o_arready(ocu0_slave_arready),
  .k2o_arregion(ocu0_slave_arregion),
  .k2o_arsize(ocu0_slave_arsize),
  .k2o_arvalid(ocu0_slave_arvalid),
  .k2o_awaddr(ocu0_slave_awaddr),
  .k2o_awburst(ocu0_slave_awburst),
  .k2o_awcache(ocu0_slave_awcache),
  .k2o_awid(ocu0_slave_awid),
  .k2o_awlen(ocu0_slave_awlen),
  .k2o_awlock(ocu0_slave_awlock),
  .k2o_awprot(ocu0_slave_awprot),
  .k2o_awqos(ocu0_slave_awqos),
  .k2o_awready(ocu0_slave_awready),
  .k2o_awregion(ocu0_slave_awregion),
  .k2o_awsize(ocu0_slave_awsize),
  .k2o_awvalid(ocu0_slave_awvalid),
  .k2o_bid(ocu0_slave_bid),
  .k2o_bready(ocu0_slave_bready),
  .k2o_bresp(ocu0_slave_bresp),
  .k2o_bvalid(ocu0_slave_bvalid),
  .k2o_rdata(ocu0_slave_rdata),
  .k2o_rid(ocu0_slave_rid),
  .k2o_rlast(ocu0_slave_rlast),
  .k2o_rready(ocu0_slave_rready),
  .k2o_rresp(ocu0_slave_rresp),
  .k2o_rvalid(ocu0_slave_rvalid),
  .k2o_wdata(ocu0_slave_wdata),
  .k2o_wlast(ocu0_slave_wlast),
  .k2o_wready(ocu0_slave_wready),
  .k2o_wstrb(ocu0_slave_wstrb),
  .k2o_wvalid(ocu0_slave_wvalid)
);

endmodule
