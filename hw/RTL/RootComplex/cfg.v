module cfg (
  // User Interface
  input   wire  user_clk,
  input   wire  user_reset,
  input   wire  user_lnk_up,

  // Controller -> CFG
  input   wire  [9:0]   ctr2cfg_mgmt_addr,
  input   wire  [7:0]   ctr2cfg_mgmt_function_number,
  input   wire          ctr2cfg_mgmt_write,
  input   wire  [31:0]  ctr2cfg_mgmt_write_data,
  input   wire  [3:0]   ctr2cfg_mgmt_byte_enable,
  input   wire          ctr2cfg_mgmt_read,
  input   wire          ctr2cfg_mgmt_debug_access,

  // CFG -> Controller
  output  reg           cfg2ctr_mgmt_write_done,
  output  reg           cfg2ctr_mgmt_read_done,
  output  reg   [31:0]  cfg2ctr_mgmt_read_data,

  // Configuration Management (CFG <-> PCIe IP)
  output  reg   [9:0]   cfg_mgmt_addr,
  output  reg   [7:0]   cfg_mgmt_function_number,
  output  reg           cfg_mgmt_write,
  output  reg   [31:0]  cfg_mgmt_write_data,
  output  reg   [3:0]   cfg_mgmt_byte_enable,
  output  reg           cfg_mgmt_read,
  output  reg           cfg_mgmt_debug_access,
  input   wire  [31:0]  cfg_mgmt_read_data,
  input   wire          cfg_mgmt_read_write_done
);
  
  localparam  STATE_IDLE  = 4'd0;
  localparam  STATE_WRITE = 4'd1;
  localparam  STATE_READ  = 4'd2;
  localparam  STATE_DONE  = 4'd3;

  reg [3:0]   cfg_state;



  

  always @(posedge user_clk) begin
    if(user_reset) begin
      cfg_mgmt_addr         <=  32'd0;
      cfg_mgmt_write_data   <=  32'd0;
      cfg_mgmt_byte_enable  <=  4'd0;
      cfg_mgmt_write        <=  1'b0;
      cfg_mgmt_read         <=  1'b0;

      cfg_state               <=  STATE_IDLE;
      
      cfg2ctr_mgmt_read_data  <=  32'd0;
      cfg2ctr_mgmt_write_done <=  1'b0;
      cfg2ctr_mgmt_read_done  <=  1'b0;
    end else begin
      case(cfg_state)
        
        STATE_IDLE: begin
          cfg2ctr_mgmt_write_done <= 1'b0;
          cfg2ctr_mgmt_read_done  <= 1'b0;

          if(ctr2cfg_mgmt_write) begin
            cfg_state <=  STATE_WRITE;
          end
          else if(ctr2cfg_mgmt_read) begin
            cfg_state <=  STATE_READ;
          end
        end

        STATE_WRITE: begin
          cfg_mgmt_addr         <=  ctr2cfg_mgmt_addr;
          cfg_mgmt_write_data   <=  ctr2cfg_mgmt_write_data;
          cfg_mgmt_byte_enable  <=  ctr2cfg_mgmt_byte_enable;
          cfg_mgmt_write        <=  ctr2cfg_mgmt_write;
          cfg_mgmt_read         <=  1'b0;

          if(cfg_mgmt_read_write_done == 1'b1) begin
            cfg_state <=  STATE_DONE;
            cfg2ctr_mgmt_write_done <=  1'b1;
          end
        end

        STATE_READ: begin
          cfg_mgmt_addr         <=  ctr2cfg_mgmt_addr;
          cfg_mgmt_write        <=  1'b0;
          cfg_mgmt_read         <=  ctr2cfg_mgmt_read;

          if(cfg_mgmt_read_write_done == 1'b1) begin
            cfg_state     <=  STATE_DONE;

            cfg2ctr_mgmt_read_data  <= cfg_mgmt_read_data;
            cfg2ctr_mgmt_read_done  <= 1'b1;
          end

        end
       
        STATE_DONE: begin
          cfg_mgmt_addr         <=  32'd0;
          cfg_mgmt_write_data   <=  32'd0;
          cfg_mgmt_byte_enable  <=  4'd0;
          cfg_mgmt_write        <=  1'b0;
          cfg_mgmt_read         <=  1'b0;

          cfg_state             <=  STATE_IDLE;
        end

      endcase

    end
  end


endmodule
