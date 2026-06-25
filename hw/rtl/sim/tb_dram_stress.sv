// ADVERSARIAL streaming test: identical traffic to tb_dram_path (256 KB single transfer through the 128 KB
// window) but the DDR4 model runs in SLOW mode (random latency + R/W bubbles + AR/AW accept delay) so the
// refill/drain can barely keep up with the SSD. This provokes the refill underrun / drain overrun; the hard
// producer/consumer interlock must make the SSD backpressure (rvalid/wready stall) and keep the data correct.
// Compile with -d NO_INTERLOCK against a stripped nvme_driver to confirm the SAME test FAILS without the gates.
`timescale 1ns/1ps
module tb_dram_stress;
  logic oculink_axi_clk=0, host_bram_clk=0, cp_clk=0, rstn=0;
  always #4 oculink_axi_clk = ~oculink_axi_clk;   // 125 MHz
  always #2 host_bram_clk   = ~host_bram_clk;     // 250 MHz
  always #3 cp_clk          = ~cp_clk;            // ~166 MHz (async)

  localparam int PAGES = 64, WORDS = PAGES*128;   // 256 KB = 8192 words
  logic [16:0] dbuf_addr=0; logic [31:0] dbuf_wdata=0; logic dbuf_we=0; logic [31:0] dbuf_rdata;
  logic cp_go_tgl=0; logic [1:0] cp_op=0; logic [15:0] cp_nwords=4096, cp_base=0; logic cp_busy;
  logic [31:0] d_awaddr; logic [7:0] d_awlen; logic d_awvalid, d_awready;
  logic [255:0] d_wdata; logic d_wlast, d_wvalid, d_wready;
  logic [1:0] d_bresp; logic d_bvalid, d_bready;
  logic [31:0] d_araddr; logic [7:0] d_arlen; logic d_arvalid, d_arready;
  logic [255:0] d_rdata; logic d_rlast, d_rvalid, d_rready; logic [1:0] d_rresp;

  logic m_arready; logic [31:0] m_araddr=0; logic [1:0] m_arburst=1; logic [3:0] m_arcache=0;
  logic [3:0] m_arid=0; logic [7:0] m_arlen=0; logic m_arlock=0; logic [2:0] m_arprot=0,m_arsize=5; logic m_arvalid=0;
  logic m_awready; logic [31:0] m_awaddr=0; logic [1:0] m_awburst=1; logic [3:0] m_awcache=0;
  logic [3:0] m_awid=0; logic [7:0] m_awlen=0; logic m_awlock=0; logic [2:0] m_awprot=0,m_awsize=5; logic m_awvalid=0;
  logic m_wready; logic [255:0] m_wdata=0; logic m_wlast=0; logic [31:0] m_wstrb='1; logic m_wvalid=0;
  logic m_rready=1; logic [255:0] m_rdata; logic [3:0] m_rid; logic m_rlast; logic [1:0] m_rresp; logic m_rvalid;
  logic m_bready=1; logic [3:0] m_bid; logic [1:0] m_bresp; logic m_bvalid;
  logic s_awready=1,s_wready=1,s_bvalid; logic [3:0] s_bid=0; logic [1:0] s_bresp=0;
  logic [31:0] s_awaddr; logic [1:0] s_awburst; logic [3:0] s_awid; logic [7:0] s_awlen; logic [3:0] s_awregion;
  logic [2:0] s_awsize; logic s_awvalid; logic [255:0] s_wdata; logic s_wlast; logic [31:0] s_wstrb; logic s_wvalid; logic s_bready;
  always_ff @(posedge oculink_axi_clk) s_bvalid <= s_wvalid & s_wlast;
  logic [31:0] nvme_addr=0, fpga_addr=0, nlb=0, cpl_status, cpl_count; logic cpl_done;
  logic [31:0] wrdata[7:0], rddata[7:0];
  localparam IORW = 32'hC000;

  // interlock-engagement monitors: cycles the SSD was forced to wait by the gates
  int rd_stall=0, wr_stall=0; logic in_rdburst=0;
  always @(posedge oculink_axi_clk) begin
    if (m_arvalid && m_arready) in_rdburst<=1; else if (m_rvalid && m_rready && m_rlast) in_rdburst<=0;
    if (in_rdburst && !m_rvalid) rd_stall++;     // mid read-burst but no data offered -> underrun gate held it
    if (m_wvalid && !m_wready)   wr_stall++;      // write-data held off -> overrun gate held it
  end

  nvme_driver dut (
    .rstn(rstn), .host_bram_clk(host_bram_clk), .oculink_axi_clk(oculink_axi_clk),
    .send_iocq_create_cmd(1'b0), .send_iosq_create_cmd(1'b0), .send_read_cmd(1'b0), .send_write_cmd(1'b0),
    .nvme_addr(nvme_addr), .fpga_addr(fpga_addr), .nlb(nlb), .cpl_done(cpl_done), .wrdata(wrdata), .rddata(rddata),
    .dbuf_addr(dbuf_addr), .dbuf_wdata(dbuf_wdata), .dbuf_we(dbuf_we), .dbuf_rdata(dbuf_rdata),
    .cp_clk(cp_clk), .cp_rstn(rstn), .cp_go_tgl(cp_go_tgl), .cp_op(cp_op), .cp_nwords(cp_nwords), .cp_base(cp_base), .cp_busy(cp_busy),
    .ddr4_awaddr(d_awaddr), .ddr4_awlen(d_awlen), .ddr4_awvalid(d_awvalid), .ddr4_awready(d_awready),
    .ddr4_wdata(d_wdata), .ddr4_wlast(d_wlast), .ddr4_wvalid(d_wvalid), .ddr4_wready(d_wready),
    .ddr4_bresp(d_bresp), .ddr4_bvalid(d_bvalid), .ddr4_bready(d_bready),
    .ddr4_araddr(d_araddr), .ddr4_arlen(d_arlen), .ddr4_arvalid(d_arvalid), .ddr4_arready(d_arready),
    .ddr4_rdata(d_rdata), .ddr4_rlast(d_rlast), .ddr4_rvalid(d_rvalid), .ddr4_rready(d_rready), .ddr4_rresp(d_rresp),
    .cpl_status(cpl_status), .cpl_count(cpl_count),
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
  ddr4_axi_model #(.AW(16), .SLOW(1)) mdl (.clk(cp_clk), .rstn(rstn),
    .awaddr(d_awaddr), .awlen(d_awlen), .awvalid(d_awvalid), .awready(d_awready),
    .wdata(d_wdata), .wlast(d_wlast), .wvalid(d_wvalid), .wready(d_wready),
    .bresp(d_bresp), .bvalid(d_bvalid), .bready(d_bready),
    .araddr(d_araddr), .arlen(d_arlen), .arvalid(d_arvalid), .arready(d_arready),
    .rdata(d_rdata), .rlast(d_rlast), .rvalid(d_rvalid), .rready(d_rready), .rresp(d_rresp));

  function automatic logic [255:0] patt(input int w); return {8{32'hBEEF0000 + w}}; endfunction
  task automatic wbuf_wr(input int word, input logic [255:0] val);
    for (int l=0;l<8;l++) begin @(posedge host_bram_clk); dbuf_addr<=(word<<5)|(l<<2); dbuf_wdata<=val[l*32+:32]; dbuf_we<=1; end
    @(posedge host_bram_clk); dbuf_we<=0;
  endtask
  task automatic rbuf2_rd(input int word, output logic [255:0] val);
    for (int l=0;l<8;l++) begin dbuf_addr<=(word<<5)|(l<<2); @(posedge host_bram_clk); @(posedge host_bram_clk); val[l*32+:32]=dbuf_rdata; end
  endtask
  task automatic do_op(input [1:0] op, input [15:0] nw, input [15:0] base, input bit wait_done);
    @(posedge host_bram_clk); cp_op<=op; cp_nwords<=nw; cp_base<=base; cp_go_tgl<=~cp_go_tgl;
    repeat(40) @(posedge cp_clk);
    if (wait_done) begin while (cp_busy) @(posedge cp_clk); repeat(4) @(posedge cp_clk); end
  endtask

  int i, p, b, bad; logic [255:0] got;
  initial begin
    repeat(20) @(posedge oculink_axi_clk); rstn=1; repeat(20) @(posedge oculink_axi_clk);

    for (i=0;i<4096;i++) wbuf_wr(i, patt(i));        do_op(0,4096,0,1);
    for (i=0;i<4096;i++) wbuf_wr(i, patt(4096+i));   do_op(0,4096,4096,1);
    do_op(2, WORDS, 0, 0);                            // refill start (no full prime: the interlock must cover it)
    repeat(800) @(posedge cp_clk);
    bad=0;
    for (p=0;p<PAGES;p++) begin
      @(posedge oculink_axi_clk); m_araddr<=IORW + p*32'h1000; m_arlen<=127; m_arvalid<=1;
      do @(posedge oculink_axi_clk); while(!m_arready); m_arvalid<=0;
      b=0;
      forever begin @(posedge oculink_axi_clk); if (m_rvalid&&m_rready) begin
        if (m_rdata!==patt(p*128+b)) begin bad++; if(bad<=4) $display("[ST] WR page %0d beat %0d got %h exp %h",p,b,m_rdata,patt(p*128+b)); end
        b++; if (m_rlast) break; end end
    end
    $display("[ST] WRITE 256KB SLOW-DDR4 streamed: %0d/%0d beats bad => %s  (rd-stall cyc=%0d)", bad, WORDS, bad==0?"PASS":"FAIL", rd_stall);

    do_op(3, WORDS, 0, 0);
    for (p=0;p<PAGES;p++) begin
      @(posedge oculink_axi_clk); m_awaddr<=IORW + p*32'h1000; m_awlen<=127; m_awvalid<=1;
      do @(posedge oculink_axi_clk); while(!m_awready); m_awvalid<=0;
      for (b=0;b<128;b++) begin m_wdata<=patt(8192+p*128+b); m_wlast<=(b==127); m_wvalid<=1; do @(posedge oculink_axi_clk); while(!m_wready); end
      m_wvalid<=0; m_wlast<=0;
    end
    do @(posedge cp_clk); while(cp_busy);
    bad=0;
    do_op(1,4096,0,1);    for (i=0;i<4096;i++) begin rbuf2_rd(i,got); if(got!==patt(8192+i)) begin bad++; if(bad<=4)$display("[ST] RD w%0d got %h",i,got); end end
    do_op(1,4096,4096,1); for (i=0;i<4096;i++) begin rbuf2_rd(i,got); if(got!==patt(8192+4096+i)) begin bad++; if(bad<=4)$display("[ST] RD2 w%0d got %h",i,got); end end
    $display("[ST] READ 256KB SLOW-DDR4 streamed: %0d/%0d words bad => %s  (wr-stall cyc=%0d)", bad, WORDS, bad==0?"PASS":"FAIL", wr_stall);
    $finish;
  end
  initial begin #400000000; $display("[ST] TIMEOUT"); $finish; end
endmodule
