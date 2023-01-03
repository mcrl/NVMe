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
  output logic [SQ_ADDR_WIDTH-1:0]   wrsq_awaddr,
  output logic [SQ_DATA_WIDTH-1:0]   wrsq_wdata,
  output logic [SQ_DATA_WIDTH/8-1:0] wrsq_wstrb,
  output logic [SQ_ADDR_WIDTH-1:0]   wrsq_araddr,
  input  logic [SQ_DATA_WIDTH-1:0]   wrsq_rdata,
  output logic [7:0] wrsq_awlen,
  output logic [2:0] wrsq_awsize,
  output logic [1:0] wrsq_awburst,
  output logic       wrsq_awvalid,
  input  logic       wrsq_awready,
  output logic       wrsq_wlast,
  output logic       wrsq_wvalid,
  input  logic       wrsq_wready,
  input  logic [1:0] wrsq_bresp,
  input  logic       wrsq_bvalid,
  output logic       wrsq_bready,
  output logic [7:0] wrsq_arlen,
  output logic [2:0] wrsq_arsize,
  output logic [1:0] wrsq_arburst,
  output logic       wrsq_arvalid,
  input  logic       wrsq_arready,
  input  logic [1:0] wrsq_rresp,
  input  logic       wrsq_rlast,
  input  logic       wrsq_rvalid,
  output logic       wrsq_rready
);

// This driver supports 16 outstanding read txns and 16 outstanding write txns.
localparam OUTSTANDING = 16;

// Inside a single driver, the address mapping is the following:
// Offset / Size   / Note
// 0      / 512MiB / PCIe Config
// 512MiB / 2MiB   / PCIe Memory
// 514MiB / 2MiB   / wrsq
// 516MiB / 2MiB   / wrbuf
// 518MiB / 2MiB   / wrcq
// 520MiB / 2MiB   / rdsq
// 522MiB / 2MiB   / rdbuf
// 524MiB / 2MiB   / rdcq
// We need the addresses of wrbuf and rdbuf to synthesize the commands.
localparam WRITE_BUF_BASE = 516 * 1024 * 1024;
localparam READ_BUF_BASE = 522 * 1024 * 1024;

// Write SQ handler (wrsqhdl)
// hp_aw -> (wrsq_aw, wrsq_w, wrbuf_aw)
// null -> wrsq_ar
// wrsq_r -> null
// state: sqtail, cid
// logic: check SQ is not full (wrsqhdl_sqtail + 1 != wrcqhdl_sqhead)
logic [$clog2(OUTSTANDING)-1:0] wrsqhdl_sqtail;
logic wrsqhdl_valid;
logic wrsqhdl_ready;
logic wrsqhdl_block0;
logic wrsqhdl_block1;
logic wrsqhdl_block2;
logic [$clog2(OUTSTANDING)-1:0] wrsqhdl_cid_idx;
logic wrsqhdl_cid_phase;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    wrsqhdl_sqtail <= 0;
    wrsqhdl_block0 <= 0;
    wrsqhdl_block1 <= 0;
    wrsqhdl_block2 <= 0;
    wrsqhdl_cid_idx <= 0;
    wrsqhdl_cid_phase <= 0;
  end else begin
    if (hp_awvalid & hp_awready) begin
      wrsqhdl_sqtail <= wrsqhdl_sqtail + 1;
      wrsqhdl_cid_idx <= wrsqhdl_cid_idx + 1;
      if (wrsqhdl_cid_idx == OUTSTANDING - 1) begin
        wrsqhdl_cid_phase <= ~wrsqhdl_cid_phase;
      end
    end
    wrsqhdl_block0 <= hp_awvalid & ~hp_awready & (wrsq_awready | wrsqhdl_block0);
    wrsqhdl_block1 <= hp_awvalid & ~hp_awready & (wrsq_wready | wrsqhdl_block1);
    wrsqhdl_block2 <= hp_awvalid & ~hp_awready & (wrbuf_awready | wrsqhdl_block2);
  end
end

