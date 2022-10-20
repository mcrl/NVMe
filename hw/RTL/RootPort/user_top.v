
(* DowngradeIPIdentifiedWarnings = "yes" *)
module user_top #(
    // Configurator Parameter
    parameter [15:0]    REQUESTER_ID = 16'h01A0,

    // BAR A settings
    parameter           BAR_A_ENABLED   = 1,
    parameter           BAR_A_64BIT     = 0,
    parameter           BAR_A_IO        = 0,
    parameter [31:0]    BAR_A_BASE      = 32'h1000_0000,
    parameter           BAR_A_SIZE      = 1024, // Size in DW

    // AXIS Parameters
    parameter       AXI4_RQ_TUSER_WIDTH = 62,
    parameter       AXI4_RC_TUSER_WIDTH = 75,
    parameter       C_DATA_WIDTH        = 128,
    parameter       KEEP_WIDTH          = C_DATA_WIDTH / 32
  )
  (
    input wire                user_clk,
    input wire                reset,
    input wire                user_lnk_up,

    // System information
    input wire                pio_test_restart,
    output wire               pio_test_finished,
    output wire               pio_test_failed,

    // Control configuration process
    output wire               start_config,
    input wire                finished_config,
    input wire                failed_config,

    // Tx - AXI-S Requester Request Interface
    input                     s_axis_rq_tready,
    output [C_DATA_WIDTH-1:0] s_axis_rq_tdata,
    output   [KEEP_WIDTH-1:0] s_axis_rq_tkeep,
    output                    s_axis_rq_tlast,
    output                    s_axis_rq_tvalid,
    output [AXI4_RQ_TUSER_WIDTH-1:0] s_axis_rq_tuser,

    // Rx - AXI-S Requester Completion Interface
    input [C_DATA_WIDTH-1:0]  m_axis_rc_tdata,
    input   [KEEP_WIDTH-1:0]  m_axis_rc_tkeep,
    input                     m_axis_rc_tlast,
    input                     m_axis_rc_tvalid,
    input [AXI4_RC_TUSER_WIDTH-1:0] m_axis_rc_tuser,

    input [7:0]  addr_offset    
  );

  // Controller <-> Packet Generator
  wire [2:0]    tx_type;
  wire [7:0]    tx_tag;
  wire [63:0]   tx_addr;
  wire [31:0]   tx_data;
  wire          tx_start;
  wire          tx_done;

  // Controller <-> Checker
  wire          rx_type;
  wire [7:0]    rx_tag;
  wire [31:0]   rx_data;
  wire          rx_good;
  wire          rx_bad;

  // User Module Controller - controls the read/write/verify process
  user_controller #(
    .BAR_A_ENABLED (BAR_A_ENABLED),
    .BAR_A_64BIT   (BAR_A_64BIT),
    .BAR_A_IO      (BAR_A_IO),
    .BAR_A_BASE    (BAR_A_BASE),
    .BAR_A_SIZE    (BAR_A_SIZE)
  ) user_controller_inst (
    // System inputs
    .user_clk           (user_clk),
    .reset              (reset),
    .user_lnk_up        (user_lnk_up),

    // Board-level control/status
    .pio_test_restart   (pio_test_restart),
    .pio_test_finished  (pio_test_finished),
    .pio_test_failed    (pio_test_failed),

    // Control of Configurator
    .start_config       (start_config),
    .finished_config    (finished_config),
    .failed_config      (failed_config),

    // Packet generator interface
    .tx_type            (tx_type),
    .tx_tag             (tx_tag),
    .tx_addr            (tx_addr),
    .tx_data            (tx_data),
    .tx_start           (tx_start),
    .tx_done            (tx_done),

    // Checker interface
    .rx_type            (rx_type),
    .rx_tag             (rx_tag),
    .rx_data            (rx_data),
    .rx_good            (rx_good),
    .rx_bad             (rx_bad),
    
    // for debugging
    .addr_offset (addr_offset)
  );


  user_tlp_encoder #(
    .REQUESTER_ID   (REQUESTER_ID),
    .C_DATA_WIDTH   (C_DATA_WIDTH),
    .KEEP_WIDTH     (KEEP_WIDTH)
  ) user_tlp_encoder_inst (
    // globals
    .user_clk               (user_clk),
    .reset                  (reset),

    // Tx - AXI-S Requester Request Interface
    .s_axis_rq_tready       (s_axis_rq_tready ),
    .s_axis_rq_tdata        (s_axis_rq_tdata ),
    .s_axis_rq_tkeep        (s_axis_rq_tkeep ),
    .s_axis_rq_tuser        (s_axis_rq_tuser ),
    .s_axis_rq_tlast        (s_axis_rq_tlast ),
    .s_axis_rq_tvalid       (s_axis_rq_tvalid ),


    // Controller interface
    .tx_type                (tx_type),
    .tx_tag                 (tx_tag),
    .tx_addr                (tx_addr),
    .tx_data                (tx_data),
    .tx_start               (tx_start),
    .tx_done                (tx_done)
  );


  user_tlp_decoder #(
    .REQUESTER_ID   (REQUESTER_ID),
    .C_DATA_WIDTH   (C_DATA_WIDTH),
    .KEEP_WIDTH     (KEEP_WIDTH)
  ) user_tlp_decoder_inst (
    // globals
    .user_clk               (user_clk),
    .reset                  (reset),

    // Rx - AXI-S Requester Completion Interface
    .m_axis_rc_tdata        (m_axis_rc_tdata ),
    .m_axis_rc_tkeep        (m_axis_rc_tkeep ),
    .m_axis_rc_tlast        (m_axis_rc_tlast ),
    .m_axis_rc_tvalid       (m_axis_rc_tvalid ),
    .m_axis_rc_tuser        (m_axis_rc_tuser ),

    // Controller interface
    .rx_type                (rx_type),
    .rx_tag                 (rx_tag),
    .rx_data                (rx_data),
    .rx_good                (rx_good),
    .rx_bad                 (rx_bad)
  );

  
  ila_1 ila_1_inst (
    .clk(user_clk),             // input wire clk
    .probe0(finished_config),   // trigger
    .probe1(s_axis_rq_tready),  // 1bit
    .probe2(s_axis_rq_tdata),   // 128bit
    .probe3(s_axis_rq_tkeep),   // 4bit
    .probe4(s_axis_rq_tlast),   // 1bit
    .probe5(s_axis_rq_tvalid),  // 1bit
    .probe6(s_axis_rq_tuser),   // 62bit
    .probe7(m_axis_rc_tdata),   // 128bit
    .probe8(m_axis_rc_tkeep),   // 4bit
    .probe9(m_axis_rc_tlast),   // 1bit
    .probe10(m_axis_rc_tvalid), // 1bit
    .probe11(m_axis_rc_tuser)   // 75bit
  );

endmodule // pio_master


