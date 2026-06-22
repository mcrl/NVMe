// Autonomous NVMe bring-up sequencer.
//
// Replays, IN HARDWARE, the exact host bring-up sequence that nvme_bw_bench.c / driver_test.c do by hand
// (~20 CSR pokes): PCIe enumeration (root bus + SSD command/BAR), NVMe controller init (CC.EN, AQA, ASQ/ACQ,
// CSTS.RDY poll), then IOCQ/IOSQ create. After a single host trigger (`start`), the host only has to wait for
// `ready` and then issue reads/writes -- the FPGA builds the queues itself.
//
// Lives in the host_bram_clk domain and drives the SAME signals the host CSR drives (cfg_write/cfg_read +
// addr/data, send_iocq/iosq, cfg_done), so the existing config-access (nvme_configurator) and admin
// (nvme_driver) paths and their CDCs are reused unchanged. The few status signals it consumes from the
// oculink domain (cfg_wr_done/cfg_rd_done/cfg_rddata/cpl_count) are 2-FF synchronized here; cfg_rddata is a
// multi-cycle path sampled only after its (synchronized) done flag, and cpl_count changes far slower
// (~us/command) than this clock so a plain 2-FF sync on its low byte is safe for "did it increment".
//
// NOTE: MPS/MRRS tuning (256 B) is intentionally NOT in this v1 microcode -- bring-up creates working IO
// queues at the 128 B default; the host can still bump MPS via the existing path, or it can be added as four
// extra microcode steps (read-modify-write DevControl 0x78 on root + SSD). Flip `start` to auto-on-link-up
// once HW-verified by gating it with `oculink_lnk_up` instead of the CSR trigger.
`timescale 1ns/1ps
module nvme_bringup (
  input  logic        host_bram_clk,
  input  logic        rstn,
  input  logic        start,            // 1-shot host trigger (CSR)
  output logic        busy,             // high while sequencing (mux-select for cfg/admin paths)
  output logic        ready,            // bring-up complete, IO queues created

  // driven onto the config-access path (muxed with the host CSR in kernel.sv)
  output logic        bu_cfg_write,
  output logic        bu_cfg_read,
  output logic [31:0] bu_cfg_wraddr,
  output logic [31:0] bu_cfg_wrdata,
  output logic [31:0] bu_cfg_rdaddr,
  output logic        bu_cfg_done,      // the 0x30 bridge-enable / cfg_done level
  // driven onto the admin-command path
  output logic        bu_send_iocq,
  output logic        bu_send_iosq,

  // status read back from the oculink domain (synchronized internally)
  input  logic        cfg_wr_done,
  input  logic        cfg_rd_done,
  input  logic [31:0] cfg_rddata,
  input  logic [31:0] cpl_count
);
  // ---- address encodings (match the host tools) ----
  localparam logic [31:0] EP   = 32'h0010_0000;  // (1<<20) = SSD endpoint config select
  localparam logic [31:0] MEM  = 32'h8000_0000;  // bit31 = memory access (to the SSD BAR)
  localparam logic [31:0] NVME = 32'h0000_4000;  // SSD BAR0 base (NVMe register block)

  // ---- microcode ops ----
  localparam OP_W   = 4'd0;   // config/mem write  (addr,data)
  localparam OP_P0  = 4'd1;   // read addr, loop until bit0==0  (CSTS.RDY)
  localparam OP_P1  = 4'd2;   // read addr, loop until bit0==1
  localparam OP_DB0 = 4'd3;   // cfg_done <= 0
  localparam OP_DB1 = 4'd4;   // cfg_done <= 1
  localparam OP_CQ  = 4'd5;   // pulse send_iocq, wait one completion
  localparam OP_SQ  = 4'd6;   // pulse send_iosq, wait one completion
  localparam OP_END = 4'd7;
  localparam OP_DCR = 4'd8;   // read DevControl(addr) into dc_reg
  localparam OP_DCW = 4'd9;   // write (dc_reg with MPS=256,MRRS=256) to addr
  // PCIe DevControl: MPS=bits[7:5], MRRS=bits[14:12]; set both to code 1 (=256 B). Without this the I/O data
  // phase fails on a freshly-programmed card (matches the host bringup()'s MPS/MRRS tuning).
  localparam logic [31:0] MPSMASK = (32'h7<<5) | (32'h7<<12);
  localparam logic [31:0] MPSBITS = (32'h1<<5) | (32'h1<<12);

  localparam int NSTEP = 25;
  // microcode ROM: replays nvme_bw_bench.c bringup() (sans the FPGA sw_reset, which precedes `start`)
  function automatic void ucode(input int pc, output logic [3:0] op,
                                output logic [31:0] addr, output logic [31:0] data);
    op='x; addr='0; data='0;
    case (pc)
      0:  op=OP_DB0;                                              // wr(0x30,0)
      1:  begin op=OP_W; addr=32'h0000_0018; data=32'h0000_0100; end  // root secondary bus
      2:  begin op=OP_W; addr=EP|32'h04;     data=32'h0000_0006; end  // SSD cmd: mem space + bus master
      3:  begin op=OP_W; addr=EP|32'h10;     data=32'h0000_4000; end  // SSD BAR0
      4:  begin op=OP_W; addr=EP|32'h14;     data=32'h0000_0000; end  // SSD BAR1
      5:  begin op=OP_DCR; addr=32'h0000_0078;                   end   // root DevControl read
      6:  begin op=OP_DCW; addr=32'h0000_0078;                   end   // root MPS/MRRS=256
      7:  begin op=OP_DCR; addr=EP|32'h78;                       end   // SSD DevControl read
      8:  begin op=OP_DCW; addr=EP|32'h78;                       end   // SSD MPS/MRRS=256
      9:  begin op=OP_W; addr=32'h0000_0148; data=32'h0000_0001; end  // bridge enable bit
      10: op=OP_DB1;                                             // wr(0x30,1)
      11: op=OP_DB0;                                             // wr(0x30,0)
      12: begin op=OP_W; addr=MEM|NVME|32'h14; data=32'h0000_0000; end // CC.EN=0
      13: begin op=OP_P0; addr=MEM|NVME|32'h1C;                 end   // wait CSTS.RDY=0
      14: begin op=OP_W; addr=MEM|NVME|32'h24; data=32'h0040_0040; end // AQA (depth 64/64)
      15: begin op=OP_W; addr=MEM|NVME|32'h28; data=32'h0000_8000; end // ASQ base
      16: begin op=OP_W; addr=MEM|NVME|32'h2C; data=32'h0000_0000; end // ASQ base high
      17: begin op=OP_W; addr=MEM|NVME|32'h30; data=32'h0000_9000; end // ACQ base
      18: begin op=OP_W; addr=MEM|NVME|32'h34; data=32'h0000_0000; end // ACQ base high
      19: begin op=OP_W; addr=MEM|NVME|32'h14; data=32'h0000_0001; end // CC.EN=1
      20: begin op=OP_P1; addr=MEM|NVME|32'h1C;                 end   // wait CSTS.RDY=1
      21: op=OP_DB1;                                             // wr(0x30,1)
      22: op=OP_CQ;                                              // IOCQ create
      23: op=OP_SQ;                                              // IOSQ create
      24: op=OP_END;
      default: op=OP_END;
    endcase
  endfunction

  // ---- 2-FF synchronizers from the oculink domain ----
  logic wrdone_m, wrdone_s, rddone_m, rddone_s;
  logic [7:0] cplcnt_m, cplcnt_s;
  always_ff @(posedge host_bram_clk or negedge rstn) begin
    if (!rstn) begin wrdone_m<=0; wrdone_s<=0; rddone_m<=0; rddone_s<=0; cplcnt_m<=0; cplcnt_s<=0; end
    else begin
      wrdone_m<=cfg_wr_done; wrdone_s<=wrdone_m;
      rddone_m<=cfg_rd_done; rddone_s<=rddone_m;
      cplcnt_m<=cpl_count[7:0]; cplcnt_s<=cplcnt_m;
    end
  end

  // ---- sequencer FSM (host_bram_clk) ----
  localparam S_IDLE=4'd0, S_FETCH=4'd1, S_WR0=4'd2, S_WR1=4'd3, S_RD0=4'd4, S_RD1=4'd5, S_CPL=4'd6, S_DONE=4'd7;
  logic [3:0]  st;
  logic [7:0]  pc;
  logic [3:0]  op;
  logic [31:0] addr, data;
  logic [7:0]  cpl_at;        // cpl_count low byte captured at admin trigger
  logic [31:0] dc_reg;        // captured DevControl for the MPS/MRRS read-modify-write

  always_comb ucode(pc, op, addr, data);   // combinational microcode decode of current pc

  always_ff @(posedge host_bram_clk or negedge rstn) begin
    if (!rstn) begin
      st<=S_IDLE; pc<=0; busy<=0; ready<=0;
      bu_cfg_write<=0; bu_cfg_read<=0; bu_cfg_wraddr<=0; bu_cfg_wrdata<=0; bu_cfg_rdaddr<=0;
      bu_cfg_done<=0; bu_send_iocq<=0; bu_send_iosq<=0; cpl_at<=0; dc_reg<=0;
    end else begin
      // default: deassert 1-cycle pulses
      bu_cfg_write<=0; bu_cfg_read<=0; bu_send_iocq<=0; bu_send_iosq<=0;
      case (st)
        S_IDLE: begin
          if (start) begin busy<=1; ready<=0; pc<=0; st<=S_FETCH; end
        end
        S_FETCH: begin
          case (op)
            OP_W:   begin bu_cfg_wraddr<=addr; bu_cfg_wrdata<=data; bu_cfg_write<=1; st<=S_WR0; end
            OP_P0,
            OP_P1:  begin bu_cfg_rdaddr<=addr; bu_cfg_read<=1; st<=S_RD0; end
            OP_DCR: begin bu_cfg_rdaddr<=addr; bu_cfg_read<=1; st<=S_RD0; end
            OP_DCW: begin bu_cfg_wraddr<=addr; bu_cfg_wrdata<=(dc_reg & ~MPSMASK) | MPSBITS; bu_cfg_write<=1; st<=S_WR0; end
            OP_DB0: begin bu_cfg_done<=0; pc<=pc+1; end
            OP_DB1: begin bu_cfg_done<=1; pc<=pc+1; end
            OP_CQ:  begin cpl_at<=cplcnt_s; bu_send_iocq<=1; st<=S_CPL; end
            OP_SQ:  begin cpl_at<=cplcnt_s; bu_send_iosq<=1; st<=S_CPL; end
            default: st<=S_DONE;   // OP_END
          endcase
        end
        // config/mem write: wait done deassert (write accepted) then assert (complete)
        S_WR0: if (!wrdone_s) st<=S_WR1;
        S_WR1: if ( wrdone_s) begin pc<=pc+1; st<=S_FETCH; end
        // read: same handshake; then test the poll condition (loop on same pc until satisfied)
        S_RD0: if (!rddone_s) st<=S_RD1;
        S_RD1: if ( rddone_s) begin
                 if (op==OP_DCR)
                   begin dc_reg <= cfg_rddata; pc<=pc+1; st<=S_FETCH; end   // capture DevControl for RMW
                 else if ((op==OP_P0 &&  cfg_rddata[0]==1'b0) || (op==OP_P1 && cfg_rddata[0]==1'b1))
                   begin pc<=pc+1; st<=S_FETCH; end     // poll condition met -> next step
                 else
                   st<=S_FETCH;                          // not yet -> re-issue same read (pc unchanged)
               end
        // admin trigger: wait for one new completion (cpl_count low byte changed)
        S_CPL: if (cplcnt_s != cpl_at) begin pc<=pc+1; st<=S_FETCH; end
        S_DONE: begin busy<=0; ready<=1; st<=S_IDLE; end
        default: st<=S_IDLE;
      endcase
    end
  end
endmodule
