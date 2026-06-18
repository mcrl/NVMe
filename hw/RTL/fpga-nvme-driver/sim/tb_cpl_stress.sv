// Focused stress: hammer the m_axi WRITE channel with back-to-back CQE writes and check that
// every one is counted (cpl_count). Reproduces the high-QD completion-capture miss without a full
// NVMe bringup -- the cpl/W-acceptor counts any CQE-class AW+W regardless of queue state.
`timescale 1ns/1ps
module tb_cpl_stress;
  logic oculink_axi_clk = 0, host_bram_clk = 0, rstn = 0;
  always #4 oculink_axi_clk = ~oculink_axi_clk;   // 125 MHz
  always #2 host_bram_clk   = ~host_bram_clk;     // 250 MHz

  // host side tied off (no NVMe commands in this test)
  logic [31:0] nvme_addr=0, fpga_addr=0, nlb=0, cpl_status, cpl_count;
  logic        cpl_done;
  logic [31:0] wrdata [7:0]; logic [31:0] rddata [7:0];

  // s_axi (DUT master -> us): accept doorbell writes the db FSM emits (CQ-head rings) and ack B
  logic        s_awready, s_wready, s_bvalid; logic [3:0] s_bid; logic [1:0] s_bresp;
  logic [31:0] s_awaddr; logic [1:0] s_awburst; logic [3:0] s_awid; logic [7:0] s_awlen;
  logic [3:0]  s_awregion; logic [2:0] s_awsize; logic s_awvalid;
  logic [255:0] s_wdata; logic s_wlast; logic [31:0] s_wstrb; logic s_wvalid; logic s_bready;
  assign s_awready = 1'b1; assign s_wready = 1'b1; assign s_bid = 0; assign s_bresp = 0;
  always_ff @(posedge oculink_axi_clk) s_bvalid <= s_wvalid & s_wlast;  // ack 1 cycle after W

  // m_axi (we master into the DUT)
  logic        m_arready; logic [31:0] m_araddr=0; logic [1:0] m_arburst=1; logic [3:0] m_arcache=0;
  logic [3:0]  m_arid=0; logic [7:0] m_arlen=0; logic m_arlock=0; logic [2:0] m_arprot=0,m_arsize=5; logic m_arvalid=0;
  logic        m_awready; logic [31:0] m_awaddr=0; logic [1:0] m_awburst=1; logic [3:0] m_awcache=0;
  logic [3:0]  m_awid=0; logic [7:0] m_awlen=0; logic m_awlock=0; logic [2:0] m_awprot=0,m_awsize=5; logic m_awvalid=0;
  logic        m_wready; logic [255:0] m_wdata=0; logic m_wlast=0; logic [31:0] m_wstrb='1; logic m_wvalid=0;
  logic        m_rready=1; logic [255:0] m_rdata; logic [3:0] m_rid; logic m_rlast; logic [1:0] m_rresp; logic m_rvalid;
  logic        m_bready=1; logic [3:0] m_bid; logic [1:0] m_bresp; logic m_bvalid;

  localparam IOCQ_BAR = 32'hA000;

  nvme_driver dut (
    .rstn(rstn), .host_bram_clk(host_bram_clk), .oculink_axi_clk(oculink_axi_clk),
    .send_iocq_create_cmd(1'b0), .send_iosq_create_cmd(1'b0), .send_read_cmd(1'b0), .send_write_cmd(1'b0),
    .nvme_addr(nvme_addr), .fpga_addr(fpga_addr), .nlb(nlb),
    .cpl_done(cpl_done), .wrdata(wrdata), .rddata(rddata), .cpl_status(cpl_status), .cpl_count(cpl_count),
    .oculink_s_axi_awready(s_awready), .oculink_s_axi_awaddr(s_awaddr), .oculink_s_axi_awburst(s_awburst),
    .oculink_s_axi_awid(s_awid), .oculink_s_axi_awlen(s_awlen), .oculink_s_axi_awregion(s_awregion),
    .oculink_s_axi_awsize(s_awsize), .oculink_s_axi_awvalid(s_awvalid), .oculink_s_axi_wready(s_wready),
    .oculink_s_axi_wdata(s_wdata), .oculink_s_axi_wlast(s_wlast), .oculink_s_axi_wstrb(s_wstrb),
    .oculink_s_axi_wvalid(s_wvalid), .oculink_s_axi_bready(s_bready), .oculink_s_axi_bid(s_bid),
    .oculink_s_axi_bresp(s_bresp), .oculink_s_axi_bvalid(s_bvalid),
    .oculink_m_axi_arready(m_arready), .oculink_m_axi_araddr(m_araddr), .oculink_m_axi_arburst(m_arburst),
    .oculink_m_axi_arcache(m_arcache), .oculink_m_axi_arid(m_arid), .oculink_m_axi_arlen(m_arlen),
    .oculink_m_axi_arlock(m_arlock), .oculink_m_axi_arprot(m_arprot), .oculink_m_axi_arsize(m_arsize),
    .oculink_m_axi_arvalid(m_arvalid), .oculink_m_axi_awready(m_awready), .oculink_m_axi_awaddr(m_awaddr),
    .oculink_m_axi_awburst(m_awburst), .oculink_m_axi_awcache(m_awcache), .oculink_m_axi_awid(m_awid),
    .oculink_m_axi_awlen(m_awlen), .oculink_m_axi_awlock(m_awlock), .oculink_m_axi_awprot(m_awprot),
    .oculink_m_axi_awsize(m_awsize), .oculink_m_axi_awvalid(m_awvalid), .oculink_m_axi_wready(m_wready),
    .oculink_m_axi_wdata(m_wdata), .oculink_m_axi_wlast(m_wlast), .oculink_m_axi_wstrb(m_wstrb),
    .oculink_m_axi_wvalid(m_wvalid), .oculink_m_axi_rready(m_rready), .oculink_m_axi_rdata(m_rdata),
    .oculink_m_axi_rid(m_rid), .oculink_m_axi_rlast(m_rlast), .oculink_m_axi_rresp(m_rresp),
    .oculink_m_axi_rvalid(m_rvalid), .oculink_m_axi_bready(m_bready), .oculink_m_axi_bid(m_bid),
    .oculink_m_axi_bresp(m_bresp), .oculink_m_axi_bvalid(m_bvalid)
  );

  // post one CQE (1-beat W) at IOCQ slot, AW immediately followed by its W -- back to back, no B wait
  task automatic post_cqe(input int slot);
    @(posedge oculink_axi_clk);
    m_awaddr <= IOCQ_BAR + slot*16; m_awlen <= 0; m_awvalid <= 1;
    do @(posedge oculink_axi_clk); while(!m_awready);
    m_awvalid <= 0;
    m_wdata <= {224'd0, 32'h00010000}; m_wlast <= 1; m_wvalid <= 1; // DW3 phase=1
    do @(posedge oculink_axi_clk); while(!m_wready);
    m_wvalid <= 0; m_wlast <= 0;
  endtask

  int i, base; int N = 200;
  initial begin
    repeat(20) @(posedge oculink_axi_clk); rstn = 1; repeat(20) @(posedge oculink_axi_clk);
    base = cpl_count;
    for (i=0;i<N;i++) post_cqe(i % 64);           // N back-to-back CQEs (~2 cycles apart)
    // let any in-flight drain
    repeat(400) @(posedge oculink_axi_clk);
    $display("[CPLSTRESS] posted %0d back-to-back CQEs; cpl_count rose by %0d => %s",
             N, cpl_count-base, ((cpl_count-base)==N) ? "PASS (none missed)" : "FAIL (missed completions)");
    $finish;
  end
  initial begin #500000; $display("[CPLSTRESS] TIMEOUT"); $finish; end
endmodule
