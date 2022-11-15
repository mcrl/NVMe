module kernel (
  input logic clk,
  input logic rstn,

  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host ADDR" *)
  input logic [14:0] host_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host CLK" *)
  input logic host_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host DIN" *)
  input logic [31:0] host_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host DOUT" *)
  output logic [31:0] host_dout,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host EN" *)
  input logic host_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host RST" *)
  input logic host_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 host WE" *)
  input logic [3:0] host_we,

  // k2o: kernel(master) to oculink(slave) AXI-MM interface
  // AW
  output logic [63:0] k2o_awaddr,
  output logic [1:0]  k2o_awburst,
  output logic [3:0]  k2o_awcache,
  output logic [3:0]  k2o_awid,
  output logic [7:0]  k2o_awlen,
  output logic [0:0]  k2o_awlock,
  output logic [2:0]  k2o_awprot,
  output logic [3:0]  k2o_awqos,
  input  logic        k2o_awready,
  output logic [3:0]  k2o_awregion,
  output logic [2:0]  k2o_awsize,
  output logic        k2o_awvalid,
  // W
  output logic [127:0] k2o_wdata,
  output logic         k2o_wlast,
  input  logic         k2o_wready,
  output logic [15:0]  k2o_wstrb,
  output logic         k2o_wvalid,
  // AR
  output logic [63:0] k2o_araddr,
  output logic [1:0]  k2o_arburst,
  output logic [3:0]  k2o_arcache,
  output logic [3:0]  k2o_arid,
  output logic [7:0]  k2o_arlen,
  output logic [0:0]  k2o_arlock,
  output logic [2:0]  k2o_arprot,
  output logic [3:0]  k2o_arqos,
  input  logic        k2o_arready,
  output logic [3:0]  k2o_arregion,
  output logic [2:0]  k2o_arsize,
  output logic        k2o_arvalid,
  // B
  input  logic [3:0] k2o_bid,
  output logic       k2o_bready,
  input  logic [1:0] k2o_bresp,
  input  logic       k2o_bvalid,
  // R
  input  logic [127:0] k2o_rdata,
  input  logic [3:0]   k2o_rid,
  input  logic         k2o_rlast,
  output logic         k2o_rready,
  input  logic [1:0]   k2o_rresp,
  input  logic         k2o_rvalid,

  // o2k: oculink(master) to kernel(slave) AXI-MM interface
  // AW
  input [63:0] o2k_awaddr,
  input [1:0]  o2k_awburst,
  input [3:0]  o2k_awcache,
  input [3:0]  o2k_awid,
  input [7:0]  o2k_awlen,
  input [0:0]  o2k_awlock,
  input [2:0]  o2k_awprot,
  input [3:0]  o2k_awqos,
  output       o2k_awready,
  input [3:0]  o2k_awregion,
  input [2:0]  o2k_awsize,
  input        o2k_awvalid,
  // W
  input [127:0] o2k_wdata,
  input         o2k_wlast,
  output        o2k_wready,
  input [15:0]  o2k_wstrb,
  input         o2k_wvalid,
  // AR
  input [63:0] o2k_araddr,
  input [1:0]  o2k_arburst,
  input [3:0]  o2k_arcache,
  input [3:0]  o2k_arid,
  input [7:0]  o2k_arlen,
  input [0:0]  o2k_arlock,
  input [2:0]  o2k_arprot,
  input [3:0]  o2k_arqos,
  output       o2k_arready,
  input [3:0]  o2k_arregion,
  input [2:0]  o2k_arsize,
  input        o2k_arvalid,
  // B
  output [3:0] o2k_bid,
  input        o2k_bready,
  output [1:0] o2k_bresp,
  output       o2k_bvalid,
  // R
  output [127:0] o2k_rdata,
  output [3:0]   o2k_rid,
  output         o2k_rlast,
  input          o2k_rready,
  output [1:0]   o2k_rresp,
  output         o2k_rvalid,
);

localparam MAGIC_AWID = 1;
localparam MAGIC_ARID = 2;

logic        k2o_aw_fifo_rvalid;
logic [63:0] k2o_aw_fifo_rdata;
logic        k2o_aw_fifo_rready;
logic        k2o_aw_fifo_wvalid;
logic [63:0] k2o_aw_fifo_wdata;
logic        k2o_aw_fifo_wready;

