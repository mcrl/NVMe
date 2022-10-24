
(* DowngradeIPIdentifiedWarnings = "yes" *)
module user_tlp_decoder #(
    parameter           TCQ                 = 1,
    parameter           AXI4_RC_TUSER_WIDTH = 75,
    parameter [15:0]    REQUESTER_ID        = 16'h10EE,
    parameter           C_DATA_WIDTH        = 64,
    parameter           KEEP_WIDTH          = C_DATA_WIDTH / 32
  ) (
    // globals
    input wire                  user_clk,
    input wire                  reset,

    // Rx - AXI-S Requester Completion Interface
    input  [C_DATA_WIDTH-1:0]   m_axis_rc_tdata,
    input  [KEEP_WIDTH-1:0]     m_axis_rc_tkeep,
    input                       m_axis_rc_tlast,
    input                       m_axis_rc_tvalid,
    input  [AXI4_RC_TUSER_WIDTH-1:0] m_axis_rc_tuser,

    // Controller interface
    input wire                  rx_type, 
    input wire [7:0]            rx_tag,
    input wire [31:0]           rx_data,
    output reg                  rx_good,
    output reg                  rx_bad
  );

  // Bit-slicing positions
  localparam FMT_TYPE_HI   = 30;
  localparam FMT_TYPE_LO   = 24;
  localparam CPL_STAT_HI   = 47;
  localparam CPL_STAT_LO   = 45;

  localparam CPL_DATA_HI   = 63;
  localparam CPL_DATA_LO   = 32;
  localparam REQ_ID_HI     = 31;
  localparam REQ_ID_LO     = 16;
  localparam TAG_HI        = 15;
  localparam TAG_LO        = 8;

  localparam CPL_DATA_HI_128   = 127;
  localparam CPL_DATA_LO_128   = 96;
  localparam REQ_ID_HI_128     = 95;
  localparam REQ_ID_LO_128     = 80;
  localparam TAG_HI_128        = 79;
  localparam TAG_LO_128        = 72;

  // Static field values for comparison
  localparam FMT_TYPE_CPLX = 6'b001010;
  localparam SC_STATUS     = 3'b000;
  localparam UR_STATUS     = 3'b001;
  localparam CRS_STATUS    = 3'b010;
  localparam CA_STATUS     = 3'b100;

  // TLP type encoding for rx_type - same as high bit of Format field
  localparam RX_TYPE_CPL   = 1'b0;
  localparam RX_TYPE_CPLD  = 1'b1;
  localparam DW_SEL_WIDTH  = (C_DATA_WIDTH==512)? 4 : (C_DATA_WIDTH==256)? 3 : (C_DATA_WIDTH==128) ? 2 : 1;

  // Local registers for processing incoming completions
  reg     cpl_status_good;
  reg     cpl_type_match;
  reg     cpl_detect;
  reg     cpl_detect_q;
  reg     cpl_detect_qq;
  reg     cpl_data_match;
  reg     cpl_reqid_match;
  reg     cpl_tag_match;
  reg [DW_SEL_WIDTH-1:0] dword_sel;       

  wire    sop;                   // Start of packet

  // start of packet generation 
  assign sop = (m_axis_rc_tuser[32] && m_axis_rc_tvalid);

  
  always @(posedge user_clk) begin
    if (reset) begin
      cpl_status_good   <= 1'b0;
      cpl_type_match    <= 1'b0;
      cpl_detect        <= 1'b0;
      cpl_data_match    <= 1'b0;
      cpl_reqid_match   <= 1'b0;
      cpl_tag_match     <= 1'b0;
      cpl_detect_q      <= 1'b0;
    end 
    else begin
      cpl_detect_q      <= cpl_detect;
      if (sop) begin
        cpl_data_match  <= (m_axis_rc_tdata[127:96] == rx_data);
      end 
      else begin
        cpl_data_match  <= 1'b0;
      end

      if (sop) begin
        // Check for beginning of Completion TLP and process entire packet in 1 clock
	      dword_sel <= m_axis_rc_tdata[3:2];
        if (m_axis_rc_tdata[30]) begin
          cpl_detect     <= 1'b1;
        end else begin
          cpl_detect     <= 1'b0;
        end

        // Compare type and completion status with expected
        cpl_reqid_match <= (m_axis_rc_tdata[87:72] == REQUESTER_ID);
        cpl_tag_match   <= (m_axis_rc_tdata[71:64] == rx_tag);
        cpl_status_good <= (m_axis_rc_tdata[45:43] == SC_STATUS);

        if ((m_axis_rc_tkeep[3] && m_axis_rc_tuser[15]) == rx_type) begin
              cpl_type_match   <= 1'b1; 
        end
      end 
      else begin
	      dword_sel <= 2'b00;
        cpl_status_good   <= 1'b0;
        cpl_type_match    <= 1'b0;
        cpl_detect        <= 1'b0;
        cpl_reqid_match   <= 1'b0;
        cpl_tag_match     <= 1'b0;
      end
    end
  end

  // After TLP is processed, check whether all fields matched expected and output results
  always @(posedge user_clk) begin
    if (reset) begin
      rx_good           <= 1'b0;
      rx_bad            <= 1'b0;
    end else begin
      if (cpl_detect) begin
        if (cpl_type_match && cpl_status_good) begin
          if (cpl_data_match || (rx_type == RX_TYPE_CPL)) begin
            // Header and data match, or header match and no data expected
            rx_good      <= 1'b1;
          end else begin
            // Data mismatch
            rx_bad       <= 1'b1;
          end
        end else begin
          // Header mismatch
          rx_bad         <= 1'b1;
        end
      end else begin
        // Not checking this cycle
        rx_good          <= 1'b0;
        rx_bad           <= 1'b0;
      end
    end
  end


endmodule 
