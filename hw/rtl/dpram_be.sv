// Simple dual-port RAM with independent clocks + byte write-enables, used for the large host<->SSD data
// buffers (wbuf/rbuf). One write port (A) and one read port (B); A and B may run on different clocks.
//
// Synthesis  : maps to xpm_memory_sdpram (MEMORY_PRIMITIVE selectable: "block" BRAM or "ultra" URAM).
// Simulation : a behavioural array with a matching READ_LATENCY pipeline (define SIM_BEHAV at compile),
//              so the read-latency-aware reader FSM is exercised the same way it is in hardware.
//
// READ_LATENCY = clocks from a port-B read (addrb sampled with enb) to doutb valid.
module dpram_be #(
  parameter int DW       = 256,        // data width (bits)
  parameter int AW       = 12,         // address width  (depth = 2**AW words)
  parameter int RDLAT    = 1,          // port-B read latency (1 for BRAM, >=2 typical for URAM)
  parameter     PRIM     = "block"     // "block" (BRAM) or "ultra" (URAM)
)(
  input  logic            clka,
  input  logic            ena,
  input  logic [DW/8-1:0] wea,         // byte write-enables
  input  logic [AW-1:0]   addra,
  input  logic [DW-1:0]   dina,
  input  logic            clkb,
  input  logic            enb,
  input  logic [AW-1:0]   addrb,
  output logic [DW-1:0]   doutb
);
`ifdef SIM_BEHAV
  // -------- behavioural model (xsim) --------
  logic [DW-1:0] mem [0:(1<<AW)-1];
  always_ff @(posedge clka)
    if (ena)
      for (int i = 0; i < DW/8; i++)
        if (wea[i]) mem[addra][i*8 +: 8] <= dina[i*8 +: 8];

  logic [DW-1:0] rpipe [0:RDLAT-1];
  always_ff @(posedge clkb) if (enb) begin
    rpipe[0] <= mem[addrb];
    for (int i = 1; i < RDLAT; i++) rpipe[i] <= rpipe[i-1];
  end
  assign doutb = rpipe[RDLAT-1];
`else
  // -------- hardware (xpm_memory_sdpram) --------
  xpm_memory_sdpram #(
    .ADDR_WIDTH_A        (AW),
    .ADDR_WIDTH_B        (AW),
    .AUTO_SLEEP_TIME     (0),
    .BYTE_WRITE_WIDTH_A  (8),
    .CLOCKING_MODE       ("independent_clock"),
    .MEMORY_PRIMITIVE    (PRIM),
    .MEMORY_SIZE         (DW * (1<<AW)),
    .READ_DATA_WIDTH_B   (DW),
    .READ_LATENCY_B      (RDLAT),
    .WRITE_DATA_WIDTH_A  (DW),
    .WRITE_MODE_B        ("read_first")
  ) u_xpm (
    .clka   (clka),  .ena (ena),  .wea (wea),  .addra (addra), .dina (dina),
    .clkb   (clkb),  .enb (enb),  .addrb (addrb), .doutb (doutb),
    .dbiterrb (), .sbiterrb (),
    .injectdbiterra (1'b0), .injectsbiterra (1'b0),
    .regceb (1'b1), .rstb (1'b0), .sleep (1'b0)
  );
`endif
endmodule
