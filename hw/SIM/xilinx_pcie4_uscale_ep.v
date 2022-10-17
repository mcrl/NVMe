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
// File       : xilinx_pcie4_uscale_ep.v
// Version    : 1.3 
//-----------------------------------------------------------------------------
//--
//-- Description:  PCI Express Endpoint example FPGA design
//--
//------------------------------------------------------------------------------
`define PCIE4_NEW_PINS 1 
`timescale 1ps / 1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module xilinx_pcie4_uscale_ep # (
/*
*/
  parameter [4:0]    PL_LINK_CAP_MAX_LINK_WIDTH     = 4,  // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16
  parameter          C_DATA_WIDTH                   = 256,         // RX/TX interface data width
  parameter          AXISTEN_IF_MC_RX_STRADDLE      = 1,
  parameter          PL_LINK_CAP_MAX_LINK_SPEED     = 4,  // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4
  parameter          KEEP_WIDTH                     = C_DATA_WIDTH / 32,
  parameter          EXT_PIPE_SIM                   = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.
  parameter          AXISTEN_IF_CC_ALIGNMENT_MODE   = "FALSE",
  parameter          AXISTEN_IF_CQ_ALIGNMENT_MODE   = "FALSE",
  parameter          AXISTEN_IF_RQ_ALIGNMENT_MODE   = "FALSE",
  parameter          AXISTEN_IF_RC_ALIGNMENT_MODE   = "FALSE",
  parameter          AXI4_CQ_TUSER_WIDTH            = 88,
  parameter          AXI4_CC_TUSER_WIDTH            = 33,
  parameter          AXI4_RQ_TUSER_WIDTH            = 62,
  parameter          AXI4_RC_TUSER_WIDTH            = 75,
  parameter          AXISTEN_IF_ENABLE_CLIENT_TAG   = 0,
  parameter          RQ_AVAIL_TAG_IDX               = 8,
  parameter          RQ_AVAIL_TAG                   = 256,
  parameter          AXISTEN_IF_RQ_PARITY_CHECK     = 0,
  parameter          AXISTEN_IF_CC_PARITY_CHECK     = 0,
  parameter          AXISTEN_IF_RC_PARITY_CHECK     = 0,
  parameter          AXISTEN_IF_CQ_PARITY_CHECK     = 0,
  parameter          AXISTEN_IF_ENABLE_RX_MSG_INTFC = "FALSE",
  parameter   [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE    = 18'h2FFFF
) (
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txp,
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txn,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxp,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxn,





  input                                           sys_clk_p,
  input                                           sys_clk_n,

  input                                           sys_rst_n
);

  // Local Parameters derived from user selection
  localparam        TCQ = 1;

  wire                                       user_lnk_up;
  wire                                       phy_rdy_out;


  //----------------------------------------------------------------------------------------------------------------//
  //  AXI Interface                                                                                                 //
  //----------------------------------------------------------------------------------------------------------------//

  wire                                       user_clk;
  wire                                       user_reset;

  wire                                       s_axis_rq_tlast;
  wire                 [C_DATA_WIDTH-1:0]    s_axis_rq_tdata;
  wire          [AXI4_RQ_TUSER_WIDTH-1:0]    s_axis_rq_tuser;
  wire                   [KEEP_WIDTH-1:0]    s_axis_rq_tkeep;
  wire                              [3:0]    s_axis_rq_tready;
  wire                                       s_axis_rq_tvalid;

  wire                 [C_DATA_WIDTH-1:0]    m_axis_rc_tdata;
  wire          [AXI4_RC_TUSER_WIDTH-1:0]    m_axis_rc_tuser;
  wire                                       m_axis_rc_tlast;
  wire                   [KEEP_WIDTH-1:0]    m_axis_rc_tkeep;
  wire                                       m_axis_rc_tvalid;
  wire                                       m_axis_rc_tready;

  wire                 [C_DATA_WIDTH-1:0]    m_axis_cq_tdata;
  wire          [AXI4_CQ_TUSER_WIDTH-1:0]    m_axis_cq_tuser;
  wire                                       m_axis_cq_tlast;
  wire                   [KEEP_WIDTH-1:0]    m_axis_cq_tkeep;
  wire                                       m_axis_cq_tvalid;
  wire                                       m_axis_cq_tready;

  wire                 [C_DATA_WIDTH-1:0]    s_axis_cc_tdata;
  wire          [AXI4_CC_TUSER_WIDTH-1:0]    s_axis_cc_tuser;
  wire                                       s_axis_cc_tlast;
  wire                   [KEEP_WIDTH-1:0]    s_axis_cc_tkeep;
  wire                                       s_axis_cc_tvalid;
  wire                              [3:0]    s_axis_cc_tready;

  wire                              [3:0]    pcie_tfc_nph_av;
  wire                              [3:0]    pcie_tfc_npd_av;
  //----------------------------------------------------------------------------------------------------------------//
  //  Configuration (CFG) Interface                                                                                 //
  //----------------------------------------------------------------------------------------------------------------//

  wire                                       pcie_cq_np_req;
  wire                              [5:0]    pcie_cq_np_req_count;
  wire                              [5:0]    pcie_rq_seq_num0;
  wire                                       pcie_rq_seq_num_vld0;
  wire                              [5:0]    pcie_rq_seq_num1;
  wire                                       pcie_rq_seq_num_vld1;

  //----------------------------------------------------------------------------------------------------------------//
  // EP and RP                                                                                                      //
  //----------------------------------------------------------------------------------------------------------------//

  wire                                       cfg_phy_link_down;
  wire                              [2:0]    cfg_negotiated_width;
  wire                              [1:0]    cfg_current_speed;
  wire                              [1:0]    cfg_max_payload;
  wire                              [2:0]    cfg_max_read_req;
  wire                              [15:0]    cfg_function_status;
  wire                              [11:0]    cfg_function_power_state;
  wire                             [503:0]    cfg_vf_status;
  wire                              [1:0]    cfg_link_power_state;

  // Error Reporting Interface
  wire                                       cfg_err_cor_out;
  wire                                       cfg_err_nonfatal_out;
  wire                                       cfg_err_fatal_out;

  wire                              [5:0]    cfg_ltssm_state;
  wire                              [3:0]    cfg_rcb_status;
  wire                              [1:0]    cfg_obff_enable;
  wire                                       cfg_pl_status_change;

  // Management Interface
  wire                             [9:0]    cfg_mgmt_addr;
  wire                                       cfg_mgmt_write;
  wire                             [31:0]    cfg_mgmt_write_data;
  wire                              [3:0]    cfg_mgmt_byte_enable;
  wire                                       cfg_mgmt_read;
  wire                             [31:0]    cfg_mgmt_read_data;
  wire                                       cfg_mgmt_read_write_done;
  wire                                       cfg_mgmt_type1_cfg_reg_access;
  wire                                       cfg_msg_received;
  wire                              [7:0]    cfg_msg_received_data;
  wire                              [4:0]    cfg_msg_received_type;
  wire                                       cfg_msg_transmit;
  wire                              [2:0]    cfg_msg_transmit_type;
  wire                             [31:0]    cfg_msg_transmit_data;
  wire                                       cfg_msg_transmit_done;
  wire                              [7:0]    cfg_fc_ph;
  wire                             [11:0]    cfg_fc_pd;
  wire                              [7:0]    cfg_fc_nph;
  wire                             [11:0]    cfg_fc_npd;
  wire                              [7:0]    cfg_fc_cplh;
  wire                             [11:0]    cfg_fc_cpld;
  wire                              [2:0]    cfg_fc_sel;
  wire                              [2:0]    cfg_per_func_status_control;
  wire                              [3:0]    cfg_per_function_number;
  wire                                       cfg_per_function_output_request;

  wire                             [63:0]    cfg_dsn;
  wire                                       cfg_power_state_change_interrupt;
  wire                                       cfg_power_state_change_ack;
  wire                                       cfg_err_cor_in;
  wire                                       cfg_err_uncor_in;

  wire                              [3:0]    cfg_flr_in_process;
  wire                              [1:0]    cfg_flr_done;
  wire                              [251:0]  cfg_vf_flr_in_process;
  wire                                       cfg_vf_flr_done;
  wire                              [7:0]    cfg_vf_flr_func_num;

  wire                                       cfg_link_training_enable;

  //----------------------------------------------------------------------------------------------------------------//
  // EP Only                                                                                                        //
  //----------------------------------------------------------------------------------------------------------------//

  // Interrupt Interface Signals
  wire                              [3:0]    cfg_interrupt_int;
  wire                              [1:0]    cfg_interrupt_pending;
  wire                                       cfg_interrupt_sent;

  wire                              [3:0]    cfg_interrupt_msi_enable;
  wire                              [11:0]   cfg_interrupt_msi_mmenable;
  wire                                       cfg_interrupt_msi_mask_update;
  wire                             [31:0]    cfg_interrupt_msi_data;
  wire                              [1:0]    cfg_interrupt_msi_select;
  wire                             [31:0]    cfg_interrupt_msi_int;
  wire                             [63:0]    cfg_interrupt_msi_pending_status;
  wire                                       cfg_interrupt_msi_sent;
  wire                                       cfg_interrupt_msi_fail;
  wire                              [2:0]    cfg_interrupt_msi_attr;
  wire                                       cfg_interrupt_msi_tph_present;
  wire                              [1:0]    cfg_interrupt_msi_tph_type;
  wire                              [7:0]    cfg_interrupt_msi_tph_st_tag;
  wire                              [7:0]    cfg_interrupt_msi_function_number;

