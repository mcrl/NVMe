module driver_v2 #(
  parameter HOST_ADDR_WIDTH = 21,
  parameter HOST_DATA_WIDTH = 32,
  parameter HP_ADDR_WIDTH = 48,
  parameter HP_DATA_WIDTH = 128,
  parameter MAIN_ADDR_WIDTH = 34,
  parameter MAIN_DATA_WIDTH = 128,
  parameter SUB_ADDR_WIDTH = 34,
  parameter SUB_DATA_WIDTH = 128
) (
  input logic clk,
  input logic rstn,

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

  output logic [MAIN_ADDR_WIDTH-1:0]   main_awaddr,
  output logic [MAIN_DATA_WIDTH-1:0]   main_wdata,
  output logic [MAIN_DATA_WIDTH/8-1:0] main_wstrb,
  output logic [MAIN_ADDR_WIDTH-1:0]   main_araddr,
  input  logic [MAIN_DATA_WIDTH-1:0]   main_rdata,
  output logic [7:0] main_awlen,
  output logic [2:0] main_awsize,
  output logic [1:0] main_awburst,
  output logic       main_awvalid,
  input  logic       main_awready,
  output logic       main_wlast,
  output logic       main_wvalid,
  input  logic       main_wready,
  input  logic [1:0] main_bresp,
  input  logic       main_bvalid,
  output logic       main_bready,
  output logic [7:0] main_arlen,
  output logic [2:0] main_arsize,
  output logic [1:0] main_arburst,
  output logic       main_arvalid,
  input  logic       main_arready,
  input  logic [1:0] main_rresp,
  input  logic       main_rlast,
  input  logic       main_rvalid,
  output logic       main_rready,

  output logic [SUB_ADDR_WIDTH-1:0]   sub_awaddr,
  output logic [SUB_DATA_WIDTH-1:0]   sub_wdata,
  output logic [SUB_DATA_WIDTH/8-1:0] sub_wstrb,
  output logic [SUB_ADDR_WIDTH-1:0]   sub_araddr,
  input  logic [SUB_DATA_WIDTH-1:0]   sub_rdata,
  output logic [7:0] sub_awlen,
  output logic [2:0] sub_awsize,
  output logic [1:0] sub_awburst,
  output logic       sub_awvalid,
  input  logic       sub_awready,
  output logic       sub_wlast,
  output logic       sub_wvalid,
  input  logic       sub_wready,
  input  logic [1:0] sub_bresp,
  input  logic       sub_bvalid,
  output logic       sub_bready,
  output logic [7:0] sub_arlen,
  output logic [2:0] sub_arsize,
  output logic [1:0] sub_arburst,
  output logic       sub_arvalid,
  input  logic       sub_arready,
  input  logic [1:0] sub_rresp,
  input  logic       sub_rlast,
  input  logic       sub_rvalid,
  output logic       sub_rready
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

// This driver supports 16 outstanding txns.
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
logic [OUTSTANDING-1:0] cqhdl_cmd_state;
logic [$clog2(OUTSTANDING)-1:0] cqhdl_sqhead;

/*
 * FSM0: SQ Handler (sqhdl)
 * State 0: Write SQE
 * hp_aw -> main_aw, main_w
 * State 1: Write Data
 * hp_w -> main_aw, main_w
 * State 2: Write SQDB
 * <null> -> main_aw, main_w
 * Always:
 * main_b -> <null>
 */
typedef enum logic [1:0] {
  SQHDL_STATE_SQE,
  SQHDL_STATE_DATA,
  SQHDL_STATE_SQDB
} sqhdl_state_t;

// global
sqhdl_state_t sqhdl_state;
logic [$clog2(OUTSTANDING)-1:0] sqhdl_sqtail;
logic sqhdl_phase;
logic [$clog2(256+1)-1:0] sqhdl_burst_len;
// for SQE
logic [$clog2(1+1)-1:0] sqhdl_sqe_in_state0; // hp_aw
logic [$clog2(1+1)-1:0] sqhdl_sqe_in_next_state0; // hp_aw
logic [$clog2(1+1)-1:0] sqhdl_sqe_out_state0; // main_aw
logic [$clog2(1+1)-1:0] sqhdl_sqe_out_next_state0; // main_aw
logic [$clog2(4+1)-1:0] sqhdl_sqe_out_state1; // main_w
logic [$clog2(4+1)-1:0] sqhdl_sqe_out_next_state1; // main_w
// for DATA
logic [$clog2(256+1)-1:0] sqhdl_data_in_state0; // hp_w
logic [$clog2(256+1)-1:0] sqhdl_data_in_next_state0; // hp_w
logic [$clog2(1+1)-1:0] sqhdl_data_out_state0; // main_aw
logic [$clog2(1+1)-1:0] sqhdl_data_out_next_state0; // main_aw
logic [$clog2(256+1)-1:0] sqhdl_data_out_state1; // main_w
logic [$clog2(256+1)-1:0] sqhdl_data_out_next_state1; // main_w
// for SQDB
logic [$clog2(1+1)-1:0] sqhdl_sqdb_out_state0; // main_aw
logic [$clog2(1+1)-1:0] sqhdl_sqdb_out_next_state0; // main_aw
logic [$clog2(1+1)-1:0] sqhdl_sqdb_out_state1; // main_w
logic [$clog2(1+1)-1:0] sqhdl_sqdb_out_next_state1; // main_w

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    sqhdl_state <= SQHDL_STATE_SQE;
    sqhdl_sqtail <= 0;
    sqhdl_phase <= 0;
    sqhdl_sqe_in_state0 <= 0;
    sqhdl_sqe_out_state0 <= 0;
    sqhdl_sqe_out_state1 <= 0;
    sqhdl_data_in_state0 <= 0;
    sqhdl_data_out_state0 <= 0;
    sqhdl_data_out_state1 <= 0;
    sqhdl_sqdb_out_state0 <= 0;
    sqhdl_sqdb_out_state1 <= 0;
  end else begin
    if (sqhdl_state == SQHDL_STATE_SQE) begin
      if (hp_awvalid & hp_awready) begin
        sqhdl_sqe_in_state0 <= sqhdl_sqe_in_next_state0;
      end
      if (main_awvalid & main_awready) begin
        sqhdl_sqe_out_state0 <= sqhdl_sqe_out_next_state0;
      end
      if (main_wvalid & main_wready) begin
        sqhdl_sqe_out_state1 <= sqhdl_sqe_out_next_state1;
      end
      if ((sqhdl_sqe_in_next_state0 == 1)
        & (sqhdl_sqe_out_next_state0 == 1)
        & (sqhdl_sqe_out_next_state1 == 4)
      ) begin
        sqhdl_sqe_in_state0 <= 0;
        sqhdl_sqe_out_state0 <= 0;
        sqhdl_sqe_out_state1 <= 0;
        sqhdl_state <= SQHDL_STATE_DATA;
        sqhdl_burst_len <= hp_awlen + 1;
      end
    end else if (sqhdl_state == SQHDL_STATE_DATA) begin
      if (hp_wvalid & hp_wready) begin
        sqhdl_data_in_state0 <= sqhdl_data_in_next_state0;
      end
      if (main_awvalid & main_awready) begin
        sqhdl_data_out_state0 <= sqhdl_data_out_next_state0;
      end
      if (main_wvalid & main_wready) begin
        sqhdl_data_out_state1 <= sqhdl_data_out_next_state1;
      end
      if ((sqhdl_data_in_next_state0 == 256)
        & (sqhdl_data_out_next_state0 == 1)
        & (sqhdl_data_out_next_state1 == 256)
      ) begin
        sqhdl_data_in_state0 <= 0;
        sqhdl_data_out_state0 <= 0;
        sqhdl_data_out_state1 <= 0;
        sqhdl_state <= SQHDL_STATE_SQDB;
      end
    end else if (sqhdl_state == SQHDL_STATE_SQDB) begin
      if (main_awvalid & main_awready) begin
        sqhdl_sqdb_out_state0 <= sqhdl_sqdb_out_next_state0;
      end
      if (main_wvalid & main_wready) begin
        sqhdl_sqdb_out_state1 <= sqhdl_sqdb_out_next_state1;
      end
      if ((sqhdl_sqdb_out_next_state0 == 1)
        & (sqhdl_sqdb_out_next_state1 == 1)
      ) begin
        sqhdl_sqdb_out_state0 <= 0;
        sqhdl_sqdb_out_state1 <= 0;
        sqhdl_state <= SQHDL_STATE_SQE;

        sqhdl_sqtail <= (sqhdl_sqtail + 1) % OUTSTANDING;
        if (sqhdl_sqtail == OUTSTANDING - 1) begin
          sqhdl_phase <= ~sqhdl_phase;
        end
      end
    end
  end
end

always_comb begin
  // TODO prevent latch
  if (sqhdl_state == SQHDL_STATE_SQE) begin
    // hp_aw -> main_aw, main_w
    logic valid;
    valid = hp_awvalid & (cqhdl_cmd_state[sqhdl_sqtail] == sqhdl_phase);
    main_awvalid = valid & (sqhdl_sqe_out_state0 != 1);
    main_wvalid = valid & (sqhdl_sqe_out_state1 != 4);
    sqhdl_sqe_in_next_state0 = hp_awvalid & hp_awready ? sqhdl_sqe_in_state0 + 1 : sqhdl_sqe_in_state0;
    sqhdl_sqe_out_next_state0 = main_awvalid & main_awready ? sqhdl_sqe_out_state0 + 1 : sqhdl_sqe_out_state0;
    sqhdl_sqe_out_next_state1 = main_wvalid & main_wready ? sqhdl_sqe_out_state1 + 1 : sqhdl_sqe_out_state1;
    hp_awready = (sqhdl_sqe_in_state0 != 1) & (sqhdl_sqe_out_next_state0 == 1) & (sqhdl_sqe_out_next_state1 == 4);

    // main_aw datapath
    main_awaddr = WRSQ_ADDR_BASE + sqhdl_sqtail * 64;
    main_awlen = 3; // 4-beat burst
    main_awsize = 4; // 2^4B
    main_awburst = 1; // INCR

    // main_w datapath
    // synthesize write command
    if (sqhdl_sqe_out_state1 == 0) begin
      main_wdata[0 +: 32] = {
        16'(sqhdl_sqtail), // cid
        2'b00, // use prp
        4'b0000, // reserved
        2'b00, // not fused
        8'h01 // opcode WRITE
      };
      main_wdata[32 +: 32] = 1; // nsid == 1
      main_wdata[64 +: 64] = 0; // CDW2-3 (not used; no end-to-end protection)
      main_wlast = 0;
    end else if (sqhdl_sqe_out_state1 == 1) begin
      main_wdata[0 +: 64] = 0; // MPTR (not used)
      main_wdata[64 +: 64] = WRBUF_ADDR_BASE + (sqhdl_sqtail << hp_word_size_log2); // DPTR - prp1
      main_wlast = 0;
    end else if (sqhdl_sqe_out_state1 == 2) begin
      main_wdata[0 +: 64] = 0; // DPTR - prp2
      // Starting LBA is address divided by 4KB
      main_wdata[64 +: 64] = hp_awaddr >> nvme_word_size_log2; // CDW10-11
      main_wlast = 0;
    end else if (sqhdl_sqe_out_state1 == 3) begin
      // Specify number of logical blocks as 0 (which means 1)
      // Other options are not used
      main_wdata[0 +: 32] = nvme_nlb; // CDW12
      // No hint for compression, sequential, latency, and frequency
      main_wdata[32 +: 32] = 0; // CDW13
      main_wdata[64 +: 32] = 0; // CDW14 (not used; no end-to-end protection)
      main_wdata[96 +: 32] = 0; // CDW15 (not used; no end-to-end protection)
      main_wlast = 1;
    end
    main_wstrb = '1;
  end else if (sqhdl_state == SQHDL_STATE_DATA) begin
    // hp_w -> main_aw, main_w
    main_awvalid = (sqhdl_data_out_state0 != 1);
    main_wvalid = hp_wvalid & (sqhdl_data_out_state1 != 256);
    sqhdl_data_in_next_state0 = hp_wvalid & hp_wready ? sqhdl_data_in_state0 + 1 : sqhdl_data_in_state0;
    sqhdl_data_out_next_state0 = main_awvalid & main_awready ? sqhdl_data_out_state0 + 1 : sqhdl_data_out_state0;
    sqhdl_data_out_next_state1 = main_wvalid & main_wready ? sqhdl_data_out_state1 + 1 : sqhdl_data_out_state1;
    hp_wready = (sqhdl_data_in_state0 != 256) & (sqhdl_data_out_next_state1 == sqhdl_data_in_state0 + 1);

    // main_aw datapath
    main_awaddr = WRBUF_ADDR_BASE + (sqhdl_sqtail << hp_word_size_log2);
    main_awlen = sqhdl_burst_len - 1;
    main_awsize = 4; // 2^4B
    main_awburst = 1; // INCR

    // main_w datapath
    main_wdata = hp_wdata;
    main_wlast = hp_wlast;
    main_wstrb = hp_wstrb;
  end else if (sqhdl_state == SQHDL_STATE_SQDB) begin
    // <null> -> main_aw, main_w
    main_awvalid = (sqhdl_sqdb_out_state0 != 1);
    main_wvalid = (sqhdl_sqdb_out_state1 != 1);
    sqhdl_sqdb_out_next_state0 = main_awvalid & main_awready ? sqhdl_sqdb_out_state0 + 1 : sqhdl_sqdb_out_state0;
    sqhdl_sqdb_out_next_state1 = main_wvalid & main_wready ? sqhdl_sqdb_out_state1 + 1 : sqhdl_sqdb_out_state1;

    // main_aw datapath
    main_awaddr = SQ1TDBL;
    main_awlen = 0; // single beat
    main_awsize = 2; // 2^2B
    main_awburst = 1; // INCR

    // main_w datapath
    // align at 8B since the bus is 16B and SQ1TDBL % 16 == 8
    main_wsqdb = {
      32'b0,
      32'((sqhdl_sqtail + 1) % OUTSTANDING),
      32'b0,
      32'b0
    };
    main_wlast = 1;
    main_wstrb = '1;
  end
  // main_b -> <null>
  main_bready = 1;
end

endmodule