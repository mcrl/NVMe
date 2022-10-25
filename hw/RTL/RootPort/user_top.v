
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

    input [11:0]  addr_offset,
    input [1:0]   vio_length,
    output        icq_full    
  );

  // Controller <-> Packet Generator
  wire [2:0]    tx_type;
  wire [7:0]    tx_tag;
  wire [63:0]   tx_addr;
  wire [127:0]  tx_data;
  wire [10:0]   tx_length;
  wire          tx_start;
  wire          tx_done;

  // Controller <-> Checker
  wire          rx_type;
  wire [7:0]    rx_tag;
  wire [31:0]   rx_data;
  wire          rx_success;
  wire          rx_fail;

  // Encoder <-> I/O Submission Queue
  wire [C_DATA_WIDTH-1:0]         wr_s_axis_rq_tdata;
  wire [KEEP_WIDTH-1:0]           wr_s_axis_rq_tkeep;
  wire                            wr_s_axis_rq_tlast;
  wire                            wr_s_axis_rq_tvalid;
  wire [AXI4_RQ_TUSER_WIDTH-1:0]  wr_s_axis_rq_tuser;

  // Encoder <-> I/O Completion Queue
  wire [C_DATA_WIDTH-1:0]         rd_m_axis_rc_tdata;
  wire [KEEP_WIDTH-1:0]           rd_m_axis_rc_tkeep;
  wire                            rd_m_axis_rc_tlast;
  wire                            rd_m_axis_rc_tvalid;
  wire [AXI4_RC_TUSER_WIDTH-1:0]  rd_m_axis_rc_tuser;


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

    // Control of Configurator
    .start_config       (start_config),
    .finished_config    (finished_config),
    .failed_config      (failed_config),

    // Packet generator interface
    .tx_type            (tx_type),
    .tx_tag             (tx_tag),
    .tx_addr            (tx_addr),
    .tx_data            (tx_data),
    //.tx_length          (tx_length),
    .tx_length          ({9'd0, vio_length}),
    .tx_start           (tx_start),
    .tx_done            (tx_done),

    // Checker interface
    .rx_type            (rx_type),
    .rx_tag             (rx_tag),
    .rx_data            (rx_data),
    .rx_success            (rx_success),
    .rx_fail             (rx_fail),
    
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
    .s_axis_rq_tdata        (wr_s_axis_rq_tdata ),
    .s_axis_rq_tkeep        (wr_s_axis_rq_tkeep ),
    .s_axis_rq_tuser        (wr_s_axis_rq_tuser ),
    .s_axis_rq_tlast        (wr_s_axis_rq_tlast ),
    .s_axis_rq_tvalid       (wr_s_axis_rq_tvalid ),

    // Controller interface
    .tx_type                (tx_type),
    .tx_tag                 (tx_tag),
    .tx_addr                (tx_addr),
    .tx_data                (tx_data),
    .tx_length              (tx_length),
    .tx_start               (tx_start),
    .tx_done                (tx_done)
  );

  user_isq #(
    .AXI4_RQ_TUSER_WIDTH  (AXI4_RQ_TUSER_WIDTH),
    .C_DATA_WIDTH         (C_DATA_WIDTH),
    .KEEP_WIDTH           (KEEP_WIDTH)
  ) user_isq_inst (
    .user_clk(user_clk),
    .user_reset(user_reset),
    .user_lnk_up(user_lnk_up),
    .s_axis_rq_tready(s_axis_rq_tready),
    .wr_s_axis_rq_tdata  (wr_s_axis_rq_tdata),
    .wr_s_axis_rq_tkeep  (wr_s_axis_rq_tkeep),
    .wr_s_axis_rq_tlast  (wr_s_axis_rq_tlast),
    .wr_s_axis_rq_tvalid (wr_s_axis_rq_tvalid),
    .wr_s_axis_rq_tuser  (wr_s_axis_rq_tuser),
    .rd_s_axis_rq_tdata  (s_axis_rq_tdata),
    .rd_s_axis_rq_tkeep  (s_axis_rq_tkeep),
    .rd_s_axis_rq_tlast  (s_axis_rq_tlast),
    .rd_s_axis_rq_tvalid (s_axis_rq_tvalid),
    .rd_s_axis_rq_tuser  (s_axis_rq_tuser)
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
    .m_axis_rc_tdata        (rd_m_axis_rc_tdata ),
    .m_axis_rc_tkeep        (rd_m_axis_rc_tkeep ),
    .m_axis_rc_tlast        (rd_m_axis_rc_tlast ),
    .m_axis_rc_tvalid       (rd_m_axis_rc_tvalid ),
    .m_axis_rc_tuser        (rd_m_axis_rc_tuser ),

    // Controller interface
    .rx_type                (rx_type),
    .rx_tag                 (rx_tag),
    .rx_data                (rx_data),
    .rx_success                (rx_success),
    .rx_fail                 (rx_fail)
  );


  user_icq #(
    .AXI4_RC_TUSER_WIDTH  (AXI4_RC_TUSER_WIDTH),
    .C_DATA_WIDTH         (C_DATA_WIDTH),
    .KEEP_WIDTH           (KEEP_WIDTH)
  ) user_icq_inst (
    .user_clk(user_clk),
    .user_reset(user_reset),
    .user_lnk_up(user_lnk_up),
    .wr_m_axis_rc_tdata  (m_axis_rc_tdata),
    .wr_m_axis_rc_tkeep  (m_axis_rc_tkeep),
    .wr_m_axis_rc_tlast  (m_axis_rc_tlast),
    .wr_m_axis_rc_tvalid (m_axis_rc_tvalid),
    .wr_m_axis_rc_tuser  (m_axis_rc_tuser),
    .rd_m_axis_rc_tdata  (rd_m_axis_rc_tdata),
    .rd_m_axis_rc_tkeep  (rd_m_axis_rc_tkeep),
    .rd_m_axis_rc_tlast  (rd_m_axis_rc_tlast),
    .rd_m_axis_rc_tvalid (rd_m_axis_rc_tvalid),
    .rd_m_axis_rc_tuser  (rd_m_axis_rc_tuser),
    .icq_full            (icq_full)
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
    .probe11(m_axis_rc_tuser),  // 75bit
    .probe12(tx_type),  // 3bit
    .probe13(tx_tag),   // 8bit
    .probe14(tx_addr),  // 64bit
    .probe15(tx_data[31:0]),  // 32bit
    .probe16(tx_start), // 1bit
    .probe17(tx_done),  // 1bit
    .probe18(rx_type),  // 1bit
    .probe19(rx_tag),   // 8bit
    .probe20(rx_data),  // 32bit
    .probe21(rx_success),  // 1bit
    .probe22(rx_fail)    // 1bit
  );

endmodule


