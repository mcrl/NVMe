// DDR4 AXI master engine (ui_clk). Serves block read / write requests on a simple streaming interface and
// drives a single AXI4 master to the DDR4 controller. AW and W are presented CONCURRENTLY (the DDR4 AXI gates
// wready on a pending awvalid). One request in flight at a time (the data path sequences them) -> simple and
// easy to verify; bursts up to 256 beats (8 KB at 256-bit) amortise command overhead.
//
//   req_valid/req_we/req_addr/req_len : start a (len+1)-beat write (we=1) or read (we=0) at byte req_addr
//   write: caller drives wd_data+wd_valid, engine pulses wd_ready as each beat is accepted by AXI
//   read : engine drives rd_data+rd_valid, caller pulses rd_ready to accept each beat
//   busy : high from request accept until the burst (+ its B / last R) completes
module ddr4_engine (
  input  logic         clk,
  input  logic         rstn,
  input  logic         req_valid,
  input  logic         req_we,
  input  logic [31:0]  req_addr,
  input  logic [7:0]   req_len,
  output logic         busy,
  input  logic [255:0] wd_data,
  input  logic         wd_valid,
  output logic         wd_ready,
  output logic [255:0] rd_data,
  output logic         rd_valid,
  input  logic         rd_ready,
  output logic [31:0]  m_awaddr,  output logic [7:0] m_awlen, output logic m_awvalid, input logic m_awready,
  output logic [255:0] m_wdata,   output logic m_wlast,  output logic m_wvalid,  input logic m_wready,
  input  logic [1:0]   m_bresp,   input  logic m_bvalid, output logic m_bready,
  output logic [31:0]  m_araddr,  output logic [7:0] m_arlen, output logic m_arvalid, input logic m_arready,
  input  logic [255:0] m_rdata,   input  logic m_rlast,  input  logic m_rvalid,  output logic m_rready,
  input  logic [1:0]   m_rresp
);
  typedef enum logic [1:0] {IDLE, WR, WB, RD} st_t;
  st_t st;
  logic [31:0] addr_q;
  logic [7:0]  len_q;
  logic [7:0]  wrem;          // write beats remaining (incl. current)
  logic        aw_acc;        // AW handshake done for this burst

  assign m_awaddr = addr_q;  assign m_araddr = addr_q;
  assign m_awlen  = len_q;   assign m_arlen  = len_q;
  assign m_wdata  = wd_data;

  // present W only when the caller has a beat; the AXI W handshake is the beat-consume event
  assign m_wvalid = (st==WR) && wd_valid;
  assign wd_ready = (st==WR) && wd_valid && m_wready;
  wire   w_fire   = m_wvalid && m_wready;
  assign m_wlast  = (st==WR) && (wrem==8'd1);

  // read data straight through; caller paces with rd_ready
  assign rd_data  = m_rdata;
  assign rd_valid = (st==RD) && m_rvalid;
  assign m_rready = (st==RD) && rd_ready;
  wire   r_fire   = m_rvalid && m_rready;

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      st<=IDLE; busy<=0; addr_q<=0; len_q<=0; wrem<=0; aw_acc<=0;
      m_awvalid<=0; m_bready<=0; m_arvalid<=0;
    end else begin
      case (st)
        IDLE: begin
          m_bready<=0;
          if (req_valid) begin
            addr_q<=req_addr; len_q<=req_len; busy<=1;
            if (req_we) begin m_awvalid<=1; wrem<=req_len+8'd1; aw_acc<=0; st<=WR; end
            else        begin m_arvalid<=1; st<=RD; end
          end
        end
        WR: begin
          if (m_awvalid && m_awready) begin m_awvalid<=0; aw_acc<=1; end
          if (w_fire) wrem<=wrem-8'd1;
          // last W beat accepted AND AW accepted -> go collect B
          if (w_fire && (wrem==8'd1) && (aw_acc || m_awready)) begin m_bready<=1; st<=WB; end
        end
        WB: if (m_bvalid) begin m_bready<=0; busy<=0; st<=IDLE; end
        RD: begin
          if (m_arvalid && m_arready) m_arvalid<=0;
          if (r_fire && m_rlast) begin busy<=0; st<=IDLE; end
        end
      endcase
    end
  end
endmodule
