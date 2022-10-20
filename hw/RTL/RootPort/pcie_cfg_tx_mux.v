
(* DowngradeIPIdentifiedWarnings = "yes" *)
module pcie_cfg_tx_mux #(
    parameter AXI4_RQ_TUSER_WIDTH      = 62,
    parameter C_DATA_WIDTH             = 128,
    parameter KEEP_WIDTH               = C_DATA_WIDTH / 32
  ) (
    input wire                            user_clk,
    input wire                            reset,

    output                                usr_s_axis_rq_tready,
    input  [C_DATA_WIDTH-1:0]             usr_s_axis_rq_tdata,
    input  [KEEP_WIDTH-1:0]               usr_s_axis_rq_tkeep,
    input  [AXI4_RQ_TUSER_WIDTH-1:0]      usr_s_axis_rq_tuser,
    input                                 usr_s_axis_rq_tlast,
    input                                 usr_s_axis_rq_tvalid,

    // Packet Generator Tx interface
    output                                pg_s_axis_rq_tready,
    input  [C_DATA_WIDTH-1:0]             pg_s_axis_rq_tdata,
    input  [KEEP_WIDTH-1:0]               pg_s_axis_rq_tkeep,
    input  [AXI4_RQ_TUSER_WIDTH-1:0]      pg_s_axis_rq_tuser,
    input                                 pg_s_axis_rq_tlast,
    input                                 pg_s_axis_rq_tvalid,

    // Root Port Wrapper Tx interface
    input                                 rport_s_axis_rq_tready,
    output reg [C_DATA_WIDTH-1:0]         rport_s_axis_rq_tdata,
    output reg [KEEP_WIDTH-1:0]           rport_s_axis_rq_tkeep,
    output reg [AXI4_RQ_TUSER_WIDTH-1:0]  rport_s_axis_rq_tuser,
    output reg                            rport_s_axis_rq_tlast,
    output reg                            rport_s_axis_rq_tvalid,

    // Controller interface
    input wire                            config_mode,
    output reg                            config_mode_active
  );

  wire    usr_active_start;
  wire    usr_active_end;
  reg     usr_active;
  reg     usr_holdoff;
  wire    sop;                   // Start of packet
  reg     in_packet_q;


  // Generate a signal that indicates if we are currently receiving a packet.
  // This value is one clock cycle delayed from what is actually on the AXIS data bus.
  always@(posedge user_clk) begin
    if(reset)
      in_packet_q <= 1'b0;
    else if (usr_s_axis_rq_tvalid && usr_s_axis_rq_tready && usr_s_axis_rq_tlast)
      in_packet_q <= 1'b0;
    else if (sop && usr_s_axis_rq_tready)
      in_packet_q <= 1'b1;
  end

  assign sop = (!in_packet_q && usr_s_axis_rq_tvalid);

  // Determine when user is in the middle of a Tx TLP
  assign usr_active_start = sop && usr_s_axis_rq_tvalid && usr_s_axis_rq_tready;
  assign usr_active_end   = usr_s_axis_rq_tlast && usr_s_axis_rq_tvalid && usr_s_axis_rq_tready;
  always @(posedge user_clk) begin
    if (reset) begin
      usr_active        <= 1'b0;
    end else begin
      if (usr_active_start) begin
        usr_active      <= 1'b1;
      end else if (usr_active_end) begin
        usr_active      <= 1'b0;
      end
    end
  end

  //  usr_holdoff is asserted. This can happen when:
  //    - config mode is asserted
  always @(posedge user_clk) begin
    if (reset) begin
      usr_holdoff       <= 1'b1;
    end else begin
      if ((!usr_active && !usr_active_start) ||
          (usr_active && usr_active_end)) begin
        if (config_mode || usr_active_end) begin
          usr_holdoff   <= 1'b1;
        end else begin
          usr_holdoff   <= 1'b0;
        end

      end else begin
        usr_holdoff     <= 1'b0;
      end
    end
  end

  // Deassert usr_s_axis_rq_tready when above logic determines user cannot transmit,
  // or when Root Port is not accepting data
  assign usr_s_axis_rq_tready = rport_s_axis_rq_tready && !usr_holdoff;

  // Accept entry to config mode when config_mode is asserted and user
  // has finished any outstanding Tx TLP
  always @(posedge user_clk) begin
    if (reset) begin
      config_mode_active  <= 1'b0;
    end else begin
      config_mode_active  <= config_mode && usr_holdoff;
    end
  end

  // tx_tready to Packet Generator is the same as usr_s_axis_tx_tready when
  // config_mode_active is asserted
  assign pg_s_axis_rq_tready = rport_s_axis_rq_tready && config_mode_active;

  // Data-path mux with one pipeline stage
  always @(posedge user_clk) begin
    if (reset) begin
      rport_s_axis_rq_tdata     <= {C_DATA_WIDTH{1'b0}};
      rport_s_axis_rq_tkeep     <= {KEEP_WIDTH{1'b0}};
      rport_s_axis_rq_tuser     <=  'b0;
      rport_s_axis_rq_tlast     <= 1'b0;
      rport_s_axis_rq_tvalid    <= 1'b0;
    end 
    else begin
      if (config_mode_active) begin
        rport_s_axis_rq_tdata     <= pg_s_axis_rq_tdata;
        rport_s_axis_rq_tkeep     <= pg_s_axis_rq_tkeep;
        rport_s_axis_rq_tuser     <= pg_s_axis_rq_tuser;
        rport_s_axis_rq_tlast     <= pg_s_axis_rq_tlast;
        rport_s_axis_rq_tvalid    <= pg_s_axis_rq_tvalid  && pg_s_axis_rq_tready;
      end else begin
        rport_s_axis_rq_tdata     <= usr_s_axis_rq_tdata;
        rport_s_axis_rq_tkeep     <= usr_s_axis_rq_tkeep;
        rport_s_axis_rq_tuser     <= usr_s_axis_rq_tuser[AXI4_RQ_TUSER_WIDTH-1:0];
        rport_s_axis_rq_tlast     <= usr_s_axis_rq_tlast;
        rport_s_axis_rq_tvalid    <= usr_s_axis_rq_tvalid  && usr_s_axis_rq_tready;
      end
    end
  end

endmodule // cgator_tx_mux