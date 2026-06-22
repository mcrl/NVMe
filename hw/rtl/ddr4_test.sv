// PL DDR4 bring-up + self-test. Instantiates the ddr4_0 MIG IP (4 GB DDR4-2400, 256-bit AXI, ECC), waits for
// calibration, then runs a small AXI BIST (write a per-address pattern to 16 addresses spread across the 4 GB,
// read them back, count mismatches). Exposes a status word the host reads over a CSR so we can confirm DDR4
// calibration + real memory access on the board BEFORE wiring it into the NVMe data path.
//   ddr4_status = { 8'hD4, err_count[15:0], 5'b0, bist_pass, bist_done, cal_done }
module ddr4_test (
  input  logic        sys_clk_p,        // J19 300 MHz DDR4 ref clock
  input  logic        sys_clk_n,
  input  logic        rstn,             // active-low board reset (host_rstn)
  input  logic        stat_clk,         // host_bram_clk, for status read-back CDC
  output logic [31:0] ddr4_status,
  // DDR4 physical pins
  output logic [16:0] c0_ddr4_adr,
  output logic [1:0]  c0_ddr4_ba,
  output logic [0:0]  c0_ddr4_bg,
  output logic [0:0]  c0_ddr4_cke,
  output logic [0:0]  c0_ddr4_odt,
  output logic [0:0]  c0_ddr4_cs_n,
  output logic        c0_ddr4_act_n,
  output logic [0:0]  c0_ddr4_ck_t,
  output logic [0:0]  c0_ddr4_ck_c,
  output logic        c0_ddr4_reset_n,
  inout  wire  [71:0] c0_ddr4_dq,
  inout  wire  [8:0]  c0_ddr4_dqs_t,
  inout  wire  [8:0]  c0_ddr4_dqs_c,
  inout  wire  [8:0]  c0_ddr4_dm_dbi_n
);
  wire ui_clk, ui_rst, cal_done;
  // AXI (256-bit) master signals driven by the BIST
  logic [31:0] awaddr, araddr;  logic awvalid, wvalid, wlast, bready, arvalid, rready;
  logic [255:0] wdata;          wire awready, wready, bvalid, arready, rvalid, rlast;
  wire  [255:0] rdata;          wire [1:0] bresp, rresp;

  ddr4_0 u_ddr4 (
    .c0_init_calib_complete (cal_done),
    .dbg_clk(), .dbg_bus(),
    .c0_sys_clk_p(sys_clk_p), .c0_sys_clk_n(sys_clk_n), .sys_rst(~rstn),   // IP sys_rst is active-high
    .c0_ddr4_adr(c0_ddr4_adr), .c0_ddr4_ba(c0_ddr4_ba), .c0_ddr4_cke(c0_ddr4_cke),
    .c0_ddr4_cs_n(c0_ddr4_cs_n), .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n), .c0_ddr4_dq(c0_ddr4_dq),
    .c0_ddr4_dqs_c(c0_ddr4_dqs_c), .c0_ddr4_dqs_t(c0_ddr4_dqs_t), .c0_ddr4_odt(c0_ddr4_odt),
    .c0_ddr4_bg(c0_ddr4_bg), .c0_ddr4_reset_n(c0_ddr4_reset_n), .c0_ddr4_act_n(c0_ddr4_act_n),
    .c0_ddr4_ck_c(c0_ddr4_ck_c), .c0_ddr4_ck_t(c0_ddr4_ck_t),
    .c0_ddr4_ui_clk(ui_clk), .c0_ddr4_ui_clk_sync_rst(ui_rst), .c0_ddr4_aresetn(~ui_rst),
    // ECC AXI-Lite control port -- tie off
    .c0_ddr4_s_axi_ctrl_awvalid(1'b0), .c0_ddr4_s_axi_ctrl_awready(), .c0_ddr4_s_axi_ctrl_awaddr(32'd0),
    .c0_ddr4_s_axi_ctrl_wvalid(1'b0), .c0_ddr4_s_axi_ctrl_wready(), .c0_ddr4_s_axi_ctrl_wdata(32'd0),
    .c0_ddr4_s_axi_ctrl_bvalid(), .c0_ddr4_s_axi_ctrl_bready(1'b1), .c0_ddr4_s_axi_ctrl_bresp(),
    .c0_ddr4_s_axi_ctrl_arvalid(1'b0), .c0_ddr4_s_axi_ctrl_arready(), .c0_ddr4_s_axi_ctrl_araddr(32'd0),
    .c0_ddr4_s_axi_ctrl_rvalid(), .c0_ddr4_s_axi_ctrl_rready(1'b1), .c0_ddr4_s_axi_ctrl_rdata(),
    .c0_ddr4_s_axi_ctrl_rresp(), .c0_ddr4_interrupt(),
    // data AXI
    .c0_ddr4_s_axi_awid(4'd0), .c0_ddr4_s_axi_awaddr(awaddr), .c0_ddr4_s_axi_awlen(8'd0),
    .c0_ddr4_s_axi_awsize(3'd5), .c0_ddr4_s_axi_awburst(2'd1), .c0_ddr4_s_axi_awlock(1'b0),
    .c0_ddr4_s_axi_awcache(4'd0), .c0_ddr4_s_axi_awprot(3'd0), .c0_ddr4_s_axi_awqos(4'd0),
    .c0_ddr4_s_axi_awvalid(awvalid), .c0_ddr4_s_axi_awready(awready),
    .c0_ddr4_s_axi_wdata(wdata), .c0_ddr4_s_axi_wstrb(32'hFFFF_FFFF), .c0_ddr4_s_axi_wlast(wlast),
    .c0_ddr4_s_axi_wvalid(wvalid), .c0_ddr4_s_axi_wready(wready),
    .c0_ddr4_s_axi_bready(bready), .c0_ddr4_s_axi_bid(), .c0_ddr4_s_axi_bresp(bresp), .c0_ddr4_s_axi_bvalid(bvalid),
    .c0_ddr4_s_axi_arid(4'd0), .c0_ddr4_s_axi_araddr(araddr), .c0_ddr4_s_axi_arlen(8'd0),
    .c0_ddr4_s_axi_arsize(3'd5), .c0_ddr4_s_axi_arburst(2'd1), .c0_ddr4_s_axi_arlock(1'b0),
    .c0_ddr4_s_axi_arcache(4'd0), .c0_ddr4_s_axi_arprot(3'd0), .c0_ddr4_s_axi_arqos(4'd0),
    .c0_ddr4_s_axi_arvalid(arvalid), .c0_ddr4_s_axi_arready(arready),
    .c0_ddr4_s_axi_rready(rready), .c0_ddr4_s_axi_rlast(rlast), .c0_ddr4_s_axi_rvalid(rvalid),
    .c0_ddr4_s_axi_rresp(rresp), .c0_ddr4_s_axi_rid(), .c0_ddr4_s_axi_rdata(rdata)
  );

  // per-address test pattern (distinct per address index)
  function automatic logic [255:0] patt(input logic [3:0] idx);
    return {8{32'hDA7A_0000 + {28'd0, idx}}};
  endfunction
  // BIST FSM (ui_clk)
  typedef enum logic [2:0] {WAITCAL, WSET, DO_W, DO_B, DO_AR, DO_R, FIN} st_t;
  st_t st;
  logic [3:0]  idx;
  logic [15:0] errs;
  logic        bist_done, bist_pass, aw_done, w_done;
  logic [25:0] wdog;                              // per-transaction watchdog (~224 ms @300 MHz)
  wire [31:0] addr_of_idx = {1'b0, idx, 27'd0};   // idx<<27 -> 16 addresses 128 MB apart across 4 GB

  // AW and W are presented CONCURRENTLY (both valid, each dropped on its own ready) -- robust to slaves that
  // gate wready on a pending awvalid. errs = mismatch count on completion, or 0xFA0n if a channel hangs at
  // state n (2=W/AW, 3=B, 4=AR, 5=R) so the host can see where a stuck transaction stalled.
  always_ff @(posedge ui_clk) begin
    if (ui_rst) begin
      st<=WAITCAL; idx<=0; errs<=0; bist_done<=0; bist_pass<=0; wdog<=0; aw_done<=0; w_done<=0;
      awvalid<=0; wvalid<=0; wlast<=0; bready<=0; arvalid<=0; rready<=0; awaddr<=0; araddr<=0; wdata<=0;
    end else begin
      wdog <= wdog + 1'b1;                              // free-running; any state transition resets it to 0
      case (st)
        WAITCAL: if (cal_done) begin idx<=0; errs<=0; st<=WSET; wdog<=0; end
        WSET: begin                                      // present AW + W together
          awaddr<=addr_of_idx; wdata<=patt(idx); awvalid<=1; wvalid<=1; wlast<=1;
          aw_done<=0; w_done<=0; st<=DO_W; wdog<=0;
        end
        DO_W: begin
          if (awready) awvalid<=0;
          if (wready) begin wvalid<=0; wlast<=0; end
          if ((aw_done | awready) & (w_done | wready)) begin bready<=1; aw_done<=0; w_done<=0; st<=DO_B; wdog<=0; end
          else begin if (awready) aw_done<=1; if (wready) w_done<=1;
                     if (&wdog) begin errs<=16'hFA02; bist_done<=1; st<=FIN; end end
        end
        DO_B:  if (bvalid) begin bready<=0; araddr<=addr_of_idx; arvalid<=1; st<=DO_AR; wdog<=0; end
               else if (&wdog) begin errs<=16'hFA03; bist_done<=1; st<=FIN; end
        DO_AR: if (arready) begin arvalid<=0; rready<=1; st<=DO_R; wdog<=0; end
               else if (&wdog) begin errs<=16'hFA04; bist_done<=1; st<=FIN; end
        DO_R:  if (rvalid) begin rready<=0;
                 if (rdata !== patt(idx)) errs<=errs+1'b1;
                 if (idx==4'd15) begin bist_done<=1; bist_pass<=(errs==0) && (rdata===patt(idx)); st<=FIN; end
                 else begin idx<=idx+1'b1; st<=WSET; wdog<=0; end end
               else if (&wdog) begin errs<=16'hFA05; bist_done<=1; st<=FIN; end
        FIN: ;
      endcase
    end
  end

  // status read-back: stable after bist_done, so a 2-FF sync into stat_clk is fine
  (* ASYNC_REG="true" *) logic [31:0] stat_meta, stat_sync;
  wire [31:0] stat_ui = {8'hD4, errs, 5'd0, bist_pass, bist_done, cal_done};
  always_ff @(posedge stat_clk) begin stat_meta <= stat_ui; stat_sync <= stat_meta; end
  assign ddr4_status = stat_sync;
endmodule
