// First-word-fall-through (FWFT) single-clock tag FIFO.
//   head is combinationally valid whenever !empty (unlike the standard-read sim_fifo).
//   Used to record the in-order class of each accepted m_axi AR / AW so the R / B channel
//   muxes can serve the OLDEST outstanding transaction (the only legal single-ID schedule).
// Small + synthesizable (distributed RAM): WIDTH x DEPTH bits, async head read.
`timescale 1ns/1ps
module tagfifo #(
  parameter int WIDTH = 9,
  parameter int DEPTH = 256
)(
  input  logic              clk,
  input  logic              srst,        // synchronous, active high (= !rstn)
  input  logic              push,
  input  logic [WIDTH-1:0]  din,
  input  logic              pop,
  output logic [WIDTH-1:0]  head,         // front entry; valid when !empty
  output logic [WIDTH-1:0]  head2,                // 2nd entry (behind head); valid when cnt >= 2
  output logic [$clog2(DEPTH):0] cnt,             // occupancy (0..DEPTH); lets a consumer peek ahead
  output logic              empty,
  output logic              full
);
  localparam int AW = $clog2(DEPTH);
  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [AW:0]      wptr, rptr;           // one extra MSB to distinguish full from empty

  assign empty = (wptr == rptr);
  assign full  = (wptr[AW] != rptr[AW]) && (wptr[AW-1:0] == rptr[AW-1:0]);
  assign head  = mem[rptr[AW-1:0]];
  assign head2 = mem[(rptr[AW-1:0] + 1'b1)];   // entry right behind head (back-to-back lookahead)
  assign cnt   = wptr - rptr;

  always_ff @(posedge clk) begin
    if (srst) begin
      wptr <= '0;
      rptr <= '0;
    end
    else begin
      if (push && !full)  begin mem[wptr[AW-1:0]] <= din; wptr <= wptr + 1'b1; end
      if (pop  && !empty) rptr <= rptr + 1'b1;
    end
  end
endmodule
