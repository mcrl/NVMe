//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
//Date        : Tue Nov 14 16:36:35 2023
//Host        : DESKTOP-4NHVH8R running 64-bit major release  (build 9200)
//Command     : generate_target oculink_0a_bd.bd
//Design      : oculink_0a_bd
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "oculink_0a_bd,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=oculink_0a_bd,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=4,numReposBlks=4,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,da_board_cnt=3,da_xdma_cnt=1,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "oculink_0a_bd.hwdef" *) 
module oculink_0a_bd
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
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.OCULINK_0A_AXI_ACLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.OCULINK_0A_AXI_ACLK, ASSOCIATED_BUSIF oculink_0a_s_axi:oculink_0a_m_axi, CLK_DOMAIN oculink_0a_bd_xdma_0_0_axi_aclk, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) output oculink_0a_axi_aclk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.OCULINK_0A_AXI_RSTN RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.OCULINK_0A_AXI_RSTN, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) output oculink_0a_axi_rstn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARADDR" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME oculink_0a_m_axi, ADDR_WIDTH 32, ARUSER_WIDTH 0, AWUSER_WIDTH 0, BUSER_WIDTH 0, CLK_DOMAIN oculink_0a_bd_xdma_0_0_axi_aclk, DATA_WIDTH 256, FREQ_HZ 125000000, HAS_BRESP 1, HAS_BURST 0, HAS_CACHE 1, HAS_LOCK 1, HAS_PROT 1, HAS_QOS 0, HAS_REGION 0, HAS_RRESP 1, HAS_WSTRB 1, ID_WIDTH 4, INSERT_VIP 0, MAX_BURST_LENGTH 256, NUM_READ_OUTSTANDING 8, NUM_READ_THREADS 1, NUM_WRITE_OUTSTANDING 16, NUM_WRITE_THREADS 1, PHASE 0.0, PROTOCOL AXI4, READ_WRITE_MODE READ_WRITE, RUSER_BITS_PER_BYTE 0, RUSER_WIDTH 0, SUPPORTS_NARROW_BURST 0, WUSER_BITS_PER_BYTE 0, WUSER_WIDTH 0" *) output [31:0]oculink_0a_m_axi_araddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARBURST" *) output [1:0]oculink_0a_m_axi_arburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARCACHE" *) output [3:0]oculink_0a_m_axi_arcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARID" *) output [3:0]oculink_0a_m_axi_arid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARLEN" *) output [7:0]oculink_0a_m_axi_arlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARLOCK" *) output oculink_0a_m_axi_arlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARPROT" *) output [2:0]oculink_0a_m_axi_arprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARREADY" *) input oculink_0a_m_axi_arready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARSIZE" *) output [2:0]oculink_0a_m_axi_arsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARVALID" *) output oculink_0a_m_axi_arvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWADDR" *) output [31:0]oculink_0a_m_axi_awaddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWBURST" *) output [1:0]oculink_0a_m_axi_awburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWCACHE" *) output [3:0]oculink_0a_m_axi_awcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWID" *) output [3:0]oculink_0a_m_axi_awid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWLEN" *) output [7:0]oculink_0a_m_axi_awlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWLOCK" *) output oculink_0a_m_axi_awlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWPROT" *) output [2:0]oculink_0a_m_axi_awprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWREADY" *) input oculink_0a_m_axi_awready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWSIZE" *) output [2:0]oculink_0a_m_axi_awsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWVALID" *) output oculink_0a_m_axi_awvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi BID" *) input [3:0]oculink_0a_m_axi_bid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi BREADY" *) output oculink_0a_m_axi_bready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi BRESP" *) input [1:0]oculink_0a_m_axi_bresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi BVALID" *) input oculink_0a_m_axi_bvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RDATA" *) input [255:0]oculink_0a_m_axi_rdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RID" *) input [3:0]oculink_0a_m_axi_rid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RLAST" *) input oculink_0a_m_axi_rlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RREADY" *) output oculink_0a_m_axi_rready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RRESP" *) input [1:0]oculink_0a_m_axi_rresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RVALID" *) input oculink_0a_m_axi_rvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi WDATA" *) output [255:0]oculink_0a_m_axi_wdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi WLAST" *) output oculink_0a_m_axi_wlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi WREADY" *) input oculink_0a_m_axi_wready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi WSTRB" *) output [31:0]oculink_0a_m_axi_wstrb;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi WVALID" *) output oculink_0a_m_axi_wvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 oculink_0a_mgt rxn" *) input [3:0]oculink_0a_mgt_rxn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 oculink_0a_mgt rxp" *) input [3:0]oculink_0a_mgt_rxp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 oculink_0a_mgt txn" *) output [3:0]oculink_0a_mgt_txn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 oculink_0a_mgt txp" *) output [3:0]oculink_0a_mgt_txp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 oculink_0a_ref CLK_N" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME oculink_0a_ref, CAN_DEBUG false, FREQ_HZ 100000000" *) input [0:0]oculink_0a_ref_clk_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 oculink_0a_ref CLK_P" *) input [0:0]oculink_0a_ref_clk_p;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.OCULINK_0A_RSTN RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.OCULINK_0A_RSTN, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) input oculink_0a_rstn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARADDR" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME oculink_0a_s_axi, ADDR_WIDTH 32, ARUSER_WIDTH 0, AWUSER_WIDTH 0, BUSER_WIDTH 0, CLK_DOMAIN oculink_0a_bd_xdma_0_0_axi_aclk, DATA_WIDTH 32, FREQ_HZ 125000000, HAS_BRESP 1, HAS_BURST 1, HAS_CACHE 1, HAS_LOCK 1, HAS_PROT 1, HAS_QOS 1, HAS_REGION 1, HAS_RRESP 1, HAS_WSTRB 1, ID_WIDTH 0, INSERT_VIP 0, MAX_BURST_LENGTH 256, NUM_READ_OUTSTANDING 1, NUM_READ_THREADS 1, NUM_WRITE_OUTSTANDING 1, NUM_WRITE_THREADS 1, PHASE 0.0, PROTOCOL AXI4, READ_WRITE_MODE READ_WRITE, RUSER_BITS_PER_BYTE 0, RUSER_WIDTH 0, SUPPORTS_NARROW_BURST 1, WUSER_BITS_PER_BYTE 0, WUSER_WIDTH 0" *) input [31:0]oculink_0a_s_axi_araddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARBURST" *) input [1:0]oculink_0a_s_axi_arburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARCACHE" *) input [3:0]oculink_0a_s_axi_arcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARLEN" *) input [7:0]oculink_0a_s_axi_arlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARLOCK" *) input [0:0]oculink_0a_s_axi_arlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARPROT" *) input [2:0]oculink_0a_s_axi_arprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARQOS" *) input [3:0]oculink_0a_s_axi_arqos;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARREADY" *) output oculink_0a_s_axi_arready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARSIZE" *) input [2:0]oculink_0a_s_axi_arsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARVALID" *) input oculink_0a_s_axi_arvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWADDR" *) input [31:0]oculink_0a_s_axi_awaddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWBURST" *) input [1:0]oculink_0a_s_axi_awburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWCACHE" *) input [3:0]oculink_0a_s_axi_awcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWLEN" *) input [7:0]oculink_0a_s_axi_awlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWLOCK" *) input [0:0]oculink_0a_s_axi_awlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWPROT" *) input [2:0]oculink_0a_s_axi_awprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWQOS" *) input [3:0]oculink_0a_s_axi_awqos;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWREADY" *) output oculink_0a_s_axi_awready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWSIZE" *) input [2:0]oculink_0a_s_axi_awsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWVALID" *) input oculink_0a_s_axi_awvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi BREADY" *) input oculink_0a_s_axi_bready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi BRESP" *) output [1:0]oculink_0a_s_axi_bresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi BVALID" *) output oculink_0a_s_axi_bvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi RDATA" *) output [31:0]oculink_0a_s_axi_rdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi RLAST" *) output oculink_0a_s_axi_rlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi RREADY" *) input oculink_0a_s_axi_rready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi RRESP" *) output [1:0]oculink_0a_s_axi_rresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi RVALID" *) output oculink_0a_s_axi_rvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi WDATA" *) input [31:0]oculink_0a_s_axi_wdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi WLAST" *) input oculink_0a_s_axi_wlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi WREADY" *) output oculink_0a_s_axi_wready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi WSTRB" *) input [3:0]oculink_0a_s_axi_wstrb;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi WVALID" *) input oculink_0a_s_axi_wvalid;

  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 ARADDR" *) (* DONT_TOUCH *) wire [31:0]S00_AXI_0_1_ARADDR;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 ARBURST" *) (* DONT_TOUCH *) wire [1:0]S00_AXI_0_1_ARBURST;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 ARCACHE" *) (* DONT_TOUCH *) wire [3:0]S00_AXI_0_1_ARCACHE;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 ARLEN" *) (* DONT_TOUCH *) wire [7:0]S00_AXI_0_1_ARLEN;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 ARLOCK" *) (* DONT_TOUCH *) wire [0:0]S00_AXI_0_1_ARLOCK;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 ARPROT" *) (* DONT_TOUCH *) wire [2:0]S00_AXI_0_1_ARPROT;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 ARQOS" *) (* DONT_TOUCH *) wire [3:0]S00_AXI_0_1_ARQOS;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 ARREADY" *) (* DONT_TOUCH *) wire S00_AXI_0_1_ARREADY;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 ARSIZE" *) (* DONT_TOUCH *) wire [2:0]S00_AXI_0_1_ARSIZE;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 ARVALID" *) (* DONT_TOUCH *) wire S00_AXI_0_1_ARVALID;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 AWADDR" *) (* DONT_TOUCH *) wire [31:0]S00_AXI_0_1_AWADDR;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 AWBURST" *) (* DONT_TOUCH *) wire [1:0]S00_AXI_0_1_AWBURST;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 AWCACHE" *) (* DONT_TOUCH *) wire [3:0]S00_AXI_0_1_AWCACHE;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 AWLEN" *) (* DONT_TOUCH *) wire [7:0]S00_AXI_0_1_AWLEN;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 AWLOCK" *) (* DONT_TOUCH *) wire [0:0]S00_AXI_0_1_AWLOCK;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 AWPROT" *) (* DONT_TOUCH *) wire [2:0]S00_AXI_0_1_AWPROT;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 AWQOS" *) (* DONT_TOUCH *) wire [3:0]S00_AXI_0_1_AWQOS;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 AWREADY" *) (* DONT_TOUCH *) wire S00_AXI_0_1_AWREADY;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 AWSIZE" *) (* DONT_TOUCH *) wire [2:0]S00_AXI_0_1_AWSIZE;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 AWVALID" *) (* DONT_TOUCH *) wire S00_AXI_0_1_AWVALID;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 BREADY" *) (* DONT_TOUCH *) wire S00_AXI_0_1_BREADY;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 BRESP" *) (* DONT_TOUCH *) wire [1:0]S00_AXI_0_1_BRESP;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 BVALID" *) (* DONT_TOUCH *) wire S00_AXI_0_1_BVALID;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 RDATA" *) (* DONT_TOUCH *) wire [31:0]S00_AXI_0_1_RDATA;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 RLAST" *) (* DONT_TOUCH *) wire S00_AXI_0_1_RLAST;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 RREADY" *) (* DONT_TOUCH *) wire S00_AXI_0_1_RREADY;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 RRESP" *) (* DONT_TOUCH *) wire [1:0]S00_AXI_0_1_RRESP;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 RVALID" *) (* DONT_TOUCH *) wire S00_AXI_0_1_RVALID;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 WDATA" *) (* DONT_TOUCH *) wire [31:0]S00_AXI_0_1_WDATA;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 WLAST" *) (* DONT_TOUCH *) wire S00_AXI_0_1_WLAST;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 WREADY" *) (* DONT_TOUCH *) wire S00_AXI_0_1_WREADY;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 WSTRB" *) (* DONT_TOUCH *) wire [3:0]S00_AXI_0_1_WSTRB;
  (* CONN_BUS_INFO = "S00_AXI_0_1 xilinx.com:interface:aximm:1.0 AXI4 WVALID" *) (* DONT_TOUCH *) wire S00_AXI_0_1_WVALID;
  wire [0:0]diff_clock_rtl_0_1_CLK_N;
  wire [0:0]diff_clock_rtl_0_1_CLK_P;
  wire reset_rtl_0_1;
  wire [31:0]smartconnect_0_M00_AXI_ARADDR;
  wire [1:0]smartconnect_0_M00_AXI_ARBURST;
  wire [7:0]smartconnect_0_M00_AXI_ARLEN;
  wire smartconnect_0_M00_AXI_ARREADY;
  wire [2:0]smartconnect_0_M00_AXI_ARSIZE;
  wire smartconnect_0_M00_AXI_ARVALID;
  wire [31:0]smartconnect_0_M00_AXI_AWADDR;
  wire [1:0]smartconnect_0_M00_AXI_AWBURST;
  wire [7:0]smartconnect_0_M00_AXI_AWLEN;
  wire smartconnect_0_M00_AXI_AWREADY;
  wire [2:0]smartconnect_0_M00_AXI_AWSIZE;
  wire smartconnect_0_M00_AXI_AWVALID;
  wire smartconnect_0_M00_AXI_BREADY;
  wire [1:0]smartconnect_0_M00_AXI_BRESP;
  wire smartconnect_0_M00_AXI_BVALID;
  wire [255:0]smartconnect_0_M00_AXI_RDATA;
  wire smartconnect_0_M00_AXI_RLAST;
  wire smartconnect_0_M00_AXI_RREADY;
  wire [1:0]smartconnect_0_M00_AXI_RRESP;
  wire smartconnect_0_M00_AXI_RVALID;
  wire [255:0]smartconnect_0_M00_AXI_WDATA;
  wire smartconnect_0_M00_AXI_WLAST;
  wire smartconnect_0_M00_AXI_WREADY;
  wire [31:0]smartconnect_0_M00_AXI_WSTRB;
  wire smartconnect_0_M00_AXI_WVALID;
  wire [31:0]smartconnect_0_M01_AXI_ARADDR;
  wire [2:0]smartconnect_0_M01_AXI_ARPROT;
  wire smartconnect_0_M01_AXI_ARREADY;
  wire smartconnect_0_M01_AXI_ARVALID;
  wire [31:0]smartconnect_0_M01_AXI_AWADDR;
  wire [2:0]smartconnect_0_M01_AXI_AWPROT;
  wire smartconnect_0_M01_AXI_AWREADY;
  wire smartconnect_0_M01_AXI_AWVALID;
  wire smartconnect_0_M01_AXI_BREADY;
  wire [1:0]smartconnect_0_M01_AXI_BRESP;
  wire smartconnect_0_M01_AXI_BVALID;
  wire [31:0]smartconnect_0_M01_AXI_RDATA;
  wire smartconnect_0_M01_AXI_RREADY;
  wire [1:0]smartconnect_0_M01_AXI_RRESP;
  wire smartconnect_0_M01_AXI_RVALID;
  wire [31:0]smartconnect_0_M01_AXI_WDATA;
  wire smartconnect_0_M01_AXI_WREADY;
  wire [3:0]smartconnect_0_M01_AXI_WSTRB;
  wire smartconnect_0_M01_AXI_WVALID;
  wire [0:0]util_ds_buf_IBUF_DS_ODIV2;
  wire [0:0]util_ds_buf_IBUF_OUT;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 ARADDR" *) (* DONT_TOUCH *) wire [31:0]xdma_oculink_0a_M_AXI_B_ARADDR;
  wire [1:0]xdma_oculink_0a_M_AXI_B_ARBURST;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 ARCACHE" *) (* DONT_TOUCH *) wire [3:0]xdma_oculink_0a_M_AXI_B_ARCACHE;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 ARID" *) (* DONT_TOUCH *) wire [3:0]xdma_oculink_0a_M_AXI_B_ARID;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 ARLEN" *) (* DONT_TOUCH *) wire [7:0]xdma_oculink_0a_M_AXI_B_ARLEN;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 ARLOCK" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_ARLOCK;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 ARPROT" *) (* DONT_TOUCH *) wire [2:0]xdma_oculink_0a_M_AXI_B_ARPROT;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 ARREADY" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_ARREADY;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 ARSIZE" *) (* DONT_TOUCH *) wire [2:0]xdma_oculink_0a_M_AXI_B_ARSIZE;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 ARVALID" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_ARVALID;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 AWADDR" *) (* DONT_TOUCH *) wire [31:0]xdma_oculink_0a_M_AXI_B_AWADDR;
  wire [1:0]xdma_oculink_0a_M_AXI_B_AWBURST;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 AWCACHE" *) (* DONT_TOUCH *) wire [3:0]xdma_oculink_0a_M_AXI_B_AWCACHE;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 AWID" *) (* DONT_TOUCH *) wire [3:0]xdma_oculink_0a_M_AXI_B_AWID;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 AWLEN" *) (* DONT_TOUCH *) wire [7:0]xdma_oculink_0a_M_AXI_B_AWLEN;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 AWLOCK" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_AWLOCK;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 AWPROT" *) (* DONT_TOUCH *) wire [2:0]xdma_oculink_0a_M_AXI_B_AWPROT;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 AWREADY" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_AWREADY;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 AWSIZE" *) (* DONT_TOUCH *) wire [2:0]xdma_oculink_0a_M_AXI_B_AWSIZE;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 AWVALID" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_AWVALID;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 BID" *) (* DONT_TOUCH *) wire [3:0]xdma_oculink_0a_M_AXI_B_BID;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 BREADY" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_BREADY;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 BRESP" *) (* DONT_TOUCH *) wire [1:0]xdma_oculink_0a_M_AXI_B_BRESP;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 BVALID" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_BVALID;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 RDATA" *) (* DONT_TOUCH *) wire [255:0]xdma_oculink_0a_M_AXI_B_RDATA;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 RID" *) (* DONT_TOUCH *) wire [3:0]xdma_oculink_0a_M_AXI_B_RID;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 RLAST" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_RLAST;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 RREADY" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_RREADY;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 RRESP" *) (* DONT_TOUCH *) wire [1:0]xdma_oculink_0a_M_AXI_B_RRESP;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 RVALID" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_RVALID;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 WDATA" *) (* DONT_TOUCH *) wire [255:0]xdma_oculink_0a_M_AXI_B_WDATA;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 WLAST" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_WLAST;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 WREADY" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_WREADY;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 WSTRB" *) (* DONT_TOUCH *) wire [31:0]xdma_oculink_0a_M_AXI_B_WSTRB;
  (* CONN_BUS_INFO = "xdma_oculink_0a_M_AXI_B xilinx.com:interface:aximm:1.0 AXI4 WVALID" *) (* DONT_TOUCH *) wire xdma_oculink_0a_M_AXI_B_WVALID;
  wire xdma_oculink_0a_axi_aclk;
  wire xdma_oculink_0a_axi_aresetn;
  wire [3:0]xdma_oculink_0a_pcie_mgt_rxn;
  wire [3:0]xdma_oculink_0a_pcie_mgt_rxp;
  wire [3:0]xdma_oculink_0a_pcie_mgt_txn;
  wire [3:0]xdma_oculink_0a_pcie_mgt_txp;

  assign S00_AXI_0_1_ARADDR = oculink_0a_s_axi_araddr[31:0];
  assign S00_AXI_0_1_ARBURST = oculink_0a_s_axi_arburst[1:0];
  assign S00_AXI_0_1_ARCACHE = oculink_0a_s_axi_arcache[3:0];
  assign S00_AXI_0_1_ARLEN = oculink_0a_s_axi_arlen[7:0];
  assign S00_AXI_0_1_ARLOCK = oculink_0a_s_axi_arlock[0];
  assign S00_AXI_0_1_ARPROT = oculink_0a_s_axi_arprot[2:0];
  assign S00_AXI_0_1_ARQOS = oculink_0a_s_axi_arqos[3:0];
  assign S00_AXI_0_1_ARSIZE = oculink_0a_s_axi_arsize[2:0];
  assign S00_AXI_0_1_ARVALID = oculink_0a_s_axi_arvalid;
  assign S00_AXI_0_1_AWADDR = oculink_0a_s_axi_awaddr[31:0];
  assign S00_AXI_0_1_AWBURST = oculink_0a_s_axi_awburst[1:0];
  assign S00_AXI_0_1_AWCACHE = oculink_0a_s_axi_awcache[3:0];
  assign S00_AXI_0_1_AWLEN = oculink_0a_s_axi_awlen[7:0];
  assign S00_AXI_0_1_AWLOCK = oculink_0a_s_axi_awlock[0];
  assign S00_AXI_0_1_AWPROT = oculink_0a_s_axi_awprot[2:0];
  assign S00_AXI_0_1_AWQOS = oculink_0a_s_axi_awqos[3:0];
  assign S00_AXI_0_1_AWSIZE = oculink_0a_s_axi_awsize[2:0];
  assign S00_AXI_0_1_AWVALID = oculink_0a_s_axi_awvalid;
  assign S00_AXI_0_1_BREADY = oculink_0a_s_axi_bready;
  assign S00_AXI_0_1_RREADY = oculink_0a_s_axi_rready;
  assign S00_AXI_0_1_WDATA = oculink_0a_s_axi_wdata[31:0];
  assign S00_AXI_0_1_WLAST = oculink_0a_s_axi_wlast;
  assign S00_AXI_0_1_WSTRB = oculink_0a_s_axi_wstrb[3:0];
  assign S00_AXI_0_1_WVALID = oculink_0a_s_axi_wvalid;
  assign diff_clock_rtl_0_1_CLK_N = oculink_0a_ref_clk_n[0];
  assign diff_clock_rtl_0_1_CLK_P = oculink_0a_ref_clk_p[0];
  assign oculink_0a_axi_aclk = xdma_oculink_0a_axi_aclk;
  assign oculink_0a_axi_rstn = xdma_oculink_0a_axi_aresetn;
  assign oculink_0a_m_axi_araddr[31:0] = xdma_oculink_0a_M_AXI_B_ARADDR;
  assign oculink_0a_m_axi_arburst[1:0] = xdma_oculink_0a_M_AXI_B_ARBURST;
  assign oculink_0a_m_axi_arcache[3:0] = xdma_oculink_0a_M_AXI_B_ARCACHE;
  assign oculink_0a_m_axi_arid[3:0] = xdma_oculink_0a_M_AXI_B_ARID;
  assign oculink_0a_m_axi_arlen[7:0] = xdma_oculink_0a_M_AXI_B_ARLEN;
  assign oculink_0a_m_axi_arlock = xdma_oculink_0a_M_AXI_B_ARLOCK;
  assign oculink_0a_m_axi_arprot[2:0] = xdma_oculink_0a_M_AXI_B_ARPROT;
  assign oculink_0a_m_axi_arsize[2:0] = xdma_oculink_0a_M_AXI_B_ARSIZE;
  assign oculink_0a_m_axi_arvalid = xdma_oculink_0a_M_AXI_B_ARVALID;
  assign oculink_0a_m_axi_awaddr[31:0] = xdma_oculink_0a_M_AXI_B_AWADDR;
  assign oculink_0a_m_axi_awburst[1:0] = xdma_oculink_0a_M_AXI_B_AWBURST;
  assign oculink_0a_m_axi_awcache[3:0] = xdma_oculink_0a_M_AXI_B_AWCACHE;
  assign oculink_0a_m_axi_awid[3:0] = xdma_oculink_0a_M_AXI_B_AWID;
  assign oculink_0a_m_axi_awlen[7:0] = xdma_oculink_0a_M_AXI_B_AWLEN;
  assign oculink_0a_m_axi_awlock = xdma_oculink_0a_M_AXI_B_AWLOCK;
  assign oculink_0a_m_axi_awprot[2:0] = xdma_oculink_0a_M_AXI_B_AWPROT;
  assign oculink_0a_m_axi_awsize[2:0] = xdma_oculink_0a_M_AXI_B_AWSIZE;
  assign oculink_0a_m_axi_awvalid = xdma_oculink_0a_M_AXI_B_AWVALID;
  assign oculink_0a_m_axi_bready = xdma_oculink_0a_M_AXI_B_BREADY;
  assign oculink_0a_m_axi_rready = xdma_oculink_0a_M_AXI_B_RREADY;
  assign oculink_0a_m_axi_wdata[255:0] = xdma_oculink_0a_M_AXI_B_WDATA;
  assign oculink_0a_m_axi_wlast = xdma_oculink_0a_M_AXI_B_WLAST;
  assign oculink_0a_m_axi_wstrb[31:0] = xdma_oculink_0a_M_AXI_B_WSTRB;
  assign oculink_0a_m_axi_wvalid = xdma_oculink_0a_M_AXI_B_WVALID;
  assign oculink_0a_mgt_txn[3:0] = xdma_oculink_0a_pcie_mgt_txn;
  assign oculink_0a_mgt_txp[3:0] = xdma_oculink_0a_pcie_mgt_txp;
  assign oculink_0a_s_axi_arready = S00_AXI_0_1_ARREADY;
  assign oculink_0a_s_axi_awready = S00_AXI_0_1_AWREADY;
  assign oculink_0a_s_axi_bresp[1:0] = S00_AXI_0_1_BRESP;
  assign oculink_0a_s_axi_bvalid = S00_AXI_0_1_BVALID;
  assign oculink_0a_s_axi_rdata[31:0] = S00_AXI_0_1_RDATA;
  assign oculink_0a_s_axi_rlast = S00_AXI_0_1_RLAST;
  assign oculink_0a_s_axi_rresp[1:0] = S00_AXI_0_1_RRESP;
  assign oculink_0a_s_axi_rvalid = S00_AXI_0_1_RVALID;
  assign oculink_0a_s_axi_wready = S00_AXI_0_1_WREADY;
  assign reset_rtl_0_1 = oculink_0a_rstn;
  assign xdma_oculink_0a_M_AXI_B_ARREADY = oculink_0a_m_axi_arready;
  assign xdma_oculink_0a_M_AXI_B_AWREADY = oculink_0a_m_axi_awready;
  assign xdma_oculink_0a_M_AXI_B_BID = oculink_0a_m_axi_bid[3:0];
  assign xdma_oculink_0a_M_AXI_B_BRESP = oculink_0a_m_axi_bresp[1:0];
  assign xdma_oculink_0a_M_AXI_B_BVALID = oculink_0a_m_axi_bvalid;
  assign xdma_oculink_0a_M_AXI_B_RDATA = oculink_0a_m_axi_rdata[255:0];
  assign xdma_oculink_0a_M_AXI_B_RID = oculink_0a_m_axi_rid[3:0];
  assign xdma_oculink_0a_M_AXI_B_RLAST = oculink_0a_m_axi_rlast;
  assign xdma_oculink_0a_M_AXI_B_RRESP = oculink_0a_m_axi_rresp[1:0];
  assign xdma_oculink_0a_M_AXI_B_RVALID = oculink_0a_m_axi_rvalid;
  assign xdma_oculink_0a_M_AXI_B_WREADY = oculink_0a_m_axi_wready;
  assign xdma_oculink_0a_pcie_mgt_rxn = oculink_0a_mgt_rxn[3:0];
  assign xdma_oculink_0a_pcie_mgt_rxp = oculink_0a_mgt_rxp[3:0];
  oculink_0a_bd_smartconnect_0_0 smartconnect_0
       (.M00_AXI_araddr(smartconnect_0_M00_AXI_ARADDR),
        .M00_AXI_arburst(smartconnect_0_M00_AXI_ARBURST),
        .M00_AXI_arlen(smartconnect_0_M00_AXI_ARLEN),
        .M00_AXI_arready(smartconnect_0_M00_AXI_ARREADY),
        .M00_AXI_arsize(smartconnect_0_M00_AXI_ARSIZE),
        .M00_AXI_arvalid(smartconnect_0_M00_AXI_ARVALID),
        .M00_AXI_awaddr(smartconnect_0_M00_AXI_AWADDR),
        .M00_AXI_awburst(smartconnect_0_M00_AXI_AWBURST),
        .M00_AXI_awlen(smartconnect_0_M00_AXI_AWLEN),
        .M00_AXI_awready(smartconnect_0_M00_AXI_AWREADY),
        .M00_AXI_awsize(smartconnect_0_M00_AXI_AWSIZE),
        .M00_AXI_awvalid(smartconnect_0_M00_AXI_AWVALID),
        .M00_AXI_bready(smartconnect_0_M00_AXI_BREADY),
        .M00_AXI_bresp(smartconnect_0_M00_AXI_BRESP),
        .M00_AXI_bvalid(smartconnect_0_M00_AXI_BVALID),
        .M00_AXI_rdata(smartconnect_0_M00_AXI_RDATA),
        .M00_AXI_rlast(smartconnect_0_M00_AXI_RLAST),
        .M00_AXI_rready(smartconnect_0_M00_AXI_RREADY),
        .M00_AXI_rresp(smartconnect_0_M00_AXI_RRESP),
        .M00_AXI_rvalid(smartconnect_0_M00_AXI_RVALID),
        .M00_AXI_wdata(smartconnect_0_M00_AXI_WDATA),
        .M00_AXI_wlast(smartconnect_0_M00_AXI_WLAST),
        .M00_AXI_wready(smartconnect_0_M00_AXI_WREADY),
        .M00_AXI_wstrb(smartconnect_0_M00_AXI_WSTRB),
        .M00_AXI_wvalid(smartconnect_0_M00_AXI_WVALID),
        .M01_AXI_araddr(smartconnect_0_M01_AXI_ARADDR),
        .M01_AXI_arprot(smartconnect_0_M01_AXI_ARPROT),
        .M01_AXI_arready(smartconnect_0_M01_AXI_ARREADY),
        .M01_AXI_arvalid(smartconnect_0_M01_AXI_ARVALID),
        .M01_AXI_awaddr(smartconnect_0_M01_AXI_AWADDR),
        .M01_AXI_awprot(smartconnect_0_M01_AXI_AWPROT),
        .M01_AXI_awready(smartconnect_0_M01_AXI_AWREADY),
        .M01_AXI_awvalid(smartconnect_0_M01_AXI_AWVALID),
        .M01_AXI_bready(smartconnect_0_M01_AXI_BREADY),
        .M01_AXI_bresp(smartconnect_0_M01_AXI_BRESP),
        .M01_AXI_bvalid(smartconnect_0_M01_AXI_BVALID),
        .M01_AXI_rdata(smartconnect_0_M01_AXI_RDATA),
        .M01_AXI_rready(smartconnect_0_M01_AXI_RREADY),
        .M01_AXI_rresp(smartconnect_0_M01_AXI_RRESP),
        .M01_AXI_rvalid(smartconnect_0_M01_AXI_RVALID),
        .M01_AXI_wdata(smartconnect_0_M01_AXI_WDATA),
        .M01_AXI_wready(smartconnect_0_M01_AXI_WREADY),
        .M01_AXI_wstrb(smartconnect_0_M01_AXI_WSTRB),
        .M01_AXI_wvalid(smartconnect_0_M01_AXI_WVALID),
        .S00_AXI_araddr(S00_AXI_0_1_ARADDR),
        .S00_AXI_arburst(S00_AXI_0_1_ARBURST),
        .S00_AXI_arcache(S00_AXI_0_1_ARCACHE),
        .S00_AXI_arlen(S00_AXI_0_1_ARLEN),
        .S00_AXI_arlock(S00_AXI_0_1_ARLOCK),
        .S00_AXI_arprot(S00_AXI_0_1_ARPROT),
        .S00_AXI_arqos(S00_AXI_0_1_ARQOS),
        .S00_AXI_arready(S00_AXI_0_1_ARREADY),
        .S00_AXI_arsize(S00_AXI_0_1_ARSIZE),
        .S00_AXI_arvalid(S00_AXI_0_1_ARVALID),
        .S00_AXI_awaddr(S00_AXI_0_1_AWADDR),
        .S00_AXI_awburst(S00_AXI_0_1_AWBURST),
        .S00_AXI_awcache(S00_AXI_0_1_AWCACHE),
        .S00_AXI_awlen(S00_AXI_0_1_AWLEN),
        .S00_AXI_awlock(S00_AXI_0_1_AWLOCK),
        .S00_AXI_awprot(S00_AXI_0_1_AWPROT),
        .S00_AXI_awqos(S00_AXI_0_1_AWQOS),
        .S00_AXI_awready(S00_AXI_0_1_AWREADY),
        .S00_AXI_awsize(S00_AXI_0_1_AWSIZE),
        .S00_AXI_awvalid(S00_AXI_0_1_AWVALID),
        .S00_AXI_bready(S00_AXI_0_1_BREADY),
        .S00_AXI_bresp(S00_AXI_0_1_BRESP),
        .S00_AXI_bvalid(S00_AXI_0_1_BVALID),
        .S00_AXI_rdata(S00_AXI_0_1_RDATA),
        .S00_AXI_rlast(S00_AXI_0_1_RLAST),
        .S00_AXI_rready(S00_AXI_0_1_RREADY),
        .S00_AXI_rresp(S00_AXI_0_1_RRESP),
        .S00_AXI_rvalid(S00_AXI_0_1_RVALID),
        .S00_AXI_wdata(S00_AXI_0_1_WDATA),
        .S00_AXI_wlast(S00_AXI_0_1_WLAST),
        .S00_AXI_wready(S00_AXI_0_1_WREADY),
        .S00_AXI_wstrb(S00_AXI_0_1_WSTRB),
        .S00_AXI_wvalid(S00_AXI_0_1_WVALID),
        .aclk(xdma_oculink_0a_axi_aclk),
        .aresetn(xdma_oculink_0a_axi_aresetn));
  oculink_0a_bd_system_ila_0_0 system_ila_0
       (.SLOT_0_AXI_araddr(xdma_oculink_0a_M_AXI_B_ARADDR),
        .SLOT_0_AXI_arcache(xdma_oculink_0a_M_AXI_B_ARCACHE),
        .SLOT_0_AXI_arid(xdma_oculink_0a_M_AXI_B_ARID),
        .SLOT_0_AXI_arlen(xdma_oculink_0a_M_AXI_B_ARLEN),
        .SLOT_0_AXI_arlock(xdma_oculink_0a_M_AXI_B_ARLOCK),
        .SLOT_0_AXI_arprot(xdma_oculink_0a_M_AXI_B_ARPROT),
        .SLOT_0_AXI_arready(xdma_oculink_0a_M_AXI_B_ARREADY),
        .SLOT_0_AXI_arsize(xdma_oculink_0a_M_AXI_B_ARSIZE),
        .SLOT_0_AXI_arvalid(xdma_oculink_0a_M_AXI_B_ARVALID),
        .SLOT_0_AXI_awaddr(xdma_oculink_0a_M_AXI_B_AWADDR),
        .SLOT_0_AXI_awcache(xdma_oculink_0a_M_AXI_B_AWCACHE),
        .SLOT_0_AXI_awid(xdma_oculink_0a_M_AXI_B_AWID),
        .SLOT_0_AXI_awlen(xdma_oculink_0a_M_AXI_B_AWLEN),
        .SLOT_0_AXI_awlock(xdma_oculink_0a_M_AXI_B_AWLOCK),
        .SLOT_0_AXI_awprot(xdma_oculink_0a_M_AXI_B_AWPROT),
        .SLOT_0_AXI_awready(xdma_oculink_0a_M_AXI_B_AWREADY),
        .SLOT_0_AXI_awsize(xdma_oculink_0a_M_AXI_B_AWSIZE),
        .SLOT_0_AXI_awvalid(xdma_oculink_0a_M_AXI_B_AWVALID),
        .SLOT_0_AXI_bid(xdma_oculink_0a_M_AXI_B_BID),
        .SLOT_0_AXI_bready(xdma_oculink_0a_M_AXI_B_BREADY),
        .SLOT_0_AXI_bresp(xdma_oculink_0a_M_AXI_B_BRESP),
        .SLOT_0_AXI_bvalid(xdma_oculink_0a_M_AXI_B_BVALID),
        .SLOT_0_AXI_rdata(xdma_oculink_0a_M_AXI_B_RDATA),
        .SLOT_0_AXI_rid(xdma_oculink_0a_M_AXI_B_RID),
        .SLOT_0_AXI_rlast(xdma_oculink_0a_M_AXI_B_RLAST),
        .SLOT_0_AXI_rready(xdma_oculink_0a_M_AXI_B_RREADY),
        .SLOT_0_AXI_rresp(xdma_oculink_0a_M_AXI_B_RRESP),
        .SLOT_0_AXI_rvalid(xdma_oculink_0a_M_AXI_B_RVALID),
        .SLOT_0_AXI_wdata(xdma_oculink_0a_M_AXI_B_WDATA),
        .SLOT_0_AXI_wlast(xdma_oculink_0a_M_AXI_B_WLAST),
        .SLOT_0_AXI_wready(xdma_oculink_0a_M_AXI_B_WREADY),
        .SLOT_0_AXI_wstrb(xdma_oculink_0a_M_AXI_B_WSTRB),
        .SLOT_0_AXI_wvalid(xdma_oculink_0a_M_AXI_B_WVALID),
        .SLOT_1_AXI_araddr(S00_AXI_0_1_ARADDR),
        .SLOT_1_AXI_arburst(S00_AXI_0_1_ARBURST),
        .SLOT_1_AXI_arcache(S00_AXI_0_1_ARCACHE),
        .SLOT_1_AXI_arlen(S00_AXI_0_1_ARLEN),
        .SLOT_1_AXI_arlock(S00_AXI_0_1_ARLOCK),
        .SLOT_1_AXI_arprot(S00_AXI_0_1_ARPROT),
        .SLOT_1_AXI_arqos(S00_AXI_0_1_ARQOS),
        .SLOT_1_AXI_arready(S00_AXI_0_1_ARREADY),
        .SLOT_1_AXI_arregion({1'b0,1'b0,1'b0,1'b0}),
        .SLOT_1_AXI_arsize(S00_AXI_0_1_ARSIZE),
        .SLOT_1_AXI_arvalid(S00_AXI_0_1_ARVALID),
        .SLOT_1_AXI_awaddr(S00_AXI_0_1_AWADDR),
        .SLOT_1_AXI_awburst(S00_AXI_0_1_AWBURST),
        .SLOT_1_AXI_awcache(S00_AXI_0_1_AWCACHE),
        .SLOT_1_AXI_awlen(S00_AXI_0_1_AWLEN),
        .SLOT_1_AXI_awlock(S00_AXI_0_1_AWLOCK),
        .SLOT_1_AXI_awprot(S00_AXI_0_1_AWPROT),
        .SLOT_1_AXI_awqos(S00_AXI_0_1_AWQOS),
        .SLOT_1_AXI_awready(S00_AXI_0_1_AWREADY),
        .SLOT_1_AXI_awregion({1'b0,1'b0,1'b0,1'b0}),
        .SLOT_1_AXI_awsize(S00_AXI_0_1_AWSIZE),
        .SLOT_1_AXI_awvalid(S00_AXI_0_1_AWVALID),
        .SLOT_1_AXI_bready(S00_AXI_0_1_BREADY),
        .SLOT_1_AXI_bresp(S00_AXI_0_1_BRESP),
        .SLOT_1_AXI_bvalid(S00_AXI_0_1_BVALID),
        .SLOT_1_AXI_rdata(S00_AXI_0_1_RDATA),
        .SLOT_1_AXI_rlast(S00_AXI_0_1_RLAST),
        .SLOT_1_AXI_rready(S00_AXI_0_1_RREADY),
        .SLOT_1_AXI_rresp(S00_AXI_0_1_RRESP),
        .SLOT_1_AXI_rvalid(S00_AXI_0_1_RVALID),
        .SLOT_1_AXI_wdata(S00_AXI_0_1_WDATA),
        .SLOT_1_AXI_wlast(S00_AXI_0_1_WLAST),
        .SLOT_1_AXI_wready(S00_AXI_0_1_WREADY),
        .SLOT_1_AXI_wstrb(S00_AXI_0_1_WSTRB),
        .SLOT_1_AXI_wvalid(S00_AXI_0_1_WVALID),
        .clk(xdma_oculink_0a_axi_aclk),
        .resetn(xdma_oculink_0a_axi_aresetn));
  oculink_0a_bd_util_ds_buf_0 util_ds_buf
       (.IBUF_DS_N(diff_clock_rtl_0_1_CLK_N),
        .IBUF_DS_ODIV2(util_ds_buf_IBUF_DS_ODIV2),
        .IBUF_DS_P(diff_clock_rtl_0_1_CLK_P),
        .IBUF_OUT(util_ds_buf_IBUF_OUT));
  oculink_0a_bd_xdma_0_0 xdma_oculink_0a
       (.axi_aclk(xdma_oculink_0a_axi_aclk),
        .axi_aresetn(xdma_oculink_0a_axi_aresetn),
        .m_axib_araddr(xdma_oculink_0a_M_AXI_B_ARADDR),
        .m_axib_arburst(xdma_oculink_0a_M_AXI_B_ARBURST),
        .m_axib_arcache(xdma_oculink_0a_M_AXI_B_ARCACHE),
        .m_axib_arid(xdma_oculink_0a_M_AXI_B_ARID),
        .m_axib_arlen(xdma_oculink_0a_M_AXI_B_ARLEN),
        .m_axib_arlock(xdma_oculink_0a_M_AXI_B_ARLOCK),
        .m_axib_arprot(xdma_oculink_0a_M_AXI_B_ARPROT),
        .m_axib_arready(xdma_oculink_0a_M_AXI_B_ARREADY),
        .m_axib_arsize(xdma_oculink_0a_M_AXI_B_ARSIZE),
        .m_axib_arvalid(xdma_oculink_0a_M_AXI_B_ARVALID),
        .m_axib_awaddr(xdma_oculink_0a_M_AXI_B_AWADDR),
        .m_axib_awburst(xdma_oculink_0a_M_AXI_B_AWBURST),
        .m_axib_awcache(xdma_oculink_0a_M_AXI_B_AWCACHE),
        .m_axib_awid(xdma_oculink_0a_M_AXI_B_AWID),
        .m_axib_awlen(xdma_oculink_0a_M_AXI_B_AWLEN),
        .m_axib_awlock(xdma_oculink_0a_M_AXI_B_AWLOCK),
        .m_axib_awprot(xdma_oculink_0a_M_AXI_B_AWPROT),
        .m_axib_awready(xdma_oculink_0a_M_AXI_B_AWREADY),
        .m_axib_awsize(xdma_oculink_0a_M_AXI_B_AWSIZE),
        .m_axib_awvalid(xdma_oculink_0a_M_AXI_B_AWVALID),
        .m_axib_bid(xdma_oculink_0a_M_AXI_B_BID),
        .m_axib_bready(xdma_oculink_0a_M_AXI_B_BREADY),
        .m_axib_bresp(xdma_oculink_0a_M_AXI_B_BRESP),
        .m_axib_bvalid(xdma_oculink_0a_M_AXI_B_BVALID),
        .m_axib_rdata(xdma_oculink_0a_M_AXI_B_RDATA),
        .m_axib_rid(xdma_oculink_0a_M_AXI_B_RID),
        .m_axib_rlast(xdma_oculink_0a_M_AXI_B_RLAST),
        .m_axib_rready(xdma_oculink_0a_M_AXI_B_RREADY),
        .m_axib_rresp(xdma_oculink_0a_M_AXI_B_RRESP),
        .m_axib_rvalid(xdma_oculink_0a_M_AXI_B_RVALID),
        .m_axib_wdata(xdma_oculink_0a_M_AXI_B_WDATA),
        .m_axib_wlast(xdma_oculink_0a_M_AXI_B_WLAST),
        .m_axib_wready(xdma_oculink_0a_M_AXI_B_WREADY),
        .m_axib_wstrb(xdma_oculink_0a_M_AXI_B_WSTRB),
        .m_axib_wvalid(xdma_oculink_0a_M_AXI_B_WVALID),
        .pci_exp_rxn(xdma_oculink_0a_pcie_mgt_rxn),
        .pci_exp_rxp(xdma_oculink_0a_pcie_mgt_rxp),
        .pci_exp_txn(xdma_oculink_0a_pcie_mgt_txn),
        .pci_exp_txp(xdma_oculink_0a_pcie_mgt_txp),
        .s_axib_araddr(smartconnect_0_M00_AXI_ARADDR),
        .s_axib_arburst(smartconnect_0_M00_AXI_ARBURST),
        .s_axib_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axib_arlen(smartconnect_0_M00_AXI_ARLEN),
        .s_axib_arready(smartconnect_0_M00_AXI_ARREADY),
        .s_axib_arregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axib_arsize(smartconnect_0_M00_AXI_ARSIZE),
        .s_axib_arvalid(smartconnect_0_M00_AXI_ARVALID),
        .s_axib_awaddr(smartconnect_0_M00_AXI_AWADDR),
        .s_axib_awburst(smartconnect_0_M00_AXI_AWBURST),
        .s_axib_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axib_awlen(smartconnect_0_M00_AXI_AWLEN),
        .s_axib_awready(smartconnect_0_M00_AXI_AWREADY),
        .s_axib_awregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axib_awsize(smartconnect_0_M00_AXI_AWSIZE),
        .s_axib_awvalid(smartconnect_0_M00_AXI_AWVALID),
        .s_axib_bready(smartconnect_0_M00_AXI_BREADY),
        .s_axib_bresp(smartconnect_0_M00_AXI_BRESP),
        .s_axib_bvalid(smartconnect_0_M00_AXI_BVALID),
        .s_axib_rdata(smartconnect_0_M00_AXI_RDATA),
        .s_axib_rlast(smartconnect_0_M00_AXI_RLAST),
        .s_axib_rready(smartconnect_0_M00_AXI_RREADY),
        .s_axib_rresp(smartconnect_0_M00_AXI_RRESP),
        .s_axib_rvalid(smartconnect_0_M00_AXI_RVALID),
        .s_axib_wdata(smartconnect_0_M00_AXI_WDATA),
        .s_axib_wlast(smartconnect_0_M00_AXI_WLAST),
        .s_axib_wready(smartconnect_0_M00_AXI_WREADY),
        .s_axib_wstrb(smartconnect_0_M00_AXI_WSTRB),
        .s_axib_wvalid(smartconnect_0_M00_AXI_WVALID),
        .s_axil_araddr(smartconnect_0_M01_AXI_ARADDR),
        .s_axil_arprot(smartconnect_0_M01_AXI_ARPROT),
        .s_axil_arready(smartconnect_0_M01_AXI_ARREADY),
        .s_axil_arvalid(smartconnect_0_M01_AXI_ARVALID),
        .s_axil_awaddr(smartconnect_0_M01_AXI_AWADDR),
        .s_axil_awprot(smartconnect_0_M01_AXI_AWPROT),
        .s_axil_awready(smartconnect_0_M01_AXI_AWREADY),
        .s_axil_awvalid(smartconnect_0_M01_AXI_AWVALID),
        .s_axil_bready(smartconnect_0_M01_AXI_BREADY),
        .s_axil_bresp(smartconnect_0_M01_AXI_BRESP),
        .s_axil_bvalid(smartconnect_0_M01_AXI_BVALID),
        .s_axil_rdata(smartconnect_0_M01_AXI_RDATA),
        .s_axil_rready(smartconnect_0_M01_AXI_RREADY),
        .s_axil_rresp(smartconnect_0_M01_AXI_RRESP),
        .s_axil_rvalid(smartconnect_0_M01_AXI_RVALID),
        .s_axil_wdata(smartconnect_0_M01_AXI_WDATA),
        .s_axil_wready(smartconnect_0_M01_AXI_WREADY),
        .s_axil_wstrb(smartconnect_0_M01_AXI_WSTRB),
        .s_axil_wvalid(smartconnect_0_M01_AXI_WVALID),
        .sys_clk(util_ds_buf_IBUF_DS_ODIV2),
        .sys_clk_gt(util_ds_buf_IBUF_OUT),
        .sys_rst_n(reset_rtl_0_1));
endmodule
