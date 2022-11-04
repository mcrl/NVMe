// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
// Date        : Fri Nov  4 14:11:00 2022
// Host        : DESKTOP-UAALCIP running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub c:/Users/js-shin/Desktop/NVMe/hw/IP/ila_cfg/ila_cfg_stub.v
// Design      : ila_cfg
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu19eg-ffvd1760-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "ila,Vivado 2021.2" *)
module ila_cfg(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9, probe10, probe11, probe12, probe13, probe14, probe15, probe16, probe17, 
  probe18, probe19, probe20, probe21, probe22, probe23, probe24, probe25, probe26, probe27)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[0:0],probe1[0:0],probe2[127:0],probe3[3:0],probe4[0:0],probe5[0:0],probe6[0:0],probe7[74:0],probe8[127:0],probe9[3:0],probe10[0:0],probe11[0:0],probe12[0:0],probe13[61:0],probe14[5:0],probe15[0:0],probe16[3:0],probe17[3:0],probe18[31:0],probe19[0:0],probe20[7:0],probe21[3:0],probe22[2:0],probe23[0:0],probe24[0:0],probe25[7:0],probe26[5:0],probe27[31:0]" */;
  input clk;
  input [0:0]probe0;
  input [0:0]probe1;
  input [127:0]probe2;
  input [3:0]probe3;
  input [0:0]probe4;
  input [0:0]probe5;
  input [0:0]probe6;
  input [74:0]probe7;
  input [127:0]probe8;
  input [3:0]probe9;
  input [0:0]probe10;
  input [0:0]probe11;
  input [0:0]probe12;
  input [61:0]probe13;
  input [5:0]probe14;
  input [0:0]probe15;
  input [3:0]probe16;
  input [3:0]probe17;
  input [31:0]probe18;
  input [0:0]probe19;
  input [7:0]probe20;
  input [3:0]probe21;
  input [2:0]probe22;
  input [0:0]probe23;
  input [0:0]probe24;
  input [7:0]probe25;
  input [5:0]probe26;
  input [31:0]probe27;
endmodule
