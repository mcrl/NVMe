// Full DRAM-routed data path: host -> wbuf -> (copy engine) -> DDR4 -> wbuf2 -> SSD, and
// SSD -> rbuf -> (copy engine) -> DDR4 -> rbuf2 -> host. nvme_driver drives a ddr4_axi_model as DDR4.
//   T1 (write path): host fills wbuf, trigger write-copy, SSD reads the data window -> must equal the pattern
//                    (the bytes the SSD reads came from DDR4, via wbuf2).
//   T2 (read path):  SSD writes the data window (-> rbuf), trigger read-copy, host reads rbuf2 -> must match.
`timescale 1ns/1ps
module tb_dram_path;
  logic oculink_axi_clk=0, host_bram_clk=0, cp_clk=0, rstn=0;
  always #4 oculink_axi_clk = ~oculink_axi_clk;   // 125 MHz
  always #2 host_bram_clk   = ~host_bram_clk;     // 250 MHz
  always #3 cp_clk          = ~cp_clk;            // ~166 MHz (DDR4 ui_clk stand-in, async)

  logic [12:0] dbuf_addr=0; logic [31:0] dbuf_wdata=0; logic dbuf_we=0; logic [31:0] dbuf_rdata;
  logic [16:0] dbuf_addr17; assign dbuf_addr17 = {4'd0, dbuf_addr};
  // copy control
  logic cp_go_tgl=0, cp_go_read=0; logic [12:0] cp_nwords=512; logic cp_busy;
  // nvme_driver DDR4 AXI master <-> model
  logic [31:0] d_awaddr; logic [7:0] d_awlen; logic d_awvalid, d_awready;
  logic [255:0] d_wdata; logic d_wlast, d_wvalid, d_wready;
  logic [1:0] d_bresp; logic d_bvalid, d_bready;
  logic [31:0] d_araddr; logic [7:0] d_arlen; logic d_arvalid, d_arready;
  logic [255:0] d_rdata; logic d_rlast, d_rvalid, d_rready; logic [1:0] d_rresp;

  // SSD-side m_axi (FPGA is slave): tb drives like the SSD
  logic m_arready; logic [31:0] m_araddr=0; logic [1:0] m_arburst=1; logic [3:0] m_arcache=0;
  logic [3:0] m_arid=0; logic [7:0] m_arlen=0; logic m_arlock=0; logic [2:0] m_arprot=0,m_arsize=5; logic m_arvalid=0;
  logic m_awready; logic [31:0] m_awaddr=0; logic [1:0] m_awburst=1; logic [3:0] m_awcache=0;
  logic [3:0] m_awid=0; logic [7:0] m_awlen=0; logic m_awlock=0; logic [2:0] m_awprot=0,m_awsize=5; logic m_awvalid=0;
  logic m_wready; logic [255:0] m_wdata=0; logic m_wlast=0; logic [31:0] m_wstrb='1; logic m_wvalid=0;
  logic m_rready=1; logic [255:0] m_rdata; logic [3:0] m_rid; logic m_rlast; logic [1:0] m_rresp; logic m_rvalid;
  logic m_bready=1; logic [3:0] m_bid; logic [1:0] m_bresp; logic m_bvalid;
  // s_axi (doorbells) - unused, tie
  logic s_awready=1,s_wready=1,s_bvalid; logic [3:0] s_bid=0; logic [1:0] s_bresp=0;
  logic [31:0] s_awaddr; logic [1:0] s_awburst; logic [3:0] s_awid; logic [7:0] s_awlen; logic [3:0] s_awregion;
  logic [2:0] s_awsize; logic s_awvalid; logic [255:0] s_wdata; logic s_wlast; logic [31:0] s_wstrb; logic s_wvalid; logic s_bready;
  always_ff @(posedge oculink_axi_clk) s_bvalid <= s_wvalid & s_wlast;

  logic [31:0] nvme_addr=0, fpga_addr=0, nlb=0, cpl_status, cpl_count; logic cpl_done;
  logic [31:0] wrdata[7:0], rddata[7:0];
  localparam IORW = 32'hC000;

  nvme_driver dut (
    .rstn(rstn), .host_bram_clk(host_bram_clk), .oculink_axi_clk(oculink_axi_clk),
    .send_iocq_create_cmd(1'b0), .send_iosq_create_cmd(1'b0), .send_read_cmd(1'b0), .send_write_cmd(1'b0),
    .nvme_addr(nvme_addr), .fpga_addr(fpga_addr), .nlb(nlb), .cpl_done(cpl_done), .wrdata(wrdata), .rddata(rddata),
    .dbuf_addr(dbuf_addr17), .dbuf_wdata(dbuf_wdata), .dbuf_we(dbuf_we), .dbuf_rdata(dbuf_rdata),
    .cp_clk(cp_clk), .cp_rstn(rstn), .cp_go_tgl(cp_go_tgl), .cp_go_read(cp_go_read), .cp_nwords(cp_nwords), .cp_busy(cp_busy),
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

  ddr4_axi_model mdl (.clk(cp_clk), .rstn(rstn),
    .awaddr(d_awaddr), .awlen(d_awlen), .awvalid(d_awvalid), .awready(d_awready),
    .wdata(d_wdata), .wlast(d_wlast), .wvalid(d_wvalid), .wready(d_wready),
    .bresp(d_bresp), .bvalid(d_bvalid), .bready(d_bready),
    .araddr(d_araddr), .arlen(d_arlen), .arvalid(d_arvalid), .arready(d_arready),
    .rdata(d_rdata), .rlast(d_rlast), .rvalid(d_rvalid), .rready(d_rready), .rresp(d_rresp));

  function automatic logic [255:0] patt(input int i); return {8{32'hBEEF0000 + i}}; endfunction

  task automatic wbuf_wr(input int word, input logic [255:0] val);
    for (int l=0;l<8;l++) begin @(posedge host_bram_clk); dbuf_addr<=(word<<5)|(l<<2); dbuf_wdata<=val[l*32+:32]; dbuf_we<=1; end
    @(posedge host_bram_clk); dbuf_we<=0;
  endtask
  task automatic rbuf_rd(input int word, output logic [255:0] val);
    for (int l=0;l<8;l++) begin dbuf_addr<=(word<<5)|(l<<2); @(posedge host_bram_clk); @(posedge host_bram_clk); val[l*32+:32]=dbuf_rdata; end
  endtask
  task automatic do_copy(input logic is_read);
    @(posedge host_bram_clk); cp_go_read<=is_read; cp_go_tgl<=~cp_go_tgl;   // toggle (CDC'd inside)
    do @(posedge cp_clk); while(!cp_busy);    // wait copy start
    do @(posedge cp_clk); while(cp_busy);     // wait copy done
  endtask

  int i, bad; logic [255:0] got;
  initial begin
    repeat(20) @(posedge oculink_axi_clk); rstn=1; repeat(20) @(posedge oculink_axi_clk);

    // ---- T1 write path: host fills wbuf -> copy -> SSD reads wbuf2 ----
    for (i=0;i<16;i++) wbuf_wr(i, patt(i));
    do_copy(1'b0);                                       // wbuf -> DDR4 -> wbuf2
    @(posedge oculink_axi_clk); m_araddr<=IORW; m_arlen<=15; m_arvalid<=1;
    do @(posedge oculink_axi_clk); while(!m_arready); m_arvalid<=0;
    bad=0; i=0;
    forever begin @(posedge oculink_axi_clk); if (m_rvalid&&m_rready) begin
      if (m_rdata!==patt(i)) begin bad++; if(bad<=3) $display("[DR] T1 beat %0d got %h exp %h",i,m_rdata,patt(i)); end
      i++; if (m_rlast) break; end end
    $display("[DR] T1 host->wbuf->DDR4->wbuf2->SSD: %0d beats, %0d mismatch => %s", i, bad, bad==0?"PASS":"FAIL");

    // ---- T2 read path: SSD writes rbuf -> copy -> host reads rbuf2 ----
    @(posedge oculink_axi_clk); m_awaddr<=IORW; m_awlen<=15; m_awvalid<=1;
    do @(posedge oculink_axi_clk); while(!m_awready); m_awvalid<=0;
    for (i=0;i<16;i++) begin m_wdata<={8{32'hCAFE0000+i}}; m_wlast<=(i==15); m_wvalid<=1; do @(posedge oculink_axi_clk); while(!m_wready); end
    m_wvalid<=0; m_wlast<=0; repeat(20) @(posedge oculink_axi_clk);
    do_copy(1'b1);                                       // rbuf -> DDR4 -> rbuf2
    bad=0;
    for (i=0;i<16;i++) begin rbuf_rd(i, got); if (got!=={8{32'hCAFE0000+i}}) begin bad++; if(bad<=3) $display("[DR] T2 word %0d got %h",i,got); end end
    $display("[DR] T2 SSD->rbuf->DDR4->rbuf2->host: 16 words, %0d mismatch => %s", bad, bad==0?"PASS":"FAIL");
    $finish;
  end
  initial begin #5000000; $display("[DR] TIMEOUT"); $finish; end
endmodule