// EP only
  wire                                       cfg_hot_reset_out;
  wire                                       cfg_config_space_enable;
  wire                                       cfg_req_pm_transition_l23_ready;

// RP only
  wire                                       cfg_hot_reset_in;

  wire                              [7:0]    cfg_ds_port_number;
  wire                              [7:0]    cfg_ds_bus_number;
  wire                              [4:0]    cfg_ds_device_number;

  //----------------------------------------------------------------------------------------------------------------//
  //    System(SYS) Interface                                                                                       //
  //----------------------------------------------------------------------------------------------------------------//

  wire                                       sys_clk;
  wire                                       sys_clk_gt;
  wire                                       sys_rst_n_c;
  //-----------------------------------------------------------------------------------------------------------------------



  IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));

  IBUFDS_GTE4 refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));


  wire [15:0]  cfg_vend_id        = 16'h10EE;   
  wire [15:0]  cfg_dev_id         = 16'hABBA;   
  wire [15:0]  cfg_dev_id_pf1     = 16'h9138;   
  wire [15:0]  cfg_subsys_id      = 16'h0007;                                
  wire [7:0]   cfg_rev_id         = 8'h00; 
  wire [15:0]  cfg_subsys_vend_id = 16'h10EE;
  
 




//
//

//------------------------------------------------------------------------------------------------------------------//
//                                     PCIe Core Top Level Wrapper                                                  //
//------------------------------------------------------------------------------------------------------------------//
// Core Top Level Wrapper
 pcie4_uscale_plus_0  pcie4_uscale_plus_0_i (
    //---------------------------------------------------------------------------------------//
    //  ID Ports 
    //---------------------------------------------------------------------------------------//





    //---------------------------------------------------------------------------------------//
    //  PCI Express (pci_exp) Interface                                                      //
    //---------------------------------------------------------------------------------------//

    // Tx
    .pci_exp_txn                                    ( pci_exp_txn ),
    .pci_exp_txp                                    ( pci_exp_txp ),

    // Rx
    .pci_exp_rxn                                    ( pci_exp_rxn ),
    .pci_exp_rxp                                    ( pci_exp_rxp ),
    
    //---------------------------------------------------------------------------------------//
    //  AXI Interface                                                                        //
    //---------------------------------------------------------------------------------------//

    .user_clk                                       ( user_clk ),
    .user_reset                                     ( user_reset ),
    .user_lnk_up                                    ( user_lnk_up ),
    .phy_rdy_out                                    ( phy_rdy_out ),
  
    .s_axis_rq_tlast                                ( s_axis_rq_tlast ),
    .s_axis_rq_tdata                                ( s_axis_rq_tdata ),
    .s_axis_rq_tuser                                ( s_axis_rq_tuser ),
    .s_axis_rq_tkeep                                ( s_axis_rq_tkeep ),
    .s_axis_rq_tready                               ( s_axis_rq_tready ),
    .s_axis_rq_tvalid                               ( s_axis_rq_tvalid ),

    .m_axis_rc_tdata                                ( m_axis_rc_tdata ),
    .m_axis_rc_tuser                                ( m_axis_rc_tuser ),
    .m_axis_rc_tlast                                ( m_axis_rc_tlast ),
    .m_axis_rc_tkeep                                ( m_axis_rc_tkeep ),
    .m_axis_rc_tvalid                               ( m_axis_rc_tvalid ),
    .m_axis_rc_tready                               ( m_axis_rc_tready ),

    .m_axis_cq_tdata                                ( m_axis_cq_tdata ),
    .m_axis_cq_tuser                                ( m_axis_cq_tuser ),
    .m_axis_cq_tlast                                ( m_axis_cq_tlast ),
    .m_axis_cq_tkeep                                ( m_axis_cq_tkeep ),
    .m_axis_cq_tvalid                               ( m_axis_cq_tvalid ),
    .m_axis_cq_tready                               ( m_axis_cq_tready ),

    .s_axis_cc_tdata                                ( s_axis_cc_tdata ),
    .s_axis_cc_tuser                                ( s_axis_cc_tuser ),
    .s_axis_cc_tlast                                ( s_axis_cc_tlast ),
    .s_axis_cc_tkeep                                ( s_axis_cc_tkeep ),
    .s_axis_cc_tvalid                               ( s_axis_cc_tvalid ),
    .s_axis_cc_tready                               ( s_axis_cc_tready ),



    //---------------------------------------------------------------------------------------//
    //  Configuration (CFG) Interface                                                        //
    //---------------------------------------------------------------------------------------//
    .pcie_tfc_nph_av                                ( pcie_tfc_nph_av ),
    .pcie_tfc_npd_av                                ( pcie_tfc_npd_av ),

    .pcie_rq_seq_num0                               ( pcie_rq_seq_num0     ) ,
    .pcie_rq_seq_num_vld0                           ( pcie_rq_seq_num_vld0 ) ,
    .pcie_rq_seq_num1                               ( pcie_rq_seq_num1     ) ,
    .pcie_rq_seq_num_vld1                           ( pcie_rq_seq_num_vld1 ) ,
    .pcie_rq_tag0                                   ( ) ,
    .pcie_rq_tag1                                   ( ) ,
    .pcie_rq_tag_av                                 ( ) ,
    .pcie_rq_tag_vld0                               ( ) ,
    .pcie_rq_tag_vld1                               ( ) ,
    .pcie_cq_np_req                                 ( {1'b0,pcie_cq_np_req} ),
    .pcie_cq_np_req_count                           ( pcie_cq_np_req_count ),
    .cfg_phy_link_down                              ( cfg_phy_link_down ),
    .cfg_phy_link_status                            ( ),
    .cfg_negotiated_width                           ( cfg_negotiated_width ),
    .cfg_current_speed                              ( cfg_current_speed ),
    .cfg_max_payload                                ( cfg_max_payload ),
    .cfg_max_read_req                               ( cfg_max_read_req ),
    .cfg_function_status                            ( cfg_function_status ),
    .cfg_function_power_state                       ( cfg_function_power_state ),
    .cfg_vf_status                                  ( cfg_vf_status ),
    .cfg_vf_power_state                             ( ),
    .cfg_link_power_state                           ( cfg_link_power_state ),
    // Error Reporting Interface
    .cfg_err_cor_out                                ( cfg_err_cor_out ),
    .cfg_err_nonfatal_out                           ( cfg_err_nonfatal_out ),
    .cfg_err_fatal_out                              ( cfg_err_fatal_out ),

    .cfg_local_error_out                                ( ),
    .cfg_local_error_valid                          ( ),

    .cfg_ltssm_state                                ( cfg_ltssm_state ),
    .cfg_rx_pm_state                                ( ),
    .cfg_tx_pm_state                                ( ), 
    .cfg_rcb_status                                 ( cfg_rcb_status ),
   
    .cfg_obff_enable                                ( cfg_obff_enable ),
    .cfg_pl_status_change                           ( cfg_pl_status_change ),

    .cfg_tph_requester_enable                       ( ),
    .cfg_tph_st_mode                                ( ),
    .cfg_vf_tph_requester_enable                    ( ),
    .cfg_vf_tph_st_mode                             ( ),
    // Management Interface
    .cfg_mgmt_addr                                  ( cfg_mgmt_addr ),
    .cfg_mgmt_write                                 ( cfg_mgmt_write ),
    .cfg_mgmt_write_data                            ( cfg_mgmt_write_data ),
    .cfg_mgmt_byte_enable                           ( cfg_mgmt_byte_enable ),
    .cfg_mgmt_read                                  ( cfg_mgmt_read ),
    .cfg_mgmt_read_data                             ( cfg_mgmt_read_data ),
    .cfg_mgmt_read_write_done                       ( cfg_mgmt_read_write_done ),
    .cfg_mgmt_debug_access                          (1'b0),
    .cfg_mgmt_function_number                       (8'b0),
    .cfg_pm_aspm_l1_entry_reject                    (1'b0),
    .cfg_pm_aspm_tx_l0s_entry_disable               (1'b1),

    .cfg_msg_received                               ( cfg_msg_received ),
    .cfg_msg_received_data                          ( cfg_msg_received_data ),
    .cfg_msg_received_type                          ( cfg_msg_received_type ),

    .cfg_msg_transmit                               ( cfg_msg_transmit ),
    .cfg_msg_transmit_type                          ( cfg_msg_transmit_type ),
    .cfg_msg_transmit_data                          ( cfg_msg_transmit_data ),
    .cfg_msg_transmit_done                          ( cfg_msg_transmit_done ),

    .cfg_fc_ph                                      ( cfg_fc_ph ),
    .cfg_fc_pd                                      ( cfg_fc_pd ),
    .cfg_fc_nph                                     ( cfg_fc_nph ),
    .cfg_fc_npd                                     ( cfg_fc_npd ),
    .cfg_fc_cplh                                    ( cfg_fc_cplh ),
    .cfg_fc_cpld                                    ( cfg_fc_cpld ),
    .cfg_fc_sel                                     ( cfg_fc_sel ),

    //-------------------------------------------------------------------------------//
    // EP and RP                                                                     //
    //-------------------------------------------------------------------------------//
    .cfg_bus_number                                 ( ), 
    .cfg_dsn                                        ( cfg_dsn ),
    .cfg_power_state_change_ack                     ( cfg_power_state_change_ack ),
    .cfg_power_state_change_interrupt               ( cfg_power_state_change_interrupt ),
    .cfg_err_cor_in                                 ( cfg_err_cor_in ),
    .cfg_err_uncor_in                               ( cfg_err_uncor_in ),

    .cfg_flr_in_process                             ( cfg_flr_in_process ),
    .cfg_flr_done                                   ( {2'b0,cfg_flr_done} ),
    .cfg_vf_flr_in_process                          ( cfg_vf_flr_in_process ),
    .cfg_vf_flr_done                                ( cfg_vf_flr_done ),
    .cfg_link_training_enable                       ( cfg_link_training_enable ),
  // EP only
    .cfg_hot_reset_out                              ( cfg_hot_reset_out ),
    .cfg_config_space_enable                        ( cfg_config_space_enable ),
    .cfg_req_pm_transition_l23_ready                ( cfg_req_pm_transition_l23_ready ),

  // RP only
    .cfg_hot_reset_in                               ( cfg_hot_reset_in ),

    .cfg_ds_bus_number                              ( cfg_ds_bus_number ),
    .cfg_ds_device_number                           ( cfg_ds_device_number ),
    .cfg_ds_port_number                             ( cfg_ds_port_number ),
    .cfg_vf_flr_func_num                            (cfg_vf_flr_func_num),

    //-------------------------------------------------------------------------------//
    // EP Only                                                                       //
    //-------------------------------------------------------------------------------//

    // Interrupt Interface Signals
    .cfg_interrupt_int                              ( cfg_interrupt_int ),
    .cfg_interrupt_pending                          ( {2'b0,cfg_interrupt_pending} ),
    .cfg_interrupt_sent                             ( cfg_interrupt_sent ),



    


    //--------------------------------------------------------------------------------------//
    //  System(SYS) Interface                                                               //
    //--------------------------------------------------------------------------------------//

    .sys_clk                                        ( sys_clk ),
    .sys_clk_gt                                     ( sys_clk_gt ),
    .sys_reset                                      ( sys_rst_n_c )
  );

//------------------------------------------------------------------------------------------------------------------//
//                                      PIO Example Design Top Level                                                //
//------------------------------------------------------------------------------------------------------------------//
  pcie_app_uscale pcie_app_uscale_i (
    .user_clk                                       ( user_clk ),
    .user_reset                                     ( user_reset ),
    .user_lnk_up                                    ( user_lnk_up ),
    .sys_rst                                        ( !sys_rst_n_c ),

    
    //-------------------------------------------------------------------------------------//
    //  AXI Interface                                                                      //
    //-------------------------------------------------------------------------------------//

    .s_axis_rq_tlast                                ( s_axis_rq_tlast ),
    .s_axis_rq_tdata                                ( s_axis_rq_tdata ),
    .s_axis_rq_tuser                                ( s_axis_rq_tuser ),
    .s_axis_rq_tkeep                                ( s_axis_rq_tkeep ),
    .s_axis_rq_tready                               ( s_axis_rq_tready[0] ),
    .s_axis_rq_tvalid                               ( s_axis_rq_tvalid ),

    .m_axis_rc_tdata                                ( m_axis_rc_tdata ),
    .m_axis_rc_tuser                                ( m_axis_rc_tuser ),
    .m_axis_rc_tlast                                ( m_axis_rc_tlast ),
    .m_axis_rc_tkeep                                ( m_axis_rc_tkeep ),
    .m_axis_rc_tvalid                               ( m_axis_rc_tvalid ),
    .m_axis_rc_tready                               ( m_axis_rc_tready ),

    .m_axis_cq_tdata                                ( m_axis_cq_tdata ),
    .m_axis_cq_tuser                                ( m_axis_cq_tuser ),
    .m_axis_cq_tlast                                ( m_axis_cq_tlast ),
    .m_axis_cq_tkeep                                ( m_axis_cq_tkeep ),
    .m_axis_cq_tvalid                               ( m_axis_cq_tvalid ),
    .m_axis_cq_tready                               ( m_axis_cq_tready ),

    .s_axis_cc_tdata                                ( s_axis_cc_tdata ),
    .s_axis_cc_tuser                                ( s_axis_cc_tuser ),
    .s_axis_cc_tlast                                ( s_axis_cc_tlast ),
    .s_axis_cc_tkeep                                ( s_axis_cc_tkeep ),
    .s_axis_cc_tvalid                               ( s_axis_cc_tvalid ),
    .s_axis_cc_tready                               ( s_axis_cc_tready[0] ),

   
    .pcie_rq_seq_num                                ( 'h0),
    .pcie_rq_seq_num_vld                            ( 'h0),
    .pcie_rq_tag                                    ( 'h0),
    .pcie_rq_tag_vld                                ( 'h0),
    .pcie_tfc_nph_av                                ( pcie_tfc_nph_av[1:0]),
    .pcie_tfc_npd_av                                ( pcie_tfc_npd_av[1:0]),
    .pcie_cq_np_req                                 ( pcie_cq_np_req ),
    .pcie_cq_np_req_count                           ( pcie_cq_np_req_count ),

    //--------------------------------------------------------------------------------//
    //  Configuration (CFG) Interface                                                 //
    //--------------------------------------------------------------------------------//

    //--------------------------------------------------------------------------------//
    // EP and RP                                                                      //
    //--------------------------------------------------------------------------------//
    .cfg_phy_link_down                              ( cfg_phy_link_down ),
    .cfg_negotiated_width                           ( cfg_negotiated_width ),
    .cfg_current_speed                              ( cfg_current_speed ),
    .cfg_max_payload                                ( cfg_max_payload ),
    .cfg_max_read_req                               ( cfg_max_read_req ),
    .cfg_function_status                            ( cfg_function_status [7:0] ),
    .cfg_function_power_state                       ( cfg_function_power_state [5:0] ),
    .cfg_vf_status                                  ( cfg_vf_status ),
    .cfg_link_power_state                           ( cfg_link_power_state ),

    // Error Reporting Interface
    .cfg_err_cor_out                                ( cfg_err_cor_out ),
    .cfg_err_nonfatal_out                           ( cfg_err_nonfatal_out ),
    .cfg_err_fatal_out                              ( cfg_err_fatal_out ),
    .cfg_ltr_enable                                 ( 1'b0  ),
    .cfg_ltssm_state                                ( cfg_ltssm_state ),
    .cfg_rcb_status                                 ( cfg_rcb_status [1:0]),
    .cfg_obff_enable                                ( cfg_obff_enable ),
    .cfg_pl_status_change                           ( cfg_pl_status_change ),

    // Management Interface
    .cfg_mgmt_addr                                  ( cfg_mgmt_addr ),
    .cfg_mgmt_write                                 ( cfg_mgmt_write ),
    .cfg_mgmt_write_data                            ( cfg_mgmt_write_data ),
    .cfg_mgmt_byte_enable                           ( cfg_mgmt_byte_enable ),
    .cfg_mgmt_read                                  ( cfg_mgmt_read ),
    .cfg_mgmt_read_data                             ( cfg_mgmt_read_data ),
    .cfg_mgmt_read_write_done                       ( cfg_mgmt_read_write_done ),
    .cfg_mgmt_type1_cfg_reg_access                  ( cfg_mgmt_type1_cfg_reg_access ),
    .cfg_msg_received                               ( cfg_msg_received ),
    .cfg_msg_received_data                          ( cfg_msg_received_data ),
    .cfg_msg_received_type                          ( cfg_msg_received_type ),
    .cfg_msg_transmit                               ( cfg_msg_transmit ),
    .cfg_msg_transmit_type                          ( cfg_msg_transmit_type ),
    .cfg_msg_transmit_data                          ( cfg_msg_transmit_data ),
    .cfg_msg_transmit_done                          ( cfg_msg_transmit_done ),

    .cfg_fc_ph                                      ( cfg_fc_ph ),
    .cfg_fc_pd                                      ( cfg_fc_pd ),
    .cfg_fc_nph                                     ( cfg_fc_nph ),
    .cfg_fc_npd                                     ( cfg_fc_npd ),
    .cfg_fc_cplh                                    ( cfg_fc_cplh ),
    .cfg_fc_cpld                                    ( cfg_fc_cpld ),
    .cfg_fc_sel                                     ( cfg_fc_sel ),

    .cfg_per_func_status_control                    ( cfg_per_func_status_control ),
    .cfg_per_function_number                        ( cfg_per_function_number ),
    .cfg_per_function_output_request                ( cfg_per_function_output_request ),

    .cfg_dsn                                        ( cfg_dsn ),
    .cfg_power_state_change_ack                     ( cfg_power_state_change_ack ),
    .cfg_power_state_change_interrupt               ( cfg_power_state_change_interrupt ),
    .cfg_err_cor_in                                 ( cfg_err_cor_in ),
    .cfg_err_uncor_in                               ( cfg_err_uncor_in ),

    .cfg_flr_in_process                             ( cfg_flr_in_process [1:0] ),
    .cfg_flr_done                                   ( cfg_flr_done ),
    .cfg_vf_flr_in_process                          ( cfg_vf_flr_in_process ),
    .cfg_vf_flr_done                                ( cfg_vf_flr_done ),
    .cfg_vf_flr_func_num                            ( cfg_vf_flr_func_num ),

    .cfg_link_training_enable                       ( cfg_link_training_enable ),

    .cfg_ds_port_number                             ( cfg_ds_port_number ),
    .cfg_hot_reset_in                               ( cfg_hot_reset_out ),
    .cfg_config_space_enable                        ( cfg_config_space_enable ),
    .cfg_req_pm_transition_l23_ready                ( cfg_req_pm_transition_l23_ready ),

  // RP only
    .cfg_hot_reset_out                              ( cfg_hot_reset_in ),

    .cfg_ds_bus_number                              ( cfg_ds_bus_number ),
    .cfg_ds_device_number                           ( cfg_ds_device_number ),
    .cfg_ds_function_number                         ( ),

    //-------------------------------------------------------------------------------------//
    // EP Only                                                                             //
    //-------------------------------------------------------------------------------------//

    .cfg_interrupt_msi_enable                       ( 1'b0 ),
    .cfg_interrupt_msi_mmenable                     ( 6'b0 ),
    .cfg_interrupt_msi_mask_update                  ( 1'b0 ),
    .cfg_interrupt_msi_data                         ( 32'b0 ),
    .cfg_interrupt_msi_select                       ( ),
    .cfg_interrupt_msi_int                          ( ),
    .cfg_interrupt_msi_pending_status               ( ),
    .cfg_interrupt_msi_sent                         ( 1'b0 ),
    .cfg_interrupt_msi_fail                         ( 1'b0 ),
    .cfg_interrupt_msi_attr                         ( ),
    .cfg_interrupt_msi_tph_present                  ( ),
    .cfg_interrupt_msi_tph_type                     ( ),
    .cfg_interrupt_msi_tph_st_tag                   ( ),
    .cfg_interrupt_msi_function_number              ( cfg_interrupt_msi_function_number ),
 
    // Interrupt Interface Signals
    .cfg_interrupt_int                              ( cfg_interrupt_int ),
    .cfg_interrupt_pending                          ( cfg_interrupt_pending ),
    .cfg_interrupt_sent                             ( cfg_interrupt_sent )
  );

endmodule
