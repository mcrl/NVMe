// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
// Date        : Tue Oct 25 21:10:44 2022
// Host        : DESKTOP-UAALCIP running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub c:/Users/js-shin/Desktop/NVMe/hw/IP/icq_fifo/icq_fifo_stub.v
// Design      : icq_fifo
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu19eg-ffvd1760-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_6,Vivado 2021.2" *)
module icq_fifo(clk, srst, din, wr_en, rd_en, dout, full, empty, valid, 
  wr_rst_busy, rd_rst_busy)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[207:0],wr_en,rd_en,dout[207:0],full,empty,valid,wr_rst_busy,rd_rst_busy" */;
  input clk;
  input srst;
  input [207:0]din;
  input wr_en;
  input rd_en;
  output [207:0]dout;
  output full;
  output empty;
  output valid;
  output wr_rst_busy;
  output rd_rst_busy;
endmodule
