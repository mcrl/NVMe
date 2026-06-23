// PL DDR4 wrapper. Instantiates the ddr4_0 MIG IP (4 GB DDR4-2400, 256-bit AXI, ECC) and exposes its user
// clock + calibration + the AXI4 slave so the NVMe data path (nvme_driver's ddr4_engine master) can read/write
// DRAM. (The earlier in-wrapper BIST proved cal + AXI on HW; it is replaced here by the real data path.)
// Unused AXI sidebands are tied to INCR / full-size / all-strobe; the master only drives addr/len/data/valid.
module ddr4_test (
  input  logic        sys_clk_p,        // J19 300 MHz DDR4 ref clock
  input  logic        sys_clk_n,
  input  logic        rstn,             // active-low board reset (host_rstn)
  output logic        ui_clk,           // DDR4 user clock -> data-path cp_clk
  output logic        ui_rst,           // sync reset in ui_clk
  output logic        cal_done,         // calibration complete
  // AXI4 slave (driven by nvme_driver's ddr4_engine master)
  input  logic [31:0] s_awaddr, input logic [7:0] s_awlen, input logic s_awvalid, output logic s_awready,
  input  logic [255:0] s_wdata, input logic s_wlast, input logic s_wvalid, output logic s_wready,
  output logic [1:0]  s_bresp, output logic s_bvalid, input logic s_bready,
  input  logic [31:0] s_araddr, input logic [7:0] s_arlen, input logic s_arvalid, output logic s_arready,
  output logic [255:0] s_rdata, output logic s_rlast, output logic s_rvalid, input logic s_rready, output logic [1:0] s_rresp,
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
    // data AXI slave  (sidebands tied: INCR, 32-byte size, all strobes, id 0)
    .c0_ddr4_s_axi_awid(4'd0), .c0_ddr4_s_axi_awaddr(s_awaddr), .c0_ddr4_s_axi_awlen(s_awlen),
    .c0_ddr4_s_axi_awsize(3'd5), .c0_ddr4_s_axi_awburst(2'd1), .c0_ddr4_s_axi_awlock(1'b0),
    .c0_ddr4_s_axi_awcache(4'd0), .c0_ddr4_s_axi_awprot(3'd0), .c0_ddr4_s_axi_awqos(4'd0),
    .c0_ddr4_s_axi_awvalid(s_awvalid), .c0_ddr4_s_axi_awready(s_awready),
    .c0_ddr4_s_axi_wdata(s_wdata), .c0_ddr4_s_axi_wstrb(32'hFFFF_FFFF), .c0_ddr4_s_axi_wlast(s_wlast),
    .c0_ddr4_s_axi_wvalid(s_wvalid), .c0_ddr4_s_axi_wready(s_wready),
    .c0_ddr4_s_axi_bready(s_bready), .c0_ddr4_s_axi_bid(), .c0_ddr4_s_axi_bresp(s_bresp), .c0_ddr4_s_axi_bvalid(s_bvalid),
    .c0_ddr4_s_axi_arid(4'd0), .c0_ddr4_s_axi_araddr(s_araddr), .c0_ddr4_s_axi_arlen(s_arlen),
    .c0_ddr4_s_axi_arsize(3'd5), .c0_ddr4_s_axi_arburst(2'd1), .c0_ddr4_s_axi_arlock(1'b0),
    .c0_ddr4_s_axi_arcache(4'd0), .c0_ddr4_s_axi_arprot(3'd0), .c0_ddr4_s_axi_arqos(4'd0),
    .c0_ddr4_s_axi_arvalid(s_arvalid), .c0_ddr4_s_axi_arready(s_arready),
    .c0_ddr4_s_axi_rready(s_rready), .c0_ddr4_s_axi_rlast(s_rlast), .c0_ddr4_s_axi_rvalid(s_rvalid),
    .c0_ddr4_s_axi_rresp(s_rresp), .c0_ddr4_s_axi_rid(), .c0_ddr4_s_axi_rdata(s_rdata)
  );
endmodule