always_comb begin
  // hp_aw -> (wrsq_aw, wrsq_w, wrbuf_aw)
  wrsqhdl_valid = hp_awvalid
                & ((wrsqhdl_sqtail + 1) % OUTSTANDING != wrcqhdl_sqhead)
                & wrcqhdl_cid_state[wrsqhdl_cid_idx] == wrsqhdl_cid_phase;
  wrsq_awvalid = wrsqhdl_valid & ~wrsqhdl_block0;
  wrsq_wvalid = wrsqhdl_valid & ~wrsqhdl_block1;
  wrbuf_awvalid = wrsqhdl_valid & ~wrsqhdl_block2;
  wrsqhdl_ready = (~wrsq_awvalid | wrsq_awready)
             & (~wrsq_wvalid | wrsq_wready)
             & (~wrbuf_awvalid | wrbuf_awready);
  hp_awready = wrsqhdl_ready & (wrsqhdl_valid | ~hp_awvalid);

  // wrsq_aw datapath
  wrsq_awaddr = wrsqhdl_sqtail * 64;
  wrsq_awlen = 0; // no burst (single beat)
  wrsq_awsize = 6; // 512b = 64B = 2^6B
  wrsq_awburst = 1; // INCR

  // wrsq_w datapath
  // synthesize write command
  wrsq_wdata[0 +: 32] = {
    16'(wrsqhdl_cid_idx), // cid
    2'b00, // use prp
    4'b0000, // reserved
    2'b00, // not fused
    8'h01 // opcode WRITE
  };
  wrsq_wdata[32 +: 32] = 1; // nsid == 1
  wrsq_wdata[64 +: 64] = 0; // CDW2-3 (not used; no end-to-end protection)
  wrsq_wdata[128 +: 64] = 0; // MPTR (not used)
  wrsq_wdata[192 +: 128] = WRITE_BUF_BASE + wrsqhdl_sqtail * 4096; // DPTR
  // Starting LBA is address divided by 4KB
  wrsq_wdata[320 +: 64] = hp_awaddr >> 12; // CDW10-11
  // Specify number of logical blocks as 0 (which means 1)
  // Other options are not used
  wrsq_wdata[384 +: 32] = 0; // CDW12
  // No hint for compression, sequential, latency, and frequency
  wrsq_wdata[416 +: 32] = 0; // CDW13
  wrsq_wdata[448 +: 32] = 0; // CDW14 (not used; no end-to-end protection)
  wrsq_wdata[480 +: 32] = 0; // CDW15 (not used; no end-to-end protection)
  wrsq_wstrb = '1;
  wrsq_wlast = 1;

  // wrbuf_aw datapath
  wrbuf_awaddr = wrsqhdl_sqtail * 4096;
  wrbuf_awlen = hp_awlen;
  wrbuf_awsize = hp_awsize;
  wrbuf_awburst = hp_awburst;

  // null -> wrsq_ar
  wrsq_arvalid = 0;
  wrsq_araddr = 0;
  wrsq_arlen = 0;
  wrsq_arsize = 0;
  wrsq_arburst = 0;

  // wrsq_r -> null
  wrsq_rready = 0;
end

// Write buffer handler (wrbufhdl)
// hp_w -> wrbuf_w
// null -> wrbuf_ar
// wrbuf_r -> null

always_comb begin
  // hp_w -> wrbuf_w
  wrbuf_wdata = hp_wdata;
  wrbuf_wstrb = hp_wstrb;
  wrbuf_wlast = hp_wlast;
  wrbuf_wvalid = hp_wvalid;
  hp_wready = wrbuf_wready;

  // null -> wrbuf_ar
  wrbuf_arvalid = 0;
  wrbuf_araddr = 0;
  wrbuf_arlen = 0;
  wrbuf_arsize = 0;
  wrbuf_arburst = 0;

  // wrbuf_r -> null
  wrbuf_rready = 0;
end

// Write SQ doorbell handler (wrsqdbhdl)
// (wrsq_b, wrbuf_b) -> (wrsqdb_aw, wrsqdb_w)
// null -> wrsqdb_ar
// wrsqdb_r -> null
// state: sqtail
logic [$clog2(OUTSTANDING)-1:0] wrsqdbhdl_sqtail;
logic wrsqdbhdl_valid;
logic wrsqdbhdl_ready;
logic wrsqdbhdl_block0;
logic wrsqdbhdl_block1;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    wrsqdbhdl_sqtail <= 0;
    wrsqdbhdl_block0 <= 0;
    wrsqdbhdl_block1 <= 0;
  end else begin
    if (wrsqdbhdl_valid & wrsqdbhdl_ready) begin
      wrsqdbhdl_sqtail <= wrsqdbhdl_sqtail + 1;
    end
    wrsqdbhdl_block0 <= wrsqdbhdl_valid & ~wrsqdbhdl_ready & (wrsqdb_awready | wrsqdbhdl_block0);
    wrsqdbhdl_block1 <= wrsqdbhdl_valid & ~wrsqdbhdl_ready & (wrsqdb_wready | wrsqdbhdl_block1);
  end
end

