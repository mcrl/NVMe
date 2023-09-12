`timescale 1 ps / 1 ps

module nvme_driver(
  input clk,
  input rstn,
  input oculink_0a_lnk_up,
  input logic bram_clk,
  input logic axi_clk,
  
  // ---------------------------------
  // AXI Slave : FPGA -> Oculink NVMe
  // ---------------------------------

  // ar
  // nvme <-> driver
  input logic oculink_0a_s_axi_arready,
  output logic [31:0]oculink_0a_s_axi_araddr,
  output logic [1:0]oculink_0a_s_axi_arburst,
  output logic [3:0]oculink_0a_s_axi_arid,
  output logic [7:0]oculink_0a_s_axi_arlen,
  output logic [3:0]oculink_0a_s_axi_arregion,
  output logic [2:0]oculink_0a_s_axi_arsize,
  output logic oculink_0a_s_axi_arvalid,
  
  // csr <-> driver
  input logic [31:0]s_axi_araddr,
  input logic [1:0]s_axi_arburst,
  input logic [3:0]s_axi_arid,
  input logic [7:0]s_axi_arlen,
  input logic [3:0]s_axi_arregion,
  input logic [2:0]s_axi_arsize,
  input logic s_axi_arvalid,
  output logic s_axi_ar_fifo_full,
  output logic s_axi_ar_fifo_empty,

  // aw
  // nvme <-> driver
  input logic oculink_0a_s_axi_awready,
  output logic [31:0]oculink_0a_s_axi_awaddr,
  output logic [1:0]oculink_0a_s_axi_awburst,
  output logic [3:0]oculink_0a_s_axi_awid,
  output logic [7:0]oculink_0a_s_axi_awlen,
  output logic [3:0]oculink_0a_s_axi_awregion,
  output logic [2:0]oculink_0a_s_axi_awsize,
  output logic oculink_0a_s_axi_awvalid,

  // csr <-> driver
  input logic [31:0]s_axi_awaddr,
  input logic [1:0]s_axi_awburst,
  input logic [3:0]s_axi_awid,
  input logic [7:0]s_axi_awlen,
  input logic [3:0]s_axi_awregion,
  input logic [2:0]s_axi_awsize,
  input logic s_axi_awvalid,
  output logic s_axi_aw_fifo_full,
  output logic s_axi_aw_fifo_empty,

  // w
  // nvme <-> driver
  input logic oculink_0a_s_axi_wready,
  output logic [255:0]oculink_0a_s_axi_wdata,
  output logic oculink_0a_s_axi_wlast,
  output logic [31:0]oculink_0a_s_axi_wstrb,
  output logic oculink_0a_s_axi_wvalid,

  // csr <-> driver
  input logic [255:0]s_axi_wdata,
  input logic s_axi_wlast,
  input logic [31:0]s_axi_wstrb,
  input logic s_axi_wvalid,  
  output logic s_axi_w_fifo_full,
  output logic s_axi_w_fifo_empty,

  // r
  // nvme <-> driver
  output logic oculink_0a_s_axi_rready,
  input logic [255:0]oculink_0a_s_axi_rdata,
  input logic [3:0]oculink_0a_s_axi_rid,
  input logic oculink_0a_s_axi_rlast,
  input logic [1:0]oculink_0a_s_axi_rresp,
  input logic oculink_0a_s_axi_rvalid,

  // csr <-> driver
  input logic s_axi_r_fifo_pop,
  output logic [255:0]s_axi_rdata,
  output logic [3:0]s_axi_rid,
  output logic s_axi_rlast,
  output logic [1:0]s_axi_rresp,
  output logic s_axi_rvalid,
  output logic s_axi_r_fifo_full,
  output logic s_axi_r_fifo_empty,

  // b
  // nvme <-> driver
  output logic oculink_0a_s_axi_bready,
  input logic [3:0]oculink_0a_s_axi_bid,
  input logic [1:0]oculink_0a_s_axi_bresp,
  input logic oculink_0a_s_axi_bvalid,

  // csr <-> driver
  input logic s_axi_b_fifo_pop,
  output logic [3:0]s_axi_bid,
  output logic [1:0]s_axi_bresp,
  output logic s_axi_bvalid,
  output logic s_axi_b_fifo_full,
  output logic s_axi_b_fifo_empty,

  // ---------------------------------
  // AXI Master : OCulink NVMe -> FPGA 
  // ---------------------------------
  
  // ar
  // nvme <-> driver
  output logic oculink_0a_m_axi_arready,
  input logic [31:0]oculink_0a_m_axi_araddr,
  input logic [1:0]oculink_0a_m_axi_arburst,
  input logic [3:0]oculink_0a_m_axi_arcache,
  input logic [3:0]oculink_0a_m_axi_arid,
  input logic [7:0]oculink_0a_m_axi_arlen,
  input logic oculink_0a_m_axi_arlock,
  input logic [2:0]oculink_0a_m_axi_arprot,
  input logic [2:0]oculink_0a_m_axi_arsize,
  input logic oculink_0a_m_axi_arvalid,

  // csr <-> driver
  input logic m_axi_ar_fifo_pop,
  output logic m_axi_ar_fifo_valid,
  output logic m_axi_ar_fifo_empty,
  output logic m_axi_ar_fifo_full,
  output logic [31:0]m_axi_araddr,
  output logic [1:0]m_axi_arburst,
  output logic [3:0]m_axi_arid,
  output logic [7:0]m_axi_arlen,
  output logic [2:0]m_axi_arsize,

  // aw
  // nvme <-> driver
  output logic oculink_0a_m_axi_awready,
  input logic [31:0]oculink_0a_m_axi_awaddr,
  input logic [1:0]oculink_0a_m_axi_awburst,
  input logic [3:0]oculink_0a_m_axi_awcache,
  input logic [3:0]oculink_0a_m_axi_awid,
  input logic [7:0]oculink_0a_m_axi_awlen,
  input logic oculink_0a_m_axi_awlock,
  input logic [2:0]oculink_0a_m_axi_awprot,
  input logic [2:0]oculink_0a_m_axi_awsize,
  input logic oculink_0a_m_axi_awvalid,

  // csr <-> driver
  input logic m_axi_aw_fifo_pop,
  output logic m_axi_aw_fifo_valid,
  output logic m_axi_aw_fifo_empty,
  output logic m_axi_aw_fifo_full,
  output logic [31:0]m_axi_awaddr,
  output logic [1:0]m_axi_awburst,
  output logic [3:0]m_axi_awid,
  output logic [7:0]m_axi_awlen,
  output logic [2:0]m_axi_awsize,

  // w
  // nvme <-> driver
  output logic oculink_0a_m_axi_wready,
  input logic [255:0]oculink_0a_m_axi_wdata,
  input logic oculink_0a_m_axi_wlast,
  input logic [31:0]oculink_0a_m_axi_wstrb,
  input logic oculink_0a_m_axi_wvalid,

  // csr <-> driver
  input logic m_axi_w_fifo_pop,
  output logic m_axi_w_fifo_valid,
  output logic m_axi_w_fifo_empty,
  output logic m_axi_w_fifo_full,
  output logic [255:0]m_axi_wdata,
  output logic m_axi_wlast,
  output logic [31:0]m_axi_wstrb,

  // r
  // nvme <-> driver
  input logic oculink_0a_m_axi_rready,
  output logic [255:0]oculink_0a_m_axi_rdata,
  output logic [3:0]oculink_0a_m_axi_rid,
  output logic oculink_0a_m_axi_rlast,
  output logic [1:0]oculink_0a_m_axi_rresp,
  output logic oculink_0a_m_axi_rvalid,

  // csr <-> driver
  input logic [255:0]m_axi_rdata,
  input logic [3:0]m_axi_rid,
  input logic m_axi_rlast,
  input logic [1:0]m_axi_rresp,
  input logic m_axi_rvalid,
  output logic m_axi_r_fifo_full,
  output logic m_axi_r_fifo_empty,

  // b
  // nvme <-> driver
  input logic oculink_0a_m_axi_bready,
  output logic [3:0]oculink_0a_m_axi_bid,
  output logic [1:0]oculink_0a_m_axi_bresp,
  output logic oculink_0a_m_axi_bvalid,

  // csr <-> driver
  input logic [3:0]m_axi_bid,
  input logic [1:0]m_axi_bresp,
  input logic m_axi_bvalid,
  output logic m_axi_b_fifo_full,
  output logic m_axi_b_fifo_empty
  );

  // s axi ar fifo signals
  // ar : 32 + 2 + 4 + 8 + 4 + 3 = 53
  logic [52:0] s_axi_ar_fifo_din;
  logic [52:0] s_axi_ar_fifo_dout;
  logic s_axi_ar_fifo_valid;

  assign s_axi_ar_fifo_din = {s_axi_araddr,   // 32
                              s_axi_arburst,  // 2
                              s_axi_arid,     // 4
                              s_axi_arlen,    // 8
                              s_axi_arregion, // 4
                              s_axi_arsize};  // 3
  assign oculink_0a_s_axi_araddr = s_axi_ar_fifo_dout[52:21];
  assign oculink_0a_s_axi_arburst = s_axi_ar_fifo_dout[20:19];
  assign oculink_0a_s_axi_arid = s_axi_ar_fifo_dout[18:15];
  assign oculink_0a_s_axi_arlen = s_axi_ar_fifo_dout[14:7];
  assign oculink_0a_s_axi_arregion = s_axi_ar_fifo_dout[6:3];
  assign oculink_0a_s_axi_arsize = s_axi_ar_fifo_dout[2:0];
  assign oculink_0a_s_axi_arvalid = s_axi_ar_fifo_valid;

  s_axi_ar_fifo s_axi_ar_fifo_i (
    .srst(!rstn),
    .wr_clk(bram_clk),
    .rd_clk(axi_clk),
    .din(s_axi_ar_fifo_din),
    .wr_en(s_axi_arvalid),
    .rd_en(oculink_0a_s_axi_arready && !s_axi_ar_fifo_empty), 
    .dout(s_axi_ar_fifo_dout),
    .full(s_axi_ar_fifo_full),
    .empty(s_axi_ar_fifo_empty),
    .valid(s_axi_ar_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );


  // s axi aw fifo signals
  // aw : 32 + 2 + 4 + 8 + 4 + 3 = 53
  logic [52:0] s_axi_aw_fifo_din;
  logic [52:0] s_axi_aw_fifo_dout;
  logic s_axi_aw_fifo_valid;

  assign s_axi_aw_fifo_din = {s_axi_awaddr,   // 32
                              s_axi_awburst,  // 2
                              s_axi_awid,     // 4
                              s_axi_awlen,    // 8
                              s_axi_awregion, // 4
                              s_axi_awsize};  // 3
  assign oculink_0a_s_axi_awaddr = s_axi_aw_fifo_dout[52:21];
  assign oculink_0a_s_axi_awburst = s_axi_aw_fifo_dout[20:19];
  assign oculink_0a_s_axi_awid = s_axi_aw_fifo_dout[18:15];
  assign oculink_0a_s_axi_awlen = s_axi_aw_fifo_dout[14:7];
  assign oculink_0a_s_axi_awregion = s_axi_aw_fifo_dout[6:3];
  assign oculink_0a_s_axi_awsize = s_axi_aw_fifo_dout[2:0];
  assign oculink_0a_s_axi_awvalid = s_axi_aw_fifo_valid;

  s_axi_ar_fifo s_axi_aw_fifo_i (
    .srst(!rstn),
    .wr_clk(bram_clk),
    .rd_clk(axi_clk),
    .din(s_axi_aw_fifo_din),
    .wr_en(s_axi_awvalid),
    .rd_en(oculink_0a_s_axi_awready && !s_axi_aw_fifo_empty), 
    .dout(s_axi_aw_fifo_dout),
    .full(s_axi_aw_fifo_full),
    .empty(s_axi_aw_fifo_empty),
    .valid(s_axi_aw_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );



  // s axi w fifo signals
  // w : 256 + 1 + 32 = 289
  logic [288:0] s_axi_w_fifo_din;
  logic [288:0] s_axi_w_fifo_dout;
  logic s_axi_w_fifo_valid;

  assign s_axi_w_fifo_din = { s_axi_wdata,    // 256
                              s_axi_wlast,    // 1
                              s_axi_wstrb};   // 32

  assign oculink_0a_s_axi_wdata = s_axi_w_fifo_dout[288:33];  // 256
  assign oculink_0a_s_axi_wlast = s_axi_w_fifo_dout[32];      // 1
  assign oculink_0a_s_axi_wstrb = s_axi_w_fifo_dout[31:0];    // 32
  assign oculink_0a_s_axi_wvalid = s_axi_w_fifo_valid;

  s_axi_w_fifo s_axi_w_fifo_i (
    .srst(!rstn),
    .wr_clk(bram_clk),
    .rd_clk(axi_clk),
    .din(s_axi_w_fifo_din),
    .wr_en(s_axi_wvalid),
    .rd_en(oculink_0a_s_axi_wready && !s_axi_w_fifo_empty), 
    .dout(s_axi_w_fifo_dout),
    .full(s_axi_w_fifo_full),
    .empty(s_axi_w_fifo_empty),
    .valid(s_axi_w_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );


  // s axi r fifo signals
  // r : 256 + 4 + 1 + 2 = 263
  logic [262:0] s_axi_r_fifo_din;
  logic [262:0] s_axi_r_fifo_dout;

  assign oculink_0a_s_axi_rready = !s_axi_r_fifo_full;
  assign s_axi_r_fifo_din = {
                              oculink_0a_s_axi_rdata,   // 256
                              oculink_0a_s_axi_rid,     // 4
                              oculink_0a_s_axi_rlast,   // 1
                              oculink_0a_s_axi_rresp    // 2         
                            };

  assign s_axi_rdata = s_axi_r_fifo_dout[262:7];
  assign s_axi_rid = s_axi_r_fifo_dout[6:3];
  assign s_axi_rlast = s_axi_r_fifo_dout[2];
  assign s_axi_rresp = s_axi_r_fifo_dout[1:0];

  s_axi_r_fifo s_axi_r_fifo_i (
    .srst(!rstn),
    .wr_clk(axi_clk),
    .rd_clk(bram_clk),
    .din(s_axi_r_fifo_din),
    .wr_en(oculink_0a_s_axi_rvalid),
    .rd_en(s_axi_r_fifo_pop && !s_axi_r_fifo_empty), 
    .dout(s_axi_r_fifo_dout),
    .full(s_axi_r_fifo_full),
    .empty(s_axi_r_fifo_empty),
    .valid(s_axi_r_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );

  // s axi b fifo signals
  // b : 4 + 2 = 6
  logic [5:0] s_axi_b_fifo_din;
  logic [5:0] s_axi_b_fifo_dout;

  assign oculink_0a_s_axi_bready = !s_axi_b_fifo_full;
  assign s_axi_b_fifo_din = {
                              oculink_0a_s_axi_bid,     // 4
                              oculink_0a_s_axi_bresp    // 2
                            };

  assign s_axi_bid = s_axi_b_fifo_dout[5:2];
  assign s_axi_bresp = s_axi_b_fifo_dout[1:0];

  s_axi_b_fifo s_axi_b_fifo_i (
    .srst(!rstn),
    .wr_clk(axi_clk),
    .rd_clk(bram_clk),
    .din(s_axi_b_fifo_din),
    .wr_en(oculink_0a_s_axi_bvalid),
    .rd_en(s_axi_b_fifo_pop && !s_axi_b_fifo_empty), 
    .dout(s_axi_b_fifo_dout),
    .full(s_axi_b_fifo_full),
    .empty(s_axi_b_fifo_empty),
    .valid(s_axi_b_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );


  // m axi ar fifo signals
  // ar : 32 + 2 + 4  + 8 + 3 = 49
  logic [48:0] m_axi_ar_fifo_din;
  logic [48:0] m_axi_ar_fifo_dout;

  assign oculink_0a_m_axi_arready = !m_axi_ar_fifo_full;
  assign m_axi_ar_fifo_din = {
                              oculink_0a_m_axi_araddr,  // 32  
                              oculink_0a_m_axi_arburst, // 2  
                              oculink_0a_m_axi_arid,    // 4
                              oculink_0a_m_axi_arlen,   // 8
                              oculink_0a_m_axi_arsize   // 3  
                            };

  assign m_axi_araddr  = m_axi_ar_fifo_dout[48:17];
  assign m_axi_arburst = m_axi_ar_fifo_dout[16:15];
  assign m_axi_arid = m_axi_ar_fifo_dout[14:11];
  assign m_axi_arlen = m_axi_ar_fifo_dout[10:3];
  assign m_axi_arsize = m_axi_ar_fifo_dout[2:0];

  m_axi_ar_fifo m_axi_ar_fifo_i (
    .srst(!rstn),
    .wr_clk(axi_clk),
    .rd_clk(bram_clk),
    .din(m_axi_ar_fifo_din),
    .wr_en(oculink_0a_m_axi_arvalid),
    .rd_en(m_axi_ar_fifo_pop && !m_axi_ar_fifo_empty), 
    .dout(m_axi_ar_fifo_dout),
    .full(m_axi_ar_fifo_full),
    .empty(m_axi_ar_fifo_empty),
    .valid(m_axi_ar_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );


  // m axi aw fifo signals
  // aw : 32 + 2 + 4  + 8 + 3 = 49
  logic [48:0] m_axi_aw_fifo_din;
  logic [48:0] m_axi_aw_fifo_dout;

  assign oculink_0a_m_axi_awready = !m_axi_aw_fifo_full;
  assign m_axi_aw_fifo_din = {
                              oculink_0a_m_axi_awaddr,  // 32  
                              oculink_0a_m_axi_awburst, // 2  
                              oculink_0a_m_axi_awid,    // 4
                              oculink_0a_m_axi_awlen,   // 8
                              oculink_0a_m_axi_awsize   // 3  
                            };

  assign m_axi_awdata  = m_axi_aw_fifo_dout[48:17];
  assign m_axi_awburst = m_axi_aw_fifo_dout[16:15];
  assign m_axi_awid = m_axi_aw_fifo_dout[14:11];
  assign m_axi_awlen = m_axi_aw_fifo_dout[10:3];
  assign m_axi_awsize = m_axi_aw_fifo_dout[2:0];

  m_axi_ar_fifo m_axi_aw_fifo_i (
    .srst(!rstn),
    .wr_clk(axi_clk),
    .rd_clk(bram_clk),
    .din(m_axi_aw_fifo_din),
    .wr_en(oculink_0a_m_axi_awvalid),
    .rd_en(m_axi_aw_fifo_pop && !m_axi_aw_fifo_empty), 
    .dout(m_axi_aw_fifo_dout),
    .full(m_axi_aw_fifo_full),
    .empty(m_axi_aw_fifo_empty),
    .valid(m_axi_aw_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );


  // m axi w fifo signals
  // w : 256 + 1 + 32  = 289
  logic [288:0] m_axi_w_fifo_din;
  logic [288:0] m_axi_w_fifo_dout;

  assign oculink_0a_m_axi_wready = !m_axi_w_fifo_full;
  assign m_axi_w_fifo_din = {
                              oculink_0a_m_axi_wdata,  // 256
                              oculink_0a_m_axi_wlast,  // 1  
                              oculink_0a_m_axi_wstrb  // 32
                            };

  assign m_axi_wdata  = m_axi_w_fifo_dout[288:33];
  assign m_axi_wlast = m_axi_w_fifo_dout[32];
  assign m_axi_wstrb = m_axi_w_fifo_dout[31:0];

  m_axi_w_fifo m_axi_w_fifo_i (
    .srst(!rstn),
    .wr_clk(axi_clk),
    .rd_clk(bram_clk),
    .din(m_axi_w_fifo_din),
    .wr_en(oculink_0a_m_axi_wvalid),
    .rd_en(m_axi_w_fifo_pop && !m_axi_w_fifo_empty), 
    .dout(m_axi_w_fifo_dout),
    .full(m_axi_w_fifo_full),
    .empty(m_axi_w_fifo_empty),
    .valid(m_axi_w_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );


  // m axi r fifo signals
  // r : 256 + 4 + 1 + 2 = 263
  logic [262:0] m_axi_r_fifo_din;
  logic [262:0] m_axi_r_fifo_dout;
  logic m_axi_r_fifo_valid;

  assign m_axi_r_fifo_din = { 
                              m_axi_rdata,  // 256
                              m_axi_rid,    // 4
                              m_axi_rlast,  // 1
                              m_axi_rresp  // 2
                            };
  
  assign oculink_0a_m_axi_rdata = m_axi_r_fifo_dout[262:7];
  assign oculink_0a_m_axi_rid = m_axi_r_fifo_dout[6:3];
  assign oculink_0a_m_axi_rlast = m_axi_r_fifo_dout[2];
  assign oculink_0a_m_axi_rresp = m_axi_r_fifo_dout[1:0];
  assign oculink_0a_m_axi_rvalid = m_axi_r_fifo_valid;

  m_axi_r_fifo m_axi_r_fifo_i (
    .srst(!rstn),
    .wr_clk(bram_clk),
    .rd_clk(axi_clk),
    .din(m_axi_r_fifo_din),
    .wr_en(m_axi_rvalid),
    .rd_en(oculink_0a_m_axi_rready && !m_axi_r_fifo_empty), 
    .dout(m_axi_r_fifo_dout),
    .full(m_axi_r_fifo_full),
    .empty(m_axi_r_fifo_empty),
    .valid(m_axi_r_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );


  // m axi b fifo signals
  // b : 4 + 2 = 6
  logic [5:0] m_axi_b_fifo_din;
  logic [5:0] m_axi_b_fifo_dout;
  logic m_axi_b_fifo_valid;

  assign m_axi_b_fifo_din = { 
                              m_axi_bid,   // 4
                              m_axi_bresp  // 2
                            };
  
  assign oculink_0a_m_axi_bid = m_axi_b_fifo_dout[5:2];
  assign oculink_0a_m_axi_bresp = m_axi_b_fifo_dout[1:0];
  assign oculink_0a_m_axi_bvalid = m_axi_b_fifo_valid;
  
  m_axi_b_fifo m_axi_b_fifo_i (
    .srst(!rstn),
    .wr_clk(bram_clk),
    .rd_clk(axi_clk),
    .din(m_axi_b_fifo_din),
    .wr_en(m_axi_bvalid),
    .rd_en(oculink_0a_m_axi_bready && !m_axi_b_fifo_empty), 
    .dout(m_axi_b_fifo_dout),
    .full(m_axi_b_fifo_full),
    .empty(m_axi_b_fifo_empty),
    .valid(m_axi_b_fifo_valid),
    .wr_rst_busy(),
    .rd_rst_busy()
  );

endmodule