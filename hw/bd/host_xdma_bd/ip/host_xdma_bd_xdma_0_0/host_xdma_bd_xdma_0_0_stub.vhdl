-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
-- Date        : Mon Jun 22 09:04:27 2026
-- Host        : aespa running 64-bit Ubuntu 20.04.5 LTS
-- Command     : write_vhdl -force -mode synth_stub -rename_top host_xdma_bd_xdma_0_0 -prefix
--               host_xdma_bd_xdma_0_0_ host_xdma_bd_xdma_0_0_stub.vhdl
-- Design      : host_xdma_bd_xdma_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu19eg-ffvd1760-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity host_xdma_bd_xdma_0_0 is
  Port ( 
    sys_clk : in STD_LOGIC;
    sys_clk_gt : in STD_LOGIC;
    sys_rst_n : in STD_LOGIC;
    user_lnk_up : out STD_LOGIC;
    pci_exp_txp : out STD_LOGIC_VECTOR ( 15 downto 0 );
    pci_exp_txn : out STD_LOGIC_VECTOR ( 15 downto 0 );
    pci_exp_rxp : in STD_LOGIC_VECTOR ( 15 downto 0 );
    pci_exp_rxn : in STD_LOGIC_VECTOR ( 15 downto 0 );
    axi_aclk : out STD_LOGIC;
    axi_aresetn : out STD_LOGIC;
    usr_irq_req : in STD_LOGIC_VECTOR ( 0 to 0 );
    usr_irq_ack : out STD_LOGIC_VECTOR ( 0 to 0 );
    msi_enable : out STD_LOGIC;
    msi_vector_width : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awready : in STD_LOGIC;
    m_axi_wready : in STD_LOGIC;
    m_axi_bid : in STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_bvalid : in STD_LOGIC;
    m_axi_arready : in STD_LOGIC;
    m_axi_rid : in STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_rdata : in STD_LOGIC_VECTOR ( 511 downto 0 );
    m_axi_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_rlast : in STD_LOGIC;
    m_axi_rvalid : in STD_LOGIC;
    m_axi_awid : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_awaddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_awlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_awvalid : out STD_LOGIC;
    m_axi_awlock : out STD_LOGIC;
    m_axi_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_wdata : out STD_LOGIC_VECTOR ( 511 downto 0 );
    m_axi_wstrb : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_wlast : out STD_LOGIC;
    m_axi_wvalid : out STD_LOGIC;
    m_axi_bready : out STD_LOGIC;
    m_axi_arid : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_araddr : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axi_arlen : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axi_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axi_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axi_arvalid : out STD_LOGIC;
    m_axi_arlock : out STD_LOGIC;
    m_axi_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axi_rready : out STD_LOGIC;
    m_axil_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axil_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axil_awvalid : out STD_LOGIC;
    m_axil_awready : in STD_LOGIC;
    m_axil_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axil_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    m_axil_wvalid : out STD_LOGIC;
    m_axil_wready : in STD_LOGIC;
    m_axil_bvalid : in STD_LOGIC;
    m_axil_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axil_bready : out STD_LOGIC;
    m_axil_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axil_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    m_axil_arvalid : out STD_LOGIC;
    m_axil_arready : in STD_LOGIC;
    m_axil_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axil_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    m_axil_rvalid : in STD_LOGIC;
    m_axil_rready : out STD_LOGIC;
    cfg_mgmt_addr : in STD_LOGIC_VECTOR ( 18 downto 0 );
    cfg_mgmt_write : in STD_LOGIC;
    cfg_mgmt_write_data : in STD_LOGIC_VECTOR ( 31 downto 0 );
    cfg_mgmt_byte_enable : in STD_LOGIC_VECTOR ( 3 downto 0 );
    cfg_mgmt_read : in STD_LOGIC;
    cfg_mgmt_read_data : out STD_LOGIC_VECTOR ( 31 downto 0 );
    cfg_mgmt_read_write_done : out STD_LOGIC
  );

  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of host_xdma_bd_xdma_0_0 : entity is "host_xdma_bd_xdma_0_0,host_xdma_bd_xdma_0_0_core_top,{}";
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of host_xdma_bd_xdma_0_0 : entity is "host_xdma_bd_xdma_0_0,host_xdma_bd_xdma_0_0_core_top,{x_ipProduct=Vivado 2024.2,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=xdma,x_ipVersion=4.1,x_ipCoreRevision=31,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,COMPONENT_NAME=xdma_0,PL_UPSTREAM_FACING=true,TL_LEGACY_MODE_ENABLE=false,PCIE_BLK_LOCN=6,PL_LINK_CAP_MAX_LINK_WIDTH=16,PL_LINK_CAP_MAX_LINK_SPEED=4,REF_CLK_FREQ=0,DRP_CLK_SEL=0,FREE_RUN_FREQ=0,AXI_ADDR_WIDTH=64,AXI_DATA_WIDTH=512,CORE_CLK_FREQ=2,PLL_TYPE=2,USER_CLK_FREQ=3,SILICON_REV=Pre-Production,PIPE_SIM=FALSE,VDM_EN=FALSE,EXT_CH_GT_DRP=false,PCIE3_DRP=false,DEDICATE_PERST=false,SYS_RESET_POLARITY=0,MCAP_ENABLEMENT=NONE,EXT_STARTUP_PRIMITIVE=false,PF0_VENDOR_ID=0x10EE,PF0_DEVICE_ID=0x903F,PF0_REVISION_ID=0x00,PF0_SUBSYSTEM_VENDOR_ID=0x10EE,PF0_SUBSYSTEM_ID=0x0007,PF0_CLASS_CODE=0x070001,PF1_VENDOR_ID=0x10EE,PF1_DEVICE_ID=0x1041,PF1_REVISION_ID=0x00,PF1_SUBSYSTEM_VENDOR_ID=0x10EE,PF1_SUBSYSTEM_ID=0x0007,PF1_CLASS_CODE=0x070001,PF2_DEVICE_ID=0x1040,PF2_REVISION_ID=0x00,PF2_SUBSYSTEM_ID=0x0007,PF3_DEVICE_ID=0x1039,PF3_REVISION_ID=0x00,PF3_SUBSYSTEM_ID=0x0007,AXILITE_MASTER_APERTURE_SIZE=0x0D,AXILITE_MASTER_CONTROL=0x4,XDMA_APERTURE_SIZE=0x09,XDMA_CONTROL=0x4,AXIST_BYPASS_APERTURE_SIZE=0x0D,AXIST_BYPASS_CONTROL=0x0,PF0_INTERRUPT_PIN=0x1,PF0_MSI_CAP_MULTIMSGCAP=0,C_COMP_TIMEOUT=1,C_TIMEOUT0_SEL=0xE,C_TIMEOUT1_SEL=0xF,C_TIMEOUT_MULT=0x3,C_OLD_BRIDGE_TIMEOUT=0,SHARED_LOGIC=1,SHARED_LOGIC_CLK=false,SHARED_LOGIC_BOTH=false,SHARED_LOGIC_GTC=false,SHARED_LOGIC_GTC_7XG2=false,SHARED_LOGIC_CLK_7XG2=false,SHARED_LOGIC_BOTH_7XG2=false,EN_TRANSCEIVER_STATUS_PORTS=FALSE,IS_BOARD_PROJECT=0,EN_GT_SELECTION=FALSE,SELECT_QUAD=GTH_Quad_227,ULTRASCALE=FALSE,ULTRASCALE_PLUS=TRUE,VERSAL=FALSE,V7_GEN3=FALSE,MSI_ENABLED=TRUE,DEV_PORT_TYPE=0,XDMA_AXI_INTF_MM=1,XDMA_PCIE_64BIT_EN=xdma_pcie_64bit_en,XDMA_AXILITE_MASTER=TRUE,XDMA_AXIST_BYPASS=FALSE,XDMA_RNUM_CHNL=4,XDMA_WNUM_CHNL=4,XDMA_AXILITE_SLAVE=FALSE,XDMA_NUM_USR_IRQ=1,XDMA_RNUM_RIDS=32,XDMA_WNUM_RIDS=16,EGW_IS_PARENT_IP=1,C_M_AXI_ID_WIDTH=4,C_AXIBAR_NUM=1,C_FAMILY=zynquplus,XDMA_NUM_PCIE_TAG=256,EN_AXI_MASTER_IF=TRUE,EN_WCHNL_0=TRUE,EN_WCHNL_1=TRUE,EN_WCHNL_2=TRUE,EN_WCHNL_3=TRUE,EN_WCHNL_4=FALSE,EN_WCHNL_5=FALSE,EN_WCHNL_6=FALSE,EN_WCHNL_7=FALSE,EN_RCHNL_0=TRUE,EN_RCHNL_1=TRUE,EN_RCHNL_2=TRUE,EN_RCHNL_3=TRUE,EN_RCHNL_4=FALSE,EN_RCHNL_5=FALSE,EN_RCHNL_6=FALSE,EN_RCHNL_7=FALSE,XDMA_DSC_BYPASS=FALSE,C_METERING_ON=1,RX_DETECT=0,C_ATS_ENABLE=FALSE,C_ATS_CAP_NEXTPTR=0x000,C_PR_CAP_NEXTPTR=0x000,C_PRI_ENABLE=FALSE,DSC_BYPASS_RD=0,DSC_BYPASS_WR=0,XDMA_STS_PORTS=FALSE,MSIX_ENABLED=FALSE,WR_CH0_ENABLED=FALSE,WR_CH1_ENABLED=FALSE,WR_CH2_ENABLED=FALSE,WR_CH3_ENABLED=FALSE,RD_CH0_ENABLED=FALSE,RD_CH1_ENABLED=FALSE,RD_CH2_ENABLED=FALSE,RD_CH3_ENABLED=FALSE,CFG_MGMT_IF=TRUE,RQ_SEQ_NUM_IGNORE=0,CFG_EXT_IF=FALSE,LEGACY_CFG_EXT_IF=FALSE,C_PARITY_CHECK=0,C_PARITY_GEN=0,C_PARITY_PROP=0,C_ECC_ENABLE=0,EN_DEBUG_PORTS=FALSE,VU9P_BOARD=FALSE,ENABLE_JTAG_DBG=FALSE,ENABLE_LTSSM_DBG=FALSE,ENABLE_IBERT=FALSE,MM_SLAVE_EN=0,DMA_EN=1,C_AXIBAR_0=0x0000000000000000,C_AXIBAR_1=0x0000000000000000,C_AXIBAR_2=0x0000000000000000,C_AXIBAR_3=0x0000000000000000,C_AXIBAR_4=0x0000000000000000,C_AXIBAR_5=0x0000000000000000,C_AXIBAR_HIGHADDR_0=0x0000000000000000,C_AXIBAR_HIGHADDR_1=0x0000000000000000,C_AXIBAR_HIGHADDR_2=0x0000000000000000,C_AXIBAR_HIGHADDR_3=0x0000000000000000,C_AXIBAR_HIGHADDR_4=0x0000000000000000,C_AXIBAR_HIGHADDR_5=0x0000000000000000,C_AXIBAR2PCIEBAR_0=0x0000000000000000,C_AXIBAR2PCIEBAR_1=0x0000000000000000,C_AXIBAR2PCIEBAR_2=0x0000000000000000,C_AXIBAR2PCIEBAR_3=0x0000000000000000,C_AXIBAR2PCIEBAR_4=0x0000000000000000,C_AXIBAR2PCIEBAR_5=0x0000000000000000,EN_AXI_SLAVE_IF=TRUE,C_INCLUDE_BAROFFSET_REG=1,C_BASEADDR=0x00001000,C_HIGHADDR=0x00001FFF,C_S_AXI_ID_WIDTH=4,C_S_AXI_NUM_READ=8,C_M_AXI_NUM_READ=8,C_M_AXI_NUM_READQ=2,C_S_AXI_NUM_WRITE=8,C_M_AXI_NUM_WRITE=32,C_M_AXI_NUM_WRITE_SCALE=1,MSIX_IMPL_EXT=FALSE,AXI_ACLK_LOOPBACK=FALSE,PF0_BAR0_APERTURE_SIZE=0x0A,PF0_BAR0_CONTROL=0x4,PF0_BAR1_APERTURE_SIZE=0x05,PF0_BAR1_CONTROL=0x0,PF0_BAR2_APERTURE_SIZE=0x05,PF0_BAR2_CONTROL=0x0,PF0_BAR3_APERTURE_SIZE=0x05,PF0_BAR3_CONTROL=0x0,PF0_BAR4_APERTURE_SIZE=0x05,PF0_BAR4_CONTROL=0x0,PF0_BAR5_APERTURE_SIZE=0x05,PF0_BAR5_CONTROL=0x0,PF0_EXPANSION_ROM_APERTURE_SIZE=0x000,PF0_EXPANSION_ROM_ENABLE=FALSE,PCIEBAR_NUM=6,C_PCIEBAR2AXIBAR_0=0x0000000000000000,C_PCIEBAR2AXIBAR_1=0x0000000000000000,C_PCIEBAR2AXIBAR_2=0x0000000000000000,C_PCIEBAR2AXIBAR_3=0x0000000000000000,C_PCIEBAR2AXIBAR_4=0x0000000000000000,C_PCIEBAR2AXIBAR_5=0x0000000000000000,C_PCIEBAR2AXIBAR_6=0x0000000000000000,BARLITE1=1,BARLITE2=7,VCU118_BOARD=FALSE,ENABLE_ERROR_INJECTION=FALSE,SPLIT_DMA=FALSE,USE_STANDARD_INTERFACES=FALSE,DMA_2RP=FALSE,SRIOV_ACTIVE_VFS=252,PIPE_LINE_STAGE=2,AXIS_PIPE_LINE_STAGE=0,MULT_PF_DES=FALSE,PF_SWAP=FALSE,PF0_MSIX_TAR_ID=0x08,PF1_MSIX_TAR_ID=0x09,RUNBIT_FIX=FALSE,USRINT_EXPN=FALSE,xlnx_ref_board=None,GTWIZ_IN_CORE=1,GTCOM_IN_CORE=2,INS_LOSS_PROFILE=Add-in_Card,FUNC_MODE=1,PF1_ENABLED=0,DMA_RESET_SOURCE_SEL=0,PF1_BAR0_APERTURE_SIZE=0x12,PF1_BAR0_CONTROL=0x4,PF1_BAR1_APERTURE_SIZE=0x0A,PF1_BAR1_CONTROL=0x4,PF1_BAR2_APERTURE_SIZE=0x0A,PF1_BAR2_CONTROL=0x6,PF1_BAR3_APERTURE_SIZE=0x0A,PF1_BAR3_CONTROL=0x0,PF1_BAR4_APERTURE_SIZE=0x0A,PF1_BAR4_CONTROL=0x6,PF1_BAR5_APERTURE_SIZE=0x0A,PF1_BAR5_CONTROL=0x0,PF1_EXPANSION_ROM_APERTURE_SIZE=0x000,PF1_EXPANSION_ROM_ENABLE=FALSE,PF1_PCIEBAR2AXIBAR_0=0x0000000000000000,PF1_PCIEBAR2AXIBAR_1=0x0000000000000000,PF1_PCIEBAR2AXIBAR_2=0x0000000000000000,PF1_PCIEBAR2AXIBAR_3=0x0000000000000000,PF1_PCIEBAR2AXIBAR_4=0x0000000000000000,PF1_PCIEBAR2AXIBAR_5=0x0000000000000000,PF1_PCIEBAR2AXIBAR_6=0x0000000000000000,C_MSIX_INT_TABLE_EN=0,VU9P_TUL_EX=FALSE,PCIE_BLK_TYPE=0,CCIX_ENABLE=FALSE,CCIX_DVSEC=FALSE,EXT_SYS_CLK_BUFG=FALSE,C_NUM_OF_SC=1,USR_IRQ_EXDES=FALSE,AXI_VIP_IN_EXDES=FALSE,PIPE_DEBUG_EN=FALSE,XDMA_NON_INCREMENTAL_EXDES=FALSE,XDMA_ST_INFINITE_DESC_EXDES=FALSE,EXT_XVC_VSEC_ENABLE=FALSE,ACS_EXT_CAP_ENABLE=FALSE,EN_PCIE_DEBUG_PORTS=FALSE,MULTQ_EN=0,DMA_MM=1,DMA_ST=0,C_PCIE_PFS_SUPPORTED=0,C_SRIOV_EN=0,BARLITE_EXT_PF0=0x01,BARLITE_EXT_PF1=0x00,BARLITE_EXT_PF2=0x00,BARLITE_EXT_PF3=0x00,BARLITE_INT_PF0=0x02,BARLITE_INT_PF1=0x00,BARLITE_INT_PF2=0x00,BARLITE_INT_PF3=0x00,NUM_VFS_PF0=0,NUM_VFS_PF1=0,NUM_VFS_PF2=0,NUM_VFS_PF3=0,FIRSTVF_OFFSET_PF0=0,FIRSTVF_OFFSET_PF1=0,FIRSTVF_OFFSET_PF2=0,FIRSTVF_OFFSET_PF3=0,VF_BARLITE_EXT_PF0=0x00,VF_BARLITE_EXT_PF1=0x00,VF_BARLITE_EXT_PF2=0x00,VF_BARLITE_EXT_PF3=0x00,VF_BARLITE_INT_PF0=0x01,VF_BARLITE_INT_PF1=0x01,VF_BARLITE_INT_PF2=0x01,VF_BARLITE_INT_PF3=0x01,C_C2H_NUM_CHNL=4,C_H2C_NUM_CHNL=4,H2C_XDMA_CHNL=0x0F,C2H_XDMA_CHNL=0x0F,AXISTEN_IF_ENABLE_MSG_ROUTE=0x00000,ENABLE_MORE=FALSE,DISABLE_BRAM_PIPELINE=FALSE,DISABLE_EQ_SYNCHRONIZER=FALSE,C_ENABLE_RESOURCE_REDUCTION=FALSE,GEN4_EIEOS_0S7=TRUE,C_S_AXI_SUPPORTS_NARROW_BURST=0,ENABLE_ATS_SWITCH=FALSE,C_ATS_SWITCH_UNIQUE_BDF=1,BRIDGE_BURST=FALSE,CFG_SPACE_ENABLE=FALSE,C_LAST_CORE_CAP_ADDR=0x100,C_VSEC_CAP_ADDR=0x128,SOFT_RESET_EN=FALSE,INTERRUPT_OUT_WIDTH=1,C_MSI_RX_PIN_EN=0,C_MSIX_RX_PIN_EN=1,C_INTX_RX_PIN_EN=1,MSIX_RX_DECODE_EN=FALSE,PCIE_ID_IF=FALSE,TL_PF_ENABLE_REG=0,AXSIZE_BYTE_ACCESS_EN=FALSE,SPLIT_DMA_SINGLE_PF=FALSE,RBAR_ENABLE=FALSE,C_SMMU_EN=0,C_M_AXI_AWUSER_WIDTH=8,C_M_AXI_ARUSER_WIDTH=8,C_SLAVE_READ_64OS_EN=0,FLR_ENABLE=FALSE,SHELL_BRIDGE=0,MSIX_PCIE_INTERNAL=0,VERSAL_PART_TYPE=SXX,TANDEM_RFSOC=FALSE,ERRC_DEC_EN=FALSE}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of host_xdma_bd_xdma_0_0 : entity is "yes";
end host_xdma_bd_xdma_0_0;

