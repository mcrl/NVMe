module driver #(
  parameter HOST_ADDR_WIDTH = 21,
  parameter HOST_DATA_WIDTH = 32,
  parameter HP_ADDR_WIDTH = 48, // 256TB
  parameter HP_DATA_WIDTH = 128,
  parameter WRSQ_ADDR_WIDTH = 34, // 2MB
  parameter WRSQ_DATA_WIDTH = 512, // 64B = 512b
  parameter WRBUF_ADDR_WIDTH = 34, // 2MB
  parameter WRBUF_DATA_WIDTH = 128, // 128b
  parameter WRSQDB_ADDR_WIDTH = 34, // 4GB
  parameter WRSQDB_DATA_WIDTH = 128, // 128b
  parameter WRCQ_ADDR_WIDTH = 34, // 2MB
  parameter WRCQ_DATA_WIDTH = 128, // 16B = 128b
  parameter WRCQDB_ADDR_WIDTH = 34, // 4GB
  parameter WRCQDB_DATA_WIDTH = 128, // 16B = 128b
  parameter RDSQ_ADDR_WIDTH = 34, // 2MB
  parameter RDSQ_DATA_WIDTH = 512, // 64B = 512b
  parameter RDBUF_ADDR_WIDTH = 34, // 2MB
  parameter RDBUF_DATA_WIDTH = 128, // 128b
  parameter RDSQDB_ADDR_WIDTH = 34, // 4GB
  parameter RDSQDB_DATA_WIDTH = 128, // 128b
  parameter RDCQ_ADDR_WIDTH = 34, // 2MB
  parameter RDCQ_DATA_WIDTH = 128, // 16B = 128b
  parameter RDCQDB_ADDR_WIDTH = 34, // 4GB
  parameter RDCQDB_DATA_WIDTH = 128 // 16B = 128b
) (
  input logic clk,
  input logic rstn,

  // AXIL slave
  input  logic [HOST_ADDR_WIDTH-1:0]   host_awaddr,
  input  logic [HOST_DATA_WIDTH-1:0]   host_wdata,
  input  logic [HOST_DATA_WIDTH/8-1:0] host_wstrb,
  input  logic [HOST_ADDR_WIDTH-1:0]   host_araddr,
  output logic [HOST_DATA_WIDTH-1:0]   host_rdata,
  input  logic       host_awvalid,
  output logic       host_awready,
  input  logic       host_wvalid,
  output logic       host_wready,
  output logic [1:0] host_bresp,
  output logic       host_bvalid,
  input  logic       host_bready,
  input  logic       host_arvalid,
  output logic       host_arready,
  output logic [1:0] host_rresp,
  output logic       host_rvalid,
  input  logic       host_rready,

  // 1 AXIB slave : hp
  // 10 AXIB master : wrsq, wrbuf, wrsqdb, wrcq, wrcqdb, rdsq, rdbuf, rdsqdb, rdcq, rdcqdb

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

  output logic [WRSQ_ADDR_WIDTH-1:0]   wrsq_awaddr,
  output logic [WRSQ_DATA_WIDTH-1:0]   wrsq_wdata,
  output logic [WRSQ_DATA_WIDTH/8-1:0] wrsq_wstrb,
  output logic [WRSQ_ADDR_WIDTH-1:0]   wrsq_araddr,
  input  logic [WRSQ_DATA_WIDTH-1:0]   wrsq_rdata,
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
  output logic       wrsq_rready,

  output logic [WRBUF_ADDR_WIDTH-1:0]   wrbuf_awaddr,
  output logic [WRBUF_DATA_WIDTH-1:0]   wrbuf_wdata,
  output logic [WRBUF_DATA_WIDTH/8-1:0] wrbuf_wstrb,
  output logic [WRBUF_ADDR_WIDTH-1:0]   wrbuf_araddr,
  input  logic [WRBUF_DATA_WIDTH-1:0]   wrbuf_rdata,
  output logic [7:0] wrbuf_awlen,
  output logic [2:0] wrbuf_awsize,
  output logic [1:0] wrbuf_awburst,
  output logic       wrbuf_awvalid,
  input  logic       wrbuf_awready,
  output logic       wrbuf_wlast,
  output logic       wrbuf_wvalid,
  input  logic       wrbuf_wready,
  input  logic [1:0] wrbuf_bresp,
  input  logic       wrbuf_bvalid,
  output logic       wrbuf_bready,
  output logic [7:0] wrbuf_arlen,
  output logic [2:0] wrbuf_arsize,
  output logic [1:0] wrbuf_arburst,
  output logic       wrbuf_arvalid,
  input  logic       wrbuf_arready,
  input  logic [1:0] wrbuf_rresp,
  input  logic       wrbuf_rlast,
  input  logic       wrbuf_rvalid,
  output logic       wrbuf_rready,

  output logic [WRSQDB_ADDR_WIDTH-1:0]   wrsqdb_awaddr,
  output logic [WRSQDB_DATA_WIDTH-1:0]   wrsqdb_wdata,
  output logic [WRSQDB_DATA_WIDTH/8-1:0] wrsqdb_wstrb,
  output logic [WRSQDB_ADDR_WIDTH-1:0]   wrsqdb_araddr,
  input  logic [WRSQDB_DATA_WIDTH-1:0]   wrsqdb_rdata,
  output logic [7:0] wrsqdb_awlen,
  output logic [2:0] wrsqdb_awsize,
  output logic [1:0] wrsqdb_awburst,
  output logic       wrsqdb_awvalid,
  input  logic       wrsqdb_awready,
  output logic       wrsqdb_wlast,
  output logic       wrsqdb_wvalid,
  input  logic       wrsqdb_wready,
  input  logic [1:0] wrsqdb_bresp,
  input  logic       wrsqdb_bvalid,
  output logic       wrsqdb_bready,
  output logic [7:0] wrsqdb_arlen,
  output logic [2:0] wrsqdb_arsize,
  output logic [1:0] wrsqdb_arburst,
  output logic       wrsqdb_arvalid,
  input  logic       wrsqdb_arready,
  input  logic [1:0] wrsqdb_rresp,
  input  logic       wrsqdb_rlast,
  input  logic       wrsqdb_rvalid,
  output logic       wrsqdb_rready,

  output logic [WRCQ_ADDR_WIDTH-1:0]   wrcq_awaddr,
  output logic [WRCQ_DATA_WIDTH-1:0]   wrcq_wdata,
  output logic [WRCQ_DATA_WIDTH/8-1:0] wrcq_wstrb,
  output logic [WRCQ_ADDR_WIDTH-1:0]   wrcq_araddr,
  input  logic [WRCQ_DATA_WIDTH-1:0]   wrcq_rdata,
  output logic [7:0] wrcq_awlen,
  output logic [2:0] wrcq_awsize,
  output logic [1:0] wrcq_awburst,
  output logic       wrcq_awvalid,
  input  logic       wrcq_awready,
  output logic       wrcq_wlast,
  output logic       wrcq_wvalid,
  input  logic       wrcq_wready,
  input  logic [1:0] wrcq_bresp,
  input  logic       wrcq_bvalid,
  output logic       wrcq_bready,
  output logic [7:0] wrcq_arlen,
  output logic [2:0] wrcq_arsize,
  output logic [1:0] wrcq_arburst,
  output logic       wrcq_arvalid,
  input  logic       wrcq_arready,
  input  logic [1:0] wrcq_rresp,
  input  logic       wrcq_rlast,
  input  logic       wrcq_rvalid,
  output logic       wrcq_rready,

  output logic [WRCQDB_ADDR_WIDTH-1:0]   wrcqdb_awaddr,
  output logic [WRCQDB_DATA_WIDTH-1:0]   wrcqdb_wdata,
  output logic [WRCQDB_DATA_WIDTH/8-1:0] wrcqdb_wstrb,
  output logic [WRCQDB_ADDR_WIDTH-1:0]   wrcqdb_araddr,
  input  logic [WRCQDB_DATA_WIDTH-1:0]   wrcqdb_rdata,
  output logic [7:0] wrcqdb_awlen,
  output logic [2:0] wrcqdb_awsize,
  output logic [1:0] wrcqdb_awburst,
  output logic       wrcqdb_awvalid,
  input  logic       wrcqdb_awready,
  output logic       wrcqdb_wlast,
  output logic       wrcqdb_wvalid,
  input  logic       wrcqdb_wready,
  input  logic [1:0] wrcqdb_bresp,
  input  logic       wrcqdb_bvalid,
  output logic       wrcqdb_bready,
  output logic [7:0] wrcqdb_arlen,
  output logic [2:0] wrcqdb_arsize,
  output logic [1:0] wrcqdb_arburst,
  output logic       wrcqdb_arvalid,
  input  logic       wrcqdb_arready,
  input  logic [1:0] wrcqdb_rresp,
  input  logic       wrcqdb_rlast,
  input  logic       wrcqdb_rvalid,
  output logic       wrcqdb_rready,

  output logic [RDSQ_ADDR_WIDTH-1:0]   rdsq_awaddr,
  output logic [RDSQ_DATA_WIDTH-1:0]   rdsq_wdata,
  output logic [RDSQ_DATA_WIDTH/8-1:0] rdsq_wstrb,
  output logic [RDSQ_ADDR_WIDTH-1:0]   rdsq_araddr,
  input  logic [RDSQ_DATA_WIDTH-1:0]   rdsq_rdata,
  output logic [7:0] rdsq_awlen,
  output logic [2:0] rdsq_awsize,
  output logic [1:0] rdsq_awburst,
  output logic       rdsq_awvalid,
  input  logic       rdsq_awready,
  output logic       rdsq_wlast,
  output logic       rdsq_wvalid,
  input  logic       rdsq_wready,
  input  logic [1:0] rdsq_bresp,
  input  logic       rdsq_bvalid,
  output logic       rdsq_bready,
  output logic [7:0] rdsq_arlen,
  output logic [2:0] rdsq_arsize,
  output logic [1:0] rdsq_arburst,
  output logic       rdsq_arvalid,
  input  logic       rdsq_arready,
  input  logic [1:0] rdsq_rresp,
  input  logic       rdsq_rlast,
  input  logic       rdsq_rvalid,
  output logic       rdsq_rready,

  output logic [RDBUF_ADDR_WIDTH-1:0]   rdbuf_awaddr,
  output logic [RDBUF_DATA_WIDTH-1:0]   rdbuf_wdata,
  output logic [RDBUF_DATA_WIDTH/8-1:0] rdbuf_wstrb,
  output logic [RDBUF_ADDR_WIDTH-1:0]   rdbuf_araddr,
  input  logic [RDBUF_DATA_WIDTH-1:0]   rdbuf_rdata,
  output logic [7:0] rdbuf_awlen,
  output logic [2:0] rdbuf_awsize,
  output logic [1:0] rdbuf_awburst,
  output logic       rdbuf_awvalid,
  input  logic       rdbuf_awready,
  output logic       rdbuf_wlast,
  output logic       rdbuf_wvalid,
  input  logic       rdbuf_wready,
  input  logic [1:0] rdbuf_bresp,
  input  logic       rdbuf_bvalid,
  output logic       rdbuf_bready,
  output logic [7:0] rdbuf_arlen,
  output logic [2:0] rdbuf_arsize,
  output logic [1:0] rdbuf_arburst,
  output logic       rdbuf_arvalid,
  input  logic       rdbuf_arready,
  input  logic [1:0] rdbuf_rresp,
  input  logic       rdbuf_rlast,
  input  logic       rdbuf_rvalid,
  output logic       rdbuf_rready,

  output logic [RDSQDB_ADDR_WIDTH-1:0]   rdsqdb_awaddr,
  output logic [RDSQDB_DATA_WIDTH-1:0]   rdsqdb_wdata,
  output logic [RDSQDB_DATA_WIDTH/8-1:0] rdsqdb_wstrb,
  output logic [RDSQDB_ADDR_WIDTH-1:0]   rdsqdb_araddr,
  input  logic [RDSQDB_DATA_WIDTH-1:0]   rdsqdb_rdata,
  output logic [7:0] rdsqdb_awlen,
  output logic [2:0] rdsqdb_awsize,
  output logic [1:0] rdsqdb_awburst,
  output logic       rdsqdb_awvalid,
  input  logic       rdsqdb_awready,
  output logic       rdsqdb_wlast,
  output logic       rdsqdb_wvalid,
  input  logic       rdsqdb_wready,
  input  logic [1:0] rdsqdb_bresp,
  input  logic       rdsqdb_bvalid,
  output logic       rdsqdb_bready,
  output logic [7:0] rdsqdb_arlen,
  output logic [2:0] rdsqdb_arsize,
  output logic [1:0] rdsqdb_arburst,
  output logic       rdsqdb_arvalid,
  input  logic       rdsqdb_arready,
  input  logic [1:0] rdsqdb_rresp,
  input  logic       rdsqdb_rlast,
  input  logic       rdsqdb_rvalid,
  output logic       rdsqdb_rready,

  output logic [RDCQ_ADDR_WIDTH-1:0]   rdcq_awaddr,
  output logic [RDCQ_DATA_WIDTH-1:0]   rdcq_wdata,
  output logic [RDCQ_DATA_WIDTH/8-1:0] rdcq_wstrb,
  output logic [RDCQ_ADDR_WIDTH-1:0]   rdcq_araddr,
  input  logic [RDCQ_DATA_WIDTH-1:0]   rdcq_rdata,
  output logic [7:0] rdcq_awlen,
  output logic [2:0] rdcq_awsize,
  output logic [1:0] rdcq_awburst,
  output logic       rdcq_awvalid,
  input  logic       rdcq_awready,
  output logic       rdcq_wlast,
  output logic       rdcq_wvalid,
  input  logic       rdcq_wready,
  input  logic [1:0] rdcq_bresp,
  input  logic       rdcq_bvalid,
  output logic       rdcq_bready,
  output logic [7:0] rdcq_arlen,
  output logic [2:0] rdcq_arsize,
  output logic [1:0] rdcq_arburst,
  output logic       rdcq_arvalid,
  input  logic       rdcq_arready,
  input  logic [1:0] rdcq_rresp,
  input  logic       rdcq_rlast,
  input  logic       rdcq_rvalid,
  output logic       rdcq_rready,

  output logic [RDCQDB_ADDR_WIDTH-1:0]   rdcqdb_awaddr,
  output logic [RDCQDB_DATA_WIDTH-1:0]   rdcqdb_wdata,
  output logic [RDCQDB_DATA_WIDTH/8-1:0] rdcqdb_wstrb,
  output logic [RDCQDB_ADDR_WIDTH-1:0]   rdcqdb_araddr,
  input  logic [RDCQDB_DATA_WIDTH-1:0]   rdcqdb_rdata,
  output logic [7:0] rdcqdb_awlen,
  output logic [2:0] rdcqdb_awsize,
  output logic [1:0] rdcqdb_awburst,
  output logic       rdcqdb_awvalid,
  input  logic       rdcqdb_awready,
  output logic       rdcqdb_wlast,
  output logic       rdcqdb_wvalid,
  input  logic       rdcqdb_wready,
  input  logic [1:0] rdcqdb_bresp,
  input  logic       rdcqdb_bvalid,
  output logic       rdcqdb_bready,
  output logic [7:0] rdcqdb_arlen,
  output logic [2:0] rdcqdb_arsize,
  output logic [1:0] rdcqdb_arburst,
  output logic       rdcqdb_arvalid,
  input  logic       rdcqdb_arready,
  input  logic [1:0] rdcqdb_rresp,
  input  logic       rdcqdb_rlast,
  input  logic       rdcqdb_rvalid,
  output logic       rdcqdb_rready
);

