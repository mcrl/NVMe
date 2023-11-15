//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
//Date        : Mon Nov 13 22:14:46 2023
//Host        : DESKTOP-4NHVH8R running 64-bit major release  (build 9200)
//Command     : generate_target host_xdma_bd.bd
//Design      : host_xdma_bd
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "host_xdma_bd,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=host_xdma_bd,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=3,numReposBlks=3,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,da_board_cnt=3,da_xdma_cnt=1,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "host_xdma_bd.hwdef" *) 
module host_xdma_bd
   (host_axi_rstn,
    host_bram_addr,
    host_bram_clk,
    host_bram_din,
    host_bram_dout,
    host_bram_en,
    host_bram_rst,
    host_bram_we,
    host_mgt_rxn,
    host_mgt_rxp,
    host_mgt_txn,
    host_mgt_txp,
    host_ref_clk_n,
    host_ref_clk_p,
    host_rstn);
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.HOST_AXI_RSTN RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.HOST_AXI_RSTN, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) output host_axi_rstn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram " *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME host_bram, MASTER_TYPE BRAM_CTRL, MEM_ECC NONE, MEM_SIZE 1048576, MEM_WIDTH 32, READ_LATENCY 1, READ_WRITE_MODE READ_WRITE" *) output [19:0]host_bram_addr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram " *) output host_bram_clk;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram " *) output [31:0]host_bram_din;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram " *) input [31:0]host_bram_dout;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram " *) output host_bram_en;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram " *) output host_bram_rst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram " *) output [3:0]host_bram_we;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt " *) input [15:0]host_mgt_rxn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt " *) input [15:0]host_mgt_rxp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt " *) output [15:0]host_mgt_txn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt " *) output [15:0]host_mgt_txp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 host_ref " *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME host_ref, CAN_DEBUG false, FREQ_HZ 100000000" *) input [0:0]host_ref_clk_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 host_ref " *) input [0:0]host_ref_clk_p;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.HOST_RSTN RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.HOST_RSTN, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) input host_rstn;

  wire [19:0]axi_bram_ctrl_0_BRAM_PORTA_ADDR;
  wire axi_bram_ctrl_0_BRAM_PORTA_CLK;
  wire [31:0]axi_bram_ctrl_0_BRAM_PORTA_DIN;
  wire [31:0]axi_bram_ctrl_0_BRAM_PORTA_DOUT;
  wire axi_bram_ctrl_0_BRAM_PORTA_EN;
  wire axi_bram_ctrl_0_BRAM_PORTA_RST;
  wire [3:0]axi_bram_ctrl_0_BRAM_PORTA_WE;
  wire [0:0]diff_clock_rtl_0_1_CLK_N;
  wire [0:0]diff_clock_rtl_0_1_CLK_P;
  wire reset_rtl_0_1;
  wire [0:0]util_ds_buf_IBUF_DS_ODIV2;
  wire [0:0]util_ds_buf_IBUF_OUT;
  wire [31:0]xdam_host_M_AXI_LITE_ARADDR;
  wire [2:0]xdam_host_M_AXI_LITE_ARPROT;
  wire xdam_host_M_AXI_LITE_ARREADY;
  wire xdam_host_M_AXI_LITE_ARVALID;
  wire [31:0]xdam_host_M_AXI_LITE_AWADDR;
  wire [2:0]xdam_host_M_AXI_LITE_AWPROT;
  wire xdam_host_M_AXI_LITE_AWREADY;
  wire xdam_host_M_AXI_LITE_AWVALID;
  wire xdam_host_M_AXI_LITE_BREADY;
  wire [1:0]xdam_host_M_AXI_LITE_BRESP;
  wire xdam_host_M_AXI_LITE_BVALID;
  wire [31:0]xdam_host_M_AXI_LITE_RDATA;
  wire xdam_host_M_AXI_LITE_RREADY;
  wire [1:0]xdam_host_M_AXI_LITE_RRESP;
  wire xdam_host_M_AXI_LITE_RVALID;
  wire [31:0]xdam_host_M_AXI_LITE_WDATA;
  wire xdam_host_M_AXI_LITE_WREADY;
  wire [3:0]xdam_host_M_AXI_LITE_WSTRB;
  wire xdam_host_M_AXI_LITE_WVALID;
  wire xdam_host_axi_aclk;
  wire xdam_host_axi_aresetn;
  wire [15:0]xdam_host_pcie_mgt_rxn;
  wire [15:0]xdam_host_pcie_mgt_rxp;
  wire [15:0]xdam_host_pcie_mgt_txn;
  wire [15:0]xdam_host_pcie_mgt_txp;

  assign axi_bram_ctrl_0_BRAM_PORTA_DOUT = host_bram_dout[31:0];
  assign diff_clock_rtl_0_1_CLK_N = host_ref_clk_n[0];
  assign diff_clock_rtl_0_1_CLK_P = host_ref_clk_p[0];
  assign host_axi_rstn = xdam_host_axi_aresetn;
  assign host_bram_addr[19:0] = axi_bram_ctrl_0_BRAM_PORTA_ADDR;
  assign host_bram_clk = axi_bram_ctrl_0_BRAM_PORTA_CLK;
  assign host_bram_din[31:0] = axi_bram_ctrl_0_BRAM_PORTA_DIN;
  assign host_bram_en = axi_bram_ctrl_0_BRAM_PORTA_EN;
  assign host_bram_rst = axi_bram_ctrl_0_BRAM_PORTA_RST;
  assign host_bram_we[3:0] = axi_bram_ctrl_0_BRAM_PORTA_WE;
  assign host_mgt_txn[15:0] = xdam_host_pcie_mgt_txn;
  assign host_mgt_txp[15:0] = xdam_host_pcie_mgt_txp;
  assign reset_rtl_0_1 = host_rstn;
  assign xdam_host_pcie_mgt_rxn = host_mgt_rxn[15:0];
  assign xdam_host_pcie_mgt_rxp = host_mgt_rxp[15:0];
  host_xdma_bd_axi_bram_ctrl_0_0 axi_bram_ctrl_0
       (.bram_addr_a(axi_bram_ctrl_0_BRAM_PORTA_ADDR),
        .bram_clk_a(axi_bram_ctrl_0_BRAM_PORTA_CLK),
        .bram_en_a(axi_bram_ctrl_0_BRAM_PORTA_EN),
        .bram_rddata_a(axi_bram_ctrl_0_BRAM_PORTA_DOUT),
        .bram_rst_a(axi_bram_ctrl_0_BRAM_PORTA_RST),
        .bram_we_a(axi_bram_ctrl_0_BRAM_PORTA_WE),
        .bram_wrdata_a(axi_bram_ctrl_0_BRAM_PORTA_DIN),
        .s_axi_aclk(xdam_host_axi_aclk),
        .s_axi_araddr(xdam_host_M_AXI_LITE_ARADDR[19:0]),
        .s_axi_aresetn(xdam_host_axi_aresetn),
        .s_axi_arprot(xdam_host_M_AXI_LITE_ARPROT),
        .s_axi_arready(xdam_host_M_AXI_LITE_ARREADY),
        .s_axi_arvalid(xdam_host_M_AXI_LITE_ARVALID),
        .s_axi_awaddr(xdam_host_M_AXI_LITE_AWADDR[19:0]),
        .s_axi_awprot(xdam_host_M_AXI_LITE_AWPROT),
        .s_axi_awready(xdam_host_M_AXI_LITE_AWREADY),
        .s_axi_awvalid(xdam_host_M_AXI_LITE_AWVALID),
        .s_axi_bready(xdam_host_M_AXI_LITE_BREADY),
        .s_axi_bresp(xdam_host_M_AXI_LITE_BRESP),
        .s_axi_bvalid(xdam_host_M_AXI_LITE_BVALID),
        .s_axi_rdata(xdam_host_M_AXI_LITE_RDATA),
        .s_axi_rready(xdam_host_M_AXI_LITE_RREADY),
        .s_axi_rresp(xdam_host_M_AXI_LITE_RRESP),
        .s_axi_rvalid(xdam_host_M_AXI_LITE_RVALID),
        .s_axi_wdata(xdam_host_M_AXI_LITE_WDATA),
        .s_axi_wready(xdam_host_M_AXI_LITE_WREADY),
        .s_axi_wstrb(xdam_host_M_AXI_LITE_WSTRB),
        .s_axi_wvalid(xdam_host_M_AXI_LITE_WVALID));
  host_xdma_bd_util_ds_buf_0 util_ds_buf
       (.IBUF_DS_N(diff_clock_rtl_0_1_CLK_N),
        .IBUF_DS_ODIV2(util_ds_buf_IBUF_DS_ODIV2),
        .IBUF_DS_P(diff_clock_rtl_0_1_CLK_P),
        .IBUF_OUT(util_ds_buf_IBUF_OUT));
  host_xdma_bd_xdma_0_0 xdam_host
       (.axi_aclk(xdam_host_axi_aclk),
        .axi_aresetn(xdam_host_axi_aresetn),
        .cfg_mgmt_addr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .cfg_mgmt_byte_enable({1'b0,1'b0,1'b0,1'b0}),
        .cfg_mgmt_read(1'b0),
        .cfg_mgmt_write(1'b0),
        .cfg_mgmt_write_data({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .m_axi_arready(1'b0),
        .m_axi_awready(1'b0),
        .m_axi_bid({1'b0,1'b0,1'b0,1'b0}),
        .m_axi_bresp({1'b0,1'b0}),
        .m_axi_bvalid(1'b0),
        .m_axi_rdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .m_axi_rid({1'b0,1'b0,1'b0,1'b0}),
        .m_axi_rlast(1'b0),
        .m_axi_rresp({1'b0,1'b0}),
        .m_axi_rvalid(1'b0),
        .m_axi_wready(1'b0),
        .m_axil_araddr(xdam_host_M_AXI_LITE_ARADDR),
        .m_axil_arprot(xdam_host_M_AXI_LITE_ARPROT),
        .m_axil_arready(xdam_host_M_AXI_LITE_ARREADY),
        .m_axil_arvalid(xdam_host_M_AXI_LITE_ARVALID),
        .m_axil_awaddr(xdam_host_M_AXI_LITE_AWADDR),
        .m_axil_awprot(xdam_host_M_AXI_LITE_AWPROT),
        .m_axil_awready(xdam_host_M_AXI_LITE_AWREADY),
        .m_axil_awvalid(xdam_host_M_AXI_LITE_AWVALID),
        .m_axil_bready(xdam_host_M_AXI_LITE_BREADY),
        .m_axil_bresp(xdam_host_M_AXI_LITE_BRESP),
        .m_axil_bvalid(xdam_host_M_AXI_LITE_BVALID),
        .m_axil_rdata(xdam_host_M_AXI_LITE_RDATA),
        .m_axil_rready(xdam_host_M_AXI_LITE_RREADY),
        .m_axil_rresp(xdam_host_M_AXI_LITE_RRESP),
        .m_axil_rvalid(xdam_host_M_AXI_LITE_RVALID),
        .m_axil_wdata(xdam_host_M_AXI_LITE_WDATA),
        .m_axil_wready(xdam_host_M_AXI_LITE_WREADY),
        .m_axil_wstrb(xdam_host_M_AXI_LITE_WSTRB),
        .m_axil_wvalid(xdam_host_M_AXI_LITE_WVALID),
        .pci_exp_rxn(xdam_host_pcie_mgt_rxn),
        .pci_exp_rxp(xdam_host_pcie_mgt_rxp),
        .pci_exp_txn(xdam_host_pcie_mgt_txn),
        .pci_exp_txp(xdam_host_pcie_mgt_txp),
        .sys_clk(util_ds_buf_IBUF_DS_ODIV2),
        .sys_clk_gt(util_ds_buf_IBUF_OUT),
        .sys_rst_n(reset_rtl_0_1),
        .usr_irq_req(1'b0));
endmodule