always_comb begin
  // (wrsq_b, wrbuf_b) -> (wrsqdb_aw, wrsqdb_w)
  wrsqdbhdl_valid = wrsq_bvalid & wrbuf_bvalid;
  wrsqdb_awvalid = wrsqdbhdl_valid & ~wrsqdbhdl_block0;
  wrsqdb_wvalid = wrsqdbhdl_valid & ~wrsqdbhdl_block1;
  wrsqdbhdl_ready = (~wrsqdb_awvalid | wrsqdb_awready)
                 & (~wrsqdb_wvalid | wrsqdb_wready);
  wrsq_bready = wrsqdbhdl_ready & (wrsqdbhdl_valid | ~wrsq_bvalid);
  wrbuf_bready = wrsqdbhdl_ready & (wrsqdbhdl_valid | ~wrbuf_bvalid);

  // wrsqdb_aw datapath
  wrsqdb_awaddr = 1008; // SQ1TDBL
  wrsqdb_awlen = 0; // single beat
  wrsqdb_awsize = 2; // 4B transfer
  wrsqdb_awburst = 1; // INCR

  // wrsqdb_w datapath
  // align at 8B since the bus is 16B
  wrsqdb_wdata = {
    32'0,
    32'((wrsqdbhdl_sqtail + 1) % OUTSTANDING),
    32'0,
    32'0
  };
  wrsqdb_wstrb = '1;
  wrsqdb_wlast = 1;

  // null -> wrsqdb_ar
  wrsqdb_arvalid = 0;
  wrsqdb_araddr = 0;
  wrsqdb_arlen = 0;
  wrsqdb_arsize = 0;
  wrsqdb_arburst = 0;

  // wrsqdb_r -> null
  wrsqdb_rready = 0;
end

// Write CQ polling handler (wrcqhdl)
// State machine:
// [IDLE]
// Goto BUSY_AR after consuming wrsqdb_b
// [BUSY_AR]
// Goto BUSY_R after generating wrcq_ar
// [BUSY_R]
// Goto BUSY_AR if phase does not match, Goto BUSY_DB if phase matches
// Consume wrcq_r
// [BUSY_DB]
// Generate (wrcqdb_aw, wrcqdb_w, hp_b)
// [ALWAYS]
// Consume wrcqdb_b
// Nullify wrcq_aw/w/b, wrcqdb_ar/r
typedef enum logic [1:0] {
  WRCQHDL_STATE_IDLE,
  WRCQHDL_STATE_BUSY_AR,
  WRCQHDL_STATE_BUSY_R,
  WRCQHDL_STATE_BUSY_DB
} wrcqhdl_state_t;

wrcqhdl_state_t wrcqhdl_state;
logic wrcqhdl_valid;
logic wrcqhdl_ready;
logic wrcqhdl_block0;
logic wrcqhdl_block1;
logic wrcqhdl_block2;
logic [$clog2(OUTSTANDING)-1:0] wrcqhdl_cqhead;
logic wrcqhdl_phase;
logic [$clog2(OUTSTANDING)-1:0] wrcqhdl_sqhead;
logic wrcqhdl_cid_state[OUTSTANDING];

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    wrcqhdl_state <= WRCQHDL_STATE_IDLE;
    wrcqhdl_block0 <= 0;
    wrcqhdl_block1 <= 0;
    wrcqhdl_block2 <= 0;
    wrcqhdl_cqhead <= 0;
    wrcqhdl_phase <= 0;
    wrcqhdl_sqhead <= 0;
    for (int i = 0; i < OUTSTANDING; ++i) begin
      wrcqhdl_cid_state[i] <= 0;
    end
  end else begin
    if (wrcqhdl_state == WRCQHDL_STATE_IDLE) begin
      if (wrsqdb_bvalid & wrsqdb_bready) begin
        wrcqhdl_state <= WRCQHDL_STATE_BUSY_AR;
      end
    end else if (wrcqhdl_state == WRCQHDL_STATE_BUSY_AR) begin
      if (wrcq_arvalid & wrcq_arready) begin
        wrcqhdl_state <= WRCQHDL_STATE_BUSY_R;
      end
    end else if (wrcqhdl_state == WRCQHDL_STATE_BUSY_R) begin
      if (wrcq_rvalid & wrcq_rready) begin
        // wrcq_rdata[0 +: 32] Command Specific DW0
        // wrcq_rdata[32 +: 32] Command Specific DW1
        // wrcq_rdata[64 +: 16] SQ Head Pointer
        // wrcq_rdata[80 +: 16] SQ Identifier
        // wrcq_rdata[96 +: 16] Command Identifier
        // wrcq_rdata[112] Phase Tag
        // wrcq_rdata[113 +: 15] Status
        if (wrcq_rdata[112] == wrcqhdl_phase) begin
          wrcqhdl_state <= WRCQHDL_STATE_BUSY_AR;
        end else begin
          wrcqhdl_state <= WRCQHDL_STATE_BUSY_DB;
          wrcqhdl_cqhead <= wrcqhdl_cqhead + 1;
          if (wrcqhdl_cqhead == OUTSTANDING - 1) begin
            wrcqhdl_phase <= ~wrcqhdl_phase;
          end
          wrcqhdl_sqhead <= wrcq_rdata[64 +: 16];
          // flip cid state
          wrcqhdl_cid_state[wrcq_rdata[96 +: $clog2(OUTSTANDING)]] <= ~wrcqhdl_cid_state[wrcq_rdata[96 +: $clog2(OUTSTANDING)]];
        end
      end
    end else if (wrcqhdl_state == WRCQHDL_STATE_BUSY_DB) begin
      wrcqhdl_block0 <= wrcqhdl_valid & ~wrcqhdl_ready & (wrcqdb_awready | wrcqhdl_block0);
      wrcqhdl_block1 <= wrcqhdl_valid & ~wrcqhdl_ready & (wrcqdb_wready | wrcqhdl_block1);
      wrcqhdl_block2 <= wrcqhdl_valid & ~wrcqhdl_ready & (hp_bready | wrcqhdl_block2);
      if (wrcqhdl_valid & wrcqhdl_ready) begin
        wrcqhdl_state <= WRCQHDL_STATE_IDLE;
      end
    end
  end
