//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : UltraScale+ FPGA PCI Express v4.0 Integrated Block
// File       : pio_ep_mem_access.v
// Version    : 1.3 
//-----------------------------------------------------------------------------
//
// Description: Endpoint Memory Access Unit. This module provides access functions
//              to the Endpoint memory aperture.
//
//              Read Access: Module returns data for the specifed address and
//              byte enables selected.
//
//              Write Access: Module accepts data, byte enables and updates
//              data when write enable is asserted. Modules signals write busy
//              when data write is in progress.
//
//--------------------------------------------------------------------------------

`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module pio_ep_mem_access #(

  parameter TCQ = 1,
  parameter C_DATA_WIDTH = 256, 
  parameter ADDR_W = 6,
  parameter MEM_W  = 256, 
  parameter BYTE_EN_W = 32

  )(

  input            user_clk,
  input            reset_n,

  //  Read Port
   input      [ADDR_W-1:0]    rd_addr,
   input      [3:0]     rd_be,
   input                rd_en, 
   input                trn_sent,
   output     [MEM_W-1:0]   rd_data,
  //  Write Port

  input      [10:0]    wr_addr,
  input      [7:0]     wr_be,
  input      [MEM_W-1:0]   wr_data,
  input                wr_en,
  output               wr_busy,

  // Payload info
  input             [10:0]   payload_len,        // added for DWORD > 4
  input             sop,
  input             eop,  
  input              [BYTE_EN_W-1:0] data_be,  
  // Trigger to TX and Interrupt Handler Block to generate
  // Transactions and Interrupts

  output reg           gen_transaction,
  output reg           gen_leg_intr,
  output reg           gen_msi_intr,
  output reg           gen_msix_intr

  );
  
  localparam PIO_MRD_TR_GEN_REG = 11'h3AA;
  localparam PIO_INTR_GEN_REG   = 11'h3BB;
  
// State machine for write data formation to memory based on the C_DATA_WIDTH 
 reg [3*C_DATA_WIDTH-1:0] wr_data_reg0;
 reg [ADDR_W-1:0] wr_addr_pntr;  
 reg [3:0] wr_pntr_512;
 reg [2:0] wr_pntr_256;
 reg [1:0] wr_pntr_128; 
 reg wr_pntr_64;  
 reg [10:0] len_rem; 
 reg wr_den;
 reg wr_data_state;
 reg [3*BYTE_EN_W-1:0] wr_mem_be; 
 wire [MEM_W-1:0] douta; 
 wire [MEM_W-1:0] wr_data_mem; 
 assign wr_data_mem = wr_data_reg0[MEM_W-1:0];  
 localparam WRITE_DATA_RST = 0;
 localparam WRITE_DATA_WAIT = 1;  
 
 reg sop_q; 
 reg sop_qq; 
 
 always @(posedge user_clk or negedge reset_n) 
 begin 
    if (!reset_n) begin 
     sop_q <= 1'b0; 
	 sop_qq <= 1'b0; 
    end
    else begin 
     sop_q <= sop; 
	 sop_qq <= sop_q; 
    end
 end
 
generate

if (C_DATA_WIDTH == 64) begin : pio_ep_mem_access_64 
  always @(posedge user_clk or negedge reset_n) begin  
   if (!reset_n) begin 
     wr_data_reg0    <= #TCQ 192'b0; 
     wr_pntr_64      <= #TCQ 1'b0; 
     len_rem         <= #TCQ 11'b0; 
     wr_den          <= #TCQ 1'b0;
     wr_mem_be       <= #TCQ 24'b0;
     wr_data_state   <= #TCQ WRITE_DATA_RST;  
   end
   else begin
     case (wr_data_state)
        WRITE_DATA_RST : begin 
                          if (wr_en & sop_qq) begin 
          			        case (wr_addr[0]) 
                			      1'b0  : begin wr_data_reg0 [127:64]   <= #TCQ wr_data[63:0]; wr_mem_be[15:8] <= #TCQ data_be[7:0]; wr_pntr_64 <= #TCQ 1'b0; end
                			      1'b1  : begin wr_data_reg0 [159:96]   <= #TCQ wr_data[63:0]; wr_mem_be[19:12] <= #TCQ data_be[7:0]; wr_pntr_64 <= #TCQ 1'b1; end
          			        endcase
                                
                            if (payload_len <= 2) begin 
                                len_rem <= #TCQ 11'b0;    
                            end
                            else begin
                                len_rem <= #TCQ payload_len - 2;  
                            end
                                wr_data_state <= #TCQ WRITE_DATA_WAIT; 
                            end   //if
                             
						  else begin 
                            wr_data_state <= #TCQ WRITE_DATA_RST; 
                            wr_den        <= #TCQ 1'b0;
                          end
                                                  
                        end // WRITE_DATA_RST
        WRITE_DATA_WAIT : begin
                              wr_den <= 1'b1; // debugging 
                              if (len_rem == 0) begin
                                  wr_data_reg0 <= #TCQ {64'b0, wr_data_reg0[191:64]}; 
                                  wr_mem_be    <= #TCQ {8'b0, wr_mem_be[23:8]}; 
                                  case (wr_pntr_64)
                                    1'b0      : begin wr_data_state <= #TCQ WRITE_DATA_RST; end 
                                    1'b1      : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                                  endcase
                                  wr_pntr_64 <= #TCQ 1'b0; 
                              end  //if end  
                              else begin
                                  case (wr_pntr_64)  
                                    1'b0      : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[127:64]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[15:8]}; wr_pntr_64 <= #TCQ 1'b0; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                		            1'b1      : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[159:64]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[19:8]}; wr_pntr_64 <= #TCQ 1'b1; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                                  endcase
                                   if ((len_rem-1)/2 == 0) begin // if len remaining is less than 2 
                                      len_rem <=  #TCQ 11'b0; 
                                   end
                                   else begin
                                      len_rem <= #TCQ len_rem - 2; 
                                   end
                              end //else end
                          end //WRITE_DATA_WAIT       
          endcase //WRITE DATA STATE MACHINE END
          //end
          
   end// else end 
 end // always block end

// address decoder block 

 always @(posedge user_clk or negedge reset_n)
 begin
     if (!reset_n) begin 
         wr_addr_pntr <= #TCQ 8'b0;
     end
     else begin 
            if (wr_den) 
                wr_addr_pntr <=  #TCQ wr_addr_pntr + 1; 
            else
                wr_addr_pntr <= #TCQ wr_addr [8:1]; 
     end      
 end

end

else if (C_DATA_WIDTH == 128) begin : pio_ep_mem_access_128
always @(posedge user_clk or negedge reset_n) begin  
   if (!reset_n) begin 
     wr_data_reg0    <= #TCQ 384'b0; 
     wr_pntr_128      <= #TCQ 2'b0; 
     len_rem         <= #TCQ 11'b0; 
     wr_den          <= #TCQ 1'b0;
     wr_mem_be       <= #TCQ 48'b0;
     wr_data_state   <= #TCQ WRITE_DATA_RST;  
   end
   else begin
     case (wr_data_state)
        WRITE_DATA_RST : begin 
                          if (wr_en & sop_q) begin 
          			        case (wr_addr[1:0]) 
                			      2'b00  : begin wr_data_reg0 [255:128]   <= #TCQ wr_data[127:0]; wr_mem_be[31:16]  <= #TCQ data_be[15:0]; wr_pntr_128 <= #TCQ 2'b00; end
                			      2'b01  : begin wr_data_reg0 [287:160]   <= #TCQ wr_data[127:0]; wr_mem_be[35:20] <= #TCQ data_be[15:0]; wr_pntr_128 <= #TCQ 2'b01; end
				              2'b10  : begin wr_data_reg0 [319:192]   <= #TCQ wr_data[127:0]; wr_mem_be[39:24] <= #TCQ data_be[15:0]; wr_pntr_128 <= #TCQ 2'b10; end
				              2'b11  : begin wr_data_reg0 [351:224]   <= #TCQ wr_data[127:0]; wr_mem_be[43:28] <= #TCQ data_be[15:0]; wr_pntr_128 <= #TCQ 2'b11; end
          			        endcase
                                
                            if (payload_len <= 4) begin 
                                len_rem <= #TCQ 11'b0;    
                            end
                            else begin
                                len_rem <= #TCQ payload_len - 4;  
                            end
                                wr_data_state <= #TCQ WRITE_DATA_WAIT; 
                            end   //if
						  else begin 
                            wr_data_state <= #TCQ WRITE_DATA_RST; 
                            wr_den        <= #TCQ 1'b0;
                          end
                                                  
                        end // WRITE_DATA_RST
        WRITE_DATA_WAIT : begin
                              wr_den <= 1'b1; // debugging 
                              if (len_rem == 0) begin
                                  wr_data_reg0 <= #TCQ {128'b0, wr_data_reg0[383:128]}; 
                                  wr_mem_be    <= #TCQ {16'b0, wr_mem_be[47:16]}; 
                                  case (wr_pntr_128)
                                    2'b00      : begin wr_data_state <= #TCQ WRITE_DATA_RST; end 
                                    2'b01      : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									2'b10      : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									2'b11      : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                                  endcase
                                  wr_pntr_128 <= #TCQ 2'b00; 
                              end  //if end  
                              else begin
                                  case (wr_pntr_128)  
                                    2'b00     : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[255:128]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[31:16]}; wr_pntr_128 <= #TCQ 2'b00; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                		            2'b01     : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[287:128]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[35:16]}; wr_pntr_128 <= #TCQ 2'b01; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									2'b10     : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[319:128]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[39:16]}; wr_pntr_128 <= #TCQ 2'b10; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                		            2'b11     : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[351:128]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[43:16]}; wr_pntr_128 <= #TCQ 2'b11; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                                  endcase
                                   if ((len_rem-1)/4 == 0) begin // if len remaining is less than 4 
                                      len_rem <=  #TCQ 11'b0; 
                                   end
                                   else begin
                                      len_rem <= #TCQ len_rem - 4; 
                                   end
                              end //else end
                          end //WRITE_DATA_WAIT       
          endcase //WRITE DATA STATE MACHINE END
          //end
          
   end// else end 
 end // always block end

// address decoder block 

 always @(posedge user_clk or negedge reset_n)
 begin
     if (!reset_n) begin 
         wr_addr_pntr <= #TCQ 7'b0;
     end
     else begin 
            if (wr_den) 
                wr_addr_pntr <=  #TCQ wr_addr_pntr + 1; 
            else
                wr_addr_pntr <= #TCQ wr_addr [8:2]; 
     end      
 end

end   // pio_ep_mem_access_128 end


else if (C_DATA_WIDTH == 256) begin : pio_ep_mem_access_256

always @(posedge user_clk or negedge reset_n) begin  
   if (!reset_n) begin 
     wr_data_reg0 <= #TCQ 768'b0; 
     wr_pntr_256      <= #TCQ 3'b0; 
     len_rem      <= #TCQ 11'b0; 
     wr_den        <= #TCQ 1'b0;
     wr_mem_be     <= #TCQ 96'b0;
     wr_data_state <= #TCQ WRITE_DATA_RST;  
   end
   else begin
    //if (wr_en) begin 
    case (wr_data_state)
        WRITE_DATA_RST : begin 
                          if (wr_en & sop) begin 
          			case (wr_addr[2:0]) 
                			3'b000  : begin wr_data_reg0 [383:256]   <= #TCQ wr_data[127:0]; wr_mem_be[47:32] <= #TCQ data_be[15:0]; wr_pntr_256 <= #TCQ 3'b000; end
                			3'b001  : begin wr_data_reg0 [415:288]   <= #TCQ wr_data[127:0]; wr_mem_be[51:36] <= #TCQ data_be[15:0]; wr_pntr_256 <= #TCQ 3'b001; end
           	     			3'b010  : begin wr_data_reg0 [447:320]   <= #TCQ wr_data[127:0]; wr_mem_be[55:40] <= #TCQ data_be[15:0]; wr_pntr_256 <= #TCQ 3'b010; end
                			3'b011  : begin wr_data_reg0 [479:352]   <= #TCQ wr_data[127:0]; wr_mem_be[59:44] <= #TCQ data_be[15:0]; wr_pntr_256 <= #TCQ 3'b011; end
                			3'b100  : begin wr_data_reg0 [511:384]   <= #TCQ wr_data[127:0]; wr_mem_be[63:48] <= #TCQ data_be[15:0]; wr_pntr_256 <= #TCQ 3'b100; end
                			3'b101  : begin wr_data_reg0 [543:416]   <= #TCQ wr_data[127:0]; wr_mem_be[67:52] <= #TCQ data_be[15:0]; wr_pntr_256 <= #TCQ 3'b101; end
                			3'b110  : begin wr_data_reg0 [575:448]   <= #TCQ wr_data[127:0]; wr_mem_be[71:56] <= #TCQ data_be[15:0]; wr_pntr_256 <= #TCQ 3'b110; end
                			3'b111  : begin wr_data_reg0 [607:480]   <= #TCQ wr_data[127:0]; wr_mem_be[75:60] <= #TCQ data_be[15:0]; wr_pntr_256 <= #TCQ 3'b111; end
          			endcase
                                
                                if (payload_len <= 4) begin 
                                    len_rem <= #TCQ 11'b0;    
                                end
                                else begin
                                    len_rem <= #TCQ payload_len - 4;  
                                end
                                wr_data_state <= #TCQ WRITE_DATA_WAIT; 
                             end   //if
                             else begin 
                                wr_data_state <= #TCQ WRITE_DATA_RST; 
                                wr_den            <= #TCQ 1'b0;
                             end
                                                  
                        end // WRITE_DATA_RST
        WRITE_DATA_WAIT : begin
                              wr_den <= 1'b1; // debugging 
                              if (len_rem == 0) begin
                                  wr_data_reg0 <= #TCQ {256'b0, wr_data_reg0[767:256]}; 
                                  wr_mem_be    <= #TCQ {32'b0, wr_mem_be[95:32]}; 
                                  case (wr_pntr_256)
                                      3'b000    : begin /*wr_den <= #TCQ 1'b1;*/ wr_data_state <= #TCQ WRITE_DATA_RST;  end 
                                      3'b001    : begin /*wr_den <= #TCQ 1'b1;*/ wr_data_state <= #TCQ WRITE_DATA_RST; end
                                      3'b010    : begin /*wr_den <= #TCQ 1'b1;*/ wr_data_state <= #TCQ WRITE_DATA_RST; end                                       
                                      3'b011    : begin /*wr_den <= #TCQ 1'b1;*/ wr_data_state <= #TCQ WRITE_DATA_RST; end   
                                      3'b100    : begin /*wr_den <= #TCQ 1'b1;*/ wr_data_state <= #TCQ WRITE_DATA_RST; end   
                                      3'b101    : begin /*wr_den <= #TCQ 1'b1;*/ wr_data_state <= #TCQ WRITE_DATA_WAIT; end   
                                      3'b110    : begin /*wr_den <= #TCQ 1'b1;*/ wr_data_state <= #TCQ WRITE_DATA_WAIT; end   
                                      3'b111    : begin /*wr_den <= #TCQ 1'b1;*/ wr_data_state <= #TCQ WRITE_DATA_WAIT; end   
                                  endcase
                                  wr_pntr_256 <= #TCQ 3'b000; 
                              end  //if end  
                              else begin
                                   case (wr_pntr_256)  
                                      3'b000  : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[383:256]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[47:32]}; wr_pntr_256 <= #TCQ 3'b000; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                		              3'b001  : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[415:256]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[51:32]}; wr_pntr_256 <= #TCQ 3'b001; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
           	     		              3'b010  : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[447:256]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[55:32]}; wr_pntr_256 <= #TCQ 3'b010; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                		              3'b011  : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[479:256]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[59:32]}; wr_pntr_256 <= #TCQ 3'b011; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                		              3'b100  : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[511:256]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[63:32]}; wr_pntr_256 <= #TCQ 3'b100; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                		              3'b101  : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[543:256]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[67:32]}; wr_pntr_256 <= #TCQ 3'b101; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                		              3'b110  : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[575:256]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[71:32]}; wr_pntr_256 <= #TCQ 3'b110; wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                		              3'b111  : begin wr_data_reg0    <= #TCQ {wr_data, wr_data_reg0[607:256]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[75:32]}; wr_pntr_256 <= #TCQ 3'b111; wr_data_state <= #TCQ WRITE_DATA_WAIT; end 
                                   endcase
                                   if ((len_rem-1)/8 == 0) begin // if len remaining is less than 8 
                                      len_rem <=  #TCQ 11'b0; 
                                   end
                                   else begin
                                      len_rem <= #TCQ len_rem - 8; 
                                   end
                              end //else end
                          end //WRITE_DATA_WAIT       
          endcase //WRITE DATA STATE MACHINE END
          //end
          
   end// else end 
 end

// address decoder block 

 always @(posedge user_clk or negedge reset_n)
 begin
     if (!reset_n) begin 
         wr_addr_pntr <= #TCQ 6'b0;
     end
     else begin 
            if (wr_den) 
                wr_addr_pntr <=  #TCQ wr_addr_pntr + 1; 
            else
                wr_addr_pntr <= #TCQ wr_addr [8:3]; 
          
     end      
 end

end //pio_ep_mem_access_256

else begin // (C_DATA_WIDTH == 512) : pio_ep_mem_access_512

always @(posedge user_clk or negedge reset_n) begin  
   if (!reset_n) begin 
     wr_data_reg0  <= #TCQ 1536'b0; 
     wr_pntr_512   <= #TCQ 4'b0; 
     len_rem       <= #TCQ 11'b0; 
     wr_den        <= #TCQ 1'b0;
     wr_mem_be     <= #TCQ 192'b0;
     wr_data_state <= #TCQ WRITE_DATA_RST;  
   end
   else begin
    //if (wr_en) begin 
    case (wr_data_state)
        WRITE_DATA_RST : begin 
                          if (wr_en & sop) begin 
          			       case (wr_addr[3:0]) 
                			4'b0000  : begin wr_data_reg0 [895:512]   <= #TCQ wr_data[383:0]; wr_mem_be[111:64] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b0000; end
                			4'b0001  : begin wr_data_reg0 [927:544]   <= #TCQ wr_data[383:0]; wr_mem_be[115:68] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b0001; end
           	     			4'b0010  : begin wr_data_reg0 [959:576]   <= #TCQ wr_data[383:0]; wr_mem_be[119:72] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b0010; end
                			4'b0011  : begin wr_data_reg0 [991:608]   <= #TCQ wr_data[383:0]; wr_mem_be[123:76] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b0011; end
                			4'b0100  : begin wr_data_reg0 [1023:640]  <= #TCQ wr_data[383:0]; wr_mem_be[127:80] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b0100; end
                			4'b0101  : begin wr_data_reg0 [1055:672]  <= #TCQ wr_data[383:0]; wr_mem_be[131:84] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b0101; end
                			4'b0110  : begin wr_data_reg0 [1087:704]  <= #TCQ wr_data[383:0]; wr_mem_be[135:88] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b0110; end
                			4'b0111  : begin wr_data_reg0 [1119:736]  <= #TCQ wr_data[383:0]; wr_mem_be[139:92] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b0111; end
							
							4'b1000  : begin wr_data_reg0 [1151:768]   <= #TCQ wr_data[383:0]; wr_mem_be[143:96] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b1000; end
                			4'b1001  : begin wr_data_reg0 [1183:800]   <= #TCQ wr_data[383:0]; wr_mem_be[147:100] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b1001; end
           	     			4'b1010  : begin wr_data_reg0 [1215:832]   <= #TCQ wr_data[383:0]; wr_mem_be[151:104] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b1010; end
                			4'b1011  : begin wr_data_reg0 [1247:864]   <= #TCQ wr_data[383:0]; wr_mem_be[155:108] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b1011; end
                			4'b1100  : begin wr_data_reg0 [1279:896]  <= #TCQ wr_data[383:0];  wr_mem_be[159:112] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b1100; end
                			4'b1101  : begin wr_data_reg0 [1311:928]  <= #TCQ wr_data[383:0];  wr_mem_be[163:116] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b1101; end
                			4'b1110  : begin wr_data_reg0 [1343:960]  <= #TCQ wr_data[383:0];  wr_mem_be[167:120] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b1110; end
                			4'b1111  : begin wr_data_reg0 [1375:992]  <= #TCQ wr_data[383:0];  wr_mem_be[171:124] <= #TCQ data_be[47:0]; wr_pntr_512 <= #TCQ 4'b1111; end
							
							
          			       endcase
                                
                                if (payload_len <= 12) begin 
                                    len_rem <= #TCQ 11'b0;    
                                end
                                else begin
                                    len_rem <= #TCQ payload_len - 12;  
                                end
                                wr_data_state <= #TCQ WRITE_DATA_WAIT; 
                             end   //if
                             else begin 
                                wr_data_state <= #TCQ WRITE_DATA_RST; 
                                wr_den            <= #TCQ 1'b0;
                             end
                                                  
                        end // WRITE_DATA_RST
        WRITE_DATA_WAIT : begin
                              wr_den <= 1'b1; // debugging 
                              if (len_rem == 0) begin
                                  wr_data_reg0 <= #TCQ {512'b0, wr_data_reg0[1535:512]}; 
                                  wr_mem_be    <= #TCQ {64'b0, wr_mem_be[191:64]}; 
                                  case (wr_pntr_512)
								      4'b0000   : begin wr_data_state <= #TCQ WRITE_DATA_RST; end
                                      4'b0001   : begin wr_data_state <= #TCQ WRITE_DATA_RST; end
                                      4'b0010   : begin wr_data_state <= #TCQ WRITE_DATA_RST; end
                                      4'b0011   : begin wr_data_state <= #TCQ WRITE_DATA_RST; end
									  4'b0100   : begin wr_data_state <= #TCQ WRITE_DATA_RST; end
									  4'b0101   : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									  4'b0110   : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									  4'b0111   : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									  4'b1000   : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									  4'b1001   : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									  4'b1010   : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									  4'b1011   : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									  4'b1100   : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									  4'b1101   : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									  4'b1110   : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
									  4'b1111   : begin wr_data_state <= #TCQ WRITE_DATA_WAIT; end
                                  endcase
                                  wr_pntr_512 <= #TCQ 4'b0000; 
                              end  //if end  
                              else begin
                                    case (wr_pntr_512)  
									  4'b0000  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [895:512]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[111:64]}; wr_pntr_512 <= #TCQ 4'b0000; end
                			          4'b0001  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [927:512]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[115:64]}; wr_pntr_512 <= #TCQ 4'b0001; end
           	     			          4'b0010  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [959:512]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[119:64]}; wr_pntr_512 <= #TCQ 4'b0010; end
                			          4'b0011  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [991:512]};  wr_mem_be <= #TCQ {data_be, wr_mem_be[123:64]}; wr_pntr_512 <= #TCQ 4'b0011; end
                			          4'b0100  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1023:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[127:64]}; wr_pntr_512 <= #TCQ 4'b0100; end
                			          4'b0101  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1055:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[131:64]}; wr_pntr_512 <= #TCQ 4'b0101; end
                			          4'b0110  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1087:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[135:64]}; wr_pntr_512 <= #TCQ 4'b0110; end
                		   	          4'b0111  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1119:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[139:64]}; wr_pntr_512 <= #TCQ 4'b0111; end
							
							          4'b1000  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1151:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[143:64]}; wr_pntr_512 <= #TCQ 4'b1000; end
                			          4'b1001  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1183:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[147:64]}; wr_pntr_512 <= #TCQ 4'b1001; end
           	     			          4'b1010  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1215:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[151:64]}; wr_pntr_512 <= #TCQ 4'b1010; end
                			          4'b1011  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1247:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[155:64]}; wr_pntr_512 <= #TCQ 4'b1011; end
                			          4'b1100  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1279:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[159:64]}; wr_pntr_512 <= #TCQ 4'b1100; end
                			          4'b1101  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1311:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[163:64]}; wr_pntr_512 <= #TCQ 4'b1101; end
                			          4'b1110  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1343:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[167:64]}; wr_pntr_512 <= #TCQ 4'b1110; end
                			          4'b1111  : begin wr_data_reg0   <= #TCQ {wr_data, wr_data_reg0 [1375:512]}; wr_mem_be <= #TCQ {data_be, wr_mem_be[171:64]}; wr_pntr_512 <= #TCQ 4'b1111; end
                                   endcase
								   
								   wr_data_state <= #TCQ WRITE_DATA_WAIT;
								   
                                   if ((len_rem-1)/16 == 0) begin // if len remaining is less than 16
                                      len_rem <=  #TCQ 11'b0; 
                                   end
                                   else begin
                                      len_rem <= #TCQ len_rem - 16; 
                                   end
                              end //else end
                          end //WRITE_DATA_WAIT       
          endcase //WRITE DATA STATE MACHINE END
          //end
          
   end// else end 
 end

// address decoder block 

 always @(posedge user_clk or negedge reset_n)
 begin
     if (!reset_n) begin 
         wr_addr_pntr <= #TCQ 5'b0;
     end
     else begin 
            if (wr_den) 
                wr_addr_pntr <=  #TCQ wr_addr_pntr + 1; 
            else
                wr_addr_pntr <= #TCQ wr_addr [8:4]; 
          
     end      
 end

end //pio_ep_mem_access_512

endgenerate



  always @(posedge user_clk)
  begin
    if(!reset_n)
    begin
      gen_transaction <= #TCQ 1'b0;
      gen_leg_intr    <= #TCQ 1'b0;
      gen_msi_intr    <= #TCQ 1'b0;
      gen_msix_intr   <= #TCQ 1'b0;
   end
   else begin
     case(wr_addr)

       PIO_MRD_TR_GEN_REG : begin

         if (trn_sent)
           gen_transaction <= #TCQ 1'b0;
         else if(wr_data[31:0] == 32'hAAAA_BBBB && !gen_transaction && wr_en)
           gen_transaction <= #TCQ 1'b1;
         else
           gen_transaction <= #TCQ 1'b0;

       end // PIO_MRD_TR_GEN_REG

       PIO_INTR_GEN_REG : begin

         if(wr_data[31:0] == 32'hCCCC_DDDD)
           gen_leg_intr  <= #TCQ 1'b1;
         else if (wr_data[31:0] == 32'hEEEE_FFFF)
           gen_msi_intr  <= #TCQ 1'b1;
         else if (wr_data[31:0] == 32'hDEAD_BEEF)
           gen_msix_intr <= #TCQ 1'b1;
         else begin
           gen_leg_intr  <= #TCQ 1'b0;
           gen_msi_intr  <= #TCQ 1'b0;
           gen_msix_intr <= #TCQ 1'b0;
         end

       end //PIO_INTR_GEN_REG

       default : begin

         gen_transaction <= #TCQ 1'b0;
         gen_leg_intr    <= #TCQ 1'b0;
         gen_msi_intr    <= #TCQ 1'b0;
         gen_msix_intr   <= #TCQ 1'b0;

       end

     endcase

   end
  end


  // Write controller busy

  assign wr_busy = wr_en | (wr_data_state != WRITE_DATA_RST) | gen_transaction;
    //localparam MEM_W = 256; // Data Width of memory
	//localparam ADDR_W = 6;  //address width of memory 
	//localparam WBE_W  = 32; // Write Byte enable width
	
  pio_ep_xpm_sdpram_wrap #(
    .MEM_W (MEM_W),
    .ADR_W (ADDR_W),  
    .WBE_W (BYTE_EN_W),
    .PAR_W (MEM_W/8),  
    .ECC_ENABLE (0),  
    .PARITY_ENABLE (0),  
    .RDT_FFOUT (0)		// rdt flop-out
  ) ep_xpm_sdpram (
    .clk   (user_clk),
    .rst   (~reset_n),   
    .wr_en (wr_den),	
    .wr_be (wr_mem_be[BYTE_EN_W-1:0]),
    .wad   (wr_addr_pntr),
    .wdt   (wr_data_reg0[MEM_W-1:0]),
    .wpar  (),    
    .re    (rd_en),
    .rad   (rd_addr),
    .rdt   (rd_data),
    .rpar  (),    
    .sbe   (),
    .dbe   ()
);
endmodule
