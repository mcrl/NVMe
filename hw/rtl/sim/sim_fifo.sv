// Behavioral async FIFO standing in for the Xilinx FIFO IPs (iosq/asq/wraddr) during simulation.
// Matches the IP interface used by nvme_driver: srst, dual clock, din/wr_en, dout/rd_en/valid, full/empty.
// Standard FIFO read: rd_en pulse -> next rd_clk, dout = front entry and valid=1.
`timescale 1ns/1ps
module sim_fifo #(parameter WIDTH=8, parameter DEPTH=1024) (
  input  logic              srst,
  input  logic              wr_clk,
  input  logic              rd_clk,
  input  logic [WIDTH-1:0]  din,
  input  logic              wr_en,
  output logic [WIDTH-1:0]  dout,
  input  logic              rd_en,
  output logic              full,
  output logic              empty,
  output logic              valid,
  output logic              wr_rst_busy,
  output logic              rd_rst_busy
);
  localparam int AW = (DEPTH<=1) ? 1 : $clog2(DEPTH);
  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [AW:0] wp, rp;

  assign wr_rst_busy = 1'b0;
  assign rd_rst_busy = 1'b0;
  assign empty = (wp == rp);
  assign full  = (wp[AW] != rp[AW]) && (wp[AW-1:0] == rp[AW-1:0]);

  always_ff @(posedge wr_clk) begin
    if (srst) wp <= '0;
    else if (wr_en && !full) begin
      mem[wp[AW-1:0]] <= din;
      wp <= wp + 1'b1;
    end
  end

  always_ff @(posedge rd_clk) begin
    if (srst) begin
      rp    <= '0;
      valid <= 1'b0;
    end else begin
      valid <= 1'b0;
      if (rd_en && !empty) begin
        dout  <= mem[rp[AW-1:0]];
        rp    <= rp + 1'b1;
        valid <= 1'b1;
      end
    end
  end
endmodule

// Wrapper modules matching the IP instance names used in nvme_driver.sv
module iosq (input logic srst, wr_clk, rd_clk, input logic [96:0] din, input logic wr_en,
            output logic [96:0] dout, input logic rd_en, output logic full, empty, valid,
            output logic wr_rst_busy, rd_rst_busy);
  sim_fifo #(.WIDTH(97), .DEPTH(1024)) i (.*);
endmodule

module asq (input logic srst, wr_clk, rd_clk, input logic din, input logic wr_en,
           output logic dout, input logic rd_en, output logic full, empty, valid,
           output logic wr_rst_busy, rd_rst_busy);
  sim_fifo #(.WIDTH(1), .DEPTH(1024)) i (.*);
endmodule

module wraddr_fifo (input logic srst, clk, input logic [7:0] din, input logic wr_en,
                   output logic [7:0] dout, input logic rd_en, output logic full, empty, valid,
                   output logic wr_rst_busy, rd_rst_busy);
  sim_fifo #(.WIDTH(8), .DEPTH(1024)) i (.wr_clk(clk), .rd_clk(clk), .*);
endmodule
