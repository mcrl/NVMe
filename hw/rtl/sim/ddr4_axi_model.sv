// Behavioural DDR4 AXI slave model for sim. Backs a memory array; reproduces the two behaviours the real PL
// DDR4 showed: (1) wready is asserted ONLY while an AW is pending (gate W on a captured AW), and (2) reads come
// back after a few cycles of latency. INCR bursts, 256-bit data, single outstanding (matches ddr4_engine).
//
// SLOW>0 = ADVERSARIAL mode: random AR/AW accept delay + random read-latency + random R/W beat bubbles, so the
// streaming engines can BARELY keep up with the SSD. Without the producer/consumer interlock this provokes the
// refill underrun / drain overrun; with it, the SSD must backpressure and the data stays correct. Deterministic
// (LFSR-seeded), so the run is reproducible.
`timescale 1ns/1ps
module ddr4_axi_model #(parameter AW=14, parameter int SLOW=0) (   // 2**14 * 32 B = 512 KB sim memory
  input  logic        clk, rstn,
  input  logic [31:0] awaddr, input logic [7:0] awlen, input logic awvalid, output logic awready,
  input  logic [255:0] wdata, input logic wlast, input logic wvalid, output logic wready,
  output logic [1:0]  bresp, output logic bvalid, input logic bready,
  input  logic [31:0] araddr, input logic [7:0] arlen, input logic arvalid, output logic arready,
  output logic [255:0] rdata, output logic rlast, output logic rvalid, input logic rready, output logic [1:0] rresp
);
  logic [255:0] mem [0:(1<<AW)-1];
  assign bresp=2'b00; assign rresp=2'b00;

  // ---- deterministic pseudo-random stall source (LFSR) ----
  logic [15:0] lfsr;
  always_ff @(posedge clk or negedge rstn) if(!rstn) lfsr<=16'hACE1; else lfsr<={lfsr[14:0], lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};
  wire r_stall = (SLOW!=0) && (lfsr[2:0]!=3'd0);    // ~7/8 of cycles: hold off a read beat
  wire w_stall = (SLOW!=0) && (lfsr[5:3]!=3'd0);    // ~7/8 of cycles: hold off a write beat
  wire a_stall = (SLOW!=0) && (lfsr[7:6]!=2'd0);    // ~3/4 of cycles: hold off AR/AW accept

  // ---- write ----
  logic        aw_pend;
  logic [AW-1:0] wptr;
  assign awready = !aw_pend && !a_stall;
  assign wready  = aw_pend && !w_stall;             // W ready only with a pending AW (real-DDR4 quirk), throttled
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

  // ---- read (3-cycle address->data latency, +random in SLOW mode) ----
  logic        rd_run;
  logic [AW-1:0] rptr;
  logic [7:0]  rcnt;
  logic [3:0]  rlat;
  assign arready = !rd_run && !a_stall;
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin rd_run<=0; rvalid<=0; rlast<=0; rptr<=0; rcnt<=0; rlat<=0; rdata<=0; end
    else if (arvalid && arready) begin rd_run<=1; rptr<=araddr[AW+4:5]; rcnt<=arlen;
                                       rlat<=(SLOW!=0)?(4'd3+{1'b0,lfsr[2:0]}):4'd3; rvalid<=0; rlast<=0; end
    else if (rd_run) begin
      if (rlat != 0) rlat<=rlat-1'b1;                                   // address -> first-data latency
      else if (!rvalid) begin if (!r_stall) begin rvalid<=1; rdata<=mem[rptr]; rlast<=(rcnt==8'd0); end end // (re)present after latency/bubble
      else if (rready) begin                                            // beat consumed -> advance or finish
        if (rlast) begin rvalid<=0; rlast<=0; rd_run<=0; end
        else begin rptr<=rptr+1'b1; rcnt<=rcnt-8'd1;
          if (r_stall) rvalid<=0;                                       // SLOW: drop valid, re-present next beat later
          else begin rdata<=mem[rptr+1'b1]; rlast<=(rcnt==8'd1); end
        end
      end
    end
  end
endmodule
