// Gated streaming engine (ui_clk). Streams a transfer between the 4 GB DDR4 and a CIRCULAR on-chip window so a
// single NVMe transfer can exceed the window size. Two instances, one per direction:
//   DIR=0 REFILL (write command): DDR4 -> window. my_prog = words filled. peer_prog = words the SSD has READ.
//          Gate: only fill ahead while (my_prog + burst) <= (peer_prog + WIN)  -> never overwrite unread data.
//   DIR=1 DRAIN  (read command):  window -> DDR4. my_prog = words drained. peer_prog = words the SSD has WRITTEN.
//          Gate: only flush      while (my_prog + burst) <=  peer_prog        -> never read unwritten data.
// Linear non-wrapping word counters (my_prog/peer_prog); wrap lives only in the low AWORDS window address.
// peer_prog arrives already Gray-synced from the oculink domain; my_prog is exported to be Gray-synced back.
// Bursts are <=256 beats and page-aligned (128 words), so a burst never straddles the power-of-two wrap seam.
module stream_engine #(parameter int AWORDS=12, parameter int WIN=4096, parameter int DIR=0)(
  input  logic        clk, rstn,
  input  logic        start,              // 1-cycle: begin streaming a transfer of total_words from DDR4 word 0
  input  logic [31:0] total_words,
  input  logic [31:0] peer_prog,          // SSD-side progress (Gray-synced, ui_clk)
  output logic [31:0] my_prog,
  output logic        busy,
  // circular window port (REFILL writes it; DRAIN reads it). win_raddr issued a cycle before win_dout (RDLAT=1).
  output logic [AWORDS-1:0] win_addr, output logic [31:0] win_we, output logic [255:0] win_din,
  output logic [AWORDS-1:0] win_raddr, output logic win_ren, input logic [255:0] win_dout,
  // ddr4_engine request/stream
  output logic        e_req_valid, output logic e_req_we, output logic [31:0] e_req_addr, output logic [7:0] e_req_len,
  input  logic        e_busy,
  output logic [255:0] e_wd_data, output logic e_wd_valid, input logic e_wd_ready,
  input  logic [255:0] e_rd_data, input logic e_rd_valid, output logic e_rd_ready
);
  typedef enum logic [2:0] {IDLE, GATE, RSTART, RWAIT, WLOAD, WSEND, WWAIT} st_t;
  st_t st;
  logic [31:0] total, my_w;            // total words / my progress (linear)
  logic [8:0]  chunk;                  // beats left in the current burst
  logic [AWORDS-1:0] wptr;             // window address for the current burst (wraps)
  assign my_prog = my_w;

  wire [31:0] remaining = total - my_w;
  wire [8:0]  this_len  = (remaining > 32'd256) ? 9'd256 : remaining[8:0];
  // gate: REFILL -> room to fill (don't overwrite unread); DRAIN -> data available (don't read unwritten)
  wire        room      = (DIR==0) ? ((my_w + {23'd0,this_len}) <= (peer_prog + WIN))
                                   : ((my_w + {23'd0,this_len}) <=  peer_prog);
  wire        more      = (my_w < total);

  // ---- REFILL data sink: DDR4 read beats -> window write ----
  assign win_we    = (DIR==0 && st==RWAIT && e_rd_valid) ? 32'hFFFF_FFFF : 32'd0;
  assign win_addr  = wptr;
  assign win_din   = e_rd_data;
  assign e_rd_ready= (DIR==0 && st==RWAIT);
  // ---- DRAIN data source: window read -> DDR4 write beats ----
  assign win_raddr = wptr;
  assign win_ren   = (DIR==1 && st==WLOAD);
  assign e_wd_data = win_dout;
  assign e_wd_valid= (DIR==1 && st==WSEND);

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      st<=IDLE; busy<=0; total<=0; my_w<=0; chunk<=0; wptr<=0;
      e_req_valid<=0; e_req_we<=0; e_req_addr<=0; e_req_len<=0;
    end else begin
      e_req_valid<=0;
      case (st)
        IDLE: if (start) begin total<=total_words; my_w<=0; wptr<=0; busy<=1; st<=GATE; end
        GATE: if (!more) begin busy<=0; st<=IDLE; end
              else if (room) begin
                e_req_valid<=1; e_req_we<=(DIR==1); e_req_addr<={my_w[26:0],5'd0}; e_req_len<=this_len-9'd1;
                chunk<=this_len;
                st <= (DIR==0) ? RWAIT : WLOAD;
              end
        // REFILL: DDR4 -> window
        RWAIT: if (e_rd_valid) begin
                 wptr<=wptr+1'b1; my_w<=my_w+1'b1;
                 if (chunk==9'd1) st<=GATE; else chunk<=chunk-9'd1;
               end
        // DRAIN: window -> DDR4 (2 cycles/beat: load addr, send data)
        WLOAD: st<=WSEND;
        WSEND: if (e_wd_ready) begin
                 wptr<=wptr+1'b1; my_w<=my_w+1'b1;
                 if (chunk==9'd1) st<=WWAIT; else begin chunk<=chunk-9'd1; st<=WLOAD; end
               end
        WWAIT: if (!e_busy) st<=GATE;       // burst's B/last accepted -> next gate
      endcase
    end
  end
endmodule
