module cfg_mgmt (
  // User Interface
  input   wire  user_clk,
  input   wire  user_reset,
  input   wire  user_lnk_up,

  // CSR signals
  input   wire          csr_cfg_mgmt_write,
  input   wire          csr_cfg_mgmt_read,
  input   wire  [31:0]  csr_cfg_mgmt_addr,
  input   wire  [31:0]  csr_cfg_mgmt_write_data,
  input   wire  [3:0]   csr_cfg_mgmt_byte_enable,

  // Configuration Management
  output  reg   [9:0]   cfg_mgmt_addr,
  output  reg   [7:0]   cfg_mgmt_function_number,
  output  reg           cfg_mgmt_write,
  output  reg   [31:0]  cfg_mgmt_write_data,
  output  reg   [3:0]   cfg_mgmt_byte_enable,
  output  reg           cfg_mgmt_read,
  input   wire  [31:0]  cfg_mgmt_read_data,
  input   wire          cfg_mgmt_read_write_done,
  output  reg           cfg_mgmt_debug_access
);
  
  localparam  STATE_IDLE  = 4'd0;
  localparam  STATE_WRITE = 4'd1;
  localparam  STATE_READ  = 4'd2;
  localparam  STATE_DONE  = 4'd3;

  reg [3:0]   cfg_state;
  reg [31:0]  cfg_read_data;


  always @(posedge user_clk) begin
    if(user_reset) begin
      cfg_mgmt_addr         <=  32'd0;
      cfg_mgmt_write_data   <=  32'd0;
      cfg_mgmt_byte_enable  <=  4'd0;
      cfg_mgmt_write        <=  1'b0;
      cfg_mgmt_read         <=  1'b0;

      cfg_read_data         <=  32'd0;
      cfg_state             <=  STATE_IDLE;
    end else begin
      case(cfg_state)
        
        STATE_IDLE: begin
          if(csr_cfg_mgmt_write) begin
            cfg_state <=  STATE_WRITE;
          end
          
          else if(csr_cfg_mgmt_read) begin
            cfg_state <=  STATE_READ;  
          end
        end

        STATE_WRITE: begin
          cfg_mgmt_addr         <=  csr_cfg_mgmt_addr;
          cfg_mgmt_write_data   <=  csr_cfg_mgmt_write_data;
          cfg_mgmt_byte_enable  <=  csr_cfg_mgmt_byte_enable;
          cfg_mgmt_write        <=  csr_cfg_mgmt_write;
          cfg_mgmt_read         <=  1'b0;

          if(cfg_mgmt_read_write_done == 1'b1) begin
            cfg_state <=  STATE_DONE;
          end
        end

        STATE_READ: begin
          cfg_mgmt_addr         <=  csr_cfg_mgmt_addr;
          cfg_mgmt_write        <=  1'b0;
          cfg_mgmt_read         <=  csr_cfg_mgmt_read;

          if(cfg_mgmt_read_write_done == 1'b1) begin
            cfg_state     <=  STATE_DONE;
            cfg_read_data <=  cfg_mgmt_read_data;
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
