//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
//Date        : Tue Nov 14 16:36:35 2023
//Host        : DESKTOP-4NHVH8R running 64-bit major release  (build 9200)
//Command     : generate_target oculink_0a_bd_wrapper.bd
//Design      : oculink_0a_bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module oculink_0a_bd_wrapper
   (oculink_0a_axi_aclk,
    oculink_0a_axi_rstn,
    oculink_0a_m_axi_araddr,
    oculink_0a_m_axi_arburst,
    oculink_0a_m_axi_arcache,
    oculink_0a_m_axi_arid,
    oculink_0a_m_axi_arlen,
    oculink_0a_m_axi_arlock,
    oculink_0a_m_axi_arprot,
    oculink_0a_m_axi_arready,
    oculink_0a_m_axi_arsize,
    oculink_0a_m_axi_arvalid,
    oculink_0a_m_axi_awaddr,
    oculink_0a_m_axi_awburst,
    oculink_0a_m_axi_awcache,
    oculink_0a_m_axi_awid,
    oculink_0a_m_axi_awlen,
    oculink_0a_m_axi_awlock,
    oculink_0a_m_axi_awprot,
    oculink_0a_m_axi_awready,
    oculink_0a_m_axi_awsize,
    oculink_0a_m_axi_awvalid,
    oculink_0a_m_axi_bid,
    oculink_0a_m_axi_bready,
    oculink_0a_m_axi_bresp,
    oculink_0a_m_axi_bvalid,
    oculink_0a_m_axi_rdata,
    oculink_0a_m_axi_rid,
    oculink_0a_m_axi_rlast,
    oculink_0a_m_axi_rready,
    oculink_0a_m_axi_rresp,
    oculink_0a_m_axi_rvalid,
    oculink_0a_m_axi_wdata,
    oculink_0a_m_axi_wlast,
    oculink_0a_m_axi_wready,
    oculink_0a_m_axi_wstrb,
    oculink_0a_m_axi_wvalid,
    oculink_0a_mgt_rxn,
    oculink_0a_mgt_rxp,
    oculink_0a_mgt_txn,
    oculink_0a_mgt_txp,
    oculink_0a_ref_clk_n,
    oculink_0a_ref_clk_p,
    oculink_0a_rstn,
    oculink_0a_s_axi_araddr,
    oculink_0a_s_axi_arburst,
    oculink_0a_s_axi_arcache,
    oculink_0a_s_axi_arlen,
    oculink_0a_s_axi_arlock,
    oculink_0a_s_axi_arprot,
    oculink_0a_s_axi_arqos,
    oculink_0a_s_axi_arready,
    oculink_0a_s_axi_arsize,
    oculink_0a_s_axi_arvalid,
    oculink_0a_s_axi_awaddr,
    oculink_0a_s_axi_awburst,
    oculink_0a_s_axi_awcache,
    oculink_0a_s_axi_awlen,
    oculink_0a_s_axi_awlock,
    oculink_0a_s_axi_awprot,
    oculink_0a_s_axi_awqos,
    oculink_0a_s_axi_awready,
    oculink_0a_s_axi_awsize,
    oculink_0a_s_axi_awvalid,
    oculink_0a_s_axi_bready,
    oculink_0a_s_axi_bresp,
    oculink_0a_s_axi_bvalid,
    oculink_0a_s_axi_rdata,
    oculink_0a_s_axi_rlast,
    oculink_0a_s_axi_rready,
    oculink_0a_s_axi_rresp,
    oculink_0a_s_axi_rvalid,
    oculink_0a_s_axi_wdata,
    oculink_0a_s_axi_wlast,
    oculink_0a_s_axi_wready,
    oculink_0a_s_axi_wstrb,
    oculink_0a_s_axi_wvalid);
  output oculink_0a_axi_aclk;
  output oculink_0a_axi_rstn;
  output [31:0]oculink_0a_m_axi_araddr;
  output [1:0]oculink_0a_m_axi_arburst;
  output [3:0]oculink_0a_m_axi_arcache;
  output [3:0]oculink_0a_m_axi_arid;
  output [7:0]oculink_0a_m_axi_arlen;
  output oculink_0a_m_axi_arlock;
  output [2:0]oculink_0a_m_axi_arprot;
  input oculink_0a_m_axi_arready;
  output [2:0]oculink_0a_m_axi_arsize;
  output oculink_0a_m_axi_arvalid;
  output [31:0]oculink_0a_m_axi_awaddr;
  output [1:0]oculink_0a_m_axi_awburst;
  output [3:0]oculink_0a_m_axi_awcache;
  output [3:0]oculink_0a_m_axi_awid;
  output [7:0]oculink_0a_m_axi_awlen;
  output oculink_0a_m_axi_awlock;
  output [2:0]oculink_0a_m_axi_awprot;
  input oculink_0a_m_axi_awready;
  output [2:0]oculink_0a_m_axi_awsize;
  output oculink_0a_m_axi_awvalid;
  input [3:0]oculink_0a_m_axi_bid;
  output oculink_0a_m_axi_bready;
  input [1:0]oculink_0a_m_axi_bresp;
  input oculink_0a_m_axi_bvalid;
  input [255:0]oculink_0a_m_axi_rdata;
  input [3:0]oculink_0a_m_axi_rid;
  input oculink_0a_m_axi_rlast;
  output oculink_0a_m_axi_rready;
  input [1:0]oculink_0a_m_axi_rresp;
  input oculink_0a_m_axi_rvalid;
  output [255:0]oculink_0a_m_axi_wdata;
  output oculink_0a_m_axi_wlast;
  input oculink_0a_m_axi_wready;
  output [31:0]oculink_0a_m_axi_wstrb;
  output oculink_0a_m_axi_wvalid;
  input [3:0]oculink_0a_mgt_rxn;
  input [3:0]oculink_0a_mgt_rxp;
  output [3:0]oculink_0a_mgt_txn;
  output [3:0]oculink_0a_mgt_txp;
  input [0:0]oculink_0a_ref_clk_n;
  input [0:0]oculink_0a_ref_clk_p;
  input oculink_0a_rstn;
  input [31:0]oculink_0a_s_axi_araddr;
  input [1:0]oculink_0a_s_axi_arburst;
  input [3:0]oculink_0a_s_axi_arcache;
  input [7:0]oculink_0a_s_axi_arlen;
  input [0:0]oculink_0a_s_axi_arlock;
  input [2:0]oculink_0a_s_axi_arprot;
  input [3:0]oculink_0a_s_axi_arqos;
  output oculink_0a_s_axi_arready;
  input [2:0]oculink_0a_s_axi_arsize;
  input oculink_0a_s_axi_arvalid;
  input [31:0]oculink_0a_s_axi_awaddr;
  input [1:0]oculink_0a_s_axi_awburst;
  input [3:0]oculink_0a_s_axi_awcache;
  input [7:0]oculink_0a_s_axi_awlen;
  input [0:0]oculink_0a_s_axi_awlock;
  input [2:0]oculink_0a_s_axi_awprot;
  input [3:0]oculink_0a_s_axi_awqos;
  output oculink_0a_s_axi_awready;
  input [2:0]oculink_0a_s_axi_awsize;
  input oculink_0a_s_axi_awvalid;
  input oculink_0a_s_axi_bready;
  output [1:0]oculink_0a_s_axi_bresp;
  output oculink_0a_s_axi_bvalid;
  output [31:0]oculink_0a_s_axi_rdata;
  output oculink_0a_s_axi_rlast;
  input oculink_0a_s_axi_rready;
  output [1:0]oculink_0a_s_axi_rresp;
  output oculink_0a_s_axi_rvalid;
  input [31:0]oculink_0a_s_axi_wdata;
  input oculink_0a_s_axi_wlast;
  output oculink_0a_s_axi_wready;
  input [3:0]oculink_0a_s_axi_wstrb;
  input oculink_0a_s_axi_wvalid;

  wire oculink_0a_axi_aclk;
  wire oculink_0a_axi_rstn;
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
  wire [3:0]oculink_0a_mgt_rxn;
  wire [3:0]oculink_0a_mgt_rxp;
  wire [3:0]oculink_0a_mgt_txn;
  wire [3:0]oculink_0a_mgt_txp;
  wire [0:0]oculink_0a_ref_clk_n;
  wire [0:0]oculink_0a_ref_clk_p;
  wire oculink_0a_rstn;
  wire [31:0]oculink_0a_s_axi_araddr;
  wire [1:0]oculink_0a_s_axi_arburst;
  wire [3:0]oculink_0a_s_axi_arcache;
  wire [7:0]oculink_0a_s_axi_arlen;
  wire [0:0]oculink_0a_s_axi_arlock;
  wire [2:0]oculink_0a_s_axi_arprot;
  wire [3:0]oculink_0a_s_axi_arqos;
  wire oculink_0a_s_axi_arready;
  wire [2:0]oculink_0a_s_axi_arsize;
  wire oculink_0a_s_axi_arvalid;
  wire [31:0]oculink_0a_s_axi_awaddr;
  wire [1:0]oculink_0a_s_axi_awburst;
  wire [3:0]oculink_0a_s_axi_awcache;
  wire [7:0]oculink_0a_s_axi_awlen;
  wire [0:0]oculink_0a_s_axi_awlock;
  wire [2:0]oculink_0a_s_axi_awprot;
  wire [3:0]oculink_0a_s_axi_awqos;
  wire oculink_0a_s_axi_awready;
  wire [2:0]oculink_0a_s_axi_awsize;
  wire oculink_0a_s_axi_awvalid;
  wire oculink_0a_s_axi_bready;
  wire [1:0]oculink_0a_s_axi_bresp;
  wire oculink_0a_s_axi_bvalid;
  wire [31:0]oculink_0a_s_axi_rdata;
  wire oculink_0a_s_axi_rlast;
  wire oculink_0a_s_axi_rready;
  wire [1:0]oculink_0a_s_axi_rresp;
  wire oculink_0a_s_axi_rvalid;
  wire [31:0]oculink_0a_s_axi_wdata;
  wire oculink_0a_s_axi_wlast;
  wire oculink_0a_s_axi_wready;
  wire [3:0]oculink_0a_s_axi_wstrb;
  wire oculink_0a_s_axi_wvalid;

  oculink_0a_bd oculink_0a_bd_i
       (.oculink_0a_axi_aclk(oculink_0a_axi_aclk),
        .oculink_0a_axi_rstn(oculink_0a_axi_rstn),
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
        .oculink_0a_mgt_rxn(oculink_0a_mgt_rxn),
        .oculink_0a_mgt_rxp(oculink_0a_mgt_rxp),
        .oculink_0a_mgt_txn(oculink_0a_mgt_txn),
        .oculink_0a_mgt_txp(oculink_0a_mgt_txp),
        .oculink_0a_ref_clk_n(oculink_0a_ref_clk_n),
        .oculink_0a_ref_clk_p(oculink_0a_ref_clk_p),
        .oculink_0a_rstn(oculink_0a_rstn),
        .oculink_0a_s_axi_araddr(oculink_0a_s_axi_araddr),
        .oculink_0a_s_axi_arburst(oculink_0a_s_axi_arburst),
        .oculink_0a_s_axi_arcache(oculink_0a_s_axi_arcache),
        .oculink_0a_s_axi_arlen(oculink_0a_s_axi_arlen),
        .oculink_0a_s_axi_arlock(oculink_0a_s_axi_arlock),
        .oculink_0a_s_axi_arprot(oculink_0a_s_axi_arprot),
        .oculink_0a_s_axi_arqos(oculink_0a_s_axi_arqos),
        .oculink_0a_s_axi_arready(oculink_0a_s_axi_arready),
        .oculink_0a_s_axi_arsize(oculink_0a_s_axi_arsize),
        .oculink_0a_s_axi_arvalid(oculink_0a_s_axi_arvalid),
        .oculink_0a_s_axi_awaddr(oculink_0a_s_axi_awaddr),
        .oculink_0a_s_axi_awburst(oculink_0a_s_axi_awburst),
        .oculink_0a_s_axi_awcache(oculink_0a_s_axi_awcache),
        .oculink_0a_s_axi_awlen(oculink_0a_s_axi_awlen),
        .oculink_0a_s_axi_awlock(oculink_0a_s_axi_awlock),
        .oculink_0a_s_axi_awprot(oculink_0a_s_axi_awprot),
        .oculink_0a_s_axi_awqos(oculink_0a_s_axi_awqos),
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
        .oculink_0a_s_axi_wvalid(oculink_0a_s_axi_wvalid));
endmodule
