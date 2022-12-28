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

endmodule