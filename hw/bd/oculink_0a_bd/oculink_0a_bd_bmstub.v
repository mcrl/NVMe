// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// -------------------------------------------------------------------------------

`timescale 1 ps / 1 ps

(* BLOCK_STUB = "true" *)
module oculink_0a_bd (
  oculink_0a_rstn,
  oculink_0a_axi_aclk,
  oculink_0a_axi_rstn,
  oculink_0a_s_axi_awaddr,
  oculink_0a_s_axi_awlen,
  oculink_0a_s_axi_awsize,
  oculink_0a_s_axi_awburst,
  oculink_0a_s_axi_awlock,
  oculink_0a_s_axi_awcache,
  oculink_0a_s_axi_awprot,
  oculink_0a_s_axi_awqos,
  oculink_0a_s_axi_awvalid,
  oculink_0a_s_axi_awready,
  oculink_0a_s_axi_wdata,
  oculink_0a_s_axi_wstrb,
  oculink_0a_s_axi_wlast,
  oculink_0a_s_axi_wvalid,
  oculink_0a_s_axi_wready,
  oculink_0a_s_axi_bresp,
  oculink_0a_s_axi_bvalid,
  oculink_0a_s_axi_bready,
  oculink_0a_s_axi_araddr,
  oculink_0a_s_axi_arlen,
  oculink_0a_s_axi_arsize,
  oculink_0a_s_axi_arburst,
  oculink_0a_s_axi_arlock,
  oculink_0a_s_axi_arcache,
  oculink_0a_s_axi_arprot,
  oculink_0a_s_axi_arqos,
  oculink_0a_s_axi_arvalid,
  oculink_0a_s_axi_arready,
  oculink_0a_s_axi_rdata,
  oculink_0a_s_axi_rresp,
  oculink_0a_s_axi_rlast,
  oculink_0a_s_axi_rvalid,
  oculink_0a_s_axi_rready,
  oculink_0a_ref_clk_p,
  oculink_0a_ref_clk_n,
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
  oculink_0a_mgt_txp
);

  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.OCULINK_0A_RSTN RST" *)
  (* X_INTERFACE_MODE = "slave RST.OCULINK_0A_RSTN" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.OCULINK_0A_RSTN, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
  input oculink_0a_rstn;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.OCULINK_0A_AXI_ACLK CLK" *)
  (* X_INTERFACE_MODE = "master CLK.OCULINK_0A_AXI_ACLK" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.OCULINK_0A_AXI_ACLK, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN oculink_0a_bd_xdma_0_0_axi_aclk, ASSOCIATED_BUSIF oculink_0a_s_axi:oculink_0a_m_axi, INSERT_VIP 0" *)
  output oculink_0a_axi_aclk;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.OCULINK_0A_AXI_RSTN RST" *)
  (* X_INTERFACE_MODE = "master RST.OCULINK_0A_AXI_RSTN" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.OCULINK_0A_AXI_RSTN, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
  output oculink_0a_axi_rstn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWADDR" *)
  (* X_INTERFACE_MODE = "slave oculink_0a_s_axi" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME oculink_0a_s_axi, DATA_WIDTH 32, PROTOCOL AXI4, FREQ_HZ 125000000, ID_WIDTH 0, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 1, HAS_LOCK 1, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 1, HAS_REGION 1, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 1, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 256, PHASE 0.0, CLK_DOMAIN oculink_0a_bd_xdma_0_0_axi_aclk, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
  input [31:0]oculink_0a_s_axi_awaddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWLEN" *)
  input [7:0]oculink_0a_s_axi_awlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWSIZE" *)
  input [2:0]oculink_0a_s_axi_awsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWBURST" *)
  input [1:0]oculink_0a_s_axi_awburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWLOCK" *)
  input [0:0]oculink_0a_s_axi_awlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWCACHE" *)
  input [3:0]oculink_0a_s_axi_awcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWPROT" *)
  input [2:0]oculink_0a_s_axi_awprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWQOS" *)
  input [3:0]oculink_0a_s_axi_awqos;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWVALID" *)
  input oculink_0a_s_axi_awvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi AWREADY" *)
  output oculink_0a_s_axi_awready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi WDATA" *)
  input [31:0]oculink_0a_s_axi_wdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi WSTRB" *)
  input [3:0]oculink_0a_s_axi_wstrb;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi WLAST" *)
  input oculink_0a_s_axi_wlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi WVALID" *)
  input oculink_0a_s_axi_wvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi WREADY" *)
  output oculink_0a_s_axi_wready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi BRESP" *)
  output [1:0]oculink_0a_s_axi_bresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi BVALID" *)
  output oculink_0a_s_axi_bvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi BREADY" *)
  input oculink_0a_s_axi_bready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARADDR" *)
  input [31:0]oculink_0a_s_axi_araddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARLEN" *)
  input [7:0]oculink_0a_s_axi_arlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARSIZE" *)
  input [2:0]oculink_0a_s_axi_arsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARBURST" *)
  input [1:0]oculink_0a_s_axi_arburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARLOCK" *)
  input [0:0]oculink_0a_s_axi_arlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARCACHE" *)
  input [3:0]oculink_0a_s_axi_arcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARPROT" *)
  input [2:0]oculink_0a_s_axi_arprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARQOS" *)
  input [3:0]oculink_0a_s_axi_arqos;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARVALID" *)
  input oculink_0a_s_axi_arvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi ARREADY" *)
  output oculink_0a_s_axi_arready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi RDATA" *)
  output [31:0]oculink_0a_s_axi_rdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi RRESP" *)
  output [1:0]oculink_0a_s_axi_rresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi RLAST" *)
  output oculink_0a_s_axi_rlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi RVALID" *)
  output oculink_0a_s_axi_rvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_s_axi RREADY" *)
  input oculink_0a_s_axi_rready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 oculink_0a_ref CLK_P" *)
  (* X_INTERFACE_MODE = "slave oculink_0a_ref" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME oculink_0a_ref, CAN_DEBUG false, FREQ_HZ 100000000" *)
  input [0:0]oculink_0a_ref_clk_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 oculink_0a_ref CLK_N" *)
  input [0:0]oculink_0a_ref_clk_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARADDR" *)
  (* X_INTERFACE_MODE = "master oculink_0a_m_axi" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME oculink_0a_m_axi, DATA_WIDTH 256, PROTOCOL AXI4, FREQ_HZ 125000000, ID_WIDTH 4, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 1, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 8, NUM_WRITE_OUTSTANDING 16, MAX_BURST_LENGTH 256, PHASE 0.0, CLK_DOMAIN oculink_0a_bd_xdma_0_0_axi_aclk, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
  output [31:0]oculink_0a_m_axi_araddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARBURST" *)
  output [1:0]oculink_0a_m_axi_arburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARCACHE" *)
  output [3:0]oculink_0a_m_axi_arcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARID" *)
  output [3:0]oculink_0a_m_axi_arid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARLEN" *)
  output [7:0]oculink_0a_m_axi_arlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARLOCK" *)
  output oculink_0a_m_axi_arlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARPROT" *)
  output [2:0]oculink_0a_m_axi_arprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARREADY" *)
  input oculink_0a_m_axi_arready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARSIZE" *)
  output [2:0]oculink_0a_m_axi_arsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi ARVALID" *)
  output oculink_0a_m_axi_arvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWADDR" *)
  output [31:0]oculink_0a_m_axi_awaddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWBURST" *)
  output [1:0]oculink_0a_m_axi_awburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWCACHE" *)
  output [3:0]oculink_0a_m_axi_awcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWID" *)
  output [3:0]oculink_0a_m_axi_awid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWLEN" *)
  output [7:0]oculink_0a_m_axi_awlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWLOCK" *)
  output oculink_0a_m_axi_awlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWPROT" *)
  output [2:0]oculink_0a_m_axi_awprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWREADY" *)
  input oculink_0a_m_axi_awready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWSIZE" *)
  output [2:0]oculink_0a_m_axi_awsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi AWVALID" *)
  output oculink_0a_m_axi_awvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi BID" *)
  input [3:0]oculink_0a_m_axi_bid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi BREADY" *)
  output oculink_0a_m_axi_bready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi BRESP" *)
  input [1:0]oculink_0a_m_axi_bresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi BVALID" *)
  input oculink_0a_m_axi_bvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RDATA" *)
  input [255:0]oculink_0a_m_axi_rdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RID" *)
  input [3:0]oculink_0a_m_axi_rid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RLAST" *)
  input oculink_0a_m_axi_rlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RREADY" *)
  output oculink_0a_m_axi_rready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RRESP" *)
  input [1:0]oculink_0a_m_axi_rresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi RVALID" *)
  input oculink_0a_m_axi_rvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi WDATA" *)
  output [255:0]oculink_0a_m_axi_wdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi WLAST" *)
  output oculink_0a_m_axi_wlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi WREADY" *)
  input oculink_0a_m_axi_wready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi WSTRB" *)
  output [31:0]oculink_0a_m_axi_wstrb;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 oculink_0a_m_axi WVALID" *)
  output oculink_0a_m_axi_wvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 oculink_0a_mgt rxn" *)
  (* X_INTERFACE_MODE = "master oculink_0a_mgt" *)
  input [3:0]oculink_0a_mgt_rxn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 oculink_0a_mgt rxp" *)
  input [3:0]oculink_0a_mgt_rxp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 oculink_0a_mgt txn" *)
  output [3:0]oculink_0a_mgt_txn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 oculink_0a_mgt txp" *)
  output [3:0]oculink_0a_mgt_txp;

  // stub module has no contents

endmodule
