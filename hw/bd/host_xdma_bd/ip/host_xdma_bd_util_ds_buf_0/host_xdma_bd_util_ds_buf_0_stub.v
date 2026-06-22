// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
// Date        : Mon Jun 22 08:56:51 2026
// Host        : aespa running 64-bit Ubuntu 20.04.5 LTS
// Command     : write_verilog -force -mode synth_stub -rename_top host_xdma_bd_util_ds_buf_0 -prefix
//               host_xdma_bd_util_ds_buf_0_ host_xdma_bd_util_ds_buf_0_stub.v
// Design      : host_xdma_bd_util_ds_buf_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu19eg-ffvd1760-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CHECK_LICENSE_TYPE = "host_xdma_bd_util_ds_buf_0,util_ds_buf,{}" *) (* core_generation_info = "host_xdma_bd_util_ds_buf_0,util_ds_buf,{x_ipProduct=Vivado 2024.2,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=util_ds_buf,x_ipVersion=2.2,x_ipCoreRevision=7,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_SIZE=1,C_BUF_TYPE=ibufdsgte4,C_BUFGCE_DIV=1,C_BUFG_GT_SYNC=0,C_OBUFDS_GTE5_ADV=00,C_REFCLK_ICNTL_TX=00000,C_SIM_DEVICE=VERSAL_AI_CORE_ES1}" *) (* downgradeipidentifiedwarnings = "yes" *) 
(* x_core_info = "util_ds_buf,Vivado 2024.2" *) 
module host_xdma_bd_util_ds_buf_0(IBUF_DS_P, IBUF_DS_N, IBUF_OUT, IBUF_DS_ODIV2)
/* synthesis syn_black_box black_box_pad_pin="IBUF_DS_P[0:0],IBUF_DS_N[0:0],IBUF_OUT[0:0],IBUF_DS_ODIV2[0:0]" */;
  (* x_interface_info = "xilinx.com:interface:diff_clock:1.0 CLK_IN_D CLK_P" *) (* x_interface_mode = "slave CLK_IN_D" *) (* x_interface_parameter = "XIL_INTERFACENAME CLK_IN_D, BOARD.ASSOCIATED_PARAM DIFF_CLK_IN_BOARD_INTERFACE, CAN_DEBUG false, FREQ_HZ 100000000" *) input [0:0]IBUF_DS_P;
  (* x_interface_info = "xilinx.com:interface:diff_clock:1.0 CLK_IN_D CLK_N" *) input [0:0]IBUF_DS_N;
  (* x_interface_info = "xilinx.com:signal:clock:1.0 IBUF_OUT CLK" *) (* x_interface_mode = "master IBUF_OUT" *) (* x_interface_parameter = "XIL_INTERFACENAME IBUF_OUT, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN host_xdma_bd_util_ds_buf_0_IBUF_OUT, INSERT_VIP 0" *) output [0:0]IBUF_OUT;
  (* x_interface_info = "xilinx.com:signal:clock:1.0 IBUF_DS_ODIV2 CLK" *) (* x_interface_mode = "master IBUF_DS_ODIV2" *) (* x_interface_parameter = "XIL_INTERFACENAME IBUF_DS_ODIV2, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN host_xdma_bd_util_ds_buf_0_IBUF_DS_ODIV2, INSERT_VIP 0" *) output [0:0]IBUF_DS_ODIV2;
endmodule