logic         k2o_w_fifo_rvalid;
logic [127:0] k2o_w_fifo_rdata;
logic         k2o_w_fifo_rready;
logic         k2o_w_fifo_wvalid;
logic [127:0] k2o_w_fifo_wdata;
logic         k2o_w_fifo_wready;

logic        k2o_ar_fifo_rvalid;
logic [63:0] k2o_ar_fifo_rdata;
logic        k2o_ar_fifo_rready;
logic        k2o_ar_fifo_wvalid;
logic [63:0] k2o_ar_fifo_wdata;
logic        k2o_ar_fifo_wready;

localparam K2O_B_FIFO_WIDTH = 4 + 2; // id, resp
logic                            k2o_b_fifo_rvalid;
logic [K2O_B_FIFO_WIDTH - 1 : 0] k2o_b_fifo_rdata;
logic                            k2o_b_fifo_rready;
logic                            k2o_b_fifo_wvalid;
logic [K2O_B_FIFO_WIDTH - 1 : 0] k2o_b_fifo_wdata;
logic                            k2o_b_fifo_wready;

localparam K2O_R_FIFO_WIDTH = 4 + 2 + 128; // id, resp, data
logic                            k2o_r_fifo_rvalid;
logic [K2O_R_FIFO_WIDTH - 1 : 0] k2o_r_fifo_rdata;
logic                            k2o_r_fifo_rready;
logic                            k2o_r_fifo_wvalid;
logic [K2O_R_FIFO_WIDTH - 1 : 0] k2o_r_fifo_wdata;
logic                            k2o_r_fifo_wready;

localparam O2K_AW_FIFO_WIDTH = 4 + 8 + 64; // id, len, addr
logic                             o2k_aw_fifo_rvalid;
logic [O2K_AW_FIFO_WIDTH - 1 : 0] o2k_aw_fifo_rdata;
logic                             o2k_aw_fifo_rready;
logic                             o2k_aw_fifo_wvalid;
logic [O2K_AW_FIFO_WIDTH - 1 : 0] o2k_aw_fifo_wdata;
logic                             o2k_aw_fifo_wready;

logic         o2k_w_fifo_rvalid;
logic [127:0] o2k_w_fifo_rdata;
logic         o2k_w_fifo_rready;
logic         o2k_w_fifo_wvalid;
logic [127:0] o2k_w_fifo_wdata;
logic         o2k_w_fifo_wready;

localparam O2K_AR_FIFO_WIDTH = 4 + 8 + 64; // id, len, addr
logic                             o2k_ar_fifo_rvalid;
logic [O2K_AR_FIFO_WIDTH - 1 : 0] o2k_ar_fifo_rdata;
logic                             o2k_ar_fifo_rready;
logic                             o2k_ar_fifo_wvalid;
logic [O2K_AR_FIFO_WIDTH - 1 : 0] o2k_ar_fifo_wdata;
logic                             o2k_ar_fifo_wready;

localparam O2K_B_FIFO_WIDTH = 4; // id
logic                            o2k_b_fifo_rvalid;
logic [O2K_B_FIFO_WIDTH - 1 : 0] o2k_b_fifo_rdata;
logic                            o2k_b_fifo_rready;
logic                            o2k_b_fifo_wvalid;
logic [O2K_B_FIFO_WIDTH - 1 : 0] o2k_b_fifo_wdata;
logic                            o2k_b_fifo_wready;

localparam O2K_R_FIFO_WIDTH = 4 + 1 + 128; // id, last, data
logic                            o2k_r_fifo_rvalid;
logic [O2K_R_FIFO_WIDTH - 1 : 0] o2k_r_fifo_rdata;
logic                            o2k_r_fifo_rready;
logic                            o2k_r_fifo_wvalid;
logic [O2K_R_FIFO_WIDTH -  1: 0] o2k_r_fifo_wdata;
logic                            o2k_r_fifo_wready;

