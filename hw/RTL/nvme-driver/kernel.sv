module kernel(

  // host bram interface
  input [15:0]host_bram_addr,
  input host_bram_clk,
  input [31:0]host_bram_din,
  output logic [31:0]host_bram_dout,
  input host_bram_en,
  input host_bram_rst,
  input [3:0]host_bram_we,

  // oculink interface
  input oculink_0a_rstn,
  input oculink_0a_axi_aclk,

  // oculink master
  input [31:0]oculink_0a_m_axi_araddr,
  input [1:0]oculink_0a_m_axi_arburst,
  input [3:0]oculink_0a_m_axi_arcache,
  input [3:0]oculink_0a_m_axi_arid,
  input [7:0]oculink_0a_m_axi_arlen,
  input oculink_0a_m_axi_arlock,
  input [2:0]oculink_0a_m_axi_arprot,
  output logic oculink_0a_m_axi_arready,
  input [2:0]oculink_0a_m_axi_arsize,
  input oculink_0a_m_axi_arvalid,
  input [31:0]oculink_0a_m_axi_awaddr,
  input [1:0]oculink_0a_m_axi_awburst,
  input [3:0]oculink_0a_m_axi_awcache,
  input [3:0]oculink_0a_m_axi_awid,
  input [7:0]oculink_0a_m_axi_awlen,
  input oculink_0a_m_axi_awlock,
  input [2:0]oculink_0a_m_axi_awprot,
  output logic oculink_0a_m_axi_awready,
  input [2:0]oculink_0a_m_axi_awsize,
  input oculink_0a_m_axi_awvalid,
  output logic [3:0]oculink_0a_m_axi_bid,
  input oculink_0a_m_axi_bready,
  output logic [1:0]oculink_0a_m_axi_bresp,
  output logic oculink_0a_m_axi_bvalid,
  output logic [255:0]oculink_0a_m_axi_rdata,
  output logic [3:0]oculink_0a_m_axi_rid,
  output logic oculink_0a_m_axi_rlast,
  input oculink_0a_m_axi_rready,
  output logic [1:0]oculink_0a_m_axi_rresp,
  output logic oculink_0a_m_axi_rvalid,
  input [255:0]oculink_0a_m_axi_wdata,
  input oculink_0a_m_axi_wlast,
  output logic oculink_0a_m_axi_wready,
  input [15:0]oculink_0a_m_axi_wstrb,
  input oculink_0a_m_axi_wvalid,

  // oculink slave
  output logic [31:0]oculink_0a_s_axi_araddr,
  output logic [1:0]oculink_0a_s_axi_arburst,
  output logic [3:0]oculink_0a_s_axi_arid,
  output logic [7:0]oculink_0a_s_axi_arlen,
  input oculink_0a_s_axi_arready,
  output logic [3:0]oculink_0a_s_axi_arregion,
  output logic [2:0]oculink_0a_s_axi_arsize,
  output logic oculink_0a_s_axi_arvalid,
  output logic [31:0]oculink_0a_s_axi_awaddr,
  output logic [1:0]oculink_0a_s_axi_awburst,
  output logic [3:0]oculink_0a_s_axi_awid,
  output logic [7:0]oculink_0a_s_axi_awlen,
  input oculink_0a_s_axi_awready,
  output logic [3:0]oculink_0a_s_axi_awregion,
  output logic [2:0]oculink_0a_s_axi_awsize,
  output logic oculink_0a_s_axi_awvalid,
  input [3:0]oculink_0a_s_axi_bid,
  output logic oculink_0a_s_axi_bready,
  input [1:0]oculink_0a_s_axi_bresp,
  input oculink_0a_s_axi_bvalid,
  input [255:0]oculink_0a_s_axi_rdata,
  input [3:0]oculink_0a_s_axi_rid,
  input oculink_0a_s_axi_rlast,
  output logic oculink_0a_s_axi_rready,
  input [1:0]oculink_0a_s_axi_rresp,
  input oculink_0a_s_axi_rvalid,
  output logic [255:0]oculink_0a_s_axi_wdata,
  output logic oculink_0a_s_axi_wlast,
  input oculink_0a_s_axi_wready,
  output logic [31:0]oculink_0a_s_axi_wstrb,
  output logic oculink_0a_s_axi_wvalid
  );

  logic sw_reset;

  // csr <-> nvme driver
  // ar
  logic [31:0]  s_axi_araddr;
  logic [1:0]   s_axi_arburst;
  logic [3:0]   s_axi_arid;
  logic [7:0]   s_axi_arlen;
  logic [3:0]   s_axi_arregion;
  logic [2:0]   s_axi_arsize;
  logic         s_axi_arvalid;
  logic         s_axi_ar_fifo_full;
  logic         s_axi_ar_fifo_empty;

  // aw
  logic [31:0]  s_axi_awaddr;
  logic [1:0]   s_axi_awburst;
  logic [3:0]   s_axi_awid;
  logic [7:0]   s_axi_awlen;
  logic [3:0]   s_axi_awregion;
  logic [2:0]   s_axi_awsize;
  logic         s_axi_awvalid;
  logic         s_axi_aw_fifo_full;
  logic         s_axi_aw_fifo_empty;

  // w
  logic [255:0] s_axi_wdata;
  logic         s_axi_wlast;
  logic [31:0]  s_axi_wstrb;
  logic         s_axi_wvalid;
  logic         s_axi_w_fifo_full;
  logic         s_axi_w_fifo_empty;

  // r
  logic [255:0] s_axi_rdata;
  logic [3:0]   s_axi_rid;
  logic         s_axi_rlast;
  logic [1:0]   s_axi_rresp;
  logic         s_axi_rvalid;
  logic         s_axi_r_fifo_pop;
  logic         s_axi_r_fifo_empty;
  logic         s_axi_r_fifo_full;

  // b
  logic [3:0]   s_axi_bid;
  logic [1:0]   s_axi_bresp;
  logic         s_axi_bvalid;
  logic         s_axi_b_fifo_pop;
  logic         s_axi_b_fifo_empty;
  logic         s_axi_b_fifo_full;

  // ar
  logic m_axi_ar_fifo_pop;
  logic m_axi_ar_fifo_valid;
  logic m_axi_ar_fifo_empty;
  logic m_axi_ar_fifo_full;
  logic [31:0]m_axi_araddr;
  logic [1:0]m_axi_arburst;
  logic [3:0]m_axi_arid;
  logic [7:0]m_axi_arlen;
  logic [2:0]m_axi_arsize;

  // aw
  logic m_axi_aw_fifo_pop;
  logic m_axi_aw_fifo_valid;
  logic m_axi_aw_fifo_empty;
  logic m_axi_aw_fifo_full;
  logic [31:0]m_axi_awaddr;
  logic [1:0]m_axi_awburst;
  logic [3:0]m_axi_awid;
  logic [7:0]m_axi_awlen;
  logic [2:0]m_axi_awsize;

  // w
  logic m_axi_w_fifo_pop;
  logic m_axi_w_fifo_valid;
  logic m_axi_w_fifo_empty;
  logic m_axi_w_fifo_full;
  logic [255:0]m_axi_wdata;
  logic m_axi_wlast;
  logic [31:0]m_axi_wstrb;

  // r
  logic [255:0]m_axi_rdata;
  logic [3:0]m_axi_rid;
  logic m_axi_rlast;
  logic [1:0]m_axi_rresp;
  logic m_axi_rvalid;
  logic m_axi_r_fifo_full;
  logic m_axi_r_fifo_empty;

  // b
  logic [3:0]m_axi_bid;
  logic [1:0]m_axi_bresp;
  logic m_axi_bvalid;
  logic m_axi_b_fifo_full;
  logic m_axi_b_fifo_empt;

  logic nvme_setting_done;
  logic do_write;
  logic do_read;

  // oculink bd <-> driver
  logic [31:0]oculink_0a_m_axi_araddr_driver;
  logic [1:0]oculink_0a_m_axi_arburst_driver;
  logic [3:0]oculink_0a_m_axi_arcache_driver;
  logic [3:0]oculink_0a_m_axi_arid_driver;
  logic [7:0]oculink_0a_m_axi_arlen_driver;
  logic oculink_0a_m_axi_arlock_driver;
  logic [2:0]oculink_0a_m_axi_arprot_driver;
  logic oculink_0a_m_axi_arready_driver;
  logic [2:0]oculink_0a_m_axi_arsize_driver;
  logic oculink_0a_m_axi_arvalid_driver;
  logic [31:0]oculink_0a_m_axi_awaddr_driver;
  logic [1:0]oculink_0a_m_axi_awburst_driver;
  logic [3:0]oculink_0a_m_axi_awcache_driver;
  logic [3:0]oculink_0a_m_axi_awid_driver;
  logic [7:0]oculink_0a_m_axi_awlen_driver;
  logic oculink_0a_m_axi_awlock_driver;
  logic [2:0]oculink_0a_m_axi_awprot_driver;
  logic oculink_0a_m_axi_awready_driver;
  logic [2:0]oculink_0a_m_axi_awsize_driver;
  logic oculink_0a_m_axi_awvalid_driver;
  logic [3:0]oculink_0a_m_axi_bid_driver;
  logic oculink_0a_m_axi_bready_driver;
  logic [1:0]oculink_0a_m_axi_bresp_driver;
  logic oculink_0a_m_axi_bvalid_driver;
  logic [255:0]oculink_0a_m_axi_rdata_driver;
  logic [3:0]oculink_0a_m_axi_rid_driver;
  logic oculink_0a_m_axi_rlast_driver;
  logic oculink_0a_m_axi_rready_driver;
  logic [1:0]oculink_0a_m_axi_rresp_driver;
  logic oculink_0a_m_axi_rvalid_driver;
  logic [255:0]oculink_0a_m_axi_wdata_driver;
  logic oculink_0a_m_axi_wlast_driver;
  logic oculink_0a_m_axi_wready_driver;
  logic [15:0]oculink_0a_m_axi_wstrb_driver;
  logic oculink_0a_m_axi_wvalid_driver;
  logic [31:0]oculink_0a_s_axi_araddr_driver;
  logic [1:0]oculink_0a_s_axi_arburst_driver;
  logic [3:0]oculink_0a_s_axi_arid_driver;
  logic [7:0]oculink_0a_s_axi_arlen_driver;
  logic oculink_0a_s_axi_arready_driver;
  logic [3:0]oculink_0a_s_axi_arregion_driver;
  logic [2:0]oculink_0a_s_axi_arsize_driver;
  logic oculink_0a_s_axi_arvalid_driver;
  logic [31:0]oculink_0a_s_axi_awaddr_driver;
  logic [1:0]oculink_0a_s_axi_awburst_driver;
  logic [3:0]oculink_0a_s_axi_awid_driver;
  logic [7:0]oculink_0a_s_axi_awlen_driver;
  logic oculink_0a_s_axi_awready_driver;
  logic [3:0]oculink_0a_s_axi_awregion_driver;
  logic [2:0]oculink_0a_s_axi_awsize_driver;
  logic oculink_0a_s_axi_awvalid_driver;
  logic [3:0]oculink_0a_s_axi_bid_driver;
  logic oculink_0a_s_axi_bready_driver;
  logic [1:0]oculink_0a_s_axi_bresp_driver;
  logic oculink_0a_s_axi_bvalid_driver;
  logic [255:0]oculink_0a_s_axi_rdata_driver;
  logic [3:0]oculink_0a_s_axi_rid_driver;
  logic oculink_0a_s_axi_rlast_driver;
  logic oculink_0a_s_axi_rready_driver;
  logic [1:0]oculink_0a_s_axi_rresp_driver;
  logic oculink_0a_s_axi_rvalid_driver;
  logic [255:0]oculink_0a_s_axi_wdata_driver;
  logic oculink_0a_s_axi_wlast_driver;
  logic oculink_0a_s_axi_wready_driver;
  logic [31:0]oculink_0a_s_axi_wstrb_driver;
  logic oculink_0a_s_axi_wvalid_driver;

  // oculink bd <-> io
  logic [31:0]oculink_0a_m_axi_araddr_io;
  logic [1:0]oculink_0a_m_axi_arburst_io;
  logic [3:0]oculink_0a_m_axi_arcache_io;
  logic [3:0]oculink_0a_m_axi_arid_io;
  logic [7:0]oculink_0a_m_axi_arlen_io;
  logic oculink_0a_m_axi_arlock_io;
  logic [2:0]oculink_0a_m_axi_arprot_io;
  logic oculink_0a_m_axi_arready_io;
  logic [2:0]oculink_0a_m_axi_arsize_io;
  logic oculink_0a_m_axi_arvalid_io;
  logic [31:0]oculink_0a_m_axi_awaddr_io;
  logic [1:0]oculink_0a_m_axi_awburst_io;
  logic [3:0]oculink_0a_m_axi_awcache_io;
  logic [3:0]oculink_0a_m_axi_awid_io;
  logic [7:0]oculink_0a_m_axi_awlen_io;
  logic oculink_0a_m_axi_awlock_io;
  logic [2:0]oculink_0a_m_axi_awprot_io;
  logic oculink_0a_m_axi_awready_io;
  logic [2:0]oculink_0a_m_axi_awsize_io;
  logic oculink_0a_m_axi_awvalid_io;
  logic [3:0]oculink_0a_m_axi_bid_io;
  logic oculink_0a_m_axi_bready_io;
  logic [1:0]oculink_0a_m_axi_bresp_io;
  logic oculink_0a_m_axi_bvalid_io;
  logic [255:0]oculink_0a_m_axi_rdata_io;
  logic [3:0]oculink_0a_m_axi_rid_io;
  logic oculink_0a_m_axi_rlast_io;
  logic oculink_0a_m_axi_rready_io;
  logic [1:0]oculink_0a_m_axi_rresp_io;
  logic oculink_0a_m_axi_rvalid_io;
  logic [255:0]oculink_0a_m_axi_wdata_io;
  logic oculink_0a_m_axi_wlast_io;
  logic oculink_0a_m_axi_wready_io;
  logic [15:0]oculink_0a_m_axi_wstrb_io;
  logic oculink_0a_m_axi_wvalid_io;
  logic [31:0]oculink_0a_s_axi_araddr_io;
  logic [1:0]oculink_0a_s_axi_arburst_io;
  logic [3:0]oculink_0a_s_axi_arid_io;
  logic [7:0]oculink_0a_s_axi_arlen_io;
  logic oculink_0a_s_axi_arready_io;
  logic [3:0]oculink_0a_s_axi_arregion_io;
  logic [2:0]oculink_0a_s_axi_arsize_io;
  logic oculink_0a_s_axi_arvalid_io;
  logic [31:0]oculink_0a_s_axi_awaddr_io;
  logic [1:0]oculink_0a_s_axi_awburst_io;
  logic [3:0]oculink_0a_s_axi_awid_io;
  logic [7:0]oculink_0a_s_axi_awlen_io;
  logic oculink_0a_s_axi_awready_io;
  logic [3:0]oculink_0a_s_axi_awregion_io;
  logic [2:0]oculink_0a_s_axi_awsize_io;
  logic oculink_0a_s_axi_awvalid_io;
  logic [3:0]oculink_0a_s_axi_bid_io;
  logic oculink_0a_s_axi_bready_io;
  logic [1:0]oculink_0a_s_axi_bresp_io;
  logic oculink_0a_s_axi_bvalid_io;
  logic [255:0]oculink_0a_s_axi_rdata_io;
  logic [3:0]oculink_0a_s_axi_rid_io;
  logic oculink_0a_s_axi_rlast_io;
  logic oculink_0a_s_axi_rready_io;
  logic [1:0]oculink_0a_s_axi_rresp_io;
  logic oculink_0a_s_axi_rvalid_io;
  logic [255:0]oculink_0a_s_axi_wdata_io;
  logic oculink_0a_s_axi_wlast_io;
  logic oculink_0a_s_axi_wready_io;
  logic [31:0]oculink_0a_s_axi_wstrb_io;
  logic oculink_0a_s_axi_wvalid_io;

  // bd <-> driver mux
  assign oculink_0a_m_axi_araddr_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_araddr;
  assign oculink_0a_m_axi_arburst_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_arburst;
  assign oculink_0a_m_axi_arcache_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_arcache;
  assign oculink_0a_m_axi_arid_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_arid;
  assign oculink_0a_m_axi_arlen_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_arlen;
  assign oculink_0a_m_axi_arlock_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_arlock;
  assign oculink_0a_m_axi_arprot_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_arprot;
  assign oculink_0a_m_axi_arsize_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_arsize;
  assign oculink_0a_m_axi_arvalid_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_arvalid;
  assign oculink_0a_m_axi_awaddr_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_awaddr;
  assign oculink_0a_m_axi_awburst_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_awburst;
  assign oculink_0a_m_axi_awcache_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_awcache;
  assign oculink_0a_m_axi_awid_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_awid;
  assign oculink_0a_m_axi_awlen_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_awlen;
  assign oculink_0a_m_axi_awlock_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_awlock;
  assign oculink_0a_m_axi_awprot_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_awprot;
  assign oculink_0a_m_axi_awsize_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_awsize;
  assign oculink_0a_m_axi_awvalid_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_awvalid;
  assign oculink_0a_m_axi_bready_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_bready;
  assign oculink_0a_m_axi_rready_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_rready;
  assign oculink_0a_m_axi_wdata_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_wdata;
  assign oculink_0a_m_axi_wlast_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_wlast;
  assign oculink_0a_m_axi_wstrb_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_wstrb;
  assign oculink_0a_m_axi_wvalid_driver = nvme_setting_done ? 0 : oculink_0a_m_axi_wvalid;

  assign oculink_0a_m_axi_araddr_io = nvme_setting_done ? oculink_0a_m_axi_araddr : 0;
  assign oculink_0a_m_axi_arburst_io = nvme_setting_done ? oculink_0a_m_axi_arburst : 0;
  assign oculink_0a_m_axi_arcache_io = nvme_setting_done ? oculink_0a_m_axi_arcache : 0;
  assign oculink_0a_m_axi_arid_io = nvme_setting_done ? oculink_0a_m_axi_arid : 0;
  assign oculink_0a_m_axi_arlen_io = nvme_setting_done ? oculink_0a_m_axi_arlen : 0;
  assign oculink_0a_m_axi_arlock_io = nvme_setting_done ? oculink_0a_m_axi_arlock : 0;
  assign oculink_0a_m_axi_arprot_io = nvme_setting_done ? oculink_0a_m_axi_arprot : 0;
  assign oculink_0a_m_axi_arsize_io = nvme_setting_done ? oculink_0a_m_axi_arsize : 0;
  assign oculink_0a_m_axi_arvalid_io = nvme_setting_done ? oculink_0a_m_axi_arvalid : 0;
  assign oculink_0a_m_axi_awaddr_io = nvme_setting_done ? oculink_0a_m_axi_awaddr : 0;
  assign oculink_0a_m_axi_awburst_io = nvme_setting_done ? oculink_0a_m_axi_awburst : 0;
  assign oculink_0a_m_axi_awcache_io = nvme_setting_done ? oculink_0a_m_axi_awcache : 0;
  assign oculink_0a_m_axi_awid_io = nvme_setting_done ? oculink_0a_m_axi_awid : 0;
  assign oculink_0a_m_axi_awlen_io = nvme_setting_done ? oculink_0a_m_axi_awlen : 0;
  assign oculink_0a_m_axi_awlock_io = nvme_setting_done ? oculink_0a_m_axi_awlock : 0;
  assign oculink_0a_m_axi_awprot_io = nvme_setting_done ? oculink_0a_m_axi_awprot : 0;
  assign oculink_0a_m_axi_awsize_io = nvme_setting_done ? oculink_0a_m_axi_awsize : 0;
  assign oculink_0a_m_axi_awvalid_io = nvme_setting_done ? oculink_0a_m_axi_awvalid : 0;
  assign oculink_0a_m_axi_bready_io = nvme_setting_done ? oculink_0a_m_axi_bready : 0;
  assign oculink_0a_m_axi_rready_io = nvme_setting_done ? oculink_0a_m_axi_rready : 0;
  assign oculink_0a_m_axi_wdata_io = nvme_setting_done ? oculink_0a_m_axi_wdata : 0;
  assign oculink_0a_m_axi_wlast_io = nvme_setting_done ? oculink_0a_m_axi_wlast : 0;
  assign oculink_0a_m_axi_wstrb_io = nvme_setting_done ? oculink_0a_m_axi_wstrb : 0;
  assign oculink_0a_m_axi_wvalid_io = nvme_setting_done ? oculink_0a_m_axi_wvalid : 0;
  
  assign oculink_0a_m_axi_arready = nvme_setting_done ? oculink_0a_m_axi_arready_io : oculink_0a_m_axi_arready_driver;
  assign oculink_0a_m_axi_awready = nvme_setting_done ? oculink_0a_m_axi_awready_io : oculink_0a_m_axi_awready_driver;
  assign oculink_0a_m_axi_bid = nvme_setting_done ? oculink_0a_m_axi_bid_io : oculink_0a_m_axi_bid_driver;
  assign oculink_0a_m_axi_bresp = nvme_setting_done ? oculink_0a_m_axi_bresp_io : oculink_0a_m_axi_bresp_driver;
  assign oculink_0a_m_axi_bvalid = nvme_setting_done ? oculink_0a_m_axi_bvalid_io : oculink_0a_m_axi_bvalid_driver;
  assign oculink_0a_m_axi_rdata = nvme_setting_done ? oculink_0a_m_axi_rdata_io : oculink_0a_m_axi_rdata_driver;
  assign oculink_0a_m_axi_rid = nvme_setting_done ? oculink_0a_m_axi_rid_io : oculink_0a_m_axi_rid_driver;
  assign oculink_0a_m_axi_rlast = nvme_setting_done ? oculink_0a_m_axi_rlast_io : oculink_0a_m_axi_rlast_driver;
  assign oculink_0a_m_axi_rresp = nvme_setting_done ? oculink_0a_m_axi_rresp_io : oculink_0a_m_axi_rresp_driver;
  assign oculink_0a_m_axi_rvalid = nvme_setting_done ? oculink_0a_m_axi_rvalid_io : oculink_0a_m_axi_rvalid_driver;
  assign oculink_0a_m_axi_wready = nvme_setting_done ? oculink_0a_m_axi_wready_io : oculink_0a_m_axi_wready_driver;

  assign oculink_0a_s_axi_araddr = nvme_setting_done ? oculink_0a_s_axi_araddr_io : oculink_0a_s_axi_araddr_driver;
  assign oculink_0a_s_axi_arburst = nvme_setting_done ? oculink_0a_s_axi_arburst_io : oculink_0a_s_axi_arburst_driver;
  assign oculink_0a_s_axi_arid = nvme_setting_done ? oculink_0a_s_axi_arid_io : oculink_0a_s_axi_arid_driver;
  assign oculink_0a_s_axi_arlen = nvme_setting_done ? oculink_0a_s_axi_arlen_io : oculink_0a_s_axi_arlen_driver;
  assign oculink_0a_s_axi_arregion = nvme_setting_done ? oculink_0a_s_axi_arregion_io : oculink_0a_s_axi_arregion_driver;
  assign oculink_0a_s_axi_arsize = nvme_setting_done ? oculink_0a_s_axi_arsize_io : oculink_0a_s_axi_arsize_driver;
  assign oculink_0a_s_axi_arvalid = nvme_setting_done ? oculink_0a_s_axi_arvalid_io : oculink_0a_s_axi_arvalid_driver;
  assign oculink_0a_s_axi_awaddr = nvme_setting_done ? oculink_0a_s_axi_awaddr_io : oculink_0a_s_axi_awaddr_driver;
  assign oculink_0a_s_axi_awburst = nvme_setting_done ? oculink_0a_s_axi_awburst_io : oculink_0a_s_axi_awburst_driver;
  assign oculink_0a_s_axi_awid = nvme_setting_done ? oculink_0a_s_axi_awid_io : oculink_0a_s_axi_awid_driver;
  assign oculink_0a_s_axi_awlen = nvme_setting_done ? oculink_0a_s_axi_awlen_io : oculink_0a_s_axi_awlen_driver;
  assign oculink_0a_s_axi_awregion = nvme_setting_done ? oculink_0a_s_axi_awregion_io : oculink_0a_s_axi_awregion_driver;
  assign oculink_0a_s_axi_awsize = nvme_setting_done ? oculink_0a_s_axi_awsize_io : oculink_0a_s_axi_awsize_driver;
  assign oculink_0a_s_axi_awvalid = nvme_setting_done ? oculink_0a_s_axi_awvalid_io : oculink_0a_s_axi_awvalid_driver;
  assign oculink_0a_s_axi_bready = nvme_setting_done ? oculink_0a_s_axi_bready_io : oculink_0a_s_axi_bready_driver;
  assign oculink_0a_s_axi_rready = nvme_setting_done ? oculink_0a_s_axi_rready_io : oculink_0a_s_axi_rready_driver;
  assign oculink_0a_s_axi_wdata = nvme_setting_done ? oculink_0a_s_axi_wdata_io : oculink_0a_s_axi_wdata_driver;
  assign oculink_0a_s_axi_wlast = nvme_setting_done ? oculink_0a_s_axi_wlast_io : oculink_0a_s_axi_wlast_driver;
  assign oculink_0a_s_axi_wstrb = nvme_setting_done ? oculink_0a_s_axi_wstrb_io : oculink_0a_s_axi_wstrb_driver;
  assign oculink_0a_s_axi_wvalid = nvme_setting_done ? oculink_0a_s_axi_wvalid_io : oculink_0a_s_axi_wvalid_driver;
  
  assign oculink_0a_s_axi_arready_driver = nvme_setting_done ? 0 : oculink_0a_s_axi_arready;
  assign oculink_0a_s_axi_awready_driver = nvme_setting_done ? 0 : oculink_0a_s_axi_awready;
  assign oculink_0a_s_axi_bid_driver = nvme_setting_done ? 0 : oculink_0a_s_axi_bid;
  assign oculink_0a_s_axi_bresp_driver = nvme_setting_done ? 0 : oculink_0a_s_axi_bresp;
  assign oculink_0a_s_axi_bvalid_driver = nvme_setting_done ? 0 : oculink_0a_s_axi_bvalid;
  assign oculink_0a_s_axi_rdata_driver = nvme_setting_done ? 0 : oculink_0a_s_axi_rdata;
  assign oculink_0a_s_axi_rid_driver = nvme_setting_done ? 0 : oculink_0a_s_axi_rid;
  assign oculink_0a_s_axi_rlast_driver = nvme_setting_done ? 0 : oculink_0a_s_axi_rlast;
  assign oculink_0a_s_axi_rresp_driver = nvme_setting_done ? 0 : oculink_0a_s_axi_rresp;
  assign oculink_0a_s_axi_rvalid_driver = nvme_setting_done ? 0 : oculink_0a_s_axi_rvalid;
  assign oculink_0a_s_axi_wready_driver = nvme_setting_done ? 0 : oculink_0a_s_axi_wready;
  
  assign oculink_0a_s_axi_arready_io = nvme_setting_done ? oculink_0a_s_axi_arready : 0;
  assign oculink_0a_s_axi_awready_io = nvme_setting_done ? oculink_0a_s_axi_awready : 0;
  assign oculink_0a_s_axi_bid_io = nvme_setting_done ? oculink_0a_s_axi_bid : 0;
  assign oculink_0a_s_axi_bresp_io = nvme_setting_done ? oculink_0a_s_axi_bresp : 0;
  assign oculink_0a_s_axi_bvalid_io = nvme_setting_done ? oculink_0a_s_axi_bvalid : 0;
  assign oculink_0a_s_axi_rdata_io = nvme_setting_done ? oculink_0a_s_axi_rdata : 0;
  assign oculink_0a_s_axi_rid_io = nvme_setting_done ? oculink_0a_s_axi_rid : 0;
  assign oculink_0a_s_axi_rlast_io = nvme_setting_done ? oculink_0a_s_axi_rlast : 0;
  assign oculink_0a_s_axi_rresp_io = nvme_setting_done ? oculink_0a_s_axi_rresp : 0;
  assign oculink_0a_s_axi_rvalid_io = nvme_setting_done ? oculink_0a_s_axi_rvalid : 0;
  assign oculink_0a_s_axi_wready_io = nvme_setting_done ? oculink_0a_s_axi_wready : 0;


  csr csr_i(
    .sw_reset(sw_reset),
    // host bram signals
    .host_addr(host_bram_addr),
    .host_clk(host_bram_clk),
    .host_din(host_bram_din),
    .host_dout(host_bram_dout),
    .host_en(host_bram_en),
    .host_rst(host_bram_rst),
    .host_we(host_bram_we),

    .nvme_setting_done(nvme_setting_done),
    .do_write(do_write),
    .do_read(do_read),

    // oculink axi interface
    // ar
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arburst(s_axi_arburst),
    .s_axi_arid(s_axi_arid),
    .s_axi_arlen(s_axi_arlen),
    .s_axi_arregion(s_axi_arregion),
    .s_axi_arsize(s_axi_arsize),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_ar_fifo_empty(s_axi_ar_fifo_empty),
    .s_axi_ar_fifo_full(s_axi_ar_fifo_full),

    // aw
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awburst(s_axi_awburst),
    .s_axi_awid(s_axi_awid),
    .s_axi_awlen(s_axi_awlen),
    .s_axi_awregion(s_axi_awregion),
    .s_axi_awsize(s_axi_awsize),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_aw_fifo_empty(s_axi_aw_fifo_empty),
    .s_axi_aw_fifo_full(s_axi_aw_fifo_full),

    // w
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wlast(s_axi_wlast),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_w_fifo_empty(s_axi_w_fifo_empty),
    .s_axi_w_fifo_full(s_axi_w_fifo_full),

    // r
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rid(s_axi_rid),
    .s_axi_rlast(s_axi_rlast),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_r_fifo_pop(s_axi_r_fifo_pop),
    .s_axi_r_fifo_empty(s_axi_r_fifo_empty),
    .s_axi_r_fifo_full(s_axi_r_fifo_full),

    // b
    .s_axi_bid(s_axi_bid),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_b_fifo_pop(s_axi_b_fifo_pop),
    .s_axi_b_fifo_empty(s_axi_b_fifo_empty),
    .s_axi_b_fifo_full(s_axi_b_fifo_full),

    // csr ar interface
    .m_axi_ar_fifo_pop(m_axi_ar_fifo_pop),
    .m_axi_ar_fifo_valid(m_axi_ar_fifo_valid),
    .m_axi_ar_fifo_empty(m_axi_ar_fifo_empty),
    .m_axi_ar_fifo_full(m_axi_ar_fifo_full),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arburst(m_axi_arburst),
    .m_axi_arid(m_axi_arid),
    .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize),

    // csr aw interface
    .m_axi_aw_fifo_pop(m_axi_aw_fifo_pop),
    .m_axi_aw_fifo_valid(m_axi_aw_fifo_valid),
    .m_axi_aw_fifo_empty(m_axi_aw_fifo_empty),
    .m_axi_aw_fifo_full(m_axi_aw_fifo_full),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awburst(m_axi_awburst),
    .m_axi_awid(m_axi_awid),
    .m_axi_awlen(m_axi_awlen),
    .m_axi_awsize(m_axi_awsize),

    // csr b interface
    .m_axi_bid(m_axi_bid),
    .m_axi_bresp(m_axi_bresp),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_b_fifo_full(m_axi_b_fifo_full),
    .m_axi_b_fifo_empty(m_axi_b_fifo_empty),

    // csr r interface
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rid(m_axi_rid),
    .m_axi_rlast(m_axi_rlast),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_r_fifo_full(m_axi_r_fifo_full),
    .m_axi_r_fifo_empty(m_axi_r_fifo_empty),

    // csr w interface
    .m_axi_w_fifo_pop(m_axi_w_fifo_pop),
    .m_axi_w_fifo_valid(m_axi_w_fifo_valid),
    .m_axi_w_fifo_empty(m_axi_w_fifo_empty),
    .m_axi_w_fifo_full(m_axi_w_fifo_full),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wlast(m_axi_wlast),
    .m_axi_wstrb(m_axi_wstrb)
  );

  nvme_driver nvme_driver_i(
    // clk, reset, link up signals
    .clk(oculink_0a_axi_aclk),
    .rstn(!sw_reset),
    .oculink_0a_lnk_up(oculink_0a_lnk_up),
    .bram_clk(host_bram_clk),
    .axi_clk(oculink_0a_axi_aclk),

    // oculink axi slave ar interface
    .oculink_0a_s_axi_arready(oculink_0a_s_axi_arready_driver),
    .oculink_0a_s_axi_araddr(oculink_0a_s_axi_araddr_driver),
    .oculink_0a_s_axi_arburst(oculink_0a_s_axi_arburst_driver),
    .oculink_0a_s_axi_arid(oculink_0a_s_axi_arid_driver),
    .oculink_0a_s_axi_arlen(oculink_0a_s_axi_arlen_driver),
    .oculink_0a_s_axi_arregion(oculink_0a_s_axi_arregion_driver),
    .oculink_0a_s_axi_arsize(oculink_0a_s_axi_arsize_driver),
    .oculink_0a_s_axi_arvalid(oculink_0a_s_axi_arvalid_driver),
    
    // csr ar interface
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arburst(s_axi_arburst),
    .s_axi_arid(s_axi_arid),
    .s_axi_arlen(s_axi_arlen),
    .s_axi_arregion(s_axi_arregion),
    .s_axi_arsize(s_axi_arsize),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_ar_fifo_empty(s_axi_ar_fifo_empty),
    .s_axi_ar_fifo_full(s_axi_ar_fifo_full),

    // oculink axi slave aw interface
    .oculink_0a_s_axi_awaddr(oculink_0a_s_axi_awaddr_driver),
    .oculink_0a_s_axi_awburst(oculink_0a_s_axi_awburst_driver),
    .oculink_0a_s_axi_awid(oculink_0a_s_axi_awid_driver),
    .oculink_0a_s_axi_awlen(oculink_0a_s_axi_awlen_driver),
    .oculink_0a_s_axi_awready(oculink_0a_s_axi_awready_driver),
    .oculink_0a_s_axi_awregion(oculink_0a_s_axi_awregion_driver),
    .oculink_0a_s_axi_awsize(oculink_0a_s_axi_awsize_driver),
    .oculink_0a_s_axi_awvalid(oculink_0a_s_axi_awvalid_driver),

    // csr aw interface
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awburst(s_axi_awburst),
    .s_axi_awid(s_axi_awid),
    .s_axi_awlen(s_axi_awlen),
    .s_axi_awregion(s_axi_awregion),
    .s_axi_awsize(s_axi_awsize),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_aw_fifo_empty(s_axi_aw_fifo_empty),
    .s_axi_aw_fifo_full(s_axi_aw_fifo_full),
    
    // oculink axi slave w interface
    .oculink_0a_s_axi_wdata(oculink_0a_s_axi_wdata_driver),
    .oculink_0a_s_axi_wlast(oculink_0a_s_axi_wlast_driver),
    .oculink_0a_s_axi_wready(oculink_0a_s_axi_wready_driver),
    .oculink_0a_s_axi_wstrb(oculink_0a_s_axi_wstrb_driver),
    .oculink_0a_s_axi_wvalid(oculink_0a_s_axi_wvalid_driver),

    // csr w interface
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wlast(s_axi_wlast),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),

    // oculink axi slave r interface
    .oculink_0a_s_axi_rdata(oculink_0a_s_axi_rdata_driver),
    .oculink_0a_s_axi_rid(oculink_0a_s_axi_rid_driver),
    .oculink_0a_s_axi_rlast(oculink_0a_s_axi_rlast_driver),
    .oculink_0a_s_axi_rready(oculink_0a_s_axi_rready_driver),
    .oculink_0a_s_axi_rresp(oculink_0a_s_axi_rresp_driver),
    .oculink_0a_s_axi_rvalid(oculink_0a_s_axi_rvalid_driver),

    // csr r interface
    .s_axi_r_fifo_pop(s_axi_r_fifo_pop),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rid(s_axi_rid),
    .s_axi_rlast(s_axi_rlast),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_r_fifo_full(s_axi_r_fifo_full),
    .s_axi_r_fifo_empty(s_axi_r_fifo_empty),

    // oculink axi slave b interface
    .oculink_0a_s_axi_bid(oculink_0a_s_axi_bid_driver),
    .oculink_0a_s_axi_bready(oculink_0a_s_axi_bready_driver),
    .oculink_0a_s_axi_bresp(oculink_0a_s_axi_bresp_driver),
    .oculink_0a_s_axi_bvalid(oculink_0a_s_axi_bvalid_driver),

    // csr b interface
    .s_axi_b_fifo_pop(s_axi_b_fifo_pop),
    .s_axi_bid(s_axi_bid),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_b_fifo_full(s_axi_b_fifo_full),
    .s_axi_b_fifo_empty(s_axi_b_fifo_empty),

    // oculink axi master ar interface
    .oculink_0a_m_axi_araddr(oculink_0a_m_axi_araddr_driver),
    .oculink_0a_m_axi_arburst(oculink_0a_m_axi_arburst_driver),
    .oculink_0a_m_axi_arcache(oculink_0a_m_axi_arcache_driver),
    .oculink_0a_m_axi_arid(oculink_0a_m_axi_arid_driver),
    .oculink_0a_m_axi_arlen(oculink_0a_m_axi_arlen_driver),
    .oculink_0a_m_axi_arlock(oculink_0a_m_axi_arlock_driver),
    .oculink_0a_m_axi_arprot(oculink_0a_m_axi_arprot_driver),
    .oculink_0a_m_axi_arready(oculink_0a_m_axi_arready_driver),
    .oculink_0a_m_axi_arsize(oculink_0a_m_axi_arsize_driver),
    .oculink_0a_m_axi_arvalid(oculink_0a_m_axi_arvalid_driver),

    // csr ar interface
    .m_axi_ar_fifo_pop(m_axi_ar_fifo_pop),
    .m_axi_ar_fifo_valid(m_axi_ar_fifo_valid),
    .m_axi_ar_fifo_empty(m_axi_ar_fifo_empty),
    .m_axi_ar_fifo_full(m_axi_ar_fifo_full),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arburst(m_axi_arburst),
    .m_axi_arid(m_axi_arid),
    .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize),

    // oculink axi master aw interface
    .oculink_0a_m_axi_awaddr(oculink_0a_m_axi_awaddr_driver),
    .oculink_0a_m_axi_awburst(oculink_0a_m_axi_awburst_driver),
    .oculink_0a_m_axi_awcache(oculink_0a_m_axi_awcache_driver),
    .oculink_0a_m_axi_awid(oculink_0a_m_axi_awid_driver),
    .oculink_0a_m_axi_awlen(oculink_0a_m_axi_awlen_driver),
    .oculink_0a_m_axi_awlock(oculink_0a_m_axi_awlock_driver),
    .oculink_0a_m_axi_awprot(oculink_0a_m_axi_awprot_driver),
    .oculink_0a_m_axi_awready(oculink_0a_m_axi_awready_driver),
    .oculink_0a_m_axi_awsize(oculink_0a_m_axi_awsize_driver),
    .oculink_0a_m_axi_awvalid(oculink_0a_m_axi_awvalid_driver),

    // csr aw interface
    .m_axi_aw_fifo_pop(m_axi_aw_fifo_pop),
    .m_axi_aw_fifo_valid(m_axi_aw_fifo_valid),
    .m_axi_aw_fifo_empty(m_axi_aw_fifo_empty),
    .m_axi_aw_fifo_full(m_axi_aw_fifo_full),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awburst(m_axi_awburst),
    .m_axi_awid(m_axi_awid),
    .m_axi_awlen(m_axi_awlen),
    .m_axi_awsize(m_axi_awsize),

    // oculink axi master b interface
    .oculink_0a_m_axi_bid(oculink_0a_m_axi_bid_driver),
    .oculink_0a_m_axi_bready(oculink_0a_m_axi_bready_driver),
    .oculink_0a_m_axi_bresp(oculink_0a_m_axi_bresp_driver),
    .oculink_0a_m_axi_bvalid(oculink_0a_m_axi_bvalid_driver),

    // csr b interface
    .m_axi_bid(m_axi_bid),
    .m_axi_bresp(m_axi_bresp),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_b_fifo_full(m_axi_b_fifo_full),
    .m_axi_b_fifo_empty(m_axi_b_fifo_empty),

    // oculink axi master r interface
    .oculink_0a_m_axi_rdata(oculink_0a_m_axi_rdata_driver),
    .oculink_0a_m_axi_rid(oculink_0a_m_axi_rid_driver),
    .oculink_0a_m_axi_rlast(oculink_0a_m_axi_rlast_driver),
    .oculink_0a_m_axi_rready(oculink_0a_m_axi_rready_driver),
    .oculink_0a_m_axi_rresp(oculink_0a_m_axi_rresp_driver),
    .oculink_0a_m_axi_rvalid(oculink_0a_m_axi_rvalid_driver),

    // csr r interface
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rid(m_axi_rid),
    .m_axi_rlast(m_axi_rlast),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_r_fifo_full(m_axi_r_fifo_full),
    .m_axi_r_fifo_empty(m_axi_r_fifo_empty),

    // oculink axi master w interface
    .oculink_0a_m_axi_wdata(oculink_0a_m_axi_wdata_driver),
    .oculink_0a_m_axi_wlast(oculink_0a_m_axi_wlast_driver),
    .oculink_0a_m_axi_wready(oculink_0a_m_axi_wready_driver),
    .oculink_0a_m_axi_wstrb(oculink_0a_m_axi_wstrb_driver),
    .oculink_0a_m_axi_wvalid(oculink_0a_m_axi_wvalid_driver),

    // csr w interface
    .m_axi_w_fifo_pop(m_axi_w_fifo_pop),
    .m_axi_w_fifo_valid(m_axi_w_fifo_valid),
    .m_axi_w_fifo_empty(m_axi_w_fifo_empty),
    .m_axi_w_fifo_full(m_axi_w_fifo_full),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wlast(m_axi_wlast),
    .m_axi_wstrb(m_axi_wstrb)
  );

  
  nvme_rw nvme_rw_i(
    // clk, reset, link up signals
    .clk(oculink_0a_axi_aclk),
    .rstn(!sw_reset),
    .oculink_0a_lnk_up(oculink_0a_lnk_up),
    .do_write(do_write),
    .do_read(do_read),

    // oculink axi slave ar interface
    .oculink_0a_s_axi_arready(oculink_0a_s_axi_arready_io),
    .oculink_0a_s_axi_araddr(oculink_0a_s_axi_araddr_io),
    .oculink_0a_s_axi_arburst(oculink_0a_s_axi_arburst_io),
    .oculink_0a_s_axi_arid(oculink_0a_s_axi_arid_io),
    .oculink_0a_s_axi_arlen(oculink_0a_s_axi_arlen_io),
    .oculink_0a_s_axi_arregion(oculink_0a_s_axi_arregion_io),
    .oculink_0a_s_axi_arsize(oculink_0a_s_axi_arsize_io),
    .oculink_0a_s_axi_arvalid(oculink_0a_s_axi_arvalid_io),

    // oculink axi slave aw interface
    .oculink_0a_s_axi_awaddr(oculink_0a_s_axi_awaddr_io),
    .oculink_0a_s_axi_awburst(oculink_0a_s_axi_awburst_io),
    .oculink_0a_s_axi_awid(oculink_0a_s_axi_awid_io),
    .oculink_0a_s_axi_awlen(oculink_0a_s_axi_awlen_io),
    .oculink_0a_s_axi_awready(oculink_0a_s_axi_awready_io),
    .oculink_0a_s_axi_awregion(oculink_0a_s_axi_awregion_io),
    .oculink_0a_s_axi_awsize(oculink_0a_s_axi_awsize_io),
    .oculink_0a_s_axi_awvalid(oculink_0a_s_axi_awvalid_io),
    
    // oculink axi slave w interface
    .oculink_0a_s_axi_wdata(oculink_0a_s_axi_wdata_io),
    .oculink_0a_s_axi_wlast(oculink_0a_s_axi_wlast_io),
    .oculink_0a_s_axi_wready(oculink_0a_s_axi_wready_io),
    .oculink_0a_s_axi_wstrb(oculink_0a_s_axi_wstrb_io),
    .oculink_0a_s_axi_wvalid(oculink_0a_s_axi_wvalid_io),

    // oculink axi slave r interface
    .oculink_0a_s_axi_rdata(oculink_0a_s_axi_rdata_io),
    .oculink_0a_s_axi_rid(oculink_0a_s_axi_rid_io),
    .oculink_0a_s_axi_rlast(oculink_0a_s_axi_rlast_io),
    .oculink_0a_s_axi_rready(oculink_0a_s_axi_rready_io),
    .oculink_0a_s_axi_rresp(oculink_0a_s_axi_rresp_io),
    .oculink_0a_s_axi_rvalid(oculink_0a_s_axi_rvalid_io),

    // oculink axi slave b interface
    .oculink_0a_s_axi_bid(oculink_0a_s_axi_bid_io),
    .oculink_0a_s_axi_bready(oculink_0a_s_axi_bready_io),
    .oculink_0a_s_axi_bresp(oculink_0a_s_axi_bresp_io),
    .oculink_0a_s_axi_bvalid(oculink_0a_s_axi_bvalid_io),

    // oculink axi master ar interface
    .oculink_0a_m_axi_araddr(oculink_0a_m_axi_araddr_io),
    .oculink_0a_m_axi_arburst(oculink_0a_m_axi_arburst_io),
    .oculink_0a_m_axi_arcache(oculink_0a_m_axi_arcache_io),
    .oculink_0a_m_axi_arid(oculink_0a_m_axi_arid_io),
    .oculink_0a_m_axi_arlen(oculink_0a_m_axi_arlen_io),
    .oculink_0a_m_axi_arlock(oculink_0a_m_axi_arlock_io),
    .oculink_0a_m_axi_arprot(oculink_0a_m_axi_arprot_io),
    .oculink_0a_m_axi_arready(oculink_0a_m_axi_arready_io),
    .oculink_0a_m_axi_arsize(oculink_0a_m_axi_arsize_io),
    .oculink_0a_m_axi_arvalid(oculink_0a_m_axi_arvalid_io),

    // oculink axi master aw interface
    .oculink_0a_m_axi_awaddr(oculink_0a_m_axi_awaddr_io),
    .oculink_0a_m_axi_awburst(oculink_0a_m_axi_awburst_io),
    .oculink_0a_m_axi_awcache(oculink_0a_m_axi_awcache_io),
    .oculink_0a_m_axi_awid(oculink_0a_m_axi_awid_io),
    .oculink_0a_m_axi_awlen(oculink_0a_m_axi_awlen_io),
    .oculink_0a_m_axi_awlock(oculink_0a_m_axi_awlock_io),
    .oculink_0a_m_axi_awprot(oculink_0a_m_axi_awprot_io),
    .oculink_0a_m_axi_awready(oculink_0a_m_axi_awready_io),
    .oculink_0a_m_axi_awsize(oculink_0a_m_axi_awsize_io),
    .oculink_0a_m_axi_awvalid(oculink_0a_m_axi_awvalid_io),

    // oculink axi master b interface
    .oculink_0a_m_axi_bid(oculink_0a_m_axi_bid_io),
    .oculink_0a_m_axi_bready(oculink_0a_m_axi_bready_io),
    .oculink_0a_m_axi_bresp(oculink_0a_m_axi_bresp_io),
    .oculink_0a_m_axi_bvalid(oculink_0a_m_axi_bvalid_io),

    // oculink axi master r interface
    .oculink_0a_m_axi_rdata(oculink_0a_m_axi_rdata_io),
    .oculink_0a_m_axi_rid(oculink_0a_m_axi_rid_io),
    .oculink_0a_m_axi_rlast(oculink_0a_m_axi_rlast_io),
    .oculink_0a_m_axi_rready(oculink_0a_m_axi_rready_io),
    .oculink_0a_m_axi_rresp(oculink_0a_m_axi_rresp_io),
    .oculink_0a_m_axi_rvalid(oculink_0a_m_axi_rvalid_io),

    // oculink axi master w interface
    .oculink_0a_m_axi_wdata(oculink_0a_m_axi_wdata_io),
    .oculink_0a_m_axi_wlast(oculink_0a_m_axi_wlast_io),
    .oculink_0a_m_axi_wready(oculink_0a_m_axi_wready_io),
    .oculink_0a_m_axi_wstrb(oculink_0a_m_axi_wstrb_io),
    .oculink_0a_m_axi_wvalid(oculink_0a_m_axi_wvalid_io)
  );



endmodule