module pcie_tlp_encoder #(
    parameter AXIS_DATA_WIDTH = 64,
		parameter REQUESTER_ID = 16'h10ee // TODO
)(
  input   wire user_clk,
  input   wire user_reset,
  input   wire user_lnk_up,

	input 	wire [3:0]	req_type,
	input 	wire [15:0]	completer_id,
	input 	wire [9:0]	reg_number,
	input 	wire [10:0]	dword_count,

	output  reg  [63 : 0]   s_axis_rq_tdata,
  output  reg  [1 : 0]    s_axis_rq_tkeep,
  output  reg             s_axis_rq_tlast,
  input   wire [3 : 0]    s_axis_rq_tready,
  output  reg  [61 : 0]   s_axis_rq_tuser,
  output  reg             s_axis_rq_tvalid,

	output 	wire [31:0]			enc2ctl_status
);

  localparam  STATE_IDLE          = 4'd0;
  localparam  STATE_CFG0RD_0      = 4'd1;
	localparam  STATE_CFG0RD_1      = 4'd2;
	localparam  STATE_CFG0RD_DONE   = 4'd3;


	reg [3:0] enc_state;

	reg [9:0]		enc_reg_number;
	reg [10:0]	enc_dword_count;

	// FSM
	always@(posedge user_clk) begin
		if(user_reset) begin
			enc_state <= STATE_IDLE;
		end else begin
			case(enc_state)
				STATE_IDLE: begin
					if(req_type == 4'b1000) begin // CFG1RD
						enc_state <= STATE_CFG0RD_0;
					end
				end

				STATE_CFG0RD_0: begin
					if(s_axis_rq_tready) begin
						enc_state <= STATE_CFG0RD_1;
					end
				end

				STATE_CFG0RD_1: begin
					if(s_axis_rq_tready) begin
						enc_state <= STATE_CFG0RD_DONE;
					end
				end

				STATE_CFG0RD_DONE: begin
					enc_state <= STATE_IDLE;
				end

			endcase
		end
	end

	always@(user_clk) begin
		if(user_reset) begin
			s_axis_rq_tdata <= 'd0;
			s_axis_rq_tkeep <= 'd0;
			s_axis_rq_tlast <= 'd0;
			s_axis_rq_tuser <= 'd0;
			s_axis_rq_tvalid <= 'd0;

			enc_reg_number <= 'd0;
			enc_dword_count <= 'd0;
		end else begin
			case(enc_state)
				STATE_IDLE: begin
          s_axis_rq_tdata   <= 64'd0;
					s_axis_rq_tkeep   <= 2'd0;
					s_axis_rq_tlast   <= 1'd0;
					s_axis_rq_tuser   <= 'd0;
					s_axis_rq_tvalid  <= 'd0;

					if(req_type == 4'b1000) begin
						enc_reg_number <= reg_number;
						enc_dword_count <= dword_count;
					end
				end

				STATE_CFG0RD_0: begin
					if(s_axis_rq_tready) begin
						// DESC0
						s_axis_rq_tdata[31:0] <= { 
																			20'd0,			// 20-bit Reserved
																			enc_reg_number,	// 10-bit Register Number
																			2'd0				// 2-bit 	Reserved
																		};
						// DESC1
						s_axis_rq_tdata[63:32] 	<= {
																				32'd0 // Reserved
																			}; 
						s_axis_rq_tuser <= { 
																2'b00,			// 2-bit	Ext Seq Number
																32'b0,			// 32-bit Parity Bit
																4'b0, 			// 4-bit 	Seq Number
																8'b0, 			// 8-bit 	tph st tag
																1'b0, 			// 1-bit 	tph indirect tag en
																2'b0,				// 2-bit 	tph type
																1'b0, 			// 1-bit 	tph present
																1'b0, 			// 1-bit 	discontinue
																3'b0, 			// 3-bit 	addr offset
																4'b0000,				// 4-bit 	last be
																4'b1111 				// 4-bit 	first be
															};
						s_axis_rq_tvalid 				<= 1'b1;
						s_axis_rq_tkeep 				<= 2'b11;
						s_axis_rq_tlast 				<= 1'b0;
					end
				end

				STATE_CFG0RD_1: begin
					if(s_axis_rq_tready) begin
						// DESC2
						s_axis_rq_tdata[31:0] <= { 
																			REQUESTER_ID, 	// 16-bit Requester ID
																			1'b0,						// 1-bit 	Poisoned Request
																			4'b1000,				// 4-bit 	Request Type (CfgRd1)
																			enc_dword_count			// 11-bit Dword count			
																		};
						// DESC3
						s_axis_rq_tdata[63:32] 	<= {32'd0}; // Reserved
						s_axis_rq_tuser 				<= 62'd0;
						s_axis_rq_tvalid 				<= 1'b1;
						s_axis_rq_tkeep 				<= 2'b11;
						s_axis_rq_tlast 				<= 1'b1;
					end
				end

				STATE_CFG0RD_DONE: begin
					enc_reg_number  <= 'd0;
					enc_dword_count <= 'd0;

          s_axis_rq_tdata   <= 64'd0;
					s_axis_rq_tkeep   <= 2'd0;
					s_axis_rq_tlast   <= 1'd0;
					s_axis_rq_tuser   <= 'd0;
					s_axis_rq_tvalid  <= 'd0;
				end

				default: begin
					s_axis_rq_tdata   <= 64'd0;
					s_axis_rq_tkeep   <= 2'd0;
					s_axis_rq_tlast   <= 1'd0;
					s_axis_rq_tuser   <= 'd0;
					s_axis_rq_tvalid  <= 'd0;
					
					enc_reg_number = 'd0;
					enc_dword_count = 'd0;
				end

			endcase
		end
	end

endmodule