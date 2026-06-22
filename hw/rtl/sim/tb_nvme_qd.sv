// QD>1 read test against the pipelined SSD model (ssd_model_pipe). After admin creates, submit N IO reads
// back-to-back (host queues them; MO-9 lets the cmd FSM pop ahead of the doorbell-B), and verify the FPGA
// captures EVERY read-payload beat and counts EACH CQE exactly once -- i.e. reproduce-or-refute the HW QD>1
// anomaly (cpl == QD*REAL) in sim. nlb=15 => 8 KB = 2 pages (PRP2 direct), 256 read beats/command.
`timescale 1ns/1ps
module tb_nvme_qd;
  logic oculink_axi_clk = 0, host_bram_clk = 0, rstn = 0;
  always #4 oculink_axi_clk = ~oculink_axi_clk;   // 125 MHz
  always #2 host_bram_clk   = ~host_bram_clk;     // 250 MHz

  logic        send_iocq, send_iosq, send_rd, send_wr;
  logic [31:0] nvme_addr, fpga_addr, nlb;
  logic        cpl_done;
  logic [31:0] wrdata [7:0]; logic [31:0] rddata [7:0]; logic [31:0] cpl_status, cpl_count;

  logic        s_awready; logic [31:0] s_awaddr; logic [1:0] s_awburst; logic [3:0] s_awid;
  logic [7:0]  s_awlen; logic [3:0] s_awregion; logic [2:0] s_awsize; logic s_awvalid;
  logic        s_wready; logic [255:0] s_wdata; logic s_wlast; logic [31:0] s_wstrb; logic s_wvalid;
  logic        s_bready; logic [3:0] s_bid; logic [1:0] s_bresp; logic s_bvalid;
  logic        m_arready; logic [31:0] m_araddr; logic [1:0] m_arburst; logic [3:0] m_arcache;
  logic [3:0]  m_arid; logic [7:0] m_arlen; logic m_arlock; logic [2:0] m_arprot, m_arsize; logic m_arvalid;
  logic        m_awready; logic [31:0] m_awaddr; logic [1:0] m_awburst; logic [3:0] m_awcache;
  logic [3:0]  m_awid; logic [7:0] m_awlen; logic m_awlock; logic [2:0] m_awprot, m_awsize; logic m_awvalid;
  logic        m_wready; logic [255:0] m_wdata; logic m_wlast; logic [31:0] m_wstrb; logic m_wvalid;
  logic        m_rready; logic [255:0] m_rdata; logic [3:0] m_rid; logic m_rlast; logic [1:0] m_rresp; logic m_rvalid;
  logic        m_bready; logic [3:0] m_bid; logic [1:0] m_bresp; logic m_bvalid;

  nvme_driver dut (
    .rstn(rstn), .host_bram_clk(host_bram_clk), .oculink_axi_clk(oculink_axi_clk),
    .send_iocq_create_cmd(send_iocq), .send_iosq_create_cmd(send_iosq),
    .send_read_cmd(send_rd), .send_write_cmd(send_wr),
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

  ssd_model_pipe ssd (
    .clk(oculink_axi_clk), .rstn(rstn),
    .s_awready(s_awready), .s_awaddr(s_awaddr), .s_awburst(s_awburst), .s_awid(s_awid), .s_awlen(s_awlen),
    .s_awregion(s_awregion), .s_awsize(s_awsize), .s_awvalid(s_awvalid), .s_wready(s_wready),
    .s_wdata(s_wdata), .s_wlast(s_wlast), .s_wstrb(s_wstrb), .s_wvalid(s_wvalid), .s_bready(s_bready),
    .s_bid(s_bid), .s_bresp(s_bresp), .s_bvalid(s_bvalid),
    .m_arready(m_arready), .m_araddr(m_araddr), .m_arburst(m_arburst), .m_arcache(m_arcache), .m_arid(m_arid),
    .m_arlen(m_arlen), .m_arlock(m_arlock), .m_arprot(m_arprot), .m_arsize(m_arsize), .m_arvalid(m_arvalid),
    .m_awready(m_awready), .m_awaddr(m_awaddr), .m_awburst(m_awburst), .m_awcache(m_awcache), .m_awid(m_awid),
    .m_awlen(m_awlen), .m_awlock(m_awlock), .m_awprot(m_awprot), .m_awsize(m_awsize), .m_awvalid(m_awvalid),
    .m_wready(m_wready), .m_wdata(m_wdata), .m_wlast(m_wlast), .m_wstrb(m_wstrb), .m_wvalid(m_wvalid),
    .m_rready(m_rready), .m_rdata(m_rdata), .m_rid(m_rid), .m_rlast(m_rlast), .m_rresp(m_rresp), .m_rvalid(m_rvalid),
    .m_bready(m_bready), .m_bid(m_bid), .m_bresp(m_bresp), .m_bvalid(m_bvalid)
  );

  task automatic pulse_cmd(input int which);
    @(posedge host_bram_clk);
    send_iocq <= (which==0); send_iosq <= (which==1); send_rd <= (which==2); send_wr <= (which==3);
    @(posedge host_bram_clk);
    send_iocq <= 0; send_iosq <= 0; send_rd <= 0; send_wr <= 0;
  endtask
  task automatic wait_cpl(input int target, input int maxcyc);
    int c; c=0; while (cpl_count < target && c < maxcyc) begin @(posedge oculink_axi_clk); c++; end
  endtask

  localparam int N   = 32;     // QD: number of IO reads submitted back-to-back
  localparam int NLB = 15;    // 16 blocks = 8 KB = 2 pages ; 256 read-payload beats/command
  int i, expbeats, gotbeats;
  initial begin
    send_iocq=0; send_iosq=0; send_rd=0; send_wr=0; nvme_addr=0; fpga_addr=0; nlb=0;
    for (i=0;i<8;i++) wrdata[i]=32'hA0000000+i;
    repeat(20) @(posedge oculink_axi_clk); rstn = 1; repeat(20) @(posedge oculink_axi_clk);

    pulse_cmd(0); wait_cpl(1, 20000);          // create IOCQ
    pulse_cmd(1); wait_cpl(2, 20000);          // create IOSQ
    $display("[QD] admin creates done: cpl_count=%0d (exp 2)", cpl_count);

    nvme_addr = 32'hC000; nlb = NLB;
    for (i=0;i<N;i++) begin fpga_addr = 100 + i*16; pulse_cmd(2); end   // N reads back-to-back
    wait_cpl(2+N, 4000000);

    expbeats = N*(NLB+1)*16;  gotbeats = dut.w_data_beats;
    $display("[QD] submitted %0d reads (nlb=%0d, %0d beats/cmd):", N, NLB, (NLB+1)*16);
    $display("[QD]   cpl_count = %0d  (exp %0d)  => %s", cpl_count, 2+N,
             (cpl_count==2+N) ? "PASS (no CQE inflation)" : "FAIL");
    $display("[QD]   w_data_beats = %0d  (exp %0d)  => %s", gotbeats, expbeats,
             (gotbeats==expbeats) ? "PASS (all read payload captured)" : "FAIL (read-data dropped)");
    $display("[QD] RESULT: %s",
             (cpl_count==2+N && gotbeats==expbeats) ? "QD>1 READ OK in sim" : "QD>1 READ ANOMALY REPRODUCED");
    repeat(50) @(posedge oculink_axi_clk);
    $finish;
  end
  initial begin #20000000; $display("[QD] TIMEOUT (likely a QD>1 hang/wedge)"); $finish; end
endmodule
