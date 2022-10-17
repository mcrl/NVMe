

module csr #(
  parameter dummy = 0
) (
  input user_clk,
  input user_reset,
  input user_lnk_up,

  output reg [255:0]  csr_ioq_data,
  output reg          csr_ioq_valid,
  input [255:0]       ioq_csr_data,
  input               ioq_csr_valid
);

`include "constants.h"

reg [9:0] t;

always@(posedge user_clk or posedge user_reset) begin
  if( user_reset ) begin
    t <= 10'd0;
  end
  else begin
    if(user_lnk_up) begin
      if(t < 10'd11) begin
        t <= t + 10'd1;
      end
    end
  end
end


reg [255:0] csr_ioq_data_q, csr_ioq_data_d;
reg         csr_ioq_valid_q, csr_ioq_valid_d;

always@(posedge user_clk or posedge user_reset) begin
  if( user_reset ) begin
    csr_ioq_data_q <= 256'h0;
    csr_ioq_valid_q <= 1'b0;
  end
  else begin
    csr_ioq_data_q <= csr_ioq_data_d;
    csr_ioq_valid_q <= csr_ioq_valid_d;
  end
end

always@(*) begin
  csr_ioq_data = csr_ioq_data_q;
  csr_ioq_valid = csr_ioq_valid_q;

  csr_ioq_data_d = csr_ioq_data_q;
  csr_ioq_valid_d = csr_ioq_valid_q;

  if(user_lnk_up) begin
    if(t==10'd2) begin
      csr_ioq_data_d = {
          35'h0,  // Not used
          6'h1,   // Tag
          11'h001,  // Dword count 
          8'h0f,  // Byte Enable (last, first)
          128'h0, // Data
          62'h0, 2'b00,   // Address 62 + 2bit
          CfgRd0         // Req Type : 4'b1000 CfgRd0
        };
      csr_ioq_valid_d = 1'b1;
    end
    else if(t==10'd4) begin
      csr_ioq_data_d = {
        35'h0,  // Not used
        6'h2,   // Tag
        11'h000,  // Dword count
        8'h0f,  // Byte Enable (last, first)
        128'h0, // Data
        62'h1, 2'b00,   // RegNum 62 + 2bit
        CfgRd1
      };
      csr_ioq_valid_d = 1'b1;
    end
    else if(t==10'd6) begin
      csr_ioq_data_d = {
        35'h0,  // Not used
        6'h3,   // Tag
        11'h001,  // Dword count
        8'h0f,  // Byte Enable (last, first)
        128'h0, // Data
        62'h10, 2'b00,   // Address 62 + 2bit
        MemRd
      };
      csr_ioq_valid_d = 1'b1;
    end
    else if(t==10'd8) begin
      csr_ioq_data_d <= {
        35'h0,  // Not used
        6'h4,   // Tag
        11'h001,  // Dword count
        8'h0f,  // Byte Enable (last, first)
        96'h0, 32'h1234_5678, // Data
        62'h10, 2'b00,   // Address 62 + 2bit
        MemWr
      };
      csr_ioq_valid_d = 1'b1;
    end
    else if(t==10'd10) begin
      csr_ioq_data_d = {
        35'h0,  // Not used
        6'h5,   // Tag
        11'h001,  // Dword count
        8'h0f,  // Byte Enable (last, first)
        128'h0, // Data
        62'h10, 2'b00,   // Address 62 + 2bit
        MemRd
      };
      csr_ioq_valid_d = 1'b1;
    end
    else begin
      csr_ioq_data_d = 256'h0;
      csr_ioq_valid_d = 1'b0;
    end
  end
end


endmodule