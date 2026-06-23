`timescale 1 ps / 1 ps

module csr(
  // host bram interface
  input logic [15:0]  host_addr,
  input logic         host_clk,
  input logic [31:0]  host_din,
  output logic [31:0] host_dout,
  input logic         host_en,
  input logic         host_rst,
  input logic [3:0]   host_we,

  output logic        sw_reset,
  
  output logic        cfg_0a_write,
  output logic        cfg_0a_read,
  output logic [31:0] cfg_0a_wraddr,
  output logic [31:0] cfg_0a_wrdata,
  output logic [31:0] cfg_0a_rdaddr,
  input logic [31:0]  cfg_0a_rddata,
  input logic         cfg_0a_wrdone,
  input logic         cfg_0a_rddone,
  output logic        cfg_0a_cfgdone,

  output logic        bringup_start,   // 0x08 write -> kick the HW bring-up sequencer
  input  logic        bringup_ready,   // 0x0C read bit0 = bring-up complete
  input  logic        bringup_busy,    // 0x0C read bit1 = bring-up running

  output logic        oculink_0a_send_iocq_create_cmd,
  output logic        oculink_0a_send_iosq_create_cmd,
  output logic        oculink_0a_send_read_cmd,
  output logic        oculink_0a_send_write_cmd,
  output logic [31:0] oculink_0a_nvme_addr,
  output logic [31:0] oculink_0a_fpga_addr,
  output logic [31:0] oculink_0a_nlb,
  input logic         oculink_0a_cpl_done,
  output logic [31:0] oculink_0a_wrdata [7:0],
  input logic [31:0]  oculink_0a_rddata [7:0],
  input logic [31:0]  oculink_0a_cpl_status,
  input logic [31:0]  oculink_0a_cpl_count,
  input logic [31:0]  oculink_0a_r_data_beats,
  input logic [31:0]  oculink_0a_w_data_beats,
  input logic [31:0]  oculink_0a_raw_w_beats,
  input logic [31:0]  oculink_0a_raw_w_bursts,
  // ---- DDR4 data-path control/status ----
  output logic        cp_go_tgl,             // toggles on each 0x84 write (CDC'd to cp_clk in nvme_driver)
  output logic [1:0]  cp_op,                 // 0x84[1:0]: 0=copy-push 1=copy-pull 2=refill 3=drain
  output logic [15:0] cp_nwords,             // 0x88: 256-b words (copy chunk size / stream total)
  output logic [15:0] cp_base,               // 0x8C: DDR4 word base for the copy op
  input  logic        cp_busy_raw,           // cp_clk; synced here
  input  logic        cal_done_raw           // ui_clk; synced here
);
  // sync the DDR4 status bits into host_clk for the 0x80 read
  (* ASYNC_REG="true" *) logic [1:0] busy_s, cal_s;
  always_ff @(posedge host_clk) begin busy_s<={busy_s[0],cp_busy_raw}; cal_s<={cal_s[0],cal_done_raw}; end
  
  // scratch reg for debugging
  reg [31:0] scratch;

  // WRITE : host -> FPGA 
  always_ff @( posedge host_clk ) begin : CSR_WRITE
    // make pulse
    cfg_0a_write   <= 0;
    cfg_0a_read    <= 0;
    oculink_0a_send_iocq_create_cmd <= 0;
    oculink_0a_send_iosq_create_cmd <= 0;
    oculink_0a_send_read_cmd        <= 0;
    oculink_0a_send_write_cmd       <= 0;
    bringup_start                   <= 0;

    if (host_rst) begin
      scratch         <= 32'd0;
      sw_reset        <= 0;

      cfg_0a_write    <= 0;
      cfg_0a_read     <= 0;
      cfg_0a_wraddr   <= 0;
      cfg_0a_wrdata   <= 0;
      cfg_0a_rdaddr   <= 0;
      cfg_0a_cfgdone  <= 0;
      oculink_0a_send_iocq_create_cmd <= 0;
      oculink_0a_send_iosq_create_cmd <= 0;
      oculink_0a_send_read_cmd        <= 0;
      oculink_0a_send_write_cmd       <= 0;
      oculink_0a_nvme_addr            <= 0;
      oculink_0a_fpga_addr            <= 0;
      oculink_0a_nlb                  <= 0;
      cp_go_tgl                       <= 0;
      cp_op                           <= 0;
      cp_nwords                       <= 16'd4096;   // default: one 128 KB window
      cp_base                         <= 0;
    end
    else if (host_we && host_en) begin
      case(host_addr)
        16'h0000: scratch                         <= host_din;
        16'h0004: sw_reset                        <= host_din[0];
        16'h0008: bringup_start                   <= 1'b1;   // kick HW bring-up sequencer
        16'h0010: cfg_0a_write                    <= 1'b1;
        16'h0014: cfg_0a_wraddr                   <= host_din;
        16'h0018: cfg_0a_wrdata                   <= host_din;
        16'h0020: cfg_0a_read                     <= 1'b1;
        16'h0024: cfg_0a_rdaddr                   <= host_din;
        16'h0030: cfg_0a_cfgdone                  <= host_din[0];
        16'h0040: oculink_0a_send_iocq_create_cmd <= 1'b1;
        16'h0044: oculink_0a_send_iosq_create_cmd <= 1'b1;
        16'h0048: oculink_0a_send_read_cmd        <= 1'b1;
        16'h004C: oculink_0a_send_write_cmd       <= 1'b1;
        16'h0084: begin cp_go_tgl <= ~cp_go_tgl; cp_op <= host_din[1:0]; end     // trigger a DDR4 op
        16'h0088: cp_nwords                       <= host_din[15:0];             // words (chunk / stream total)
        16'h008C: cp_base                         <= host_din[15:0];             // DDR4 word base for the copy
        16'h0050: oculink_0a_nvme_addr            <= host_din;
        16'h0054: oculink_0a_fpga_addr            <= host_din;
        16'h0058: oculink_0a_nlb                  <= host_din;
        16'h0100: oculink_0a_wrdata[0]            <= host_din;
        16'h0104: oculink_0a_wrdata[1]            <= host_din;
        16'h0108: oculink_0a_wrdata[2]            <= host_din;
        16'h010C: oculink_0a_wrdata[3]            <= host_din;
        16'h0110: oculink_0a_wrdata[4]            <= host_din;
        16'h0114: oculink_0a_wrdata[5]            <= host_din;
        16'h0118: oculink_0a_wrdata[6]            <= host_din;
        16'h011C: oculink_0a_wrdata[7]            <= host_din;

        default:;
      endcase
    end

  end
  

  // READ : FPGA -> host
  always_ff @( posedge host_clk ) begin : CSR_READ
    // make pulse

    if (host_rst) begin
      host_dout <= 32'd0;

    end
    else if (host_en) begin
      case(host_addr) 
        16'h0000: host_dout <= scratch;
        16'h0004: host_dout <= sw_reset;
        16'h000C: host_dout <= {30'd0, bringup_busy, bringup_ready};  // bring-up status
        16'h0014: host_dout <= cfg_0a_wraddr;
        16'h0018: host_dout <= cfg_0a_wrdata;
        16'h001C: host_dout <= cfg_0a_wrdone;
        16'h0024: host_dout <= cfg_0a_rdaddr;
        16'h0028: host_dout <= cfg_0a_rddata;
        16'h002C: host_dout <= cfg_0a_rddone;
        16'h0030: host_dout <= cfg_0a_cfgdone;
        16'h0050: host_dout <= oculink_0a_nvme_addr;
        16'h0054: host_dout <= oculink_0a_fpga_addr;
        16'h0058: host_dout <= oculink_0a_nlb;
        16'h005C: host_dout <= oculink_0a_cpl_done;
        16'h0060: host_dout <= oculink_0a_cpl_status;   // last completion CQE DW3 (status/phase/cid)
        16'h0064: host_dout <= oculink_0a_cpl_count;    // monotonic completion counter (multi-outstanding)
        16'h0068: host_dout <= oculink_0a_r_data_beats; // real write-payload R beats served (x32 B)
        16'h006C: host_dout <= oculink_0a_w_data_beats; // real read-payload  W beats captured (x32 B)
        16'h0070: host_dout <= oculink_0a_raw_w_beats;  // DIAG: ALL accepted W beats (any class)
        16'h0074: host_dout <= oculink_0a_raw_w_bursts; // DIAG: read-data (non-CQE) W bursts
        16'h0080: host_dout <= {30'd0, cal_s[1], busy_s[1]};  // DDR4: bit1=cal_done, bit0=copy busy
        16'h0100: host_dout <= oculink_0a_wrdata[0];
        16'h0104: host_dout <= oculink_0a_wrdata[1];
        16'h0108: host_dout <= oculink_0a_wrdata[2];
        16'h010C: host_dout <= oculink_0a_wrdata[3];
        16'h0110: host_dout <= oculink_0a_wrdata[4];
        16'h0114: host_dout <= oculink_0a_wrdata[5];
        16'h0118: host_dout <= oculink_0a_wrdata[6];
        16'h011C: host_dout <= oculink_0a_wrdata[7];
        16'h0200: host_dout <= oculink_0a_rddata[0];   // read-back data (valid after cpl_done)
        16'h0204: host_dout <= oculink_0a_rddata[1];
        16'h0208: host_dout <= oculink_0a_rddata[2];
        16'h020C: host_dout <= oculink_0a_rddata[3];
        16'h0210: host_dout <= oculink_0a_rddata[4];
        16'h0214: host_dout <= oculink_0a_rddata[5];
        16'h0218: host_dout <= oculink_0a_rddata[6];
        16'h021C: host_dout <= oculink_0a_rddata[7];

        default: host_dout <= 32'd0;
      endcase
    end
  end

endmodule
