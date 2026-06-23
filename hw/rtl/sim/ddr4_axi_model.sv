// Behavioural DDR4 AXI slave model for sim. Backs a memory array; reproduces the two behaviours the real PL
// DDR4 showed: (1) wready is asserted ONLY while an AW is pending (gate W on a captured AW), and (2) reads come
// back after a few cycles of latency. INCR bursts, 256-bit data, single outstanding (matches ddr4_engine).
`timescale 1ns/1ps
module ddr4_axi_model #(parameter AW=14) (   // 2**14 * 32 B = 512 KB sim memory
  input  logic        clk, rstn,
  input  logic [31:0] awaddr, input logic [7:0] awlen, input logic awvalid, output logic awready,
  input  logic [255:0] wdata, input logic wlast, input logic wvalid, output logic wready,
  output logic [1:0]  bresp, output logic bvalid, input logic bready,
  input  logic [31:0] araddr, input logic [7:0] arlen, input logic arvalid, output logic arready,
  output logic [255:0] rdata, output logic rlast, output logic rvalid, input logic rready, output logic [1:0] rresp
);
  logic [255:0] mem [0:(1<<AW)-1];
  assign bresp=2'b00; assign rresp=2'b00;

  // ---- write ----
  logic        aw_pend;
  logic [AW-1:0] wptr;
  assign awready = !aw_pend;
  assign wready  = aw_pend;              // <-- W only ready with a pending AW (the real-DDR4 quirk)
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin aw_pend<=0; wptr<=0; bvalid<=0; end
    else begin
      if (bvalid && bready) bvalid<=0;
      if (awvalid && awready) begin aw_pend<=1; wptr<=awaddr[AW+4:5]; end
      if (wvalid && wready) begin
        mem[wptr] <= wdata; wptr<=wptr+1'b1;
        if (wlast) begin aw_pend<=0; bvalid<=1; end
      end
    end
  end

  // ---- read (3-cycle address->data latency) ----
  logic        rd_run;
  logic [AW-1:0] rptr;
  logic [7:0]  rcnt;
  logic [2:0]  rlat;
  assign arready = !rd_run;
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin rd_run<=0; rvalid<=0; rlast<=0; rptr<=0; rcnt<=0; rlat<=0; rdata<=0; end
    else if (arvalid && arready) begin rd_run<=1; rptr<=araddr[AW+4:5]; rcnt<=arlen; rlat<=3'd3; rvalid<=0; rlast<=0; end
    else if (rd_run) begin
      if (rlat != 0) rlat<=rlat-1'b1;                       // address -> first-data latency
      else if (!rvalid) begin rvalid<=1; rdata<=mem[rptr]; rlast<=(rcnt==8'd0); end   // first beat
      else if (rready) begin                                 // beat consumed -> advance or finish
        if (rlast) begin rvalid<=0; rlast<=0; rd_run<=0; end
        else begin rptr<=rptr+1'b1; rcnt<=rcnt-8'd1; rdata<=mem[rptr+1'b1]; rlast<=(rcnt==8'd1); end
      end
    end
  end
endmodule