// host handler

// hp_word_size is a size of burst from hp. (e.g., 128-bit 256-beat burst = 4096)
// nvme_word_size is lba size format of NVMe. (512 or 4096)

// Register map
// 0x00 RW hp_word_size_log2 (== log2(hp_word_size))
// 0x04 RW hp_burst_len (== hp_word_size / 16 - 1)
// 0x08 RW nvme_nlb (== hp_word_size / nvme_word_size, number of logical blocks, 0-base)
// 0x0c RW nvme_word_size_log2 (== log2(nvme_word_size))
logic [3:0] hp_word_size_log2;
logic [7:0] hp_burst_len;
logic [15:0] nvme_nlb;
logic [3:0] nvme_word_size_log2;

// glue logic
logic hostwrhdl_valid;
logic hostwrhdl_ready;
logic hostrdhdl_valid;
logic hostrdhdl_ready;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    host_bvalid <= 0;
    host_rvalid <= 0;
  end else begin
    if (hostwrhdl_valid & hostwrhdl_ready) begin
      host_bvalid <= 1;
      if          (host_awaddr == 'h00) begin
        hp_word_size_log2 <= host_wdata;
      end else if (host_awaddr == 'h04) begin
        hp_burst_len <= host_wdata;
      end else if (host_awaddr == 'h08) begin
        nvme_nlb <= host_wdata;
      end else if (host_awaddr == 'h0c) begin
        nvme_word_size_log2 <= host_wdata;
      end
    end
    if (host_bvalid & host_bready) begin
      host_bvalid <= 0;
    end
    if (hostrdhdl_valid & hostrdhdl_ready) begin
      host_rvalid <= 1;
      if          (host_araddr == 'h00) begin
        host_rdata <= hp_word_size_log2;
      end else if (host_araddr == 'h04) begin
        host_rdata <= hp_burst_len;
      end else if (host_araddr == 'h08) begin
        host_rdata <= nvme_nlb;
      end else if (host_araddr == 'h0c) begin
        host_rdata <= nvme_word_size_log2;
      end
    end
    if (host_rvalid & host_rready) begin
      host_rvalid <= 0;
    end
  end
end

always_comb begin
  // sync AW, W, bvalid (only accept when bvalid == 0)
  hostwrhdl_valid = host_awvalid & host_wvalid & (host_bvalid == 0);
  hostwrhdl_ready = 1;
  host_awready = hostwrhdl_ready & (hostwrhdl_valid | ~host_awvalid);
  host_wready = hostwrhdl_ready & (hostwrhdl_valid | ~host_wvalid);
  host_bresp = 0;
  // sync AR, rvalid (only accept when rvalid == 0)
  hostrdhdl_valid = host_arvalid & (host_rvalid == 0);
  hostrdhdl_ready = 1;
  host_arready = hostrdhdl_ready & (hostrdhdl_valid | ~host_arvalid);
  host_rresp = 0;
end

// This driver supports 16 outstanding read txns and 16 outstanding write txns.
localparam OUTSTANDING = 16;

// Base addresses
localparam WRSQ_ADDR_BASE  = 'h000000000;
localparam WRBUF_ADDR_BASE = 'h000200000;
localparam WRCQ_ADDR_BASE  = 'h000400000;
localparam RDSQ_ADDR_BASE  = 'h000600000;
localparam RDBUF_ADDR_BASE = 'h000800000;
localparam RDCQ_ADDR_BASE  = 'h000a00000;
localparam ADBUF_ADDR_BASE = 'h000c00000;
localparam NL_ADDR_BASE    = 'h200000000;
localparam NM_ADDR_BASE    = 'h300000000;

// NVMe Locations
localparam NVME_BAR0 = NM_ADDR_BASE + 'h80000000;
localparam SQ1TDBL = NVME_BAR0 + 'h1008;
localparam CQ1HDBL = NVME_BAR0 + 'h100c;
localparam SQ2TDBL = NVME_BAR0 + 'h1010;
localparam CQ2HDBL = NVME_BAR0 + 'h1014;

// Inter-module states
logic [OUTSTANDING-1:0] wrcqhdl_cid_state;
logic [$clog2(OUTSTANDING)-1:0] wrcqhdl_sqhead;
logic [OUTSTANDING-1:0] rdcqhdl_cid_state;
logic [$clog2(OUTSTANDING)-1:0] rdcqhdl_sqhead;

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
logic wrsqhdl_cid_phase;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    wrsqhdl_sqtail <= 0;
    wrsqhdl_block0 <= 0;
    wrsqhdl_block1 <= 0;
    wrsqhdl_block2 <= 0;
    wrsqhdl_cid_phase <= 0;
  end else begin
    if (wrsqhdl_valid & wrsqhdl_ready) begin
      wrsqhdl_sqtail <= (wrsqhdl_sqtail + 1) % OUTSTANDING;
      if (wrsqhdl_sqtail == OUTSTANDING - 1) begin
        wrsqhdl_cid_phase <= ~wrsqhdl_cid_phase;
      end
    end
    wrsqhdl_block0 <= wrsqhdl_valid & ~wrsqhdl_ready & (wrsq_awready | wrsqhdl_block0);
    wrsqhdl_block1 <= wrsqhdl_valid & ~wrsqhdl_ready & (wrsq_wready | wrsqhdl_block1);
    wrsqhdl_block2 <= wrsqhdl_valid & ~wrsqhdl_ready & (wrbuf_awready | wrsqhdl_block2);
  end
end

always_comb begin
  // hp_aw -> (wrsq_aw, wrsq_w, wrbuf_aw)
  wrsqhdl_valid = hp_awvalid
                & wrcqhdl_cid_state[wrsqhdl_sqtail] == wrsqhdl_cid_phase;
  wrsq_awvalid = wrsqhdl_valid & ~wrsqhdl_block0;
  wrsq_wvalid = wrsqhdl_valid & ~wrsqhdl_block1;
  wrbuf_awvalid = wrsqhdl_valid & ~wrsqhdl_block2;
  wrsqhdl_ready = (~wrsq_awvalid | wrsq_awready)
             & (~wrsq_wvalid | wrsq_wready)
             & (~wrbuf_awvalid | wrbuf_awready);
  hp_awready = wrsqhdl_ready & (wrsqhdl_valid | ~hp_awvalid);

  // wrsq_aw datapath
  wrsq_awaddr = WRSQ_ADDR_BASE + wrsqhdl_sqtail * 64;
  wrsq_awlen = 0; // no burst (single beat)
  wrsq_awsize = 6; // 512b = 64B = 2^6B
  wrsq_awburst = 1; // INCR

  // wrsq_w datapath
  // synthesize write command
  wrsq_wdata[0 +: 32] = {
    16'(wrsqhdl_sqtail), // cid
    2'b00, // use prp
    4'b0000, // reserved
    2'b00, // not fused
    8'h01 // opcode WRITE
  };
  wrsq_wdata[32 +: 32] = 1; // nsid == 1
  wrsq_wdata[64 +: 64] = 0; // CDW2-3 (not used; no end-to-end protection)
  wrsq_wdata[128 +: 64] = 0; // MPTR (not used)
  wrsq_wdata[192 +: 128] = WRBUF_ADDR_BASE + (wrsqhdl_sqtail << hp_word_size_log2); // DPTR
  // Starting LBA is address divided by 4KB
  wrsq_wdata[320 +: 64] = hp_awaddr >> nvme_word_size_log2; // CDW10-11
  // Specify number of logical blocks as 0 (which means 1)
  // Other options are not used
  wrsq_wdata[384 +: 32] = nvme_nlb; // CDW12
  // No hint for compression, sequential, latency, and frequency
  wrsq_wdata[416 +: 32] = 0; // CDW13
  wrsq_wdata[448 +: 32] = 0; // CDW14 (not used; no end-to-end protection)
  wrsq_wdata[480 +: 32] = 0; // CDW15 (not used; no end-to-end protection)
  wrsq_wstrb = '1;
  wrsq_wlast = 1;

  // wrbuf_aw datapath
  wrbuf_awaddr = WRBUF_ADDR_BASE + (wrsqhdl_sqtail << hp_word_size_log2);
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
      wrsqdbhdl_sqtail <= (wrsqdbhdl_sqtail + 1) % OUTSTANDING;
    end
    wrsqdbhdl_block0 <= wrsqdbhdl_valid & ~wrsqdbhdl_ready & (wrsqdb_awready | wrsqdbhdl_block0);
    wrsqdbhdl_block1 <= wrsqdbhdl_valid & ~wrsqdbhdl_ready & (wrsqdb_wready | wrsqdbhdl_block1);
  end
end

always_comb begin
  // (wrsq_b, wrbuf_b) -> (wrsqdb_aw, wrsqdb_w)
  wrsqdbhdl_valid = wrsq_bvalid & wrbuf_bvalid & ((wrsqdbhdl_sqtail + 1) % OUTSTANDING != wrcqhdl_sqhead);
  wrsqdb_awvalid = wrsqdbhdl_valid & ~wrsqdbhdl_block0;
  wrsqdb_wvalid = wrsqdbhdl_valid & ~wrsqdbhdl_block1;
  wrsqdbhdl_ready = (~wrsqdb_awvalid | wrsqdb_awready)
                 & (~wrsqdb_wvalid | wrsqdb_wready);
  wrsq_bready = wrsqdbhdl_ready & (wrsqdbhdl_valid | ~wrsq_bvalid);
  wrbuf_bready = wrsqdbhdl_ready & (wrsqdbhdl_valid | ~wrbuf_bvalid);

  // wrsqdb_aw datapath
  wrsqdb_awaddr = SQ1TDBL;
  wrsqdb_awlen = 0; // single beat
  wrsqdb_awsize = 2; // 4B transfer
  wrsqdb_awburst = 1; // INCR

  // wrsqdb_w datapath
  // align at 8B since the bus is 16B and SQ1TDBL % 16 == 8
  wrsqdb_wdata = {
    32'b0,
    32'((wrsqdbhdl_sqtail + 1) % OUTSTANDING),
    32'b0,
    32'b0
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
// Generate (wrcqdb_aw, wrcqdb_w)
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
logic [$clog2(OUTSTANDING)-1:0] wrcqhdl_cqhead;
logic wrcqhdl_phase;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    wrcqhdl_state <= WRCQHDL_STATE_IDLE;
    wrcqhdl_block0 <= 0;
    wrcqhdl_block1 <= 0;
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
          wrcqhdl_cqhead <= (wrcqhdl_cqhead + 1) % OUTSTANDING;
          if (wrcqhdl_cqhead == OUTSTANDING - 1) begin
            wrcqhdl_phase <= ~wrcqhdl_phase;
          end
          // flip cid state
          wrcqhdl_cid_state[wrcq_rdata[96 +: $clog2(OUTSTANDING)]] <= ~wrcqhdl_cid_state[wrcq_rdata[96 +: $clog2(OUTSTANDING)]];
          wrcqhdl_sqhead <= wrcq_rdata[64 +: 16];
        end
      end
    end else if (wrcqhdl_state == WRCQHDL_STATE_BUSY_DB) begin
      wrcqhdl_block0 <= wrcqhdl_valid & ~wrcqhdl_ready & (wrcqdb_awready | wrcqhdl_block0);
      wrcqhdl_block1 <= wrcqhdl_valid & ~wrcqhdl_ready & (wrcqdb_wready | wrcqhdl_block1);
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
  wrcq_araddr = WRCQ_ADDR_BASE + wrcqhdl_cqhead * 16;
  wrcq_arlen = 0;
  wrcq_arsize = 4; // 16B = 2^4B
  wrcq_arburst = 1; // INCR

  // wrcq_r
  wrcq_rready = 0;

  // wrcqdb_aw
  wrcqdb_awvalid = 0;
  wrcqdb_awaddr = CQ1HDBL;
  wrcqdb_awlen = 0; // single beat
  wrcqdb_awsize = 2; // 4B transfer
  wrcqdb_awburst = 1; // INCR

  // wrcqdb_w
  // align at 12B since the bus is 16B and CQ1HDBL % 16 == 12
  wrcqdb_wvalid = 0;
  wrcqdb_wdata = {
    32'(wrcqhdl_cqhead),
    32'b0,
    32'b0,
    32'b0
  };
  wrcqdb_wstrb = '1;
  wrcqdb_wlast = 1;

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
    // Generate (wrcqdb_aw, wrcqdb_w)
    wrcqhdl_valid = 1;
    wrcqdb_awvalid = wrcqhdl_valid & ~wrcqhdl_block0;
    wrcqdb_wvalid = wrcqhdl_valid & ~wrcqhdl_block1;
    wrcqhdl_ready = (~wrcqdb_awvalid | wrcqdb_awready)
                  & (~wrcqdb_wvalid | wrcqdb_wready);
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

// Write response handler (wrreshdl)
// Check cid, Generate hp_b
logic [$clog2(OUTSTANDING)-1:0] wrreshdl_cid_idx;
logic wrreshdl_cid_phase;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    wrreshdl_cid_idx <= 0;
    wrreshdl_cid_phase <= 0;
  end else begin
    if (hp_bvalid & hp_bready) begin
      wrreshdl_cid_idx <= (wrreshdl_cid_idx + 1) % OUTSTANDING;
      if (wrreshdl_cid_idx == OUTSTANDING - 1) begin
        wrreshdl_cid_phase <= ~wrreshdl_cid_phase;
      end
    end
  end
end

always_comb begin
  // hp_b
  hp_bvalid = wrcqhdl_cid_state[wrreshdl_cid_idx] != wrreshdl_cid_phase;
  hp_bresp = 0;
end

// Read SQ handler (rdsqhdl)
// hp_ar -> (rdsq_aw, rdsq_w)
// Nullify rdsq_ar, rdsq_r
// State: sqtail, cid
// Logic: Check SQ is not full
logic [$clog2(OUTSTANDING)-1:0] rdsqhdl_sqtail;
logic rdsqhdl_valid;
logic rdsqhdl_ready;
logic rdsqhdl_block0;
logic rdsqhdl_block1;
logic rdsqhdl_cid_phase;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    rdsqhdl_sqtail <= 0;
    rdsqhdl_block0 <= 0;
    rdsqhdl_block1 <= 0;
    rdsqhdl_cid_phase <= 0;
  end else begin
    if (rdsqhdl_valid & rdsqhdl_ready) begin
      rdsqhdl_sqtail <= (rdsqhdl_sqtail + 1) % OUTSTANDING;
      if (rdsqhdl_sqtail == OUTSTANDING - 1) begin
        rdsqhdl_cid_phase <= ~rdsqhdl_cid_phase;
      end
    end
    rdsqhdl_block0 <= rdsqhdl_valid & ~rdsqhdl_ready & (rdsq_awready | rdsqhdl_block0);
    rdsqhdl_block1 <= rdsqhdl_valid & ~rdsqhdl_ready & (rdsq_wready | rdsqhdl_block1);
  end
end

always_comb begin
  // hp_ar -> (rdsq_aw, rdsq_w)
  rdsqhdl_valid = hp_arvalid
                & rdcqhdl_cid_state[rdsqhdl_sqtail] == rdsqhdl_cid_phase;
  rdsq_awvalid = rdsqhdl_valid & ~rdsqhdl_block0;
  rdsq_wvalid = rdsqhdl_valid & ~rdsqhdl_block1;
  rdsqhdl_ready = (~rdsq_awvalid | rdsq_awready)
             & (~rdsq_wvalid | rdsq_wready);
  hp_arready = rdsqhdl_ready & (rdsqhdl_valid | ~hp_arvalid);

  // rdsq_aw datapath
  rdsq_awaddr = RDSQ_ADDR_BASE + rdsqhdl_sqtail * 64;
  rdsq_awlen = 0; // no burst (single beat)
  rdsq_awsize = 6; // 512b = 64B = 2^6B
  rdsq_awburst = 1; // INCR

  // rdsq_w datapath
  // synthesize read command
  rdsq_wdata[0 +: 32] = {
    16'(rdsqhdl_sqtail), // cid
    2'b00, // use prp
    4'b0000, // reserved
    2'b00, // not fused
    8'h02 // opcode READ
  };
  rdsq_wdata[32 +: 32] = 1; // nsid == 1
  rdsq_wdata[64 +: 64] = 0; // CDW2-3 (not used; no end-to-end protection)
  rdsq_wdata[128 +: 64] = 0; // MPTR (not used)
  rdsq_wdata[192 +: 128] = RDBUF_ADDR_BASE + (rdsqhdl_sqtail << hp_word_size_log2); // DPTR
  // Starting LBA is address divided by 4KB
  rdsq_wdata[320 +: 64] = hp_araddr >> nvme_word_size_log2; // CDW10-11
  // Specify number of logical blocks as 0 (which means 1)
  // Other options are not used
  rdsq_wdata[384 +: 32] = nvme_nlb; // CDW12
  // No hint for compression, sequential, latency, and frequency
  rdsq_wdata[416 +: 32] = 0; // CDW13
  rdsq_wdata[448 +: 32] = 0; // CDW14 (not used; no end-to-end protection)
  rdsq_wdata[480 +: 32] = 0; // CDW15 (not used; no end-to-end protection)
  rdsq_wstrb = '1;
  rdsq_wlast = 1;

  // null -> rdsq_ar
  rdsq_arvalid = 0;
  rdsq_araddr = 0;
  rdsq_arlen = 0;
  rdsq_arsize = 0;
  rdsq_arburst = 0;

  // rdsq_r -> null
  rdsq_rready = 0;
end

// Read SQ doorbell handler (rdsqdbhdl)
// rdsq_b -> (rdsqdb_aw, rdsqdb_w)
// null -> rdsqdb_ar
// rdsqdb_r -> null
// state: sqtail
logic [$clog2(OUTSTANDING)-1:0] rdsqdbhdl_sqtail;
logic rdsqdbhdl_valid;
logic rdsqdbhdl_ready;
logic rdsqdbhdl_block0;
logic rdsqdbhdl_block1;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    rdsqdbhdl_sqtail <= 0;
    rdsqdbhdl_block0 <= 0;
    rdsqdbhdl_block1 <= 0;
  end else begin
    if (rdsqdbhdl_valid & rdsqdbhdl_ready) begin
      rdsqdbhdl_sqtail <= (rdsqdbhdl_sqtail + 1) % OUTSTANDING;
    end
    rdsqdbhdl_block0 <= rdsqdbhdl_valid & ~rdsqdbhdl_ready & (rdsqdb_awready | rdsqdbhdl_block0);
    rdsqdbhdl_block1 <= rdsqdbhdl_valid & ~rdsqdbhdl_ready & (rdsqdb_wready | rdsqdbhdl_block1);
  end
end

always_comb begin
  // rdsq_b -> (rdsqdb_aw, rdsqdb_w)
  rdsqdbhdl_valid = rdsq_bvalid & ((rdsqdbhdl_sqtail + 1) % OUTSTANDING != rdcqhdl_sqhead);
  rdsqdb_awvalid = rdsqdbhdl_valid & ~rdsqdbhdl_block0;
  rdsqdb_wvalid = rdsqdbhdl_valid & ~rdsqdbhdl_block1;
  rdsqdbhdl_ready = (~rdsqdb_awvalid | rdsqdb_awready)
                 & (~rdsqdb_wvalid | rdsqdb_wready);
  rdsq_bready = rdsqdbhdl_ready;

  // rdsqdb_aw datapath
  rdsqdb_awaddr = SQ2TDBL;
  rdsqdb_awlen = 0; // single beat
  rdsqdb_awsize = 2; // 4B transfer
  rdsqdb_awburst = 1; // INCR

  // rdsqdb_w datapath
  // align at 0B since the bus is 16B and SQ2TDBL % 16 == 0
  rdsqdb_wdata = {
    32'b0,
    32'b0,
    32'b0,
    32'((rdsqdbhdl_sqtail + 1) % OUTSTANDING)
  };
  rdsqdb_wstrb = '1;
  rdsqdb_wlast = 1;

  // null -> rdsqdb_ar
  rdsqdb_arvalid = 0;
  rdsqdb_araddr = 0;
  rdsqdb_arlen = 0;
  rdsqdb_arsize = 0;
  rdsqdb_arburst = 0;

  // rdsqdb_r -> null
  rdsqdb_rready = 0;
end

// Read CQ polling handler (rdcqhdl)
// State machine:
// [IDLE]
// Goto BUSY_AR after consuming rdsqdb_b
// [BUSY_AR]
// Goto BUSY_R after generating rdcq_ar
// [BUSY_R]
// Goto BUSY_AR if phase does not match, Goto BUSY_DB if phase matches
// Consume rdcq_r
// [BUSY_DB]
// Generate (rdcqdb_aw, rdcqdb_w)
// [ALWAYS]
// Consume rdcqdb_b
// Nullify rdcq_aw/w/b, rdcqdb_ar/r
typedef enum logic [1:0] {
  RDCQHDL_STATE_IDLE,
  RDCQHDL_STATE_BUSY_AR,
  RDCQHDL_STATE_BUSY_R,
  RDCQHDL_STATE_BUSY_DB
} rdcqhdl_state_t;

rdcqhdl_state_t rdcqhdl_state;
logic rdcqhdl_valid;
logic rdcqhdl_ready;
logic rdcqhdl_block0;
logic rdcqhdl_block1;
logic [$clog2(OUTSTANDING)-1:0] rdcqhdl_cqhead;
logic rdcqhdl_phase;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    rdcqhdl_state <= RDCQHDL_STATE_IDLE;
    rdcqhdl_block0 <= 0;
    rdcqhdl_block1 <= 0;
    rdcqhdl_cqhead <= 0;
    rdcqhdl_phase <= 0;
    for (int i = 0; i < OUTSTANDING; ++i) begin
      rdcqhdl_cid_state[i] <= 0;
    end
    rdcqhdl_sqhead <= 0;
  end else begin
    if (rdcqhdl_state == RDCQHDL_STATE_IDLE) begin
      if (rdsqdb_bvalid & rdsqdb_bready) begin
        rdcqhdl_state <= RDCQHDL_STATE_BUSY_AR;
      end
    end else if (rdcqhdl_state == RDCQHDL_STATE_BUSY_AR) begin
      if (rdcq_arvalid & rdcq_arready) begin
        rdcqhdl_state <= RDCQHDL_STATE_BUSY_R;
      end
    end else if (rdcqhdl_state == RDCQHDL_STATE_BUSY_R) begin
      if (rdcq_rvalid & rdcq_rready) begin
        // rdcq_rdata[0 +: 32] Command Specific DW0
        // rdcq_rdata[32 +: 32] Command Specific DW1
        // rdcq_rdata[64 +: 16] SQ Head Pointer
        // rdcq_rdata[80 +: 16] SQ Identifier
        // rdcq_rdata[96 +: 16] Command Identifier
        // rdcq_rdata[112] Phase Tag
        // rdcq_rdata[113 +: 15] Status
        if (rdcq_rdata[112] == rdcqhdl_phase) begin
          rdcqhdl_state <= RDCQHDL_STATE_BUSY_AR;
        end else begin
          rdcqhdl_state <= RDCQHDL_STATE_BUSY_DB;
          rdcqhdl_cqhead <= (rdcqhdl_cqhead + 1) % OUTSTANDING;
          if (rdcqhdl_cqhead == OUTSTANDING - 1) begin
            rdcqhdl_phase <= ~rdcqhdl_phase;
          end
          // flip cid state
          rdcqhdl_cid_state[rdcq_rdata[96 +: $clog2(OUTSTANDING)]] <= ~rdcqhdl_cid_state[rdcq_rdata[96 +: $clog2(OUTSTANDING)]];
          rdcqhdl_sqhead <= rdcq_rdata[64 +: 16];
        end
      end
    end else if (rdcqhdl_state == RDCQHDL_STATE_BUSY_DB) begin
      rdcqhdl_block0 <= rdcqhdl_valid & ~rdcqhdl_ready & (rdcqdb_awready | rdcqhdl_block0);
      rdcqhdl_block1 <= rdcqhdl_valid & ~rdcqhdl_ready & (rdcqdb_wready | rdcqhdl_block1);
      if (rdcqhdl_valid & rdcqhdl_ready) begin
        rdcqhdl_state <= RDCQHDL_STATE_IDLE;
      end
    end
  end
end

always_comb begin
  // Drive defaults
  // rdsqdb_b
  rdsqdb_bready = 0;
  
  // rdcq_ar
  rdcq_arvalid = 0;
  rdcq_araddr = RDCQ_ADDR_BASE + rdcqhdl_cqhead * 16;
  rdcq_arlen = 0;
  rdcq_arsize = 4; // 16B = 2^4B
  rdcq_arburst = 1; // INCR

  // rdcq_r
  rdcq_rready = 0;

  // rdcqdb_aw
  rdcqdb_awvalid = 0;
  rdcqdb_awaddr = CQ2HDBL;
  rdcqdb_awlen = 0; // single beat
  rdcqdb_awsize = 2; // 4B transfer
  rdcqdb_awburst = 1; // INCR

  // rdcqdb_w
  // align at 4B since the bus is 16B and CQ2HDBL % 16 == 4
  rdcqdb_wvalid = 0;
  rdcqdb_wdata = {
    32'b0,
    32'b0,
    32'(rdcqhdl_cqhead),
    32'b0
  };
  rdcqdb_wstrb = '1;
  rdcqdb_wlast = 1;

  // rdcqhdl_valid/ready
  rdcqhdl_valid = 0;
  rdcqhdl_ready = 0;
  
  if (rdcqhdl_state == RDCQHDL_STATE_IDLE) begin
    rdsqdb_bready = 1;
  end else if (rdcqhdl_state == RDCQHDL_STATE_BUSY_AR) begin
    rdcq_arvalid = 1;
  end else if (rdcqhdl_state == RDCQHDL_STATE_BUSY_R) begin
    rdcq_rready = 1;
  end else begin
    // Generate (rdcqdb_aw, rdcqdb_w)
    rdcqhdl_valid = 1;
    rdcqdb_awvalid = rdcqhdl_valid & ~rdcqhdl_block0;
    rdcqdb_wvalid = rdcqhdl_valid & ~rdcqhdl_block1;
    rdcqhdl_ready = (~rdcqdb_awvalid | rdcqdb_awready)
                  & (~rdcqdb_wvalid | rdcqdb_wready);
  end

  // Consume rdcqdb_b
  rdcqdb_bready = 1;

  // null -> rdcq_aw
  rdcq_awvalid = 0;
  rdcq_awaddr = 0;
  rdcq_awlen = 0;
  rdcq_awsize = 0;
  rdcq_awburst = 0;

  // null -> rdcq_w
  rdcq_wvalid = 0;
  rdcq_wdata = 0;
  rdcq_wstrb = 0;
  rdcq_wlast = 0;

  // rdcq_b -> null
  rdcq_bready = 0;

  // null -> rdcqdb_ar
  rdcqdb_arvalid = 0;
  rdcqdb_araddr = 0;
  rdcqdb_arlen = 0;
  rdcqdb_arsize = 0;
  rdcqdb_arburst = 0;

  // rdcqdb_r -> null
  rdcqdb_rready = 0;
end

// Read response handler (rdreshdl)
// Check cid, Generate rdbuf_ar
logic [$clog2(OUTSTANDING)-1:0] rdreshdl_cid_idx;
logic rdreshdl_cid_phase;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    rdreshdl_cid_idx <= 0;
    rdreshdl_cid_phase <= 0;
  end else begin
    if (rdbuf_arvalid & rdbuf_arready) begin
      rdreshdl_cid_idx <= (rdreshdl_cid_idx + 1) % OUTSTANDING;
      if (rdreshdl_cid_idx == OUTSTANDING - 1) begin
        rdreshdl_cid_phase <= ~rdreshdl_cid_phase;
      end
    end
  end
end

always_comb begin
  // Generate rdbuf_ar
  rdbuf_arvalid = rdcqhdl_cid_state[rdreshdl_cid_idx] != rdreshdl_cid_phase;
  rdbuf_araddr = RDBUF_ADDR_BASE + (rdreshdl_cid_idx << hp_word_size_log2);
  rdbuf_arlen = hp_burst_len; // 128b * 256 = 4KB
  rdbuf_arsize = 4; // 128b = 16B = 2^4B
  rdbuf_arburst = 1; // INCR
end

// Read buffer handler (rdbufhdl)
// rdbuf_r -> hp_r
// Nullify rdbuf_aw/w/b
always_comb begin
  // rdbuf_r -> hp_r
  hp_rvalid = rdbuf_rvalid;
  rdbuf_rready = hp_rready;

  // hp_r datapath
  hp_rdata = rdbuf_rdata;
  hp_rresp = rdbuf_rresp;
  hp_rlast = rdbuf_rlast;

  // rdbuf_aw
  rdbuf_awvalid = 0;
  rdbuf_awaddr = 0;
  rdbuf_awlen = 0;
  rdbuf_awsize = 0;
  rdbuf_awburst = 0;

  // rdbuf_w
  rdbuf_wvalid = 0;
  rdbuf_wdata = 0;
  rdbuf_wstrb = 0;
  rdbuf_wlast = 0;

  // rdbuf_b
  rdbuf_bready = 0;
end

/*
probe0
wrsqhdl_sqtail 4
wrsqhdl_cid_phase 1
wrsqdbhdl_sqtail 4
wrcqhdl_state 2
wrcqhdl_cqhead 4
wrcqhdl_phase 1
wrcqhdl_cid_state 16
wrreshdl_cid_idx 4
wrreshdl_cid_phase 1
4+1+4+2+4+1+16+4+1=37b

probe1
rdsqhdl_sqtail 4
rdsqhdl_cid_phase 1
rdsqdbhdl_sqtail 4
rdcqhdl_state 2
rdcqhdl_cqhead 4
rdcqhdl_phase 1
rdcqhdl_cid_state 16
rdreshdl_cid_idx 4
rdreshdl_cid_phase 1
4+1+4+2+4+1+16+4+1=37b

probe2
wrsqhdl_block0, wrsqhdl_block1, wrsqhdl_block2
wrsqdbhdl_block0, wrsqdbhdl_block1
wrcqhdl_block0, wrcqhdl_block1
rdsqhdl_block0, rdsqhdl_block1
rdsqdbhdl_block0, rdsqdbhdl_block1
rdcqhdl_block0, rdcqhdl_block1
13b
*/

ila_driver ila_driver_inst (
  .clk(clk),
  .probe0({wrsqhdl_sqtail, wrsqhdl_cid_phase, wrsqdbhdl_sqtail, wrcqhdl_state, wrcqhdl_cqhead, wrcqhdl_phase, wrcqhdl_cid_state, wrreshdl_cid_idx, wrreshdl_cid_phase}),
  .probe1({rdsqhdl_sqtail, rdsqhdl_cid_phase, rdsqdbhdl_sqtail, rdcqhdl_state, rdcqhdl_cqhead, rdcqhdl_phase, rdcqhdl_cid_state, rdreshdl_cid_idx, rdreshdl_cid_phase}),
  .probe2({wrsqhdl_block0, wrsqhdl_block1, wrsqhdl_block2, wrsqdbhdl_block0, wrsqdbhdl_block1, wrcqhdl_block0, wrcqhdl_block1, rdsqhdl_block0, rdsqhdl_block1, rdsqdbhdl_block0, rdsqdbhdl_block1, rdcqhdl_block0, rdcqhdl_block1})
);

endmodule