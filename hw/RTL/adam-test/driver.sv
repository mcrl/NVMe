module driver #(
  parameter HP_ADDR_WIDTH = 48,
  parameter HP_DATA_WIDTH = 128,
  parameter LP_ADDR_WIDTH = 32,
  parameter LP_DATA_WIDTH = 32,
  parameter NL_ADDR_WIDTH = 32,
  parameter NL_DATA_WIDTH = 32,
  parameter NM_ADDR_WIDTH = 32,
  parameter NM_DATA_WIDTH = 128,
  parameter NS_ID_WIDTH = 4,
  parameter NS_ADDR_WIDTH = 32,
  parameter NS_DATA_WIDTH = 128,
  parameter SQ_ADDR_WIDTH = 10, // 16 * 64B = 1KB = 2^10B
  parameter SQ_DATA_WIDTH = 512 // 64B = 512b
) (
  input logic clk,
  input logic rstn,

  // AXIB slave
  input  logic [HP_ADDR_WIDTH-1:0]   hp_awaddr,
  input  logic [HP_DATA_WIDTH-1:0]   hp_wdata,
  input  logic [HP_DATA_WIDTH/8-1:0] hp_wstrb,
  input  logic [HP_ADDR_WIDTH-1:0]   hp_araddr,
  output logic [HP_DATA_WIDTH-1:0]   hp_rdata,
  input  logic [7:0] hp_awlen,
  input  logic [2:0] hp_awsize,
  input  logic [1:0] hp_awburst,
  input  logic       hp_awvalid,
  output logic       hp_awready,
  input  logic       hp_wlast,
  input  logic       hp_wvalid,
  output logic       hp_wready,
  output logic [1:0] hp_bresp,
  output logic       hp_bvalid,
  input  logic       hp_bready,
  input  logic [7:0] hp_arlen,
  input  logic [2:0] hp_arsize,
  input  logic [1:0] hp_arburst,
  input  logic       hp_arvalid,
  output logic       hp_arready,
  output logic [1:0] hp_rresp,
  output logic       hp_rlast,
  output logic       hp_rvalid,
  input  logic       hp_rready,

  // AXIL slave
  input  logic [LP_ADDR_WIDTH-1:0]   lp_awaddr,
  input  logic [LP_DATA_WIDTH-1:0]   lp_wdata,
  input  logic [LP_DATA_WIDTH/8-1:0] lp_wstrb,
  input  logic [LP_ADDR_WIDTH-1:0]   lp_araddr,
  output logic [LP_DATA_WIDTH-1:0]   lp_rdata,
  input  logic       lp_awvalid,
  output logic       lp_awready,
  input  logic       lp_wvalid,
  output logic       lp_wready,
  output logic [1:0] lp_bresp,
  output logic       lp_bvalid,
  input  logic       lp_bready,
  input  logic       lp_arvalid,
  output logic       lp_arready,
  output logic [1:0] lp_rresp,
  output logic       lp_rvalid,
  input  logic       lp_rready,

  // AXIL master
  output logic [NL_ADDR_WIDTH-1:0]   nl_awaddr,
  output logic [NL_DATA_WIDTH-1:0]   nl_wdata,
  output logic [NL_DATA_WIDTH/8-1:0] nl_wstrb,
  output logic [NL_ADDR_WIDTH-1:0]   nl_araddr,
  input  logic [NL_DATA_WIDTH-1:0]   nl_rdata,
  output logic       nl_awvalid,
  input  logic       nl_awready,
  output logic       nl_wvalid,
  input  logic       nl_wready,
  input  logic [1:0] nl_bresp,
  input  logic       nl_bvalid,
  output logic       nl_bready,
  output logic       nl_arvalid,
  input  logic       nl_arready,
  input  logic [1:0] nl_rresp,
  input  logic       nl_rvalid,
  output logic       nl_rready,

  // AXIB master
  output logic [NM_ADDR_WIDTH-1:0]   nm_awaddr,
  output logic [NM_DATA_WIDTH-1:0]   nm_wdata,
  output logic [NM_DATA_WIDTH/8-1:0] nm_wstrb,
  output logic [NM_ADDR_WIDTH-1:0]   nm_araddr,
  input  logic [NM_DATA_WIDTH-1:0]   nm_rdata,
  output logic [7:0] nm_awlen,
  output logic [2:0] nm_awsize,
  output logic [1:0] nm_awburst,
  output logic       nm_awvalid,
  input  logic       nm_awready,
  output logic       nm_wlast,
  output logic       nm_wvalid,
  input  logic       nm_wready,
  input  logic [1:0] nm_bresp,
  input  logic       nm_bvalid,
  output logic       nm_bready,
  output logic [7:0] nm_arlen,
  output logic [2:0] nm_arsize,
  output logic [1:0] nm_arburst,
  output logic       nm_arvalid,
  input  logic       nm_arready,
  input  logic [1:0] nm_rresp,
  input  logic       nm_rlast,
  input  logic       nm_rvalid,
  output logic       nm_rready,

  // AXIB slave
  input  logic [NS_ID_WIDTH-1:0]     ns_awid,
  input  logic [NS_ADDR_WIDTH-1:0]   ns_awaddr,
  input  logic [NS_DATA_WIDTH-1:0]   ns_wdata,
  input  logic [NS_DATA_WIDTH/8-1:0] ns_wstrb,
  output logic [NS_ID_WIDTH-1:0]     ns_bid,
  input  logic [NS_ID_WIDTH-1:0]     ns_arid,
  input  logic [NS_ADDR_WIDTH-1:0]   ns_araddr,
  output logic [NS_ID_WIDTH-1:0]     ns_rid,
  output logic [NS_DATA_WIDTH-1:0]   ns_rdata,
  input  logic [7:0] ns_awlen,
  input  logic [2:0] ns_awsize,
  input  logic [1:0] ns_awburst,
  input  logic       ns_awvalid,
  output logic       ns_awready,
  input  logic       ns_wlast,
  input  logic       ns_wvalid,
  output logic       ns_wready,
  output logic [1:0] ns_bresp,
  output logic       ns_bvalid,
  input  logic       ns_bready,
  input  logic [7:0] ns_arlen,
  input  logic [2:0] ns_arsize,
  input  logic [1:0] ns_arburst,
  input  logic       ns_arvalid,
  output logic       ns_arready,
  output logic [1:0] ns_rresp,
  output logic       ns_rlast,
  output logic       ns_rvalid,
  input  logic       ns_rready,

  // AXIB master
  output logic [SQ_ADDR_WIDTH-1:0]   sq_awaddr,
  output logic [SQ_DATA_WIDTH-1:0]   sq_wdata,
  output logic [SQ_DATA_WIDTH/8-1:0] sq_wstrb,
  output logic [SQ_ADDR_WIDTH-1:0]   sq_araddr,
  input  logic [SQ_DATA_WIDTH-1:0]   sq_rdata,
  output logic [7:0] sq_awlen,
  output logic [2:0] sq_awsize,
  output logic [1:0] sq_awburst,
  output logic       sq_awvalid,
  input  logic       sq_awready,
  output logic       sq_wlast,
  output logic       sq_wvalid,
  input  logic       sq_wready,
  input  logic [1:0] sq_bresp,
  input  logic       sq_bvalid,
  output logic       sq_bready,
  output logic [7:0] sq_arlen,
  output logic [2:0] sq_arsize,
  output logic [1:0] sq_arburst,
  output logic       sq_arvalid,
  input  logic       sq_arready,
  input  logic [1:0] sq_rresp,
  input  logic       sq_rlast,
  input  logic       sq_rvalid,
  output logic       sq_rready
);

