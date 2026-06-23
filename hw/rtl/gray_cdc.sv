// Cross a MONOTONE (increment-only, <=1 per clk_in cycle) binary counter from clk_in to clk_out via Gray code:
// b->gray (clk_in reg) -> 2-FF ASYNC_REG sync -> gray->b (clk_out). A metastable sample yields only the old or
// new value (one Gray bit changes per increment), never a corrupt midpoint -- so the consumer sees a value that
// is at worst slightly STALE, which the flow-control gates treat as safe-by-direction.
module gray_cdc #(parameter int W=32) (
  input  logic         clk_in,
  input  logic [W-1:0] bin_in,
  input  logic         clk_out,
  output logic [W-1:0] bin_out
);
  function automatic logic [W-1:0] b2g(input logic [W-1:0] b); return b ^ (b >> 1); endfunction
  function automatic logic [W-1:0] g2b(input logic [W-1:0] g);
    logic [W-1:0] b; b[W-1] = g[W-1];
    for (int i = W-2; i >= 0; i--) b[i] = b[i+1] ^ g[i];
    return b;
  endfunction
  logic [W-1:0] g_in;
  (* ASYNC_REG="true" *) logic [W-1:0] g_s1, g_s2;
  always_ff @(posedge clk_in)  g_in <= b2g(bin_in);
  always_ff @(posedge clk_out) begin g_s1 <= g_in; g_s2 <= g_s1; end
  assign bin_out = g2b(g_s2);
endmodule
