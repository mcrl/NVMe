
`timescale 1ps / 1ps
(* DowngradeIPIdentifiedWarnings = "yes" *)
module oculink_port # (
  // PCIe Parameters
  parameter           PCIE_EXT_CLK                  = "FALSE",
  parameter           EXT_PIPE_SIM                  = "FALSE",                               
  parameter           PL_LINK_CAP_MAX_LINK_SPEED    = 4,  // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4
  parameter [4:0]     PL_LINK_CAP_MAX_LINK_WIDTH    = 4,  // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16
  parameter           PL_DISABLE_EI_INFER_IN_L0     = "TRUE",
  parameter           PL_DISABLE_UPCONFIG_CAPABLE   = "FALSE",
  parameter  integer  USER_CLK2_FREQ                = 3,
  parameter           REF_CLK_FREQ                  = 0,  // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz

  // Configurator Parameters
  parameter [15:0]   REQUESTER_ID                 = 16'h0100,
  parameter          ROM_FILE                     = "pcie_cfg_rom.data",
  parameter          ROM_SIZE                     = 12,

  // AXIS Parameters
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXI4_CQ_TUSER_WIDTH            = 88,
  parameter        AXI4_CC_TUSER_WIDTH            = 33,
  parameter        AXI4_RQ_TUSER_WIDTH            = 62,
  parameter        AXI4_RC_TUSER_WIDTH            = 75,
  parameter        AXISTEN_IF_ENABLE_CLIENT_TAG   = "TRUE",
  parameter        AXISTEN_IF_RQ_PARITY_CHECK     = "FALSE",
  parameter        AXISTEN_IF_CC_PARITY_CHECK     = "FALSE",
  parameter        AXISTEN_IF_MC_RX_STRADDLE      = "FALSE",
  parameter        AXISTEN_IF_ENABLE_RX_MSG_INTFC = "FALSE",
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE    = 18'h2FFFF,
  parameter          C_DATA_WIDTH                 = 128,            
  parameter KEEP_WIDTH                            = C_DATA_WIDTH / 32
)
(
  // Oculink Interface
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txp,
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txn,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxp,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxn,
  input                                           sys_clk_p,    // Oculink ref clock
  input                                           sys_clk_n,    // Oculink ref clock
  output                                          perst_n,
  input                                           cprsnt,

  // System Interface
  input                                           sys_rst_n_c 
);
  
  // System clock
  wire sys_clk;
  wire sys_clk_gt;
  IBUFDS_GTE4 refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));


  //-------------------------------------------------------
  // 1. Configurator Interface
  //-------------------------------------------------------
   
  wire                                       start_config;    // in
  wire                                       finished_config; // out
  wire                                       failed_config;   // out
  
  wire                                       user_clk;
  wire                                       user_reset;
  wire                                       user_lnk_up;
  wire                                       phy_rdy_out;
  
  //-------------------------------------------------------
  // 2. Transaction (AXIS) Interface
  //-------------------------------------------------------  
  
  wire                                       s_axis_rq_tlast;
  wire                 [C_DATA_WIDTH-1:0]    s_axis_rq_tdata;
  wire          [AXI4_RQ_TUSER_WIDTH-1:0]    s_axis_rq_tuser;
  wire                   [KEEP_WIDTH-1:0]    s_axis_rq_tkeep;
  wire                                       s_axis_rq_tready;
  wire                                       s_axis_rq_tvalid;
  wire                 [C_DATA_WIDTH-1:0]    m_axis_rc_tdata;
  wire             [AXI4_RC_TUSER_WIDTH-1:0] m_axis_rc_tuser;
  wire                                       m_axis_rc_tlast;
  wire                   [KEEP_WIDTH-1:0]    m_axis_rc_tkeep;
  wire                                       m_axis_rc_tvalid;


  wire [15:0] probe_in0;
  wire [15:0] probe_out0;
  wire        vio_reset_n;
  wire [7:0]  addr_offset;

  // cfg_ltssm_state L0 is 6'h10
  assign probe_in0 = {
                      user_lnk_up,       // [   15]
                      start_config,      // [   14]
                      finished_config,   // [   13]
                      failed_config,     // [   12]
                      1'b0,              // [   11]
                      1'b0,              // [   10]
                      sys_rst_n_c,       // [    9]
                      perst_n,           // [    8]
                      cprsnt,            // [    7]
                      1'b0,              // [    6]
                      6'h0               // [ 5: 0]
                    };  

  assign addr_offset      = probe_out0[9:2];
  assign pio_test_restart = probe_out0[1];
  assign vio_reset_n      = probe_out0[0];
  assign perst_n          = vio_reset_n;

  vio_0 vio_0 (
    .clk        (user_clk),  // input  wire          clk
    .probe_in0  (probe_in0), // input  wire [15 : 0] probe_in0
    .probe_out0 (probe_out0) // output wire [15 : 0] probe_out0
  );

  pcie_top #(
    .ROM_FILE                       (ROM_FILE),
    .ROM_SIZE                       (ROM_SIZE),
    .REQUESTER_ID                   (REQUESTER_ID),  
    .PL_LINK_CAP_MAX_LINK_SPEED     (PL_LINK_CAP_MAX_LINK_SPEED),          
    .PL_LINK_CAP_MAX_LINK_WIDTH     (PL_LINK_CAP_MAX_LINK_WIDTH),          
    .REF_CLK_FREQ                   (REF_CLK_FREQ),          
    .C_DATA_WIDTH                   (C_DATA_WIDTH),
    .KEEP_WIDTH                     (KEEP_WIDTH)
  ) pcie_top_inst
  (

    //-------------------------------------------------------
    // 1. PCI Express (pci_exp) Interface
    //-------------------------------------------------------
    
    .pci_exp_txp                              (pci_exp_txp[PL_LINK_CAP_MAX_LINK_WIDTH-1:0]),
    .pci_exp_txn                              (pci_exp_txn[PL_LINK_CAP_MAX_LINK_WIDTH-1:0]),
    .pci_exp_rxp                              (pci_exp_rxp[PL_LINK_CAP_MAX_LINK_WIDTH-1:0]),
    .pci_exp_rxn                              (pci_exp_rxn[PL_LINK_CAP_MAX_LINK_WIDTH-1:0]),
    .sys_clk                                  ( sys_clk ),
    .sys_clk_gt                               (sys_clk_gt ),
    .sys_reset_n                              (sys_rst_n_c),

    //-------------------------------------------------------
    // 2. User Interface
    //-------------------------------------------------------
    
    .start_config                             (start_config),
    .finished_config                          (finished_config),
    .failed_config                            (failed_config),
    .user_clk_out                             (user_clk),
    .user_reset_out                           (user_reset),
    .user_lnk_up                              (user_lnk_up),
    .phy_rdy_out                              (phy_rdy_out),
    
    //-------------------------------------------------------
    // 3. Transaction (AXIS) Interface
    //-------------------------------------------------------

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
    .m_axis_rc_tuser                          ( m_axis_rc_tuser )
  );



  // BAR A: 2 MB, 32-bit Memory BAR using BAR0
  user_top #(
    .REQUESTER_ID                   (REQUESTER_ID),  
    .BAR_A_ENABLED  (1),
    .BAR_A_64BIT    (0),
    .BAR_A_IO       (0),
    .BAR_A_BASE     (32'h1000_0000),
    .BAR_A_SIZE     (1024/4),
    .C_DATA_WIDTH   (C_DATA_WIDTH),
    .KEEP_WIDTH     (KEEP_WIDTH)
  ) user_top_inst
  (
    // System inputs
    .user_clk               (user_clk),
    .reset                  (user_reset),
    .user_lnk_up            (user_lnk_up),

    // Board-level control/status
    .pio_test_restart       (pio_test_restart),
    .pio_test_finished      (pio_test_finished),
    .pio_test_failed        (pio_test_failed),

    // Control of Configurator
    .start_config           (start_config),
    .finished_config        (finished_config),
    .failed_config          (failed_config),

    // Transaction interfaces
    //TX
    .s_axis_rq_tready       (s_axis_rq_tready ),
    .s_axis_rq_tdata        (s_axis_rq_tdata ),
    .s_axis_rq_tkeep        (s_axis_rq_tkeep ),
    .s_axis_rq_tuser        (s_axis_rq_tuser ),
    .s_axis_rq_tlast        (s_axis_rq_tlast ),
    .s_axis_rq_tvalid       (s_axis_rq_tvalid ),

    // Rx
    .m_axis_rc_tdata        (m_axis_rc_tdata ),
    .m_axis_rc_tkeep        (m_axis_rc_tkeep ),
    .m_axis_rc_tlast        (m_axis_rc_tlast ),
    .m_axis_rc_tvalid       (m_axis_rc_tvalid ),
    .m_axis_rc_tuser        (m_axis_rc_tuser),

    // for debugging
    .addr_offset(addr_offset)
  );



endmodule
