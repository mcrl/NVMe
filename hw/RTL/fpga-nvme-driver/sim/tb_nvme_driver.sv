// Testbench for nvme_driver multiple-outstanding behaviour, driven against the behavioural ssd_model.
// Submits N IO write commands and checks that all N completions are captured (cpl_count).
`timescale 1ns/1ps
module tb_nvme_driver;
  logic oculink_axi_clk = 0;   // 125 MHz
  logic host_bram_clk   = 0;   // 250 MHz
  logic rstn = 0;
  always #4   oculink_axi_clk = ~oculink_axi_clk;  // 8ns period
  always #2   host_bram_clk   = ~host_bram_clk;    // 4ns period

  // host-side stimulus
  logic        send_iocq, send_iosq, send_rd, send_wr;
  logic [31:0] nvme_addr, fpga_addr, nlb;
  logic        cpl_done;
  logic [31:0] wrdata [7:0];
  logic [31:0] rddata [7:0];
  logic [31:0] cpl_status, cpl_count;

  // AXI nets between nvme_driver (DUT) and ssd_model
  // s_axi (DUT master -> SSD slave)
  logic        s_awready; logic [31:0] s_awaddr; logic [1:0] s_awburst; logic [3:0] s_awid;
  logic [7:0]  s_awlen; logic [3:0] s_awregion; logic [2:0] s_awsize; logic s_awvalid;
  logic        s_wready; logic [255:0] s_wdata; logic s_wlast; logic [31:0] s_wstrb; logic s_wvalid;
  logic        s_bready; logic [3:0] s_bid; logic [1:0] s_bresp; logic s_bvalid;
  // m_axi (SSD master -> DUT slave)
  logic        m_arready; logic [31:0] m_araddr; logic [1:0] m_arburst; logic [3:0] m_arcache;
  logic [3:0]  m_arid; logic [7:0] m_arlen; logic m_arlock; logic [2:0] m_arprot; logic [2:0] m_arsize; logic m_arvalid;
  logic        m_awready; logic [31:0] m_awaddr; logic [1:0] m_awburst; logic [3:0] m_awcache;
  logic [3:0]  m_awid; logic [7:0] m_awlen; logic m_awlock; logic [2:0] m_awprot; logic [2:0] m_awsize; logic m_awvalid;
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

  ssd_model #(.PIPELINE_CPL(1)) ssd (
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

  // debug: when SSD issues the write-data AR (>=0xC000), show the DUT's write-serve state
  int dbgn = 0;
  always @(posedge oculink_axi_clk) begin
    if (m_arvalid && (m_araddr >= 32'hC000) && dbgn < 8) begin
      $display("[DBG] t=%0t data-AR: rtag_sel_cmd=%b rtag_empty=%b rtag_head_is_sqe=%b wrdata_state=%0d cmd_state=%0d db_state=%0d",
               $time, dut.rtag_sel_cmd, dut.rtag_empty, dut.rtag_head_is_sqe, dut.wrdata_state, dut.cmd_state, dut.db_state);
      dbgn++;
    end
  end

  // ---- demux invariant checks (sim-only): catch in-order/routing/pop-accounting bugs ----
  localparam CMD_RECV_ADDR_ST = 8'd3;
  int rbeats = 0;
  always @(posedge oculink_axi_clk) if (rstn) begin
    if (m_rvalid && m_rready && m_rlast && dut.rtag_empty)
      $error("[ASSERT] rtag underflow: R rlast handshake with empty rtag @%0t", $time);
    if (m_bvalid && m_bready && dut.wtag_empty)
      $error("[ASSERT] wtag underflow: B handshake with empty wtag @%0t", $time);
    if (dut.cmd_state == CMD_RECV_ADDR_ST && !dut.sqear_empty && (dut.sqear_head !== dut.cmd_is_admin))
      $error("[ASSERT] SQE-AR class mismatch: sqear_head=%b cmd_is_admin=%b @%0t", dut.sqear_head, dut.cmd_is_admin, $time);
    // count beats per data-read burst and check against arlen+1 at rlast (write-data reads only)
    if (m_rvalid && m_rready && !dut.rtag_sel_cmd) begin
      rbeats <= rbeats + 1;
      if (m_rlast) begin
        if ((rbeats + 1) != (dut.rtag_head_arlen + 1))
          $error("[ASSERT] write-data beat count %0d != arlen+1 %0d @%0t", rbeats+1, dut.rtag_head_arlen+1, $time);
        rbeats <= 0;
      end
    end
  end

  // ---- host stimulus tasks (host_bram_clk domain) ----
  task automatic pulse_cmd(input int which);  // 0=iocq 1=iosq 2=rd 3=wr
    @(posedge host_bram_clk);
    send_iocq <= (which==0); send_iosq <= (which==1); send_rd <= (which==2); send_wr <= (which==3);
    @(posedge host_bram_clk);
    send_iocq <= 0; send_iosq <= 0; send_rd <= 0; send_wr <= 0;
  endtask

  task automatic wait_cpl(input int target, input int maxcyc);
    int c; c=0;
    while (cpl_count < target && c < maxcyc) begin @(posedge oculink_axi_clk); c++; end
  endtask

  int i, base, expN;
  initial begin
    send_iocq=0; send_iosq=0; send_rd=0; send_wr=0; nvme_addr=0; fpga_addr=0; nlb=0;
    for (i=0;i<8;i++) wrdata[i]=32'hA0000000 + i;
    repeat(20) @(posedge oculink_axi_clk);
    rstn = 1;
    repeat(20) @(posedge oculink_axi_clk);

    // admin: create IOCQ then IOSQ
    pulse_cmd(0); wait_cpl(1, 5000);
    pulse_cmd(1); wait_cpl(2, 5000);
    $display("[TB] after admin creates: cpl_count=%0d (expN 2)", cpl_count);

    // submit N IO writes back-to-back (multiple outstanding); 70 > queue depth 64 -> exercises SQ/CQ wrap
    nvme_addr = 32'hC000; nlb = 0;
    base = cpl_count;
    for (i=0;i<70;i++) begin
      fpga_addr = 100+i;     // SLBA
      pulse_cmd(3);          // send_write_cmd (1 host-clk pulse each, FIFO buffers)
    end
    expN = base + 70;
    wait_cpl(expN, 600000);
    $display("[TB] submitted 70 writes; cpl_count=%0d (expN %0d) => %s",
             cpl_count, expN, (cpl_count>=expN) ? "PASS (all completions captured)" : "FAIL (missed completions)");

    // IO reads: exercise the W-channel demux (read-data AW -> rd sink, then CQE AW -> cpl sink)
    base = cpl_count;
    nvme_addr = 32'hC000; nlb = 0;
    for (i=0;i<8;i++) begin
      fpga_addr = 200+i;
      pulse_cmd(2);          // send_read_cmd
    end
    expN = base + 8;
    wait_cpl(expN, 200000);
    $display("[TB] submitted 8 reads;  cpl_count=%0d (expN %0d) => %s ; rddata[0]=%08x (expect dadacafe)",
             cpl_count, expN, (cpl_count>=expN) ? "PASS" : "FAIL", rddata[0]);

    repeat(50) @(posedge oculink_axi_clk);
    $finish;
  end

  initial begin #2000000; $display("[TB] TIMEOUT"); $finish; end
endmodule
