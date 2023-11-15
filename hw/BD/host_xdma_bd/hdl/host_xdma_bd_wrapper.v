//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
//Date        : Mon Nov 13 22:14:46 2023
//Host        : DESKTOP-4NHVH8R running 64-bit major release  (build 9200)
//Command     : generate_target host_xdma_bd_wrapper.bd
//Design      : host_xdma_bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module host_xdma_bd_wrapper
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
  output host_axi_rstn;
  output [19:0]host_bram_addr;
  output host_bram_clk;
  output [31:0]host_bram_din;
  input [31:0]host_bram_dout;
  output host_bram_en;
  output host_bram_rst;
  output [3:0]host_bram_we;
  input [15:0]host_mgt_rxn;
  input [15:0]host_mgt_rxp;
  output [15:0]host_mgt_txn;
  output [15:0]host_mgt_txp;
  input [0:0]host_ref_clk_n;
  input [0:0]host_ref_clk_p;
  input host_rstn;

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

  host_xdma_bd host_xdma_bd_i
       (.host_axi_rstn(host_axi_rstn),
        .host_bram_addr(host_bram_addr),
        .host_bram_clk(host_bram_clk),
        .host_bram_din(host_bram_din),
        .host_bram_dout(host_bram_dout),
        .host_bram_en(host_bram_en),
        .host_bram_rst(host_bram_rst),
        .host_bram_we(host_bram_we),
        .host_mgt_rxn(host_mgt_rxn),
        .host_mgt_rxp(host_mgt_rxp),
        .host_mgt_txn(host_mgt_txn),
        .host_mgt_txp(host_mgt_txp),
        .host_ref_clk_n(host_ref_clk_n),
        .host_ref_clk_p(host_ref_clk_p),
        .host_rstn(host_rstn));
endmodule
