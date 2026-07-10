// ddr4_engine vs ddr4_axi_model: write bursts then read them back, check data + no cross-burst corruption.
`timescale 1ns/1ps
module tb_ddr4_engine;
  logic clk=0, rstn=0;
  always #2 clk=~clk;

  logic req_valid=0, req_we=0; logic [31:0] req_addr=0; logic [7:0] req_len=0; logic busy;
  logic [255:0] wd_data=0; logic wd_valid=0; logic wd_ready;
  logic [255:0] rd_data; logic rd_valid; logic rd_ready=0;
  logic [31:0] awaddr; logic [7:0] awlen; logic awvalid, awready;
  logic [255:0] wdata; logic wlast, wvalid, wready;
  logic [1:0] bresp; logic bvalid, bready;
  logic [31:0] araddr; logic [7:0] arlen; logic arvalid, arready;
  logic [255:0] rdata; logic rlast, rvalid, rready; logic [1:0] rresp;

  ddr4_engine dut(.clk(clk),.rstn(rstn),
    .req_valid(req_valid),.req_we(req_we),.req_addr(req_addr),.req_len(req_len),.busy(busy),
    .wd_data(wd_data),.wd_valid(wd_valid),.wd_ready(wd_ready),
    .rd_data(rd_data),.rd_valid(rd_valid),.rd_ready(rd_ready),
    .m_awaddr(awaddr),.m_awlen(awlen),.m_awvalid(awvalid),.m_awready(awready),
    .m_wdata(wdata),.m_wlast(wlast),.m_wvalid(wvalid),.m_wready(wready),
    .m_bresp(bresp),.m_bvalid(bvalid),.m_bready(bready),
    .m_araddr(araddr),.m_arlen(arlen),.m_arvalid(arvalid),.m_arready(arready),
    .m_rdata(rdata),.m_rlast(rlast),.m_rvalid(rvalid),.m_rready(rready),.m_rresp(rresp));

  ddr4_axi_model mdl(.clk(clk),.rstn(rstn),
    .awaddr(awaddr),.awlen(awlen),.awvalid(awvalid),.awready(awready),
    .wdata(wdata),.wlast(wlast),.wvalid(wvalid),.wready(wready),
    .bresp(bresp),.bvalid(bvalid),.bready(bready),
    .araddr(araddr),.arlen(arlen),.arvalid(arvalid),.arready(arready),
    .rdata(rdata),.rlast(rlast),.rvalid(rvalid),.rready(rready),.rresp(rresp));

  function automatic logic [255:0] patt(input int tag, input int i); return {8{32'h1000_0000 + (tag<<16) + i}}; endfunction

  task automatic wr_burst(input [31:0] addr, input int n, input int tag);
    @(posedge clk); req_addr<=addr; req_len<=n-1; req_we<=1; req_valid<=1;
    @(posedge clk); req_valid<=0;
    for (int i=0;i<n;i++) begin wd_data<=patt(tag,i); wd_valid<=1; do @(posedge clk); while(!wd_ready); end
    wd_valid<=0; do @(posedge clk); while(busy);
  endtask

  task automatic rd_burst(input [31:0] addr, input int n, input int tag, output int bad);
    bad=0;
    @(posedge clk); req_addr<=addr; req_len<=n-1; req_we<=0; req_valid<=1; rd_ready<=1;
    @(posedge clk); req_valid<=0;
    for (int i=0;i<n;i++) begin
      do @(posedge clk); while(!rd_valid);
      if (rd_data !== patt(tag,i)) begin bad++; if(bad<=2) $display("[DE] rd beat %0d got %h exp %h",i,rd_data,patt(tag,i)); end
    end
    rd_ready<=0; do @(posedge clk); while(busy);
  endtask

  int bad;
  initial begin
    repeat(10) @(posedge clk); rstn=1; repeat(10) @(posedge clk);
    wr_burst(32'h0000, 8, 1);  rd_burst(32'h0000, 8, 1, bad);
    $display("[DE] T1 8-beat W+R @0x0000:  %0d mismatch => %s", bad, bad==0?"PASS":"FAIL");
    wr_burst(32'h2000, 16, 2); rd_burst(32'h2000, 16, 2, bad);
    $display("[DE] T2 16-beat W+R @0x2000: %0d mismatch => %s", bad, bad==0?"PASS":"FAIL");
    rd_burst(32'h0000, 8, 1, bad);
    $display("[DE] T3 re-read @0x0000 (no corruption): %0d mismatch => %s", bad, bad==0?"PASS":"FAIL");
    $finish;
  end
  initial begin #500000; $display("[DE] TIMEOUT"); $finish; end
endmodule