// Address mapping (assuming 16 outstanding txns)
// from nvme
// 0 ~ 64KB (64KB) write buf
// 64KB ~ 128KB (64KB) read buf
// 128KB ~ 129KB (1KB) SQ
// 129KB ~ 129.25KB (256B) CQ
localparam OUTSTANDING = 16;
localparam WRITE_BUF_BASE = 0;
localparam WRITE_BUF_SIZE = OUTSTANDING * 4096;
localparam READ_BUF_BASE = WRITE_BUF_BASE + WRITE_BUF_SIZE;
localparam SQ_BASE = READ_BUF_BASE + OUTSTANDING * 4096;
localparam CQ_BASE = SQ_BASE + OUTSTANDING * 64;

// A1. hp_aw comes
// A2. syntehsize command and write to sq_aw and sq_w
// A3. sq_b comes

// B1. hp_w comes
// B2. write to wb_aw and wb_w
// B3. wb_b comes (for full beats)

// C1. wait A3 and B3
// C2. goes hp_b
// C2. write doorbell via nm_aw and nm_w
// C3. nm_b comes

// below 2 steps happen outside of driver
// C4. ns_ar comes (for data)
// C5. ns_r goes

// C6. ns_aw and ns_w comes (for CQ)
// C7. ns_b goes

