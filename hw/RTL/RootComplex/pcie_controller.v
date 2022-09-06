// PCI express Controller
module pcie_controller(
  // User Interface
  input   wire  user_clk,
  input   wire  user_reset,
  input   wire  user_lnk_up,

  // Controller -> CFG
  output  reg   [9:0]   ctr2cfg_mgmt_addr,
  output  reg   [7:0]   ctr2cfg_mgmt_function_number,
  output  reg           ctr2cfg_mgmt_write,
  output  reg   [31:0]  ctr2cfg_mgmt_write_data,
  output  reg   [3:0]   ctr2cfg_mgmt_byte_enable,
  output  reg           ctr2cfg_mgmt_read,
  output  reg           ctr2cfg_mgmt_debug_access,

  // CFG -> Controller
  input   wire  [31:0]  cfg2ctr_mgmt_read_data,
  input   wire          cfg2ctr_mgmt_write_done,
  input   wire          cfg2ctr_mgmt_read_done,

  // Controller -> TX
  output  reg           ctr2tx_type0_cfg_read,
  output  reg   [7:0]   ctr2tx_type0_cfg_read_tag,
  output  reg   [11:0]  ctr2tx_type0_cfg_read_reg_addr,
  output  reg   [3:0]   ctr2tx_type0_cfg_read_first_dw_be,  

  // TX -> Controller
  input   wire          tx2ctr_type0_cfg_read_done
);

  localparam  DEV_CTRL_REG_ADDR = 12'h078;
  localparam  DEV_CAP_MAX_PAYLOAD_SUPPORTED = 1;
  localparam  DEFAULT_TAG = 8'h0;
  localparam  LINK_CTRL_REG_ADDR = 12'h080;



  localparam  STATE_IDLE                = 4'd0;
  localparam  STATE_SYS_INIT_WRITE_CFG  = 4'd1;
  localparam  STATE_SYS_INIT_READ_CFG   = 4'd2;
  localparam  STATE_SYS_INIT_WRITE_CFG2 = 4'd3;
  localparam  STATE_SYS_INIT_CFG_CHECK  = 4'd4;
  localparam  STATE_WAIT_FOR_READ_DATA  = 4'd5;

  reg [3:0]   ctr_state;

  reg [31:0]  ctr_mgmt_read_data;

  always@(posedge user_clk) begin
    if(user_reset) begin
      ctr_state <=  STATE_SYS_INIT_WRITE_CFG;

      ctr2cfg_mgmt_addr             <= 10'd0;
      ctr2cfg_mgmt_function_number  <= 8'd0;
      ctr2cfg_mgmt_write            <= 1'b0;
      ctr2cfg_mgmt_write_data       <= 32'd0;
      ctr2cfg_mgmt_byte_enable      <= 4'd0;
      ctr2cfg_mgmt_read             <= 1'b0;
      ctr2cfg_mgmt_debug_access     <= 1'b0;

      ctr_mgmt_read_data            <= 32'd0;

      ctr2tx_type0_cfg_read             <= 'd0;
      ctr2tx_type0_cfg_read_tag         <= 'd0;
      ctr2tx_type0_cfg_read_reg_addr    <= 'd0;
      ctr2tx_type0_cfg_read_first_dw_be <= 'd0;
    end
    else begin
      case(ctr_state)
        
        STATE_SYS_INIT_WRITE_CFG: begin
          ctr2cfg_mgmt_addr             <= 10'h01;
          ctr2cfg_mgmt_write            <= 1'b1;
          ctr2cfg_mgmt_write_data       <= 32'h07;
          ctr2cfg_mgmt_byte_enable      <= 4'h1;
          ctr2cfg_mgmt_read             <= 1'b0;
          ctr2cfg_mgmt_debug_access     <= 1'b0;

          if(cfg2ctr_mgmt_write_done) begin
            ctr_state <=  STATE_SYS_INIT_READ_CFG;
            
            ctr2cfg_mgmt_addr             <= 10'd0;
            ctr2cfg_mgmt_write            <= 1'b0;
            ctr2cfg_mgmt_write_data       <= 32'd0;
            ctr2cfg_mgmt_byte_enable      <= 4'd0;
            ctr2cfg_mgmt_read             <= 1'b0;
            ctr2cfg_mgmt_debug_access     <= 1'b0;
          end
        end // STATE_SYS_INIT_WRITE_CFG

        STATE_SYS_INIT_READ_CFG: begin
          ctr2cfg_mgmt_addr             <= DEV_CTRL_REG_ADDR/4;
          ctr2cfg_mgmt_write            <= 1'b0;
          ctr2cfg_mgmt_write_data       <= 32'd0;
          ctr2cfg_mgmt_byte_enable      <= 4'h1;
          ctr2cfg_mgmt_read             <= 1'b1;
          ctr2cfg_mgmt_debug_access     <= 1'b0;

          if(cfg2ctr_mgmt_read_done) begin
            ctr_state <=  STATE_SYS_INIT_WRITE_CFG2;
            ctr_mgmt_read_data <= cfg2ctr_mgmt_read_data;

            ctr2cfg_mgmt_addr             <= 10'd0;
            ctr2cfg_mgmt_write            <= 1'b0;
            ctr2cfg_mgmt_write_data       <= 32'd0;
            ctr2cfg_mgmt_byte_enable      <= 4'd0;
            ctr2cfg_mgmt_read             <= 1'b0;
            ctr2cfg_mgmt_debug_access     <= 1'b0;
          end
        end // STATE_SYS_INIT_WRITE_CFG

        STATE_SYS_INIT_WRITE_CFG2: begin
          ctr2cfg_mgmt_addr             <= DEV_CTRL_REG_ADDR/4;
          ctr2cfg_mgmt_write            <= 1'b1;
          ctr2cfg_mgmt_write_data       <= ctr_mgmt_read_data | (DEV_CAP_MAX_PAYLOAD_SUPPORTED * 32);
          ctr2cfg_mgmt_byte_enable      <= 4'h1;
          ctr2cfg_mgmt_read             <= 1'b0;
          ctr2cfg_mgmt_debug_access     <= 1'b0;

          if(cfg2ctr_mgmt_write_done) begin
            ctr_state <=  STATE_SYS_INIT_CFG_CHECK;
            
            ctr2cfg_mgmt_addr             <= 10'd0;
            ctr2cfg_mgmt_write            <= 1'b0;
            ctr2cfg_mgmt_write_data       <= 32'd0;
            ctr2cfg_mgmt_byte_enable      <= 4'd0;
            ctr2cfg_mgmt_read             <= 1'b0;
            ctr2cfg_mgmt_debug_access     <= 1'b0;
          end 
        end // STATE_SYS_INIT_WRITE_CFG

        STATE_SYS_INIT_CFG_CHECK: begin
          if(user_lnk_up) begin
            ctr2tx_type0_cfg_read             <= 1'b1;
            ctr2tx_type0_cfg_read_tag         <= DEFAULT_TAG;
            ctr2tx_type0_cfg_read_reg_addr    <= LINK_CTRL_REG_ADDR;
            ctr2tx_type0_cfg_read_first_dw_be <= 4'hf;

            if(tx2ctr_type0_cfg_read_done) begin
              ctr2tx_type0_cfg_read             <= 'd0;
              ctr2tx_type0_cfg_read_tag         <= 'd0;
              ctr2tx_type0_cfg_read_reg_addr    <= 'd0;
              ctr2tx_type0_cfg_read_first_dw_be <= 'd0;

              ctr_state  <= STATE_WAIT_FOR_READ_DATA;
            end
          end

        end
        
        STATE_WAIT_FOR_READ_DATA: begin

        end

      endcase
    end
  end





endmodule