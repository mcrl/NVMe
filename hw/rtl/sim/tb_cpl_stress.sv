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

  // free-running cycle counter for throughput measurement
  int cyc_cnt = 0;
  always @(posedge oculink_axi_clk) cyc_cnt <= cyc_cnt + 1;

  // Measure the write-data R-serve throughput: issue `n` back-to-back data-class AR bursts of `chunk`
  // beats each (mimicking the SSD's back-to-back MRds when fetching write payload), drain R, and report
  // total cycles vs total beats. cyc==beats => no inter-burst bubble (line rate); cyc>beats => bubble.
  task automatic rd_burst_stress(input int n, input int chunk);
    int b0, t0, beats, cyc, i;
    b0 = dut.r_data_beats;
    // issue n data-class ARs back-to-back (arready tied 1 -> one accepted per cycle); FPGA serves wrdata
    m_araddr <= 32'h100000; m_arlen <= chunk-1; m_arvalid <= 1;
    t0 = cyc_cnt;
    repeat(n) @(posedge oculink_axi_clk);
    m_arvalid <= 0;
    // drain until the rtag is empty and no more R beats in flight
    do @(posedge oculink_axi_clk); while(!dut.rtag_empty || m_rvalid);
    beats = dut.r_data_beats - b0;  cyc = cyc_cnt - t0;
    $display("[RDBURST] n=%0d chunk=%0d : beats=%0d cycles=%0d  bubble=%0d (%0d%%)  => %s",
      n, chunk, beats, cyc, cyc-beats, (beats>0)?((cyc-beats)*100/cyc):0,
      (beats==n*chunk) ? "all beats served" : "BEAT MISMATCH");
  endtask

  // Same as rd_burst_stress but the SSD throttles rready (3 high / 1 low) throughout the drain, including
  // at burst boundaries -> exercises the AXI stall path the all-rready=1 test misses. Must still serve every
  // beat with no rtag desync (the naive chain hung here on HW; the robust FSM holds across stalls).
  task automatic rd_burst_stall(input int n, input int chunk);
    int b0, beats, guard;
    b0 = dut.r_data_beats;
    m_rready <= 0;                                   // hold ready low while we queue all the ARs
    m_araddr <= 32'h100000; m_arlen <= chunk-1; m_arvalid <= 1;
    repeat(n) @(posedge oculink_axi_clk);
    m_arvalid <= 0;
    guard = 0;
    while ((!dut.rtag_empty || m_rvalid) && guard < n*chunk*8) begin   // drain with periodic ready stalls
      m_rready <= 1; repeat(3) @(posedge oculink_axi_clk);
      m_rready <= 0; repeat(1) @(posedge oculink_axi_clk);
      guard += 4;
    end
    m_rready <= 1; repeat(5) @(posedge oculink_axi_clk);
    beats = dut.r_data_beats - b0;
    $display("[RDSTALL] n=%0d chunk=%0d (rready 3hi/1lo): beats=%0d (exp %0d) => %s",
      n, chunk, beats, n*chunk, (beats==n*chunk) ? "PASS (all served across stalls)" : "FAIL (desync/drop)");
  endtask

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

  // Reproduce QD>1 reads on the W channel: interleave N (read-data burst + CQE) commands with all 2N AWs
  // issued before the W bursts (multiple outstanding AWs), then check every read-data beat is captured and
  // every CQE counted (no drop, no wedge). aw=read-data:16 beats(512B), CQE:1 beat.
  task automatic rd_cqe_stress(input int n);
    longint b0; int c0, dbeats, dcpl, i, j;
    b0 = dut.w_data_beats; c0 = cpl_count;
    // issue all 2N AWs first as clean 1-cycle pulses (data_i then cqe_i, interleaved) -> 2N outstanding
    for (i=0;i<n;i++) begin
      m_awaddr <= 32'h10000 + i*32'h1000; m_awlen <= 15; m_awvalid <= 1;  // read-data (16 beats)
      do @(posedge oculink_axi_clk); while(!m_awready);
      m_awvalid <= 0; @(posedge oculink_axi_clk);
      m_awaddr <= IOCQ_BAR + (i%64)*16;   m_awlen <= 0;   m_awvalid <= 1; // CQE (1 beat)
      do @(posedge oculink_axi_clk); while(!m_awready);
      m_awvalid <= 0; @(posedge oculink_axi_clk);
    end
    // W bursts in AW order: data_i (16 beats) then cqe_i (1 beat)
    for (i=0;i<n;i++) begin
      for (j=0;j<16;j++) begin m_wdata<={8{32'hDA7A0000+j}}; m_wlast<=(j==15); m_wvalid<=1; do @(posedge oculink_axi_clk); while(!m_wready); end
      m_wvalid<=0; m_wlast<=0; @(posedge oculink_axi_clk);
      m_wdata<={224'd0,32'h00010000}; m_wlast<=1; m_wvalid<=1; do @(posedge oculink_axi_clk); while(!m_wready);
      m_wvalid<=0; m_wlast<=0; @(posedge oculink_axi_clk);
    end
    repeat(300) @(posedge oculink_axi_clk);
    dbeats = dut.w_data_beats - b0; dcpl = cpl_count - c0;
    $display("[RDCQE] %0d cmds (2N AWs outstanding): read-data beats +%0d (exp %0d), cpl_count +%0d (exp %0d) => %s",
      n, dbeats, n*16, dcpl, n,
      (dbeats==n*16 && dcpl==n) ? "PASS" : "FAIL (drop)");
  endtask

  // read the PRP list (AR to 0xD000) and verify entry(k) = 0xE000 + k*4096
  task automatic check_list(input int nbeats);
    int b, bad; logic [255:0] beat; logic [31:0] exp, got;
    b=0; bad=0;
    @(posedge oculink_axi_clk);
    m_araddr <= 32'hD000; m_arlen <= nbeats-1; m_arvalid <= 1;
    do @(posedge oculink_axi_clk); while(!m_arready);
    m_arvalid <= 0;
    forever begin
      @(posedge oculink_axi_clk);
      if (m_rvalid) begin
        beat = m_rdata;
        for (int ii=0; ii<4; ii++) begin
          exp = 32'hE000 + ((4*b+ii) << 12);
          got = beat[ii*64 +: 32];
          if (got !== exp) begin bad++; if(bad<=4) $display("[LIST] beat %0d entry %0d got %08h exp %08h", b, ii, got, exp); end
        end
        b++;
        if (m_rlast) break;
      end
    end
    $display("[LIST] read %0d beats (%0d entries), %0d mismatches => %s", b, b*4, bad, bad==0?"PASS":"FAIL");
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
    check_list(8);   // verify the PRP-list generator (32 entries = pages 2..33)
    rd_cqe_stress(2);   // QD>1 read W-channel: interleaved read-data + CQE, 2N outstanding AWs
    rd_cqe_stress(4);
    rd_cqe_stress(8);
    // write-data R-serve throughput: back-to-back MRd-sized bursts (8 beats = 256 B at MPS=256)
    rd_burst_stress(64, 8);    // 64 bursts of 8 beats (mimics 64 back-to-back 256 B MRds)
    rd_burst_stress(64, 16);   // 64 bursts of 16 beats (512 B)
    rd_burst_stall(64, 8);     // same, but rready throttled -> proves the chain survives mid-burst stalls
    rd_burst_stall(64, 16);
    rd_burst_stall(40, 4);
    repeat(50) @(posedge oculink_axi_clk);
    $finish;
  end
  initial begin #500000; $display("[CPLSTRESS] TIMEOUT"); $finish; end
endmodule
