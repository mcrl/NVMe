module pcie_cfg_mgmt (
    // User Interface
    input   wire  user_clk,
    input   wire  user_reset,
    input   wire  user_lnk_up,
    
    output  reg   [9:0]   cfg_mgmt_addr,
    output  reg   [7:0]   cfg_mgmt_function_number,
    output  reg           cfg_mgmt_write,
    output  reg   [31:0]  cfg_mgmt_write_data,
    output  reg   [3:0]   cfg_mgmt_byte_enable,
    output  reg           cfg_mgmt_read,
    output  reg           cfg_mgmt_debug_access,
    input   wire  [31:0]  cfg_mgmt_read_data,
    input   wire          cfg_mgmt_read_write_done,

    output  wire  [31:0]  cfg2ctr_status
);

    localparam  STATE_IDLE          = 4'd0;
    localparam  STATE_CFGRD0        = 4'd1;
    localparam  STATE_CFGRD0_WAIT   = 4'd2;
    localparam  STATE_CFGWR0        = 4'd3;
    localparam  STATE_CFGWR0_WAIT   = 4'd4;
    localparam  STATE_CFGRD1        = 4'd5;
    localparam  STATE_CFGRD1_WAIT   = 4'd6;
    localparam  STATE_CFGRW_DONE    = 4'd7;
   
    reg [3:0]   cfg_state;
    reg         cfg1_rwdone;

    assign cfg2ctr_status = {
                              27'd0,        // 27-bit
                              cfg_state,    // 4-bit
                              cfg1_rwdone   // 1-bit
                            };

    // FSM
    always@(posedge user_clk) begin
        if(user_reset) begin
            cfg_state <= STATE_IDLE;
        end
        else begin
            case(cfg_state)
                STATE_IDLE: begin
                    if(user_lnk_up) begin
                      cfg_state <= STATE_CFGRD0;
                    end
                end

                STATE_CFGRD0: begin
                  if(user_lnk_up) begin
                    cfg_state <= STATE_CFGRD0_WAIT;
                  end
                end

                STATE_CFGRD0_WAIT: begin
                  if(cfg_mgmt_read_write_done && user_lnk_up) begin
                    cfg_state <= STATE_CFGRW_DONE;
                  end
                end

                STATE_CFGWR0: begin
                  if(user_lnk_up) begin
                    cfg_state <= STATE_CFGWR0_WAIT;
                  end
                end
                
                STATE_CFGWR0_WAIT: begin
                  if(cfg_mgmt_read_write_done && user_lnk_up) begin
                    cfg_state <= STATE_CFGRD1;
                  end
                end

                STATE_CFGRD1: begin
                  if(user_lnk_up) begin
                    cfg_state <= STATE_CFGRD1_WAIT;
                  end
                end

                STATE_CFGRD1_WAIT: begin
                  if(cfg_mgmt_read_write_done && user_lnk_up) begin
                    cfg_state <= STATE_CFGRW_DONE;
                  end
                end

                STATE_CFGRW_DONE: begin
                  if(user_lnk_up) begin
                    if(cfg_mgmt_addr < 10'h28) begin
                      cfg_state <= STATE_IDLE;
                    end
                  end
                end
            endcase
        end
    end

    always@(posedge user_clk) begin
        if(user_reset) begin
            cfg_mgmt_addr             <= 10'd0;
            cfg_mgmt_function_number  <= 8'd0;
            cfg_mgmt_write            <= 1'b0;
            cfg_mgmt_write_data       <= 32'd0;
            cfg_mgmt_byte_enable      <= 4'd0;
            cfg_mgmt_read             <= 1'b0;
            cfg_mgmt_debug_access     <= 1'd0;
            cfg1_rwdone               <= 1'd0;
        end 
        else begin
            case(cfg_state)
                STATE_CFGRD0: begin
                  //cfg_mgmt_addr             <= cfg_mgmt_addr + 10'd1;
                  cfg_mgmt_function_number  <= 8'd0;
                  cfg_mgmt_write            <= 1'b0;
                  cfg_mgmt_write_data       <= 32'd0;
                  cfg_mgmt_byte_enable      <= 4'b1111;
                  cfg_mgmt_read             <= 1'b1;
                  cfg_mgmt_debug_access     <= 1'b1;
                end

                STATE_CFGRD0_WAIT: begin
                  //cfg_mgmt_addr             <= 10'd0;
                  cfg_mgmt_function_number  <= 8'd0;
                  cfg_mgmt_write            <= 1'b0;
                  cfg_mgmt_write_data       <= 32'd0;
                  cfg_mgmt_byte_enable      <= 4'b0000;
                  cfg_mgmt_read             <= 1'b0;
                  cfg_mgmt_debug_access     <= 1'b1;
                end

                STATE_CFGWR0: begin
                  //cfg_mgmt_addr             <= 10'd4;
                  cfg_mgmt_function_number  <= 8'd0;
                  cfg_mgmt_write            <= 1'b1;
                  cfg_mgmt_write_data       <= 32'h1234_5678;
                  cfg_mgmt_byte_enable      <= 4'b1111;
                  cfg_mgmt_read             <= 1'b0;
                  cfg_mgmt_debug_access     <= 1'b1;
                end

                STATE_CFGWR0_WAIT: begin
                  //cfg_mgmt_addr             <= 10'd0;
                  cfg_mgmt_function_number  <= 8'd0;
                  cfg_mgmt_write            <= 1'b0;
                  cfg_mgmt_write_data       <= 32'd0;
                  cfg_mgmt_byte_enable      <= 4'h0;
                  cfg_mgmt_read             <= 1'b0;
                  cfg_mgmt_debug_access     <= 1'b1;
                end

                STATE_CFGRD1: begin
                  //cfg_mgmt_addr             <= 10'd4;
                  cfg_mgmt_function_number  <= 8'd0;
                  cfg_mgmt_write            <= 1'b0;
                  cfg_mgmt_write_data       <= 32'd0;
                  cfg_mgmt_byte_enable      <= 4'b1111;
                  cfg_mgmt_read             <= 1'b1;
                  cfg_mgmt_debug_access     <= 1'b1;
                end

                STATE_CFGRD1_WAIT: begin
                  //cfg_mgmt_addr             <= 10'd0;
                  cfg_mgmt_function_number  <= 8'd0;
                  cfg_mgmt_write            <= 1'b0;
                  cfg_mgmt_write_data       <= 32'd0;
                  cfg_mgmt_byte_enable      <= 4'h0;
                  cfg_mgmt_read             <= 1'b0;
                  cfg_mgmt_debug_access     <= 1'b1;
                end

                STATE_CFGRW_DONE: begin
                  if(cfg_mgmt_addr == 10'h28) begin
                      cfg1_rwdone = 1'b1;
                  end
                  else cfg_mgmt_addr <= cfg_mgmt_addr + 10'd1;
                end

            endcase
        end
    end


endmodule
