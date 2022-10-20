//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : UltraScale+ FPGA PCI Express v4.0 Integrated Block
// File       : board.v
// Version    : 1.3 
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// Project    : Ultrascale FPGA Gen4 Integrated Block for PCI Express
// File       : board.v
// Version    : 31.0 
//-----------------------------------------------------------------------------
//
// Description: Top level testbench
//
//------------------------------------------------------------------------------

`timescale 1ns/1ns

//`include "board_common.vh"

module board;

  parameter          REF_CLK_FREQ       = 0 ;      // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  parameter    [4:0] LINK_WIDTH         = 5'd4;
  `ifdef LINKSPEED
  localparam   [3:0] LINK_SPEED_US      = 4'h`LINKSPEED;
  `else
  localparam   [3:0] LINK_SPEED_US      = 4'h4;
  `endif
  localparam   [1:0] LINK_SPEED         = (LINK_SPEED_US == 4'h8) ? 2'h3 :
                                          (LINK_SPEED_US == 4'h4) ? 2'h2 :
                                          (LINK_SPEED_US == 4'h2) ? 2'h1 : 2'h0;

  localparam         REF_CLK_HALF_CYCLE = (REF_CLK_FREQ == 0) ? 5000 :
                                          (REF_CLK_FREQ == 1) ? 4000 :
                                          (REF_CLK_FREQ == 2) ? 2000 : 0;

  localparam   [2:0] PF0_DEV_CAP_MAX_PAYLOAD_SIZE = 3'b011; //fixed the MPS to 1024 bytes
//  Comment below line to support post synth/impl simulation support
//  defparam board.EP.pcie4_uscale_plus_0_i.inst.PL_SIM_FAST_LINK_TRAINING=2'h3;
//
//
//
  localparam EXT_PIPE_SIM = "FALSE";

  localparam MSI_INT  = 32 ;
  localparam  PL_LINK_CAP_MAX_LINK_WIDTH   = 4'h4;
  localparam AXI4_CQ_TUSER_WIDTH          = 88;
  localparam AXI4_CC_TUSER_WIDTH          = 33;
  localparam AXI4_RQ_TUSER_WIDTH          = 62; 
  localparam AXI4_RC_TUSER_WIDTH          = 75;
  localparam AXI4_CC_TREADY_WIDTH         = 4 ;
  localparam AXI4_RQ_TREADY_WIDTH         = 4 ; 
  localparam AXI4_DATA_WIDTH              = 256;
  localparam AXI4_TKEEP_WIDTH            = 8; 

  integer            i;

  // System-level clock and reset
  reg                sys_rst_n;

  wire               ep_sys_clk_p;
  wire               ep_sys_clk_n;
  wire               rp_sys_clk_p;
  wire               rp_sys_clk_n;


  //
  // PCI-Express Serial Interconnect
  //
  wire  [(LINK_WIDTH-1):0]  ep_pci_exp_txn;
  wire  [(LINK_WIDTH-1):0]  ep_pci_exp_txp;
  wire  [(LINK_WIDTH-1):0]  rp_pci_exp_txn;
  wire  [(LINK_WIDTH-1):0]  rp_pci_exp_txp;
  wire  [11:0] rp_txn;
  wire  [11:0] rp_txp;
 

// Ltssm debug signal
 wire [5:0]     cfg_ltssm_state;
 assign cfg_ltssm_state   =  board.EP.pcie4_uscale_plus_0_i.inst.cfg_ltssm_state;

 

  sys_clk_gen_ds # (
    .halfcycle(REF_CLK_HALF_CYCLE),
    .offset(0)
  )
  CLK_GEN_RP (
    .sys_clk_p(rp_sys_clk_p),
    .sys_clk_n(rp_sys_clk_n)
  );

  sys_clk_gen_ds # (
    .halfcycle(REF_CLK_HALF_CYCLE),
    .offset(0)
  )
  CLK_GEN_EP (
    .sys_clk_p(ep_sys_clk_p),
    .sys_clk_n(ep_sys_clk_n)
  );


  //------------------------------------------------------------------------------//
  // Generate system-level reset
  //------------------------------------------------------------------------------//
  initial begin
    $display("[%t] : System Reset Is Asserted...", $realtime);
    sys_rst_n = 1'b1;
    repeat (500) @(posedge rp_sys_clk_p);
    $display("[%t] : System Reset Is De-asserted...", $realtime);
    sys_rst_n = 1'b0;
  end


  //------------------------------------------------------------------------------//
  // Simulation endpoint with PIO Slave
  //------------------------------------------------------------------------------//
  //
  // PCI-Express Endpoint Instance
  //

  xilinx_pcie4_uscale_ep 
 EP (
    // SYS Inteface
    .sys_clk_n(ep_sys_clk_n),
    .sys_clk_p(ep_sys_clk_p),
    .sys_rst_n(sys_rst_n),



    // PCI-Express Serial Interface
    .pci_exp_txn(ep_pci_exp_txn),
    .pci_exp_txp(ep_pci_exp_txp),
    .pci_exp_rxn(rp_pci_exp_txn),
    .pci_exp_rxp(rp_pci_exp_txp)
  );

  //------------------------------------------------------------------------------//
  // Simulation Root Port Model
  // (Comment out this module to interface EndPoint with BFM)
  
  //------------------------------------------------------------------------------//
  // PCI-Express Model Root Port Instance
  //-----------------------------------------------------------------------------//

  nvme_top nvme_top_inst (
    .pcie_0a_txp(rp_pci_exp_txp),
    .pcie_0a_txn(rp_pci_exp_txn),
    .pcie_0a_rxp(ep_pci_exp_txp),
    .pcie_0a_rxn(ep_pci_exp_txn),
    .oc0_cprsnt_n(),
    .oc0_perst_n(),
    .pcie_0a_sys_clk(rp_sys_clk_p),
    .sys_rst_n(!sys_rst_n)
    //.pcie_0a_sys_clk_n(rp_sys_clk_n)
  );



  initial begin
    #2500000;  // 200us timeout
    $display("[%t] : Simulation timeout. TEST FAILED", $realtime);
    #100;
    $finish;
    end



endmodule // BOARD
