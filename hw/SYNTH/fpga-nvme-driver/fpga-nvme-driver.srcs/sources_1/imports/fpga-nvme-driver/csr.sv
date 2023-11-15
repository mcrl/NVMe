`timescale 1 ps / 1 ps

module csr(
  // host bram interface
  input [15:0] host_addr,
  input host_clk,
  input [31:0] host_din,
  output logic [31:0] host_dout,
  input host_en,
  input host_rst,
  input [3:0] host_we,

  // sw reset
  output logic sw_reset,
  output logic nvme_setting_done,
  output logic do_write,
  output logic do_read,

  // csr to nvme rw interfaces
  output logic push_write_cmd,
  output logic push_read_cmd,
  output logic [31:0] nvme_addr,
  output logic [31:0] fpga_addr,
  output logic [31:0] nlb,

  output logic [31:0] dw0,
  output logic [31:0] dw1,
  output logic [31:0] dw2,
  output logic [31:0] dw3,
  output logic [31:0] dw4,
  output logic [31:0] dw5,
  output logic [31:0] dw6,
  output logic [31:0] dw7,
  output logic [31:0] dw8,
  output logic [31:0] dw9,
  output logic [31:0] dw10,
  output logic [31:0] dw11,
  output logic [31:0] dw12,
  output logic [31:0] dw13,
  output logic [31:0] dw14,
  output logic [31:0] dw15,
  output logic [31:0] csr_iosqtdbl,
  output logic [31:0] wrdw0,
  output logic [31:0] wrdw1,
  output logic [31:0] wrdw2,
  output logic [31:0] wrdw3,
  output logic [31:0] wrdw4,
  output logic [31:0] wrdw5,
  output logic [31:0] wrdw6,
  output logic [31:0] wrdw7,
  input logic [63:0] perf_cnt,
  input logic [3:0] perf_state,

  // axi slave interface
  // ar
  output logic [31:0]s_axi_araddr,
  output logic [1:0]s_axi_arburst,
  output logic [3:0]s_axi_arid,
  output logic [7:0]s_axi_arlen,
  output logic [3:0]s_axi_arregion,
  output logic [2:0]s_axi_arsize,
  output logic s_axi_arvalid,
  input logic s_axi_ar_fifo_empty,
  input logic s_axi_ar_fifo_full,  

  // aw
  output logic [31:0]s_axi_awaddr,
  output logic [1:0]s_axi_awburst,
  output logic [3:0]s_axi_awid,
  output logic [7:0]s_axi_awlen,
  output logic [3:0]s_axi_awregion,
  output logic [2:0]s_axi_awsize,
  output logic s_axi_awvalid,
  input logic s_axi_aw_fifo_empty,
  input logic s_axi_aw_fifo_full,  

  // w
  output logic [255:0]s_axi_wdata,
  output logic s_axi_wlast,
  output logic [31:0]s_axi_wstrb,
  output logic s_axi_wvalid,
  input logic s_axi_w_fifo_empty,
  input logic s_axi_w_fifo_full,  

  // r
  input logic [255:0]s_axi_rdata,
  input logic [3:0]s_axi_rid,
  input logic s_axi_rlast,
  input logic [1:0]s_axi_rresp,
  input logic s_axi_rvalid,
  output logic s_axi_r_fifo_pop,
  input logic s_axi_r_fifo_empty,
  input logic s_axi_r_fifo_full,

  // b
  input logic [3:0]s_axi_bid,
  input logic [1:0]s_axi_bresp,
  input logic s_axi_bvalid,
  output logic s_axi_b_fifo_pop,
  input logic s_axi_b_fifo_empty,
  input logic s_axi_b_fifo_full,

  // oculink master interface
  // ar
  output logic m_axi_ar_fifo_pop,
  input logic m_axi_ar_fifo_valid,
  input logic m_axi_ar_fifo_empty,
  input logic m_axi_ar_fifo_full,
  input logic [31:0]m_axi_araddr,
  input logic [1:0]m_axi_arburst,
  input logic [3:0]m_axi_arid,
  input logic [7:0]m_axi_arlen,
  input logic [2:0]m_axi_arsize,

  // aw
  output logic m_axi_aw_fifo_pop,
  input logic m_axi_aw_fifo_valid,
  input logic m_axi_aw_fifo_empty,
  input logic m_axi_aw_fifo_full,
  input logic [31:0]m_axi_awaddr,
  input logic [1:0]m_axi_awburst,
  input logic [3:0]m_axi_awid,
  input logic [7:0]m_axi_awlen,
  input logic [2:0]m_axi_awsize,

  // w
  output logic m_axi_w_fifo_pop,
  input logic m_axi_w_fifo_valid,
  input logic m_axi_w_fifo_empty,
  input logic m_axi_w_fifo_full,
  input logic [255:0]m_axi_wdata,
  input logic m_axi_wlast,
  input logic [31:0]m_axi_wstrb,
  input logic m_axi_wvalid,

  // r
  output logic [255:0]m_axi_rdata,
  output logic [3:0]m_axi_rid,
  output logic m_axi_rlast,
  output logic [1:0]m_axi_rresp,
  output logic m_axi_rvalid,
  input logic m_axi_r_fifo_full,
  input logic m_axi_r_fifo_empty,

  // b
  output logic [3:0]m_axi_bid,
  output logic [1:0]m_axi_bresp,
  output logic m_axi_bvalid,
  input logic m_axi_b_fifo_full,
  input logic m_axi_b_fifo_empty
);
  
  // scratch reg for debugging
  reg [31:0] scratch;

  // WRITE : host -> FPGA 
  always_ff @( posedge host_clk ) begin : CSR_WRITE
    // make pulse
    s_axi_arvalid <= 0;
    s_axi_awvalid <= 0;
    s_axi_wvalid <= 0;
    m_axi_rvalid <= 0;
    m_axi_bvalid <= 0;
    push_write_cmd <= 0;
    push_read_cmd <= 0;

    if (host_rst) begin
      scratch <= 32'd0;
      sw_reset <= 0;
      nvme_setting_done <= 0;
      do_write <= 0;
      do_read <= 0;

      s_axi_araddr <= 0;
      s_axi_arburst <= 0;
      s_axi_arid <= 0;
      s_axi_arlen <= 0;
      s_axi_arregion <= 0;
      s_axi_arsize <= 0;
      s_axi_arvalid <= 0;
      s_axi_awaddr <= 0;
      s_axi_awburst <= 0;
      s_axi_awid <= 0;
      s_axi_awlen <= 0;
      s_axi_awregion <= 0;
      s_axi_awsize <= 0;
      s_axi_awvalid <= 0;
      s_axi_wlast <= 0;
      s_axi_wstrb <= 0;
      s_axi_wdata <= 0;
      s_axi_wvalid <= 0;
      m_axi_rdata <= 0;
      m_axi_rid <= 0;
      m_axi_rlast <= 0;
      m_axi_rresp <= 0;
      m_axi_rvalid <= 0;
      m_axi_bid <= 0;
      m_axi_bresp <= 0;
      m_axi_bvalid <= 0;

      push_write_cmd <= 0;
      push_read_cmd <= 0;
      nvme_addr <= 0;
      fpga_addr <= 0;
      nlb <= 0;

      dw0 <= 0;
      dw1 <= 0;
      dw2 <= 0;
      dw3 <= 0;
      dw4 <= 0;
      dw5 <= 0;
      dw6 <= 0;
      dw7 <= 0;
      dw8 <= 0;
      dw9 <= 0;
      dw10 <= 0;
      dw11 <= 0;
      dw12 <= 0;
      dw13 <= 0;
      dw14 <= 0;
      dw15 <= 0;
      csr_iosqtdbl <= 0;
      wrdw0 <= 0;
      wrdw1 <= 0;
      wrdw2 <= 0;
      wrdw3 <= 0;
      wrdw4 <= 0;
      wrdw5 <= 0;
      wrdw6 <= 0;
      wrdw7 <= 0;

    end  
    else if (host_we && host_en) begin
      case(host_addr) 
        16'h0000: scratch <= host_din;
        16'h0004: sw_reset <= host_din[0];
        16'h0008: nvme_setting_done <= host_din[0];
        16'h000C: do_write <= host_din[0];
        16'h0010: do_read <= host_din[0];
        16'h0014: push_write_cmd <= 1;
        16'h0018: push_read_cmd <= 1;
        16'h001C: nvme_addr <= host_din;
        16'h0020: fpga_addr <= host_din;
        16'h0024: nlb <= host_din;

        16'h0030: dw0 <= host_din;
        16'h0034: dw1 <= host_din;
        16'h0038: dw2 <= host_din;
        16'h003C: dw3 <= host_din;
        16'h0040: dw4 <= host_din;
        16'h0044: dw5 <= host_din;
        16'h0048: dw6 <= host_din;
        16'h004C: dw7 <= host_din;
        16'h0050: dw8 <= host_din;
        16'h0054: dw9 <= host_din;
        16'h0058: dw10 <= host_din;
        16'h005C: dw11 <= host_din;
        16'h0060: dw12 <= host_din;
        16'h0064: dw13 <= host_din;
        16'h0068: dw14 <= host_din;
        16'h006C: dw15 <= host_din;
        16'h0070: csr_iosqtdbl <= host_din;
        16'h0080: wrdw0 <= host_din;
        16'h0084: wrdw1 <= host_din;
        16'h0088: wrdw2 <= host_din;
        16'h008C: wrdw3 <= host_din;
        16'h0090: wrdw4 <= host_din;
        16'h0094: wrdw5 <= host_din;
        16'h0098: wrdw6 <= host_din;
        16'h009C: wrdw7 <= host_din;


        // AXI Slave signals
        // ar
        16'h0100: s_axi_araddr    <= host_din;       // 32
        16'h0104: s_axi_arburst   <= host_din[1:0];  // 2
        16'h0108: s_axi_arid      <= host_din[3:0];  // 4
        16'h010C: s_axi_arlen     <= host_din[7:0];  // 8
        16'h0110: s_axi_arregion  <= host_din[3:0];  // 4
        16'h0114: s_axi_arsize    <= host_din[2:0];  // 3
        16'h0120: s_axi_arvalid   <= 1;

        // aw
        16'h0200: s_axi_awaddr    <= host_din;
        16'h0204: s_axi_awburst   <= host_din[1:0];
        16'h0208: s_axi_awid      <= host_din[3:0];
        16'h020C: s_axi_awlen     <= host_din[7:0];
        16'h0210: s_axi_awregion  <= host_din[3:0];
        16'h0214: s_axi_awsize    <= host_din[2:0];
        16'h0220: s_axi_awvalid   <= 1;

        // w
        16'h0300: s_axi_wlast                 <= host_din[0];
        16'h0304: s_axi_wstrb                 <= host_din;
        16'h0308: s_axi_wdata[32 * 0 + : 32]  <= host_din;
        16'h030C: s_axi_wdata[32 * 1 + : 32]  <= host_din;
        16'h0310: s_axi_wdata[32 * 2 + : 32]  <= host_din;
        16'h0314: s_axi_wdata[32 * 3 + : 32]  <= host_din;
        16'h0318: s_axi_wdata[32 * 4 + : 32]  <= host_din;
        16'h031C: s_axi_wdata[32 * 5 + : 32]  <= host_din;
        16'h0320: s_axi_wdata[32 * 6 + : 32]  <= host_din;
        16'h0324: s_axi_wdata[32 * 7 + : 32]  <= host_din;
        16'h0330: s_axi_wvalid <= 1;

        // AXI Master signals
        // r
        16'h0900: m_axi_rid                   <= host_din[3:0]; // 4
        16'h0904: m_axi_rlast                 <= host_din[0];   // 1
        16'h0908: m_axi_rresp                 <= host_din[1:0]; // 2
        16'h090C: m_axi_rdata[32 * 0 + : 32]  <= host_din;
        16'h0910: m_axi_rdata[32 * 1 + : 32]  <= host_din;
        16'h0914: m_axi_rdata[32 * 2 + : 32]  <= host_din;
        16'h0918: m_axi_rdata[32 * 3 + : 32]  <= host_din;
        16'h091C: m_axi_rdata[32 * 4 + : 32]  <= host_din;
        16'h0920: m_axi_rdata[32 * 5 + : 32]  <= host_din;
        16'h0924: m_axi_rdata[32 * 6 + : 32]  <= host_din;
        16'h0928: m_axi_rdata[32 * 7 + : 32]  <= host_din;
        16'h0934: m_axi_rvalid                <= 1;

        // b
        16'h0A00: m_axi_bid    <= host_din[3:0];  // 4
        16'h0A04: m_axi_bresp  <= host_din[1:0];  // 2
        16'h0A10: m_axi_bvalid <= 1;
        default:;
      endcase
    end

  end
  

  // READ : FPGA -> host
  always_ff @( posedge host_clk ) begin : CSR_READ
    // make pulse
    s_axi_r_fifo_pop <= 0;
    s_axi_b_fifo_pop <= 0;
    m_axi_ar_fifo_pop <= 0;
    m_axi_aw_fifo_pop <= 0;
    m_axi_w_fifo_pop <= 0;

    if (host_rst) begin
      host_dout <= 32'd0;
      s_axi_r_fifo_pop <= 0;
      s_axi_b_fifo_pop <= 0;
      m_axi_ar_fifo_pop <= 0;
      m_axi_aw_fifo_pop <= 0;
      m_axi_w_fifo_pop <= 0;
    end
    else if (host_en) begin
      case(host_addr) 
        16'h0000: host_dout <= scratch;
        16'h0004: host_dout <= sw_reset;
        16'h001C: host_dout <= nvme_addr;
        16'h0020: host_dout <= fpga_addr;
        16'h0024: host_dout <= nlb;
        
        16'h0030: host_dout <= dw0;
        16'h0034: host_dout <= dw1;
        16'h0038: host_dout <= dw2;
        16'h003C: host_dout <= dw3;
        16'h0040: host_dout <= dw4;
        16'h0044: host_dout <= dw5;
        16'h0048: host_dout <= dw6;
        16'h004C: host_dout <= dw7;
        16'h0050: host_dout <= dw8;
        16'h0054: host_dout <= dw9;
        16'h0058: host_dout <= dw10;
        16'h005C: host_dout <= dw11;
        16'h0060: host_dout <= dw12;
        16'h0064: host_dout <= dw13;
        16'h0068: host_dout <= dw14;
        16'h006C: host_dout <= dw15;
        16'h0070: host_dout <= csr_iosqtdbl;
        16'h0074: host_dout <= perf_cnt[31:0];
        16'h0078: host_dout <= perf_cnt[63:32];
        16'h007C: host_dout <= perf_state;
        16'h0080: host_dout <= wrdw0;
        16'h0084: host_dout <= wrdw1;
        16'h0088: host_dout <= wrdw2;
        16'h008C: host_dout <= wrdw3;
        16'h0090: host_dout <= wrdw4;
        16'h0094: host_dout <= wrdw5;
        16'h0098: host_dout <= wrdw6;
        16'h009C: host_dout <= wrdw7;

        // AXI Slave signals
        // ar
        16'h0100: host_dout <= s_axi_araddr;
        16'h0104: host_dout <= s_axi_arburst;
        16'h0108: host_dout <= s_axi_arid;
        16'h010C: host_dout <= s_axi_arlen;
        16'h0110: host_dout <= s_axi_arregion;
        16'h0114: host_dout <= s_axi_arsize;
        16'h0118: host_dout <= s_axi_ar_fifo_empty;
        16'h011C: host_dout <= s_axi_ar_fifo_full;
        //16'h0120: s_axi_arvalid   <= 1;

        // aw
        16'h0200: host_dout <= s_axi_awaddr;
        16'h0204: host_dout <= s_axi_awburst;
        16'h0208: host_dout <= s_axi_awid;
        16'h020C: host_dout <= s_axi_awlen;
        16'h0210: host_dout <= s_axi_awregion;
        16'h0214: host_dout <= s_axi_awsize;
        16'h0218: host_dout <= s_axi_ar_fifo_empty;
        16'h021C: host_dout <= s_axi_ar_fifo_full;
        //16'h0220: s_axi_awvalid   <= 1;

        // w
        16'h0300: host_dout <= s_axi_wlast;
        16'h0304: host_dout <= s_axi_wstrb;
        16'h0308: host_dout <= s_axi_wdata[32 * 0 + : 32];
        16'h030C: host_dout <= s_axi_wdata[32 * 1 + : 32];
        16'h0310: host_dout <= s_axi_wdata[32 * 2 + : 32];
        16'h0314: host_dout <= s_axi_wdata[32 * 3 + : 32];
        16'h0318: host_dout <= s_axi_wdata[32 * 4 + : 32];
        16'h031C: host_dout <= s_axi_wdata[32 * 5 + : 32];
        16'h0320: host_dout <= s_axi_wdata[32 * 6 + : 32];
        16'h0324: host_dout <= s_axi_wdata[32 * 7 + : 32];
        16'h0328: host_dout <= s_axi_w_fifo_empty;
        16'h032C: host_dout <= s_axi_w_fifo_full;
        //16'h0330: s_axi_wvalid <= 1;

        // r
        16'h0400: host_dout <= s_axi_rresp;
        16'h0404: host_dout <= s_axi_rlast;
        16'h0408: host_dout <= s_axi_rid;
        16'h040C: host_dout <= s_axi_rdata[32 * 0 + : 32];
        16'h0410: host_dout <= s_axi_rdata[32 * 1 + : 32];
        16'h0414: host_dout <= s_axi_rdata[32 * 2 + : 32];
        16'h0418: host_dout <= s_axi_rdata[32 * 3 + : 32];
        16'h041C: host_dout <= s_axi_rdata[32 * 4 + : 32];
        16'h0420: host_dout <= s_axi_rdata[32 * 5 + : 32];
        16'h0424: host_dout <= s_axi_rdata[32 * 6 + : 32];
        16'h0428: host_dout <= s_axi_rdata[32 * 7 + : 32];
        16'h042C: host_dout <= s_axi_r_fifo_full;
        16'h0430: host_dout <= s_axi_r_fifo_empty;
        16'h0434: s_axi_r_fifo_pop <= 1;

        // b
        16'h0500: host_dout <= s_axi_bresp;
        16'h0504: host_dout <= s_axi_bid;
        16'h0508: host_dout <= s_axi_b_fifo_full;
        16'h050C: host_dout <= s_axi_b_fifo_empty;
        16'h0510: s_axi_b_fifo_pop <= 1;

        // AXI Master signals
        // ar
        16'h0600: host_dout <= m_axi_araddr;
        16'h0604: host_dout <= m_axi_arburst;
        16'h0608: host_dout <= m_axi_arid;
        16'h060C: host_dout <= m_axi_arlen;
        16'h0614: host_dout <= m_axi_arsize;
        16'h0618: host_dout <= m_axi_ar_fifo_empty;
        16'h061C: host_dout <= m_axi_ar_fifo_full;
        16'h0620: m_axi_ar_fifo_pop <= 1;

        // aw
        16'h0700: host_dout <= m_axi_awaddr;
        16'h0704: host_dout <= m_axi_awburst;
        16'h0708: host_dout <= m_axi_awid;
        16'h070C: host_dout <= m_axi_awlen;
        16'h0710: host_dout <= m_axi_awsize;
        16'h0714: host_dout <= m_axi_aw_fifo_empty;
        16'h0718: host_dout <= m_axi_aw_fifo_full;
        16'h071C: m_axi_aw_fifo_pop <= 1;

        // w
        16'h0800: host_dout <= m_axi_wlast;
        16'h0804: host_dout <= m_axi_wstrb;
        16'h0808: host_dout <= m_axi_wdata[32 * 0 + : 32];
        16'h080C: host_dout <= m_axi_wdata[32 * 1 + : 32];
        16'h0810: host_dout <= m_axi_wdata[32 * 2 + : 32];
        16'h0814: host_dout <= m_axi_wdata[32 * 3 + : 32];
        16'h0818: host_dout <= m_axi_wdata[32 * 4 + : 32];
        16'h081C: host_dout <= m_axi_wdata[32 * 5 + : 32];
        16'h0820: host_dout <= m_axi_wdata[32 * 6 + : 32];
        16'h0824: host_dout <= m_axi_wdata[32 * 7 + : 32];
        16'h0828: host_dout <= m_axi_w_fifo_empty;
        16'h082C: host_dout <= m_axi_w_fifo_full;
        16'h0830: m_axi_w_fifo_pop <= 1;

        // r
        16'h0900: host_dout <= m_axi_rresp; // 2
        16'h0904: host_dout <= m_axi_rlast; // 1
        16'h0908: host_dout <= m_axi_rid;   // 4
        16'h090C: host_dout <= m_axi_rdata[32 * 0 + : 32];
        16'h0910: host_dout <= m_axi_rdata[32 * 1 + : 32];
        16'h0914: host_dout <= m_axi_rdata[32 * 2 + : 32];
        16'h0918: host_dout <= m_axi_rdata[32 * 3 + : 32];
        16'h091C: host_dout <= m_axi_rdata[32 * 4 + : 32];
        16'h0920: host_dout <= m_axi_rdata[32 * 5 + : 32];
        16'h0924: host_dout <= m_axi_rdata[32 * 6 + : 32];
        16'h0928: host_dout <= m_axi_rdata[32 * 7 + : 32];
        16'h092C: host_dout <= m_axi_r_fifo_full;
        16'h0930: host_dout <= m_axi_r_fifo_empty;
        //16'h0934: m_axi_rvalid <= 1;

        // b
        16'h0A00: host_dout <= m_axi_bresp;
        16'h0A04: host_dout <= m_axi_bid;
        16'h0A08: host_dout <= m_axi_b_fifo_full;
        16'h0A0C: host_dout <= m_axi_b_fifo_empty;
        //16'h0A10: m_axi_bvalid <= 1;

        default: host_dout <= 32'd0;
      endcase
    end
  end

endmodule
