// Pipelined OcuLink NVMe SSD model for QD>1 testing. Unlike ssd_model.sv (one command in flight), the
// SQE-fetch (R channel) and the data+CQE (AW/W/B channel) run as two CONCURRENT threads, so several commands
// are in flight at once: the fetcher pulls IO SQEs ahead (advancing io_sq_head across one coalesced SQ-tail
// doorbell jump, which the FPGA's MO-9 rendezvous-decouple now permits) while the data engine streams the
// read-payload + CQE of earlier commands. Read-payload is written as back-to-back 8-beat (256 B = MPS) MemWr
// bursts then a 1-beat CQE -- the exact interleave the HW QD>1 read anomaly lives in. Reads use npages<=2
// (PRP2 = page2 direct, no PRP-list) which is enough to reproduce the anomaly (it appeared at every size).
// The tb checks cpl_count == (2 admin + N) and w_data_beats == N*(nlb+1)*16 (no drop, no CQE inflation).
`timescale 1ns/1ps
module ssd_model_pipe #(
  parameter ASQ_BAR  = 32'h8000,
  parameter ACQ_BAR  = 32'h9000,
  parameter IOCQ_BAR = 32'hA000,
  parameter IOSQ_BAR = 32'hB000,
  parameter IORW_BAR = 32'hC000,
  parameter NVME_BAR  = 32'h8000_4000,
  parameter ADB_OFF   = 32'h1000 + NVME_BAR,
  parameter IODB_OFF  = 32'h1008 + NVME_BAR,
  parameter ACQDB_OFF = 32'h1004 + NVME_BAR,
  parameter ICQDB_OFF = 32'h100C + NVME_BAR,
  parameter CQ_DEPTH  = 64
)(
  input  logic         clk,
  input  logic         rstn,
  output logic         s_awready,
  input  logic [31:0]  s_awaddr,  input logic [1:0] s_awburst, input logic [3:0] s_awid,
  input  logic [7:0]   s_awlen,   input logic [3:0] s_awregion, input logic [2:0] s_awsize, input logic s_awvalid,
  output logic         s_wready,
  input  logic [255:0] s_wdata,   input logic s_wlast, input logic [31:0] s_wstrb, input logic s_wvalid,
  input  logic         s_bready,  output logic [3:0] s_bid, output logic [1:0] s_bresp, output logic s_bvalid,
  input  logic         m_arready, output logic [31:0] m_araddr, output logic [1:0] m_arburst,
  output logic [3:0]   m_arcache, output logic [3:0] m_arid, output logic [7:0] m_arlen,
  output logic         m_arlock,  output logic [2:0] m_arprot, output logic [2:0] m_arsize, output logic m_arvalid,
  input  logic         m_awready, output logic [31:0] m_awaddr, output logic [1:0] m_awburst,
  output logic [3:0]   m_awcache, output logic [3:0] m_awid, output logic [7:0] m_awlen,
  output logic         m_awlock,  output logic [2:0] m_awprot, output logic [2:0] m_awsize, output logic m_awvalid,
  input  logic         m_wready,  output logic [255:0] m_wdata, output logic m_wlast, output logic [31:0] m_wstrb,
  output logic         m_wvalid,
  output logic         m_rready,  input logic [255:0] m_rdata, input logic [3:0] m_rid, input logic m_rlast,
  input  logic [1:0]   m_rresp,   input logic m_rvalid,
  output logic         m_bready,  input logic [3:0] m_bid, input logic [1:0] m_bresp, input logic m_bvalid
);
  // ---- doorbell registers (s_axi slave) ----
  int io_sq_tail = 0, a_sq_tail = 0, io_cq_head = 0, a_cq_head = 0;
  int io_sq_head = 0, a_sq_head = 0;
  int io_cq_tail = 0, a_cq_tail = 0, io_cpl_phase = 1, a_cpl_phase = 1;
  assign s_awready = 1'b1; assign s_wready = 1'b1; assign s_bid = 0; assign s_bresp = 0;
  logic [31:0] db_addr;
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin s_bvalid<=0; db_addr<=0; io_sq_tail<=0; a_sq_tail<=0; io_cq_head<=0; a_cq_head<=0; end
    else begin
      if (s_awvalid) db_addr <= s_awaddr;
      s_bvalid <= 1'b0;
      if (s_wvalid && s_wlast) begin
        case (db_addr)
          IODB_OFF : io_sq_tail <= s_wdata[31:0];
          ADB_OFF  : a_sq_tail  <= s_wdata[31:0];
          ICQDB_OFF: io_cq_head <= s_wdata[31:0];
          ACQDB_OFF: a_cq_head  <= s_wdata[31:0];
          default  : ;
        endcase
        s_bvalid <= 1'b1;
      end
    end
  end

  initial begin
    m_arvalid=0; m_araddr=0; m_arlen=0; m_arsize=5; m_arburst=1; m_arcache=0; m_arid=0; m_arlock=0; m_arprot=0;
    m_awvalid=0; m_awaddr=0; m_awlen=0; m_awsize=5; m_awburst=1; m_awcache=0; m_awid=0; m_awlock=0; m_awprot=0;
    m_wvalid=0; m_wdata=0; m_wlast=0; m_wstrb='1; m_rready=1'b1; m_bready=1'b1;
  end

  // ---- completion queue: fetcher pushes a descriptor per fetched SQE, data engine pops + completes ----
  int q_admin [$];   // 1 = admin create (ACQ CQE, no data) ; 0 = IO read (IOCQ CQE + read payload)
  int q_nlb   [$];

  task automatic fetch_sqe(input [31:0] addr, output [255:0] b0, output [255:0] b1);
    int n; b0='0; b1='0; n=0; @(posedge clk);
    m_araddr<=addr; m_arlen<=1; m_arvalid<=1;
    do @(posedge clk); while(!m_arready);
    m_arvalid<=0;
    forever begin @(posedge clk);
      if (m_rvalid) begin if(n==0) b0=m_rdata; else b1=m_rdata; n++; if (m_rlast) break; end end
  endtask
  task automatic aw_burst(input [31:0] addr, input [7:0] len, input [255:0] fill);
    int i; @(posedge clk);
    m_awaddr<=addr; m_awlen<=len; m_awvalid<=1;
    do @(posedge clk); while(!m_awready);
    m_awvalid<=0;
    for (i=0;i<=len;i++) begin m_wdata<=fill; m_wstrb<='1; m_wlast<=(i==len); m_wvalid<=1;
      do @(posedge clk); while(!m_wready); end
    m_wvalid<=0; m_wlast<=0;
    forever begin @(posedge clk); if (m_bvalid) break; end
  endtask
  task automatic post_io_cqe();
    logic [255:0] cqe; cqe='0;
    cqe[127:96] = {15'd0, io_cpl_phase[0], 16'd0};
    cqe[95:64]  = {16'd1, io_sq_head[15:0]};
    aw_burst(IOCQ_BAR + io_cq_tail*16, 8'd0, cqe);
    io_cq_tail = (io_cq_tail+1) % CQ_DEPTH; if (io_cq_tail==0) io_cpl_phase = ~io_cpl_phase;
  endtask
  task automatic post_admin_cqe();
    logic [255:0] cqe; cqe='0;
    cqe[127:96] = {15'd0, a_cpl_phase[0], 16'd0};
    aw_burst(ACQ_BAR + a_cq_tail*16, 8'd0, cqe);
    a_cq_tail = (a_cq_tail+1) % CQ_DEPTH; if (a_cq_tail==0) a_cpl_phase = ~a_cpl_phase;
  endtask

  // ================= two concurrent controller threads =================
  logic [255:0] sqe0, sqe1; int opcode, nlb;
  initial begin
    @(posedge rstn); repeat(4) @(posedge clk);
    fork
      // ---- FETCHER (R): admin SQEs first, then pull IO SQEs ahead of the data engine ----
      forever begin
        if (a_sq_tail != a_sq_head) begin
          fetch_sqe(ASQ_BAR + a_sq_head*64, sqe0, sqe1);
          a_sq_head = (a_sq_head+1) % CQ_DEPTH;
          q_admin.push_back(1); q_nlb.push_back(0);
        end
        else if (io_sq_tail != io_sq_head) begin
          fetch_sqe(IOSQ_BAR + io_sq_head*64, sqe0, sqe1);
          nlb = sqe1[159:128];
          io_sq_head = (io_sq_head+1) % CQ_DEPTH;
          q_admin.push_back(0); q_nlb.push_back(nlb);
        end
        else @(posedge clk);
      end
      // ---- DATA ENGINE (AW/W/B): complete queued commands in order, back-to-back ----
      forever begin
        if (q_admin.size() > 0) begin
          int isadm, nb, beats, b, chunk;
          isadm = q_admin.pop_front(); nb = q_nlb.pop_front();
          if (isadm) begin
            post_admin_cqe();
          end else begin
            beats = (nb+1)*16;                       // read payload, 32 B beats
            b = 0;
            while (b < beats) begin
              chunk = (beats - b >= 8) ? 8 : (beats - b);   // 8-beat (256 B = MPS) MemWr bursts
              aw_burst(IORW_BAR + b*32, chunk-1, {8{32'hDADA_CAFE}});
              b += chunk;
            end
            post_io_cqe();
          end
        end else @(posedge clk);
      end
    join_none
  end
endmodule
