// SRAM <-> DDR4 copy engine (ui_clk). On a `go` pulse it streams a source on-chip SRAM through the 4 GB DDR4
// and back into a destination on-chip SRAM, so host data genuinely transits the board DRAM:
//   phase 1 (PUSH): read src SRAM -> DDR4 write   (DDR4 now holds the data)
//   phase 2 (PULL): DDR4 read     -> write dst SRAM
// Splits into <=256-beat AXI bursts (AXI4 awlen limit). All ui_clk -> the dual-clock src/dst SRAMs absorb the
// host/oculink clock crossing, so no explicit AXI CDC is needed. Drives one ddr4_engine. Per-beat src read is
// 2 cycles (latency-1 SRAM); fine since the copy runs once per command and is far shorter than the SSD xfer.
module copy_engine #(parameter int AWORDS = 12)(   // 2**12 = 4096 words = 128 KB
  input  logic        clk, rstn,
  input  logic        go,                 // 1-cycle pulse
  input  logic [AWORDS:0] nwords,         // number of 256-b words to copy (from DDR4 word 0)
  output logic        busy,
  // source SRAM read port (latency-1 registered read)
  output logic [AWORDS-1:0] src_addr, output logic src_en, input logic [255:0] src_dout,
  // destination SRAM write port (full-word byte enables)
  output logic [AWORDS-1:0] dst_addr, output logic [31:0] dst_we, output logic [255:0] dst_din,
  // ddr4_engine request/stream
  output logic        e_req_valid, output logic e_req_we, output logic [31:0] e_req_addr, output logic [7:0] e_req_len,
  input  logic        e_busy,
  output logic [255:0] e_wd_data, output logic e_wd_valid, input logic e_wd_ready,
  input  logic [255:0] e_rd_data, input logic e_rd_valid, output logic e_rd_ready
);
  typedef enum logic [2:0] {IDLE, WSTART, WLOAD, WSEND, WWAIT, RSTART, RWAIT, FIN} st_t;
  st_t st;
  logic [AWORDS:0] total, done_w;            // words total / processed-so-far in current phase
  logic [8:0]      chunk;                     // beats remaining in the current burst
  logic [AWORDS-1:0] sptr, dptr;              // src / dst word pointers (= DDR4 word index)

  wire [AWORDS:0] remaining = total - done_w;
  wire [8:0]      this_len  = (remaining > {{(AWORDS-8){1'b0}},9'd256}) ? 9'd256 : remaining[8:0];

  assign src_addr = sptr;
  assign src_en   = (st==WLOAD);
  assign e_wd_data  = src_dout;
  assign e_wd_valid = (st==WSEND);
  assign e_rd_ready = (st==RWAIT);
  assign dst_addr   = dptr;
  assign dst_din    = e_rd_data;
  assign dst_we     = (st==RWAIT && e_rd_valid) ? 32'hFFFF_FFFF : 32'd0;

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      st<=IDLE; busy<=0; total<=0; done_w<=0; chunk<=0; sptr<=0; dptr<=0;
      e_req_valid<=0; e_req_we<=0; e_req_addr<=0; e_req_len<=0;
    end else begin
      e_req_valid<=0;
      case (st)
        IDLE: if (go) begin total<=nwords; done_w<=0; sptr<=0; dptr<=0; busy<=1; st<=WSTART; end
        // ---- PUSH: src SRAM -> DDR4 ----
        WSTART: begin
          e_req_valid<=1; e_req_we<=1; e_req_addr<={done_w,5'd0}; e_req_len<=this_len-9'd1;
          chunk<=this_len; st<=WLOAD;
        end
        WLOAD: st<=WSEND;                            // src_dout = src[sptr] valid next cycle
        WSEND: if (e_wd_ready) begin
                 sptr<=sptr+1'b1; done_w<=done_w+1'b1;
                 if (chunk==9'd1) st<=WWAIT; else begin chunk<=chunk-9'd1; st<=WLOAD; end
               end
        WWAIT: if (!e_busy) begin
                 if (done_w==total) begin done_w<=0; st<=RSTART; end
                 else st<=WSTART;
               end
        // ---- PULL: DDR4 -> dst SRAM ----
        RSTART: begin
          e_req_valid<=1; e_req_we<=0; e_req_addr<={done_w,5'd0}; e_req_len<=this_len-9'd1;
          chunk<=this_len; st<=RWAIT;
        end
        RWAIT: if (e_rd_valid) begin
                 dptr<=dptr+1'b1; done_w<=done_w+1'b1;
                 if (chunk==9'd1) begin
                   if ((done_w+1'b1)==total) begin busy<=0; st<=FIN; end else st<=RSTART;
                 end else chunk<=chunk-9'd1;
               end
        FIN: st<=IDLE;
      endcase
    end
  end
endmodule
