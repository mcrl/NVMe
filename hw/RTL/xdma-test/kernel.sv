module kernel (
  input logic clk,
  input logic rstn,
  output logic ocu_rstn,

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
  input  logic [63:0] o2k_awaddr,
  input  logic [1:0]  o2k_awburst,
  input  logic [3:0]  o2k_awcache,
  input  logic [3:0]  o2k_awid,
  input  logic [7:0]  o2k_awlen,
  input  logic [0:0]  o2k_awlock,
  input  logic [2:0]  o2k_awprot,
  input  logic [3:0]  o2k_awqos,
  output logic        o2k_awready,
  input  logic [3:0]  o2k_awregion,
  input  logic [2:0]  o2k_awsize,
  input  logic        o2k_awvalid,
  // W
  input  logic [127:0] o2k_wdata,
  input  logic         o2k_wlast,
  output logic         o2k_wready,
  input  logic [15:0]  o2k_wstrb,
  input  logic         o2k_wvalid,
  // AR
  input  logic [63:0] o2k_araddr,
  input  logic [1:0]  o2k_arburst,
  input  logic [3:0]  o2k_arcache,
  input  logic [3:0]  o2k_arid,
  input  logic [7:0]  o2k_arlen,
  input  logic [0:0]  o2k_arlock,
  input  logic [2:0]  o2k_arprot,
  input  logic [3:0]  o2k_arqos,
  output logic        o2k_arready,
  input  logic [3:0]  o2k_arregion,
  input  logic [2:0]  o2k_arsize,
  input  logic        o2k_arvalid,
  // B
  output logic [3:0] o2k_bid,
  input  logic       o2k_bready,
  output logic [1:0] o2k_bresp,
  output logic       o2k_bvalid,
  // R
  output logic [127:0] o2k_rdata,
  output logic [3:0]   o2k_rid,
  output logic         o2k_rlast,
  input  logic         o2k_rready,
  output logic [1:0]   o2k_rresp,
  output logic         o2k_rvalid
);

localparam MAGIC_AWID = 1;
localparam MAGIC_ARID = 2;

localparam K2O_AW_FIFO_WIDTH = 3 + 64; // awsize, awaddr
logic                             k2o_aw_fifo_rvalid;
logic [K2O_AW_FIFO_WIDTH - 1 : 0] k2o_aw_fifo_rdata;
logic                             k2o_aw_fifo_rready;
logic                             k2o_aw_fifo_wvalid;
logic [K2O_AW_FIFO_WIDTH - 1 : 0] k2o_aw_fifo_wdata;
logic                             k2o_aw_fifo_wready;

localparam K2O_W_FIFO_WIDTH = 16 + 128; // wstrb, wdata
logic                            k2o_w_fifo_rvalid;
logic [K2O_W_FIFO_WIDTH - 1 : 0] k2o_w_fifo_rdata;
logic                            k2o_w_fifo_rready;
logic                            k2o_w_fifo_wvalid;
logic [K2O_W_FIFO_WIDTH - 1 : 0] k2o_w_fifo_wdata;
logic                            k2o_w_fifo_wready;

localparam K2O_AR_FIFO_WIDTH = 3 + 64; // arsize, araddr
logic                             k2o_ar_fifo_rvalid;
logic [K2O_AR_FIFO_WIDTH - 1 : 0] k2o_ar_fifo_rdata;
logic                             k2o_ar_fifo_rready;
logic                             k2o_ar_fifo_wvalid;
logic [K2O_AR_FIFO_WIDTH - 1 : 0] k2o_ar_fifo_wdata;
logic                             k2o_ar_fifo_wready;

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

localparam O2K_AW_FIFO_WIDTH = 4 + 8 + 3 + 64; // id, len, size, addr
logic                             o2k_aw_fifo_rvalid;
logic [O2K_AW_FIFO_WIDTH - 1 : 0] o2k_aw_fifo_rdata;
logic                             o2k_aw_fifo_rready;
logic                             o2k_aw_fifo_wvalid;
logic [O2K_AW_FIFO_WIDTH - 1 : 0] o2k_aw_fifo_wdata;
logic                             o2k_aw_fifo_wready;

localparam O2K_W_FIFO_WIDTH = 16 + 128; // strb, data
logic                            o2k_w_fifo_rvalid;
logic [O2K_W_FIFO_WIDTH - 1 : 0] o2k_w_fifo_rdata;
logic                            o2k_w_fifo_rready;
logic                            o2k_w_fifo_wvalid;
logic [O2K_W_FIFO_WIDTH - 1 : 0] o2k_w_fifo_wdata;
logic                            o2k_w_fifo_wready;

localparam O2K_AR_FIFO_WIDTH = 4 + 8 + 3 + 64; // id, len, size, addr
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
logic ocu_rstn_sw;


