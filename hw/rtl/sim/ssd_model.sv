// Behavioral OcuLink-side NVMe SSD model for simulating nvme_driver.
//  - s_axi (FPGA is master): receives doorbell writes (SQ tail / CQ head).
//  - m_axi (SSD is master): fetches SQEs, runs the data phase, posts CQEs.
// Designed to reproduce the multiple-outstanding behaviour: it can post CQEs back-to-back
// (pipelined writes) to stress the FPGA's completion-capture path.
`timescale 1ns/1ps
module ssd_model #(
  parameter ASQ_BAR  = 32'h8000,
  parameter ACQ_BAR  = 32'h9000,
  parameter IOCQ_BAR = 32'hA000,
  parameter IOSQ_BAR = 32'hB000,
  parameter IORW_BAR = 32'hC000,
  parameter NVME_BAR    = 32'h8000_4000,
  parameter ADB_OFF     = 32'h1000 + NVME_BAR,  // admin SQ tail
  parameter IODB_OFF    = 32'h1008 + NVME_BAR,  // IO SQ tail
  parameter ACQDB_OFF   = 32'h1004 + NVME_BAR,  // admin CQ head
  parameter ICQDB_OFF   = 32'h100C + NVME_BAR,  // IO CQ head
  parameter CQ_DEPTH    = 64,
  parameter bit PIPELINE_CPL = 1                // 1 = post CQEs back-to-back (stress); 0 = one at a time
)(
  input  logic         clk,
  input  logic         rstn,

  // s_axi : FPGA master writes doorbells to us (we are slave)
  output logic         s_awready,
  input  logic [31:0]  s_awaddr,
  input  logic [1:0]   s_awburst,
  input  logic [3:0]   s_awid,
  input  logic [7:0]   s_awlen,
  input  logic [3:0]   s_awregion,
  input  logic [2:0]   s_awsize,
  input  logic         s_awvalid,
  output logic         s_wready,
  input  logic [255:0] s_wdata,
  input  logic         s_wlast,
  input  logic [31:0]  s_wstrb,
  input  logic         s_wvalid,
  input  logic         s_bready,
  output logic [3:0]   s_bid,
  output logic [1:0]   s_bresp,
  output logic         s_bvalid,

  // m_axi : we are master into the FPGA
  input  logic         m_arready,
  output logic [31:0]  m_araddr,
  output logic [1:0]   m_arburst,
  output logic [3:0]   m_arcache,
  output logic [3:0]   m_arid,
  output logic [7:0]   m_arlen,
  output logic         m_arlock,
  output logic [2:0]   m_arprot,
  output logic [2:0]   m_arsize,
  output logic         m_arvalid,
  input  logic         m_awready,
  output logic [31:0]  m_awaddr,
  output logic [1:0]   m_awburst,
  output logic [3:0]   m_awcache,
  output logic [3:0]   m_awid,
  output logic [7:0]   m_awlen,
  output logic         m_awlock,
  output logic [2:0]   m_awprot,
  output logic [2:0]   m_awsize,
  output logic         m_awvalid,
  input  logic         m_wready,
  output logic [255:0] m_wdata,
  output logic         m_wlast,
  output logic [31:0]  m_wstrb,
  output logic         m_wvalid,
  output logic         m_rready,
  input  logic [255:0] m_rdata,
  input  logic [3:0]   m_rid,
  input  logic         m_rlast,
  input  logic [1:0]   m_rresp,
  input  logic         m_rvalid,
  output logic         m_bready,
  input  logic [3:0]   m_bid,
  input  logic [1:0]   m_bresp,
  input  logic         m_bvalid
);

  // ---------------- doorbell registers (updated by s_axi writes) ----------------
  int io_sq_tail = 0, a_sq_tail = 0;   // from FPGA SQ-tail doorbells
  int io_cq_head = 0, a_cq_head = 0;   // from FPGA CQ-head doorbells
  int io_sq_head = 0, a_sq_head = 0;   // our processed pointer
  int io_cq_tail = 0, a_cq_tail = 0;   // next CQ slot we post to
  int io_cpl_phase = 1, a_cpl_phase = 1;

  // ---------------- s_axi slave: accept doorbell writes ----------------
  assign s_awready = 1'b1;
  assign s_wready  = 1'b1;
  assign s_bid     = 4'd0;
  assign s_bresp   = 2'd0;
  logic [31:0] db_addr;
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      s_bvalid <= 1'b0; db_addr <= 0;
      io_sq_tail<=0; a_sq_tail<=0; io_cq_head<=0; a_cq_head<=0;
    end else begin
      if (s_awvalid) db_addr <= s_awaddr;
      s_bvalid <= 1'b0;
      if (s_wvalid && s_wlast) begin
        $display("[SSD-DB] t=%0t addr=%08h val=%0d", $time, db_addr, s_wdata[31:0]);
        case (db_addr)
          IODB_OFF : io_sq_tail <= s_wdata[31:0];
          ADB_OFF  : a_sq_tail  <= s_wdata[31:0];
          ICQDB_OFF: io_cq_head <= s_wdata[31:0];
          ACQDB_OFF: a_cq_head  <= s_wdata[31:0];
          default  : ;
        endcase
        s_bvalid <= 1'b1;   // ack the doorbell write
      end
    end
  end

  // ---------------- m_axi master defaults ----------------
  initial begin
    m_arvalid=0; m_araddr=0; m_arlen=0; m_arsize=3'd5; m_arburst=2'd1;
    m_arcache=0; m_arid=0; m_arlock=0; m_arprot=0;
    m_awvalid=0; m_awaddr=0; m_awlen=0; m_awsize=3'd5; m_awburst=2'd1;
    m_awcache=0; m_awid=0; m_awlock=0; m_awprot=0;
    m_wvalid=0; m_wdata=0; m_wlast=0; m_wstrb='1;
    m_rready=1'b1; m_bready=1'b1;
  end

  // ---- AXI read burst (returns nothing; just drains R) ----
  task automatic axi_read(input [31:0] addr, input [7:0] len);
    int g; g=0;
    @(posedge clk);
    m_araddr<=addr; m_arlen<=len; m_arvalid<=1'b1;
    do @(posedge clk); while(!m_arready);
    m_arvalid<=1'b0;
    // drain R beats (count them to verify the burst length)
    begin int nb; nb=0;
      forever begin
        @(posedge clk); g++;
        if (m_rvalid && m_rready) nb++;
        if (m_rvalid && m_rready && m_rlast) begin
          if (nb != (len+1)) $display("[SSD] BEATCOUNT addr=%08h got %0d beats, expected %0d", addr, nb, len+1);
          break;
        end
        if (g>2000) begin $display("[SSD] axi_read TIMEOUT addr=%08h len=%0d (no rlast)", addr, len); break; end
      end
    end
  endtask

  // ---- capture first 2 R beats of an SQE fetch ----
  task automatic fetch_sqe(input [31:0] addr, output [255:0] b0, output [255:0] b1);
    int n; b0='0; b1='0; n=0;
    @(posedge clk);
    m_araddr<=addr; m_arlen<=8'd1; m_arvalid<=1'b1;   // 2 beats
    do @(posedge clk); while(!m_arready);
    m_arvalid<=1'b0;
    forever begin
      @(posedge clk);
      if (m_rvalid) begin
        if (n==0) b0=m_rdata; else b1=m_rdata;
        n++;
        if (m_rlast) break;
      end
    end
  endtask

  // ---- AXI write burst of `len+1` beats (data = fill) ----
  task automatic axi_write(input [31:0] addr, input [7:0] len, input [255:0] fill);
    int i;
    @(posedge clk);
    m_awaddr<=addr; m_awlen<=len; m_awvalid<=1'b1;
    do @(posedge clk); while(!m_awready);
    m_awvalid<=1'b0;
    for (i=0;i<=len;i++) begin
      m_wdata<=fill; m_wstrb<='1; m_wlast<=(i==len); m_wvalid<=1'b1;
      do @(posedge clk); while(!m_wready);
    end
    m_wvalid<=1'b0; m_wlast<=1'b0;
    // wait B
    forever begin @(posedge clk); if (m_bvalid) break; end
  endtask

  // post one IO CQE (16B in low lane); SQ head id in DW2, status/phase in DW3
  task automatic post_io_cqe(input int cid);
    logic [255:0] cqe;
    cqe = '0;
    cqe[127:96] = {15'd0, io_cpl_phase[0], 16'd0}; // DW3: SC=0, phase, CID=0
    cqe[95:64]  = {16'd1, io_sq_head[15:0]};        // DW2: SQID=1, SQ head ptr
    axi_write(IOCQ_BAR + io_cq_tail*16, 8'd0, cqe);
    io_cq_tail = (io_cq_tail+1) % CQ_DEPTH;
    if (io_cq_tail==0) io_cpl_phase = ~io_cpl_phase;
  endtask

  task automatic post_admin_cqe();
    logic [255:0] cqe;
    cqe = '0;
    cqe[127:96] = {15'd0, a_cpl_phase[0], 16'd0};
    axi_write(ACQ_BAR + a_cq_tail*16, 8'd0, cqe);
    a_cq_tail = (a_cq_tail+1) % CQ_DEPTH;
    if (a_cq_tail==0) a_cpl_phase = ~a_cpl_phase;
  endtask

  // ---------------- main controller loop ----------------
  logic [255:0] sqe0, sqe1;
  logic [31:0]  opcode, prp1, slba, nlb;
  initial begin
    @(posedge rstn);
    repeat(4) @(posedge clk);
    forever begin
      // ADMIN first
      if (a_sq_tail != a_sq_head) begin
        $display("[SSD] t=%0t fetch ADMIN sqe slot %0d (a_sq_tail=%0d)", $time, a_sq_head, a_sq_tail);
        fetch_sqe(ASQ_BAR + a_sq_head*64, sqe0, sqe1);
        a_sq_head = (a_sq_head+1) % CQ_DEPTH;
        repeat(2) @(posedge clk);
        post_admin_cqe();
        $display("[SSD] t=%0t posted ADMIN cqe (a_cq_tail now %0d)", $time, a_cq_tail);
      end
      else if (io_sq_tail != io_sq_head) begin
        $display("[SSD] t=%0t fetch IO sqe slot %0d (io_sq_tail=%0d)", $time, io_sq_head, io_sq_tail);
        fetch_sqe(IOSQ_BAR + io_sq_head*64, sqe0, sqe1);
        opcode = sqe0[31:0];
        prp1   = sqe0[223:192];
        slba   = sqe1[95:64];
        nlb    = sqe1[159:128];
        io_sq_head = (io_sq_head+1) % CQ_DEPTH;
        $display("[SSD] t=%0t IO sqe parsed op=%02h prp1=%08h slba=%0d nlb=%0d -> data phase", $time, opcode[7:0], prp1, slba, nlb);
        // data phase: write cmd (0x01) -> read data from FPGA ; read cmd (0x02) -> write data to FPGA
        if (opcode[7:0]==8'h01)      axi_read (prp1, (nlb[7:0]<<4) | 8'h0F);          // (nlb+1)*16 beats
        else if (opcode[7:0]==8'h02) axi_write(prp1, (nlb[7:0]<<4) | 8'h0F, 256'hDADA_CAFE);
        // wait for CQ space (FPGA must advance io_cq_head via CQ-head doorbell)
        while (((io_cq_tail - io_cq_head + CQ_DEPTH) % CQ_DEPTH) == CQ_DEPTH-1) @(posedge clk);
        $display("[SSD] t=%0t IO op=%02h slba=%0d nlb=%0d -> post cqe (io_cq_tail %0d, io_cq_head %0d)", $time, opcode[7:0], slba, nlb, io_cq_tail, io_cq_head);
        post_io_cqe(0);
        if (!PIPELINE_CPL) repeat(3) @(posedge clk);
      end
      else @(posedge clk);
    end
  end
endmodule
