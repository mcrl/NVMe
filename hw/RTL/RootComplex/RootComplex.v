// PCIE Root Complex module

module RootComplex #(
  parameter   PCIE_LINK_WIDTH   = 1   // 1 - x1
) (
  // System Interface
  input   wire  sys_clk,
  input   wire  sys_reset,

  // PCIe serial Interface
  output  wire  [PCIE_LINK_WIDTH-1:0]   pci_exp_txp,
  output  wire  [PCIE_LINK_WIDTH-1:0]   pci_exp_txn,
  input   wire  [PCIE_LINK_WIDTH-1:0]   pci_exp_rxp,
  input   wire  [PCIE_LINK_WIDTH-1:0]   pci_exp_rxn
);


  // ------------------------
  // Wires and Regs
  // ------------------------

  // User Interface
  wire user_clk;
  wire user_reset;
  wire user_lnk_up;
  
  // Configuration Management
  wire  [9:0]   cfg_mgmt_addr;
  wire  [7:0]   cfg_mgmt_function_number;
  wire          cfg_mgmt_write;
  wire  [31:0]  cfg_mgmt_write_data;
  wire  [3:0]   cfg_mgmt_byte_enable;
  wire          cfg_mgmt_read;
  wire  [31:0]  cfg_mgmt_read_data;
  wire          cfg_mgmt_read_write_done;
  wire          cfg_mgmt_debug_access;
  
  // PCIe Controller -> CFG signals
  wire          ctr2cfg_mgmt_write;
  wire          ctr2cfg_mgmt_read;
  wire  [31:0]  ctr2cfg_mgmt_addr;
  wire  [31:0]  ctr2cfg_mgmt_write_data;
  wire  [3:0]   ctr2cfg_mgmt_byte_enable;

  // CFG -> PCIe Controller signals
  wire  [31:0]  cfg2ctr_mgmt_read_data;
  wire          cfg2ctr_mgmt_write_done;
  wire          cfg2ctr_mgmt_read_done;

  // Controller -> TX
  wire          ctr2tx_type0_cfg_read;
  wire  [7:0]   ctr2tx_type0_cfg_read_tag;
  wire  [11:0]  ctr2tx_type0_cfg_read_reg_addr;
  wire  [3:0]   ctr2tx_type0_cfg_read_first_dw_be;

  // TX -> Controller
  wire          tx2ctr_type0_cfg_read_done;

  /*
  // AXI-Stream Interface
  wire  [63:0]  s_axis_rq_tdata;
  wire  [1:0]   s_axis_rq_tkeep;
  wire          s_axis_rq_tlast;
  wire  [3:0]   s_axis_rq_tready;
  wire  [61:0]  s_axis_rq_tuser;
  wire          s_axis_rq_tvalid;
  
  wire  [63:0]  m_axis_rc_tdata;
  wire  [1:0]   m_axis_rc_tkeep;
  wire          m_axis_rc_tlast;
  wire  [3:0]   m_axis_rc_tready;
  wire  [61:0]  m_axis_rc_tuser;
  wire          m_axis_rc_tvalid;
 
  wire  [63:0]  m_axis_cq_tdata;
  wire  [1:0]   m_axis_cq_tkeep;
  wire          m_axis_cq_tlast;
  wire  [3:0]   m_axis_cq_tready;
  wire  [61:0]  m_axis_cq_tuser;
  wire          m_axis_cq_tvalid;
  
  wire  [63:0]  s_axis_cc_tdata;
  wire  [1:0]   s_axis_cc_tkeep;
  wire          s_axis_cc_tlast;
  wire  [3:0]   s_axis_cc_tready;
  wire  [61:0]  s_axis_cc_tuser;
  wire          s_axis_cc_tvalid;
*/


  // ------------------------
  // PCIe RootComplex IP
  // ------------------------
  
  pcie4_rc pcie_rc_inst (
    // PCIe Serial
    .pci_exp_txn(pci_exp_txn),                                            // output wire [0 : 0] pci_exp_txn
    .pci_exp_txp(pci_exp_txp),                                            // output wire [0 : 0] pci_exp_txp
    .pci_exp_rxn(pci_exp_rxn),                                            // input wire [0 : 0] pci_exp_rxn
    .pci_exp_rxp(pci_exp_rxp),                                            // input wire [0 : 0] pci_exp_rxp
    
    // System Interface
    .sys_clk(sys_clk),                                                    // input wire sys_clk
    .sys_clk_gt(sys_clk),                                                 // input wire sys_clk_gt
    .sys_reset(sys_reset),                                               // input wire sys_reset
   
    // User Interface
    .user_clk(user_clk),                                                  // output wire user_clk
    .user_reset(user_reset),                                              // output wire user_reset
    .user_lnk_up(user_lnk_up),                                            // output wire user_lnk_up
    
    // AXI-Steram Interface
    // PCIe Requester reQuester
    .s_axis_rq_tdata(s_axis_rq_tdata),                                    // input wire [63 : 0] s_axis_rq_tdata
    .s_axis_rq_tkeep(s_axis_rq_tkeep),                                    // input wire [1 : 0] s_axis_rq_tkeep
    .s_axis_rq_tlast(s_axis_rq_tlast),                                    // input wire s_axis_rq_tlast
    .s_axis_rq_tready(s_axis_rq_tready),                                  // output wire [3 : 0] s_axis_rq_tready
    .s_axis_rq_tuser(s_axis_rq_tuser),                                    // input wire [61 : 0] s_axis_rq_tuser
    .s_axis_rq_tvalid(s_axis_rq_tvalid),                                  // input wire s_axis_rq_tvalid
    
    // PCIe Requester Completion
    .m_axis_rc_tdata(m_axis_rc_tdata),                                    // output wire [63 : 0] m_axis_rc_tdata
    .m_axis_rc_tkeep(m_axis_rc_tkeep),                                    // output wire [1 : 0] m_axis_rc_tkeep
    .m_axis_rc_tlast(m_axis_rc_tlast),                                    // output wire m_axis_rc_tlast
    .m_axis_rc_tready(m_axis_rc_tready),                                  // input wire m_axis_rc_tready
    .m_axis_rc_tuser(m_axis_rc_tuser),                                    // output wire [74 : 0] m_axis_rc_tuser
    .m_axis_rc_tvalid(m_axis_rc_tvalid),                                  // output wire m_axis_rc_tvalid
    
    // PCIe Completer reQuester 
    .m_axis_cq_tdata(m_axis_cq_tdata),                                    // output wire [63 : 0] m_axis_cq_tdata
    .m_axis_cq_tkeep(m_axis_cq_tkeep),                                    // output wire [1 : 0] m_axis_cq_tkeep
    .m_axis_cq_tlast(m_axis_cq_tlast),                                    // output wire m_axis_cq_tlast
    .m_axis_cq_tready(m_axis_cq_tready),                                  // input wire m_axis_cq_tready
    .m_axis_cq_tuser(m_axis_cq_tuser),                                    // output wire [87 : 0] m_axis_cq_tuser
    .m_axis_cq_tvalid(m_axis_cq_tvalid),                                  // output wire m_axis_cq_tvalid
    
    // PCIe Completer Completion
    .s_axis_cc_tdata(s_axis_cc_tdata),                                    // input wire [63 : 0] s_axis_cc_tdata
    .s_axis_cc_tkeep(s_axis_cc_tkeep),                                    // input wire [1 : 0] s_axis_cc_tkeep
    .s_axis_cc_tlast(s_axis_cc_tlast),                                    // input wire s_axis_cc_tlast
    .s_axis_cc_tready(s_axis_cc_tready),                                  // output wire [3 : 0] s_axis_cc_tready
    .s_axis_cc_tuser(s_axis_cc_tuser),                                    // input wire [32 : 0] s_axis_cc_tuser
    .s_axis_cc_tvalid(s_axis_cc_tvalid),                                  // input wire s_axis_cc_tvalid

    // PCIe Configuration Management
    .cfg_mgmt_addr(cfg_mgmt_addr),                                        // input wire [9 : 0] cfg_mgmt_addr
    .cfg_mgmt_function_number(cfg_mgmt_function_number),                  // input wire [7 : 0] cfg_mgmt_function_number
    .cfg_mgmt_write(cfg_mgmt_write),                                      // input wire cfg_mgmt_write
    .cfg_mgmt_write_data(cfg_mgmt_write_data),                            // input wire [31 : 0] cfg_mgmt_write_data
    .cfg_mgmt_byte_enable(cfg_mgmt_byte_enable),                          // input wire [3 : 0] cfg_mgmt_byte_enable
    .cfg_mgmt_read(cfg_mgmt_read),                                        // input wire cfg_mgmt_read
    .cfg_mgmt_read_data(cfg_mgmt_read_data),                              // output wire [31 : 0] cfg_mgmt_read_data
    .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),                  // output wire cfg_mgmt_read_write_done
    .cfg_mgmt_debug_access(cfg_mgmt_debug_access),                        // input wire cfg_mgmt_debug_access
    
    // PCIe Status signals
    .pcie_rq_seq_num0(pcie_rq_seq_num0),                                  // output wire [5 : 0] pcie_rq_seq_num0
    .pcie_rq_seq_num_vld0(pcie_rq_seq_num_vld0),                          // output wire pcie_rq_seq_num_vld0
    .pcie_rq_seq_num1(pcie_rq_seq_num1),                                  // output wire [5 : 0] pcie_rq_seq_num1
    .pcie_rq_seq_num_vld1(pcie_rq_seq_num_vld1),                          // output wire pcie_rq_seq_num_vld1
    .pcie_rq_tag0(pcie_rq_tag0),                                          // output wire [7 : 0] pcie_rq_tag0
    .pcie_rq_tag1(pcie_rq_tag1),                                          // output wire [7 : 0] pcie_rq_tag1
    .pcie_rq_tag_av(pcie_rq_tag_av),                                      // output wire [3 : 0] pcie_rq_tag_av
    .pcie_rq_tag_vld0(pcie_rq_tag_vld0),                                  // output wire pcie_rq_tag_vld0
    .pcie_rq_tag_vld1(pcie_rq_tag_vld1),                                  // output wire pcie_rq_tag_vld1
    .pcie_tfc_nph_av(pcie_tfc_nph_av),                                    // output wire [3 : 0] pcie_tfc_nph_av
    .pcie_tfc_npd_av(pcie_tfc_npd_av),                                    // output wire [3 : 0] pcie_tfc_npd_av
    .pcie_cq_np_req(pcie_cq_np_req),                                      // input wire [1 : 0] pcie_cq_np_req
    .pcie_cq_np_req_count(pcie_cq_np_req_count),                          // output wire [5 : 0] pcie_cq_np_req_count
    .cfg_phy_link_down(cfg_phy_link_down),                                // output wire cfg_phy_link_down
    .cfg_phy_link_status(cfg_phy_link_status),                            // output wire [1 : 0] cfg_phy_link_status
    .cfg_negotiated_width(cfg_negotiated_width),                          // output wire [2 : 0] cfg_negotiated_width
    .cfg_current_speed(cfg_current_speed),                                // output wire [1 : 0] cfg_current_speed
    .cfg_max_payload(cfg_max_payload),                                    // output wire [1 : 0] cfg_max_payload
    .cfg_max_read_req(cfg_max_read_req),                                  // output wire [2 : 0] cfg_max_read_req
    .cfg_function_status(cfg_function_status),                            // output wire [15 : 0] cfg_function_status
    .cfg_function_power_state(cfg_function_power_state),                  // output wire [11 : 0] cfg_function_power_state
    .cfg_vf_status(cfg_vf_status),                                        // output wire [503 : 0] cfg_vf_status
    .cfg_vf_power_state(cfg_vf_power_state),                              // output wire [755 : 0] cfg_vf_power_state
    .cfg_link_power_state(cfg_link_power_state),                          // output wire [1 : 0] cfg_link_power_state
    .cfg_err_cor_out(cfg_err_cor_out),                                    // output wire cfg_err_cor_out
    .cfg_err_nonfatal_out(cfg_err_nonfatal_out),                          // output wire cfg_err_nonfatal_out
    .cfg_err_fatal_out(cfg_err_fatal_out),                                // output wire cfg_err_fatal_out
    .cfg_local_error_valid(cfg_local_error_valid),                        // output wire cfg_local_error_valid
    .cfg_local_error_out(cfg_local_error_out),                            // output wire [4 : 0] cfg_local_error_out
    .cfg_ltssm_state(cfg_ltssm_state),                                    // output wire [5 : 0] cfg_ltssm_state
    .cfg_rx_pm_state(cfg_rx_pm_state),                                    // output wire [1 : 0] cfg_rx_pm_state
    .cfg_tx_pm_state(cfg_tx_pm_state),                                    // output wire [1 : 0] cfg_tx_pm_state
    .cfg_rcb_status(cfg_rcb_status),                                      // output wire [3 : 0] cfg_rcb_status
    .cfg_obff_enable(cfg_obff_enable),                                    // output wire [1 : 0] cfg_obff_enable
    .cfg_pl_status_change(cfg_pl_status_change),                          // output wire cfg_pl_status_change
    .cfg_tph_requester_enable(cfg_tph_requester_enable),                  // output wire [3 : 0] cfg_tph_requester_enable
    .cfg_tph_st_mode(cfg_tph_st_mode),                                    // output wire [11 : 0] cfg_tph_st_mode
    .cfg_vf_tph_requester_enable(cfg_vf_tph_requester_enable),            // output wire [251 : 0] cfg_vf_tph_requester_enable
    .cfg_vf_tph_st_mode(cfg_vf_tph_st_mode),                              // output wire [755 : 0] cfg_vf_tph_st_mode
    .cfg_msg_received(cfg_msg_received),                                  // output wire cfg_msg_received
    .cfg_msg_received_data(cfg_msg_received_data),                        // output wire [7 : 0] cfg_msg_received_data
    .cfg_msg_received_type(cfg_msg_received_type),                        // output wire [4 : 0] cfg_msg_received_type
    .cfg_msg_transmit(cfg_msg_transmit),                                  // input wire cfg_msg_transmit
    .cfg_msg_transmit_type(cfg_msg_transmit_type),                        // input wire [2 : 0] cfg_msg_transmit_type
    .cfg_msg_transmit_data(cfg_msg_transmit_data),                        // input wire [31 : 0] cfg_msg_transmit_data
    .cfg_msg_transmit_done(cfg_msg_transmit_done),                        // output wire cfg_msg_transmit_done
    .cfg_fc_ph(cfg_fc_ph),                                                // output wire [7 : 0] cfg_fc_ph
    .cfg_fc_pd(cfg_fc_pd),                                                // output wire [11 : 0] cfg_fc_pd
    .cfg_fc_nph(cfg_fc_nph),                                              // output wire [7 : 0] cfg_fc_nph
    .cfg_fc_npd(cfg_fc_npd),                                              // output wire [11 : 0] cfg_fc_npd
    .cfg_fc_cplh(cfg_fc_cplh),                                            // output wire [7 : 0] cfg_fc_cplh
    .cfg_fc_cpld(cfg_fc_cpld),                                            // output wire [11 : 0] cfg_fc_cpld
    .cfg_fc_sel(cfg_fc_sel),                                              // input wire [2 : 0] cfg_fc_sel
    .cfg_dsn(cfg_dsn),                                                    // input wire [63 : 0] cfg_dsn
    .cfg_bus_number(cfg_bus_number),                                      // output wire [7 : 0] cfg_bus_number
    .cfg_power_state_change_ack(cfg_power_state_change_ack),              // input wire cfg_power_state_change_ack
    .cfg_power_state_change_interrupt(cfg_power_state_change_interrupt),  // output wire cfg_power_state_change_interrupt
    .cfg_err_cor_in(cfg_err_cor_in),                                      // input wire cfg_err_cor_in
    .cfg_err_uncor_in(cfg_err_uncor_in),                                  // input wire cfg_err_uncor_in
    .cfg_flr_in_process(cfg_flr_in_process),                              // output wire [3 : 0] cfg_flr_in_process
    .cfg_flr_done(cfg_flr_done),                                          // input wire [3 : 0] cfg_flr_done
    .cfg_vf_flr_in_process(cfg_vf_flr_in_process),                        // output wire [251 : 0] cfg_vf_flr_in_process
    .cfg_vf_flr_func_num(cfg_vf_flr_func_num),                            // input wire [7 : 0] cfg_vf_flr_func_num
    .cfg_vf_flr_done(cfg_vf_flr_done),                                    // input wire [0 : 0] cfg_vf_flr_done
    .cfg_link_training_enable(ctr2cfg_link_training_enable),              // input wire cfg_link_training_enable
    .cfg_interrupt_int(cfg_interrupt_int),                                // input wire [3 : 0] cfg_interrupt_int
    .cfg_interrupt_pending(cfg_interrupt_pending),                        // input wire [3 : 0] cfg_interrupt_pending
    .cfg_interrupt_sent(cfg_interrupt_sent),                              // output wire cfg_interrupt_sent
    .cfg_pm_aspm_l1_entry_reject(cfg_pm_aspm_l1_entry_reject),            // input wire cfg_pm_aspm_l1_entry_reject
    .cfg_pm_aspm_tx_l0s_entry_disable(cfg_pm_aspm_tx_l0s_entry_disable),  // input wire cfg_pm_aspm_tx_l0s_entry_disable
    .cfg_hot_reset_out(cfg_hot_reset_out),                                // output wire cfg_hot_reset_out
    .cfg_config_space_enable(cfg_config_space_enable),                    // input wire cfg_config_space_enable
    .cfg_req_pm_transition_l23_ready(cfg_req_pm_transition_l23_ready),    // input wire cfg_req_pm_transition_l23_ready
    .cfg_hot_reset_in(cfg_hot_reset_in),                                  // input wire cfg_hot_reset_in
    .cfg_ds_port_number(cfg_ds_port_number),                              // input wire [7 : 0] cfg_ds_port_number
    .cfg_ds_bus_number(cfg_ds_bus_number),                                // input wire [7 : 0] cfg_ds_bus_number
    .cfg_ds_device_number(cfg_ds_device_number),                          // input wire [4 : 0] cfg_ds_device_number
    .phy_rdy_out(phy_rdy_out)                                             // output wire phy_rdy_out
  );

  pcie_controller pcie_controller_inst(
    // User Interface
    .user_clk(user_clk),                                                  // input  wire user_clk
    .user_reset(user_reset),                                              // input  wire user_reset
    .user_lnk_up(user_lnk_up),                                            // input  wire user_lnk_up

    // Controller -> CFG
    .ctr2cfg_mgmt_addr(ctr2cfg_mgmt_addr),                                    // output wire [9 : 0] cfg_mgmt_addr
    .ctr2cfg_mgmt_function_number(ctr2cfg_mgmt_function_number),              // output wire [7 : 0] cfg_mgmt_function_number
    .ctr2cfg_mgmt_write(ctr2cfg_mgmt_write),                                  // output wire cfg_mgmt_write
    .ctr2cfg_mgmt_write_data(ctr2cfg_mgmt_write_data),                        // output wire [31 : 0] cfg_mgmt_write_data
    .ctr2cfg_mgmt_byte_enable(ctr2cfg_mgmt_byte_enable),                      // output wire [3 : 0] cfg_mgmt_byte_enable
    .ctr2cfg_mgmt_read(ctr2cfg_mgmt_read),                                    // output wire cfg_mgmt_read
    .ctr2cfg_mgmt_debug_access(ctr2cfg_mgmt_debug_access),                    // output wire cfg_mgmt_debug_access

    // CFG -> Controller
    .cfg2ctr_mgmt_read_data(cfg2ctr_mgmt_read_data),                      // input wire [31:0] cfg2ctr_mgmt_read_data
    .cfg2ctr_mgmt_write_done(cfg2ctr_mgmt_write_done),                    // input wire cfg2ctr_mgmt_write_done
    .cfg2ctr_mgmt_read_done(cfg2ctr_mgmt_read_done),                      // input wire cfg2ctr_mgmt_read_done

    // Controller -> TX
    .ctr2tx_type0_cfg_read(ctr2tx_type0_cfg_read),
    .ctr2tx_type0_cfg_read_tag(ctr2tx_type0_cfg_read_tag),
    .ctr2tx_type0_cfg_read_reg_addr(ctr2tx_type0_cfg_read_reg_addr),
    .ctr2tx_type0_cfg_read_first_dw_be(ctr2tx_type0_cfg_read_first_dw_be)
  );

  cfg cfg_inst(
    // User Interface
    .user_clk(user_clk),                                                  // input wire user_clk
    .user_reset(user_reset),                                              // input wire user_reset
    .user_lnk_up(user_lnk_up),                                            // input wire user_lnk_up

    // Controller -> CFG
    .ctr2cfg_mgmt_addr(ctr2cfg_mgmt_addr),                                // input wire [9 : 0] cfg_mgmt_addr
    .ctr2cfg_mgmt_function_number(ctr2cfg_mgmt_function_number),          // input wire [7 : 0] cfg_mgmt_function_number
    .ctr2cfg_mgmt_write(ctr2cfg_mgmt_write),                              // input wire cfg_mgmt_write
    .ctr2cfg_mgmt_write_data(ctr2cfg_mgmt_write_data),                    // input wire [31 : 0] cfg_mgmt_write_data
    .ctr2cfg_mgmt_byte_enable(ctr2cfg_mgmt_byte_enable),                  // input wire [3 : 0] cfg_mgmt_byte_enable
    .ctr2cfg_mgmt_read(ctr2cfg_mgmt_read),                                // input wire cfg_mgmt_read
    .ctr2cfg_mgmt_debug_access(ctr2cfg_mgmt_debug_access),                // input wire cfg_mgmt_debug_access

    // CFG -> Controller
    .cfg2ctr_mgmt_write_done(cfg2ctr_mgmt_write_done),                    // output reg cfg2ctr_mgmt_write_done
    .cfg2ctr_mgmt_read_done(cfg2ctr_mgmt_read_done),                      // output reg cfg2ctr_mgmt_read_done
    .cfg2ctr_mgmt_read_data(cfg2ctr_mgmt_read_data),                      // output reg [31:0] cfg2ctr_mgmt_read_data

    // PCIe Configuration Management (CFG -> PCIe IP)
    .cfg_mgmt_addr(cfg_mgmt_addr),                                        // output wire [9 : 0] cfg_mgmt_addr
    .cfg_mgmt_function_number(cfg_mgmt_function_number),                  // output wire [7 : 0] cfg_mgmt_function_number
    .cfg_mgmt_write(cfg_mgmt_write),                                      // output wire cfg_mgmt_write
    .cfg_mgmt_write_data(cfg_mgmt_write_data),                            // output wire [31 : 0] cfg_mgmt_write_data
    .cfg_mgmt_byte_enable(cfg_mgmt_byte_enable),                          // output wire [3 : 0] cfg_mgmt_byte_enable
    .cfg_mgmt_read(cfg_mgmt_read),                                        // output wire cfg_mgmt_read
    .cfg_mgmt_read_data(cfg_mgmt_read_data),                              // input  wire [31 : 0] cfg_mgmt_read_data
    .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),                  // input  wire cfg_mgmt_read_write_done
    .cfg_mgmt_debug_access(cfg_mgmt_debug_access)                         // output wire cfg_mgmt_debug_access
  );


  pcie_tx pcie_tx_inst(
    // User Interface
    .user_clk(user_clk),                                                  // input  wire user_clk
    .user_reset(user_reset),                                              // input  wire user_reset
    .user_lnk_up(user_lnk_up),                                            // input  wire user_lnk_up
    
    // AXI-Steram Interface
    // PCIe Requester reQuester
    .s_axis_rq_tdata(s_axis_rq_tdata),                                    // input wire [63 : 0] s_axis_rq_tdata
    .s_axis_rq_tkeep(s_axis_rq_tkeep),                                    // input wire [1 : 0] s_axis_rq_tkeep
    .s_axis_rq_tlast(s_axis_rq_tlast),                                    // input wire s_axis_rq_tlast
    .s_axis_rq_tready(s_axis_rq_tready),                                  // output wire [3 : 0] s_axis_rq_tready
    .s_axis_rq_tuser(s_axis_rq_tuser),                                    // input wire [61 : 0] s_axis_rq_tuser
    .s_axis_rq_tvalid(s_axis_rq_tvalid),                                  // input wire s_axis_rq_tvalid

    // TX -> Controller
    .tx2ctr_type0_cfg_read_done(tx2ctr_type0_cfg_read_done)               // output reg tx2ctr_type0_cfg_read_done
  );


  pcie_rx pcie_rx_inst(
    // User Interface
    .user_clk(user_clk),                                                  // input  wire user_clk
    .user_reset(user_reset),                                              // input  wire user_reset
    .user_lnk_up(user_lnk_up),                                            // input  wire user_lnk_up
    
    // AXI-Steram Interface
    // PCIe Requester reQuester
    .m_axis_rc_tdata(m_axis_rc_tdata),                                    // input wire [63 : 0] m_axis_rc_tdata
    .m_axis_rc_tkeep(m_axis_rc_tkeep),                                    // input wire [1 : 0] m_axis_rc_tkeep
    .m_axis_rc_tlast(m_axis_rc_tlast),                                    // input wire m_axis_rc_tlast
    .m_axis_rc_tready(m_axis_rc_tready),                                  // output reg m_axis_rc_tready
    .m_axis_rc_tuser(m_axis_rc_tuser),                                    // input wire [74 : 0] m_axis_rc_tuser
    .m_axis_rc_tvalid(m_axis_rc_tvalid)                                   // input wire m_axis_rc_tvalid
  );


endmodule
