module raider #(
  parameter S_ADDR_WIDTH = 48,
  parameter S_DATA_WIDTH = 256,
  parameter M_ADDR_WIDTH = 48,
  parameter M_DATA_WIDTH = 128
) (
  input logic clk,
  input logic rstn,

  input  logic [S_ADDR_WIDTH-1:0]   s_awaddr,
  input  logic [S_DATA_WIDTH-1:0]   s_wdata,
  input  logic [S_DATA_WIDTH/8-1:0] s_wstrb,
  input  logic [S_ADDR_WIDTH-1:0]   s_araddr,
  output logic [S_DATA_WIDTH-1:0]   s_rdata,
  input  logic [7:0] s_awlen,
  input  logic [2:0] s_awsize,
  input  logic [1:0] s_awburst,
  input  logic       s_awvalid,
  output logic       s_awready,
  input  logic       s_wlast,
  input  logic       s_wvalid,
  output logic       s_wready,
  output logic [1:0] s_bresp,
  output logic       s_bvalid,
  input  logic       s_bready,
  input  logic [7:0] s_arlen,
  input  logic [2:0] s_arsize,
  input  logic [1:0] s_arburst,
  input  logic       s_arvalid,
  output logic       s_arready,
  output logic [1:0] s_rresp,
  output logic       s_rlast,
  output logic       s_rvalid,
  input  logic       s_rready,

  output logic [M_ADDR_WIDTH-1:0]   m0_awaddr,
  output logic [M_DATA_WIDTH-1:0]   m0_wdata,
  output logic [M_DATA_WIDTH/8-1:0] m0_wstrb,
  output logic [M_ADDR_WIDTH-1:0]   m0_araddr,
  input  logic [M_DATA_WIDTH-1:0]   m0_rdata,
  output logic [7:0] m0_awlen,
  output logic [2:0] m0_awsize,
  output logic [1:0] m0_awburst,
  output logic       m0_awvalid,
  input  logic       m0_awready,
  output logic       m0_wlast,
  output logic       m0_wvalid,
  input  logic       m0_wready,
  input  logic [1:0] m0_bresp,
  input  logic       m0_bvalid,
  output logic       m0_bready,
  output logic [7:0] m0_arlen,
  output logic [2:0] m0_arsize,
  output logic [1:0] m0_arburst,
  output logic       m0_arvalid,
  input  logic       m0_arready,
  input  logic [1:0] m0_rresp,
  input  logic       m0_rlast,
  input  logic       m0_rvalid,
  output logic       m0_rready,

  output logic [M_ADDR_WIDTH-1:0]   m1_awaddr,
  output logic [M_DATA_WIDTH-1:0]   m1_wdata,
  output logic [M_DATA_WIDTH/8-1:0] m1_wstrb,
  output logic [M_ADDR_WIDTH-1:0]   m1_araddr,
  input  logic [M_DATA_WIDTH-1:0]   m1_rdata,
  output logic [7:0] m1_awlen,
  output logic [2:0] m1_awsize,
  output logic [1:0] m1_awburst,
  output logic       m1_awvalid,
  input  logic       m1_awready,
  output logic       m1_wlast,
  output logic       m1_wvalid,
  input  logic       m1_wready,
  input  logic [1:0] m1_bresp,
  input  logic       m1_bvalid,
  output logic       m1_bready,
  output logic [7:0] m1_arlen,
  output logic [2:0] m1_arsize,
  output logic [1:0] m1_arburst,
  output logic       m1_arvalid,
  input  logic       m1_arready,
  input  logic [1:0] m1_rresp,
  input  logic       m1_rlast,
  input  logic       m1_rvalid,
  output logic       m1_rready
);

// aw channel
logic aw_block0;
logic aw_block1;
always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    aw_block0 <= 0;
    aw_block1 <= 0;
  end else begin
    aw_block0 <= s_awvalid & ~s_awready & (m0_awready | aw_block0);
    aw_block1 <= s_awvalid & ~s_awready & (m1_awready | aw_block1);
  end
end
always_comb begin
  m0_awvalid = s_awvalid & ~aw_block0;
  m1_awvalid = s_awvalid & ~aw_block1;
  s_awready = (~m0_awvalid | m0_awready)
            & (~m1_awvalid | m1_awready);

  m0_awaddr = s_awaddr;
  m0_awlen = s_awlen;
  m0_awsize = s_awsize;
  m0_awburst = s_awburst;

  m1_awaddr = s_awaddr;
  m1_awlen = s_awlen;
  m1_awsize = s_awsize;
  m1_awburst = s_awburst;
end

// w channel
logic w_block0;
logic w_block1;
always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    w_block0 <= 0;
    w_block1 <= 0;
  end else begin
    w_block0 <= s_wvalid & ~s_wready & (m0_wready | w_block0);
    w_block1 <= s_wvalid & ~s_wready & (m1_wready | w_block1);
  end
end
always_comb begin
  m0_wvalid = s_wvalid & ~w_block0;
  m1_wvalid = s_wvalid & ~w_block1;
  s_wready = (~m0_wvalid | m0_wready)
           & (~m1_wvalid | m1_wready);
  
  {m1_wdata, m0_wdata} = s_wdata;
  {m1_wstrb, m0_wstrb} = s_wstrb;
  m0_wlast = s_wlast;
  m1_wlast = s_wlast;
end

// b channel
always_comb begin
  s_bvalid = m0_bvalid & m1_bvalid;
  m0_bready = s_bready & (s_bvalid | ~m0_bvalid);
  m1_bready = s_bready & (s_bvalid | ~m1_bvalid);
  s_bresp = 0;
end

// ar channel
logic ar_block0;
logic ar_block1;
always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    ar_block0 <= 0;
    ar_block1 <= 0;
  end else begin
    ar_block0 <= s_arvalid & ~s_arready & (m0_arready | ar_block0);
    ar_block1 <= s_arvalid & ~s_arready & (m1_arready | ar_block1);
  end
end
always_comb begin
  m0_arvalid = s_arvalid & ~ar_block0;
  m1_arvalid = s_arvalid & ~ar_block1;
  s_arready = (~m0_arvalid | m0_arready)
            & (~m1_arvalid | m1_arready);
  
  m0_araddr = s_araddr;
  m0_arlen = s_arlen;
  m0_arsize = s_arsize;
  m0_arburst = s_arburst;

  m1_araddr = s_araddr;
  m1_arlen = s_arlen;
  m1_arsize = s_arsize;
  m1_arburst = s_arburst;
end

// r channel
always_comb begin
  s_rvalid = m0_rvalid & m1_rvalid;
  m0_rready = s_rready & (s_rvalid | ~m0_rvalid);
  m1_rready = s_rready & (s_rvalid | ~m1_rvalid);
  s_rdata = {m1_rdata, m0_rdata};
  s_rresp = 0;
  s_rlast = m0_rlast;
end

endmodule