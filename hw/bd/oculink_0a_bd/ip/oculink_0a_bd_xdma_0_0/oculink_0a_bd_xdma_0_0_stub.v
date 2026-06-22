// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
// Date        : Mon Jun 22 09:00:00 2026
// Host        : aespa running 64-bit Ubuntu 20.04.5 LTS
// Command     : write_verilog -force -mode synth_stub -rename_top oculink_0a_bd_xdma_0_0 -prefix
//               oculink_0a_bd_xdma_0_0_ oculink_0a_bd_xdma_0_0_stub.v
// Design      : oculink_0a_bd_xdma_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu19eg-ffvd1760-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CHECK_LICENSE_TYPE = "oculink_0a_bd_xdma_0_0,oculink_0a_bd_xdma_0_0_core_top,{}" *) (* CORE_GENERATION_INFO = "oculink_0a_bd_xdma_0_0,oculink_0a_bd_xdma_0_0_core_top,{x_ipProduct=Vivado 2024.2,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=xdma,x_ipVersion=4.1,x_ipCoreRevision=31,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,COMPONENT_NAME=xdma_0,PL_UPSTREAM_FACING=false,TL_LEGACY_MODE_ENABLE=true,PCIE_BLK_LOCN=3,PL_LINK_CAP_MAX_LINK_WIDTH=4,PL_LINK_CAP_MAX_LINK_SPEED=4,REF_CLK_FREQ=0,DRP_CLK_SEL=0,FREE_RUN_FREQ=0,AXI_ADDR_WIDTH=32,AXI_DATA_WIDTH=256,CORE_CLK_FREQ=1,PLL_TYPE=2,USER_CLK_FREQ=1,SILICON_REV=Pre-Production,PIPE_SIM=FALSE,VDM_EN=TRUE,EXT_CH_GT_DRP=false,PCIE3_DRP=false,DEDICATE_PERST=false,SYS_RESET_POLARITY=0,MCAP_ENABLEMENT=NONE,EXT_STARTUP_PRIMITIVE=false,PF0_VENDOR_ID=0x10EE,PF0_DEVICE_ID=0x9134,PF0_REVISION_ID=0x00,PF0_SUBSYSTEM_VENDOR_ID=0x10EE,PF0_SUBSYSTEM_ID=0x0007,PF0_CLASS_CODE=0x060700,PF1_VENDOR_ID=0x10EE,PF1_DEVICE_ID=0x1041,PF1_REVISION_ID=0x00,PF1_SUBSYSTEM_VENDOR_ID=0x10EE,PF1_SUBSYSTEM_ID=0x0007,PF1_CLASS_CODE=0x060700,PF2_DEVICE_ID=0x1040,PF2_REVISION_ID=0x00,PF2_SUBSYSTEM_ID=0x0007,PF3_DEVICE_ID=0x1039,PF3_REVISION_ID=0x00,PF3_SUBSYSTEM_ID=0x0007,AXILITE_MASTER_APERTURE_SIZE=0x12,AXILITE_MASTER_CONTROL=0x0,XDMA_APERTURE_SIZE=0x0E,XDMA_CONTROL=0x4,AXIST_BYPASS_APERTURE_SIZE=0x12,AXIST_BYPASS_CONTROL=0x0,PF0_INTERRUPT_PIN=0x1,PF0_MSI_CAP_MULTIMSGCAP=0,C_COMP_TIMEOUT=1,C_TIMEOUT0_SEL=0xE,C_TIMEOUT1_SEL=0xF,C_TIMEOUT_MULT=0x3,C_OLD_BRIDGE_TIMEOUT=0,SHARED_LOGIC=1,SHARED_LOGIC_CLK=false,SHARED_LOGIC_BOTH=false,SHARED_LOGIC_GTC=false,SHARED_LOGIC_GTC_7XG2=false,SHARED_LOGIC_CLK_7XG2=false,SHARED_LOGIC_BOTH_7XG2=false,EN_TRANSCEIVER_STATUS_PORTS=FALSE,IS_BOARD_PROJECT=0,EN_GT_SELECTION=TRUE,SELECT_QUAD=GTY_Quad_131,ULTRASCALE=FALSE,ULTRASCALE_PLUS=TRUE,VERSAL=FALSE,V7_GEN3=FALSE,MSI_ENABLED=TRUE,DEV_PORT_TYPE=2,XDMA_AXI_INTF_MM=1,XDMA_PCIE_64BIT_EN=xdma_pcie_64bit_en,XDMA_AXILITE_MASTER=FALSE,XDMA_AXIST_BYPASS=FALSE,XDMA_RNUM_CHNL=4,XDMA_WNUM_CHNL=4,XDMA_AXILITE_SLAVE=TRUE,XDMA_NUM_USR_IRQ=1,XDMA_RNUM_RIDS=32,XDMA_WNUM_RIDS=16,EGW_IS_PARENT_IP=1,C_M_AXI_ID_WIDTH=4,C_AXIBAR_NUM=1,C_FAMILY=zynquplus,XDMA_NUM_PCIE_TAG=256,EN_AXI_MASTER_IF=TRUE,EN_WCHNL_0=TRUE,EN_WCHNL_1=TRUE,EN_WCHNL_2=TRUE,EN_WCHNL_3=TRUE,EN_WCHNL_4=FALSE,EN_WCHNL_5=FALSE,EN_WCHNL_6=FALSE,EN_WCHNL_7=FALSE,EN_RCHNL_0=TRUE,EN_RCHNL_1=TRUE,EN_RCHNL_2=TRUE,EN_RCHNL_3=TRUE,EN_RCHNL_4=FALSE,EN_RCHNL_5=FALSE,EN_RCHNL_6=FALSE,EN_RCHNL_7=FALSE,XDMA_DSC_BYPASS=FALSE,C_METERING_ON=1,RX_DETECT=0,C_ATS_ENABLE=FALSE,C_ATS_CAP_NEXTPTR=0x000,C_PR_CAP_NEXTPTR=0x000,C_PRI_ENABLE=FALSE,DSC_BYPASS_RD=0,DSC_BYPASS_WR=0,XDMA_STS_PORTS=FALSE,MSIX_ENABLED=FALSE,WR_CH0_ENABLED=FALSE,WR_CH1_ENABLED=FALSE,WR_CH2_ENABLED=FALSE,WR_CH3_ENABLED=FALSE,RD_CH0_ENABLED=FALSE,RD_CH1_ENABLED=FALSE,RD_CH2_ENABLED=FALSE,RD_CH3_ENABLED=FALSE,CFG_MGMT_IF=TRUE,RQ_SEQ_NUM_IGNORE=0,CFG_EXT_IF=FALSE,LEGACY_CFG_EXT_IF=FALSE,C_PARITY_CHECK=0,C_PARITY_GEN=0,C_PARITY_PROP=0,C_ECC_ENABLE=0,EN_DEBUG_PORTS=FALSE,VU9P_BOARD=FALSE,ENABLE_JTAG_DBG=FALSE,ENABLE_LTSSM_DBG=FALSE,ENABLE_IBERT=FALSE,MM_SLAVE_EN=1,DMA_EN=0,C_AXIBAR_0=0x0000000080000000,C_AXIBAR_1=0x0000000000000000,C_AXIBAR_2=0x0000000000000000,C_AXIBAR_3=0x0000000000000000,C_AXIBAR_4=0x0000000000000000,C_AXIBAR_5=0x0000000000000000,C_AXIBAR_HIGHADDR_0=0x00000000FFFFFFFF,C_AXIBAR_HIGHADDR_1=0x0000000000000000,C_AXIBAR_HIGHADDR_2=0x0000000000000000,C_AXIBAR_HIGHADDR_3=0x0000000000000000,C_AXIBAR_HIGHADDR_4=0x0000000000000000,C_AXIBAR_HIGHADDR_5=0x0000000000000000,C_AXIBAR2PCIEBAR_0=0x0000000000000000,C_AXIBAR2PCIEBAR_1=0x0000000000000000,C_AXIBAR2PCIEBAR_2=0x0000000000000000,C_AXIBAR2PCIEBAR_3=0x0000000000000000,C_AXIBAR2PCIEBAR_4=0x0000000000000000,C_AXIBAR2PCIEBAR_5=0x0000000000000000,EN_AXI_SLAVE_IF=TRUE,C_INCLUDE_BAROFFSET_REG=1,C_BASEADDR=0x00000000,C_HIGHADDR=0x001FFFFF,C_S_AXI_ID_WIDTH=4,C_S_AXI_NUM_READ=8,C_M_AXI_NUM_READ=8,C_M_AXI_NUM_READQ=2,C_S_AXI_NUM_WRITE=8,C_M_AXI_NUM_WRITE=16,C_M_AXI_NUM_WRITE_SCALE=1,MSIX_IMPL_EXT=FALSE,AXI_ACLK_LOOPBACK=FALSE,PF0_BAR0_APERTURE_SIZE=0x0F,PF0_BAR0_CONTROL=0x0,PF0_BAR1_APERTURE_SIZE=0x0A,PF0_BAR1_CONTROL=0x0,PF0_BAR2_APERTURE_SIZE=0x0A,PF0_BAR2_CONTROL=0x0,PF0_BAR3_APERTURE_SIZE=0x0A,PF0_BAR3_CONTROL=0x0,PF0_BAR4_APERTURE_SIZE=0x0A,PF0_BAR4_CONTROL=0x0,PF0_BAR5_APERTURE_SIZE=0x0A,PF0_BAR5_CONTROL=0x0,PF0_EXPANSION_ROM_APERTURE_SIZE=0x000,PF0_EXPANSION_ROM_ENABLE=FALSE,PCIEBAR_NUM=0,C_PCIEBAR2AXIBAR_0=0x0000000000000000,C_PCIEBAR2AXIBAR_1=0x0000000000000000,C_PCIEBAR2AXIBAR_2=0x0000000000000000,C_PCIEBAR2AXIBAR_3=0x0000000000000000,C_PCIEBAR2AXIBAR_4=0x0000000000000000,C_PCIEBAR2AXIBAR_5=0x0000000000000000,C_PCIEBAR2AXIBAR_6=0x0000000000000000,BARLITE1=0,BARLITE2=7,VCU118_BOARD=FALSE,ENABLE_ERROR_INJECTION=FALSE,SPLIT_DMA=FALSE,USE_STANDARD_INTERFACES=FALSE,DMA_2RP=FALSE,SRIOV_ACTIVE_VFS=252,PIPE_LINE_STAGE=2,AXIS_PIPE_LINE_STAGE=0,MULT_PF_DES=FALSE,PF_SWAP=FALSE,PF0_MSIX_TAR_ID=0x08,PF1_MSIX_TAR_ID=0x09,RUNBIT_FIX=FALSE,USRINT_EXPN=FALSE,xlnx_ref_board=None,GTWIZ_IN_CORE=1,GTCOM_IN_CORE=2,INS_LOSS_PROFILE=Add-in_Card,FUNC_MODE=0,PF1_ENABLED=0,DMA_RESET_SOURCE_SEL=1,PF1_BAR0_APERTURE_SIZE=0x17,PF1_BAR0_CONTROL=0x4,PF1_BAR1_APERTURE_SIZE=0x0F,PF1_BAR1_CONTROL=0x4,PF1_BAR2_APERTURE_SIZE=0x0F,PF1_BAR2_CONTROL=0x0,PF1_BAR3_APERTURE_SIZE=0x0F,PF1_BAR3_CONTROL=0x0,PF1_BAR4_APERTURE_SIZE=0x0F,PF1_BAR4_CONTROL=0x0,PF1_BAR5_APERTURE_SIZE=0x0F,PF1_BAR5_CONTROL=0x0,PF1_EXPANSION_ROM_APERTURE_SIZE=0x000,PF1_EXPANSION_ROM_ENABLE=FALSE,PF1_PCIEBAR2AXIBAR_0=0x0000000000000000,PF1_PCIEBAR2AXIBAR_1=0x0000000000000000,PF1_PCIEBAR2AXIBAR_2=0x0000000000000000,PF1_PCIEBAR2AXIBAR_3=0x0000000000000000,PF1_PCIEBAR2AXIBAR_4=0x0000000000000000,PF1_PCIEBAR2AXIBAR_5=0x0000000000000000,PF1_PCIEBAR2AXIBAR_6=0x0000000000000000,C_MSIX_INT_TABLE_EN=0,VU9P_TUL_EX=FALSE,PCIE_BLK_TYPE=0,CCIX_ENABLE=FALSE,CCIX_DVSEC=FALSE,EXT_SYS_CLK_BUFG=FALSE,C_NUM_OF_SC=1,USR_IRQ_EXDES=FALSE,AXI_VIP_IN_EXDES=FALSE,PIPE_DEBUG_EN=FALSE,XDMA_NON_INCREMENTAL_EXDES=FALSE,XDMA_ST_INFINITE_DESC_EXDES=FALSE,EXT_XVC_VSEC_ENABLE=FALSE,ACS_EXT_CAP_ENABLE=FALSE,EN_PCIE_DEBUG_PORTS=FALSE,MULTQ_EN=0,DMA_MM=0,DMA_ST=0,C_PCIE_PFS_SUPPORTED=0,C_SRIOV_EN=0,BARLITE_EXT_PF0=0x00,BARLITE_EXT_PF1=0x00,BARLITE_EXT_PF2=0x00,BARLITE_EXT_PF3=0x00,BARLITE_INT_PF0=0x00,BARLITE_INT_PF1=0x00,BARLITE_INT_PF2=0x00,BARLITE_INT_PF3=0x00,NUM_VFS_PF0=0,NUM_VFS_PF1=0,NUM_VFS_PF2=0,NUM_VFS_PF3=0,FIRSTVF_OFFSET_PF0=0,FIRSTVF_OFFSET_PF1=0,FIRSTVF_OFFSET_PF2=0,FIRSTVF_OFFSET_PF3=0,VF_BARLITE_EXT_PF0=0x00,VF_BARLITE_EXT_PF1=0x00,VF_BARLITE_EXT_PF2=0x00,VF_BARLITE_EXT_PF3=0x00,VF_BARLITE_INT_PF0=0x00,VF_BARLITE_INT_PF1=0x00,VF_BARLITE_INT_PF2=0x00,VF_BARLITE_INT_PF3=0x00,C_C2H_NUM_CHNL=4,C_H2C_NUM_CHNL=4,H2C_XDMA_CHNL=0x0F,C2H_XDMA_CHNL=0x0F,AXISTEN_IF_ENABLE_MSG_ROUTE=0x27FFF,ENABLE_MORE=FALSE,DISABLE_BRAM_PIPELINE=FALSE,DISABLE_EQ_SYNCHRONIZER=FALSE,C_ENABLE_RESOURCE_REDUCTION=FALSE,GEN4_EIEOS_0S7=TRUE,C_S_AXI_SUPPORTS_NARROW_BURST=0,ENABLE_ATS_SWITCH=FALSE,C_ATS_SWITCH_UNIQUE_BDF=1,BRIDGE_BURST=TRUE,CFG_SPACE_ENABLE=FALSE,C_LAST_CORE_CAP_ADDR=0x100,C_VSEC_CAP_ADDR=0x128,SOFT_RESET_EN=FALSE,INTERRUPT_OUT_WIDTH=1,C_MSI_RX_PIN_EN=0,C_MSIX_RX_PIN_EN=1,C_INTX_RX_PIN_EN=1,MSIX_RX_DECODE_EN=FALSE,PCIE_ID_IF=FALSE,TL_PF_ENABLE_REG=0,AXSIZE_BYTE_ACCESS_EN=FALSE,SPLIT_DMA_SINGLE_PF=FALSE,RBAR_ENABLE=FALSE,C_SMMU_EN=0,C_M_AXI_AWUSER_WIDTH=8,C_M_AXI_ARUSER_WIDTH=8,C_SLAVE_READ_64OS_EN=0,FLR_ENABLE=FALSE,SHELL_BRIDGE=0,MSIX_PCIE_INTERNAL=0,VERSAL_PART_TYPE=SXX,TANDEM_RFSOC=FALSE,ERRC_DEC_EN=FALSE}" *) (* DowngradeIPIdentifiedWarnings = "yes" *) 
(* X_CORE_INFO = "oculink_0a_bd_xdma_0_0_core_top,Vivado 2024.2" *) 
module oculink_0a_bd_xdma_0_0(sys_clk, sys_clk_gt, sys_rst_n, 
  cfg_ltssm_state, user_lnk_up, pci_exp_txp, pci_exp_txn, pci_exp_rxp, pci_exp_rxn, axi_aclk, 
  axi_aresetn, axi_ctl_aresetn, m_axib_awid, m_axib_awaddr, m_axib_awlen, m_axib_awsize, 
  m_axib_awburst, m_axib_awprot, m_axib_awvalid, m_axib_awready, m_axib_awlock, 
  m_axib_awcache, m_axib_wdata, m_axib_wstrb, m_axib_wlast, m_axib_wvalid, m_axib_wready, 
  m_axib_bid, m_axib_bresp, m_axib_bvalid, m_axib_bready, m_axib_arid, m_axib_araddr, 
  m_axib_arlen, m_axib_arsize, m_axib_arburst, m_axib_arprot, m_axib_arvalid, m_axib_arready, 
  m_axib_arlock, m_axib_arcache, m_axib_rid, m_axib_rdata, m_axib_rresp, m_axib_rlast, 
  m_axib_rvalid, m_axib_rready, s_axil_awaddr, s_axil_awprot, s_axil_awvalid, s_axil_awready, 
  s_axil_wdata, s_axil_wstrb, s_axil_wvalid, s_axil_wready, s_axil_bvalid, s_axil_bresp, 
  s_axil_bready, s_axil_araddr, s_axil_arprot, s_axil_arvalid, s_axil_arready, s_axil_rdata, 
  s_axil_rresp, s_axil_rvalid, s_axil_rready, interrupt_out, s_axib_awid, s_axib_awaddr, 
  s_axib_awregion, s_axib_awlen, s_axib_awsize, s_axib_awburst, s_axib_awvalid, s_axib_wdata, 
  s_axib_wstrb, s_axib_wlast, s_axib_wvalid, s_axib_bready, s_axib_arid, s_axib_araddr, 
  s_axib_arregion, s_axib_arlen, s_axib_arsize, s_axib_arburst, s_axib_arvalid, 
  s_axib_rready, s_axib_awready, s_axib_wready, s_axib_bid, s_axib_bresp, s_axib_bvalid, 
  s_axib_arready, s_axib_rid, s_axib_rdata, s_axib_rresp, s_axib_rlast, s_axib_rvalid)
