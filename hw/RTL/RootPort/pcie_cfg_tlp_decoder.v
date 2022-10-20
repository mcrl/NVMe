
(* DowngradeIPIdentifiedWarnings = "yes" *)
module pcie_cfg_tlp_decoder #(
    parameter [15:0]    REQUESTER_ID        = 16'h10EE,
    parameter           AXI4_RC_TUSER_WIDTH = 75,
    parameter           C_DATA_WIDTH        = 128,
    parameter           KEEP_WIDTH          = C_DATA_WIDTH / 32
  ) (
    input wire          user_clk,
    input wire          reset,

    // Root Port Wrapper Rx interface
    input  [C_DATA_WIDTH-1:0]     rport_m_axis_rc_tdata,
    input  [KEEP_WIDTH-1:0]       rport_m_axis_rc_tkeep,
    input                         rport_m_axis_rc_tlast,
    input                         rport_m_axis_rc_tvalid,
    output                        rport_m_axis_rc_tready,
    input  [AXI4_RC_TUSER_WIDTH-1:0] rport_m_axis_rc_tuser,

    // User Rx interface
    output reg [C_DATA_WIDTH-1:0]     usr_m_axis_rc_tdata,
    output reg [KEEP_WIDTH-1:0]       usr_m_axis_rc_tkeep,
    output reg                        usr_m_axis_rc_tlast,
    output reg                        usr_m_axis_rc_tvalid,
    output reg [AXI4_RC_TUSER_WIDTH-1:0] usr_m_axis_rc_tuser,

    // Controller interface
    input wire          config_mode,
    output reg          cpl_sc,
    output reg          cpl_ur,
    output reg          cpl_crs,
    output reg          cpl_ca,
    output reg [31:0]   cpl_data,
    output reg          cpl_mismatch
  );

  localparam EXTRA_PIPELINE = 1;

  // Bit-slicing positions for decoding header fields
  localparam FMT_TYPE_HI   = 30;
  localparam FMT_TYPE_LO   = 24;
  localparam CPL_STAT_HI   = 47;
  localparam CPL_STAT_LO   = 45;
  localparam CPL_DATA_HI   = 63;
  localparam CPL_DATA_LO   = 32;
  localparam REQ_ID_HI     = 31;
  localparam REQ_ID_LO     = 16;

  localparam CPL_DATA_HI_128 = 127;
  localparam CPL_DATA_LO_128 = 96;
  localparam REQ_ID_HI_128   = 95;
  localparam REQ_ID_LO_128   = 80;

  // Static field values for comparison
  localparam FMT_TYPE_CPLX = 6'b001010;
  localparam SC_STATUS     = 3'b000;
  localparam UR_STATUS     = 3'b001;
  localparam CRS_STATUS    = 3'b010;
  localparam CA_STATUS     = 3'b100;


  // Local variables
  reg    [C_DATA_WIDTH-1:0]   pipe_m_axis_rc_tdata;
  reg    [KEEP_WIDTH-1:0]     pipe_m_axis_rc_tkeep;
  reg                         pipe_m_axis_rc_tlast;
  reg                         pipe_m_axis_rc_tvalid;
  reg [AXI4_RC_TUSER_WIDTH-1:0] pipe_m_axis_rc_tuser;
  reg                         pipe_rx_np_ok;
  reg                         pipe_rsop;

  reg [C_DATA_WIDTH-1:0]  check_rd;
  reg         check_rsop;
  reg         check_rsrc_rdy;
  reg [2:0]   cpl_status;
  reg         cpl_detect;

  wire        sop;                   // Start of packet
  wire        check_cpl_cpld;
 
  // Dst rdy and rNP OK are always asserted to Root Port wrapper
  assign rport_m_axis_rc_tready = 1'b1;

  // start of packet generation
  assign sop = (rport_m_axis_rc_tuser[32] && rport_m_axis_rc_tvalid);

  // Data-path with one or two pipeline stages
  always @(posedge user_clk) begin
    if (reset) begin
      pipe_m_axis_rc_tdata   <= {C_DATA_WIDTH{1'b0}};
      pipe_m_axis_rc_tkeep   <= {KEEP_WIDTH{1'b0}};
      pipe_m_axis_rc_tlast   <= 1'b0;
      pipe_m_axis_rc_tvalid  <= 1'b0;
      pipe_m_axis_rc_tuser   <= {AXI4_RC_TUSER_WIDTH{1'b0}};
      pipe_rx_np_ok          <= 1'b0;
      pipe_rsop              <= 1'b0;

      usr_m_axis_rc_tdata    <= {C_DATA_WIDTH{1'b0}};
      usr_m_axis_rc_tkeep    <= {KEEP_WIDTH{1'b0}};
      usr_m_axis_rc_tlast    <= 1'b0;
      usr_m_axis_rc_tvalid   <= 1'b0;
      usr_m_axis_rc_tuser    <= {AXI4_RC_TUSER_WIDTH{1'b0}};

    end else begin

      pipe_m_axis_rc_tdata   <= rport_m_axis_rc_tdata;
      pipe_m_axis_rc_tkeep   <= rport_m_axis_rc_tkeep;
      pipe_m_axis_rc_tlast   <= rport_m_axis_rc_tlast;
      pipe_m_axis_rc_tvalid  <= rport_m_axis_rc_tvalid;
      pipe_m_axis_rc_tuser   <= rport_m_axis_rc_tuser;
      pipe_rsop              <= sop;

      usr_m_axis_rc_tdata    <= (EXTRA_PIPELINE == 1) ? pipe_m_axis_rc_tdata     : rport_m_axis_rc_tdata;
      usr_m_axis_rc_tkeep    <= (EXTRA_PIPELINE == 1) ? pipe_m_axis_rc_tkeep     : rport_m_axis_rc_tkeep;
      usr_m_axis_rc_tlast    <= (EXTRA_PIPELINE == 1) ? pipe_m_axis_rc_tlast     : rport_m_axis_rc_tlast;
      usr_m_axis_rc_tvalid   <= (EXTRA_PIPELINE == 1) ? (pipe_m_axis_rc_tvalid && !config_mode) :
                                                            (rport_m_axis_rc_tvalid && !config_mode);
      usr_m_axis_rc_tuser    <= (EXTRA_PIPELINE == 1) ? pipe_m_axis_rc_tuser     : rport_m_axis_rc_tuser;
    end
  end


  // Completion processing w/ extra pipeline stage
  always @* begin
    check_rd         = pipe_m_axis_rc_tdata;
    check_rsop       = pipe_rsop;
    check_rsrc_rdy   = pipe_m_axis_rc_tvalid;
  end

  assign check_cpl_cpld = (pipe_m_axis_rc_tkeep[3] && pipe_m_axis_rc_tuser[15]);

  // Process first 2 QW's of received TLP - Check for Cpl or CplD type and capture completion status
  always @(posedge user_clk) begin
    if (reset) begin
      cpl_status     <= 3'b000;
      cpl_detect     <= 1'b0;
      cpl_sc         <= 1'b0;
      cpl_ur         <= 1'b0;
      cpl_crs        <= 1'b0;
      cpl_ca         <= 1'b0;
      cpl_data       <= 32'd0;
      cpl_mismatch   <= 1'b0;
    end 
    else begin
      // Check for Start of Frame
      if (check_rsop && check_rsrc_rdy) begin

        if (check_rd[30]) begin
          cpl_detect     <= 1'b1;  
          
          // If requester ID matches, check Completion Status field
          if (check_rd[87:72] == REQUESTER_ID) begin
            cpl_sc       <= (check_rd[45:43] == SC_STATUS);
            cpl_ur       <= (check_rd[45:43] == UR_STATUS);
            cpl_crs      <= (check_rd[45:43] == CRS_STATUS);
            cpl_ca       <= (check_rd[45:43] == CA_STATUS);
            cpl_mismatch <= 1'b0;
          end 
          else begin
            cpl_sc       <= 1'b0;
            cpl_ur       <= 1'b0;
            cpl_crs      <= 1'b0;
            cpl_ca       <= 1'b0;
            cpl_mismatch <= 1'b1;
          end

          // Capture data
          if (check_cpl_cpld) begin
            cpl_data     <= check_rd[CPL_DATA_HI_128:CPL_DATA_LO_128];
          end
        end 

        // Not a Cpl or CplD TLP
        else begin
          cpl_data     <= {C_DATA_WIDTH{1'b0}};
          cpl_sc       <= 1'b0;
          cpl_ur       <= 1'b0;
          cpl_crs      <= 1'b0;
          cpl_ca       <= 1'b0;
          cpl_mismatch <= 1'b0;
        end
      end 

      // Not start-of-frame
      else begin
        cpl_data     <= {C_DATA_WIDTH{1'b0}};
        cpl_sc       <= 1'b0;
        cpl_ur       <= 1'b0;
        cpl_crs      <= 1'b0;
        cpl_ca       <= 1'b0;
        cpl_mismatch <= 1'b0;
      end
    end
  end

endmodule 