architecture stub of host_xdma_bd_xdma_0_0 is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "sys_clk,sys_clk_gt,sys_rst_n,user_lnk_up,pci_exp_txp[15:0],pci_exp_txn[15:0],pci_exp_rxp[15:0],pci_exp_rxn[15:0],axi_aclk,axi_aresetn,usr_irq_req[0:0],usr_irq_ack[0:0],msi_enable,msi_vector_width[2:0],m_axi_awready,m_axi_wready,m_axi_bid[3:0],m_axi_bresp[1:0],m_axi_bvalid,m_axi_arready,m_axi_rid[3:0],m_axi_rdata[511:0],m_axi_rresp[1:0],m_axi_rlast,m_axi_rvalid,m_axi_awid[3:0],m_axi_awaddr[63:0],m_axi_awlen[7:0],m_axi_awsize[2:0],m_axi_awburst[1:0],m_axi_awprot[2:0],m_axi_awvalid,m_axi_awlock,m_axi_awcache[3:0],m_axi_wdata[511:0],m_axi_wstrb[63:0],m_axi_wlast,m_axi_wvalid,m_axi_bready,m_axi_arid[3:0],m_axi_araddr[63:0],m_axi_arlen[7:0],m_axi_arsize[2:0],m_axi_arburst[1:0],m_axi_arprot[2:0],m_axi_arvalid,m_axi_arlock,m_axi_arcache[3:0],m_axi_rready,m_axil_awaddr[31:0],m_axil_awprot[2:0],m_axil_awvalid,m_axil_awready,m_axil_wdata[31:0],m_axil_wstrb[3:0],m_axil_wvalid,m_axil_wready,m_axil_bvalid,m_axil_bresp[1:0],m_axil_bready,m_axil_araddr[31:0],m_axil_arprot[2:0],m_axil_arvalid,m_axil_arready,m_axil_rdata[31:0],m_axil_rresp[1:0],m_axil_rvalid,m_axil_rready,cfg_mgmt_addr[18:0],cfg_mgmt_write,cfg_mgmt_write_data[31:0],cfg_mgmt_byte_enable[3:0],cfg_mgmt_read,cfg_mgmt_read_data[31:0],cfg_mgmt_read_write_done";
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of sys_clk : signal is "xilinx.com:signal:clock:1.0 CLK.SYS_CLK CLK";
  attribute X_INTERFACE_MODE : string;
  attribute X_INTERFACE_MODE of sys_clk : signal is "slave";
  attribute X_INTERFACE_PARAMETER : string;
  attribute X_INTERFACE_PARAMETER of sys_clk : signal is "XIL_INTERFACENAME CLK.SYS_CLK, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN host_xdma_bd_util_ds_buf_0_IBUF_DS_ODIV2, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of sys_clk_gt : signal is "xilinx.com:signal:clock:1.0 CLK.sys_clk_gt CLK";
  attribute X_INTERFACE_MODE of sys_clk_gt : signal is "slave";
  attribute X_INTERFACE_PARAMETER of sys_clk_gt : signal is "XIL_INTERFACENAME CLK.sys_clk_gt, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN host_xdma_bd_util_ds_buf_0_IBUF_OUT, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of sys_rst_n : signal is "xilinx.com:signal:reset:1.0 RST.sys_rst_n RST";
  attribute X_INTERFACE_MODE of sys_rst_n : signal is "slave";
  attribute X_INTERFACE_PARAMETER of sys_rst_n : signal is "XIL_INTERFACENAME RST.sys_rst_n, BOARD.ASSOCIATED_PARAM SYS_RST_N_BOARD_INTERFACE, TYPE PCIE_PERST, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of pci_exp_txp : signal is "xilinx.com:interface:pcie_7x_mgt:1.0 pcie_mgt txp";
  attribute X_INTERFACE_MODE of pci_exp_txp : signal is "master";
  attribute X_INTERFACE_PARAMETER of pci_exp_txp : signal is "XIL_INTERFACENAME pcie_mgt, BOARD.ASSOCIATED_PARAM PCIE_BOARD_INTERFACE";
  attribute X_INTERFACE_INFO of pci_exp_txn : signal is "xilinx.com:interface:pcie_7x_mgt:1.0 pcie_mgt txn";
  attribute X_INTERFACE_INFO of pci_exp_rxp : signal is "xilinx.com:interface:pcie_7x_mgt:1.0 pcie_mgt rxp";
  attribute X_INTERFACE_INFO of pci_exp_rxn : signal is "xilinx.com:interface:pcie_7x_mgt:1.0 pcie_mgt rxn";
  attribute X_INTERFACE_INFO of axi_aclk : signal is "xilinx.com:signal:clock:1.0 CLK.axi_aclk CLK";
  attribute X_INTERFACE_MODE of axi_aclk : signal is "master";
  attribute X_INTERFACE_PARAMETER of axi_aclk : signal is "XIL_INTERFACENAME CLK.axi_aclk, ASSOCIATED_BUSIF M_AXI:S_AXI_B:M_AXI_LITE:S_AXI_LITE:M_AXI_BYPASS:M_AXI_B:S_AXIS_C2H_0:S_AXIS_C2H_1:S_AXIS_C2H_2:S_AXIS_C2H_3:M_AXIS_H2C_0:M_AXIS_H2C_1:M_AXIS_H2C_2:M_AXIS_H2C_3:sc0_ats_m_axis_cq:sc0_ats_m_axis_rc:sc0_ats_s_axis_cc:sc0_ats_s_axis_rq:sc1_ats_m_axis_cq:sc1_ats_m_axis_rc:sc1_ats_s_axis_cc:sc1_ats_s_axis_rq:cxs_tx:cxs_rx:atspri_s_axis_rq:atspri_m_axis_cq, ASSOCIATED_RESET axi_aresetn, FREQ_HZ 250000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN host_xdma_bd_xdma_0_0_axi_aclk, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of axi_aresetn : signal is "xilinx.com:signal:reset:1.0 RST.axi_aresetn RST";
  attribute X_INTERFACE_MODE of axi_aresetn : signal is "master";
  attribute X_INTERFACE_PARAMETER of axi_aresetn : signal is "XIL_INTERFACENAME RST.axi_aresetn, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of m_axi_awready : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWREADY";
  attribute X_INTERFACE_MODE of m_axi_awready : signal is "master";
  attribute X_INTERFACE_PARAMETER of m_axi_awready : signal is "XIL_INTERFACENAME M_AXI, NUM_READ_OUTSTANDING 32, NUM_WRITE_OUTSTANDING 16, SUPPORTS_NARROW_BURST 0, HAS_BURST 0, HAS_BURST.VALUE_SRC CONSTANT, DATA_WIDTH 512, PROTOCOL AXI4, FREQ_HZ 250000000, ID_WIDTH 4, ADDR_WIDTH 64, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_LOCK 1, HAS_PROT 1, HAS_CACHE 1, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, MAX_BURST_LENGTH 256, PHASE 0.0, CLK_DOMAIN host_xdma_bd_xdma_0_0_axi_aclk, NUM_READ_THREADS 4, NUM_WRITE_THREADS 4, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of m_axi_wready : signal is "xilinx.com:interface:aximm:1.0 M_AXI WREADY";
  attribute X_INTERFACE_INFO of m_axi_bid : signal is "xilinx.com:interface:aximm:1.0 M_AXI BID";
  attribute X_INTERFACE_INFO of m_axi_bresp : signal is "xilinx.com:interface:aximm:1.0 M_AXI BRESP";
  attribute X_INTERFACE_INFO of m_axi_bvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI BVALID";
  attribute X_INTERFACE_INFO of m_axi_arready : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARREADY";
  attribute X_INTERFACE_INFO of m_axi_rid : signal is "xilinx.com:interface:aximm:1.0 M_AXI RID";
  attribute X_INTERFACE_INFO of m_axi_rdata : signal is "xilinx.com:interface:aximm:1.0 M_AXI RDATA";
  attribute X_INTERFACE_INFO of m_axi_rresp : signal is "xilinx.com:interface:aximm:1.0 M_AXI RRESP";
  attribute X_INTERFACE_INFO of m_axi_rlast : signal is "xilinx.com:interface:aximm:1.0 M_AXI RLAST";
  attribute X_INTERFACE_INFO of m_axi_rvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI RVALID";
  attribute X_INTERFACE_INFO of m_axi_awid : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWID";
  attribute X_INTERFACE_INFO of m_axi_awaddr : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWADDR";
  attribute X_INTERFACE_INFO of m_axi_awlen : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWLEN";
  attribute X_INTERFACE_INFO of m_axi_awsize : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWSIZE";
  attribute X_INTERFACE_INFO of m_axi_awburst : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWBURST";
  attribute X_INTERFACE_INFO of m_axi_awprot : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWPROT";
  attribute X_INTERFACE_INFO of m_axi_awvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWVALID";
  attribute X_INTERFACE_INFO of m_axi_awlock : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWLOCK";
  attribute X_INTERFACE_INFO of m_axi_awcache : signal is "xilinx.com:interface:aximm:1.0 M_AXI AWCACHE";
  attribute X_INTERFACE_INFO of m_axi_wdata : signal is "xilinx.com:interface:aximm:1.0 M_AXI WDATA";
  attribute X_INTERFACE_INFO of m_axi_wstrb : signal is "xilinx.com:interface:aximm:1.0 M_AXI WSTRB";
  attribute X_INTERFACE_INFO of m_axi_wlast : signal is "xilinx.com:interface:aximm:1.0 M_AXI WLAST";
  attribute X_INTERFACE_INFO of m_axi_wvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI WVALID";
  attribute X_INTERFACE_INFO of m_axi_bready : signal is "xilinx.com:interface:aximm:1.0 M_AXI BREADY";
  attribute X_INTERFACE_INFO of m_axi_arid : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARID";
  attribute X_INTERFACE_INFO of m_axi_araddr : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARADDR";
  attribute X_INTERFACE_INFO of m_axi_arlen : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARLEN";
  attribute X_INTERFACE_INFO of m_axi_arsize : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARSIZE";
  attribute X_INTERFACE_INFO of m_axi_arburst : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARBURST";
  attribute X_INTERFACE_INFO of m_axi_arprot : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARPROT";
  attribute X_INTERFACE_INFO of m_axi_arvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARVALID";
  attribute X_INTERFACE_INFO of m_axi_arlock : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARLOCK";
  attribute X_INTERFACE_INFO of m_axi_arcache : signal is "xilinx.com:interface:aximm:1.0 M_AXI ARCACHE";
  attribute X_INTERFACE_INFO of m_axi_rready : signal is "xilinx.com:interface:aximm:1.0 M_AXI RREADY";
  attribute X_INTERFACE_INFO of m_axil_awaddr : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE AWADDR";
  attribute X_INTERFACE_MODE of m_axil_awaddr : signal is "master";
  attribute X_INTERFACE_PARAMETER of m_axil_awaddr : signal is "XIL_INTERFACENAME M_AXI_LITE, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, SUPPORTS_NARROW_BURST 0, DATA_WIDTH 32, PROTOCOL AXI4LITE, FREQ_HZ 250000000, ID_WIDTH 0, ADDR_WIDTH 32, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, MAX_BURST_LENGTH 1, PHASE 0.0, CLK_DOMAIN host_xdma_bd_xdma_0_0_axi_aclk, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0";
  attribute X_INTERFACE_INFO of m_axil_awprot : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE AWPROT";
  attribute X_INTERFACE_INFO of m_axil_awvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE AWVALID";
  attribute X_INTERFACE_INFO of m_axil_awready : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE AWREADY";
  attribute X_INTERFACE_INFO of m_axil_wdata : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE WDATA";
  attribute X_INTERFACE_INFO of m_axil_wstrb : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE WSTRB";
  attribute X_INTERFACE_INFO of m_axil_wvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE WVALID";
  attribute X_INTERFACE_INFO of m_axil_wready : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE WREADY";
  attribute X_INTERFACE_INFO of m_axil_bvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE BVALID";
  attribute X_INTERFACE_INFO of m_axil_bresp : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE BRESP";
  attribute X_INTERFACE_INFO of m_axil_bready : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE BREADY";
  attribute X_INTERFACE_INFO of m_axil_araddr : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE ARADDR";
  attribute X_INTERFACE_INFO of m_axil_arprot : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE ARPROT";
  attribute X_INTERFACE_INFO of m_axil_arvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE ARVALID";
  attribute X_INTERFACE_INFO of m_axil_arready : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE ARREADY";
  attribute X_INTERFACE_INFO of m_axil_rdata : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE RDATA";
  attribute X_INTERFACE_INFO of m_axil_rresp : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE RRESP";
  attribute X_INTERFACE_INFO of m_axil_rvalid : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE RVALID";
  attribute X_INTERFACE_INFO of m_axil_rready : signal is "xilinx.com:interface:aximm:1.0 M_AXI_LITE RREADY";
  attribute X_INTERFACE_INFO of cfg_mgmt_addr : signal is "xilinx.com:interface:pcie_cfg_mgmt:1.0 pcie_cfg_mgmt ADDR";
  attribute X_INTERFACE_MODE of cfg_mgmt_addr : signal is "slave";
  attribute X_INTERFACE_INFO of cfg_mgmt_write : signal is "xilinx.com:interface:pcie_cfg_mgmt:1.0 pcie_cfg_mgmt WRITE_EN";
  attribute X_INTERFACE_INFO of cfg_mgmt_write_data : signal is "xilinx.com:interface:pcie_cfg_mgmt:1.0 pcie_cfg_mgmt WRITE_DATA";
  attribute X_INTERFACE_INFO of cfg_mgmt_byte_enable : signal is "xilinx.com:interface:pcie_cfg_mgmt:1.0 pcie_cfg_mgmt BYTE_EN";
  attribute X_INTERFACE_INFO of cfg_mgmt_read : signal is "xilinx.com:interface:pcie_cfg_mgmt:1.0 pcie_cfg_mgmt READ_EN";
  attribute X_INTERFACE_INFO of cfg_mgmt_read_data : signal is "xilinx.com:interface:pcie_cfg_mgmt:1.0 pcie_cfg_mgmt READ_DATA";
  attribute X_INTERFACE_INFO of cfg_mgmt_read_write_done : signal is "xilinx.com:interface:pcie_cfg_mgmt:1.0 pcie_cfg_mgmt READ_WRITE_DONE";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of stub : architecture is "host_xdma_bd_xdma_0_0_core_top,Vivado 2024.2";
begin
end;