end

always_comb begin
  // Drive defaults
  // wrsqdb_b
  wrsqdb_bready = 0;
  
  // wrcq_ar
  wrcq_arvalid = 0;
  wrcq_araddr = wrcqhdl_cqhead * 16;
  wrcq_arlen = 0;
  wrcq_arsize = 4; // 16B = 2^4B
  wrcq_arburst = 1; // INCR

  // wrcq_r
  wrcq_rready = 0;

  // wrcqdb_aw
  wrcqdb_awvalid = 0;
  wrcqdb_awaddr = 1012; // CQ1HDBL
  wrcqdb_awlen = 0; // single beat
  wrcqdb_awsize = 2; // 4B transfer
  wrcqdb_awburst = 1; // INCR

  // wrcqdb_w
  wrcqdb_wvalid = 0;
  wrcqdb_wdata = {
    32'(wrcqhdl_cqhead),
    32'0,
    32'0,
    32'0
  };
  wrcqdb_wstrb = '1;
  wrcqdb_wlast = 1;

  // hp_b
  hp_bvalid = 0;
  hp_bresp = 0;

  // wrcqhdl_valid/ready
  wrcqhdl_valid = 0;
  wrcqhdl_ready = 0;
  
  if (wrcqhdl_state == WRCQHDL_STATE_IDLE) begin
    wrsqdb_bready = 1;
  end else if (wrcqhdl_state == WRCQHDL_STATE_BUSY_AR) begin
    wrcq_arvalid = 1;
  end else if (wrcqhdl_state == WRCQHDL_STATE_BUSY_R) begin
    wrcq_rready = 1;
  end else begin
    // Generate (wrcqdb_aw, wrcqdb_w, hp_b)
    wrcqhdl_valid = 1;
    wrcqdb_awvalid = wrcqhdl_valid & ~wrcqhdl_block0;
    wrcqdb_wvalid = wrcqhdl_valid & ~wrcqhdl_block1;
    hp_bvalid = wrcqhdl_valid & ~wrcqhdl_block2;
    wrcqhdl_ready = (~wrcqdb_awvalid | wrcqdb_awready)
              & (~wrcqdb_wvalid | wrcqdb_wready)
              & (~hp_bvalid | hp_bready);
  end

  // Consume wrcqdb_b
  wrcqdb_bready = 1;

  // null -> wrcq_aw
  wrcq_awvalid = 0;
  wrcq_awaddr = 0;
  wrcq_awlen = 0;
  wrcq_awsize = 0;
  wrcq_awburst = 0;

  // null -> wrcq_w
  wrcq_wvalid = 0;
  wrcq_wdata = 0;
  wrcq_wstrb = 0;
  wrcq_wlast = 0;

  // wrcq_b -> null
  wrcq_bready = 0;

  // null -> wrcqdb_ar
  wrcqdb_arvalid = 0;
  wrcqdb_araddr = 0;
  wrcqdb_arlen = 0;
  wrcqdb_arsize = 0;
  wrcqdb_arburst = 0;

  // wrcqdb_r -> null
  wrcqdb_rready = 0;
end

// 1. Generate new free cid and lock (request null, response cid) set.insert
// output new_cid_valid
// input new_cid_ready
// output new_cid
// 2. Unlock given cid (request cid, response null) set.remove
// input unlock_cid_valid
// output unlock_cid_ready
// input unlock_cid
// 3. Check cid is free in-order (request cid, response bool) set.find
// input is_free_cid_valid
// output is_free_cid_ready
// input is_free_cid

endmodule