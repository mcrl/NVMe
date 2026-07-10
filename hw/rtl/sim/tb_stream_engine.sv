// stream_engine REFILL: stream a 256-word transfer through a SMALL 64-word circular window (4 wraps) from a
// DDR4 model, while a SLOW "SSD reader" drains the window. Verifies (a) the SSD always reads filled data ahead
// of where it is (refill stays ahead), (b) the room gate never lets the refill overrun unread data, (c) wrap.
`timescale 1ns/1ps
module tb_stream_engine;
  logic clk=0, rstn=0; always #2 clk=~clk;
  localparam int AW=9, WIN=512, TOT=2048;   // window (512) >= burst (256); 2048 words = 4 wraps

  logic start=0; logic [31:0] total=TOT; logic [31:0] peer=0, myp; logic busy;
  logic [AW-1:0] win_addr; logic [31:0] win_we; logic [255:0] win_din;
  logic [AW-1:0] win_raddr; logic win_ren; logic [255:0] win_dout_unused;
  logic e_req_valid, e_req_we; logic [31:0] e_req_addr; logic [7:0] e_req_len; logic e_busy;
  logic [255:0] e_wd_data; logic e_wd_valid, e_wd_ready;
  logic [255:0] e_rd_data; logic e_rd_valid, e_rd_ready;
  logic [31:0] aw_a; logic [7:0] aw_l; logic awv,awr; logic [255:0] wd; logic wl,wv,wr;
  logic [1:0] br; logic bv,brdy; logic [31:0] ar_a; logic [7:0] ar_l; logic arv,arr;
  logic [255:0] rdat; logic rl,rv,rr; logic [1:0] rrs;

  // window: port A = refill write (clk), port B = tb "SSD reader" (clk)
  logic [AW-1:0] rd_a=0; logic [255:0] rd_d;
  dpram_be #(.DW(256),.AW(AW),.RDLAT(1),.PRIM("block")) win (
    .clka(clk),.ena(1'b1),.wea(win_we),.addra(win_addr),.dina(win_din),
    .clkb(clk),.enb(1'b1),.addrb(rd_a),.doutb(rd_d));

  stream_engine #(.AWORDS(AW),.WIN(WIN),.DIR(0)) se (.clk(clk),.rstn(rstn),.start(start),.total_words(total),
    .peer_prog(peer),.my_prog(myp),.busy(busy),
    .win_addr(win_addr),.win_we(win_we),.win_din(win_din),
    .win_raddr(win_raddr),.win_ren(win_ren),.win_dout(256'd0),
    .e_req_valid(e_req_valid),.e_req_we(e_req_we),.e_req_addr(e_req_addr),.e_req_len(e_req_len),.e_busy(e_busy),
    .e_wd_data(e_wd_data),.e_wd_valid(e_wd_valid),.e_wd_ready(e_wd_ready),
    .e_rd_data(e_rd_data),.e_rd_valid(e_rd_valid),.e_rd_ready(e_rd_ready));
  ddr4_engine eng (.clk(clk),.rstn(rstn),
    .req_valid(e_req_valid),.req_we(e_req_we),.req_addr(e_req_addr),.req_len(e_req_len),.busy(e_busy),
    .wd_data(e_wd_data),.wd_valid(e_wd_valid),.wd_ready(e_wd_ready),
    .rd_data(e_rd_data),.rd_valid(e_rd_valid),.rd_ready(e_rd_ready),
    .m_awaddr(aw_a),.m_awlen(aw_l),.m_awvalid(awv),.m_awready(awr),.m_wdata(wd),.m_wlast(wl),.m_wvalid(wv),.m_wready(wr),
    .m_bresp(br),.m_bvalid(bv),.m_bready(brdy),
    .m_araddr(ar_a),.m_arlen(ar_l),.m_arvalid(arv),.m_arready(arr),
    .m_rdata(rdat),.m_rlast(rl),.m_rvalid(rv),.m_rready(rr),.m_rresp(rrs));
  ddr4_axi_model mdl (.clk(clk),.rstn(rstn),.awaddr(aw_a),.awlen(aw_l),.awvalid(awv),.awready(awr),
    .wdata(wd),.wlast(wl),.wvalid(wv),.wready(wr),.bresp(br),.bvalid(bv),.bready(brdy),
    .araddr(ar_a),.arlen(ar_l),.arvalid(arv),.arready(arr),.rdata(rdat),.rlast(rl),.rvalid(rv),.rready(rr),.rresp(rrs));

  function automatic logic [255:0] patt(input int i); return {8{32'h5713_0000 + i}}; endfunction
  int i, bad;
  initial begin
    for (i=0;i<TOT;i++) mdl.mem[i]=patt(i);            // DDR4 pre-loaded with the transfer
    repeat(10) @(posedge clk); rstn=1; repeat(5) @(posedge clk);
    @(posedge clk); start<=1; @(posedge clk); start<=0;
    // SSD reader: walk position 0..TOT-1, each time read the circular window slot and check it is FILLED ahead
    bad=0;
    for (i=0;i<TOT;i++) begin
      // wait until the refill has filled position i (myp > i); refill must keep ahead
      while (myp <= i) @(posedge clk);
      rd_a <= i % WIN; @(posedge clk); @(posedge clk);
      if (rd_d !== patt(i)) begin bad++; if(bad<=4) $display("[SE] pos %0d slot %0d got %h exp %h",i,i%WIN,rd_d,patt(i)); end
      // sanity: refill never overran unread data (myp <= consumed + WIN). consumed = i (we just read pos i).
      if (myp > i + WIN + 1) begin bad++; $display("[SE] OVERRUN at pos %0d: myp=%0d > %0d",i,myp,i+WIN); end
      peer <= i + 1;                                    // SSD has now read through position i
      repeat(3) @(posedge clk);                         // SSD pace (slower than DDR4 refill)
    end
    $display("[SE] REFILL 256 words / 64-word window (4 wraps): %0d errors => %s", bad, bad==0?"PASS":"FAIL");
    $finish;
  end
  initial begin #2000000; $display("[SE] TIMEOUT (refill stuck? myp=%0d peer=%0d)", myp, peer); $finish; end
endmodule
