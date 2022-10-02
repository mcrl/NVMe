module pcie_tlp_controller #(
    parameter AXIS_TDATA_WIDTH = 64
)(
  input   wire user_clk,
  input   wire user_reset,
  input   wire user_lnk_up,

	input 	wire [31:0]	cfg2ctr_status,

	output 	reg		[9:0]		reg_number,
	output 	reg		[15:0]	completer_id,
	output 	reg 	[3:0]		req_type,
	output 	reg 	[10:0]	dword_count,

  input wire recv_data
);

  localparam  STATE_IDLE          = 4'd0;
  localparam  STATE_CFG1RW        = 4'd1;
  localparam  STATE_CFG0RD        = 4'd2;
	localparam  STATE_CFG0RD_WAIT   = 4'd3;
  localparam  STATE_CFG0RD_DONE   = 4'd4;

  reg [3:0]   ctl_state;

	// FSM
	always@(posedge user_clk) begin
		if(user_reset) begin
			ctl_state <= STATE_IDLE;
		end
		else begin
			case(ctl_state)
				STATE_IDLE: begin
					if(user_lnk_up) begin
						ctl_state <= STATE_CFG1RW;
					end
				end

				STATE_CFG1RW: begin
          // cfg1 r/w done
					if( (cfg2ctr_status[0] == 1'b1) && user_lnk_up) begin
						ctl_state <= STATE_CFG0RD;
					end
				end

				STATE_CFG0RD: begin
					if(user_lnk_up) begin
						ctl_state <= STATE_CFG0RD_WAIT;
					end
				end

				STATE_CFG0RD_WAIT: begin
					if(user_lnk_up) begin
            if((recv_data) && (reg_number < 10'h28)) ctl_state <= STATE_CFG0RD;
            else if((recv_data) && (reg_number == 10'h28)) ctl_state <= STATE_CFG0RD_DONE;
          end
				end
        
        STATE_CFG0RD_DONE: begin
          if(user_lnk_up) begin
            
          end
        end
			endcase
		end
	end

	always@(posedge user_clk) begin
		if(user_reset) begin
			reg_number 		<= 10'd0;
			completer_id 	<= 16'd0;
			req_type 			<= 4'd0;
			dword_count 	<= 11'd0;
		end
		else begin
			case(ctl_state)
        STATE_CFG0RD: begin
					completer_id 	<= 16'd0; 
					req_type 			<= 4'b1000;   // cfgRd0
					dword_count 	<= 11'd1;
				end

        STATE_CFG0RD_WAIT: begin
					completer_id 	<= 16'd0; 
					req_type 			<= 4'd0;  
					dword_count 	<= 11'd0;
          if(user_lnk_up && recv_data) begin
            reg_number <= reg_number + 10'd1;
          end
        end

				default: begin
					completer_id 	<= 16'd0;
					req_type 			<= 4'd0;
					dword_count 	<= 11'd0;
				end
			endcase
		end

	end

endmodule