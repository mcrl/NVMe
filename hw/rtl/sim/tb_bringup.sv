// Isolation test for the autonomous bring-up sequencer (nvme_bringup). Mocks the config-access responses
// (cfg_wr_done/cfg_rd_done/cfg_rddata, with a CC.EN->CSTS.RDY model) and the completion counter, then checks
// the sequencer emits the full bring-up (12 config/mem writes, the two CSTS polls, IOCQ+IOSQ triggers) and
// asserts `ready`.
`timescale 1ns/1ps
module tb_bringup;
  logic clk=0, rstn=0, start=0;
  always #2 clk = ~clk;   // host_bram_clk

  logic        busy, ready;
  logic        bu_cfg_write, bu_cfg_read, bu_cfg_done, bu_send_iocq, bu_send_iosq;
  logic [31:0] bu_cfg_wraddr, bu_cfg_wrdata, bu_cfg_rdaddr;
  logic        cfg_wr_done=0, cfg_rd_done=0;
  logic [31:0] cfg_rddata=0, cpl_count=0;

  nvme_bringup dut (
    .host_bram_clk(clk), .rstn(rstn), .start(start), .busy(busy), .ready(ready),
    .bu_cfg_write(bu_cfg_write), .bu_cfg_read(bu_cfg_read), .bu_cfg_wraddr(bu_cfg_wraddr),
    .bu_cfg_wrdata(bu_cfg_wrdata), .bu_cfg_rdaddr(bu_cfg_rdaddr), .bu_cfg_done(bu_cfg_done),
    .bu_send_iocq(bu_send_iocq), .bu_send_iosq(bu_send_iosq),
    .cfg_wr_done(cfg_wr_done), .cfg_rd_done(cfg_rd_done), .cfg_rddata(cfg_rddata), .cpl_count(cpl_count)
  );

  localparam logic [31:0] CC_ADDR   = 32'h8000_0000 | 32'h4000 | 32'h14;
  localparam logic [31:0] CSTS_ADDR = 32'h8000_0000 | 32'h4000 | 32'h1C;

  int nwr=0, nrd=0, niocq=0, niosq=0;
  logic cc_en=0, csts_rdy=0;

  // ---- mock config-access WRITE: cfg_wr_done goes 0 (accepted) then 1 (done) a few cycles later ----
  int wcnt=0;
  always @(posedge clk) begin
    if (bu_cfg_write) begin
      cfg_wr_done <= 0; wcnt <= 6; nwr++;
      if (bu_cfg_wraddr==CC_ADDR) cc_en <= bu_cfg_wrdata[0];   // model CC.EN
    end else if (wcnt>0) begin
      wcnt <= wcnt-1;
      if (wcnt==1) begin cfg_wr_done <= 1; csts_rdy <= cc_en; end // CSTS.RDY tracks CC.EN after the write
    end
  end
  // ---- mock config-access READ: return CSTS.RDY for CSTS addr, 0 otherwise ----
  int rcnt=0; logic [31:0] rdaddr_l;
  always @(posedge clk) begin
    if (bu_cfg_read) begin cfg_rd_done <= 0; rcnt <= 6; rdaddr_l <= bu_cfg_rdaddr; nrd++; end
    else if (rcnt>0) begin
      rcnt <= rcnt-1;
      if (rcnt==1) begin cfg_rddata <= (rdaddr_l==CSTS_ADDR) ? {31'd0,csts_rdy} : 32'd0; cfg_rd_done <= 1; end
    end
  end
  // ---- mock completion: each admin trigger bumps cpl_count a few cycles later ----
  int ccnt=0;
  always @(posedge clk) begin
    if (bu_send_iocq) begin niocq++; ccnt<=8; end
    else if (bu_send_iosq) begin niosq++; ccnt<=8; end
    else if (ccnt>0) begin ccnt<=ccnt-1; if (ccnt==1) cpl_count <= cpl_count+1; end
  end

  initial begin
    repeat(10) @(posedge clk); rstn=1; repeat(10) @(posedge clk);
    @(posedge clk); start<=1; @(posedge clk); start<=0;
    // wait for ready
    fork : w
      begin wait(ready); disable w; end
      begin repeat(4000) @(posedge clk); $display("[BRINGUP] TIMEOUT (ready never asserted)"); disable w; end
    join
    repeat(5) @(posedge clk);
    $display("[BRINGUP] writes=%0d reads=%0d iocq=%0d iosq=%0d ready=%0b cfgdone_final=%0b",
             nwr, nrd, niocq, niosq, ready, bu_cfg_done);
    $display("[BRINGUP] => %s",
      (ready && nwr==14 && nrd>=4 && niocq==1 && niosq==1 && bu_cfg_done==1) ? "PASS (autonomous bring-up sequence complete)"
                                                                            : "FAIL");
    $finish;
  end
endmodule
