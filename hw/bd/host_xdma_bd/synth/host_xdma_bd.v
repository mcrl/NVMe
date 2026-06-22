//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
//Date        : Mon Jun 22 08:55:45 2026
//Host        : aespa running 64-bit Ubuntu 20.04.5 LTS
//Command     : generate_target host_xdma_bd.bd
//Design      : host_xdma_bd
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "host_xdma_bd,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=host_xdma_bd,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=3,numReposBlks=3,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "host_xdma_bd.hwdef" *) 
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
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram ADDR" *) (* X_INTERFACE_MODE = "Master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME host_bram, MASTER_TYPE BRAM_CTRL, MEM_ECC NONE, MEM_SIZE 1048576, MEM_WIDTH 32, READ_LATENCY 1, READ_WRITE_MODE READ_WRITE" *) output [19:0]host_bram_addr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram CLK" *) output host_bram_clk;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram DIN" *) output [31:0]host_bram_din;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram DOUT" *) input [31:0]host_bram_dout;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram EN" *) output host_bram_en;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram RST" *) output host_bram_rst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram WE" *) output [3:0]host_bram_we;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt rxn" *) (* X_INTERFACE_MODE = "Master" *) input [15:0]host_mgt_rxn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt rxp" *) input [15:0]host_mgt_rxp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt txn" *) output [15:0]host_mgt_txn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt txp" *) output [15:0]host_mgt_txp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 host_ref CLK_N" *) (* X_INTERFACE_MODE = "Slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME host_ref, CAN_DEBUG false, FREQ_HZ 100000000" *) input [0:0]host_ref_clk_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 host_ref CLK_P" *) input [0:0]host_ref_clk_p;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.HOST_RSTN RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.HOST_RSTN, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) input host_rstn;

  wire host_axi_rstn;
  wire [19:0]host_bram_addr;
  wire host_bram_clk;
  wire [31:0]host_bram_din;
  wire [31:0]host_bram_dout;
  wire host_bram_en;
  wire host_bram_rst;
  wire [3:0]host_bram_we;
  wire [15:0]host_mgt_rxn;
  wire [15:0]host_mgt_rxp;
  wire [15:0]host_mgt_txn;
  wire [15:0]host_mgt_txp;
  wire [0:0]host_ref_clk_n;
  wire [0:0]host_ref_clk_p;
  wire host_rstn;
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

  host_xdma_bd_axi_bram_ctrl_0_0 axi_bram_ctrl_0
       (.bram_addr_a(host_bram_addr),
        .bram_clk_a(host_bram_clk),
        .bram_en_a(host_bram_en),
        .bram_rddata_a(host_bram_dout),
        .bram_rst_a(host_bram_rst),
        .bram_we_a(host_bram_we),
        .bram_wrdata_a(host_bram_din),
        .s_axi_aclk(xdam_host_axi_aclk),
        .s_axi_araddr(xdam_host_M_AXI_LITE_ARADDR[19:0]),
        .s_axi_aresetn(host_axi_rstn),
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
       (.IBUF_DS_N(host_ref_clk_n),
        .IBUF_DS_ODIV2(util_ds_buf_IBUF_DS_ODIV2),
        .IBUF_DS_P(host_ref_clk_p),
        .IBUF_OUT(util_ds_buf_IBUF_OUT));
  host_xdma_bd_xdma_0_0 xdam_host
       (.axi_aclk(xdam_host_axi_aclk),
        .axi_aresetn(host_axi_rstn),
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
        .pci_exp_rxn(host_mgt_rxn),
        .pci_exp_rxp(host_mgt_rxp),
        .pci_exp_txn(host_mgt_txn),
        .pci_exp_txp(host_mgt_txp),
        .sys_clk(util_ds_buf_IBUF_DS_ODIV2),
        .sys_clk_gt(util_ds_buf_IBUF_OUT),
        .sys_rst_n(host_rstn),
        .usr_irq_req(1'b0));
endmodule
