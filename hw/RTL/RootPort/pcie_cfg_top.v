
(* DowngradeIPIdentifiedWarnings = "yes" *)
module pcie_cfg_top #(
    // Configurator Parameters
    parameter [15:0]    REQUESTER_ID          = 16'h10EE,
    parameter           ROM_FILE              = "pcie_cfg_rom.data",
    parameter           ROM_SIZE              = 12,
    parameter           ROM_ADDR_WIDTH        = (ROM_SIZE-1 < 2  )  ? 1 :
                                                (ROM_SIZE-1 < 4  )  ? 2 :
                                                (ROM_SIZE-1 < 8  )  ? 3 :
                                                (ROM_SIZE-1 < 16 )  ? 4 :
                                                (ROM_SIZE-1 < 32 )  ? 5 : 
                                                                      6,

    // AXIS Parameters                                                                      
    parameter           AXI4_CQ_TUSER_WIDTH   = 88,
    parameter           AXI4_CC_TUSER_WIDTH   = 33,
    parameter           AXI4_RQ_TUSER_WIDTH   = 62,
    parameter           AXI4_RC_TUSER_WIDTH   = 75,
    parameter           C_DATA_WIDTH          = 128,
    parameter           KEEP_WIDTH            = C_DATA_WIDTH / 32
  ) (
    input wire                          user_clk,
    input wire                          reset,
    input wire                          start_config,
    output wire                         finished_config,
    output wire                         failed_config,

    // AXIS interfaces 
    // Requests : Configurator -> PCIe IP
    input                               rport_s_axis_rq_tready,
    output [C_DATA_WIDTH-1:0]           rport_s_axis_rq_tdata,
    output [KEEP_WIDTH-1:0]             rport_s_axis_rq_tkeep,
    output [AXI4_RQ_TUSER_WIDTH-1:0]    rport_s_axis_rq_tuser,
    output                              rport_s_axis_rq_tlast,
    output                              rport_s_axis_rq_tvalid,

    // Completions : PCIe IP -> Configurator
    input  [C_DATA_WIDTH-1:0]           rport_m_axis_rc_tdata,
    input  [KEEP_WIDTH-1:0]             rport_m_axis_rc_tkeep,
    input                               rport_m_axis_rc_tlast,
    input                               rport_m_axis_rc_tvalid,
    output                              rport_m_axis_rc_tready,
    input  [AXI4_RC_TUSER_WIDTH-1:0]    rport_m_axis_rc_tuser,

    // User AXIS interfaces
    output                              usr_s_axis_rq_tready,
    input  [C_DATA_WIDTH-1:0]           usr_s_axis_rq_tdata,
    input  [KEEP_WIDTH-1:0]             usr_s_axis_rq_tkeep,
    input  [AXI4_RQ_TUSER_WIDTH-1:0]    usr_s_axis_rq_tuser,
    input                               usr_s_axis_rq_tlast,
    input                               usr_s_axis_rq_tvalid,

    output  [C_DATA_WIDTH-1:0]          usr_m_axis_rc_tdata,
    output  [KEEP_WIDTH-1:0]            usr_m_axis_rc_tkeep,
    output                              usr_m_axis_rc_tlast,
    output                              usr_m_axis_rc_tvalid,
    output  [AXI4_RC_TUSER_WIDTH-1:0]   usr_m_axis_rc_tuser,

    output [2:0]                ctl_state,
    output [ROM_ADDR_WIDTH-1:0] ctl_addr,
    output [31:0]               ctl_data,
    output                      ctl_last_cfg,
    output                      ctl_skip_cpl,

    input icq_full
  );

  // Controller <-> All modules
  wire          config_mode;
  wire          config_mode_active;

  wire                            pg_s_axis_rq_tready;
  wire [C_DATA_WIDTH-1:0]         pg_s_axis_rq_tdata;
  wire [KEEP_WIDTH-1:0]           pg_s_axis_rq_tkeep;
  wire [AXI4_RQ_TUSER_WIDTH-1:0]  pg_s_axis_rq_tuser;
  wire                            pg_s_axis_rq_tlast;
  wire                            pg_s_axis_rq_tvalid;

  // Controller <-> Packet Generator
  wire [1:0]    pkt_type;
  wire [1:0]    pkt_func_num;
  wire [9:0]    pkt_reg_num;
  wire [3:0]    pkt_1dw_be;
  wire [2:0]    pkt_msg_routing;
  wire [7:0]    pkt_msg_code;
  wire [31:0]   pkt_data;
  wire          pkt_start;
  wire          pkt_done;

  // Completion Decoder -> Controller
  wire          cpl_sc;
  wire          cpl_ur;
  wire          cpl_crs;
  wire          cpl_ca;
  wire [31:0]   cpl_data;
  wire          cpl_mismatch;


  // PCIe Configurator Controller module
  pcie_cfg_controller #(
    .ROM_FILE             (ROM_FILE),
    .ROM_SIZE             (ROM_SIZE)
  ) pcie_cfg_controller_inst (
    // globals
    .user_clk           (user_clk),
    .reset              (reset),

    // User interface
    .start_config       (start_config),
    .finished_config    (finished_config),
    .failed_config      (failed_config),

    // Packet generator interface
    .pkt_type           (pkt_type),
    .pkt_func_num       (pkt_func_num),
    .pkt_reg_num        (pkt_reg_num),
    .pkt_1dw_be         (pkt_1dw_be),
    .pkt_msg_routing    (pkt_msg_routing),
    .pkt_msg_code       (pkt_msg_code),
    .pkt_data           (pkt_data),
    .pkt_start          (pkt_start),
    .pkt_done           (pkt_done),

    // Tx mux and completion decoder interface
    .config_mode        (config_mode),
    .config_mode_active (config_mode_active),
    .cpl_sc             (cpl_sc),
    .cpl_ur             (cpl_ur),
    .cpl_crs            (cpl_crs),
    .cpl_ca             (cpl_ca),
    .cpl_data           (cpl_data),
    .cpl_mismatch       (cpl_mismatch),
  
    .ctl_state          (ctl_state),      
    .ctl_addr           (ctl_addr),    
    .ctl_data           (ctl_data),    
    .ctl_last_cfg       (ctl_last_cfg),        
    .ctl_skip_cpl       (ctl_skip_cpl)
  );


  pcie_cfg_tlp_encoder #(
    .REQUESTER_ID (REQUESTER_ID),
    .C_DATA_WIDTH (C_DATA_WIDTH),
    .KEEP_WIDTH   (KEEP_WIDTH)
  ) pcie_cfg_tlp_encoder_inst (
    // globals
    .user_clk             (user_clk),
    .reset                (reset),

    .pg_s_axis_rq_tready  (pg_s_axis_rq_tready),
    .pg_s_axis_rq_tdata   (pg_s_axis_rq_tdata),
    .pg_s_axis_rq_tkeep   (pg_s_axis_rq_tkeep),
    .pg_s_axis_rq_tuser   (pg_s_axis_rq_tuser),
    .pg_s_axis_rq_tlast   (pg_s_axis_rq_tlast),
    .pg_s_axis_rq_tvalid  (pg_s_axis_rq_tvalid),

    // Controller interface
    .pkt_type             (pkt_type),
    .pkt_func_num         (pkt_func_num),
    .pkt_reg_num          (pkt_reg_num),
    .pkt_1dw_be           (pkt_1dw_be),
    .pkt_msg_routing      (pkt_msg_routing),
    .pkt_msg_code         (pkt_msg_code),
    .pkt_data             (pkt_data),
    .pkt_start            (pkt_start),
    .pkt_done             (pkt_done)
  );


  // Configurator Tx Mux module
  pcie_cfg_tx_mux #(
    .C_DATA_WIDTH         (C_DATA_WIDTH),
    .KEEP_WIDTH           (KEEP_WIDTH)
  ) pcie_cfg_tx_mux_inst (
    // globals
    .user_clk                   (user_clk),
    .reset                      (reset),

    // User Tx AXIS interface
    .usr_s_axis_rq_tready       (usr_s_axis_rq_tready),
    .usr_s_axis_rq_tdata        (usr_s_axis_rq_tdata),
    .usr_s_axis_rq_tkeep        (usr_s_axis_rq_tkeep),
    .usr_s_axis_rq_tuser        (usr_s_axis_rq_tuser),
    .usr_s_axis_rq_tlast        (usr_s_axis_rq_tlast),
    .usr_s_axis_rq_tvalid       (usr_s_axis_rq_tvalid),

    // Packet Generator Tx interface
    .pg_s_axis_rq_tready        (pg_s_axis_rq_tready),
    .pg_s_axis_rq_tdata         (pg_s_axis_rq_tdata),
    .pg_s_axis_rq_tkeep         (pg_s_axis_rq_tkeep),
    .pg_s_axis_rq_tuser         (pg_s_axis_rq_tuser),
    .pg_s_axis_rq_tlast         (pg_s_axis_rq_tlast),
    .pg_s_axis_rq_tvalid        (pg_s_axis_rq_tvalid),

    // Root Port Wrapper Tx interface
    .rport_s_axis_rq_tready     (rport_s_axis_rq_tready),
    .rport_s_axis_rq_tdata      (rport_s_axis_rq_tdata),
    .rport_s_axis_rq_tkeep      (rport_s_axis_rq_tkeep),
    .rport_s_axis_rq_tuser      (rport_s_axis_rq_tuser),
    .rport_s_axis_rq_tlast      (rport_s_axis_rq_tlast),
    .rport_s_axis_rq_tvalid     (rport_s_axis_rq_tvalid),

    // Controller interface
    .config_mode                (config_mode),
    .config_mode_active         (config_mode_active)
  );


  // PCIe Configurator Completion Decoder module
  pcie_cfg_tlp_decoder #(
    .REQUESTER_ID   (REQUESTER_ID),
    .C_DATA_WIDTH   (C_DATA_WIDTH),
    .KEEP_WIDTH     (KEEP_WIDTH)
  ) pcie_cfg_tlp_decoder_inst (
    // globals
    .user_clk                 (user_clk),
    .reset                    (reset),

    // Root Port Wrapper Rx interface
    .rport_m_axis_rc_tdata    (rport_m_axis_rc_tdata),
    .rport_m_axis_rc_tkeep    (rport_m_axis_rc_tkeep),
    .rport_m_axis_rc_tlast    (rport_m_axis_rc_tlast),
    .rport_m_axis_rc_tvalid   (rport_m_axis_rc_tvalid),
    .rport_m_axis_rc_tready   (rport_m_axis_rc_tready),
    .rport_m_axis_rc_tuser    (rport_m_axis_rc_tuser),
    // User Rx AXIS interface
    .usr_m_axis_rc_tdata      (usr_m_axis_rc_tdata),
    .usr_m_axis_rc_tkeep      (usr_m_axis_rc_tkeep),
    .usr_m_axis_rc_tlast      (usr_m_axis_rc_tlast),
    .usr_m_axis_rc_tvalid     (usr_m_axis_rc_tvalid),
    .usr_m_axis_rc_tuser      (usr_m_axis_rc_tuser),

    // Controller interface
    .config_mode              (config_mode),
    .cpl_sc                   (cpl_sc),
    .cpl_ur                   (cpl_ur),
    .cpl_crs                  (cpl_crs),
    .cpl_ca                   (cpl_ca),
    .cpl_data                 (cpl_data),
    .cpl_mismatch             (cpl_mismatch),

    .icq_full(icq_full)
  );



endmodule

