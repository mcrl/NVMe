`timescale 1ps / 1ps

module oculink_port # (
  // PCIe Parameters
  parameter           PCIE_EXT_CLK                      = "FALSE",
  parameter           EXT_PIPE_SIM                      = "FALSE",                               
  parameter           PL_LINK_CAP_MAX_LINK_SPEED        = 4,  // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4
  parameter [4:0]     PL_LINK_CAP_MAX_LINK_WIDTH        = 4,  // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16
  parameter           PL_DISABLE_EI_INFER_IN_L0         = "TRUE",
  parameter           PL_DISABLE_UPCONFIG_CAPABLE       = "FALSE",
  parameter  integer  USER_CLK2_FREQ                    = 3,
  parameter           REF_CLK_FREQ                      = 0,  // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz

  // AXIS Parameters
  parameter           AXISTEN_IF_RQ_ALIGNMENT_MODE      = "FALSE",
  parameter           AXISTEN_IF_CC_ALIGNMENT_MODE      = "FALSE",
  parameter           AXISTEN_IF_CQ_ALIGNMENT_MODE      = "FALSE",
  parameter           AXISTEN_IF_RC_ALIGNMENT_MODE      = "FALSE",
  parameter           AXI4_CQ_TUSER_WIDTH               = 88,
  parameter           AXI4_CC_TUSER_WIDTH               = 33,
  parameter           AXI4_RQ_TUSER_WIDTH               = 62,
  parameter           AXI4_RC_TUSER_WIDTH               = 75,
  parameter           AXISTEN_IF_ENABLE_CLIENT_TAG      = "TRUE",
  parameter           AXISTEN_IF_RQ_PARITY_CHECK        = "FALSE",
  parameter           AXISTEN_IF_CC_PARITY_CHECK        = "FALSE",
  parameter           AXISTEN_IF_MC_RX_STRADDLE         = "FALSE",
  parameter           AXISTEN_IF_ENABLE_RX_MSG_INTFC    = "FALSE",
  parameter [17:0]    AXISTEN_IF_ENABLE_MSG_ROUTE       = 18'h2FFFF,
  parameter           C_DATA_WIDTH                      = 128,            
  parameter           KEEP_WIDTH                        = C_DATA_WIDTH / 32
)
(
  //-------------------------------------------------------
  // PCI Express (OcuLink) Interface 
  //-------------------------------------------------------

  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txp,
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txn,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxp,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxn,

  //-------------------------------------------------------
  // System Interface
  //-------------------------------------------------------

  input                                           sys_clk_p,    // OcuLink ref clock
  input                                           sys_clk_n,    // OcuLink ref clock
  output                                          perst_n,      // OcuLink reset 
  input                                           cprsnt,       // OcuLink reset
  input                                           sys_rst_n_c   // System reset
);
  
  // System clock generation
  wire sys_clk;
  wire sys_clk_gt;
  IBUFDS_GTE4 refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));


  //-------------------------------------------------------
  // System Interface
  //-------------------------------------------------------

  wire                                          user_clk;
  wire                                          user_reset;
  wire                                          user_lnk_up;
  wire                                          phy_rdy_out;

  //-------------------------------------------------------
  // Transaction (AXIS) Interface
  //-------------------------------------------------------

  wire                                [3:0]     s_axis_rq_tready;
  wire                   [C_DATA_WIDTH-1:0]     s_axis_rq_tdata;
  wire                     [KEEP_WIDTH-1:0]     s_axis_rq_tkeep;
  wire            [AXI4_RQ_TUSER_WIDTH-1:0]     s_axis_rq_tuser;
  wire                                          s_axis_rq_tlast;
  wire                                          s_axis_rq_tvalid;
  
  wire                   [C_DATA_WIDTH-1:0]     m_axis_rc_tdata;
  wire                     [KEEP_WIDTH-1:0]     m_axis_rc_tkeep;
  wire                                          m_axis_rc_tlast;
  wire                                          m_axis_rc_tvalid;
  wire                                          m_axis_rc_tready;
  wire            [AXI4_RC_TUSER_WIDTH-1:0]     m_axis_rc_tuser;

  wire                   [C_DATA_WIDTH-1:0]     m_axis_cq_tdata;
  wire            [AXI4_CQ_TUSER_WIDTH-1:0]     m_axis_cq_tuser;
  wire                                          m_axis_cq_tlast;
  wire                     [KEEP_WIDTH-1:0]     m_axis_cq_tkeep;
  wire                                          m_axis_cq_tvalid;
  wire                                          m_axis_cq_tready;
  assign m_axis_cq_tready = 1'b1;

  wire                   [C_DATA_WIDTH-1:0]     s_axis_cc_tdata;
  wire            [AXI4_CC_TUSER_WIDTH-1:0]     s_axis_cc_tuser;
  wire                                          s_axis_cc_tlast;
  wire                     [KEEP_WIDTH-1:0]     s_axis_cc_tkeep;
  wire                                          s_axis_cc_tvalid;
  wire                                [3:0]     s_axis_cc_tready;

  //-------------------------------------------------------
  // PCIe IP Cfg Ineterface
  //-------------------------------------------------------
  
  wire                             [3:0]        pcie_tfc_nph_av;
  wire                             [3:0]        pcie_tfc_npd_av;
  reg                                           pcie_cq_np_req;
  wire                              [5:0]       pcie_cq_np_req_count;
  wire                                          cfg_phy_link_down;
  wire                              [1:0]       cfg_phy_link_status;
  wire                              [2:0]       cfg_negotiated_width;
  wire                              [1:0]       cfg_current_speed;
  wire                              [1:0]       cfg_max_payload;
  wire                              [2:0]       cfg_max_read_req;
  wire                             [15:0]       cfg_function_status;
  wire                             [11:0]       cfg_function_power_state;
  wire                            [503:0]       cfg_vf_status;
  wire                            [755:0]       cfg_vf_power_state;
  wire                              [1:0]       cfg_link_power_state;
  wire                                          cfg_err_cor_out;
  wire                                          cfg_err_nonfatal_out;
  wire                                          cfg_err_fatal_out;
  wire                              [5:0]       cfg_ltssm_state;
  wire                              [3:0]       cfg_rcb_status;
  wire                              [1:0]       cfg_obff_enable;
  wire                                          cfg_pl_status_change;
  wire                              [3:0]       cfg_tph_requester_enable;
  wire                             [11:0]       cfg_tph_st_mode;
  wire                            [251:0]       cfg_vf_tph_requester_enable;
  wire                            [755:0]       cfg_vf_tph_st_mode;
  reg                              [9:0]        cfg_mgmt_addr;
  reg                                           cfg_mgmt_write;
  reg                             [31:0]        cfg_mgmt_write_data;
  reg                              [3:0]        cfg_mgmt_byte_enable;
  reg                                           cfg_mgmt_read;
  wire                             [31:0]       cfg_mgmt_read_data;
  wire                                          cfg_mgmt_read_write_done;
  wire                                          cfg_msg_received;
  wire                              [7:0]       cfg_msg_received_data;
  wire                              [4:0]       cfg_msg_received_type;
  reg                                           cfg_msg_transmit;
  reg                              [2:0]        cfg_msg_transmit_type;
  reg                             [31:0]        cfg_msg_transmit_data;
  wire                                          cfg_msg_transmit_done;
  wire                              [7:0]       cfg_fc_ph;
  wire                             [11:0]       cfg_fc_pd;
  wire                              [7:0]       cfg_fc_nph;
  wire                             [11:0]       cfg_fc_npd;
  wire                              [7:0]       cfg_fc_cplh;
  wire                             [11:0]       cfg_fc_cpld;
  reg                               [2:0]       cfg_fc_sel;
  wire                                          cfg_hot_reset_out;
  reg                                           cfg_config_space_enable;
  reg                                           cfg_req_pm_transition_l23_ready;
  reg                                           cfg_hot_reset_in;
  reg                               [7:0]       cfg_ds_port_number;
  reg                               [7:0]       cfg_ds_bus_number;
  reg                               [4:0]       cfg_ds_device_number;
  reg                              [63:0]       cfg_dsn;
  reg                                           cfg_power_state_change_ack;
  wire                                          cfg_power_state_change_interrupt;
  reg                                           cfg_err_cor_in;
  reg                                           cfg_err_uncor_in;  
  wire                              [3:0]       cfg_flr_in_process;
  reg                               [3:0]       cfg_flr_done;
  wire                            [251:0]       cfg_vf_flr_in_process;
  reg                               [0:0]       cfg_vf_flr_done;
  reg                                           cfg_link_training_enable;
  reg                               [3:0]       cfg_interrupt_int;
  reg                               [1:0]       cfg_interrupt_pending;
  wire                                          cfg_interrupt_sent;
  wire                              [3:0]       cfg_interrupt_msi_enable;
  wire                             [11:0]       cfg_interrupt_msi_mmenable;
  wire                                          cfg_interrupt_msi_mask_update;
  wire                             [31:0]       cfg_interrupt_msi_data;
  reg                               [1:0]       cfg_interrupt_msi_select;
  reg                              [31:0]       cfg_interrupt_msi_int;
  reg                              [63:0]       cfg_interrupt_msi_pending_status;
  wire                                          cfg_interrupt_msi_sent;
  wire                                          cfg_interrupt_msi_fail;
  reg                                           cfg_interrupt_msi_pending_status_data_enable;
  reg                               [3:0]       cfg_interrupt_msi_pending_status_function_num;
  reg                               [2:0]       cfg_interrupt_msi_attr;
  reg                                           cfg_interrupt_msi_tph_present;
  reg                               [1:0]       cfg_interrupt_msi_tph_type;
  reg                               [7:0]       cfg_interrupt_msi_tph_st_tag;
  reg                               [2:0]       cfg_interrupt_msi_function_number;


  //-------------------------------------------------------
  // Configurator & Doorbell to Arbiter 
  //-------------------------------------------------------

  wire                                [3:0]     cfg_s_axis_rq_tready;
  wire                   [C_DATA_WIDTH-1:0]     cfg_s_axis_rq_tdata;
  wire                     [KEEP_WIDTH-1:0]     cfg_s_axis_rq_tkeep;
  wire            [AXI4_RQ_TUSER_WIDTH-1:0]     cfg_s_axis_rq_tuser;
  wire                                          cfg_s_axis_rq_tlast;
  wire                                          cfg_s_axis_rq_tvalid;
  
  wire                   [C_DATA_WIDTH-1:0]     cfg_m_axis_rc_tdata;
  wire                     [KEEP_WIDTH-1:0]     cfg_m_axis_rc_tkeep;
  wire                                          cfg_m_axis_rc_tlast;
  wire                                          cfg_m_axis_rc_tvalid;
  wire                                          cfg_m_axis_rc_tready;
  wire            [AXI4_RC_TUSER_WIDTH-1:0]     cfg_m_axis_rc_tuser;

  wire                                [3:0]     db_s_axis_rq_tready;
  wire                   [C_DATA_WIDTH-1:0]     db_s_axis_rq_tdata;
  wire                     [KEEP_WIDTH-1:0]     db_s_axis_rq_tkeep;
  wire            [AXI4_RQ_TUSER_WIDTH-1:0]     db_s_axis_rq_tuser;
  wire                                          db_s_axis_rq_tlast;
  wire                                          db_s_axis_rq_tvalid;


  //-------------------------------------------------------
  // Configurator <-> Controller Interface 
  //-------------------------------------------------------
  wire start_config;
  wire cfg_done;


  //-------------------------------------------------------
  // DoorBell <-> Controller Interface
  //-------------------------------------------------------

  wire write_sqtdbl;
  wire [63:0] sqt_addr;
  wire write_cqhdbl;
  wire [63:0] cqh_addr;
  wire write_sqtdbl_done;
  wire write_cqhdbl_done;


  //-------------------------------------------------------
  // TX CC <-> Controller Interface
  //-------------------------------------------------------
  wire send_cmd;
  wire send_cmd_done;


  //-------------------------------------------------------
  // Debugging Signals 
  //-------------------------------------------------------
  wire [3:0] ctl_state;
  wire [4:0] cfg_state;
  wire [3:0] db_state;


  //-------------------------------------------------------
  // Virtual I/O Signals
  //-------------------------------------------------------
  wire [255:0] probe_in0;
  wire [255:0] probe_out0;
  wire        vio_reset_n;
  wire [3:0]  vio_sqt_addr;
  wire        vio_write_sqtdbl;
  wire        vio_send_cmd;


  // cfg_ltssm_state L0 is 6'h10
  assign probe_in0 = {  
                        240'h0,
                        4'h00,
                        ctl_state,
                        perst_n,
                        cprsnt,
                        cfg_ltssm_state // 6-bit
                      };

  assign vio_reset_n      = probe_out0[0];
  assign perst_n          = vio_reset_n;
  assign vio_sqt_addr     = probe_out0[32:1];
  assign vio_write_sqtdbl = probe_out0[33];
  assign vio_send_cmd     = probe_out0[34];

  // Note: PCIe is in RESET by default--allows ILA triggers to be added  
  vio_0 vio_0 (
    .clk        (user_clk),  // input  wire          clk
    .probe_in0  (probe_in0), // input  wire [255 : 0] probe_in0
    .probe_out0 (probe_out0) // output wire [255 : 0] probe_out0
  );





  pcie_arbiter #(
    .AXI4_CQ_TUSER_WIDTH  (AXI4_CQ_TUSER_WIDTH),
    .AXI4_CC_TUSER_WIDTH  (AXI4_CC_TUSER_WIDTH),
    .AXI4_RQ_TUSER_WIDTH  (AXI4_RQ_TUSER_WIDTH),
    .AXI4_RC_TUSER_WIDTH  (AXI4_RC_TUSER_WIDTH),
    .C_DATA_WIDTH         (C_DATA_WIDTH),
    .KEEP_WIDTH           (KEEP_WIDTH)
  ) pcie_arbiter_inst (
    // System Interface
    .user_clk                                 ( user_clk ),
    .user_reset                               ( user_reset ),
    .user_lnk_up                              ( user_lnk_up ),
    
    // PCIe IP AXI4-Stream Interface
    .s_axis_rq_tready                         ( s_axis_rq_tready ),
    .s_axis_rq_tdata                          ( s_axis_rq_tdata ),
    .s_axis_rq_tkeep                          ( s_axis_rq_tkeep ),
    .s_axis_rq_tuser                          ( s_axis_rq_tuser ),
    .s_axis_rq_tlast                          ( s_axis_rq_tlast ),
    .s_axis_rq_tvalid                         ( s_axis_rq_tvalid ),
    .m_axis_rc_tdata                          ( m_axis_rc_tdata ),
    .m_axis_rc_tkeep                          ( m_axis_rc_tkeep ),
    .m_axis_rc_tlast                          ( m_axis_rc_tlast ),
    .m_axis_rc_tvalid                         ( m_axis_rc_tvalid ),
    .m_axis_rc_tuser                          ( m_axis_rc_tuser ),
    .m_axis_rc_tready                         ( m_axis_rc_tready ),
/*
    .m_axis_cq_tdata                          ( m_axis_cq_tdata ),
    .m_axis_cq_tuser                          ( m_axis_cq_tuser ),
    .m_axis_cq_tlast                          ( m_axis_cq_tlast ),
    .m_axis_cq_tkeep                          ( m_axis_cq_tkeep ),
    .m_axis_cq_tvalid                         ( m_axis_cq_tvalid ),
    .m_axis_cq_tready                         ( m_axis_cq_tready ),
    .s_axis_cc_tdata                          ( s_axis_cc_tdata ),
    .s_axis_cc_tuser                          ( s_axis_cc_tuser ),
    .s_axis_cc_tlast                          ( s_axis_cc_tlast ),
    .s_axis_cc_tkeep                          ( s_axis_cc_tkeep ),
    .s_axis_cc_tvalid                         ( s_axis_cc_tvalid ),
    .s_axis_cc_tready                         ( s_axis_cc_tready ),
*/
    // Configurator -> Arbiter
    .cfg_done                                 ( cfg_done ),
    .cfg_s_axis_rq_tready                     ( cfg_s_axis_rq_tready ),
    .cfg_s_axis_rq_tdata                      ( cfg_s_axis_rq_tdata ),
    .cfg_s_axis_rq_tkeep                      ( cfg_s_axis_rq_tkeep ),
    .cfg_s_axis_rq_tuser                      ( cfg_s_axis_rq_tuser ),
    .cfg_s_axis_rq_tlast                      ( cfg_s_axis_rq_tlast ),
    .cfg_s_axis_rq_tvalid                     ( cfg_s_axis_rq_tvalid ),
    .cfg_m_axis_rc_tdata                      ( cfg_m_axis_rc_tdata ),
    .cfg_m_axis_rc_tkeep                      ( cfg_m_axis_rc_tkeep ),
    .cfg_m_axis_rc_tlast                      ( cfg_m_axis_rc_tlast ),
    .cfg_m_axis_rc_tvalid                     ( cfg_m_axis_rc_tvalid ),
    .cfg_m_axis_rc_tuser                      ( cfg_m_axis_rc_tuser ),
    .cfg_m_axis_rc_tready                     ( cfg_m_axis_rc_tready ),

    // Doorbell -> Arbiter
    .db_s_axis_rq_tready                       ( db_s_axis_rq_tready ),
    .db_s_axis_rq_tdata                        ( db_s_axis_rq_tdata ),
    .db_s_axis_rq_tkeep                        ( db_s_axis_rq_tkeep ),
    .db_s_axis_rq_tuser                        ( db_s_axis_rq_tuser ),
    .db_s_axis_rq_tlast                        ( db_s_axis_rq_tlast ),
    .db_s_axis_rq_tvalid                       ( db_s_axis_rq_tvalid )
  );


  controller #(
    .AXI4_CQ_TUSER_WIDTH  (AXI4_CQ_TUSER_WIDTH),
    .AXI4_CC_TUSER_WIDTH  (AXI4_CC_TUSER_WIDTH),
    .AXI4_RQ_TUSER_WIDTH  (AXI4_RQ_TUSER_WIDTH),
    .AXI4_RC_TUSER_WIDTH  (AXI4_RC_TUSER_WIDTH),
    .C_DATA_WIDTH         (C_DATA_WIDTH),
    .KEEP_WIDTH           (KEEP_WIDTH)
  ) controller_inst (
    // System Interface
    .user_clk                                ( user_clk ),
    .user_reset                              ( user_reset ),
    .user_lnk_up                             ( user_lnk_up ),
    
    // Configurator <-> Controller
    .start_config                            (start_config),
    .cfg_done                                (cfg_done),

    // Doorbell <-> Controller
    .write_sqtdbl                             ( write_sqtdbl ),
    .sqt_addr                                 ( sqt_addr ),
    .write_cqhdbl                             ( write_cqhdbl ),
    .cqh_addr                                 ( cqh_addr ),
    .write_sqtdbl_done                        ( write_sqtdbl_done ),
    .write_cqhdbl_done                        ( write_cqhdbl_done ),

    // TX CC <-> Controller
    .send_cmd                                 (send_cmd),
    .send_cmd_done                            (send_cmd_done),

    // for debugging
    .vio_sqt_addr                             (vio_sqt_addr),
    .vio_write_sqtdbl                         (vio_write_sqtdbl),
    .vio_send_cmd                             (vio_send_cmd),
    .ctl_state                                (ctl_state)
  );



  configurator #(
    .AXI4_RQ_TUSER_WIDTH  (AXI4_RQ_TUSER_WIDTH),
    .AXI4_RC_TUSER_WIDTH  (AXI4_RC_TUSER_WIDTH),
    .C_DATA_WIDTH         (C_DATA_WIDTH),
    .KEEP_WIDTH           (KEEP_WIDTH)
  ) configurator_inst (
    // System Interface
    .user_clk                                 ( user_clk ),
    .user_reset                               ( user_reset ),
    .user_lnk_up                              ( user_lnk_up ),

    // Controller <-> Configurator Interface
    .start_config                             (start_config),
    .cfg_done                                 (cfg_done),

    // Requester reQuest
    .s_axis_rq_tready                         ( cfg_s_axis_rq_tready ),
    .s_axis_rq_tdata                          ( cfg_s_axis_rq_tdata ),
    .s_axis_rq_tkeep                          ( cfg_s_axis_rq_tkeep ),
    .s_axis_rq_tuser                          ( cfg_s_axis_rq_tuser ),
    .s_axis_rq_tlast                          ( cfg_s_axis_rq_tlast ),
    .s_axis_rq_tvalid                         ( cfg_s_axis_rq_tvalid ),

    // Requester Completion    
    .m_axis_rc_tdata                          ( cfg_m_axis_rc_tdata ),
    .m_axis_rc_tkeep                          ( cfg_m_axis_rc_tkeep ),
    .m_axis_rc_tlast                          ( cfg_m_axis_rc_tlast ),
    .m_axis_rc_tvalid                         ( cfg_m_axis_rc_tvalid ),
    .m_axis_rc_tuser                          ( cfg_m_axis_rc_tuser ),
    .m_axis_rc_tready                         ( cfg_m_axis_rc_tready ),
    
    // for debugging
    .cfg_state                                (cfg_state)
  );


  doorbell #(
    .AXI4_RQ_TUSER_WIDTH  (AXI4_RQ_TUSER_WIDTH),
    .C_DATA_WIDTH         (C_DATA_WIDTH),
    .KEEP_WIDTH           (KEEP_WIDTH)
  ) doorbell_inst (
    // System Interface
    .user_clk                                 ( user_clk ),
    .user_reset                               ( user_reset ),
    .user_lnk_up                              ( user_lnk_up ),

    // Controller Interface
    .write_sqtdbl                             ( write_sqtdbl ),
    .sqt_addr                                 ( sqt_addr ),
    .write_cqhdbl                             ( write_cqhdbl ),
    .cqh_addr                                 ( cqh_addr ),
    .write_sqtdbl_done                        ( write_sqtdbl_done ),
    .write_cqhdbl_done                        ( write_cqhdbl_done ),

    // Requester reQuest
    .s_axis_rq_tready                         ( db_s_axis_rq_tready ),
    .s_axis_rq_tdata                          ( db_s_axis_rq_tdata ),
    .s_axis_rq_tkeep                          ( db_s_axis_rq_tkeep ),
    .s_axis_rq_tuser                          ( db_s_axis_rq_tuser ),
    .s_axis_rq_tlast                          ( db_s_axis_rq_tlast ),
    .s_axis_rq_tvalid                         ( db_s_axis_rq_tvalid ),

    // for debugging
    .db_state                                 (db_state)
  );


  tx_cc #(
    .AXI4_CC_TUSER_WIDTH  (AXI4_CC_TUSER_WIDTH),
    .C_DATA_WIDTH         (C_DATA_WIDTH),
    .KEEP_WIDTH           (KEEP_WIDTH)
  ) tx_cc_inst (
    // System Interface
    .user_clk                                 ( user_clk ),
    .user_reset                               ( user_reset ),
    .user_lnk_up                              ( user_lnk_up ),

    .s_axis_cc_tready                         ( s_axis_cc_tready ),
    .s_axis_cc_tdata                          ( s_axis_cc_tdata ),
    .s_axis_cc_tkeep                          ( s_axis_cc_tkeep ),
    .s_axis_cc_tuser                          ( s_axis_cc_tuser ),
    .s_axis_cc_tlast                          ( s_axis_cc_tlast ),
    .s_axis_cc_tvalid                         ( s_axis_cc_tvalid ),

    .send_cmd                                 ( send_cmd),
    .send_cmd_done                            ( send_cmd_done)
  );

  //-------------------------------------------------------
  // ILA Pipelining
  //-------------------------------------------------------

  wire                                [3:0]     s_axis_rq_tready_q;
  wire                   [C_DATA_WIDTH-1:0]     s_axis_rq_tdata_q;
  wire                     [KEEP_WIDTH-1:0]     s_axis_rq_tkeep_q;
  wire            [AXI4_RQ_TUSER_WIDTH-1:0]     s_axis_rq_tuser_q;
  wire                                          s_axis_rq_tlast_q;
  wire                                          s_axis_rq_tvalid_q;
  wire                   [C_DATA_WIDTH-1:0]     m_axis_rc_tdata_q;
  wire                     [KEEP_WIDTH-1:0]     m_axis_rc_tkeep_q;
  wire                                          m_axis_rc_tlast_q;
  wire                                          m_axis_rc_tvalid_q;
  wire                                          m_axis_rc_tready_q;
  wire            [AXI4_RC_TUSER_WIDTH-1:0]     m_axis_rc_tuser_q;
  wire                   [C_DATA_WIDTH-1:0]     m_axis_cq_tdata_q;
  wire            [AXI4_CQ_TUSER_WIDTH-1:0]     m_axis_cq_tuser_q;
  wire                                          m_axis_cq_tlast_q;
  wire                     [KEEP_WIDTH-1:0]     m_axis_cq_tkeep_q;
  wire                                          m_axis_cq_tvalid_q;
  wire                                          m_axis_cq_tready_q;
  wire                   [C_DATA_WIDTH-1:0]     s_axis_cc_tdata_q;
  wire            [AXI4_CC_TUSER_WIDTH-1:0]     s_axis_cc_tuser_q;
  wire                                          s_axis_cc_tlast_q;
  wire                     [KEEP_WIDTH-1:0]     s_axis_cc_tkeep_q;
  wire                                          s_axis_cc_tvalid_q;
  wire                                [3:0]     s_axis_cc_tready_q;

  reg                                [3:0]     s_axis_rq_tready_d;
  reg                   [C_DATA_WIDTH-1:0]     s_axis_rq_tdata_d;
  reg                     [KEEP_WIDTH-1:0]     s_axis_rq_tkeep_d;
  reg            [AXI4_RQ_TUSER_WIDTH-1:0]     s_axis_rq_tuser_d;
  reg                                          s_axis_rq_tlast_d;
  reg                                          s_axis_rq_tvalid_d;
  reg                   [C_DATA_WIDTH-1:0]     m_axis_rc_tdata_d;
  reg                     [KEEP_WIDTH-1:0]     m_axis_rc_tkeep_d;
  reg                                          m_axis_rc_tlast_d;
  reg                                          m_axis_rc_tvalid_d;
  reg                                          m_axis_rc_tready_d;
  reg            [AXI4_RC_TUSER_WIDTH-1:0]     m_axis_rc_tuser_d;
  reg                   [C_DATA_WIDTH-1:0]     m_axis_cq_tdata_d;
  reg            [AXI4_CQ_TUSER_WIDTH-1:0]     m_axis_cq_tuser_d;
  reg                                          m_axis_cq_tlast_d;
  reg                     [KEEP_WIDTH-1:0]     m_axis_cq_tkeep_d;
  reg                                          m_axis_cq_tvalid_d;
  reg                                          m_axis_cq_tready_d;
  reg                   [C_DATA_WIDTH-1:0]     s_axis_cc_tdata_d;
  reg            [AXI4_CC_TUSER_WIDTH-1:0]     s_axis_cc_tuser_d;
  reg                                          s_axis_cc_tlast_d;
  reg                     [KEEP_WIDTH-1:0]     s_axis_cc_tkeep_d;
  reg                                          s_axis_cc_tvalid_d;
  reg                                [3:0]     s_axis_cc_tready_d;


  wire        user_lnk_up_q;
  wire [5:0]  cfg_ltssm_state_q;
  wire [3:0]  ctl_state_q;
  wire [4:0]  cfg_state_q;
  wire [3:0]  db_state_q;
  wire        start_config_q;
  wire        cfg_done_q;

  reg         user_lnk_up_d;
  reg [5:0]   cfg_ltssm_state_d;
  reg [3:0]   ctl_state_d;
  reg [4:0]   cfg_state_d;
  reg [3:0]   db_state_d;
  reg         start_config_d;
  reg         cfg_done_d;

  // cfg_ltssm_state, user_lnk_up, cfg_done, start_config, cfg_state, ctl_state, db_state
  always@(posedge user_clk) begin
    user_lnk_up_d <= user_lnk_up;
    cfg_ltssm_state_d <= cfg_ltssm_state;
    cfg_done_d <= cfg_done;
    start_config_d <= start_config;
    cfg_state_d <= cfg_state;
    ctl_state_d <= ctl_state;
    db_state_d <= db_state;

    s_axis_rq_tready_d <= s_axis_rq_tready;
    s_axis_rq_tdata_d <= s_axis_rq_tdata;
    s_axis_rq_tkeep_d <= s_axis_rq_tkeep;
    s_axis_rq_tuser_d <= s_axis_rq_tuser;
    s_axis_rq_tlast_d <= s_axis_rq_tlast;
    s_axis_rq_tvalid_d <= s_axis_rq_tvalid;
    m_axis_rc_tdata_d <= m_axis_rc_tdata;
    m_axis_rc_tkeep_d <= m_axis_rc_tkeep;
    m_axis_rc_tlast_d <= m_axis_rc_tlast;
    m_axis_rc_tvalid_d <= m_axis_rc_tvalid;
    m_axis_rc_tready_d <= m_axis_rc_tready;
    m_axis_rc_tuser_d <= m_axis_rc_tuser;
    m_axis_cq_tdata_d <= m_axis_cq_tdata;
    m_axis_cq_tuser_d <= m_axis_cq_tuser;
    m_axis_cq_tlast_d <= m_axis_cq_tlast;
    m_axis_cq_tkeep_d <= m_axis_cq_tkeep;
    m_axis_cq_tvalid_d <= m_axis_cq_tvalid;
    m_axis_cq_tready_d <= m_axis_cq_tready;
    s_axis_cc_tdata_d <= s_axis_cc_tdata;
    s_axis_cc_tuser_d <= s_axis_cc_tuser;
    s_axis_cc_tlast_d <= s_axis_cc_tlast;
    s_axis_cc_tkeep_d <= s_axis_cc_tkeep;
    s_axis_cc_tvalid_d <= s_axis_cc_tvalid;
    s_axis_cc_tready_d <= s_axis_cc_tready;
  end

  assign s_axis_rq_tready_q  = s_axis_rq_tready_d;
  assign s_axis_rq_tdata_q = s_axis_rq_tdata_d;
  assign s_axis_rq_tkeep_q = s_axis_rq_tkeep_d;
  assign s_axis_rq_tuser_q = s_axis_rq_tuser_d;
  assign s_axis_rq_tlast_q = s_axis_rq_tlast_d;
  assign s_axis_rq_tvalid_q  = s_axis_rq_tvalid_d;
  assign m_axis_rc_tdata_q = m_axis_rc_tdata_d;
  assign m_axis_rc_tkeep_q = m_axis_rc_tkeep_d;
  assign m_axis_rc_tlast_q = m_axis_rc_tlast_d;
  assign m_axis_rc_tvalid_q  = m_axis_rc_tvalid_d;
  assign m_axis_rc_tready_q  = m_axis_rc_tready_d;
  assign m_axis_rc_tuser_q = m_axis_rc_tuser_d;
  assign m_axis_cq_tdata_q = m_axis_cq_tdata_d;
  assign m_axis_cq_tuser_q = m_axis_cq_tuser_d;
  assign m_axis_cq_tlast_q = m_axis_cq_tlast_d;
  assign m_axis_cq_tkeep_q = m_axis_cq_tkeep_d;
  assign m_axis_cq_tvalid_q  = m_axis_cq_tvalid_d;
  assign m_axis_cq_tready_q  = m_axis_cq_tready_d;
  assign s_axis_cc_tdata_q = s_axis_cc_tdata_d;
  assign s_axis_cc_tuser_q = s_axis_cc_tuser_d;
  assign s_axis_cc_tlast_q = s_axis_cc_tlast_d;
  assign s_axis_cc_tkeep_q = s_axis_cc_tkeep_d;
  assign s_axis_cc_tvalid_q  = s_axis_cc_tvalid_d;
  assign s_axis_cc_tready_q  = s_axis_cc_tready_d;

  assign user_lnk_up_q = user_lnk_up_d;
  assign cfg_ltssm_state_q = cfg_ltssm_state_d;
  assign ctl_state_q = ctl_state_d;
  assign cfg_state_q = cfg_state_d;
  assign db_state_q = db_state_d;
  assign start_config_q = start_config_d;
  assign cfg_done_q = cfg_done_d;


  // ILA
  ila_cfg ila_cfg_inst (
    .clk(user_clk),             // input clk
    .probe0(cfg_ltssm_state_q),   // 6-bit
    .probe1(user_lnk_up_q),       // 1-bit
    .probe2(m_axis_rc_tdata_q),   // 128-bit
    .probe3(m_axis_rc_tkeep_q),   // 4-bit
    .probe4(m_axis_rc_tlast_q),   
    .probe5(m_axis_rc_tvalid_q),
    .probe6(m_axis_rc_tready_q),
    .probe7(m_axis_rc_tuser_q),   // 75-bit
    .probe8(s_axis_rq_tdata_q),   // 128-bit
    .probe9(s_axis_rq_tkeep_q),   // 4-bit
    .probe10(s_axis_rq_tlast_q),
    .probe11(s_axis_rq_tvalid_q),
    .probe12(s_axis_rq_tready_q),
    .probe13(s_axis_rq_tuser_q),  // 62-bit
    .probe14(m_axis_cq_tdata_q),  // 128-bit
    .probe15(m_axis_cq_tkeep_q),  // 4-bit
    .probe16(m_axis_cq_tlast_q),  // 1-bit
    .probe17(m_axis_cq_tready_q), // 1-bit
    .probe18(m_axis_cq_tuser_q),  // 88-bit
    .probe19(m_axis_cq_tvalid_q), // 1-bit
    .probe20(s_axis_cc_tdata_q),  // 128-bit
    .probe21(s_axis_cc_tkeep_q),  // 4-bit
    .probe22(s_axis_cc_tlast_q),  
    .probe23(s_axis_cc_tvalid_q),
    .probe24(s_axis_cc_tready_q),
    .probe25(s_axis_cc_tuser_q),  // 33-bit
    .probe26(cfg_done_q),         // 1-bit
    .probe27(start_config_q),     // 1-bit
    .probe28(cfg_state_q),        // 5-bit
    .probe29(ctl_state_q),        // 4-bit
    .probe30(db_state_q)          // 4-bit
  );



  
  //-------------------------------------------------------  
  //  PCIe IP : RootComplex
  //-------------------------------------------------------  
  
  pcie4_uscale_plus_0  pcie4_uscale_plus_0a (
    .pci_exp_txn                                    ( pci_exp_txn ),
    .pci_exp_txp                                    ( pci_exp_txp ),
    .pci_exp_rxn                                    ( pci_exp_rxn ),
    .pci_exp_rxp                                    ( pci_exp_rxp ),
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
    .pcie_tfc_nph_av                                ( pcie_tfc_nph_av ),
    .pcie_tfc_npd_av                                ( pcie_tfc_npd_av ),
    .pcie_rq_seq_num0                               ( pcie_rq_seq_num0) ,
    .pcie_rq_seq_num_vld0                           ( pcie_rq_seq_num_vld0) ,
    .pcie_rq_seq_num1                               ( pcie_rq_seq_num1) ,
    .pcie_rq_seq_num_vld1                           ( pcie_rq_seq_num_vld1) ,
    .pcie_rq_tag0                                   ( pcie_rq_tag0) ,
    .pcie_rq_tag1                                   ( pcie_rq_tag1) ,
    .pcie_rq_tag_av                                 ( pcie_rq_tag_av) ,
    .pcie_rq_tag_vld0                               ( pcie_rq_tag_vld0) ,
    .pcie_rq_tag_vld1                               ( pcie_rq_tag_vld1) ,
    .pcie_cq_np_req                                 ( pcie_cq_np_req ),
    .pcie_cq_np_req_count                           ( pcie_cq_np_req_count ),
    .cfg_phy_link_down                              ( cfg_phy_link_down ),
    .cfg_phy_link_status                            ( cfg_phy_link_status),
    .cfg_negotiated_width                           ( cfg_negotiated_width ),
    .cfg_current_speed                              ( cfg_current_speed ),
    .cfg_max_payload                                ( cfg_max_payload ),
    .cfg_max_read_req                               ( cfg_max_read_req ),
    .cfg_function_status                            ( cfg_function_status ),
    .cfg_function_power_state                       ( cfg_function_power_state ),
    .cfg_vf_status                                  ( cfg_vf_status ),
    .cfg_vf_power_state                             ( cfg_vf_power_state ),
    .cfg_link_power_state                           ( cfg_link_power_state ),
    .cfg_err_cor_out                                ( cfg_err_cor_out ),
    .cfg_err_nonfatal_out                           ( cfg_err_nonfatal_out ),
    .cfg_err_fatal_out                              ( cfg_err_fatal_out ),
    .cfg_local_error_out                            ( cfg_local_error_out ),
    .cfg_local_error_valid                          ( cfg_local_error_valid ),
    .cfg_ltssm_state                                ( cfg_ltssm_state ),
    .cfg_rx_pm_state                                ( cfg_rx_pm_state ),
    .cfg_tx_pm_state                                ( cfg_tx_pm_state ),
    .cfg_rcb_status                                 ( cfg_rcb_status ),
    .cfg_obff_enable                                ( cfg_obff_enable ),
    .cfg_pl_status_change                           ( cfg_pl_status_change ),
    .cfg_tph_requester_enable                       ( cfg_tph_requester_enable ),
    .cfg_tph_st_mode                                ( cfg_tph_st_mode ),
    .cfg_vf_tph_requester_enable                    ( cfg_vf_tph_requester_enable ),
    .cfg_vf_tph_st_mode                             ( cfg_vf_tph_st_mode ),
    .cfg_mgmt_addr                                  ( cfg_mgmt_addr ),
    .cfg_mgmt_write                                 ( cfg_mgmt_write ),
    .cfg_mgmt_write_data                            ( cfg_mgmt_write_data ),
    .cfg_mgmt_byte_enable                           ( cfg_mgmt_byte_enable ),
    .cfg_mgmt_read                                  ( cfg_mgmt_read ),
    .cfg_mgmt_read_data                             ( cfg_mgmt_read_data ),
    .cfg_mgmt_read_write_done                       ( cfg_mgmt_read_write_done ),
    .cfg_mgmt_debug_access                          ( cfg_mgmt_debug_access ),
    .cfg_mgmt_function_number                       ( cfg_mgmt_function_number ),
    .cfg_pm_aspm_l1_entry_reject                    ( cfg_pm_aspm_l1_entry_reject),
    .cfg_pm_aspm_tx_l0s_entry_disable               ( cfg_pm_aspm_tx_l0s_entry_disable),
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
    .cfg_bus_number                                 ( cfg_bus_number ), 
    .cfg_dsn                                        ( cfg_dsn ),
    .cfg_power_state_change_ack                     ( cfg_power_state_change_ack ),
    .cfg_power_state_change_interrupt               ( cfg_power_state_change_interrupt ),
    .cfg_err_cor_in                                 ( cfg_err_cor_in ),
    .cfg_err_uncor_in                               ( cfg_err_uncor_in ),
    .cfg_flr_in_process                             ( cfg_flr_in_process ),
    .cfg_flr_done                                   ( cfg_flr_done ),
    .cfg_vf_flr_in_process                          ( cfg_vf_flr_in_process ),
    .cfg_vf_flr_done                                ( cfg_vf_flr_done ),
    .cfg_link_training_enable                       ( cfg_link_training_enable ),
    .cfg_hot_reset_out                              ( cfg_hot_reset_out ),
    .cfg_config_space_enable                        ( cfg_config_space_enable ),
    .cfg_req_pm_transition_l23_ready                ( cfg_req_pm_transition_l23_ready ),
    .cfg_hot_reset_in                               ( cfg_hot_reset_in ),
    .cfg_ds_bus_number                              ( cfg_ds_bus_number ),
    .cfg_ds_device_number                           ( cfg_ds_device_number ),
    .cfg_ds_port_number                             ( cfg_ds_port_number ),
    .cfg_vf_flr_func_num                            (cfg_vf_flr_func_num),
    .cfg_interrupt_int                              ( cfg_interrupt_int ),
    .cfg_interrupt_pending                          ( {2'b0,cfg_interrupt_pending} ),
    .cfg_interrupt_sent                             ( cfg_interrupt_sent ),
    .cfg_interrupt_msi_enable                       ( cfg_interrupt_msi_enable ),
    .cfg_interrupt_msi_mmenable                     ( cfg_interrupt_msi_mmenable ),
    .cfg_interrupt_msi_mask_update                  ( cfg_interrupt_msi_mask_update ),
    .cfg_interrupt_msi_data                         ( cfg_interrupt_msi_data ),
    .cfg_interrupt_msi_select                       ( cfg_interrupt_msi_select ),
    .cfg_interrupt_msi_int                          ( cfg_interrupt_msi_int ),
    .cfg_interrupt_msi_pending_status               ( cfg_interrupt_msi_pending_status [31:0]),
    .cfg_interrupt_msi_sent                         ( cfg_interrupt_msi_sent ),
    .cfg_interrupt_msi_fail                         ( cfg_interrupt_msi_fail ),
    .cfg_interrupt_msi_attr                         ( cfg_interrupt_msi_attr ),
    .cfg_interrupt_msi_tph_present                  ( cfg_interrupt_msi_tph_present ),
    .cfg_interrupt_msi_tph_type                     ( cfg_interrupt_msi_tph_type ),
    .cfg_interrupt_msi_tph_st_tag                   ( cfg_interrupt_msi_tph_st_tag ),
    .cfg_interrupt_msi_pending_status_function_num  ( 2'b0 ),
    .cfg_interrupt_msi_pending_status_data_enable   ( 1'b0 ),
    .cfg_interrupt_msi_function_number              ( 8'b0 ),
    .sys_clk                                        ( sys_clk ),
    .sys_clk_gt                                     ( sys_clk_gt ),
    .sys_reset                                      ( sys_rst_n_c )
  );



  // CFG_WRITE
  reg write_cfg_done_1;
  always @(posedge user_clk) begin
    if (user_reset) begin
        cfg_mgmt_addr        <= 32'b0;
        cfg_mgmt_write_data  <= 32'b0;
        cfg_mgmt_byte_enable <= 4'b0;
        cfg_mgmt_write       <= 1'b0;
        cfg_mgmt_read        <= 1'b0;
        write_cfg_done_1     <= 1'b0; 
    end
    else begin
      if (cfg_mgmt_read_write_done == 1'b1 && write_cfg_done_1 == 1'b1) begin
        cfg_mgmt_addr        <= 0;
        cfg_mgmt_write_data  <= 0;
        cfg_mgmt_byte_enable <= 0;
        cfg_mgmt_write       <= 0;
        cfg_mgmt_read        <= 0;  
      end
      else if (cfg_mgmt_read_write_done == 1'b1 && write_cfg_done_1 == 1'b0) begin
        cfg_mgmt_addr         <= 10'h010;         // BAR0 Reg Num
        //cfg_mgmt_write_data   <= 32'h0000_1000;   // BAR0 Value
        cfg_mgmt_byte_enable  <= 4'hF;
        cfg_mgmt_write        <= 1'b0;
        cfg_mgmt_read         <= 1'b1;  
        write_cfg_done_1      <= 1'b1; 
      end
      /*
      else if (write_cfg_done_1 == 1'b0) begin
        cfg_mgmt_addr        <= 32'h40082;
        cfg_mgmt_write_data  <= 32'b0;
        cfg_mgmt_byte_enable <= 4'hF;
        cfg_mgmt_write       <= 1'b0;
        cfg_mgmt_read        <= 1'b1;  
      end
      */
    end
  end


  // Configuration signals which are unused
  initial begin
    cfg_msg_transmit                 <= 0 ;// 
    cfg_msg_transmit_type            <= 0 ;//[2:0]
    cfg_msg_transmit_data            <= 0 ;//[31:0]  
    cfg_fc_sel                       <= 0 ;//[2:0]     
    pcie_cq_np_req                   <= 0 ;// 
    cfg_config_space_enable          <= 1'b1 ;//    
    cfg_req_pm_transition_l23_ready  <= 0 ;//                                   
    cfg_hot_reset_in                 <= 0 ;//        
    cfg_ds_bus_number                <= 8'h45 ;//[7:0]
    cfg_ds_device_number             <= 4'b0001 ;//[4:0]        
    cfg_ds_port_number               <= 8'h00 ;//[7:0]           
    cfg_dsn                          <= 64'h78EE32BAD28F906B ;//[63:0]       
    cfg_power_state_change_ack       <= 0 ;   
    cfg_err_cor_in                   <= 0 ;
    cfg_err_uncor_in                 <= 0 ;    
    cfg_flr_done                     <= 0 ;//[1:0]
    cfg_vf_flr_done                  <= 0 ;//[5:0]    
    cfg_link_training_enable         <= 1 ;
    cfg_interrupt_int                <= 0 ;//[3:0]  
    cfg_interrupt_pending            <= 0 ;//[1:0]      
    cfg_interrupt_msi_select         <= 0 ;//[3:0]        
    cfg_interrupt_msi_int            <= 0 ;//[31:0]  
    cfg_interrupt_msi_pending_status <= 0 ;//[63:0]  
    cfg_interrupt_msi_attr           <= 0 ;//[2:0] 
    cfg_interrupt_msi_tph_present    <= 0 ;       
    cfg_interrupt_msi_tph_type       <= 0 ;//[1:0]       
    cfg_interrupt_msi_tph_st_tag     <= 0 ;//[8:0]        
    cfg_interrupt_msi_function_number<= 0 ;//[2:0]            
    cfg_interrupt_msi_pending_status_data_enable <= 0 ; 
    cfg_interrupt_msi_pending_status_function_num <= 0 ;//[3:0]  
  end




endmodule