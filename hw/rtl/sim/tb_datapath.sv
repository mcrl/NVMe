// Data-path integrity test for the real host buffer path (wbuf/rbuf). Drives nvme_driver's m_axi like the SSD
// and the dbuf host port like the host:
//   T1 (wbuf -> write-payload R): host writes a pattern into wbuf, SSD reads the data window (0xC000) -> the R
//       beats must equal the pattern.
//   T2 (read-payload W -> rbuf):  SSD writes a pattern to the data window (0xC000), host reads rbuf -> must match.
`timescale 1ns/1ps
module tb_datapath;
  logic oculink_axi_clk=0, host_bram_clk=0, rstn=0;
  always #4 oculink_axi_clk = ~oculink_axi_clk;   // 125 MHz
  always #2 host_bram_clk   = ~host_bram_clk;     // 250 MHz

  logic [31:0] nvme_addr=0, fpga_addr=0, nlb=0, cpl_status, cpl_count;
  logic        cpl_done;
  logic [31:0] wrdata [7:0]; logic [31:0] rddata [7:0];
  logic [12:0] dbuf_addr=0; logic [31:0] dbuf_wdata=0; logic dbuf_we=0; logic [31:0] dbuf_rdata;

  logic        s_awready,s_wready,s_bvalid; logic [3:0] s_bid; logic [1:0] s_bresp;
  logic [31:0] s_awaddr; logic [1:0] s_awburst; logic [3:0] s_awid; logic [7:0] s_awlen;
  logic [3:0]  s_awregion; logic [2:0] s_awsize; logic s_awvalid;
  logic [255:0] s_wdata; logic s_wlast; logic [31:0] s_wstrb; logic s_wvalid; logic s_bready;
  assign s_awready=1; assign s_wready=1; assign s_bid=0; assign s_bresp=0;
  always_ff @(posedge oculink_axi_clk) s_bvalid <= s_wvalid & s_wlast;

  logic        m_arready; logic [31:0] m_araddr=0; logic [1:0] m_arburst=1; logic [3:0] m_arcache=0;
  logic [3:0]  m_arid=0; logic [7:0] m_arlen=0; logic m_arlock=0; logic [2:0] m_arprot=0,m_arsize=5; logic m_arvalid=0;
  logic        m_awready; logic [31:0] m_awaddr=0; logic [1:0] m_awburst=1; logic [3:0] m_awcache=0;
  logic [3:0]  m_awid=0; logic [7:0] m_awlen=0; logic m_awlock=0; logic [2:0] m_awprot=0,m_awsize=5; logic m_awvalid=0;
  logic        m_wready; logic [255:0] m_wdata=0; logic m_wlast=0; logic [31:0] m_wstrb='1; logic m_wvalid=0;
  logic        m_rready=1; logic [255:0] m_rdata; logic [3:0] m_rid; logic m_rlast; logic [1:0] m_rresp; logic m_rvalid;
  logic        m_bready=1; logic [3:0] m_bid; logic [1:0] m_bresp; logic m_bvalid;

  localparam IORW = 32'hC000;

  nvme_driver dut (
    .rstn(rstn), .host_bram_clk(host_bram_clk), .oculink_axi_clk(oculink_axi_clk),
    .send_iocq_create_cmd(1'b0), .send_iosq_create_cmd(1'b0), .send_read_cmd(1'b0), .send_write_cmd(1'b0),
    .nvme_addr(nvme_addr), .fpga_addr(fpga_addr), .nlb(nlb),
    .cpl_done(cpl_done), .wrdata(wrdata), .rddata(rddata),
    .dbuf_addr(dbuf_addr), .dbuf_wdata(dbuf_wdata), .dbuf_we(dbuf_we), .dbuf_rdata(dbuf_rdata),
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

  function automatic logic [255:0] patt(input int i); return {8{32'hBEEF0000 + i}}; endfunction

  // host writes one 256-b wbuf word as 8x32-b lanes
  task automatic wbuf_wr(input int word, input logic [255:0] val);
    for (int l=0;l<8;l++) begin
      @(posedge host_bram_clk);
      dbuf_addr <= (word<<5)|(l<<2); dbuf_wdata <= val[l*32 +: 32]; dbuf_we <= 1;
    end
    @(posedge host_bram_clk); dbuf_we <= 0;
  endtask
  // host reads one 256-b rbuf word (8 lanes); dbuf_rdata is registered (1-cycle)
  task automatic rbuf_rd(input int word, output logic [255:0] val);
    for (int l=0;l<8;l++) begin
      dbuf_addr <= (1<<12)|(word<<5)|(l<<2);
      @(posedge host_bram_clk);   // addr applied
      @(posedge host_bram_clk);   // dbuf_rdata now = rbuf[addr] (registered)
      val[l*32 +: 32] = dbuf_rdata;
    end
  endtask

  int i, bad; logic [255:0] got, exp;
  initial begin
    repeat(20) @(posedge oculink_axi_clk); rstn=1; repeat(20) @(posedge oculink_axi_clk);

    // ---- T1: host fills wbuf, SSD reads the write-payload (0xC000), check R == pattern ----
    for (i=0;i<16;i++) wbuf_wr(i, patt(i));
    repeat(10) @(posedge oculink_axi_clk);
    @(posedge oculink_axi_clk); m_araddr<=IORW; m_arlen<=15; m_arvalid<=1;
    do @(posedge oculink_axi_clk); while(!m_arready); m_arvalid<=0;
    bad=0; i=0;
    forever begin @(posedge oculink_axi_clk);
      if (m_rvalid && m_rready) begin
        if (m_rdata !== patt(i)) begin bad++; if(bad<=3) $display("[DP] T1 beat %0d got %h exp %h",i,m_rdata,patt(i)); end
        i++; if (m_rlast) break;
      end
    end
    $display("[DP] T1 wbuf->write-payload: %0d beats, %0d mismatch => %s", i, bad, bad==0?"PASS":"FAIL");

    // ---- T2: SSD writes read-payload to 0xC000, host reads rbuf, check == pattern ----
    @(posedge oculink_axi_clk); m_awaddr<=IORW; m_awlen<=15; m_awvalid<=1;
    do @(posedge oculink_axi_clk); while(!m_awready); m_awvalid<=0;
    for (i=0;i<16;i++) begin
      m_wdata<={8{32'hCAFE0000 + i}}; m_wlast<=(i==15); m_wvalid<=1;
      do @(posedge oculink_axi_clk); while(!m_wready);
    end
    m_wvalid<=0; m_wlast<=0;
    repeat(20) @(posedge oculink_axi_clk);
    bad=0;
    for (i=0;i<16;i++) begin rbuf_rd(i, got); exp={8{32'hCAFE0000 + i}};
      if (got !== exp) begin bad++; if(bad<=3) $display("[DP] T2 word %0d got %h exp %h",i,got,exp); end end
    $display("[DP] T2 read-payload->rbuf: 16 words, %0d mismatch => %s", bad, bad==0?"PASS":"FAIL");
    $finish;
  end
  initial begin #2000000; $display("[DP] TIMEOUT"); $finish; end
endmodule
