module kernel #(
  parameter HOST_ADDR_WIDTH = 32,
  parameter HOST_DATA_WIDTH = 32,
  parameter HP_ADDR_WIDTH = 48,
  parameter HP_DATA_WIDTH = 128
) (
  input logic clk,
  input logic rstn,
  output logic driver_rstn,

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

  // AXIB master
  output logic [HP_ADDR_WIDTH-1:0]   hp_awaddr,
  output logic [HP_DATA_WIDTH-1:0]   hp_wdata,
  output logic [HP_DATA_WIDTH/8-1:0] hp_wstrb,
  output logic [HP_ADDR_WIDTH-1:0]   hp_araddr,
  input  logic [HP_DATA_WIDTH-1:0]   hp_rdata,
  output logic [7:0] hp_awlen,
  output logic [2:0] hp_awsize,
  output logic [1:0] hp_awburst,
  output logic       hp_awvalid,
  input  logic       hp_awready,
  output logic       hp_wlast,
  output logic       hp_wvalid,
  input  logic       hp_wready,
  input  logic [1:0] hp_bresp,
  input  logic       hp_bvalid,
  output logic       hp_bready,
  output logic [7:0] hp_arlen,
  output logic [2:0] hp_arsize,
  output logic [1:0] hp_arburst,
  output logic       hp_arvalid,
  input  logic       hp_arready,
  input  logic [1:0] hp_rresp,
  input  logic       hp_rlast,
  input  logic       hp_rvalid,
  output logic       hp_rready
);

// Register map
// 0x00 WO kernel start trigger
// 0x04 RO kernel state (0=idle, 1=running, 2=done)
// 0x08 WO reset kernel state to idle
// 0x0c RW driver reset (0=reset, 1=normal)
// 0x10 RW start address (low)
// 0x14 RW start address (high)
// 0x18 RW end address (low)
// 0x1c RW end address (high)
// 0x20 RW start value (DW0)
// 0x24 RW start value (DW1)
// 0x28 RW start value (DW2)
// 0x2c RW start value (DW3)
// 0x30 RW stride (DW0)
// 0x34 RW stride (DW1)
// 0x38 RW stride (DW2)
// 0x3c RW stride (DW3)
// 0x40 RW benchmode (write=0, read=1)
// 0x44 RO checksum (after read)

endmodule