// copy_engine: fill a src SRAM, copy it src -> DDR4 (model) -> dst SRAM, check dst == src (data transits DRAM).
`timescale 1ns/1ps
module tb_copy_engine;
  logic clk=0, rstn=0; always #2 clk=~clk;
  localparam int AW=12;
  localparam int NW=512;   // words (16 KB) -> spans two 256-beat bursts

  logic go=0, ce_busy; logic [AW:0] nwords = NW;
  logic [AW-1:0] src_addr; logic src_en; logic [255:0] src_dout;
  logic [AW-1:0] dst_addr; logic [31:0] dst_we; logic [255:0] dst_din;
  logic e_req_valid, e_req_we; logic [31:0] e_req_addr; logic [7:0] e_req_len; logic e_busy;
  logic [255:0] e_wd_data; logic e_wd_valid, e_wd_ready;
  logic [255:0] e_rd_data; logic e_rd_valid, e_rd_ready;
  logic [31:0] awaddr; logic [7:0] awlen; logic awvalid, awready;
  logic [255:0] wdata; logic wlast, wvalid, wready;
  logic [1:0] bresp; logic bvalid, bready;
  logic [31:0] araddr; logic [7:0] arlen; logic arvalid, arready;
  logic [255:0] rdata; logic rlast, rvalid, rready; logic [1:0] rresp;

  logic [AW-1:0] s_wa=0; logic [31:0] s_we=0; logic [255:0] s_wd=0;
  dpram_be #(.DW(256),.AW(AW),.RDLAT(1),.PRIM("block")) src (
    .clka(clk),.ena(1'b1),.wea(s_we),.addra(s_wa),.dina(s_wd),
    .clkb(clk),.enb(src_en),.addrb(src_addr),.doutb(src_dout));
  logic [AW-1:0] d_ra=0; logic [255:0] d_rdout;
  dpram_be #(.DW(256),.AW(AW),.RDLAT(1),.PRIM("block")) dst (
    .clka(clk),.ena(1'b1),.wea(dst_we),.addra(dst_addr),.dina(dst_din),
    .clkb(clk),.enb(1'b1),.addrb(d_ra),.doutb(d_rdout));

  copy_engine #(.AWORDS(AW)) ce (.clk(clk),.rstn(rstn),.go(go),.nwords(nwords),.ddr4_base(32'd0),.mode(2'd0),.busy(ce_busy),
    .src_addr(src_addr),.src_en(src_en),.src_dout(src_dout),
    .dst_addr(dst_addr),.dst_we(dst_we),.dst_din(dst_din),
    .e_req_valid(e_req_valid),.e_req_we(e_req_we),.e_req_addr(e_req_addr),.e_req_len(e_req_len),.e_busy(e_busy),
    .e_wd_data(e_wd_data),.e_wd_valid(e_wd_valid),.e_wd_ready(e_wd_ready),
    .e_rd_data(e_rd_data),.e_rd_valid(e_rd_valid),.e_rd_ready(e_rd_ready));
  ddr4_engine eng (.clk(clk),.rstn(rstn),
    .req_valid(e_req_valid),.req_we(e_req_we),.req_addr(e_req_addr),.req_len(e_req_len),.busy(e_busy),
    .wd_data(e_wd_data),.wd_valid(e_wd_valid),.wd_ready(e_wd_ready),
    .rd_data(e_rd_data),.rd_valid(e_rd_valid),.rd_ready(e_rd_ready),
    .m_awaddr(awaddr),.m_awlen(awlen),.m_awvalid(awvalid),.m_awready(awready),
    .m_wdata(wdata),.m_wlast(wlast),.m_wvalid(wvalid),.m_wready(wready),
    .m_bresp(bresp),.m_bvalid(bvalid),.m_bready(bready),
    .m_araddr(araddr),.m_arlen(arlen),.m_arvalid(arvalid),.m_arready(arready),
    .m_rdata(rdata),.m_rlast(rlast),.m_rvalid(rvalid),.m_rready(rready),.m_rresp(rresp));
  ddr4_axi_model mdl (.clk(clk),.rstn(rstn),
    .awaddr(awaddr),.awlen(awlen),.awvalid(awvalid),.awready(awready),
    .wdata(wdata),.wlast(wlast),.wvalid(wvalid),.wready(wready),
    .bresp(bresp),.bvalid(bvalid),.bready(bready),
    .araddr(araddr),.arlen(arlen),.arvalid(arvalid),.arready(arready),
    .rdata(rdata),.rlast(rlast),.rvalid(rvalid),.rready(rready),.rresp(rresp));

  function automatic logic [255:0] patt(input int i); return {8{32'hC0DE_0000 + i}}; endfunction
  int i, bad;
  initial begin
    repeat(10) @(posedge clk); rstn=1; repeat(5) @(posedge clk);
    for (i=0;i<NW;i++) begin @(posedge clk); s_wa<=i; s_wd<=patt(i); s_we<=32'hFFFFFFFF; end
    @(posedge clk); s_we<=0; repeat(5) @(posedge clk);
    @(posedge clk); go<=1; @(posedge clk); go<=0;
    do @(posedge clk); while(ce_busy);
    repeat(5) @(posedge clk);
    bad=0;
    for (i=0;i<NW;i++) begin
      d_ra<=i; @(posedge clk); @(posedge clk);
      if (d_rdout !== patt(i)) begin bad++; if(bad<=3) $display("[CE] word %0d got %h exp %h",i,d_rdout,patt(i)); end
    end
    $display("[CE] copy %0d words src->DDR4->dst: %0d mismatch => %s", NW, bad, bad==0?"PASS":"FAIL");
    $finish;
  end
  initial begin #3000000; $display("[CE] TIMEOUT"); $finish; end
endmodule