/* synthesis syn_black_box black_box_pad_pin="sys_clk_gt,sys_rst_n,cfg_ltssm_state[5:0],user_lnk_up,pci_exp_txp[3:0],pci_exp_txn[3:0],pci_exp_rxp[3:0],pci_exp_rxn[3:0],axi_aresetn,axi_ctl_aresetn,m_axib_awid[3:0],m_axib_awaddr[31:0],m_axib_awlen[7:0],m_axib_awsize[2:0],m_axib_awburst[1:0],m_axib_awprot[2:0],m_axib_awvalid,m_axib_awready,m_axib_awlock,m_axib_awcache[3:0],m_axib_wdata[255:0],m_axib_wstrb[31:0],m_axib_wlast,m_axib_wvalid,m_axib_wready,m_axib_bid[3:0],m_axib_bresp[1:0],m_axib_bvalid,m_axib_bready,m_axib_arid[3:0],m_axib_araddr[31:0],m_axib_arlen[7:0],m_axib_arsize[2:0],m_axib_arburst[1:0],m_axib_arprot[2:0],m_axib_arvalid,m_axib_arready,m_axib_arlock,m_axib_arcache[3:0],m_axib_rid[3:0],m_axib_rdata[255:0],m_axib_rresp[1:0],m_axib_rlast,m_axib_rvalid,m_axib_rready,s_axil_awaddr[31:0],s_axil_awprot[2:0],s_axil_awvalid,s_axil_awready,s_axil_wdata[31:0],s_axil_wstrb[3:0],s_axil_wvalid,s_axil_wready,s_axil_bvalid,s_axil_bresp[1:0],s_axil_bready,s_axil_araddr[31:0],s_axil_arprot[2:0],s_axil_arvalid,s_axil_arready,s_axil_rdata[31:0],s_axil_rresp[1:0],s_axil_rvalid,s_axil_rready,interrupt_out,s_axib_awid[3:0],s_axib_awaddr[31:0],s_axib_awregion[3:0],s_axib_awlen[7:0],s_axib_awsize[2:0],s_axib_awburst[1:0],s_axib_awvalid,s_axib_wdata[255:0],s_axib_wstrb[31:0],s_axib_wlast,s_axib_wvalid,s_axib_bready,s_axib_arid[3:0],s_axib_araddr[31:0],s_axib_arregion[3:0],s_axib_arlen[7:0],s_axib_arsize[2:0],s_axib_arburst[1:0],s_axib_arvalid,s_axib_rready,s_axib_awready,s_axib_wready,s_axib_bid[3:0],s_axib_bresp[1:0],s_axib_bvalid,s_axib_arready,s_axib_rid[3:0],s_axib_rdata[255:0],s_axib_rresp[1:0],s_axib_rlast,s_axib_rvalid" */
/* synthesis syn_force_seq_prim="sys_clk" */
/* synthesis syn_force_seq_prim="axi_aclk" */;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.SYS_CLK CLK" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.SYS_CLK, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN oculink_0a_bd_util_ds_buf_0_IBUF_DS_ODIV2, INSERT_VIP 0" *) input sys_clk /* synthesis syn_isclock = 1 */;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.sys_clk_gt CLK" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.sys_clk_gt, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN oculink_0a_bd_util_ds_buf_0_IBUF_OUT, INSERT_VIP 0" *) input sys_clk_gt;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.sys_rst_n RST" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.sys_rst_n, BOARD.ASSOCIATED_PARAM SYS_RST_N_BOARD_INTERFACE, TYPE PCIE_PERST, POLARITY ACTIVE_LOW, INSERT_VIP 0" *) input sys_rst_n;
  output [5:0]cfg_ltssm_state;
  output user_lnk_up;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 pcie_mgt txp" *) (* X_INTERFACE_MODE = "master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME pcie_mgt, BOARD.ASSOCIATED_PARAM PCIE_BOARD_INTERFACE" *) output [3:0]pci_exp_txp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 pcie_mgt txn" *) output [3:0]pci_exp_txn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 pcie_mgt rxp" *) input [3:0]pci_exp_rxp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 pcie_mgt rxn" *) input [3:0]pci_exp_rxn;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.axi_aclk CLK" *) (* X_INTERFACE_MODE = "master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.axi_aclk, ASSOCIATED_BUSIF M_AXI_B:S_AXI_B:S_AXI_LITE, ASSOCIATED_RESET axi_aresetn:axi_ctl_aresetn, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN oculink_0a_bd_xdma_0_0_axi_aclk, INSERT_VIP 0" *) output axi_aclk /* synthesis syn_isclock = 1 */;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.axi_aresetn RST" *) (* X_INTERFACE_MODE = "master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.axi_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *) output axi_aresetn;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.axi_ctl_aresetn RST" *) (* X_INTERFACE_MODE = "master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.axi_ctl_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0" *) output axi_ctl_aresetn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B AWID" *) (* X_INTERFACE_MODE = "master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI_B, NUM_READ_OUTSTANDING 8, NUM_WRITE_OUTSTANDING 16, HAS_BURST 0, SUPPORTS_NARROW_BURST 0, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, DATA_WIDTH 256, PROTOCOL AXI4, FREQ_HZ 125000000, ID_WIDTH 4, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_LOCK 1, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, MAX_BURST_LENGTH 256, PHASE 0.0, CLK_DOMAIN oculink_0a_bd_xdma_0_0_axi_aclk, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *) output [3:0]m_axib_awid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B AWADDR" *) output [31:0]m_axib_awaddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B AWLEN" *) output [7:0]m_axib_awlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B AWSIZE" *) output [2:0]m_axib_awsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B AWBURST" *) output [1:0]m_axib_awburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B AWPROT" *) output [2:0]m_axib_awprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B AWVALID" *) output m_axib_awvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B AWREADY" *) input m_axib_awready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B AWLOCK" *) output m_axib_awlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B AWCACHE" *) output [3:0]m_axib_awcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B WDATA" *) output [255:0]m_axib_wdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B WSTRB" *) output [31:0]m_axib_wstrb;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B WLAST" *) output m_axib_wlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B WVALID" *) output m_axib_wvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B WREADY" *) input m_axib_wready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B BID" *) input [3:0]m_axib_bid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B BRESP" *) input [1:0]m_axib_bresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B BVALID" *) input m_axib_bvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B BREADY" *) output m_axib_bready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B ARID" *) output [3:0]m_axib_arid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B ARADDR" *) output [31:0]m_axib_araddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B ARLEN" *) output [7:0]m_axib_arlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B ARSIZE" *) output [2:0]m_axib_arsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B ARBURST" *) output [1:0]m_axib_arburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B ARPROT" *) output [2:0]m_axib_arprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B ARVALID" *) output m_axib_arvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B ARREADY" *) input m_axib_arready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B ARLOCK" *) output m_axib_arlock;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B ARCACHE" *) output [3:0]m_axib_arcache;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B RID" *) input [3:0]m_axib_rid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B RDATA" *) input [255:0]m_axib_rdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B RRESP" *) input [1:0]m_axib_rresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B RLAST" *) input m_axib_rlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B RVALID" *) input m_axib_rvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_B RREADY" *) output m_axib_rready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE AWADDR" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI_LITE, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, SUPPORTS_NARROW_BURST 0, DATA_WIDTH 32, PROTOCOL AXI4LITE, FREQ_HZ 125000000, ID_WIDTH 0, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, MAX_BURST_LENGTH 1, PHASE 0.0, CLK_DOMAIN oculink_0a_bd_xdma_0_0_axi_aclk, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *) input [31:0]s_axil_awaddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE AWPROT" *) input [2:0]s_axil_awprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE AWVALID" *) input s_axil_awvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE AWREADY" *) output s_axil_awready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE WDATA" *) input [31:0]s_axil_wdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE WSTRB" *) input [3:0]s_axil_wstrb;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE WVALID" *) input s_axil_wvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE WREADY" *) output s_axil_wready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE BVALID" *) output s_axil_bvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE BRESP" *) output [1:0]s_axil_bresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE BREADY" *) input s_axil_bready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE ARADDR" *) input [31:0]s_axil_araddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE ARPROT" *) input [2:0]s_axil_arprot;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE ARVALID" *) input s_axil_arvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE ARREADY" *) output s_axil_arready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE RDATA" *) output [31:0]s_axil_rdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE RRESP" *) output [1:0]s_axil_rresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE RVALID" *) output s_axil_rvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_LITE RREADY" *) input s_axil_rready;
  (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 INTERRUPT.interrupt_out INTERRUPT" *) (* X_INTERFACE_MODE = "master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME INTERRUPT.interrupt_out, SENSITIVITY LEVEL_HIGH, PortWidth 1" *) output interrupt_out;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B AWID" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXI_B, NUM_READ_OUTSTANDING 8, NUM_WRITE_OUTSTANDING 8, SUPPORTS_NARROW_BURST 0, DATA_WIDTH 256, PROTOCOL AXI4, FREQ_HZ 125000000, ID_WIDTH 4, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 1, HAS_LOCK 0, HAS_PROT 0, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 1, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, MAX_BURST_LENGTH 32, PHASE 0.0, CLK_DOMAIN oculink_0a_bd_xdma_0_0_axi_aclk, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *) input [3:0]s_axib_awid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B AWADDR" *) input [31:0]s_axib_awaddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B AWREGION" *) input [3:0]s_axib_awregion;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B AWLEN" *) input [7:0]s_axib_awlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B AWSIZE" *) input [2:0]s_axib_awsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B AWBURST" *) input [1:0]s_axib_awburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B AWVALID" *) input s_axib_awvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B WDATA" *) input [255:0]s_axib_wdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B WSTRB" *) input [31:0]s_axib_wstrb;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B WLAST" *) input s_axib_wlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B WVALID" *) input s_axib_wvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B BREADY" *) input s_axib_bready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B ARID" *) input [3:0]s_axib_arid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B ARADDR" *) input [31:0]s_axib_araddr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B ARREGION" *) input [3:0]s_axib_arregion;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B ARLEN" *) input [7:0]s_axib_arlen;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B ARSIZE" *) input [2:0]s_axib_arsize;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B ARBURST" *) input [1:0]s_axib_arburst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B ARVALID" *) input s_axib_arvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B RREADY" *) input s_axib_rready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B AWREADY" *) output s_axib_awready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B WREADY" *) output s_axib_wready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B BID" *) output [3:0]s_axib_bid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B BRESP" *) output [1:0]s_axib_bresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B BVALID" *) output s_axib_bvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B ARREADY" *) output s_axib_arready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B RID" *) output [3:0]s_axib_rid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B RDATA" *) output [255:0]s_axib_rdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B RRESP" *) output [1:0]s_axib_rresp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B RLAST" *) output s_axib_rlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI_B RVALID" *) output s_axib_rvalid;
endmodule
