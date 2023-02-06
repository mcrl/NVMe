module kernel #(
  parameter HOST_ADDR_WIDTH = 21,
  parameter HOST_DATA_WIDTH = 32,
  parameter CMAC_DATA_WIDTH = 512
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

  // AXIS master for cmac
  output logic [CMAC_DATA_WIDTH-1:0]   m_tdata,
  output logic [CMAC_DATA_WIDTH/8-1:0] m_tkeep,
  output logic m_tvalid,
  input  logic m_tready,
  output logic m_tlast,
  output logic m_tuser,

  // AXIS slave for cmac
  input logic [CMAC_DATA_WIDTH-1:0]   s_tdata,
  input logic [CMAC_DATA_WIDTH/8-1:0] s_tkeep,
  input logic s_tvalid,
  input logic s_tlast,
  input logic s_tuser
);

// Register map
// 0x00 WO m_tdata
// ...
// 0x3c WO m_tdata
// 0x40 WO m_tkeep
// 0x44 WO m_tkeep
// 0x48 WO m_tlast
// 0x4c WO m_tuser
// 0x50 RW m_tvalid trigger until ready
// 0x60 RO s_tdata
// ...
// 0x9c RO s_tdata from last valid
// 0xa0 RO s_tkeep
// 0xa4 RO s_tkeep
// 0xa8 RO s_tlast
// 0xac RO s_tuser

// glue logic
logic hostwrhdl_valid;
logic hostwrhdl_ready;
logic hostrdhdl_valid;
logic hostrdhdl_ready;

// regs R/W by host
logic [CMAC_DATA_WIDTH-1:0]   s_tdata_buf;
logic [CMAC_DATA_WIDTH/8-1:0] s_tkeep_buf;
logic s_tlast_buf;
logic s_tuser_buf;

always_ff @(posedge clk, negedge rstn) begin
  if (~rstn) begin
    host_bvalid <= 0;
    host_rvalid <= 0;
    m_tvalid <= 0;
  end else begin
    if (hostwrhdl_valid & hostwrhdl_ready) begin
      host_bvalid <= 1;
      if          (host_awaddr == 'h00) begin
        m_tdata[0 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h04) begin
        m_tdata[1 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h08) begin
        m_tdata[2 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h0c) begin
        m_tdata[3 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h10) begin
        m_tdata[4 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h14) begin
        m_tdata[5 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h18) begin
        m_tdata[6 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h1c) begin
        m_tdata[7 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h20) begin
        m_tdata[8 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h24) begin
        m_tdata[9 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h28) begin
        m_tdata[10 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h2c) begin
        m_tdata[11 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h30) begin
        m_tdata[12 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h34) begin
        m_tdata[13 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h38) begin
        m_tdata[14 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h3c) begin
        m_tdata[15 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h40) begin
        m_tkeep[0 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h44) begin
        m_tkeep[1 * 32 +: 32] <= host_wdata;
      end else if (host_awaddr == 'h48) begin
        m_tlast <= host_wdata;
      end else if (host_awaddr == 'h4c) begin
        m_tuser <= host_wdata;
      end else if (host_awaddr == 'h50) begin
        m_tvalid <= 1;
      end
    end
    if (m_tvalid & m_tready) begin
      m_tvalid <= 0;
    end
    if (host_bvalid & host_bready) begin
      host_bvalid <= 0;
    end
    if (hostrdhdl_valid & hostrdhdl_ready) begin
      host_rvalid <= 1;
      if          (host_araddr == 'h50) begin
        host_rdata <= m_tvalid;
      end else if (host_araddr == 'h60) begin
        host_rdata <= s_tdata_buf[0 * 32 +: 32];
      end else if (host_araddr == 'h64) begin
        host_rdata <= s_tdata_buf[1 * 32 +: 32];
      end else if (host_araddr == 'h68) begin
        host_rdata <= s_tdata_buf[2 * 32 +: 32];
      end else if (host_araddr == 'h6c) begin
        host_rdata <= s_tdata_buf[3 * 32 +: 32];
      end else if (host_araddr == 'h70) begin
        host_rdata <= s_tdata_buf[4 * 32 +: 32];
      end else if (host_araddr == 'h74) begin
        host_rdata <= s_tdata_buf[5 * 32 +: 32];
      end else if (host_araddr == 'h78) begin
        host_rdata <= s_tdata_buf[6 * 32 +: 32];
      end else if (host_araddr == 'h7c) begin
        host_rdata <= s_tdata_buf[7 * 32 +: 32];
      end else if (host_araddr == 'h80) begin
        host_rdata <= s_tdata_buf[8 * 32 +: 32];
      end else if (host_araddr == 'h84) begin
        host_rdata <= s_tdata_buf[9 * 32 +: 32];
      end else if (host_araddr == 'h88) begin
        host_rdata <= s_tdata_buf[10 * 32 +: 32];
      end else if (host_araddr == 'h8c) begin
        host_rdata <= s_tdata_buf[11 * 32 +: 32];
      end else if (host_araddr == 'h90) begin
        host_rdata <= s_tdata_buf[12 * 32 +: 32];
      end else if (host_araddr == 'h94) begin
        host_rdata <= s_tdata_buf[13 * 32 +: 32];
      end else if (host_araddr == 'h98) begin
        host_rdata <= s_tdata_buf[14 * 32 +: 32];
      end else if (host_araddr == 'h9c) begin
        host_rdata <= s_tdata_buf[15 * 32 +: 32];
      end else if (host_araddr == 'ha0) begin
        host_rdata <= s_tkeep_buf[0 * 32 +: 32];
      end else if (host_araddr == 'ha4) begin
        host_rdata <= s_tkeep_buf[1 * 32 +: 32];
      end else if (host_araddr == 'ha8) begin
        host_rdata <= s_tlast_buf;
      end else if (host_araddr == 'hac) begin
        host_rdata <= s_tuser_buf;
      end
    end
    if (s_tvalid) begin
      s_tdata_buf <= s_tdata;
      s_tkeep_buf <= s_tkeep;
      s_tlast_buf <= s_tlast;
      s_tuser_buf <= s_tuser;
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

endmodule