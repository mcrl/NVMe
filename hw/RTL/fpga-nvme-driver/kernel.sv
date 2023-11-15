module kernel(

  // host bram interface
  input logic [15:0]  host_bram_addr,
  input logic         host_bram_clk,
  input logic [31:0]  host_bram_din,
  output logic [31:0] host_bram_dout,
  input logic         host_bram_en,
  input logic         host_bram_rst,
  input logic [3:0]   host_bram_we,

  // oculink 0a interface
  input logic           oculink_0a_axi_rstn,
  input logic           oculink_0a_axi_aclk,
  input logic [31:0]    oculink_0a_m_axi_araddr,
  input logic [1:0]     oculink_0a_m_axi_arburst,
  input logic [3:0]     oculink_0a_m_axi_arcache,
  input logic [3:0]     oculink_0a_m_axi_arid,
  input logic [7:0]     oculink_0a_m_axi_arlen,
  input logic           oculink_0a_m_axi_arlock,
  input logic [2:0]     oculink_0a_m_axi_arprot,
  output logic          oculink_0a_m_axi_arready,
  input logic [2:0]     oculink_0a_m_axi_arsize,
  input logic           oculink_0a_m_axi_arvalid,
  input logic [31:0]    oculink_0a_m_axi_awaddr,
  input logic [1:0]     oculink_0a_m_axi_awburst,
  input logic [3:0]     oculink_0a_m_axi_awcache,
  input logic [3:0]     oculink_0a_m_axi_awid,
  input logic [7:0]     oculink_0a_m_axi_awlen,
  input logic           oculink_0a_m_axi_awlock,
  input logic [2:0]     oculink_0a_m_axi_awprot,
  output logic          oculink_0a_m_axi_awready,
  input logic [2:0]     oculink_0a_m_axi_awsize,
  input logic           oculink_0a_m_axi_awvalid,
  output logic [3:0]    oculink_0a_m_axi_bid,
  input logic           oculink_0a_m_axi_bready,
  output logic [1:0]    oculink_0a_m_axi_bresp,
  output logic          oculink_0a_m_axi_bvalid,
  output logic [255:0]  oculink_0a_m_axi_rdata,
  output logic [3:0]    oculink_0a_m_axi_rid,
  output logic          oculink_0a_m_axi_rlast,
  input logic           oculink_0a_m_axi_rready,
  output logic [1:0]    oculink_0a_m_axi_rresp,
  output logic          oculink_0a_m_axi_rvalid,
  input logic[ 255:0]   oculink_0a_m_axi_wdata,
  input logic           oculink_0a_m_axi_wlast,
  output logic          oculink_0a_m_axi_wready,
  input logic [15:0]    oculink_0a_m_axi_wstrb,
  input logic           oculink_0a_m_axi_wvalid,
  output logic [31:0]   oculink_0a_s_axi_araddr,
  output logic [1:0]    oculink_0a_s_axi_arburst,
  output logic [3:0]    oculink_0a_s_axi_arid,
  output logic [7:0]    oculink_0a_s_axi_arlen,
  input logic           oculink_0a_s_axi_arready,
  output logic [3:0]    oculink_0a_s_axi_arregion,
  output logic [2:0]    oculink_0a_s_axi_arsize,
  output logic          oculink_0a_s_axi_arvalid,
  output logic [31:0]   oculink_0a_s_axi_awaddr,
  output logic [1:0]    oculink_0a_s_axi_awburst,
  output logic [3:0]    oculink_0a_s_axi_awid,
  output logic [7:0]    oculink_0a_s_axi_awlen,
  input logic           oculink_0a_s_axi_awready,
  output logic [3:0]    oculink_0a_s_axi_awregion,
  output logic [2:0]    oculink_0a_s_axi_awsize,
  output logic          oculink_0a_s_axi_awvalid,
  input logic [3:0]     oculink_0a_s_axi_bid,
  output logic          oculink_0a_s_axi_bready,
  input logic [1:0]     oculink_0a_s_axi_bresp,
  input logic           oculink_0a_s_axi_bvalid,
  input logic [255:0]   oculink_0a_s_axi_rdata,
  input logic [3:0]     oculink_0a_s_axi_rid,
  input logic           oculink_0a_s_axi_rlast,
  output logic          oculink_0a_s_axi_rready,
  input logic [1:0]     oculink_0a_s_axi_rresp,
  input logic           oculink_0a_s_axi_rvalid,
  output logic [255:0]  oculink_0a_s_axi_wdata,
  output logic          oculink_0a_s_axi_wlast,
  input logic           oculink_0a_s_axi_wready,
  output logic [31:0]   oculink_0a_s_axi_wstrb,
  output logic          oculink_0a_s_axi_wvalid
  );

  logic           sw_reset;

  /* Oculink 0a signals */

  logic           cfg_0a_write;
  logic           cfg_0a_read;
  logic [31:0]    cfg_0a_wraddr;
  logic [31:0]    cfg_0a_wrdata;
  logic [31:0]    cfg_0a_rdaddr;
  logic [31:0]    cfg_0a_rddata;
  logic           cfg_0a_wrdone;
  logic           cfg_0a_rddone;
  logic           cfg_0a_cfgdone;

  logic           oculink_0a_send_iocq_create_cmd;
  logic           oculink_0a_send_iosq_create_cmd;
  logic           oculink_0a_send_read_cmd;
  logic           oculink_0a_send_write_cmd;
  logic [31:0]    oculink_0a_nvme_addr;
  logic [31:0]    oculink_0a_fpga_addr;
  logic [31:0]    oculink_0a_nlb;
  logic           oculink_0a_cpl_done;
  logic [31:0]    oculink_0a_wrdata [7:0];

  logic [31:0]    oculink_0a_s_axi_awaddr_cfg;
  logic [1:0]     oculink_0a_s_axi_awburst_cfg;
  logic [3:0]     oculink_0a_s_axi_awid_cfg;
  logic [7:0]     oculink_0a_s_axi_awlen_cfg;
  logic [3:0]     oculink_0a_s_axi_awregion_cfg;
  logic [2:0]     oculink_0a_s_axi_awsize_cfg;
  logic           oculink_0a_s_axi_awvalid_cfg;
  logic [255:0]   oculink_0a_s_axi_wdata_cfg;
  logic           oculink_0a_s_axi_wlast_cfg;
  logic [31:0]    oculink_0a_s_axi_wstrb_cfg;
  logic           oculink_0a_s_axi_wvalid_cfg;
  logic [31:0]    oculink_0a_s_axi_awaddr_driver;
  logic [1:0]     oculink_0a_s_axi_awburst_driver;
  logic [3:0]     oculink_0a_s_axi_awid_driver;
  logic [7:0]     oculink_0a_s_axi_awlen_driver;
  logic [3:0]     oculink_0a_s_axi_awregion_driver;
  logic [2:0]     oculink_0a_s_axi_awsize_driver;
  logic           oculink_0a_s_axi_awvalid_driver;
  logic [255:0]   oculink_0a_s_axi_wdata_driver;
  logic           oculink_0a_s_axi_wlast_driver;
  logic [31:0]    oculink_0a_s_axi_wstrb_driver;
  logic           oculink_0a_s_axi_wvalid_driver;

  assign oculink_0a_s_axi_rready    = 1'b1;
  assign oculink_0a_s_axi_bready    = 1'b1;
  assign oculink_0a_m_axi_arready   = 1'b1;
  assign oculink_0a_m_axi_awready   = 1'b1;
  assign oculink_0a_m_axi_wready    = 1'b1;
  assign oculink_0a_s_axi_awaddr    = cfg_0a_cfgdone ? oculink_0a_s_axi_awaddr_driver : oculink_0a_s_axi_awaddr_cfg;
  assign oculink_0a_s_axi_awburst   = cfg_0a_cfgdone ? oculink_0a_s_axi_awburst_driver : oculink_0a_s_axi_awburst_cfg;
  assign oculink_0a_s_axi_awid      = cfg_0a_cfgdone ? oculink_0a_s_axi_awid_driver : oculink_0a_s_axi_awid_cfg;
  assign oculink_0a_s_axi_awlen     = cfg_0a_cfgdone ? oculink_0a_s_axi_awlen_driver : oculink_0a_s_axi_awlen_cfg;
  assign oculink_0a_s_axi_awregion  = cfg_0a_cfgdone ? oculink_0a_s_axi_awregion_driver : oculink_0a_s_axi_awregion_cfg;
  assign oculink_0a_s_axi_awsize    = cfg_0a_cfgdone ? oculink_0a_s_axi_awsize_driver : oculink_0a_s_axi_awsize_cfg;
  assign oculink_0a_s_axi_awvalid   = cfg_0a_cfgdone ? oculink_0a_s_axi_awvalid_driver : oculink_0a_s_axi_awvalid_cfg;
  assign oculink_0a_s_axi_wdata     = cfg_0a_cfgdone ? oculink_0a_s_axi_wdata_driver : oculink_0a_s_axi_wdata_cfg;
  assign oculink_0a_s_axi_wlast     = cfg_0a_cfgdone ? oculink_0a_s_axi_wlast_driver : oculink_0a_s_axi_wlast_cfg;
  assign oculink_0a_s_axi_wstrb     = cfg_0a_cfgdone ? oculink_0a_s_axi_wstrb_driver : oculink_0a_s_axi_wstrb_cfg;
  assign oculink_0a_s_axi_wvalid    = cfg_0a_cfgdone ? oculink_0a_s_axi_wvalid_driver : oculink_0a_s_axi_wvalid_cfg;

  csr csr_i(
    // host bram
    .host_addr      (host_bram_addr),
    .host_clk       (host_bram_clk),
    .host_din       (host_bram_din),
    .host_dout      (host_bram_dout),
    .host_en        (host_bram_en),
    .host_rst       (host_bram_rst),
    .host_we        (host_bram_we),

    .sw_reset       (sw_reset),

    // nvme 0a configurator
    .cfg_0a_write   (cfg_0a_write),
    .cfg_0a_read    (cfg_0a_read),
    .cfg_0a_wraddr  (cfg_0a_wraddr),
    .cfg_0a_wrdata  (cfg_0a_wrdata),
    .cfg_0a_rdaddr  (cfg_0a_rdaddr),
    .cfg_0a_rddata  (cfg_0a_rddata),
    .cfg_0a_wrdone  (cfg_0a_wrdone),
    .cfg_0a_rddone  (cfg_0a_rddone),
    .cfg_0a_cfgdone (cfg_0a_cfgdone),
    .oculink_0a_send_iocq_create_cmd  (oculink_0a_send_iocq_create_cmd),
    .oculink_0a_send_iosq_create_cmd  (oculink_0a_send_iosq_create_cmd),
    .oculink_0a_send_read_cmd         (oculink_0a_send_read_cmd),
    .oculink_0a_send_write_cmd        (oculink_0a_send_write_cmd),
    .oculink_0a_nvme_addr             (oculink_0a_nvme_addr),
    .oculink_0a_fpga_addr             (oculink_0a_fpga_addr),
    .oculink_0a_nlb                   (oculink_0a_nlb),
    .oculink_0a_cpl_done              (oculink_0a_cpl_done),
    .oculink_0a_wrdata                (oculink_0a_wrdata)
  );

  nvme_configurator nvme_0a_configurator_i(
    .rstn                   (!sw_reset),
    .oculink_lnk_up         (oculink_0a_lnk_up),
    .host_bram_clk          (host_bram_clk),
    .oculink_axi_clk        (oculink_0a_axi_aclk),
    .cfg_write              (cfg_0a_write),
    .cfg_read               (cfg_0a_read),
    .cfg_wraddr             (cfg_0a_wraddr),
    .cfg_wrdata             (cfg_0a_wrdata),
    .cfg_rdaddr             (cfg_0a_rdaddr),
    .cfg_rddata             (cfg_0a_rddata),
    .cfg_wr_done            (cfg_0a_wrdone),
    .cfg_rd_done            (cfg_0a_rddone),
    .oculink_s_axi_arready  (oculink_0a_s_axi_arready),
    .oculink_s_axi_araddr   (oculink_0a_s_axi_araddr),
    .oculink_s_axi_arburst  (oculink_0a_s_axi_arburst),
    .oculink_s_axi_arid     (oculink_0a_s_axi_arid),
    .oculink_s_axi_arlen    (oculink_0a_s_axi_arlen),
    .oculink_s_axi_arregion (oculink_0a_s_axi_arregion),
    .oculink_s_axi_arsize   (oculink_0a_s_axi_arsize),
    .oculink_s_axi_arvalid  (oculink_0a_s_axi_arvalid),
    .oculink_s_axi_rdata    (oculink_0a_s_axi_rdata),
    .oculink_s_axi_rid      (oculink_0a_s_axi_rid),
    .oculink_s_axi_rlast    (oculink_0a_s_axi_rlast),
    .oculink_s_axi_rready   (),
    .oculink_s_axi_rresp    (oculink_0a_s_axi_rresp),
    .oculink_s_axi_rvalid   (oculink_0a_s_axi_rvalid),
    .oculink_s_axi_awaddr   (oculink_0a_s_axi_awaddr_cfg),
    .oculink_s_axi_awburst  (oculink_0a_s_axi_awburst_cfg),
    .oculink_s_axi_awid     (oculink_0a_s_axi_awid_cfg),
    .oculink_s_axi_awlen    (oculink_0a_s_axi_awlen_cfg),
    .oculink_s_axi_awready  (oculink_0a_s_axi_awready),
    .oculink_s_axi_awregion (oculink_0a_s_axi_awregion_cfg),
    .oculink_s_axi_awsize   (oculink_0a_s_axi_awsize_cfg),
    .oculink_s_axi_awvalid  (oculink_0a_s_axi_awvalid_cfg),
    .oculink_s_axi_wdata    (oculink_0a_s_axi_wdata_cfg),
    .oculink_s_axi_wlast    (oculink_0a_s_axi_wlast_cfg),
    .oculink_s_axi_wready   (oculink_0a_s_axi_wready),
    .oculink_s_axi_wstrb    (oculink_0a_s_axi_wstrb_cfg),
    .oculink_s_axi_wvalid   (oculink_0a_s_axi_wvalid_cfg),
    .oculink_s_axi_bid      (oculink_0a_s_axi_bid),
    .oculink_s_axi_bready   (),
    .oculink_s_axi_bresp    (oculink_0a_s_axi_bresp),
    .oculink_s_axi_bvalid   (oculink_0a_s_axi_bvalid)
  );


  nvme_driver nvme_driver_0a_i(
    // clk, reset, link up signals
    .rstn                   (!sw_reset),
    .host_bram_clk          (host_bram_clk),
    .oculink_axi_clk        (oculink_0a_axi_aclk),

    .send_iocq_create_cmd   (oculink_0a_send_iocq_create_cmd),
    .send_iosq_create_cmd   (oculink_0a_send_iosq_create_cmd),
    .send_read_cmd          (oculink_0a_send_read_cmd),
    .send_write_cmd         (oculink_0a_send_write_cmd),
    .nvme_addr              (oculink_0a_nvme_addr),
    .fpga_addr              (oculink_0a_fpga_addr),
    .nlb                    (oculink_0a_nlb),
    .cpl_done               (oculink_0a_cpl_done),
    .wrdata                 (oculink_0a_wrdata),
    
    .oculink_s_axi_awaddr   (oculink_0a_s_axi_awaddr_driver),
    .oculink_s_axi_awburst  (oculink_0a_s_axi_awburst_driver),
    .oculink_s_axi_awid     (oculink_0a_s_axi_awid_driver),
    .oculink_s_axi_awlen    (oculink_0a_s_axi_awlen_driver),
    .oculink_s_axi_awready  (oculink_0a_s_axi_awready),
    .oculink_s_axi_awregion (oculink_0a_s_axi_awregion_driver),
    .oculink_s_axi_awsize   (oculink_0a_s_axi_awsize_driver),
    .oculink_s_axi_awvalid  (oculink_0a_s_axi_awvalid_driver),
    .oculink_s_axi_wdata    (oculink_0a_s_axi_wdata_driver),
    .oculink_s_axi_wlast    (oculink_0a_s_axi_wlast_driver),
    .oculink_s_axi_wready   (oculink_0a_s_axi_wready),
    .oculink_s_axi_wstrb    (oculink_0a_s_axi_wstrb_driver),
    .oculink_s_axi_wvalid   (oculink_0a_s_axi_wvalid_driver),
    .oculink_s_axi_bid      (oculink_0a_s_axi_bid),
    .oculink_s_axi_bready   (),
    .oculink_s_axi_bresp    (oculink_0a_s_axi_bresp),
    .oculink_s_axi_bvalid   (oculink_0a_s_axi_bvalid),
    .oculink_m_axi_araddr   (oculink_0a_m_axi_araddr),
    .oculink_m_axi_arburst  (oculink_0a_m_axi_arburst),
    .oculink_m_axi_arcache  (oculink_0a_m_axi_arcache),
    .oculink_m_axi_arid     (oculink_0a_m_axi_arid),
    .oculink_m_axi_arlen    (oculink_0a_m_axi_arlen),
    .oculink_m_axi_arlock   (oculink_0a_m_axi_arlock),
    .oculink_m_axi_arprot   (oculink_0a_m_axi_arprot),
    .oculink_m_axi_arready  (),
    .oculink_m_axi_arsize   (oculink_0a_m_axi_arsize),
    .oculink_m_axi_arvalid  (oculink_0a_m_axi_arvalid),
    .oculink_m_axi_awaddr   (oculink_0a_m_axi_awaddr),
    .oculink_m_axi_awburst  (oculink_0a_m_axi_awburst),
    .oculink_m_axi_awcache  (oculink_0a_m_axi_awcache),
    .oculink_m_axi_awid     (oculink_0a_m_axi_awid),
    .oculink_m_axi_awlen    (oculink_0a_m_axi_awlen),
    .oculink_m_axi_awlock   (oculink_0a_m_axi_awlock),
    .oculink_m_axi_awprot   (oculink_0a_m_axi_awprot),
    .oculink_m_axi_awready  (),
    .oculink_m_axi_awsize   (oculink_0a_m_axi_awsize),
    .oculink_m_axi_awvalid  (oculink_0a_m_axi_awvalid),
    .oculink_m_axi_bid      (oculink_0a_m_axi_bid),
    .oculink_m_axi_bready   (oculink_0a_m_axi_bready),
    .oculink_m_axi_bresp    (oculink_0a_m_axi_bresp),
    .oculink_m_axi_bvalid   (oculink_0a_m_axi_bvalid),
    .oculink_m_axi_rdata    (oculink_0a_m_axi_rdata),
    .oculink_m_axi_rid      (oculink_0a_m_axi_rid),
    .oculink_m_axi_rlast    (oculink_0a_m_axi_rlast),
    .oculink_m_axi_rready   (oculink_0a_m_axi_rready),
    .oculink_m_axi_rresp    (oculink_0a_m_axi_rresp),
    .oculink_m_axi_rvalid   (oculink_0a_m_axi_rvalid),
    .oculink_m_axi_wdata    (oculink_0a_m_axi_wdata),
    .oculink_m_axi_wlast    (oculink_0a_m_axi_wlast),
    .oculink_m_axi_wready   (),
    .oculink_m_axi_wstrb    (oculink_0a_m_axi_wstrb),
    .oculink_m_axi_wvalid   (oculink_0a_m_axi_wvalid)
  );
  

endmodule