logic [255 : 0] data;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    k2o_aw_fifo_wvalid <= 0;
    k2o_w_fifo_wvalid <= 0;
    k2o_ar_fifo_wvalid <= 0;
    k2o_b_fifo_rready <= 0;
    k2o_r_fifo_rready <= 0;
    o2k_aw_fifo_rready <= 0;
    o2k_w_fifo_rready <= 0;
    o2k_ar_fifo_rready <= 0;
  end else begin
    k2o_aw_fifo_wvalid <= 0;
    k2o_w_fifo_wvalid <= 0;
    k2o_ar_fifo_wvalid <= 0;
    k2o_b_fifo_rready <= 0;
    k2o_r_fifo_rready <= 0;
    o2k_aw_fifo_rready <= 0;
    o2k_w_fifo_rready <= 0;
    o2k_ar_fifo_rready <= 0;
    if (host_we != 0) begin
      if          (host_addr == 'h00 / 4) begin
        data[0 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h04 / 4) begin
        data[1 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h08 / 4) begin
        data[2 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h0c / 4) begin
        data[3 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h10 / 4) begin
        data[4 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h14 / 4) begin
        data[5 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h18 / 4) begin
        data[6 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h1c / 4) begin
        data[7 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h20 / 4) begin
        k2o_aw_fifo_wvalid <= 1;
        k2o_aw_fifo_wdata <= data;
      end else if (host_addr == 'h30 / 4) begin
        k2o_w_fifo_wvalid <= 1;
        k2o_w_fifo_wdata <= data;
      end else if (host_addr == 'h40 / 4) begin
        k2o_ar_fifo_wvalid <= 1;
        k2o_ar_fifo_wdata <= data;
      end else if (host_addr == 'h54 / 4) begin
        k2o_b_fifo_rready <= 1;
        data <= k2o_b_fifo_rdata;
      end else if (host_addr == 'h64 / 4) begin
        k2o_r_fifo_rready <= 1;
        data <= k2o_r_fifo_rdata;
      end else if (host_addr == 'h74 / 4) begin
        o2k_aw_fifo_rready <= 1;
        data <= o2k_aw_fifo_rdata;
      end else if (host_addr == 'h84 / 4) begin
        o2k_w_fifo_rready <= 1;
        data <= o2k_w_fifo_rdata;
      end else if (host_addr == 'h94 / 4) begin
        o2k_ar_fifo_rready <= 1;
        data <= o2k_ar_fifo_rdata;
      end else if (host_addr == 'ha0 / 4) begin
        o2k_b_fifo_wvalid <= 1;
        o2k_b_fifo_wdata <= data;
      end else if (host_addr == 'hb0 / 4) begin
        o2k_r_fifo_wvalid <= 1;
        o2k_r_fifo_wdata <= data;
      end
    end else begin
      if          (host_addr == 'h00 / 4) begin
        host_dout <= data[0 * 32 +: 32];
      end else if (host_addr == 'h04 / 4) begin
        host_dout <= data[1 * 32 +: 32];
      end else if (host_addr == 'h08 / 4) begin
        host_dout <= data[2 * 32 +: 32];
      end else if (host_addr == 'h0c / 4) begin
        host_dout <= data[3 * 32 +: 32];
      end else if (host_addr == 'h10 / 4) begin
        host_dout <= data[4 * 32 +: 32];
      end else if (host_addr == 'h14 / 4) begin
        host_dout <= data[5 * 32 +: 32];
      end else if (host_addr == 'h18 / 4) begin
        host_dout <= data[6 * 32 +: 32];
      end else if (host_addr == 'h1c / 4) begin
        host_dout <= data[7 * 32 +: 32];
      end else if (host_addr == 'h50 / 4) begin
        host_dout <= k2o_b_fifo_rvalid;
      end else if (host_addr == 'h60 / 4) begin
        host_dout <= k2o_r_fifo_rvalid;
      end else if (host_addr == 'h70 / 4) begin
        host_dout <= o2k_aw_fifo_rvalid;
      end else if (host_addr == 'h80 / 4) begin
        host_dout <= o2k_w_fifo_rvalid;
      end else if (host_addr == 'h90 / 4) begin
        host_dout <= o2k_ar_fifo_rvalid;
      end
    end
  end
end

fifo_bp #(
  .DATA_WIDTH(64),
  .LOG2_DEPTH($clog2(512))
) k2o_aw_fifo (
  .clk(clk),
  .rstn(rstn),
  .rvalid(k2o_aw_fifo_rvalid),
  .rdata (k2o_aw_fifo_rdata),
  .rready(k2o_aw_fifo_rready),
  .wvalid(k2o_aw_fifo_wvalid),
  .wdata (k2o_aw_fifo_wdata),
  .wready(k2o_aw_fifo_wready)
);

always_comb begin
  // except awburst/awlen/awsize, default is 0
  k2o_awaddr = k2o_aw_fifo_rdata;
  k2o_awburst = 1; // INCR
  k2o_awcache = 0;
  k2o_awid = MAGIC_AWID;
  k2o_awlen = 0; // burst length 1
  k2o_awlock = 0;
  k2o_awprot = 0;
  k2o_awqos = 0;
  k2o_aw_fifo_rready = k2o_awready;
  k2o_awregion = 0;
  k2o_awsize = 4; // 16B = 128b
  k2o_awvalid = k2o_aw_fifo_rvalid;
end

fifo_bp #(
  .DATA_WIDTH(128),
  .LOG2_DEPTH($clog2(512))
) k2o_w_fifo (
  .clk(clk),
  .rstn(rstn),
  .rvalid(k2o_w_fifo_rvalid),
  .rdata (k2o_w_fifo_rdata),
  .rready(k2o_w_fifo_rready),
  .wvalid(k2o_w_fifo_wvalid),
  .wdata (k2o_w_fifo_wdata),
  .wready(k2o_w_fifo_wready)
);

always_comb begin
  k2o_wdata = k2o_w_fifo_rdata;
  k2o_wlast = 1;
  k2o_w_fifo_rready = k2o_wready;
  k2o_strb = '1;
  k2o_wvalid = k2o_w_fifo_rvalid;
end

fifo_bp #(
  .DATA_WIDTH(64),
  .LOG2_DEPTH($clog2(512))
) k2o_ar_fifo (
  .clk(clk),
  .rstn(rstn),
  .rvalid(k2o_ar_fifo_rvalid),
  .rdata (k2o_ar_fifo_rdata),
  .rready(k2o_ar_fifo_rready),
  .wvalid(k2o_ar_fifo_wvalid),
  .wdata (k2o_ar_fifo_wdata),
  .wready(k2o_ar_fifo_wready)
);

always_comb begin
  // except arburst/arlen/arsize, default is 0
  k2o_araddr = k2o_ar_fifo_rdata;
  k2o_arburst = 1; // INCR
  k2o_arcache = 0;
  k2o_arid = MAGIC_ARID;
  k2o_arlen = 0; // burst length 1
  k2o_arlock = 0;
  k2o_arprot = 0;
  k2o_arqos = 0;
  k2o_ar_fifo_rready = k2o_arready;
  k2o_arregion = 0;
  k2o_arsize = 4; // 16B = 128b
  k2o_arvalid = k2o_ar_fifo_rvalid;
end

fifo_bp #(
  .DATA_WIDTH(K2O_B_FIFO_WIDTH),
  .LOG2_DEPTH($clog2(512))
) k2o_b_fifo (
  .clk(clk),
  .rstn(rstn),
  .rvalid(k2o_b_fifo_rvalid),
  .rdata (k2o_b_fifo_rdata),
  .rready(k2o_b_fifo_rready),
  .wvalid(k2o_b_fifo_wvalid),
  .wdata (k2o_b_fifo_wdata),
  .wready(k2o_b_fifo_wready)
);

always_comb begin
  k2o_b_fifo_wvalid = k2o_bvalid;
  k2o_b_fifo_wdata = {k2o_bid, k2o_bresp};
  k2o_bready = k2o_b_fifo_wready;
end

fifo_bp #(
  .DATA_WIDTH(K2O_R_FIFO_WIDTH),
  .LOG2_DEPTH($clog2(512))
) k2o_r_fifo (
  .clk(clk),
  .rstn(rstn),
  .rvalid(k2o_r_fifo_rvalid),
  .rdata (k2o_r_fifo_rdata),
  .rready(k2o_r_fifo_rready),
  .wvalid(k2o_r_fifo_wvalid),
  .wdata (k2o_r_fifo_wdata),
  .wready(k2o_r_fifo_wready)
);

always_comb begin
  k2o_r_fifo_wvalid = k2o_rvalid;
  k2o_r_fifo_wdata = {k2o_rid, k2o_rresp, k2o_rdata};
  k2o_rready = k2o_r_fifo_wready;
end

fifo_bp #(
  .DATA_WIDTH(O2K_AW_FIFO_WIDTH),
  .LOG2_DEPTH($clog2(512))
) o2k_aw_fifo (
  .clk(clk),
  .rstn(rstn),
  .rvalid(o2k_aw_fifo_rvalid),
  .rdata (o2k_aw_fifo_rdata),
  .rready(o2k_aw_fifo_rready),
  .wvalid(o2k_aw_fifo_wvalid),
  .wdata (o2k_aw_fifo_wdata),
  .wready(o2k_aw_fifo_wready)
);

always_comb begin
  o2k_aw_fifo_wvalid = o2k_awvalid;
  o2k_aw_fifo_wdata = {o2k_awid, o2k_awlen, o2k_awaddr};
  o2k_awready = o2k_aw_fifo_wready;
end

fifo_bp #(
  .DATA_WIDTH(128),
  .LOG2_DEPTH($clog2(512))
) o2k_w_fifo (
  .clk(clk),
  .rstn(rstn),
  .rvalid(o2k_w_fifo_rvalid),
  .rdata (o2k_w_fifo_rdata),
  .rready(o2k_w_fifo_rready),
  .wvalid(o2k_w_fifo_wvalid),
  .wdata (o2k_w_fifo_wdata),
  .wready(o2k_w_fifo_wready)
);

always_comb begin
  o2k_w_fifo_wvalid = o2k_wvalid;
  o2k_w_fifo_wdata = o2k_wdata;
  o2k_wready = o2k_w_fifo_wready;
end

fifo_bp #(
  .DATA_WIDTH(O2K_AR_FIFO_WIDTH),
  .LOG2_DEPTH($clog2(512))
) o2k_ar_fifo (
  .clk(clk),
  .rstn(rstn),
  .rvalid(o2k_ar_fifo_rvalid),
  .rdata (o2k_ar_fifo_rdata),
  .rready(o2k_ar_fifo_rready),
  .wvalid(o2k_ar_fifo_wvalid),
  .wdata (o2k_ar_fifo_wdata),
  .wready(o2k_ar_fifo_wready)
);

always_comb begin
  o2k_ar_fifo_wvalid = o2k_arvalid;
  o2k_ar_fifo_wdata = {o2k_arid, o2k_arlen, o2k_araddr};
  o2k_arready = o2k_ar_fifo_wready;
end

fifo_bp #(
  .DATA_WIDTH(O2K_B_FIFO_WIDTH),
  .LOG2_DEPTH($clog2(512))
) o2k_b_fifo (
  .clk(clk),
  .rstn(rstn),
  .rvalid(o2k_b_fifo_rvalid),
  .rdata (o2k_b_fifo_rdata),
  .rready(o2k_b_fifo_rready),
  .wvalid(o2k_b_fifo_wvalid),
  .wdata (o2k_b_fifo_wdata),
  .wready(o2k_b_fifo_wready)
);

always_comb begin
  o2k_bid = o2k_b_fifo_rdata;
  o2k_bresp = 0; // OKAY
  o2k_bvalid = o2k_b_fifo_rvalid;
  o2k_b_fifo_rready = o2k_bready;
end

fifo_bp #(
  .DATA_WIDTH(O2K_R_FIFO_WIDTH),
  .LOG2_DEPTH($clog2(512))
) o2k_r_fifo (
  .clk(clk),
  .rstn(rstn),
  .rvalid(o2k_r_fifo_rvalid),
  .rdata (o2k_r_fifo_rdata),
  .rready(o2k_r_fifo_rready),
  .wvalid(o2k_r_fifo_wvalid),
  .wdata (o2k_r_fifo_wdata),
  .wready(o2k_r_fifo_wready)
);

always_comb begin
  {o2k_rid, o2k_rlast, o2k_rdata} = o2k_r_fifo_rdata;
  o2k_rresp = 0; // OKAY
  o2k_rvalid = o2k_r_fifo_rvalid;
  o2k_r_fifo_rready = o2k_rready;
end

endmodule