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

  output logic        oculink_0a_send_iocq_create_cmd,
  output logic        oculink_0a_send_iosq_create_cmd,
  output logic        oculink_0a_send_read_cmd,
  output logic        oculink_0a_send_write_cmd,
  output logic [31:0] oculink_0a_nvme_addr,
  output logic [31:0] oculink_0a_fpga_addr,
  output logic [31:0] oculink_0a_nlb,
  input logic         oculink_0a_cpl_done,
  output logic [31:0] oculink_0a_wrdata [7:0]
);
  
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
    end  
    else if (host_we && host_en) begin
      case(host_addr) 
        16'h0000: scratch                         <= host_din;
        16'h0004: sw_reset                        <= host_din[0];
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
        16'h0100: host_dout <= oculink_0a_wrdata[0];
        16'h0104: host_dout <= oculink_0a_wrdata[1];
        16'h0108: host_dout <= oculink_0a_wrdata[2];
        16'h010C: host_dout <= oculink_0a_wrdata[3];
        16'h0110: host_dout <= oculink_0a_wrdata[4];
        16'h0114: host_dout <= oculink_0a_wrdata[5];
        16'h0118: host_dout <= oculink_0a_wrdata[6];
        16'h011C: host_dout <= oculink_0a_wrdata[7];

        default: host_dout <= 32'd0;
      endcase
    end
  end

endmodule
