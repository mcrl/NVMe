// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// -------------------------------------------------------------------------------

`timescale 1 ps / 1 ps

(* BLOCK_STUB = "true" *)
module host_xdma_bd (
  host_rstn,
  host_axi_rstn,
  host_bram_addr,
  host_bram_clk,
  host_bram_din,
  host_bram_dout,
  host_bram_en,
  host_bram_rst,
  host_bram_we,
  host_ref_clk_p,
  host_ref_clk_n,
  host_mgt_rxn,
  host_mgt_rxp,
  host_mgt_txn,
  host_mgt_txp
);

  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.HOST_RSTN RST" *)
  (* X_INTERFACE_MODE = "slave RST.HOST_RSTN" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.HOST_RSTN, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
  input host_rstn;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.HOST_AXI_RSTN RST" *)
  (* X_INTERFACE_MODE = "master RST.HOST_AXI_RSTN" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.HOST_AXI_RSTN, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
  output host_axi_rstn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram ADDR" *)
  (* X_INTERFACE_MODE = "master host_bram" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME host_bram, MEM_SIZE 1048576, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE BRAM_CTRL, READ_WRITE_MODE READ_WRITE, READ_LATENCY 1" *)
  output [19:0]host_bram_addr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram CLK" *)
  output host_bram_clk;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram DIN" *)
  output [31:0]host_bram_din;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram DOUT" *)
  input [31:0]host_bram_dout;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram EN" *)
  output host_bram_en;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram RST" *)
  output host_bram_rst;
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host_bram WE" *)
  output [3:0]host_bram_we;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 host_ref CLK_P" *)
  (* X_INTERFACE_MODE = "slave host_ref" *)
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME host_ref, CAN_DEBUG false, FREQ_HZ 100000000" *)
  input [0:0]host_ref_clk_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 host_ref CLK_N" *)
  input [0:0]host_ref_clk_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt rxn" *)
  (* X_INTERFACE_MODE = "master host_mgt" *)
  input [15:0]host_mgt_rxn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt rxp" *)
  input [15:0]host_mgt_rxp;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt txn" *)
  output [15:0]host_mgt_txn;
  (* X_INTERFACE_INFO = "xilinx.com:interface:pcie_7x_mgt:1.0 host_mgt txp" *)
  output [15:0]host_mgt_txp;

  // stub module has no contents

endmodule
