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
// File       : pio_tx_engine.v
// Version    : 1.3 
//-----------------------------------------------------------------------------
//
// Description: Local-Link Transmit Unit.
//
//--------------------------------------------------------------------------------
`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module pio_tx_engine    #(

  parameter       TCQ = 1,
  parameter [1:0] AXISTEN_IF_WIDTH = 00,
  parameter       AXI4_CC_TUSER_WIDTH = 33,
  parameter       AXI4_RQ_TUSER_WIDTH = 62,
  parameter       AXISTEN_IF_RQ_ALIGNMENT_MODE = "FALSE",
  parameter       AXISTEN_IF_CC_ALIGNMENT_MODE = "FALSE",
  parameter       AXISTEN_IF_ENABLE_CLIENT_TAG = 0,
  parameter       AXISTEN_IF_RQ_PARITY_CHECK   = 0,
  parameter       AXISTEN_IF_CC_PARITY_CHECK   = 0,

  //Do not modify the parameters below this line
  //parameter C_DATA_WIDTH = (AXISTEN_IF_WIDTH[1]) ? 256 : (AXISTEN_IF_WIDTH[0])? 128 : 64,
  parameter C_DATA_WIDTH = 512,
  parameter ADDR_W       = 6,                 // Memory Depth based on the C_DATA_WIDTH
  parameter MEM_W        = 256,                 // Memory Depth based on the C_DATA_WIDTH
  parameter BYTE_EN_W    = 32,               // Width of byte enable going to memory for write data
  
  parameter PARITY_WIDTH = C_DATA_WIDTH /8,
  parameter KEEP_WIDTH   = C_DATA_WIDTH /32,
  parameter STRB_WIDTH   = C_DATA_WIDTH / 8
)(

  input                          user_clk,
  input                          reset_n,

  // AXI-S Completer Completion Interface

  output reg        [C_DATA_WIDTH-1:0]  s_axis_cc_tdata,
  output reg          [KEEP_WIDTH-1:0]  s_axis_cc_tkeep,
  output reg                            s_axis_cc_tlast,
  output reg                            s_axis_cc_tvalid,
  output     [AXI4_CC_TUSER_WIDTH-1:0]  s_axis_cc_tuser,
  input                                 s_axis_cc_tready,

  // AXI-S Requester Request Interface

  output reg        [C_DATA_WIDTH-1:0]  s_axis_rq_tdata,
  output reg          [KEEP_WIDTH-1:0]  s_axis_rq_tkeep,
  output reg                            s_axis_rq_tlast,
  output reg                            s_axis_rq_tvalid,
  output reg [AXI4_RQ_TUSER_WIDTH-1:0]  s_axis_rq_tuser,
  input                                 s_axis_rq_tready,

  // TX Message Interface

  input                          cfg_msg_transmit_done,
  output reg                     cfg_msg_transmit,
  output reg              [2:0]  cfg_msg_transmit_type,
  output reg             [31:0]  cfg_msg_transmit_data,

  //Tag availability and Flow control Information

  input                   [5:0]  pcie_rq_tag,
  input                          pcie_rq_tag_vld,
  input                   [1:0]  pcie_tfc_nph_av,
  input                   [1:0]  pcie_tfc_npd_av,
  input                          pcie_tfc_np_pl_empty,
  input                   [3:0]  pcie_rq_seq_num,
  input                          pcie_rq_seq_num_vld,

  //Cfg Flow Control Information

  input                   [7:0]  cfg_fc_ph,
  input                   [7:0]  cfg_fc_nph,
  input                   [7:0]  cfg_fc_cplh,
  input                  [11:0]  cfg_fc_pd,
  input                  [11:0]  cfg_fc_npd,
  input                  [11:0]  cfg_fc_cpld,
  output                   [2:0]  cfg_fc_sel,


  // PIO RX Engine Interface

  input                          req_compl,
  input                          req_compl_wd,
  input                          req_compl_ur,
 input                         [10:0] payload_len,
  output reg                     compl_done,
  input                   [2:0]  req_tc,
  input                          req_td,
  input                          req_ep,
  input                   [1:0]  req_attr,
  input                   [10:0]  req_len,
  input                  [15:0]  req_rid,
  input                   [7:0]  req_tag,
  input                   [7:0]  req_be,
  input                  [12:0]  req_addr,
  input                   [1:0]  req_at,

  input                  [15:0]  completer_id,

  // Inputs to the TX Block in case of an UR
  // Required to form the completions

  input                  [63:0]  req_des_qword0,
  input                  [63:0]  req_des_qword1,
  input                          req_des_tph_present,
  input                   [1:0]  req_des_tph_type,
  input                   [7:0]  req_des_tph_st_tag,

  //Indicate that the Request was a Mem lock Read Req

  input                          req_mem_lock,
  input                          req_mem,

  // PIO Memory Access Control Interface
  output reg       [ADDR_W-1:0]  rd_addr,
  output reg       [3:0]         rd_be,
  output reg                     rd_en,
  output reg                     trn_sent,
  input            [MEM_W-1:0]   rd_data,
  input                          gen_transaction

);


  localparam PIO_TX_RST_STATE                   = 4'b0000;
  localparam PIO_TX_COMPL_C1                    = 4'b0001;
  localparam PIO_TX_COMPL_C2                    = 4'b0010;
  localparam PIO_TX_COMPL_WD_C1                 = 4'b0011;
  localparam PIO_TX_COMPL_WD_C2                 = 4'b0100;
  localparam PIO_TX_COMPL_PYLD                  = 4'b0101;
  localparam PIO_TX_CPL_UR_C1                   = 4'b0110;
  localparam PIO_TX_CPL_UR_C2                   = 4'b0111;
  localparam PIO_TX_CPL_UR_C3                   = 4'b1000;
  localparam PIO_TX_CPL_UR_C4                   = 4'b1001;
  localparam PIO_TX_MRD_C1                      = 4'b1010;
  localparam PIO_TX_MRD_C2                      = 4'b1011;
  localparam PIO_TX_COMPL_WD_2DW                = 4'b1100;
  localparam PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C1   = 4'b1101;
  localparam PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C2   = 4'b1110;
  localparam PIO_TX_COMPL_WD_N_DW               = 4'b1111; // added for N-DW support

  // Local registers


  reg  [11:0]              byte_count_fbe;
  reg  [11:0]              byte_count_lbe;
//  wire [11:0]              byte_count; //currently not used
  reg  [06:0]              lower_addr;
  reg  [06:0]              lower_addr_q;
  reg  [06:0]              lower_addr_qq;
  reg  [6:0]               lower_addr_dw;  
  reg  [15:0]              tkeep;
  reg  [15:0]              tkeep_q;
  reg  [15:0]              tkeep_qq;

  reg                      req_compl_q;
  reg                      req_compl_qq;
  reg                      req_compl_wd_q;
  reg                      req_compl_wd_qq;
  reg                      req_compl_wd_qqq;
  reg                      req_compl_wd_qqqq; 
  reg                      req_compl_wd_qqqqq;
  reg                      req_compl_ur_q;
  reg                      req_compl_ur_qq;

  reg  [3:0]               state;

  wire  [31:0]             s_axis_cc_tparity;
  wire  [31:0]             s_axis_rq_tparity;

  reg                      dword_count; // to count if its a 1DW or 2 DW transaction
  reg  [95:0]              rd_data_s1; // To Store the 1st rd_data in case of N-DW payload
  reg [3*C_DATA_WIDTH-1:0] rd_data_s0;
  reg  [10:0]              len_i; 
  reg  [31:0]              rd_data_reg; // To Store the 1st rd_data in case of 2DW payload
  reg [AXI4_CC_TUSER_WIDTH-1:0]  s_axis_cc_tuser_wo_parity;

  reg [12:0] byte_count; 
 // CFG func sel

  assign cfg_fc_sel = 3'b0;


  // Present address and byte enable to memory module

always @ (posedge user_clk)begin
   if (!reset_n) begin
         rd_be    <=  #TCQ 4'b0;
   end
   else if(req_compl_wd) begin
        if(payload_len == 0) begin
         rd_be    <= #TCQ 4'h0;
        end
        else begin 
         rd_be    <= #TCQ req_be[3:0];
       end
end
end

generate

// State machine to increment the read address to the memory 
  if (C_DATA_WIDTH == 64) begin : pio_tx_sm_64
    reg  rd_addr_state; 
    reg [10:0] rd_addr_rem;

        
    always @(s_axis_cc_tready) begin 
        rd_en = 1'b0; 
    if (s_axis_cc_tready) 
        rd_en = 1'b1; 
    else
        rd_en = 1'b0;   
    end
    
	
    always @(posedge user_clk or negedge reset_n) begin 
      if (!reset_n) begin 
	      rd_addr       <= #TCQ 8'b0; 
		  rd_addr_state <= #TCQ 1'b0; 
		  rd_addr_rem   <= #TCQ 11'b0; 
		  //rd_en         <= #TCQ 1'b0;
	  end 
	  else begin
          case (rd_addr_state) 
		        1'b0   : begin
                                if (req_compl_wd) begin
                                    rd_addr        <= #TCQ req_addr[10:3];
                                    //rd_en          <= #TCQ 1'b1; 
                                    rd_addr_state  <= #TCQ 1'b1; 
                                    case (req_addr[2])
									    1'b0   : rd_addr_rem <= #TCQ (payload_len < 3 ) ? 11'b0 : payload_len - 11'h2; 
										1'b1   : rd_addr_rem <= #TCQ (payload_len < 2 ) ? 11'b0 : payload_len - 11'h1; 
                                    endcase			
                                end
                                else begin
                                    rd_addr        <= #TCQ rd_addr; 
                                    rd_addr_state  <= #TCQ 1'b0; 
                                    rd_addr_rem    <= #TCQ 11'b0; 
                                    //rd_en          <= #TCQ 1'b0; 									
                                end								    								
				         end // RST State end
				1'b1   : begin 
				if (s_axis_cc_tready) begin 
				                 if (rd_addr_rem == 0) begin 
								     rd_addr        <= #TCQ rd_addr; 
									 rd_addr_state  <= #TCQ 1'b0; 
									 rd_addr_rem    <= #TCQ 11'b0; 
									 //rd_en          <= #TCQ 1'b1; 
							     end 
								 else begin
								     if ((rd_addr_rem-1)/2 == 0 ) begin 
                                         rd_addr        <= #TCQ rd_addr + 1; 
									     rd_addr_state  <= #TCQ 1'b0; 
									     rd_addr_rem    <= #TCQ 11'b0;
									     //rd_en          <= #TCQ 1'b1; 
                                     end
                                     else begin
 									     rd_addr        <= #TCQ rd_addr + 1; 
									     rd_addr_state  <= #TCQ 1'b1; 
									     rd_addr_rem    <= #TCQ rd_addr_rem - 11'h2;
									     //rd_en          <= #TCQ 1'b1; 
                                     end									 
								 end
				end
				else begin 
                                        rd_addr        <= #TCQ rd_addr; //_prev; 
					rd_addr_state  <= #TCQ 1'b1; 
					rd_addr_rem    <= #TCQ rd_addr_rem; // _prev;
					//rd_en          <= #TCQ rd_en; 

				end 
						   end // Address Increment State end
		        
          endcase		  
	  end
   end
//State machine to form the read data based on the offset 
    reg [1:0] rd_data_state;
    wire [63:0] temp_64_data_64; // debugging
    wire [63:0] temp_128_data_64; //debugging
    wire [63:0] temp_192_data_64; //debugging
    reg [10:0] dw_rem; 
    reg rd_data_ready; 
    localparam PIO_RD_DATA_RST  = 2'b00; 
	localparam PIO_RD_DATA_WAIT = 2'b01;  
	//debugging 
	assign temp_64_data_64  = rd_data_s0[63:0]; 
	assign temp_128_data_64 = rd_data_s0[127:64]; 
    assign temp_192_data_64 = rd_data_s0[191:127]; 
    //debugging
  always @(posedge user_clk or negedge reset_n) 
  begin
      if (!reset_n) begin 
	      rd_data_state <= #TCQ 3'b000; 
		  rd_data_s0    <= #TCQ 192'b0; 
		  rd_data_ready <= #TCQ 1'b0; 
		  dw_rem        <= #TCQ 11'b0; 
      end
	  else begin
          case (rd_data_state)
		  PIO_RD_DATA_RST : begin 
		                          rd_data_ready <= #TCQ 1'b0;
				                  if (req_compl_wd_qq) begin 
								      case (req_addr[2])
									        1'b0   : begin rd_data_s0[127:64]  <= #TCQ rd_data[63:0];   dw_rem <= #TCQ (payload_len < 3 ) ? 11'b0 : payload_len - 11'h2; end
											1'b1   : begin rd_data_s0[95:64]   <= #TCQ rd_data[63:32];  dw_rem <= #TCQ (payload_len < 2 ) ? 11'b0 : payload_len - 11'h1; end						
									  endcase
									  if (s_axis_cc_tready) 
									      rd_data_state <= #TCQ PIO_RD_DATA_WAIT; 
									  else
                                          rd_data_state <= #TCQ PIO_RD_DATA_RST; 	              										
							      end
								  else begin 
								      rd_data_s0   <= #TCQ rd_data_s0;
									  rd_data_state <= #TCQ PIO_RD_DATA_RST; 
								  end
						    end //PIO_RD_DATA_RST 
		  PIO_RD_DATA_WAIT : begin
		                     if (s_axis_cc_tready) begin 
		                          rd_data_ready <= #TCQ 1'b1; 
		                          if (dw_rem == 0 ) begin
								      rd_data_s0    <= #TCQ {64'b0, rd_data_s0[191:64]};
									  rd_data_state  <= #TCQ PIO_RD_DATA_RST; 
								  end
								  else begin
								      case (req_addr[2])
									        1'b0   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[127:64]};  end
											1'b1   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[95:64]};  end									
									  endcase
									  if ((dw_rem -1)/2 == 0) 
                                          dw_rem        <= #TCQ 11'h0; 
                                      else 
									      dw_rem        <= #TCQ dw_rem - 11'h2; 
										  
                                      rd_data_state <= #TCQ PIO_RD_DATA_WAIT;  								  
								  end  	
				      end
				      else begin 
                                          rd_data_state <= #TCQ PIO_RD_DATA_WAIT;  
                                          rd_data_s0 <= #TCQ rd_data_s0; //_prev;
				      end 
		                     end //PIO_RD_DATA_WAIT 
							 
		  default : begin rd_data_s0 <= #TCQ rd_data_s0; rd_data_state <= #TCQ PIO_RD_DATA_RST; end
          endcase		  
	  end
	  
  end  
  
  end
  
  else if (C_DATA_WIDTH == 128) begin : pio_tx_sm_128
    reg  rd_addr_state; 
    reg [10:0] rd_addr_rem;
	
	always @(s_axis_cc_tready) begin 
        rd_en = 1'b0; 
    if (s_axis_cc_tready) 
        rd_en = 1'b1; 
    else
        rd_en = 1'b0;   
    end
	
    always @(posedge user_clk or negedge reset_n) begin 
      if (!reset_n) begin 
	      rd_addr       <= #TCQ 7'b0; 
		  rd_addr_state <= #TCQ 1'b0; 
		  rd_addr_rem   <= #TCQ 11'b0; 
		  //rd_en         <= #TCQ 1'b0; 
	  end 
	  else begin
          case (rd_addr_state) 
		        1'b0   : begin
                                if (req_compl_wd) begin
                                    rd_addr        <= #TCQ req_addr[10:4];
                                    //rd_en          <= #TCQ 1'b1; 
                                    rd_addr_state  <= #TCQ 1'b1; 
                                    case (req_addr[3:2])
									    2'b00  : rd_addr_rem <= #TCQ (payload_len < 5 ) ? 11'b0 : payload_len - 11'h4; 
										2'b01  : rd_addr_rem <= #TCQ (payload_len < 4 ) ? 11'b0 : payload_len - 11'h3; 
										2'b10  : rd_addr_rem <= #TCQ (payload_len < 3 ) ? 11'b0 : payload_len - 11'h2; 
										2'b11  : rd_addr_rem <= #TCQ (payload_len < 2 ) ? 11'b0 : payload_len - 11'h1;
                                    endcase			
                                end
                                else begin
                                    rd_addr        <= #TCQ rd_addr; 
                                    rd_addr_state  <= #TCQ 1'b0; 
                                    rd_addr_rem    <= #TCQ 11'b0; 
                                    //rd_en          <= #TCQ 1'b0; 									
                                end								    								
				         end // RST State end
				1'b1   : begin 
				                 if (rd_addr_rem == 0) begin 
								     rd_addr        <= #TCQ rd_addr; 
									 rd_addr_state  <= #TCQ 1'b0; 
									 rd_addr_rem    <= #TCQ 11'b0; 
									 //rd_en          <= #TCQ 1'b1; 
							     end 
								 else begin
								     if ((rd_addr_rem-1)/4 == 0 ) begin 
                                         rd_addr        <= #TCQ rd_addr + 1; 
									     rd_addr_state  <= #TCQ 1'b0; 
									     rd_addr_rem    <= #TCQ 11'b0;
									     //rd_en          <= #TCQ 1'b1; 
                                     end
                                     else begin
 									     rd_addr        <= #TCQ rd_addr + 1; 
									     rd_addr_state  <= #TCQ 1'b1; 
									     rd_addr_rem    <= #TCQ rd_addr_rem - 11'h4;
									     //rd_en          <= #TCQ 1'b1; 
                                     end									 
								 end
						   end // Address Increment State end
		        
          endcase		  
	  end
   end
//State machine to form the read data based on the offset 
    reg [1:0] rd_data_state;
    wire [127:0] temp_128_data_128; // debugging
    wire [127:0] temp_256_data_128; //debugging
    wire [127:0] temp_384_data_128; //debugging
    reg [10:0] dw_rem; 
    reg rd_data_ready; 
    localparam PIO_RD_DATA_RST  = 2'b00; 
	localparam PIO_RD_DATA_WAIT = 2'b01;  
	//debugging 
	assign temp_128_data_128  = rd_data_s0[127:0]; 
	assign temp_256_data_128 = rd_data_s0[255:128]; 
    assign temp_384_data_128 = rd_data_s0[383:256]; 
    //debugging
  always @(posedge user_clk or negedge reset_n) 
  begin
      if (!reset_n) begin 
	      rd_data_state <= #TCQ 2'b00; 
		  rd_data_s0    <= #TCQ 384'b0; 
		  rd_data_ready <= #TCQ 1'b0; 
		  dw_rem        <= #TCQ 11'b0; 
      end
	  else begin
          case (rd_data_state)
		  PIO_RD_DATA_RST : begin 
		                          rd_data_ready <= #TCQ 1'b0;
				                  if (req_compl_wd_qq) begin 
								      case (req_addr[3:2])
									        2'b00   : begin rd_data_s0[255:128]  <= #TCQ rd_data[127:0];   dw_rem <= #TCQ (payload_len < 5 ) ? 11'b0 : payload_len - 11'h4; end
											2'b01   : begin rd_data_s0[223:128]  <= #TCQ rd_data[127:32];  dw_rem <= #TCQ (payload_len < 4 ) ? 11'b0 : payload_len - 11'h3; end	
                                            2'b10   : begin rd_data_s0[191:128]  <= #TCQ rd_data[127:64];  dw_rem <= #TCQ (payload_len < 3 ) ? 11'b0 : payload_len - 11'h2; end
											2'b11   : begin rd_data_s0[159:128]  <= #TCQ rd_data[127:96];  dw_rem <= #TCQ (payload_len < 2 ) ? 11'b0 : payload_len - 11'h1; end															
									  endcase
									  if (s_axis_cc_tready) 
									      rd_data_state <= #TCQ PIO_RD_DATA_WAIT; 
									  else
                                          rd_data_state <= #TCQ PIO_RD_DATA_RST; 	              										
							      end
								  else begin 
								      rd_data_s0   <= #TCQ rd_data_s0;
									  rd_data_state <= #TCQ PIO_RD_DATA_RST; 
								  end
						    end //PIO_RD_DATA_RST 
		  PIO_RD_DATA_WAIT : begin
		                     if (s_axis_cc_tready) begin 
		                          rd_data_ready <= #TCQ 1'b1; 
		                          if (dw_rem == 0 ) begin
								      rd_data_s0    <= #TCQ {128'b0, rd_data_s0[383:128]};
									  rd_data_state  <= #TCQ PIO_RD_DATA_RST; 
								  end
								  else begin
								      case (req_addr[3:2])
									        2'b00   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[255:128]};  end
											2'b01   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[223:128]};  end	
                                            2'b10   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[191:128]};  end
											2'b11   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[159:128]};  end												
									  endcase
									  if ((dw_rem -1)/4 == 0) 
                                          dw_rem        <= #TCQ 11'h0; 
                                      else 
									      dw_rem        <= #TCQ dw_rem - 11'h4; 
										  
                                      rd_data_state <= #TCQ PIO_RD_DATA_WAIT;  								  
								  end  	
						     end
                             else begin 
                                          rd_data_state <= #TCQ PIO_RD_DATA_WAIT;  
                                          rd_data_s0 <= #TCQ rd_data_s0; //_prev;
				             end 								  
		                    end //PIO_RD_DATA_WAIT 
							 
		  default : begin rd_data_s0 <= #TCQ rd_data_s0; rd_data_state <= #TCQ PIO_RD_DATA_RST; end
          endcase		  
	  end
	  
  end  
  end
  
  else if (C_DATA_WIDTH == 256 ) begin : pio_tx_sm_256
    reg  rd_addr_state; 
    reg [10:0] rd_addr_rem;
	
	always @(s_axis_cc_tready) begin 
        rd_en = 1'b0; 
    if (s_axis_cc_tready) 
        rd_en = 1'b1; 
    else
        rd_en = 1'b0;   
    end
	
    always @(posedge user_clk or negedge reset_n) begin 
      if (!reset_n) begin 
	          rd_addr   <= #TCQ 6'b0; 
		  rd_addr_state <= #TCQ 1'b0; 
		  rd_addr_rem   <= #TCQ 11'b0; 
		  //rd_en         <= #TCQ 1'b0; 
	  end 
	  else begin
          case (rd_addr_state) 
		        1'b0   : begin
                                if (req_compl_wd) begin
                                    rd_addr        <= #TCQ req_addr[10:5];
                                    //rd_en          <= #TCQ 1'b1; 
                                    rd_addr_state  <= #TCQ 1'b1; 
                                    case (req_addr[4:2])
									    3'b000   : rd_addr_rem <= #TCQ (payload_len < 9 ) ? 11'b0 : payload_len - 11'h8; 
										3'b001   : rd_addr_rem <= #TCQ (payload_len < 8 ) ? 11'b0 : payload_len - 11'h7; 
										3'b010   : rd_addr_rem <= #TCQ (payload_len < 7 ) ? 11'b0 : payload_len - 11'h6; 
										3'b011   : rd_addr_rem <= #TCQ (payload_len < 6 ) ? 11'b0 : payload_len - 11'h5; 
										3'b100   : rd_addr_rem <= #TCQ (payload_len < 5 ) ? 11'b0 : payload_len - 11'h4; 
										3'b101   : rd_addr_rem <= #TCQ (payload_len < 4 ) ? 11'b0 : payload_len - 11'h3; 
										3'b110   : rd_addr_rem <= #TCQ (payload_len < 3 ) ? 11'b0 : payload_len - 11'h2; 
										3'b111   : rd_addr_rem <= #TCQ (payload_len < 2 ) ? 11'b0 : payload_len - 11'h1; 
                                    endcase			
                                end
                                else begin
                                    rd_addr        <= #TCQ rd_addr; 
                                    rd_addr_state  <= #TCQ 2'b00; 
                                    rd_addr_rem    <= #TCQ 11'b0; 
                                    //rd_en          <= #TCQ 1'b0; 									
                                end								    								
				         end // RST State end
				1'b1   : begin 
				                 if (rd_addr_rem == 0) begin 
								     rd_addr        <= #TCQ rd_addr; 
									 rd_addr_state  <= #TCQ 1'b0; 
									 rd_addr_rem    <= #TCQ 11'b0; 
									 //rd_en          <= #TCQ 1'b1; 
							     end 
								 else begin
								     if ((rd_addr_rem-1)/8 == 0 ) begin 
                                         rd_addr        <= #TCQ rd_addr + 1; 
									     rd_addr_state  <= #TCQ 2'b00; 
									     rd_addr_rem    <= #TCQ 11'b0;
									     //rd_en          <= #TCQ 1'b1; 
                                     end
                                     else begin
 									     rd_addr        <= #TCQ rd_addr + 1; 
									     rd_addr_state  <= #TCQ 2'b01; 
									     rd_addr_rem    <= #TCQ rd_addr_rem - 11'h8;
									     //rd_en          <= #TCQ 1'b1; 
                                     end									 
								 end
						   end // Address Increment State end
		        
          endcase		  
	  end
   end
//State machine to form the read data based on the offset 
    reg [1:0] rd_data_state;
    wire [255:0] temp_256_data_256; // debugging
    wire [255:0] temp_512_data_256; //debugging
    wire [255:0] temp_768_data_256; //debugging
    reg [10:0] dw_rem; 
    reg rd_data_ready; 
    localparam PIO_RD_DATA_RST  = 2'b00; 
	localparam PIO_RD_DATA_WAIT = 2'b01;  
	//debugging 
	assign temp_256_data_256 = rd_data_s0[255:0]; 
	assign temp_512_data_256 = rd_data_s0[511:256]; 
    assign temp_768_data_256 = rd_data_s0[767:512]; 
    //debugging
  always @(posedge user_clk or negedge reset_n) 
  begin
      if (!reset_n) begin 
	      rd_data_state <= #TCQ 3'b000; 
		  rd_data_s0   <= #TCQ 768'b0; 
		  rd_data_ready <= #TCQ 1'b0; 
		  dw_rem        <= #TCQ 11'b0; 
      end
	  else begin
          case (rd_data_state)
		  PIO_RD_DATA_RST : begin 
		                          rd_data_ready <= #TCQ 1'b0;
				                  if (req_compl_wd_qq) begin 
								      case (req_addr[4:2])
									        3'b000   : begin rd_data_s0[511:256] <= #TCQ rd_data[255:0];   dw_rem <= #TCQ (payload_len < 9 ) ? 11'b0 : payload_len - 11'h8; end
											3'b001   : begin rd_data_s0[479:256] <= #TCQ rd_data[255:32];  dw_rem <= #TCQ (payload_len < 8 ) ? 11'b0 : payload_len - 11'h7; end
											3'b010   : begin rd_data_s0[447:256] <= #TCQ rd_data[255:64];  dw_rem <= #TCQ (payload_len < 7 ) ? 11'b0 : payload_len - 11'h6; end
											3'b011   : begin rd_data_s0[415:256] <= #TCQ rd_data[255:96];  dw_rem <= #TCQ (payload_len < 6 ) ? 11'b0 : payload_len - 11'h5; end
                                            3'b100   : begin rd_data_s0[383:256] <= #TCQ rd_data[255:128]; dw_rem <= #TCQ (payload_len < 5 ) ? 11'b0 : payload_len - 11'h4; end
											3'b101   : begin rd_data_s0[351:256] <= #TCQ rd_data[255:160]; dw_rem <= #TCQ (payload_len < 4 ) ? 11'b0 : payload_len - 11'h3; end
                                            3'b110   : begin rd_data_s0[319:256] <= #TCQ rd_data[255:192]; dw_rem <= #TCQ (payload_len < 3 ) ? 11'b0 : payload_len - 11'h2; end
											3'b111   : begin rd_data_s0[287:256] <= #TCQ rd_data[255:224]; dw_rem <= #TCQ (payload_len < 2 ) ? 11'b0 : payload_len - 11'h1; end											
									  endcase
									  if (s_axis_cc_tready) 
									      rd_data_state <= #TCQ PIO_RD_DATA_WAIT; 
									  else
                                          rd_data_state <= #TCQ PIO_RD_DATA_RST; 	              										
							      end
								  else begin 
								      rd_data_s0   <= #TCQ rd_data_s0;
									  rd_data_state <= #TCQ PIO_RD_DATA_RST; 
								  end
						    end //PIO_RD_DATA_RST 
		  PIO_RD_DATA_WAIT : begin
		                     if (s_axis_cc_tready) begin 
		                          rd_data_ready <= #TCQ 1'b1; 
		                          if (dw_rem == 0 ) begin
								      rd_data_s0    <= #TCQ {256'b0, rd_data_s0[767:256]};
									  rd_data_state  <= #TCQ PIO_RD_DATA_RST; 
								  end
								  else begin
								      case (req_addr[4:2])
									        3'b000   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[511:256]};  end
											3'b001   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[479:256]};  end
											3'b010   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[447:256]};  end
											3'b011   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[415:256]};  end
                                            3'b100   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[383:256]};  end
											3'b101   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[351:256]};  end
                                            3'b110   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[319:256]};  end
											3'b111   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[287:256]};  end											
									  endcase
									  if ((dw_rem -1)/8 == 0) 
                                          dw_rem        <= #TCQ 11'h0; 
                                      else 
									      dw_rem        <= #TCQ dw_rem - 11'h8; 
										  
                                      rd_data_state <= #TCQ PIO_RD_DATA_WAIT;  								  
								  end  
                             end
                             else begin 
                                          rd_data_state <= #TCQ PIO_RD_DATA_WAIT;  
                                          rd_data_s0 <= #TCQ rd_data_s0; //_prev;
				             end 									  
		                     end //PIO_RD_DATA_WAIT 
							 
		  default : begin rd_data_s0 <= #TCQ rd_data_s0; rd_data_state <= #TCQ PIO_RD_DATA_RST; end
          endcase		  
	  end
	  
  end  
  
  end
  
  else begin // (C_DATA_WIDTH == 512 ) : pio_tx_sm_512
    reg  rd_addr_state; 
    reg [10:0] rd_addr_rem;
	
	always @(s_axis_cc_tready) begin 
        rd_en = 1'b0; 
    if (s_axis_cc_tready) 
        rd_en = 1'b1; 
    else
        rd_en = 1'b0;   
    end
	
    always @(posedge user_clk or negedge reset_n) begin 
      if (!reset_n) begin 
	      rd_addr       <= #TCQ 5'b0; 
		  rd_addr_state <= #TCQ 1'b0; 
		  rd_addr_rem   <= #TCQ 11'b0; 
		  //rd_en         <= #TCQ 1'b0; 
	  end 
	  else begin
          case (rd_addr_state) 
		        1'b0   : begin
                                if (req_compl_wd) begin
                                    rd_addr        <= #TCQ req_addr[10:6];
                                    //rd_en          <= #TCQ 1'b1; 
                                    rd_addr_state  <= #TCQ 1'b1; 
                                    case (req_addr[5:2])
									    4'b0000   : rd_addr_rem <= #TCQ (payload_len < 17 ) ? 11'b0 : payload_len - 11'h10; 
										4'b0001   : rd_addr_rem <= #TCQ (payload_len < 16 ) ? 11'b0 : payload_len - 11'hF; 
										4'b0010   : rd_addr_rem <= #TCQ (payload_len < 15 ) ? 11'b0 : payload_len - 11'hE; 
										4'b0011   : rd_addr_rem <= #TCQ (payload_len < 14 ) ? 11'b0 : payload_len - 11'hD; 
										4'b0100   : rd_addr_rem <= #TCQ (payload_len < 13 ) ? 11'b0 : payload_len - 11'hC; 
										4'b0101   : rd_addr_rem <= #TCQ (payload_len < 12 ) ? 11'b0 : payload_len - 11'hB; 
										4'b0110   : rd_addr_rem <= #TCQ (payload_len < 11 ) ? 11'b0 : payload_len - 11'hA; 
										4'b0111   : rd_addr_rem <= #TCQ (payload_len < 10 ) ? 11'b0 : payload_len - 11'h9; 
										4'b1000   : rd_addr_rem <= #TCQ (payload_len < 9 )  ? 11'b0 : payload_len - 11'h8; 
										4'b1001   : rd_addr_rem <= #TCQ (payload_len < 8 )  ? 11'b0 : payload_len - 11'h7; 
										4'b1010   : rd_addr_rem <= #TCQ (payload_len < 7 )  ? 11'b0 : payload_len - 11'h6; 
										4'b1011   : rd_addr_rem <= #TCQ (payload_len < 6 )  ? 11'b0 : payload_len - 11'h5; 
										4'b1100   : rd_addr_rem <= #TCQ (payload_len < 5 )  ? 11'b0 : payload_len - 11'h4; 
										4'b1101   : rd_addr_rem <= #TCQ (payload_len < 4 )  ? 11'b0 : payload_len - 11'h3; 
										4'b1110   : rd_addr_rem <= #TCQ (payload_len < 3 )  ? 11'b0 : payload_len - 11'h2; 
										4'b1111   : rd_addr_rem <= #TCQ (payload_len < 2 )  ? 11'b0 : payload_len - 11'h1; 
                                    endcase			
                                end
                                else begin
                                    rd_addr        <= #TCQ rd_addr; 
                                    rd_addr_state  <= #TCQ 2'b00; 
                                    rd_addr_rem    <= #TCQ 11'b0; 
                                    //rd_en          <= #TCQ 1'b0; 									
                                end								    								
				         end // RST State end
				1'b1   : begin 
				                 if (rd_addr_rem == 0) begin 
								     rd_addr        <= #TCQ rd_addr; 
									 rd_addr_state  <= #TCQ 1'b0; 
									 rd_addr_rem    <= #TCQ 11'b0; 
									 //rd_en          <= #TCQ 1'b1; 
							     end 
								 else begin
								     if ((rd_addr_rem-1)/16 == 0 ) begin 
                                         rd_addr        <= #TCQ rd_addr + 1; 
									     rd_addr_state  <= #TCQ 1'b0; 
									     rd_addr_rem    <= #TCQ 11'b0;
									     //rd_en          <= #TCQ 1'b1; 
                                     end
                                     else begin
 									     rd_addr        <= #TCQ rd_addr + 1; 
									     rd_addr_state  <= #TCQ 1'b1; 
									     rd_addr_rem    <= #TCQ rd_addr_rem - 11'h10;
									     //rd_en          <= #TCQ 1'b1; 
                                     end									 
								 end
						   end // Address Increment State end
		        
          endcase		  
	  end
   end
//State machine to form the read data based on the offset 
    reg [1:0] rd_data_state;
    wire [512:0] temp_512_data; // debugging
    wire [512:0] temp_1024_data; //debugging
    wire [512:0] temp_1536_data; //debugging
    reg [10:0] dw_rem; 
    reg rd_data_ready; 
    localparam PIO_RD_DATA_RST  = 2'b00; 
	localparam PIO_RD_DATA_WAIT = 2'b01;  
	//debugging 
	assign temp_512_data  = rd_data_s0[511:0]; 
	assign temp_1024_data = rd_data_s0[1023:512]; 
    assign temp_1536_data = rd_data_s0[1535:1024]; 
    //debugging
	
  always @(posedge user_clk or negedge reset_n) 
  begin
      if (!reset_n) begin 
	      rd_data_state <= #TCQ 2'b00; 
		  rd_data_s0   <= #TCQ 1536'b0; 
		  rd_data_ready <= #TCQ 1'b0; 
		  dw_rem        <= #TCQ 11'b0; 
      end
	  else begin
          case (rd_data_state)
		  PIO_RD_DATA_RST : begin 
		                          rd_data_ready <= #TCQ 1'b0;
				                  if (req_compl_wd_qq) begin 
								      case (req_addr[5:2])
									        4'b0000   : begin rd_data_s0[1023:512] <= #TCQ rd_data[511:0];  dw_rem <= #TCQ (payload_len < 17 ) ? 11'b0 : payload_len - 11'h10; end
											4'b0001   : begin rd_data_s0[991:512] <= #TCQ rd_data[511:32];  dw_rem <= #TCQ (payload_len < 16 ) ? 11'b0 : payload_len - 11'hF; end
											4'b0010   : begin rd_data_s0[959:512] <= #TCQ rd_data[511:64];  dw_rem <= #TCQ (payload_len < 15 ) ? 11'b0 : payload_len - 11'hE; end
											4'b0011   : begin rd_data_s0[927:512] <= #TCQ rd_data[511:96];  dw_rem <= #TCQ (payload_len < 14 ) ? 11'b0 : payload_len - 11'hD; end
                                            4'b0100   : begin rd_data_s0[895:512] <= #TCQ rd_data[511:128]; dw_rem <= #TCQ (payload_len < 13 ) ? 11'b0 : payload_len - 11'hC; end
											4'b0101   : begin rd_data_s0[863:512] <= #TCQ rd_data[511:160]; dw_rem <= #TCQ (payload_len < 12 ) ? 11'b0 : payload_len - 11'hB; end
                                            4'b0110   : begin rd_data_s0[831:512] <= #TCQ rd_data[511:192]; dw_rem <= #TCQ (payload_len < 11 ) ? 11'b0 : payload_len - 11'hA; end
											4'b0111   : begin rd_data_s0[799:512] <= #TCQ rd_data[511:224]; dw_rem <= #TCQ (payload_len < 10 ) ? 11'b0 : payload_len - 11'h9; end			
                                            4'b1000   : begin rd_data_s0[767:512] <= #TCQ rd_data[511:256]; dw_rem <= #TCQ (payload_len < 9 )  ? 11'b0 : payload_len - 11'h8; end
											4'b1001   : begin rd_data_s0[735:512] <= #TCQ rd_data[511:288]; dw_rem <= #TCQ (payload_len < 8 )  ? 11'b0 : payload_len - 11'h7; end
											4'b1010   : begin rd_data_s0[703:512] <= #TCQ rd_data[511:320]; dw_rem <= #TCQ (payload_len < 7 )  ? 11'b0 : payload_len - 11'h6; end
											4'b1011   : begin rd_data_s0[671:512] <= #TCQ rd_data[511:352]; dw_rem <= #TCQ (payload_len < 6 )  ? 11'b0 : payload_len - 11'h5; end
                                            4'b1100   : begin rd_data_s0[639:512] <= #TCQ rd_data[511:384]; dw_rem <= #TCQ (payload_len < 5 )  ? 11'b0 : payload_len - 11'h4; end
											4'b1101   : begin rd_data_s0[607:512] <= #TCQ rd_data[511:416]; dw_rem <= #TCQ (payload_len < 4 )  ? 11'b0 : payload_len - 11'h3; end
                                            4'b1110   : begin rd_data_s0[575:512] <= #TCQ rd_data[511:448]; dw_rem <= #TCQ (payload_len < 3 )  ? 11'b0 : payload_len - 11'h2; end
											4'b1111   : begin rd_data_s0[543:512] <= #TCQ rd_data[511:480]; dw_rem <= #TCQ (payload_len < 2 )  ? 11'b0 : payload_len - 11'h1; end														
									  endcase
									  if (s_axis_cc_tready) 
									      rd_data_state <= #TCQ PIO_RD_DATA_WAIT; 
									  else
                                          rd_data_state <= #TCQ PIO_RD_DATA_RST; 	              										
							      end
								  else begin 
								      rd_data_s0   <= #TCQ rd_data_s0;
									  rd_data_state <= #TCQ PIO_RD_DATA_RST; 
								  end
						    end //PIO_RD_DATA_RST 
		  PIO_RD_DATA_WAIT : begin
		                     if (s_axis_cc_tready) begin 
		                          rd_data_ready <= #TCQ 1'b1; 
		                          if (dw_rem == 0 ) begin
								      rd_data_s0    <= #TCQ {512'b0, rd_data_s0[1535:512]};
									  rd_data_state  <= #TCQ PIO_RD_DATA_RST; 
								  end
								  else begin
								      case (req_addr[5:2])
									        4'b0000   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[1023:512]}; end
											4'b0001   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[991:512]};  end
											4'b0010   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[959:512]};  end
											4'b0011   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[927:512]};  end
                                            4'b0100   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[895:512]};  end
											4'b0101   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[863:512]};  end
                                            4'b0110   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[831:512]};  end
											4'b0111   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[799:512]};  end		
                                            4'b1000   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[767:512]};  end												
                                            4'b1001   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[735:512]};  end
											4'b1010   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[703:512]};  end
											4'b1011   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[671:512]};  end
											4'b1100   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[639:512]};  end
                                            4'b1101   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[607:512]};  end
											4'b1110   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[575:512]};  end
                                            4'b1111   : begin rd_data_s0 <= #TCQ {rd_data, rd_data_s0[543:512]};  end																						
									  endcase
									  if ((dw_rem -1)/16 == 0) 
                                          dw_rem        <= #TCQ 11'h0; 
                                      else 
									      dw_rem        <= #TCQ dw_rem - 11'h10; 
										  
                                      rd_data_state <= #TCQ PIO_RD_DATA_WAIT;  								  
								  end   
                             end
                             else begin 
                                          rd_data_state <= #TCQ PIO_RD_DATA_WAIT;  
                                          rd_data_s0 <= #TCQ rd_data_s0; //_prev;
				             end 									  
		                    end //PIO_RD_DATA_WAIT 
							 
		  default : begin rd_data_s0 <= #TCQ rd_data_s0; rd_data_state <= #TCQ PIO_RD_DATA_RST; end
          endcase		  
	  end
	  
  end  
  
  end

endgenerate

    

  // Calculate byte count based on byte enable

/* currently not used
  always @ (req_be) begin
     
    casex (req_be[3:0])

      4'b1xx1 : byte_count_fbe = 12'h004;
      4'b01x1 : byte_count_fbe = 12'h003;
      4'b1x10 : byte_count_fbe = 12'h003;
      4'b0011 : byte_count_fbe = 12'h002;
      4'b0110 : byte_count_fbe = 12'h002;
      4'b1100 : byte_count_fbe = 12'h002;
      4'b0001 : byte_count_fbe = 12'h001;
      4'b0010 : byte_count_fbe = 12'h001;
      4'b0100 : byte_count_fbe = 12'h001;
      4'b1000 : byte_count_fbe = 12'h001;
      4'b0000 : byte_count_fbe = 12'h001;
      default : byte_count_fbe = 12'h000;
    endcase

    casex (req_be[7:4])

      4'b1xx1 : byte_count_lbe = 12'h004;
      4'b01x1 : byte_count_lbe = 12'h003;
      4'b1x10 : byte_count_lbe = 12'h003;
      4'b0011 : byte_count_lbe = 12'h002;
      4'b0110 : byte_count_lbe = 12'h002;
      4'b1100 : byte_count_lbe = 12'h002;
      4'b0001 : byte_count_lbe = 12'h001;
      4'b0010 : byte_count_lbe = 12'h001;
      4'b0100 : byte_count_lbe = 12'h001;
      4'b1000 : byte_count_lbe = 12'h001;
      4'b0000 : byte_count_lbe = 12'h001;
      default : byte_count_lbe = 12'h000;

    endcase

  end
*/

  // Calculate the byte_count for 1DW or 2DW packets

//   assign byte_count = (payload_len == 1)? (byte_count_lbe + byte_count_fbe) : byte_count_fbe; //currently not used
  // Present address and byte enable to memory module
  
  
  
// calculating byte count based on first_be, last_be and payload length 
always @(req_be or payload_len) begin 

casex (req_be [7:0])

       8'b00001xx1   : byte_count = 13'h4; 
       8'b000001x1   : byte_count = 13'h3; 
       8'b00001x10   : byte_count = 13'h3; 
       8'b00000011   : byte_count = 13'h2; 
       8'b00000110   : byte_count = 13'h2; 
       8'b00001100   : byte_count = 13'h2; 
       8'b00000001   : byte_count = 13'h1; 
       8'b00000010   : byte_count = 13'h1; 
       8'b00000100   : byte_count = 13'h1; 
       8'b00001000   : byte_count = 13'h1; 
       8'b00000000   : byte_count = 13'h1; 
       8'b1xxxxxx1   : byte_count = (payload_len*4); 
       8'b01xxxxx1   : byte_count = (payload_len*4)-4'h1;
       8'b001xxxx1   : byte_count = (payload_len*4)-4'h2; 
       8'b0001xxx1   : byte_count = (payload_len*4)-4'h3; 
       8'b1xxxxx10   : byte_count = (payload_len*4)-4'h1; 
       8'b01xxxx10   : byte_count = (payload_len*4)-4'h2; 
       8'b001xxx10   : byte_count = (payload_len*4)-4'h3; 
       8'b0001xx10   : byte_count = (payload_len*4)-4'h4; 
       8'b1xxxx100   : byte_count = (payload_len*4)-4'h2; 
       8'b01xxx100   : byte_count = (payload_len*4)-4'h3; 
       8'b001xx100   : byte_count = (payload_len*4)-4'h4; 
       8'b0001x100   : byte_count = (payload_len*4)-4'h5; 
       8'b1xxx1000   : byte_count = (payload_len*4)-4'h3; 
       8'b01xx1000   : byte_count = (payload_len*4)-4'h4; 
       8'b001x1000   : byte_count = (payload_len*4)-4'h5; 
       8'b00011000   : byte_count = (payload_len*4)-4'h6;
       default       : byte_count = 13'h0; 

endcase


end



  // Calculate lower address based on  byte enable

  always @ (rd_be or req_addr or req_compl_wd_qqq) begin

    casex ({req_compl_wd_qqq, rd_be[3:0]})

        5'b1_0000 : lower_addr = {req_addr[6:2], 2'b00};
        5'b1_xxx1 : lower_addr = {req_addr[6:2], 2'b00};
        5'b1_xx10 : lower_addr = {req_addr[6:2], 2'b01};
        5'b1_x100 : lower_addr = {req_addr[6:2], 2'b10};
        5'b1_1000 : lower_addr = {req_addr[6:2], 2'b11};
        5'b0_xxxx : lower_addr = 8'h0;
    endcase

  end
  
  always @ (rd_be or req_addr) begin
    
     casex ({rd_be[3:0]})
  
          4'b0000 : lower_addr_dw = {req_addr[6:2], 2'b00};
          4'bxxx1 : lower_addr_dw = {req_addr[6:2], 2'b00};
          4'bxx10 : lower_addr_dw = {req_addr[6:2], 2'b01};
          4'bx100 : lower_addr_dw = {req_addr[6:2], 2'b10};
          4'b1000 : lower_addr_dw = {req_addr[6:2], 2'b11};
          4'bxxxx : lower_addr_dw = 8'h0;
      endcase
  
    end
    

  
  always @  (lower_addr) begin

    casex (lower_addr[4:2])

      3'b000 : tkeep = (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" ) ? 16'h1 :16'h1; 
      3'b001 : tkeep = (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" ) ? 16'h3 :16'h1; 
      3'b010 : tkeep = (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" ) ? 16'h7 :16'h1; 
      3'b011 : tkeep = (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" ) ? 16'hf :16'h1; 
      3'b100 : tkeep = (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" ) ? 16'h1f :16'h1; 
      3'b101 : tkeep = (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" ) ? 16'h3f :16'h1; 
      3'b110 : tkeep = (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" ) ? 16'h7f :16'h1; 
      3'b111 : tkeep = (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" ) ? 16'hff :16'h1; 
    endcase

  end


  always @ (posedge user_clk)
  begin

    if (!reset_n) begin

      req_compl_q     <= #TCQ 1'b0;
      req_compl_qq    <= #TCQ 1'b0;
      req_compl_wd_q  <= #TCQ 1'b0;
      req_compl_wd_qq <= #TCQ 1'b0;
      req_compl_wd_qqq <= #TCQ 1'b0;
      req_compl_wd_qqqq <= #TCQ 1'b0; 
      req_compl_wd_qqqqq <= #TCQ 1'b0; 
      tkeep_q         <= #TCQ 16'h0F;
      req_compl_ur_q  <= #TCQ 1'b0;
      req_compl_ur_qq <= #TCQ 1'b0;

    end else begin

      lower_addr_q    <= #TCQ lower_addr;
      tkeep_q         <= #TCQ tkeep;
      tkeep_qq         <= #TCQ tkeep_q;
      lower_addr_qq   <= #TCQ lower_addr_q;
      req_compl_q     <= #TCQ req_compl;
      req_compl_qq    <= #TCQ req_compl_q;
      req_compl_wd_q  <= #TCQ req_compl_wd;
      req_compl_wd_qq <= #TCQ req_compl_wd_q;
      req_compl_wd_qqq <= #TCQ req_compl_wd_qq;
      req_compl_wd_qqqq <= #TCQ req_compl_wd_qqq; 
      req_compl_wd_qqqqq <= #TCQ req_compl_wd_qqqq;
      req_compl_ur_q  <= #TCQ req_compl_ur;
      req_compl_ur_qq <= #TCQ req_compl_ur_q;
    end

  end



  // Logic to compute the Parity of the CC and the RQ channel

  generate
  begin
    if(AXISTEN_IF_RQ_PARITY_CHECK == 1)
    begin

      genvar a;
      for(a=0; a< STRB_WIDTH; a = a + 1) // Parity needs to be computed for every byte of data
      begin : parity_assign
        assign s_axis_rq_tparity[a] = !(  s_axis_rq_tdata[(8*a)+ 0] ^ s_axis_rq_tdata[(8*a)+ 1]
                                 ^ s_axis_rq_tdata[(8*a)+ 2] ^ s_axis_rq_tdata[(8*a)+ 3]
                                 ^ s_axis_rq_tdata[(8*a)+ 4] ^ s_axis_rq_tdata[(8*a)+ 5]
                                 ^ s_axis_rq_tdata[(8*a)+ 6] ^ s_axis_rq_tdata[(8*a)+ 7]);

        assign s_axis_cc_tparity[a] = !(  s_axis_cc_tdata[(8*a)+ 0] ^ s_axis_cc_tdata[(8*a)+ 1]
                                 ^ s_axis_cc_tdata[(8*a)+ 2] ^ s_axis_cc_tdata[(8*a)+ 3]
                                 ^ s_axis_cc_tdata[(8*a)+ 4] ^ s_axis_cc_tdata[(8*a)+ 5]
                                 ^ s_axis_cc_tdata[(8*a)+ 6] ^ s_axis_cc_tdata[(8*a)+ 7]);
      end
    end else begin
      genvar b;
      for(b=0; b< STRB_WIDTH; b = b + 1) // Drive parity low if not enabled
      begin : parity_assign
        assign s_axis_rq_tparity[b] = {PARITY_WIDTH{1'b0}};
        assign s_axis_cc_tparity[b] = {PARITY_WIDTH{1'b0}};
      end
    end

  end
  endgenerate


  generate 
  if( AXISTEN_IF_WIDTH == 2'b11) // 512 -bit interface
  begin
    assign s_axis_cc_tuser   = {(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity : 64'b0), s_axis_cc_tuser_wo_parity[16:0]};
  end
  else
  begin
    assign s_axis_cc_tuser   = {(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity : 32'b0), s_axis_cc_tuser_wo_parity[0]};
  end
  endgenerate

  generate // 512 bit Interface

  if( AXISTEN_IF_WIDTH == 2'b11) // 512 -bit interface
  begin
   
    always @ ( posedge user_clk )
    begin

      if(!reset_n ) begin

        state                   <= #TCQ PIO_TX_RST_STATE;
        rd_data_reg             <= #TCQ 32'b0;
        s_axis_cc_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
        s_axis_cc_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
        s_axis_cc_tlast         <= #TCQ 1'b0;
        s_axis_cc_tvalid        <= #TCQ 1'b0;
        s_axis_rq_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
        s_axis_rq_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
        s_axis_rq_tlast         <= #TCQ 1'b0;
        s_axis_rq_tvalid        <= #TCQ 1'b0;
        s_axis_cc_tuser_wo_parity <= #TCQ {AXI4_CC_TUSER_WIDTH{1'b0}};
        s_axis_rq_tuser         <= #TCQ {AXI4_RQ_TUSER_WIDTH{1'b0}};
        cfg_msg_transmit        <= #TCQ 1'b0;
        cfg_msg_transmit_type   <= #TCQ 3'b0;
        cfg_msg_transmit_data   <= #TCQ 32'b0;
        compl_done              <= #TCQ 1'b0;
        dword_count             <= #TCQ 1'b0;
        trn_sent                <= #TCQ 1'b0;
		len_i                   <= #TCQ 11'b0;
        rd_data_s1              <= #TCQ 96'b0; 

      end else begin // reset_else_block

            case (state)

              PIO_TX_RST_STATE : begin  // Reset_State

                state                   <= #TCQ PIO_TX_RST_STATE;
                s_axis_cc_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
                s_axis_cc_tkeep         <= #TCQ {KEEP_WIDTH{1'b1}};
                s_axis_cc_tlast         <= #TCQ 1'b0;
                s_axis_cc_tvalid        <= #TCQ 1'b0;
                s_axis_cc_tuser_wo_parity <= #TCQ 81'b0;
                s_axis_rq_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
                s_axis_rq_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
                s_axis_rq_tlast         <= #TCQ 1'b0;
                s_axis_rq_tvalid        <= #TCQ 1'b0;
                s_axis_rq_tuser         <= #TCQ 60'b0;
                cfg_msg_transmit        <= #TCQ 1'b0;
                cfg_msg_transmit_type   <= #TCQ 3'b0;
                cfg_msg_transmit_data   <= #TCQ 32'b0;
                compl_done              <= #TCQ 1'b0;
                trn_sent                <= #TCQ 1'b0;
                dword_count             <= #TCQ 1'b0;
				len_i                   <= #TCQ payload_len; 

                if(req_compl) begin
                   state <= #TCQ PIO_TX_COMPL_C1;
                end else if (req_compl_wd) begin
                   state <= #TCQ PIO_TX_COMPL_WD_C1;
                end else if (req_compl_ur) begin
                   state <= #TCQ PIO_TX_CPL_UR_C1;
                end else if (gen_transaction) begin
                   state <= #TCQ PIO_TX_MRD_C1;
                end
              end // PIO_TX_RST_STATE

              PIO_TX_COMPL_C1 : begin // Completion Without Payload - Alignment doesnt matter
                                   // Sent in a Single Beat When Interface Width is 512 bit
                if(req_compl_qq) begin
                  s_axis_cc_tvalid  <= #TCQ 1'b1;
                  s_axis_cc_tlast   <= #TCQ 1'b1;
                  s_axis_cc_tkeep   <= #TCQ 8'h07;
                  s_axis_cc_tdata   <= #TCQ {256'b0,160'b0,        // Tied to 0 for 3DW completion descriptor
                                             1'b0,          // Force ECRC
                                             1'b0, req_attr,// 3- bits
                                             req_tc,        // 3- bits
                                             1'b0,          // Completer ID to control selection of Client
                                                            // Supplied Bus number
                                             8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                             8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                             (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                             8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                             req_rid,       // Requester ID - 16 bits
                                             1'b0,          // Rsvd
                                             1'b0,          // Posioned completion
                                             3'b000,        // SuccessFull completion
                                             (req_mem ? (11'h1 + payload_len) : 11'b0),         // DWord Count 0 - IO Write completions
                                             2'b0,          // Rsvd
                                             1'b0,          // Locked Read Completion
                                             13'h0004,      // Byte Count
                                             6'b0,          // Rsvd
                                             req_at,        // Adress Type - 2 bits
                                             1'b0,          // Rsvd
                                             lower_addr};   // Starting address of the mem byte - 7 bits
                  s_axis_cc_tuser_wo_parity   <= #TCQ {/*(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity :*/ 64'b0, // parity 64 bit -[80:17]
                                                1'b0,                    // Discontinue          
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b00,                   // is_eop[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b00};                  // is_sop[1:0]


                  if(s_axis_cc_tready) begin
                    state <= #TCQ PIO_TX_RST_STATE;
                    compl_done        <= #TCQ 1'b1;
                  end else begin
                    state <= #TCQ PIO_TX_COMPL_C1;
                  end
                end

              end  //PIO_TX_COMPL

              PIO_TX_COMPL_WD_C1 : begin  // Completion With Payload
                                       // Possible Scenario's Payload can be 1 DW or 2 DW
                                       // Alignment can be either of Dword aligned or address aligned

// Support n-DW 
             // Requires three clock cycle to get the first rd_data from the BRAM 
             if (req_compl_wd_qqqq) begin
                 if(AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE") begin //DWORD_Aligned mode
					   s_axis_cc_tvalid  <= #TCQ 1'b1; 
					   s_axis_cc_tdata   <= #TCQ {rd_data_s0[415:0],       // 13 DW Read Data 
                                                 1'b0,          // Force ECRC
                                                 1'b0, req_attr,// 3- bits
                                                 req_tc,        // 3- bits
                                                 1'b0,          // Completer ID to control selection of Client
                                                                // Supplied Bus number
                                                 8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                                 8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                                 (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                                 8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                                 req_rid,       // Requester ID - 16 bits
                                                 1'b0,          // Rsvd
                                                 1'b0,          // Posioned completion
                                                 3'b000,        // SuccessFull completion
                                                 (req_mem ? (payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                                 2'b0,          // Rsvd
                                                 (req_mem_lock? 1'b1 : 1'b0),  // Locked Read Completion
                                                 byte_count,               //13'h0004,      // Byte Count
                                                 6'b0,          // Rsvd
                                                 req_at,        // Adress Type - 2 bits
                                                 1'b0,          // Rsvd
                                                 lower_addr_dw};   // Starting address of the mem byte - 7 bits
                      
					  s_axis_cc_tuser_wo_parity <= #TCQ {64'b0, // parity 64 bit -[80:17]
                                                         1'b0,                    // Discontinue          
                                                         4'b0000,                 // is_eop1_ptr
                                                         4'b0000,                 // is_eop0_ptr
                                                         2'b00,                   // is_eop[1:0]
                                                         2'b00,                   // is_sop1_ptr[1:0]
                                                         2'b00,                   // is_sop0_ptr[1:0]
                                                         2'b01};                  // is_sop[1:0]
					  if (s_axis_cc_tready) begin
					    if (len_i < 14 ) begin
					      case (len_i) 
					             1  : s_axis_cc_tkeep <= #TCQ 16'h000F; 
							     2  : s_axis_cc_tkeep <= #TCQ 16'h001F; 
							     3  : s_axis_cc_tkeep <= #TCQ 16'h003F; 
							     4  : s_axis_cc_tkeep <= #TCQ 16'h007F; 
							     5  : s_axis_cc_tkeep <= #TCQ 16'h00FF; 
								 6  : s_axis_cc_tkeep <= #TCQ 16'h01FF; 
							     7  : s_axis_cc_tkeep <= #TCQ 16'h03FF; 
							     8  : s_axis_cc_tkeep <= #TCQ 16'h07FF; 
							     9  : s_axis_cc_tkeep <= #TCQ 16'h0FFF; 
							    10  : s_axis_cc_tkeep <= #TCQ 16'h1FFF; 
					            11  : s_axis_cc_tkeep <= #TCQ 16'h3FFF; 
							    12  : s_axis_cc_tkeep <= #TCQ 16'h7FFF; 
							    13  : s_axis_cc_tkeep <= #TCQ 16'hFFFF;
					      endcase
						  s_axis_cc_tlast <= #TCQ 1'b1; 
                          state           <= #TCQ PIO_TX_RST_STATE;		
                          rd_data_s1      <= #TCQ 96'h0; 	
                          len_i           <= #TCQ 11'b0; 	
                          compl_done      <= #TCQ 1'b1; 						  
				        end
						else begin 
						  s_axis_cc_tkeep <= #TCQ 16'hFFFF; 
						  s_axis_cc_tlast <= #TCQ 1'b0;
						  state           <= #TCQ PIO_TX_COMPL_WD_N_DW; 
						  rd_data_s1      <= #TCQ rd_data_s0[511:416];
                          len_i           <= #TCQ len_i - 11'hD; 	
                          compl_done      <= #TCQ 1'b0; 						  
						end
					  end
					 else begin 
					      state           <= #TCQ PIO_TX_COMPL_WD_C1; 
				     end
					 
			     end // DWORD Aligned mode end              
             end 

              end // PIO_TX_COMPL_WD

              PIO_TX_COMPL_PYLD : begin // FIXME : Completion with 1DW Payload in Address Aligned mode

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ tkeep_q;
                s_axis_cc_tdata[31:0]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b000) ? {rd_data} : ((AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE" ) ? rd_data : 32'b0);
                s_axis_cc_tdata[63:32]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b001) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[95:64]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b010) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[127:96]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b011) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[159:128]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b100) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[191:160]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b101) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[223:192]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b110) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[255:224]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b111) ? {rd_data} : {32'b0};

                s_axis_cc_tuser_wo_parity <= #TCQ {/*(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity :*/ 64'b0, // parity 64 bit -[80:17]
                                                1'b0,                    // Discontinue          
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b00,                   // is_eop[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b00};                  // is_sop[1:0]

                if(s_axis_cc_tready) begin
                  state        <= #TCQ PIO_TX_RST_STATE;
                  compl_done   <= #TCQ 1'b1;
                end else begin
                  state <= #TCQ PIO_TX_COMPL_PYLD;
                end
              end // PIO_TX_COMPL_PYLD

              PIO_TX_COMPL_WD_2DW : begin // Completion with 2DW Payload in DWord Aligned mode
                                          // Requires 2 states to get the 2DW Payload

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ 8'h1F;
                s_axis_cc_tdata   <= #TCQ {256'b0,96'b0,         // Tied to 0 for 3DW completion descriptor with 2DW Payload
                                           rd_data,       // 32 bit read data
                                           rd_data_reg,   // 32- bit read data
                                           1'b0,          // Force ECRC
                                           1'b0, req_attr,// 3- bits
                                           req_tc,        // 3- bits
                                           1'b0,          // Completer ID to control selection of Client
                                                          // Supplied Bus number
                                           8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                           8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                           (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                           8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                           req_rid,       // Requester ID - 16 bits
                                           1'b0,          // Rsvd
                                           1'b0,          // Posioned completion
                                           3'b000,        // SuccessFull completion
                                           (req_mem ? (11'h1 + payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                           2'b0,          // Rsvd
                                           (req_mem_lock? 1'b1 : 1'b0),   // Locked Read Completion
                                           byte_count,                //13'h0004,      // Byte Count
                                           6'b0,          // Rsvd
                                           req_at,        // Adress Type - 2 bits
                                           1'b0,          // Rsvd
                                           lower_addr_q};   // Starting address of the mem byte - 7 bits
                s_axis_cc_tuser_wo_parity <= #TCQ {/*(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity :*/ 64'b0, // parity 64 bit -[80:17]
                                                1'b0,                    // Discontinue          
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b00,                   // is_eop[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b00};                  // is_sop[1:0]


                if(s_axis_cc_tready) begin
                  state        <= #TCQ PIO_TX_RST_STATE;
                  compl_done   <= #TCQ 1'b1;
                end else begin
                  state <= #TCQ PIO_TX_COMPL_WD_2DW;
                  dword_count <= #TCQ 1'b1; // To increment the Read Address
                  rd_data_reg <= #TCQ rd_data; // store the current read data
                end

              end //  PIO_TX_COMPL_WD_2DW

              PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C1 : begin 

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ (lower_addr_q[3:2]==2'b00)   ?  16'h003F :
                                          (lower_addr_q[3:2]==2'b01)   ?  16'h007F :
                                          (lower_addr_q[3:2]==2'b10)   ?  16'h00FF :
                                          /*(lower_addr_q[3:2]==2'b10) ?*/16'h01FF;

                s_axis_cc_tdata[511:128] <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b00)   ? {256'b0, 64'b0, rd_data,rd_data_reg} 
                                                :(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b01)   ? {256'b0, 32'b0, rd_data,rd_data_reg, 32'b0} 
                                                :(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b10)   ? {256'b0,        rd_data,rd_data_reg, 64'b0} 
                                                :/*(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b11)?*/{224'b0,        rd_data,rd_data_reg, 96'b0};
                s_axis_cc_tdata[127:0] <= #TCQ {32'b0,        // Tied to 0 for 3DW completion descriptor
                                           1'b0,          // Force ECRC
                                           1'b0, req_attr,// 3- bits
                                           req_tc,        // 3- bits
                                           1'b0,          // Completer ID to control selection of Client
                                                          // Supplied Bus number
                                           8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                           8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                           (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                           8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                           req_rid,       // Requester ID - 16 bits
                                           1'b0,          // Rsvd
                                           1'b0,          // Posioned completion
                                           3'b000,        // SuccessFull completion
                                           (req_mem ? (11'h1 + payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                           2'b0,          // Rsvd
                                           (req_mem_lock? 1'b1 : 1'b0),      // Locked Read Completion
                                           byte_count,               //13'h0004,      // Byte Count
                                           6'b0,          // Rsvd
                                           req_at,        // Adress Type - 2 bits
                                           1'b0,          // Rsvd
                                           lower_addr_q};   // Starting address of the mem byte - 7 bits

                s_axis_cc_tuser_wo_parity <= #TCQ {/*(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity :*/ 64'b0, // parity 64 bit -[80:17]
                                          1'b0,                    // Discontinue          
                                          4'b0000,                 // is_eop1_ptr
                                          4'b0000,                 // is_eop0_ptr
                                          2'b01,                   // is_eop[1:0]
                                          2'b00,                   // is_sop1_ptr[1:0]
                                          2'b00,                   // is_sop0_ptr[1:0]
                                          2'b01};                  // is_sop[1:0]

                dword_count       <= #TCQ 1'b0;
                if(s_axis_cc_tready) begin
                 state        <= #TCQ PIO_TX_RST_STATE;
                 compl_done   <= #TCQ 1'b1;
                end else begin
                  state <= #TCQ PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C1;
                end // PIO_TX_COMPL_WD_2DW_ADDR_ALGN
              end


              PIO_TX_CPL_UR_C1 : begin // Completions with UR - Alignement mode matters here

                if (req_compl_ur_qq) begin

                     s_axis_cc_tvalid  <= #TCQ 1'b1;
                     s_axis_cc_tlast   <= #TCQ 1'b1;
                     s_axis_cc_tkeep   <= #TCQ 8'hFF;
                     s_axis_cc_tdata   <= #TCQ {256'b0,req_des_qword1, // 64 bits - Descriptor of the request 2 DW
                                                req_des_qword0, // 64 bits - Descriptor of the request 2 DW
                                                8'b0, // Rsvd
                                                req_des_tph_st_tag,   // TPH Steering tag - 8 bits
                                                5'b0,  // Rsvd
                                                req_des_tph_type,    // TPH type - 2 bits
                                                req_des_tph_present, // TPH present - 1 bit
                                                req_be,          // Request Byte enables - 8bits
                                                1'b0,          // Force ECRC
                                                1'b0, req_attr,// 3- bits
                                                req_tc,        // 3- bits
                                                1'b0,          // Completer ID to control selection of Client
                                                               // Supplied Bus number
                                                8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                                8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                                (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                                8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                                req_rid,       // Requester ID - 16 bits
                                                1'b0,          // Rsvd
                                                1'b0,          // Posioned completion
                                                3'b001,        // Completion Status - UR
                                                11'h005,       // DWord Count -55
                                                2'b0,          // Rsvd
                                                (req_mem_lock? 1'b1 : 1'b0),   // Locked Read Completion
                                                13'h0014,      // Byte Count - 20 bytes of Payload
                                                6'b0,          // Rsvd
                                                req_at,        // Adress Type - 2 bits
                                                1'b0,          // Rsvd
                                                lower_addr};   // Starting address of the mem byte - 7 bits

                     s_axis_cc_tuser_wo_parity <= #TCQ {/*(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity :*/ 64'b0, // parity 64 bit -[80:17]
                                                1'b0,                    // Discontinue          
                                                4'b0000,                 // is_eop1_ptr
                                                4'b0000,                 // is_eop0_ptr
                                                2'b00,                   // is_eop[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b00};                  // is_sop[1:0]

                     if(s_axis_cc_tready) begin
                       state        <= #TCQ PIO_TX_RST_STATE;
                       compl_done   <= #TCQ 1'b1;
                     end else begin
                       state        <= #TCQ PIO_TX_CPL_UR_C1;
                     end
                end

              end // PIO_TX_CPL_UR

//             PIO_TX_CPL_UR_PYLD_C1 : begin // Completion for UR with addr aligned mode
//
//               s_axis_cc_tvalid  <= #TCQ 1'b1;
//               s_axis_cc_tlast   <= #TCQ 1'b1;
//               s_axis_cc_tkeep   <= #TCQ 8'h1F;
//               s_axis_cc_tdata   <= #TCQ {96'b0,
//                                          req_des_qword1, // 64 bits - Descriptor of the request 2 DW
//                                          req_des_qword0, // 64 bits - Descriptor of the request 2 DW
//                                          8'b0, // Rsvd
//                                          req_des_tph_st_tag,   // TPH Steering tag - 8 bits
//                                          5'b0,  // Rsvd
//                                          req_des_tph_type,    // TPH type - 2 bits
//                                          req_des_tph_present, // TPH present - 1 bit
//                                          req_be};          // Request Byte enables - 8bits
//               s_axis_cc_tuser_wo_parity   <= #TCQ {1'b0, (AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity : 32'b0)};
//               if(s_axis_cc_tready) begin
//                 state        <= #TCQ PIO_TX_RST_STATE;
//                 compl_done   <= #TCQ 1'b1;
//               end
//               else
//                 state        <= #TCQ PIO_TX_CPL_UR_PYLD_C1;
//
//             end // PIO_TX_CPL_UR_PYLD


              PIO_TX_MRD_C1 : begin // Not used Memory Read Transaction - Alignment Doesnt Matter

                s_axis_rq_tvalid  <= #TCQ 1'b1;
                s_axis_rq_tlast   <= #TCQ 1'b1;
                s_axis_rq_tkeep   <= #TCQ 8'h0F;  // 4DW Descriptor For Memory Transaction Alone
                s_axis_rq_tdata   <= #TCQ {256'b0,128'b0,       // 4DW Unused
                                           1'b0,         // Force ECRC
                                           3'b000,       // Attributes
                                           3'b000,       // Traffic Class
                                           1'b0,         // RID Enable to use the Client supplied Bus/Device/Func No
                                           16'b0,        // Completer -ID, set only for Completers or ID based routing
                                           (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                           8'h00 : req_tag),  // Select Client Tag or core's internal tag
                                           8'h00,             // Req Bus No- used only when RID enable = 1
                                           8'h00,             // Req Dev/Func no - used only when RID enable = 1
                                           1'b0,              // Poisoned Req
                                           4'b0000,           // Req Type for MRd Req
                                           11'h001,           // DWORD Count
                                           62'h2AAA_BBBB_CCCC_DDDD, // Memory Read Address [62 bits]
                                           2'b00};             //AT -> 00- Untranslated Address

                s_axis_rq_tuser          <= #TCQ {(AXISTEN_IF_RQ_PARITY_CHECK ? s_axis_rq_tparity : 64'b0), // Parity
                                                  6'b101010,      // Seq Number 1
                                                  6'b101010,      // Seq Number 0
                                                  16'h0000,        // TPH Steering Tag
                                                  2'b0,         // TPH indirect Tag Enable
                                                  4'b0000,         // TPH Type
                                                  2'b00,         // TPH Present
                                                  1'b0,         // Discontinue
                                                  4'b0000, //eop1 ptr   
                                                  4'b0000, //eop0 ptr  
                                                  2'b01, //is EOP?  
                                                  2'b10, //sop1 ptr   
                                                  2'b00, //sop0 ptr   
                                                  2'b01,  //is SOP 
                                                  4'b0000,       // Byte Lane number in case of Address Aligned mode
                                                  8'h0,    // Last BE of the Read Data
                                                  8'hF }; // First BE of the Read Data


                if(s_axis_rq_tready) begin
                  state <= #TCQ PIO_TX_RST_STATE;
                  trn_sent <= #TCQ 1'b1;
                end
                else
                  state <= #TCQ PIO_TX_MRD_C1;

              end // PIO_TX_MRD
			  
			  PIO_TX_COMPL_WD_N_DW : begin
               if ((len_i-1)/16 == 0) begin 
                   s_axis_cc_tvalid  <= #TCQ 1'b1;
                   s_axis_cc_tlast   <= #TCQ 1'b1;
                   s_axis_cc_tuser_wo_parity <= #TCQ {64'b0, // parity 64 bit -[80:17]
                                                1'b0,                    // Discontinue          
                                                4'b0000,                 // is_eop1_ptr
                                                ((len_i==16) ? 4'b1111 : 
												(len_i==15) ? 4'b1110 : 
												(len_i==14) ? 4'b1101 : 
												(len_i==13) ? 4'b1100 : 
												(len_i==12) ? 4'b1011 : 
												(len_i==11) ? 4'b1010 : 
												(len_i==10) ? 4'b1001 :
												(len_i==9) ? 4'b1000 :
												(len_i==8) ? 4'b0111 :
												(len_i==7) ? 4'b0110 :
												(len_i==6) ? 4'b0101 :
												(len_i==5) ? 4'b0100 :
												(len_i==4) ? 4'b0011 : 
												(len_i==3) ? 4'b0010 :
                                                (len_i==2) ? 4'b0001 : 4'b0000 ), // is_eop0_ptr
                                                2'b01,                   // is_eop[1:0]
                                                2'b00,                   // is_sop1_ptr[1:0]
                                                2'b00,                   // is_sop0_ptr[1:0]
                                                2'b00};                  // is_sop[1:0]
                   case (len_i) 
                          1      : begin s_axis_cc_tdata <= #TCQ {480'b0, rd_data_s1[31:0]};
                                         s_axis_cc_tkeep <= #TCQ 16'h0001; 
                                   end
                          2      : begin s_axis_cc_tdata <= #TCQ {448'b0, rd_data_s1[63:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h0003; 
                                   end
                          3      : begin s_axis_cc_tdata <= #TCQ {416'b0, rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h0007; 
                                   end
                          4      : begin s_axis_cc_tdata <= #TCQ {384'b0, rd_data_s0[31:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h000F; 
                                   end
                          5      : begin s_axis_cc_tdata <= #TCQ {352'b0, rd_data_s0[63:0],rd_data_s1[95:0]};
                                         s_axis_cc_tkeep <= #TCQ 16'h001F; 
                                   end
                          6      : begin s_axis_cc_tdata <= #TCQ {320'b0, rd_data_s0[95:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h003F; 
                                   end
                          7      : begin s_axis_cc_tdata <= #TCQ {288'b0, rd_data_s0[127:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h007F; 
                                   end
                          8      : begin s_axis_cc_tdata <= #TCQ {256'b0,rd_data_s0[159:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h00FF; 
                                   end
			  9      : begin s_axis_cc_tdata <= #TCQ {224'b0,rd_data_s0[191:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h01FF; 
                                   end	
                         10      : begin s_axis_cc_tdata <= #TCQ {192'b0,rd_data_s0[223:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h03FF; 
                                   end
                         11      : begin s_axis_cc_tdata <= #TCQ {160'b0,rd_data_s0[255:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h07FF; 
                                   end		
                         12      : begin s_axis_cc_tdata <= #TCQ {128'b0,rd_data_s0[287:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h0FFF; 
                                   end	
                         13      : begin s_axis_cc_tdata <= #TCQ {96'b0,rd_data_s0[319:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h1FFF; 
                                   end	
                         14      : begin s_axis_cc_tdata <= #TCQ {64'b0,rd_data_s0[351:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h3FFF; 
                                   end	
                         15      : begin s_axis_cc_tdata <= #TCQ {32'b0,rd_data_s0[383:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'h7FFF; 
                                   end	
                         16      : begin s_axis_cc_tdata <= #TCQ {rd_data_s0[415:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 16'hFFFF; 
                                   end									   
                   endcase
                   len_i <= #TCQ 11'b0;
                   if(s_axis_cc_tready) begin
                       state        <= #TCQ PIO_TX_RST_STATE;
                       compl_done   <= #TCQ 1'b1;
					   rd_data_s1   <= #TCQ rd_data_s0[511:416]; 
                   end else begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW; 
                   end               
               end // len_i <= 16
               else begin 
                   s_axis_cc_tvalid            <= #TCQ 1'b1; 
                   s_axis_cc_tlast             <= #TCQ 1'b0; 
                   s_axis_cc_tuser_wo_parity   <= #TCQ {/*(AXISTEN_IF_CC_PARITY_CHECK ? s_axis_cc_tparity :*/ 64'b0, // parity 64 bit -[80:17]
                                                          1'b0,                    // Discontinue          
                                                          4'b0000,                 // is_eop1_ptr
                                                          4'b0000,                 // is_eop0_ptr
                                                          2'b00,                   // is_eop[1:0]
                                                          2'b00,                   // is_sop1_ptr[1:0]
                                                          2'b00,                   // is_sop0_ptr[1:0]
                                                          2'b00};                  // is_sop[1:0]
                   s_axis_cc_tkeep             <= #TCQ 16'hFFFF; 
                   s_axis_cc_tdata             <= #TCQ {rd_data_s0[415:0], rd_data_s1[95:0]}; 
                   rd_data_s1                  <= #TCQ rd_data_s0[511:416]; 
                   len_i                       <= #TCQ len_i - 11'h10; 
                   if(s_axis_cc_tready) begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW;
                       compl_done   <= #TCQ 1'b0;
                   end else begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW; 
                   end     
               end    
            
           end //PIO_TX_COMPL_WD_N_DW

            endcase

          end // reset_else_block

      end // Always Block Ends
    end // If AXISTEN_IF_WIDTH = 512
  else if( AXISTEN_IF_WIDTH == 2'b10) // 256-bit interface
  begin

    always @ ( posedge user_clk )
    begin

      if(!reset_n ) begin

        state                   <= #TCQ PIO_TX_RST_STATE;
        rd_data_reg             <= #TCQ 32'b0;
        s_axis_cc_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
        s_axis_cc_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
        s_axis_cc_tlast         <= #TCQ 1'b0;
        s_axis_cc_tvalid        <= #TCQ 1'b0;
        s_axis_rq_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
        s_axis_rq_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
        s_axis_rq_tlast         <= #TCQ 1'b0;
        s_axis_rq_tvalid        <= #TCQ 1'b0;
        s_axis_cc_tuser_wo_parity <= #TCQ {AXI4_CC_TUSER_WIDTH{1'b0}};
        s_axis_rq_tuser         <= #TCQ {AXI4_RQ_TUSER_WIDTH{1'b0}};
        cfg_msg_transmit        <= #TCQ 1'b0;
        cfg_msg_transmit_type   <= #TCQ 3'b0;
        cfg_msg_transmit_data   <= #TCQ 32'b0;
        compl_done              <= #TCQ 1'b0;
        dword_count             <= #TCQ 1'b0;
        trn_sent                <= #TCQ 1'b0;
        len_i                   <= #TCQ 11'b0;
        rd_data_s1              <= #TCQ 96'b0; 
      end else begin // reset_else_block

            case (state)

              PIO_TX_RST_STATE : begin  // Reset_State

                state                   <= #TCQ PIO_TX_RST_STATE;
                s_axis_cc_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
                s_axis_cc_tkeep         <= #TCQ {KEEP_WIDTH{1'b1}};
                s_axis_cc_tlast         <= #TCQ 1'b0;
                s_axis_cc_tvalid        <= #TCQ 1'b0;
                s_axis_cc_tuser_wo_parity <= #TCQ 81'b0;
                s_axis_rq_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
                s_axis_rq_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
                s_axis_rq_tlast         <= #TCQ 1'b0;
                s_axis_rq_tvalid        <= #TCQ 1'b0;
                s_axis_rq_tuser         <= #TCQ 60'b0;
                cfg_msg_transmit        <= #TCQ 1'b0;
                cfg_msg_transmit_type   <= #TCQ 3'b0;
                cfg_msg_transmit_data   <= #TCQ 32'b0;
                compl_done              <= #TCQ 1'b0;
                trn_sent                <= #TCQ 1'b0;
                dword_count             <= #TCQ 1'b0;
                len_i                   <= #TCQ payload_len; 

                if(req_compl) begin
                   state <= #TCQ PIO_TX_COMPL_C1;
                end else if (req_compl_wd) begin
                   state <= #TCQ PIO_TX_COMPL_WD_C1;
                end else if (req_compl_ur) begin
                   state <= #TCQ PIO_TX_CPL_UR_C1;
                end else if (gen_transaction) begin
                   state <= #TCQ PIO_TX_MRD_C1;
                end
              end // PIO_TX_RST_STATE

              PIO_TX_COMPL_C1 : begin // Completion Without Payload - Alignment doesnt matter
                                   // Sent in a Single Beat When Interface Width is 256 bit
                if(req_compl_qq) begin
                  s_axis_cc_tvalid  <= #TCQ 1'b1;
                  s_axis_cc_tlast   <= #TCQ 1'b1;
                  s_axis_cc_tkeep   <= #TCQ 8'h07;
                  s_axis_cc_tdata   <= #TCQ {160'b0,        // Tied to 0 for 3DW completion descriptor
                                             1'b0,          // Force ECRC
                                             1'b0, req_attr,// 3- bits
                                             req_tc,        // 3- bits
                                             1'b0,          // Completer ID to control selection of Client
                                                            // Supplied Bus number
                                             8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                             8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                             (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                             8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                             req_rid,       // Requester ID - 16 bits
                                             1'b0,          // Rsvd
                                             1'b0,          // Posioned completion
                                             3'b000,        // SuccessFull completion
                                             (req_mem ? (11'h1 + payload_len) : 11'b0),         // DWord Count 0 - IO Write completions
                                             2'b0,          // Rsvd
                                             1'b0,          // Locked Read Completion
                                             13'h0004,      // Byte Count
                                             6'b0,          // Rsvd
                                             req_at,        // Adress Type - 2 bits
                                             1'b0,          // Rsvd
                                             lower_addr};   // Starting address of the mem byte - 7 bits
                  s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                  if(s_axis_cc_tready) begin
                    state <= #TCQ PIO_TX_RST_STATE;
                    compl_done        <= #TCQ 1'b1;
                  end else begin
                    state <= #TCQ PIO_TX_COMPL_C1;
                  end
                end

              end  //PIO_TX_COMPL

              PIO_TX_COMPL_WD_C1 : begin  // Completion With Payload
                                       // Alignment can be either of Dword aligned or address aligned
             // Support n-DW 
             // Requires three clock cycle to get the first rd_data from the BRAM 
             if (req_compl_wd_qqqq) begin
                 if(AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE") begin //DWORD_Aligned mode
					   s_axis_cc_tvalid  <= #TCQ 1'b1; 
					   s_axis_cc_tdata   <= #TCQ {rd_data_s0[159:0],       // 5- DW read data
                                                 1'b0,          // Force ECRC
                                                 1'b0, req_attr,// 3- bits
                                                 req_tc,        // 3- bits
                                                 1'b0,          // Completer ID to control selection of Client
                                                                // Supplied Bus number
                                                 8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                                 8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                                 (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                                 8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                                 req_rid,       // Requester ID - 16 bits
                                                 1'b0,          // Rsvd
                                                 1'b0,          // Posioned completion
                                                 3'b000,        // SuccessFull completion
                                                 (req_mem ? (payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                                 2'b0,          // Rsvd
                                                 (req_mem_lock? 1'b1 : 1'b0),  // Locked Read Completion
                                                byte_count,     // 13'h0004,      // Byte Count
                                                 6'b0,          // Rsvd
                                                 req_at,        // Adress Type - 2 bits
                                                 1'b0,          // Rsvd
                                                 lower_addr_dw};   // Starting address of the mem byte - 7 bits
                      s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
					  if (s_axis_cc_tready) begin
					    if (len_i < 6 ) begin
					      case (len_i) 
					             1  : s_axis_cc_tkeep <= #TCQ 8'h0F; 
							     2  : s_axis_cc_tkeep <= #TCQ 8'h1F; 
							     3  : s_axis_cc_tkeep <= #TCQ 8'h3F; 
							     4  : s_axis_cc_tkeep <= #TCQ 8'h7F; 
							     5  : s_axis_cc_tkeep <= #TCQ 8'hFF; 
					      endcase
						  s_axis_cc_tlast <= #TCQ 1'b1; 
                          state           <= #TCQ PIO_TX_RST_STATE;		
                          rd_data_s1    <= #TCQ 96'h0; 	
                          len_i           <= #TCQ 11'b0; 	
                          compl_done      <= #TCQ 1'b1; 						  
				        end
						else begin 
						  s_axis_cc_tkeep <= #TCQ 8'hFF; 
						  s_axis_cc_tlast <= #TCQ 1'b0;
						  state           <= #TCQ PIO_TX_COMPL_WD_N_DW; 
						  rd_data_s1    <= #TCQ rd_data_s0[255:160];
                          len_i           <= #TCQ len_i - 11'h5; 	
                          compl_done      <= #TCQ 1'b0; 						  
						end
					  end
					 else begin 
					      state           <= #TCQ PIO_TX_COMPL_WD_C1; 
				     end
					 
			     end // DWORD Aligned mode end
                 
                 else begin //Address aligned mode
                      s_axis_cc_tvalid  <= #TCQ 1'b1;
                      s_axis_cc_tlast   <= #TCQ 1'b0;
                      s_axis_cc_tkeep   <= #TCQ 8'h07;
                      s_axis_cc_tdata   <= #TCQ {160'b0,        // Tied to 0 for 3DW completion descriptor
                                                 1'b0,          // Force ECRC
                                                 1'b0, req_attr,// 3- bits
                                                 req_tc,        // 3- bits
                                                 1'b0,          // Completer ID to control selection of Client
                                                                // Supplied Bus number
                                                 8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                                 8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                                 (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                                 8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                                 req_rid,       // Requester ID - 16 bits
                                                 1'b0,          // Rsvd
                                                 1'b0,          // Posioned completion
                                                 3'b000,        // SuccessFull completion
                                                 (req_mem ? (payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                                 2'b0,          // Rsvd
                                                 (req_mem_lock? 1'b1 : 1'b0),      // Locked Read Completion
                                                 byte_count,    //13'h0004,      // Byte Count
                                                 6'b0,          // Rsvd
                                                 req_at,        // Adress Type - 2 bits
                                                 1'b0,          // Rsvd
                                                 lower_addr_dw};   // Starting address of the mem byte - 7 bits
                      s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                      compl_done        <= #TCQ 1'b0;

                      if(s_axis_cc_tready) begin
                        state <= #TCQ PIO_TX_COMPL_PYLD;
                      end else begin
                        state <= #TCQ PIO_TX_COMPL_WD_C1;
                      end

                 end //Address aligned mode end
             end 

              end // PIO_TX_COMPL_WD

              PIO_TX_COMPL_PYLD : begin // Completion with 1DW Payload in Address Aligned mode

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ tkeep_q;
                s_axis_cc_tdata[31:0]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b000) ? {rd_data} : ((AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE" ) ? rd_data : 32'b0);
                s_axis_cc_tdata[63:32]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b001) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[95:64]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b010) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[127:96]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b011) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[159:128]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b100) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[191:160]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b101) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[223:192]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b110) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[255:224]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b111) ? {rd_data} : {32'b0};

                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                if(s_axis_cc_tready) begin
                  state        <= #TCQ PIO_TX_RST_STATE;
                  compl_done   <= #TCQ 1'b1;
                end else begin
                  state <= #TCQ PIO_TX_COMPL_PYLD;
                end
              end // PIO_TX_COMPL_PYLD

              PIO_TX_COMPL_WD_2DW : begin // Completion with 2DW Payload in DWord Aligned mode
                                          // Requires 2 states to get the 2DW Payload

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ 8'h1F;
                s_axis_cc_tdata   <= #TCQ {96'b0,         // Tied to 0 for 3DW completion descriptor with 2DW Payload
                                           rd_data,       // 32 bit read data
                                           rd_data_reg,   // 32- bit read data
                                           1'b0,          // Force ECRC
                                           1'b0, req_attr,// 3- bits
                                           req_tc,        // 3- bits
                                           1'b0,          // Completer ID to control selection of Client
                                                          // Supplied Bus number
                                           8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                           8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                           (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                           8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                           req_rid,       // Requester ID - 16 bits
                                           1'b0,          // Rsvd
                                           1'b0,          // Posioned completion
                                           3'b000,        // SuccessFull completion
                                           (req_mem ? (11'h1 + payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                           2'b0,          // Rsvd
                                           (req_mem_lock? 1'b1 : 1'b0),   // Locked Read Completion
                                           13'h0004,      // Byte Count
                                           6'b0,          // Rsvd
                                           req_at,        // Adress Type - 2 bits
                                           1'b0,          // Rsvd
                                           lower_addr_q};   // Starting address of the mem byte - 7 bits
                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                if(s_axis_cc_tready) begin
                  state        <= #TCQ PIO_TX_RST_STATE;
                  compl_done   <= #TCQ 1'b1;
                end else begin
                  state <= #TCQ PIO_TX_COMPL_WD_2DW;
                  dword_count <= #TCQ 1'b1; // To increment the Read Address
                  rd_data_reg <= #TCQ rd_data; // store the current read data
                end

              end //  PIO_TX_COMPL_WD_2DW

              PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C1 : begin // Completions with 2-DW Payload and Addr aligned mode

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ tkeep_q;
                s_axis_cc_tdata[255:0]     <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b000) ?  {192'b0, {rd_data,rd_data_reg}} 
                                                  :(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b001) ?  {160'b0, {rd_data,rd_data_reg}, 32'b0}
                                                  :(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b010) ?  {128'b0, {rd_data,rd_data_reg}, 64'b0} 
                                                  :(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b011) ?  { 96'b0, {rd_data,rd_data_reg}, 96'b0} 
                                                  :(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b100) ?  { 64'b0, {rd_data,rd_data_reg},128'b0} 
                                                  :(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b101) ?  { 32'b0, {rd_data,rd_data_reg},160'b0} 
                                                  :(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b110) ?  {        {rd_data,rd_data_reg},192'b0} 
                                                  :/*(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[4:2]==3'b111) ?*/  {    {        rd_data_reg},224'b0}; 



                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                dword_count       <= #TCQ 1'b0;
                if(s_axis_cc_tready) begin
		   if(lower_addr_q[4:2]==3'b111)
		   begin
                     state <= #TCQ PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C2;
                     compl_done   <= #TCQ 1'b0;
                     s_axis_cc_tlast   <= #TCQ 1'b0;
		   end
		   else
		   begin
                     state        <= #TCQ PIO_TX_RST_STATE;
                     compl_done   <= #TCQ 1'b1;
                     s_axis_cc_tlast   <= #TCQ 1'b1;
		   end
                end else begin
                  state <= #TCQ PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C1;
                end // PIO_TX_COMPL_WD_2DW_ADDR_ALGN
              end

              PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C2 : begin // Completions with 2-DW Payload and Addr aligned mode

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ 8'h01;
                s_axis_cc_tdata   <= #TCQ {224'b0, rd_data};

                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                dword_count       <= #TCQ 1'b0;
                if(s_axis_cc_tready) begin
                   state        <= #TCQ PIO_TX_RST_STATE;
                   compl_done   <= #TCQ 1'b1;
                end else begin
                  state <= #TCQ PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C2;
                end // PIO_TX_COMPL_WD_2DW_ADDR_ALGN
              end


              PIO_TX_CPL_UR_C1 : begin // Completions with UR - Alignement mode matters here

                if (req_compl_ur_qq) begin

                     s_axis_cc_tvalid  <= #TCQ 1'b1;
                     s_axis_cc_tlast   <= #TCQ 1'b1;
                     s_axis_cc_tkeep   <= #TCQ 8'hFF;
                     s_axis_cc_tdata   <= #TCQ {req_des_qword1, // 64 bits - Descriptor of the request 2 DW
                                                req_des_qword0, // 64 bits - Descriptor of the request 2 DW
                                                8'b0, // Rsvd
                                                req_des_tph_st_tag,   // TPH Steering tag - 8 bits
                                                5'b0,  // Rsvd
                                                req_des_tph_type,    // TPH type - 2 bits
                                                req_des_tph_present, // TPH present - 1 bit
                                                req_be,          // Request Byte enables - 8bits
                                                1'b0,          // Force ECRC
                                                1'b0, req_attr,// 3- bits
                                                req_tc,        // 3- bits
                                                1'b0,          // Completer ID to control selection of Client
                                                               // Supplied Bus number
                                                8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                                8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                                (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                                8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                                req_rid,       // Requester ID - 16 bits
                                                1'b0,          // Rsvd
                                                1'b0,          // Posioned completion
                                                3'b001,        // Completion Status - UR
                                                11'h005,       // DWord Count -55
                                                2'b0,          // Rsvd
                                                (req_mem_lock? 1'b1 : 1'b0),   // Locked Read Completion
                                                13'h0014,      // Byte Count - 20 bytes of Payload
                                                6'b0,          // Rsvd
                                                req_at,        // Adress Type - 2 bits
                                                1'b0,          // Rsvd
                                                lower_addr};   // Starting address of the mem byte - 7 bits
                     s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                     if(s_axis_cc_tready) begin
                       state        <= #TCQ PIO_TX_RST_STATE;
                       compl_done   <= #TCQ 1'b1;
                     end else begin
                       state        <= #TCQ PIO_TX_CPL_UR_C1;
                     end
                end

              end // PIO_TX_CPL_UR

//             PIO_TX_CPL_UR_PYLD_C1 : begin // Completion for UR with addr aligned mode
//
//               s_axis_cc_tvalid  <= #TCQ 1'b1;
//               s_axis_cc_tlast   <= #TCQ 1'b1;
//               s_axis_cc_tkeep   <= #TCQ 8'h1F;
//               s_axis_cc_tdata   <= #TCQ {96'b0,
//                                          req_des_qword1, // 64 bits - Descriptor of the request 2 DW
//                                          req_des_qword0, // 64 bits - Descriptor of the request 2 DW
//                                          8'b0, // Rsvd
//                                          req_des_tph_st_tag,   // TPH Steering tag - 8 bits
//                                          5'b0,  // Rsvd
//                                          req_des_tph_type,    // TPH type - 2 bits
//                                          req_des_tph_present, // TPH present - 1 bit
//                                          req_be};          // Request Byte enables - 8bits
//               s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
//               if(s_axis_cc_tready) begin
//                 state        <= #TCQ PIO_TX_RST_STATE;
//                 compl_done   <= #TCQ 1'b1;
//               end
//               else
//                 state        <= #TCQ PIO_TX_CPL_UR_PYLD_C1;
//
//             end // PIO_TX_CPL_UR_PYLD


              PIO_TX_MRD_C1 : begin // Memory Read Transaction - Alignment Doesnt Matter

                s_axis_rq_tvalid  <= #TCQ 1'b1;
                s_axis_rq_tlast   <= #TCQ 1'b1;
                s_axis_rq_tkeep   <= #TCQ 8'h0F;  // 4DW Descriptor For Memory Transaction Alone
                s_axis_rq_tdata   <= #TCQ {128'b0,       // 4DW Unused
                                           1'b0,         // Force ECRC
                                           3'b000,       // Attributes
                                           3'b000,       // Traffic Class
                                           1'b0,         // RID Enable to use the Client supplied Bus/Device/Func No
                                           16'b0,        // Completer -ID, set only for Completers or ID based routing
                                           (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                           8'h00 : req_tag),  // Select Client Tag or core's internal tag
                                           8'h00,             // Req Bus No- used only when RID enable = 1
                                           8'h00,             // Req Dev/Func no - used only when RID enable = 1
                                           1'b0,              // Poisoned Req
                                           4'b0000,           // Req Type for MRd Req
                                           11'h001,           // DWORD Count
                                           62'h2AAA_BBBB_CCCC_DDDD, // Memory Read Address [62 bits]
                                           2'b00};             //AT -> 00- Untranslated Address

                s_axis_rq_tuser          <= #TCQ {(AXISTEN_IF_RQ_PARITY_CHECK ? s_axis_rq_tparity : 32'b0), // Parity
                                                  4'b1010,      // Seq Number
                                                  8'h00,        // TPH Steering Tag
                                                  1'b0,         // TPH indirect Tag Enable
                                                  2'b0,         // TPH Type
                                                  1'b0,         // TPH Present
                                                  1'b0,         // Discontinue
                                                  3'b000,       // Byte Lane number in case of Address Aligned mode
                                                  4'h0,    // Last BE of the Read Data
                                                  4'hF}; // First BE of the Read Data


                if(s_axis_rq_tready) begin
                  state <= #TCQ PIO_TX_RST_STATE;
                  trn_sent <= #TCQ 1'b1;
                end
                else
                  state <= #TCQ PIO_TX_MRD_C1;

              end // PIO_TX_MRD
             
           PIO_TX_COMPL_WD_N_DW : begin
               if ((len_i-1)/8 == 0) begin 
                   s_axis_cc_tvalid  <= #TCQ 1'b1;
                   s_axis_cc_tlast   <= #TCQ 1'b1;
                   s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                   case (len_i) 
                          1      : begin s_axis_cc_tdata <= #TCQ {224'b0, rd_data_s1[31:0]};
                                         s_axis_cc_tkeep <= #TCQ 8'h01; 
                                   end
                          2      : begin s_axis_cc_tdata <= #TCQ {192'b0, rd_data_s1[63:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 8'h03; 
                                   end
                          3      : begin s_axis_cc_tdata <= #TCQ {160'b0, rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 8'h07; 
                                   end
                          4      : begin s_axis_cc_tdata <= #TCQ {128'b0, rd_data_s0[31:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 8'h0F; 
                                   end
                          5      : begin s_axis_cc_tdata <= #TCQ {96'b0, rd_data_s0[63:0],rd_data_s1[95:0]};
                                         s_axis_cc_tkeep <= #TCQ 8'h1F; 
                                   end
                          6      : begin s_axis_cc_tdata <= #TCQ {64'b0, rd_data_s0[95:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 8'h3F; 
                                   end
                          7      : begin s_axis_cc_tdata <= #TCQ {32'b0, rd_data_s0[127:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 8'h7F; 
                                   end
                          8      : begin s_axis_cc_tdata <= #TCQ {rd_data_s0[159:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 8'hFF; 
                                   end
                   endcase
                   len_i <= #TCQ 11'b0;
                   if(s_axis_cc_tready) begin
                       state        <= #TCQ PIO_TX_RST_STATE;
                       compl_done   <= #TCQ 1'b1;
					   rd_data_s1   <= #TCQ rd_data_s1; 
                   end else begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW; 
                   end               
               end // len_i <= 8 
               else begin 
                   s_axis_cc_tvalid            <= #TCQ 1'b1; 
                   s_axis_cc_tlast             <= #TCQ 1'b0; 
                   s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                   s_axis_cc_tkeep             <= #TCQ 8'hFF; 
                   s_axis_cc_tdata             <= #TCQ {rd_data_s0[159:0], rd_data_s1[95:0]}; 
                   rd_data_s1                 <= #TCQ rd_data_s0[255:160]; 
                   len_i                       <= #TCQ len_i - 11'h8; 
                   if(s_axis_cc_tready) begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW;
                       compl_done   <= #TCQ 1'b0;
                   end else begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW; 
                   end     
               end    
            
           end //PIO_TX_COMPL_WD_N_DW
            

            endcase

          end // reset_else_block

      end // Always Block Ends
    end // If AXISTEN_IF_WIDTH = 256




    else if( AXISTEN_IF_WIDTH == 2'b01) // 128-bit Interface
    begin
    always @ ( posedge user_clk )
    begin

      if(!reset_n ) begin

        state                   <= #TCQ PIO_TX_RST_STATE;
        rd_data_reg             <= #TCQ 32'b0;
        s_axis_cc_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
        s_axis_cc_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
        s_axis_cc_tlast         <= #TCQ 1'b0;
        s_axis_cc_tvalid        <= #TCQ 1'b0;
        s_axis_rq_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
        s_axis_rq_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
        s_axis_rq_tlast         <= #TCQ 1'b0;
        s_axis_rq_tvalid        <= #TCQ 1'b0;
        s_axis_cc_tuser_wo_parity <= #TCQ {AXI4_CC_TUSER_WIDTH{1'b0}};
        s_axis_rq_tuser         <= #TCQ {AXI4_RQ_TUSER_WIDTH{1'b0}};
        cfg_msg_transmit        <= #TCQ 1'b0;
        cfg_msg_transmit_type   <= #TCQ 3'b0;
        cfg_msg_transmit_data   <= #TCQ 32'b0;
        compl_done              <= #TCQ 1'b0;
        dword_count             <= #TCQ 1'b0;
        trn_sent                <= #TCQ 1'b0;
		len_i                   <= #TCQ 11'b0; 
		rd_data_s1              <= #TCQ 96'b0;

      end else begin // reset_else_block

            case (state)

              PIO_TX_RST_STATE : begin  // Reset_State

                state                   <= #TCQ PIO_TX_RST_STATE;
                s_axis_cc_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
                s_axis_cc_tkeep         <= #TCQ {KEEP_WIDTH{1'b1}};
                s_axis_cc_tlast         <= #TCQ 1'b0;
                s_axis_cc_tvalid        <= #TCQ 1'b0;
                s_axis_cc_tuser_wo_parity <= #TCQ 81'b0;
                s_axis_rq_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
                s_axis_rq_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
                s_axis_rq_tlast         <= #TCQ 1'b0;
                s_axis_rq_tvalid        <= #TCQ 1'b0;
                s_axis_rq_tuser         <= #TCQ 60'b0;
                cfg_msg_transmit        <= #TCQ 1'b0;
                cfg_msg_transmit_type   <= #TCQ 3'b0;
                cfg_msg_transmit_data   <= #TCQ 32'b0;
                compl_done              <= #TCQ 1'b0;
                trn_sent                <= #TCQ 1'b0;
                dword_count             <= #TCQ 1'b0;
				len_i                   <= #TCQ payload_len; 

                if(req_compl) begin
                   state <= #TCQ PIO_TX_COMPL_C1;
                end else if (req_compl_wd) begin
                   state <= #TCQ PIO_TX_COMPL_WD_C1;
                end else if (req_compl_ur) begin
                   state <= #TCQ PIO_TX_CPL_UR_C1;
                end else if (gen_transaction) begin
                   state <= #TCQ PIO_TX_MRD_C1;
                end

              end // PIO_TX_RST_STATE

              PIO_TX_COMPL_C1 : begin // Completion Without Payload - Alignment doesnt matter
                                   // Sent in a Single Beat When Interface Width is 128 bit
                if(req_compl_qq) begin
                  s_axis_cc_tvalid  <= #TCQ 1'b1;
                  s_axis_cc_tlast   <= #TCQ 1'b1;
                  s_axis_cc_tkeep   <= #TCQ 4'h7;
                  s_axis_cc_tdata   <= #TCQ {32'b0,        // Tied to 0 for 3DW completion descriptor
                                             1'b0,          // Force ECRC
                                             1'b0, req_attr,// 3- bits
                                             req_tc,        // 3- bits
                                             1'b0,          // Completer ID to control selection of Client
                                                            // Supplied Bus number
                                             8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                             8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                             (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                             8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                             req_rid,       // Requester ID - 16 bits
                                             1'b0,          // Rsvd
                                             1'b0,          // Posioned completion
                                             3'b000,        // SuccessFull completion
                                             (req_mem ? (11'h1 + payload_len) : 11'b0),         // DWord Count 0 - IO Write completions
                                             2'b0,          // Rsvd
                                             1'b0,          // Locked Read Completion
                                             13'h0004,      // Byte Count
                                             6'b0,          // Rsvd
                                             req_at,        // Adress Type - 2 bits
                                             1'b0,          // Rsvd
                                             lower_addr};   // Starting address of the mem byte - 7 bits
                  s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                  if(s_axis_cc_tready) begin
                    state <= #TCQ PIO_TX_RST_STATE;
                    compl_done        <= #TCQ 1'b1;
                  end else begin
                    state <= #TCQ PIO_TX_COMPL_C1;
                  end

                end
              end  //PIO_TX_COMPL

              PIO_TX_COMPL_WD_C1 : begin  // Completion With Payload
                                          // Possible Scenario's Payload can be 1 DW or 2 DW
                                          // Alignment can be either of Dword aligned or address aligned
             // Support n-DW 
             // Requires three clock cycle to get the first rd_data from the BRAM 
             if (req_compl_wd_qqqq) begin
                 if(AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE") begin //DWORD_Aligned mode
					   s_axis_cc_tvalid  <= #TCQ 1'b1; 
					   s_axis_cc_tdata   <= #TCQ {rd_data_s0[31:0],       // 1- DW read data in first transaction
                                                 1'b0,          // Force ECRC
                                                 1'b0, req_attr,// 3- bits
                                                 req_tc,        // 3- bits
                                                 1'b0,          // Completer ID to control selection of Client
                                                                // Supplied Bus number
                                                 8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                                 8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                                 (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                                 8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                                 req_rid,       // Requester ID - 16 bits
                                                 1'b0,          // Rsvd
                                                 1'b0,          // Posioned completion
                                                 3'b000,        // SuccessFull completion
                                                 (req_mem ? (payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                                 2'b0,          // Rsvd
                                                 (req_mem_lock? 1'b1 : 1'b0),  // Locked Read Completion
                                                 byte_count,     //13'h0004,      // Byte Count
                                                 6'b0,          // Rsvd
                                                 req_at,        // Adress Type - 2 bits
                                                 1'b0,          // Rsvd
                                                 lower_addr_dw};   // Starting address of the mem byte - 7 bits
                      s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
					  if (s_axis_cc_tready) begin
					    if (len_i < 2) begin
					      s_axis_cc_tkeep <= #TCQ 4'hF; 
						  s_axis_cc_tlast <= #TCQ 1'b1; 
                          state           <= #TCQ PIO_TX_RST_STATE;		
                          rd_data_s1      <= #TCQ 96'h0; 	
                          len_i           <= #TCQ 11'b0; 	
                          compl_done      <= #TCQ 1'b1; 						  
				        end
						else begin 
						  s_axis_cc_tkeep <= #TCQ 4'hF; 
						  s_axis_cc_tlast <= #TCQ 1'b0;
						  state           <= #TCQ PIO_TX_COMPL_WD_N_DW; 
						  rd_data_s1      <= #TCQ rd_data_s0[127:32];
                          len_i           <= #TCQ len_i - 11'h1; 	
                          compl_done      <= #TCQ 1'b0; 						  
						end
					  end
					 else begin 
					      state           <= #TCQ PIO_TX_COMPL_WD_N_DW; 
				     end
					 
			     end // DWORD Aligned mode end
                 
                 else begin //Address aligned mode
                      s_axis_cc_tvalid  <= #TCQ 1'b1;
                      s_axis_cc_tlast   <= #TCQ 1'b0;
                      s_axis_cc_tkeep   <= #TCQ 8'h07;
                      s_axis_cc_tdata   <= #TCQ {32'b0,        // Tied to 0 for 1DW completion descriptor
                                                 1'b0,          // Force ECRC
                                                 1'b0, req_attr,// 3- bits
                                                 req_tc,        // 3- bits
                                                 1'b0,          // Completer ID to control selection of Client
                                                                // Supplied Bus number
                                                 8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                                 8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                                 (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                                 8'hCC : req_tag),  // Select Client Tag or core's internal tag
                                                 req_rid,       // Requester ID - 16 bits
                                                 1'b0,          // Rsvd
                                                 1'b0,          // Posioned completion
                                                 3'b000,        // SuccessFull completion
                                                 (req_mem ? (payload_len) : 11'b1),         // DWord Count 0 - IO Write completions
                                                 2'b0,          // Rsvd
                                                 (req_mem_lock? 1'b1 : 1'b0),      // Locked Read Completion
                                                 byte_count,     //13'h0004,      // Byte Count
                                                 6'b0,          // Rsvd
                                                 req_at,        // Adress Type - 2 bits
                                                 1'b0,          // Rsvd
                                                 lower_addr_dw};   // Starting address of the mem byte - 7 bits
                      s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                      compl_done        <= #TCQ 1'b0;

                      if(s_axis_cc_tready) begin
                        state <= #TCQ PIO_TX_COMPL_PYLD;
                      end else begin
                        state <= #TCQ PIO_TX_COMPL_WD_C1;
                      end

                 end //Address aligned mode end
             end 
              end // PIO_TX_COMPL_WD

              PIO_TX_COMPL_PYLD : begin // Completion with 1DW Payload in Address Aligned mode

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ (tkeep_q[7:0]&8'hF);
                s_axis_cc_tdata[31:0]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b00) ? {rd_data} : ((AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE" ) ? rd_data : 32'b0);
                s_axis_cc_tdata[63:32]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b01) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[95:64]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b10) ? {rd_data} : {32'b0};
                s_axis_cc_tdata[127:96]   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b11) ? {rd_data} : {32'b0};
                s_axis_cc_tuser_wo_parity <= #TCQ {32'b0,1'b0};

                if(s_axis_cc_tready) begin
                  state           <= #TCQ PIO_TX_RST_STATE;
                  compl_done      <= #TCQ 1'b1;
                end else begin
                  state           <= #TCQ PIO_TX_COMPL_PYLD;
                end

              end // PIO_TX_COMPL_PYLD

              PIO_TX_COMPL_WD_2DW : begin // Completion with 2DW Payload in DWord Aligned mode
                                          // Requires 2 states to get the 2DW Payload

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ (tkeep_q[7:0]&8'hF);
                s_axis_cc_tdata[127:0]  <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b00) ? {64'b0,{rd_data,rd_data_reg}}
                                               :(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b01) ? {32'b0,{rd_data,rd_data_reg},32'b0}
                                               :(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b10) ? {      {rd_data,rd_data_reg},64'b0}
                                               :/*(AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_q[3:2]==2'b11)?*/{    {        rd_data_reg},96'b0};
                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                if(s_axis_cc_tready) begin
		   if(lower_addr_q[3:2]==2'b11)
		   begin
                     state           <= #TCQ PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C2;
                     compl_done      <= #TCQ 1'b0;
                     s_axis_cc_tlast <= #TCQ 1'b0;
		   end
		   else
		   begin
                     state           <= #TCQ PIO_TX_RST_STATE;
                     compl_done      <= #TCQ 1'b1;
                     s_axis_cc_tlast <= #TCQ 1'b1;
		   end
                end else begin
                  state           <= #TCQ PIO_TX_COMPL_WD_2DW;
                end

              end //  PIO_TX_COMPL_WD_2DW

              PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C2 : begin // Completions with 2-DW Payload and Addr aligned mode

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ 8'h01;
                s_axis_cc_tdata   <= #TCQ {96'b0, rd_data};

                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                dword_count       <= #TCQ 1'b0;
                if(s_axis_cc_tready) begin
                   state        <= #TCQ PIO_TX_RST_STATE;
                   compl_done   <= #TCQ 1'b1;
                end else begin
                  state <= #TCQ PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C2;
                end // PIO_TX_COMPL_WD_2DW_ADDR_ALGN
              end

              PIO_TX_CPL_UR_C1 : begin // Completions with UR - Alignement mode matters here

                if(req_compl_ur_qq) begin

                     s_axis_cc_tvalid  <= #TCQ 1'b1;
                     s_axis_cc_tlast   <= #TCQ 1'b1;
                     s_axis_cc_tkeep   <= #TCQ 4'hF;
                     compl_done        <= #TCQ 1'b0;
                     s_axis_cc_tdata   <= #TCQ {8'b0,                // Rsvd
                                                req_des_tph_st_tag,  // TPH Steering tag - 8 bits
                                                5'b0,                // Rsvd
                                                req_des_tph_type,    // TPH type - 2 bits
                                                req_des_tph_present, // TPH present - 1 bit
                                                req_be,              // Request Byte enables - 8bits

                                                1'b0,                // Force ECRC
                                                1'b0, req_attr,      // 3- bits
                                                req_tc,              // 3- bits
                                                1'b0,                // Completer ID to control selection of Client
                                                                     // Supplied Bus number
                                                8'h00,               // Completer Bus number - selected if Compl ID    = 1
                                                8'h00,               // Compl Dev / Func no - sel if Compl ID = 1
                                                (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                                8'hCC : req_tag),    // Select Client Tag or core's internal tag
                                                req_rid,             // Requester ID - 16 bits
                                                1'b0,                // Rsvd
                                                1'b0,                // Posioned completion
                                                3'b001,              // Completion Status - UR
                                                11'h005,             // DWord Count -55
                                                2'b0,                // Rsvd
                                                (req_mem_lock? 1'b1 : 1'b0),   // Locked Read Completion
                                                13'h0014,            // Byte Count - 20 bytes of Payload
                                                6'b0,                // Rsvd
                                                req_at,              // Adress Type - 2 bits
                                                1'b0,                // Rsvd
                                                lower_addr};   // Starting address of the mem byte - 7 bits
                     s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                     if (s_axis_cc_tready) begin
                       state           <= #TCQ PIO_TX_CPL_UR_C2;
                     end else begin
                       state           <= #TCQ PIO_TX_CPL_UR_C1;
                     end
                end

              end // PIO_TX_CPL_UR_C1

              PIO_TX_CPL_UR_C2 : begin // Completion for UR - Clock 2


                 s_axis_cc_tvalid  <= #TCQ 1'b1;
                 s_axis_cc_tlast   <= #TCQ 1'b1;
                 s_axis_cc_tkeep   <= #TCQ 4'hF;
                 s_axis_cc_tdata   <= #TCQ {req_des_qword1,      // 64 bits - Descriptor of the request 2 DW
                                            req_des_qword0};     // 64 bits - Descriptor of the request 2 DW};

                 s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                 if (s_axis_cc_tready) begin
                   state           <= #TCQ PIO_TX_RST_STATE;
                   compl_done      <= #TCQ 1'b1;
                 end else begin
                   state           <= #TCQ PIO_TX_CPL_UR_C2;
                 end
//                s_axis_cc_tvalid  <= #TCQ 1'b1;
//                s_axis_cc_tlast   <= #TCQ 1'b1;
//                s_axis_cc_tkeep   <= #TCQ 8'h1F;
//                s_axis_cc_tdata   <= #TCQ {96'b0,
//                                           req_des_qword1, // 64 bits - Descriptor of the request 2 DW
//                                           req_des_qword0, // 64 bits - Descriptor of the request 2 DW
//                                           8'b0, // Rsvd
//                                           req_des_tph_st_tag,   // TPH Steering tag - 8 bits
//                                           5'b0,  // Rsvd
//                                           req_des_tph_type,    // TPH type - 2 bits
//                                           req_des_tph_present, // TPH present - 1 bit
//                                           req_be};          // Request Byte enables - 8bits
//                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
//                if(s_axis_cc_tready) begin
//                  state        <= #TCQ PIO_TX_RST_STATE;
//                  compl_done   <= #TCQ 1'b1;
//                end
//                else
//                  state        <= #TCQ PIO_TX_CPL_UR_PYLD;

              end // PIO_TX_CPL_UR_PYLD_C1

              PIO_TX_MRD_C1 : begin // Memory Read Transaction - Alignment Doesnt Matter

                s_axis_rq_tvalid  <= #TCQ 1'b1;
                s_axis_rq_tlast   <= #TCQ 1'b1;
                s_axis_rq_tkeep   <= #TCQ 4'hF;  // 4DW Descriptor For Memory Transaction Alone
                s_axis_rq_tdata   <= #TCQ {1'b0,         // Force ECRC
                                           3'b000,       // Attributes
                                           3'b000,       // Traffic Class
                                           1'b0,         // RID Enable to use the Client supplied Bus/Device/Func No
                                           16'b0,        // Completer -ID, set only for Completers or ID based routing
                                           (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                           8'h00 : req_tag),  // Select Client Tag or core's internal tag
                                           8'h00,             // Req Bus No- used only when RID enable = 1
                                           8'h00,             // Req Dev/Func no - used only when RID enable = 1
                                           1'b0,              // Poisoned Req
                                           4'b0000,           // Req Type for MRd Req
                                           11'h001,           // DWORD Count
                                           62'h2AAA_BBBB_CCCC_DDDD, // Memory Read Address [62 bits]
                                           2'b00};             //AT -> 00- Untranslated Address

                s_axis_rq_tuser          <= #TCQ {(AXISTEN_IF_RQ_PARITY_CHECK ? s_axis_rq_tparity : 32'b0), // Parity
                                                  4'b1010,      // Seq Number
                                                  8'h00,        // TPH Steering Tag
                                                  1'b0,         // TPH indirect Tag Enable
                                                  2'b0,         // TPH Type
                                                  1'b0,         // TPH Present
                                                  1'b0,         // Discontinue
                                                  3'b000,       // Byte Lane number in case of Address Aligned mode
                                                  4'h0,    // Last BE of the Read Data
                                                  4'hF}; // First BE of the Read Data

                if(s_axis_rq_tready) begin
                  state           <= #TCQ PIO_TX_RST_STATE;
                  trn_sent        <= #TCQ 1'b1;
                end else begin
                  state           <= #TCQ PIO_TX_MRD_C1;
                end
              end // PIO_TX_MRD
			  
			  
			  PIO_TX_COMPL_WD_N_DW : begin
               if ((len_i-1)/4 == 0) begin 
                   s_axis_cc_tvalid  <= #TCQ 1'b1;
                   s_axis_cc_tlast   <= #TCQ 1'b1;
                   s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                   case (len_i) 
                          1      : begin s_axis_cc_tdata <= #TCQ {96'b0, rd_data_s1[31:0]};
                                         s_axis_cc_tkeep <= #TCQ 4'h1; 
                                   end
                          2      : begin s_axis_cc_tdata <= #TCQ {64'b0, rd_data_s1[63:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 4'h3; 
                                   end
                          3      : begin s_axis_cc_tdata <= #TCQ {32'b0, rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 4'h7; 
                                   end
                          4      : begin s_axis_cc_tdata <= #TCQ {rd_data_s0[31:0],rd_data_s1[95:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 4'hF; 
                                   end
                   endcase
                   len_i <= #TCQ 11'b0;
                   if(s_axis_cc_tready) begin
                       state        <= #TCQ PIO_TX_RST_STATE;
                       compl_done   <= #TCQ 1'b1;
					   rd_data_s1   <= #TCQ rd_data_s1; 
                   end else begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW; 
                   end               
               end // len_i <= 4
               else begin 
                   s_axis_cc_tvalid            <= #TCQ 1'b1; 
                   s_axis_cc_tlast             <= #TCQ 1'b0; 
                   s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                   s_axis_cc_tkeep             <= #TCQ 4'hF; 
                   s_axis_cc_tdata             <= #TCQ {rd_data_s0[31:0], rd_data_s1[95:0]}; 
                   rd_data_s1                  <= #TCQ rd_data_s0[127:32]; 
                   len_i                       <= #TCQ len_i - 11'h4; 
                   if(s_axis_cc_tready) begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW;
                       compl_done   <= #TCQ 1'b0;
                   end else begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW; 
                   end     
               end    
            
           end //PIO_TX_COMPL_WD_N_DW

            endcase

          end // reset_else_block

      end // Always Block Ends
    end // If AXISTEN_IF_WIDTH = 128

    else
    begin // 64 Bit Interface
    always @ ( posedge user_clk )
    begin

      if(!reset_n ) begin

        state                   <= #TCQ PIO_TX_RST_STATE;
        rd_data_reg             <= #TCQ 32'b0;
        s_axis_cc_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
        s_axis_cc_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
        s_axis_cc_tlast         <= #TCQ 1'b0;
        s_axis_cc_tvalid        <= #TCQ 1'b0;
        s_axis_rq_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
        s_axis_rq_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
        s_axis_rq_tlast         <= #TCQ 1'b0;
        s_axis_rq_tvalid        <= #TCQ 1'b0;
        s_axis_cc_tuser_wo_parity <= #TCQ {AXI4_CC_TUSER_WIDTH{1'b0}};
        s_axis_rq_tuser         <= #TCQ {AXI4_RQ_TUSER_WIDTH{1'b0}};
        cfg_msg_transmit        <= #TCQ 1'b0;
        cfg_msg_transmit_type   <= #TCQ 3'b0;
        cfg_msg_transmit_data   <= #TCQ 32'b0;
        compl_done              <= #TCQ 1'b0;
        dword_count             <= #TCQ 1'b0;
        trn_sent                <= #TCQ 1'b0;
		len_i                   <= #TCQ 11'b0; 
		rd_data_s1              <= #TCQ 96'b0;

      end else begin // reset_else_block

            case (state)

              PIO_TX_RST_STATE : begin  // Reset_State

                state                   <= #TCQ PIO_TX_RST_STATE;
                s_axis_cc_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
                s_axis_cc_tkeep         <= #TCQ {KEEP_WIDTH{1'b1}};
                s_axis_cc_tlast         <= #TCQ 1'b0;
                s_axis_cc_tvalid        <= #TCQ 1'b0;
                s_axis_cc_tuser_wo_parity <= #TCQ 81'b0;
                s_axis_rq_tdata         <= #TCQ {C_DATA_WIDTH{1'b0}};
                s_axis_rq_tkeep         <= #TCQ {KEEP_WIDTH{1'b0}};
                s_axis_rq_tlast         <= #TCQ 1'b0;
                s_axis_rq_tvalid        <= #TCQ 1'b0;
                s_axis_rq_tuser         <= #TCQ 60'b0;
                cfg_msg_transmit        <= #TCQ 1'b0;
                cfg_msg_transmit_type   <= #TCQ 3'b0;
                cfg_msg_transmit_data   <= #TCQ 32'b0;
                compl_done              <= #TCQ 1'b0;
                trn_sent                <= #TCQ 1'b0;
                dword_count             <= #TCQ 1'b0;
				len_i                   <= #TCQ payload_len; 

                if(req_compl) begin
                   state <= #TCQ PIO_TX_COMPL_C1;
                end else if (req_compl_wd) begin
                   state <= #TCQ PIO_TX_COMPL_WD_C1;
                end else if (req_compl_ur) begin
                   state <= #TCQ PIO_TX_CPL_UR_C1;
                end else if (gen_transaction) begin
                   state <= #TCQ PIO_TX_MRD_C1;
                end

              end // PIO_TX_RST_STATE

              PIO_TX_COMPL_C1 : begin // Completion Without Payload - Alignment doesnt matter
                                   // Sent in a Single Beat When Interface Width is 128 bit
                if(req_compl_qq)
                begin
                  s_axis_cc_tvalid  <= #TCQ 1'b1;
                  s_axis_cc_tlast   <= #TCQ 1'b0;
                  s_axis_cc_tkeep   <= #TCQ 2'h3;
                  compl_done        <= #TCQ 1'b0;
                  s_axis_cc_tdata   <= #TCQ {req_rid,       // Requester ID - 16 bits
                                             1'b0,          // Rsvd
                                             1'b0,          // Posioned completion
                                             3'b000,        // SuccessFull completion
                                             (req_mem ? (11'h1 + payload_len) : 11'b0),         // DWord Count 0 - IO Write completions
                                             2'b0,          // Rsvd
                                             1'b0,          // Locked Read Completion
                                             13'h0004,      // Byte Count
                                             6'b0,          // Rsvd
                                             req_at,        // Adress Type - 2 bits
                                             1'b0,          // Rsvd
                                             lower_addr};   // Starting address of the mem byte - 7 bits
                  s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                  if(s_axis_cc_tready) begin
                    state           <= #TCQ PIO_TX_COMPL_C2;
                  end else begin
                    state           <= #TCQ PIO_TX_COMPL_C1;
                  end
                end
              end  //PIO_TX_COMPL

              PIO_TX_COMPL_C2 : begin // Completion Without Payload - Alignment doesnt matter
                                      // Sent in a Two Beats When Interface Width is 64 bit
                  s_axis_cc_tvalid  <= #TCQ 1'b1;
                  s_axis_cc_tlast   <= #TCQ 1'b1;
                  s_axis_cc_tkeep   <= #TCQ 2'h1;
                  s_axis_cc_tdata   <= #TCQ {32'b0,         // Tied to 0 for 3DW completion descriptor
                                             1'b0,          // Force ECRC
                                             1'b0, req_attr,// 3- bits
                                             req_tc,        // 3- bits
                                             1'b0,          // Completer ID to control selection of Client
                                                            // Supplied Bus number
                                             8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                             8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                             (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                             8'hCC : req_tag)};   // Starting address of the mem byte - 7 bits
                  s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                  if(s_axis_cc_tready) begin
                    state           <= #TCQ PIO_TX_RST_STATE;
                    compl_done      <= #TCQ 1'b1;
                  end else begin
                    state           <= #TCQ PIO_TX_COMPL_C2;
                  end

              end  //PIO_TX_COMPL

              PIO_TX_COMPL_WD_C1 : begin  // Completion With Payload
                                          // Possible Scenario's Payload can be 1 DW or 2 DW
                                          // Alignment can be either of Dword aligned or address aligned
                if(req_compl_wd_qqq)
                begin

                  s_axis_cc_tvalid  <= #TCQ 1'b1;
                  s_axis_cc_tlast   <= #TCQ 1'b0;
                  s_axis_cc_tkeep   <= #TCQ 2'h3;
                  compl_done        <= #TCQ 1'b0;
                  if(AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE") begin // DWORD_aligned_Mode
                    s_axis_cc_tdata   <= #TCQ {req_rid,                                   // Requester ID - 16 bits
                                             1'b0,                                      // Rsvd
                                             1'b0,                                      // Posioned completion
                                             3'b000,                                    // SuccessFull completion
                                             (req_mem ? payload_len: 11'b1),            // DWord Count 0 - IO Write completions
                                             2'b0,                                      // Rsvd
                                             (req_mem_lock? 1'b1 : 1'b0),               // Locked Read Completion
                                             byte_count,                                //13'h0004,// Byte Count
                                             6'b0,                                      // Rsvd
                                             req_at,                                    // Adress Type - 2 bits
                                             1'b0,                                      // Rsvd
                                             lower_addr_dw};                               // Starting address of the mem byte - 7 bits
				  end
                  else begin //Address Align Mode 
                    s_axis_cc_tdata   <= #TCQ {req_rid,                                   // Requester ID - 16 bits
                                             1'b0,                                      // Rsvd
                                             1'b0,                                      // Posioned completion
                                             3'b000,                                    // SuccessFull completion
                                             (req_mem ? (1'b1 + payload_len): 11'b1),            // DWord Count 0 - IO Write completions
                                             2'b0,                                      // Rsvd
                                             (req_mem_lock? 1'b1 : 1'b0),               // Locked Read Completion
                                             byte_count,                                //13'h0004,// Byte Count
                                             6'b0,                                      // Rsvd
                                             req_at,                                    // Adress Type - 2 bits
                                             1'b0,                                      // Rsvd
                                             lower_addr_dw};                               // Starting address of the mem byte - 7 bits
                  end			 
									
                  s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                  if(s_axis_cc_tready) begin
                    state      <= #TCQ PIO_TX_COMPL_WD_C2;
                    dword_count <= #TCQ (payload_len != 0 ) ? 1'b1 : 1'b0;    // To increment the Read Address
                  end else begin
                    state      <= #TCQ PIO_TX_COMPL_WD_C1;
                  end
                end

              end // PIO_TX_COMPL_WD

              PIO_TX_COMPL_WD_C2 : begin  // Completion With Payload
                                          // Possible Scenario's Payload can be 1 DW or 2 DW
                                          // Alignment can be either of Dword aligned or address aligned

                  if(AXISTEN_IF_CC_ALIGNMENT_MODE == "FALSE") begin // DWORD_aligned_Mode
                    if(s_axis_cc_tready) begin

                      s_axis_cc_tvalid  <= #TCQ 1'b1;
                      s_axis_cc_tkeep   <= #TCQ 2'h3;
                      s_axis_cc_tdata   <= #TCQ {rd_data_s0[31:0],       // 32- bit read data
                                                 1'b0,          // Force ECRC
                                                 1'b0, req_attr,// 3- bits
                                                 req_tc,        // 3- bits
                                                 1'b0,          // Completer ID to control selection of Client
                                                                // Supplied Bus number
                                                 8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                                 8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                                 (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                                 8'hCC : req_tag)};   // Starting address of the mem byte - 7 bits
                      s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                       if(len_i < 2) // 1DW_packet - Requires just one cycle to get the data rd_data from the BRAM.
                        begin
                          state             <= #TCQ PIO_TX_RST_STATE;
                          s_axis_cc_tlast   <= #TCQ 1'b1;
                          compl_done        <= #TCQ 1'b1;
						  len_i             <= #TCQ 11'b0;
                        end else begin
                          s_axis_cc_tlast   <= #TCQ 1'b0;
                          state             <= #TCQ PIO_TX_COMPL_WD_N_DW;
						  len_i             <= #TCQ payload_len - 11'b1;
						  rd_data_s1        <= #TCQ rd_data_s0[63:32];
                        end
                      end else begin
                        state <= #TCQ PIO_TX_COMPL_WD_C2;
                      end

                end        //DWORD_aligned_Mode
                else begin // Addr_aligned_mode
                  s_axis_cc_tvalid  <= #TCQ 1'b1;
                  s_axis_cc_tlast   <= #TCQ 1'b0;
                  s_axis_cc_tkeep   <= #TCQ 2'h3;
                  s_axis_cc_tdata   <= #TCQ {1'b0,          // Force ECRC
                                             1'b0, req_attr,// 3- bits
                                             req_tc,        // 3- bits
                                             1'b0,          // Completer ID to control selection of Client
                                                            // Supplied Bus number
                                             8'h00,         // Completer Bus number - selected if Compl ID    = 1
                                             8'h00,         // Compl Dev / Func no - sel if Compl ID = 1
                                             (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                             8'hCC : req_tag)};   // Starting address of the mem byte - 7 bits
                  s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                  compl_done        <= #TCQ 1'b0;

                  if(s_axis_cc_tready) begin
                    if(payload_len == 0) begin // 1DW_packet - Requires just one cycle to get the data rd_data from the BRAM.
                      state         <= #TCQ PIO_TX_COMPL_PYLD;
                    end else begin
                      state         <= #TCQ PIO_TX_COMPL_WD_2DW;
                      dword_count   <= #TCQ 1'b1;    // To increment the Read Address
                      rd_data_reg   <= #TCQ rd_data; // store the current read data
                    end
                  end else begin
                      state         <= #TCQ PIO_TX_COMPL_WD_C2;
                  end
//                end

              end    // Addr_aligned_mode
            end // PIO_TX_COMPL_WD

              PIO_TX_COMPL_PYLD : begin // Completion with 1DW Payload in Address Aligned mode

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ tkeep_qq[1:0]&2'h3;
                s_axis_cc_tdata   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_qq[2]) ? {rd_data,32'b0} : {32'b0, rd_data};
                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                if(s_axis_cc_tready) begin
                  state           <= #TCQ PIO_TX_RST_STATE;
                  compl_done      <= #TCQ 1'b1;
                end else begin
                  state           <= #TCQ PIO_TX_COMPL_PYLD;
                end

              end // PIO_TX_COMPL_PYLD

              PIO_TX_COMPL_WD_2DW : begin // Completion with 2DW Payload in DWord Aligned mode
                                          // Requires 2 states to get the 2DW Payload

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ 2'h3;
                s_axis_cc_tdata   <= #TCQ (AXISTEN_IF_CC_ALIGNMENT_MODE == "TRUE" && lower_addr_qq[2]) ? {rd_data_reg,32'b0} : {rd_data,rd_data_reg};
                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                if(s_axis_cc_tready) begin
		   if(lower_addr_qq[2])
		   begin
                     state           <= #TCQ PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C2;
                     compl_done      <= #TCQ 1'b0;
                     s_axis_cc_tlast <= #TCQ 1'b0;
		   end
		   else
		   begin
                     state           <= #TCQ PIO_TX_RST_STATE;
                     compl_done      <= #TCQ 1'b1;
                     s_axis_cc_tlast <= #TCQ 1'b1;
		   end
                end else begin
                  state           <= #TCQ PIO_TX_COMPL_WD_2DW;
                end

              end //  PIO_TX_COMPL_WD_2DW
              PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C2 : begin // Completions with 2-DW Payload and Addr aligned mode

                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ 8'h01;
                s_axis_cc_tdata   <= #TCQ {32'b0, rd_data};

                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                dword_count       <= #TCQ 1'b0;
                if(s_axis_cc_tready) begin
                   state        <= #TCQ PIO_TX_RST_STATE;
                   compl_done   <= #TCQ 1'b1;
                end else begin
                  state <= #TCQ PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C2;
                end // PIO_TX_COMPL_WD_2DW_ADDR_ALGN
              end



              PIO_TX_CPL_UR_C1 : begin // Completions with UR - Beat 1

                if(req_compl_ur_qq) begin

                  s_axis_cc_tvalid  <= #TCQ 1'b1;
                  s_axis_cc_tlast   <= #TCQ 1'b1;
                  s_axis_cc_tkeep   <= #TCQ 2'h3;
                  compl_done        <= #TCQ 1'b0;
                  s_axis_cc_tdata   <= #TCQ {req_rid,             // Requester ID - 16 bits
                                             1'b0,                // Rsvd
                                             1'b0,                // Posioned completion
                                             3'b001,              // Completion Status - UR
                                             11'h005,             // DWord Count -55
                                             2'b0,                // Rsvd
                                             (req_mem_lock? 1'b1 : 1'b0),   // Locked Read Completion
                                             13'h0014,            // Byte Count - 20 bytes of Payload
                                             6'b0,                // Rsvd
                                             req_at,              // Adress Type - 2 bits
                                             1'b0,                // Rsvd
                                             lower_addr};   // Starting address of the mem byte - 7 bits
                  s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                  if(s_axis_cc_tready) begin
                    state           <= #TCQ PIO_TX_CPL_UR_C2;
                  end else begin
                    state           <= #TCQ PIO_TX_CPL_UR_C1;
                  end

                end
              end // PIO_TX_CPL_UR_C1

              PIO_TX_CPL_UR_C2 : begin // Completions with UR - Beat 2
                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ 2'h3;
                compl_done        <= #TCQ 1'b0;
                s_axis_cc_tdata   <= #TCQ {8'b0,                // Rsvd
                                           req_des_tph_st_tag,  // TPH Steering tag - 8 bits
                                           5'b0,                // Rsvd
                                           req_des_tph_type,    // TPH type - 2 bits
                                           req_des_tph_present, // TPH present - 1 bit
                                           req_be,              // Request Byte enables - 8bits

                                           1'b0,                // Force ECRC
                                           1'b0, req_attr,      // 3- bits
                                           req_tc,              // 3- bits
                                           1'b0,                // Completer ID to control selection of Client
                                                                // Supplied Bus number
                                           8'h00,               // Completer Bus number - selected if Compl ID    = 1
                                           8'h00,               // Compl Dev / Func no - sel if Compl ID = 1
                                           (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                           8'hCC : req_tag)};    // Select Client Tag or core's internal tag
                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                if(s_axis_cc_tready) begin
                  state           <= #TCQ PIO_TX_CPL_UR_C3;
                end else begin
                  state           <= #TCQ PIO_TX_CPL_UR_C2;
                end

              end // PIO_TX_CPL_UR_C2

              PIO_TX_CPL_UR_C3 : begin // Completions with UR - Beat 3
                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ 2'h3;
                compl_done        <= #TCQ 1'b0;
                s_axis_cc_tdata   <= #TCQ req_des_qword0;      // 64 bits - Descriptor of the request 2 DW
                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                if(s_axis_cc_tready) begin
                  state           <= #TCQ PIO_TX_CPL_UR_C4;
                end else begin
                  state           <= #TCQ PIO_TX_CPL_UR_C3;
                end

              end // PIO_TX_CPL_UR_C3

              PIO_TX_CPL_UR_C4 : begin // Completions with UR - Beat 4
                s_axis_cc_tvalid  <= #TCQ 1'b1;
                s_axis_cc_tlast   <= #TCQ 1'b1;
                s_axis_cc_tkeep   <= #TCQ 2'h3;
                s_axis_cc_tdata   <= #TCQ req_des_qword1;      // 64 bits - Descriptor of the request 2 DW
                s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};

                if(s_axis_cc_tready) begin
                  state           <= #TCQ PIO_TX_RST_STATE;
                  compl_done      <= #TCQ 1'b1;
                end else begin
                  state           <= #TCQ PIO_TX_CPL_UR_C4;
                end

              end // PIO_TX_CPL_UR_C4

              PIO_TX_MRD_C1 : begin // Memory Read Transaction - Alignment Doesnt Matter

                s_axis_rq_tvalid  <= #TCQ 1'b1;
                s_axis_rq_tlast   <= #TCQ 1'b0;
                s_axis_rq_tkeep   <= #TCQ 2'h3;  // 2DW Descriptor For Memory Transaction Alone
                trn_sent          <= #TCQ 1'b0;
                s_axis_rq_tdata   <= #TCQ {62'h2AAA_BBBB_CCCC_DDDD, // Memory Read Address [62 bits]
                                           2'b00};             //AT -> 00- Untranslated Address

                s_axis_rq_tuser          <= #TCQ {(AXISTEN_IF_RQ_PARITY_CHECK ? s_axis_rq_tparity : 32'b0), // Parity
                                                  4'b1010,      // Seq Number
                                                  8'h00,        // TPH Steering Tag
                                                  1'b0,         // TPH indirect Tag Enable
                                                  2'b0,         // TPH Type
                                                  1'b0,         // TPH Present
                                                  1'b0,         // Discontinue
                                                  3'b000,       // Byte Lane number in case of Address Aligned mode
                                                  4'h0,    // Last BE of the Read Data
                                                  4'hF}; // First BE of the Read Data

                if(s_axis_rq_tready) begin
                  state <= #TCQ PIO_TX_MRD_C2;
                end else begin
                  state <= #TCQ PIO_TX_MRD_C1;
                end

              end // PIO_TX_MRD

              PIO_TX_MRD_C2 : begin // Memory Read Transaction - Alignment Doesnt Matter

                s_axis_rq_tvalid  <= #TCQ 1'b1;
                s_axis_rq_tlast   <= #TCQ 1'b1;
                s_axis_rq_tkeep   <= #TCQ 2'h3;               // 2DW Descriptor For Memory Transaction Alone
                s_axis_rq_tdata   <= #TCQ {1'b0,              // Force ECRC
                                           3'b000,            // Attributes
                                           3'b000,            // Traffic Class
                                           1'b0,              // RID Enable to use the Client supplied Bus/Device/Func No
                                           16'b0,             // Completer -ID, set only for Completers or ID based routing
                                           (AXISTEN_IF_ENABLE_CLIENT_TAG ?
                                           8'h00 : req_tag),  // Select Client Tag or core's internal tag
                                           8'h00,             // Req Bus No- used only when RID enable = 1
                                           8'h00,             // Req Dev/Func no - used only when RID enable = 1
                                           1'b0,              // Poisoned Req
                                           4'b0000,           // Req Type for MRd Req
                                           11'h001};          // DWORD Count

                s_axis_rq_tuser   <= #TCQ 60'b0;

                if(s_axis_rq_tready) begin
                  state           <= #TCQ PIO_TX_RST_STATE;
                  trn_sent        <= #TCQ 1'b1;
                end else begin
                  state           <= #TCQ PIO_TX_MRD_C2;
                end

              end // PIO_TX_MRD
			  
			  PIO_TX_COMPL_WD_N_DW : begin
			  if (s_axis_cc_tready) begin 
               if ((len_i-1)/2 == 0) begin 
                   s_axis_cc_tvalid  <= #TCQ 1'b1;
                   s_axis_cc_tlast   <= #TCQ 1'b1;
                   s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                   case (len_i) 
                          1      : begin s_axis_cc_tdata <= #TCQ {32'b0, rd_data_s1[31:0]};
                                         s_axis_cc_tkeep <= #TCQ 2'h1; 
                                   end
                          2      : begin s_axis_cc_tdata <= #TCQ {rd_data_s0[31:0],rd_data_s1[31:0]}; 
                                         s_axis_cc_tkeep <= #TCQ 2'h3; 
                                   end
                   endcase
                   len_i <= #TCQ 11'b0;
                   if(s_axis_cc_tready) begin
                       state        <= #TCQ PIO_TX_RST_STATE;
                       compl_done   <= #TCQ 1'b1;
					   rd_data_s1   <= #TCQ rd_data_s1; 
                   end else begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW; 
                   end               
               end // len_i <= 2
               else begin 
                   s_axis_cc_tvalid            <= #TCQ 1'b1; 
                   s_axis_cc_tlast             <= #TCQ 1'b0; 
                   s_axis_cc_tuser_wo_parity   <= #TCQ {32'b0,1'b0};
                   s_axis_cc_tkeep             <= #TCQ 2'h3; 
                   s_axis_cc_tdata             <= #TCQ {rd_data_s0[31:0], rd_data_s1[31:0]}; 
                   rd_data_s1                  <= #TCQ rd_data_s0[63:32]; 
                   len_i                       <= #TCQ len_i - 11'h2; 
                   if(s_axis_cc_tready) begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW;
                       compl_done   <= #TCQ 1'b0;
                   end else begin
                       state        <= #TCQ PIO_TX_COMPL_WD_N_DW; 
                   end     
               end    
	       end else begin 
                     state        <= #TCQ PIO_TX_COMPL_WD_N_DW; 
	       end
            
           end //PIO_TX_COMPL_WD_N_DW


            endcase

          end // reset_else_block

      end // If AXISTEN_IF_WIDTH = 64
    end
  endgenerate


  // synthesis translate_off
  reg  [8*20:1] state_ascii;
  always @(state)
  begin
    case (state)
      PIO_TX_RST_STATE                    : state_ascii <= #TCQ "TX_RST_STATE";
      PIO_TX_COMPL_C1                     : state_ascii <= #TCQ "TX_COMPL_C1";
      PIO_TX_COMPL_C2                     : state_ascii <= #TCQ "TX_COMPL_C2";
      PIO_TX_COMPL_WD_C1                  : state_ascii <= #TCQ "TX_COMPL_WD_C1";
      PIO_TX_COMPL_WD_C2                  : state_ascii <= #TCQ "TX_COMPL_WD_C2";
      PIO_TX_COMPL_PYLD                   : state_ascii <= #TCQ "TX_COMPL_PYLD";
      PIO_TX_CPL_UR_C1                    : state_ascii <= #TCQ "TX_CPL_UR_C1";
      PIO_TX_CPL_UR_C2                    : state_ascii <= #TCQ "TX_CPL_UR_C2";
      PIO_TX_CPL_UR_C3                    : state_ascii <= #TCQ "TX_CPL_UR_C3";
      PIO_TX_CPL_UR_C4                    : state_ascii <= #TCQ "TX_CPL_UR_C4";
      PIO_TX_MRD_C1                       : state_ascii <= #TCQ "TX_MRD_C1";
      PIO_TX_MRD_C2                       : state_ascii <= #TCQ "TX_MRD_C2";
      PIO_TX_COMPL_WD_2DW                 : state_ascii <= #TCQ "TX_COMPL_WD_2DW";
      PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C1    : state_ascii <= #TCQ "TX_COMPL_WD_2DW_ADDR_ALGN_C1";
      PIO_TX_COMPL_WD_2DW_ADDR_ALGN_C2    : state_ascii <= #TCQ "TX_COMPL_WD_2DW_ADDR_ALGN_C2";
      default                             : state_ascii <= #TCQ "PIO STATE ERR";
    endcase
  end
  // synthesis translate_on

endmodule // pio_tx_engine