// SQ step
logic sq_valid;
logic sq_ready;

logic [$clog2(OUTSTANDING)-1:0] sq_sqtail;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    sq_sqtail <= 0;
  end else begin
    if (hp_awvalid & hp_awready) begin
      sq_sqtail <= sq_sqtail + 1;
    end
  end
end

// hp_aw -> (sq_aw, sq_w, wb_aw) glue logic
logic hp_aw_sq_aw_block;
logic hp_aw_sq_w_block;
logic hp_aw_wb_aw_block;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    hp_aw_sq_aw_block <= 0;
    hp_aw_sq_w_block <= 0;
    hp_aw_wb_aw_block <= 0;
  end else begin
    hp_aw_sq_aw_block <= hp_awvalid & ~hp_awready & (sq_awready | hp_aw_sq_aw_block);
    hp_aw_sq_w_block <= hp_awvalid & ~hp_awready & (sq_wready | hp_aw_sq_w_block);
    hp_aw_wb_aw_block <= hp_awvalid & ~hp_awready & (wb_awready | hp_aw_wb_aw_block);
  end
end

always_comb begin
  sq_awaddr = sq_sqtail * 64;
  sq_awlen = 0; // no burst (single beat)
  sq_awsize = 6; // 512b = 64B = 2^6B
  sq_awburst = 1; // INCR

  // synthesize write command
  sq_wdata[0 +: 32] = {
    16'(sq_sqtail), // sqtail as cid
    2'b00, // use prp
    4'b0000, // reserved
    2'b00, // not fused
    8'h01 // opcode WRITE
  };
  sq_wdata[32 +: 32] = 1; // nsid == 1
  sq_wdata[64 +: 64] = 0; // CDW2-3 (not used; no end-to-end protection)
  sq_wdata[128 +: 64] = 0; // MPTR (not used)
  sq_wdata[192 +: 128] = WRITE_BUF_BASE + sq_sqtail * 4096; // DPTR
  // Starting LBA is address divided by 4KB
  sq_wdata[320 +: 64] = hp_awaddr >> 12; // CDW10-11
  // Specify number of logical blocks as 0 (which means 1)
  // Other options are not used
  sq_wdata[384 +: 32] = 0; // CDW12
  // Not hint for compression, sequential, latency, and frequency
  sq_wdata[416 +: 32] = 0; // CDW13
  sq_wdata[448 +: 32] = 0; // CDW14 (not used; no end-to-end protection)
  sq_wdata[480 +: 32] = 0; // CDW15 (not used; no end-to-end protection)
  sq_wstrb = '1;
  sq_wlast = 1;

  wb_awaddr = sq_sqtail * 4096;
  wb_awlen = hp_awlen;
  wb_awsize = hp_awsize;
  wb_awburst = hp_awburst;

  sq_valid = hp_awvalid & ((sq_sqtail + 1) % OUTSTANDING != cqdb_sqhead);
  sq_awvalid = sq_valid & ~hp_aw_sq_aw_block;
  sq_wvalid = sq_valid & ~hp_aw_sq_w_block;
  wb_awvalid = sq_valid & ~hp_aw_wb_aw_block;
  sq_ready = (~sq_awvalid | sq_awready)
             & (~sq_wvalid | sq_wready)
             & (~wb_awvalid | wb_awready);
  hp_awready = sq_ready;
  
end

// hp_w -> wb_w glue logic
always_comb begin
  wb_wdata = hp_wdata;
  wb_wstrb = hp_wstrb;
  wb_wlast = hp_wlast;
  wb_wvalid = hp_wvalid;
  hp_wready = wb_wready;
end

// Nullify sq_ar, sq_r, wb_ar, wb_r
always_comb begin
  sq_araddr = 0;
  sq_arlen = 0;
  sq_arsize = 0;
  sq_arburst = 0;
  sq_arvalid = 0;
  sq_rready = 0;

  wb_araddr = 0;
  wb_arlen = 0;
  wb_arsize = 0;
  wb_arburst = 0;
  wb_arvalid = 0;
  wb_rready = 0;
end