logic [511:0] command;
logic [15:0] command_id;
logic sq_push;
logic sq_pop;
logic [15:0] sq_head_ptr;
logic [511:0] sq_din;
logic [127:0] sq_dout;
logic sq_full;
logic sq_empty;
logic sq_rvalid;
logic sq_wack;

logic flag;

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
    o2k_b_fifo_wvalid <= 0;
    o2k_r_fifo_wvalid <= 0;
    ocu_rstn <= 0;
    ocu_rstn_sw <= 1;

    command_id <= 0;
    sq_head_ptr <= 0;
    sq_pop <= 0;
    sq_push <= 0;

    flag <= 0;
  end else begin
    k2o_aw_fifo_wvalid <= 0;
    k2o_w_fifo_wvalid <= 0;
    k2o_ar_fifo_wvalid <= 0;
    k2o_b_fifo_rready <= 0;
    k2o_r_fifo_rready <= 0;
    o2k_aw_fifo_rready <= 0;
    o2k_w_fifo_rready <= 0;
    o2k_ar_fifo_rready <= 0;
    o2k_b_fifo_wvalid <= 0;
    o2k_r_fifo_wvalid <= 0;
    ocu_rstn <= ocu_rstn_sw;
    
    sq_pop <= 0;
    sq_push <= 0;
    command[1 * 32 +: 32] <= 32'h1; // NSID

    if (flag) begin
      if          (host_addr == 'h400) begin
        k2o_aw_fifo_wvalid <= 1;
        k2o_aw_fifo_wdata <= 'h5008;
        k2o_w_fifo_wvalid <= 1;
        k2o_w_fifo_wdata <= sq_head_ptr;
      end else if (host_addr == 'h404) begin
        flag <= 0;
      end 
    end
    else if (host_en && host_we != 0) begin
      if          (host_addr == 'h00) begin
        data[0 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h04) begin
        data[1 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h08) begin
        data[2 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h0c) begin
        data[3 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h10) begin
        data[4 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h14) begin
        data[5 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h18) begin
        data[6 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h1c) begin
        data[7 * 32 +: 32] <= host_din;
      end else if (host_addr == 'h20) begin
        k2o_aw_fifo_wvalid <= 1;
        k2o_aw_fifo_wdata <= data;
      end else if (host_addr == 'h30) begin
        k2o_w_fifo_wvalid <= 1;
        k2o_w_fifo_wdata <= data;
      end else if (host_addr == 'h40) begin
        k2o_ar_fifo_wvalid <= 1;
        k2o_ar_fifo_wdata <= data;
      end else if (host_addr == 'h54) begin
        k2o_b_fifo_rready <= 1;
        data <= k2o_b_fifo_rdata;
      end else if (host_addr == 'h64) begin
        k2o_r_fifo_rready <= 1;
        data <= k2o_r_fifo_rdata;
      end else if (host_addr == 'h74) begin
        o2k_aw_fifo_rready <= 1;
        data <= o2k_aw_fifo_rdata;
      end else if (host_addr == 'h84) begin
        o2k_w_fifo_rready <= 1;
        data <= o2k_w_fifo_rdata;
      end else if (host_addr == 'h94) begin
        o2k_ar_fifo_rready <= 1;
        data <= o2k_ar_fifo_rdata;
      end else if (host_addr == 'ha0) begin
        o2k_b_fifo_wvalid <= 1;
        o2k_b_fifo_wdata <= data;
      end else if (host_addr == 'hb0) begin
        o2k_r_fifo_wvalid <= 1;
        o2k_r_fifo_wdata <= data;
      end else if (host_addr == 'hc0) begin
        ocu_rstn_sw <= 0;
      end else if (host_addr == 'hc4) begin
        ocu_rstn_sw <= 1;
      end else if (host_addr == 'h100) begin
        // nvme address (LBA)
        command[(15-10) * 32 +: 32] <= host_din;  
      end else if (host_addr == 'h104) begin
        // fpga data pointer (DPTR)
        command[(15-6) * 32 +: 32] <= host_din;  
      end else if (host_addr == 'h108) begin
        // 4KB * n length (NLB) + Opcode + CID
        command[(15-10) * 32 +: 16] <= host_din[31:16];  
        command[(15-0) * 32 +: 32] <= {command_id, 8'h0, host_din[7:0]};  
      end else if (host_addr == 'h110) begin 
        // push command + write doorbell
        sq_din <= command;
        sq_push <= 1'b1;
        command_id <= command_id + 16'b1;
        sq_head_ptr <= sq_head_ptr + 16'b1;
      end else if (host_addr == 'h114) begin
        // Reset ptr + command id 
        command_id <= 0;
        sq_head_ptr <= 0;
      end else if (host_addr == 'h300) begin
        flag <= 1;
      end else if (host_addr == 'h304) begin
        flag <= 0;
      end 

    end else begin
      sq_pop <= 0;
      
      if          (host_addr == 'h00) begin
        host_dout <= data[0 * 32 +: 32];
      end else if (host_addr == 'h04) begin
        host_dout <= data[1 * 32 +: 32];
      end else if (host_addr == 'h08) begin
        host_dout <= data[2 * 32 +: 32];
      end else if (host_addr == 'h0c) begin
        host_dout <= data[3 * 32 +: 32];
      end else if (host_addr == 'h10) begin
        host_dout <= data[4 * 32 +: 32];
      end else if (host_addr == 'h14) begin
        host_dout <= data[5 * 32 +: 32];
      end else if (host_addr == 'h18) begin
        host_dout <= data[6 * 32 +: 32];
      end else if (host_addr == 'h1c) begin
        host_dout <= data[7 * 32 +: 32];
      end else if (host_addr == 'h50) begin
        host_dout <= k2o_b_fifo_rvalid;
      end else if (host_addr == 'h60) begin
        host_dout <= k2o_r_fifo_rvalid;
      end else if (host_addr == 'h70) begin
        host_dout <= o2k_aw_fifo_rvalid;
      end else if (host_addr == 'h80) begin
        host_dout <= o2k_w_fifo_rvalid;
      end else if (host_addr == 'h90) begin
        host_dout <= o2k_ar_fifo_rvalid;
      end else if (host_addr == 'h200) begin
        if(!sq_empty) sq_pop <= 1;
        else sq_pop <= 0;
      end else if (host_addr == 'h204) begin
        host_dout <= {command_id, sq_head_ptr};
      end
    end
  end
end


fifo_bp #(
  .DATA_WIDTH(K2O_AW_FIFO_WIDTH),
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
  {k2o_awsize, k2o_awaddr} = k2o_aw_fifo_rdata;
  k2o_awburst = 1; // INCR
  k2o_awcache = 0;
  k2o_awid = MAGIC_AWID;
  k2o_awlen = 0; // burst length 1
  k2o_awlock = 0;
  k2o_awprot = 0;
  k2o_awqos = 0;
  k2o_aw_fifo_rready = k2o_awready;
  k2o_awvalid = k2o_aw_fifo_rvalid;
end

fifo_bp #(
  .DATA_WIDTH(K2O_W_FIFO_WIDTH),
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
  {k2o_wstrb, k2o_wdata} = k2o_w_fifo_rdata;
  k2o_wlast = 1;
  k2o_w_fifo_rready = k2o_wready;
  k2o_wvalid = k2o_w_fifo_rvalid;
end

fifo_bp #(
  .DATA_WIDTH(K2O_AR_FIFO_WIDTH),
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
  {k2o_arsize, k2o_araddr} = k2o_ar_fifo_rdata;
  k2o_arburst = 1; // INCR
  k2o_arcache = 0;
  k2o_arid = MAGIC_ARID;
  k2o_arlen = 0; // burst length 1
  k2o_arlock = 0;
  k2o_arprot = 0;
  k2o_arqos = 0;
  k2o_ar_fifo_rready = k2o_arready;
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
  o2k_aw_fifo_wdata = {o2k_awid, o2k_awlen, o2k_awsize, o2k_awaddr};
  o2k_awready = o2k_aw_fifo_wready;
end

fifo_bp #(
  .DATA_WIDTH(O2K_W_FIFO_WIDTH),
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
  o2k_w_fifo_wdata = {o2k_wstrb, o2k_wdata};
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
  o2k_ar_fifo_wdata = {o2k_arid, o2k_arlen, o2k_arsize, o2k_araddr};
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

// I/O submission queue
sq sq_inst (
  .clk(clk),          // input wire clk
  .srst(~rstn),       // input wire srst
  .din(sq_din),       // input wire [511 : 0] din
  .wr_en(sq_push),    // input wire wr_en
  .rd_en(sq_pop),     // input wire rd_en
  .dout(sq_dout),     // output wire [127 : 0] dout
  .full(sq_full),     // output wire full
  .empty(sq_empty),   // output wire empty
  .wr_ack(sq_wack),   // output wire wr_ack
  .valid(sq_rvalid),  // output wire valid
  .wr_rst_busy(),     // output wire wr_rst_busy
  .rd_rst_busy()      // output wire rd_rst_busy
);


ila_0 ila_0_inst (
	.clk(clk), // input wire clk
	.probe0(sq_din), // input wire [511:0]  probe0  
	.probe1(sq_push), // input wire [0:0]  probe1 
	.probe2(sq_pop), // input wire [0:0]  probe2 
	.probe3(sq_dout), // input wire [127:0]  probe3 
	.probe4(sq_full), // input wire [0:0]  probe4 
	.probe5(sq_empty), // input wire [0:0]  probe5 
	.probe6(command), // input wire [511:0]  probe6
  .probe7(host_addr), // input wire [14:0] probe7
  .probe8(sq_rvalid), // 1-bit 
  .probe9(sq_wack)    // 1-bit
);

endmodule