// Doorbell step
// (sq_b, wb_b) -> (nmsq_aw, nmsq_w) glue logic
logic doorbell_valid;
logic doorbell_ready;
logic doorbell_nmsq_aw_block;
logic doorbell_nmsq_w_block;
logic [$clog2(OUTSTANDING)-1:0] doorbell_sqtail;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    doorbell_nmsq_aw_block <= 0;
    doorbell_nmsq_w_block <= 0;
    doorbell_sqtail <= 0;
  end else begin
    doorbell_nmsq_aw_block <= doorbell_valid & ~doorbell_ready & (nmsq_awready | doorbell_nmsq_aw_block);
    doorbell_nmsq_w_block <= doorbell_valid & ~doorbell_ready & (nmsq_wready | doorbell_nmsq_w_block);
    if (doorbell_valid & doorbell_ready) begin
      doorbell_sqtail <= doorbell_sqtail + 1;
    end
  end
end

always_comb begin
  doorbell_valid = sq_bvalid & wb_bvalid;
  nmsq_awvalid = doorbell_valid & ~doorbell_nmsq_aw_block;
  nmsq_wvalid = doorbell_valid & ~doorbell_nmsq_w_block;
  doorbell_ready = (~nmsq_awvalid | nmsq_awready)
                 & (~nmsq_wvalid | nmsq_wready);
  sq_bready = doorbell_ready & (doorbell_valid | ~sq_bvalid);
  wb_bready = doorbell_ready & (doorbell_valid | ~wb_bvalid);

  nmsq_awaddr = 1008; // SQ1TDBL
  nmsq_awlen = 0; // single beat
  nmsq_awsize = 2; // 4B transfer
  nmsq_awburst = 1; // INCR

  // align at 8B since the bus is 16B
  nmsq_wdata = {
    32'0,
    32'((doorbell_sqtail + 1) % OUTSTANDING),
    32'0,
    32'0
  };
  nmsq_wstrb = '1;
  nmsq_wlast = 1;
end

// Nullify nmsq_b
always_comb begin
  nmsq_bready = 1;
end

// CQ polling step
// Generate cq_ar
always_comb begin
  cq_araddr = cqdb_cqhead * 16;
  cq_arlen = 0;
  cq_arsize = 4; // 16B = 2^4B
  cq_arburst = 1; // INCR
  cq_arvalid = 1;
end

// CQ doorbell step
// cq_r -> (nmcq_aw, nmcq_w, hp_b)
// Fix cq_rready to 1, check phase tag to consume or not

logic cqdb_valid;
logic cqdb_ready;

logic cqdb_nmcq_aw_block;
logic cqdb_nmcq_w_block;
logic cqdb_hp_b_block;

logic [$clog2(OUTSTANDING)-1:0] cqdb_cqhead;
logic cqdb_phase;
logic [$clog2(OUTSTANDING)-1:0] cqdb_sqhead;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    cqdb_nmcq_aw_block <= 0;
    cqdb_nmcq_w_block <= 0;
    cqdb_hp_b_block <= 0;
    cqdb_cqhead <= 0;
    cqdb_phase <= 1;
    cqdb_sqhead <= 0;
  end else begin
    cqdb_nmcq_aw_block <= cqdb_valid & ~cqdb_ready & (nmcq_awready | cqdb_nmcq_aw_block);
    cqdb_nmcq_w_block <= cqdb_valid & ~cqdb_ready & (nmcq_wready | cqdb_nmcq_w_block);
    cqdb_hp_b_block <= cqdb_valid & ~cqdb_ready & (hp_bready | cqdb_hp_b_block);
    if (cqdb_valid & cqdb_ready) begin
      cqdb_cqhead <= cqdb_cqhead + 1;
      if (cqdb_cqhead == OUTSTANDING - 1) begin
        cqdb_phase <= ~cqdb_phase;
      end
      cqdb_sqhead <= cq_rdata[64 +: 16];
    end
  end
end

always_comb begin
  // cq_rdata[0 +: 32] Command Specific DW0
  // cq_rdata[32 +: 32] Command Specific DW1
  // cq_rdata[64 +: 16] SQ Head Pointer
  // cq_rdata[80 +: 16] SQ Identifier
  // cq_rdata[96 +: 16] Command Identifier
  // cq_rdata[112] Phase Tag
  // cq_rdata[113 +: 15] Status
  cqdb_valid = cq_rvalid & (cq_rdata[112] == cqdb_phase);
end

endmodule