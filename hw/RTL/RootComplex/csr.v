module csr(
  // User Interface
  input   wire  user_clk,
  input   wire  user_reset,
  input   wire  user_lnk_up,

  // Host to FPGA control signals
  input   wire          h2f_csr_read,
  input   wire          h2f_csr_write,
  input   wire  [31:0]  h2f_csr_addr,
  input   wire  [511:0] h2f_csr_wrData,
  output  reg   [511:0] f2h_csr_rdData,

  // CSR signals
  output  reg           csr_cfg_mgmt_write,
  output  reg           csr_cfg_mgmt_read,
  output  reg   [31:0]  csr_cfg_mgmt_addr,
  output  reg   [31:0]  csr_cfg_mgmt_write_data,
  output  reg   [3:0]   csr_cfg_mgmt_byte_enable,

  // CSR to RootComplex
  output  reg           csr_cfg_mgmt_type1_cfg_reg_access, 
  output  reg           csr_cfg_msg_transmit,               
  output  reg   [2:0]   csr_cfg_msg_transmit_type,          
  output  reg   [31:0]  csr_cfg_msg_transmit_data,          
  output  reg   [2:0]   csr_cfg_fc_sel,                     
  output  reg   [2:0]   csr_cfg_per_func_status_control,    
  output  reg           csr_cfg_per_function_output_request,
  output  reg   [2:0]   csr_cfg_per_function_number,        
  output  reg   [63:0]  csr_cfg_dsn,                        
  output  reg           csr_cfg_power_state_change_ack,     
  output  reg           csr_cfg_err_cor_in,                 
  output  reg           csr_cfg_err_uncor_in,               
  output  reg   [1:0]   csr_cfg_flr_done,                   
  output  reg   [5:0]   csr_cfg_vf_flr_done,                
  output  reg           csr_cfg_link_training_enable,       
  output  reg   [7:0]   csr_cfg_ds_port_number,             
  output  reg           csr_cfg_hot_reset_in,               
  output  reg   [7:0]   csr_cfg_ds_bus_number,              
  output  reg   [4:0]   csr_cfg_ds_device_number,           
  output  reg   [2:0]   csr_cfg_ds_function_number 
);

  reg [511:0]   scratch_data;
  
  localparam RP_BUS_DEV_FNS   =   16'b0000_0000_1010_1111;

  initial begin
    csr_cfg_mgmt_addr                     <= 32'd0;
    csr_cfg_mgmt_write_data               <= 32'd0;
    csr_cfg_mgmt_byte_enable              <= 4'd0;
    csr_cfg_mgmt_write                    <= 1'b0;
    csr_cfg_mgmt_read                     <= 1'b0;

    csr_cfg_mgmt_type1_cfg_reg_access     <= 0;  
    csr_cfg_msg_transmit                  <= 0;
    csr_cfg_msg_transmit_type             <= 3'd0;
    csr_cfg_msg_transmit_data             <= 32'd0;
    csr_cfg_fc_sel                        <= 3'd0;     

    csr_cfg_per_func_status_control       <= 3'd0;             
    csr_cfg_per_function_output_request   <= 0; 
    csr_cfg_per_function_number           <= 3'd0; 

    csr_cfg_dsn                           <= 64'h78EE32BAD28F906B; 
    csr_cfg_power_state_change_ack        <= 0;    
    csr_cfg_err_cor_in                    <= 0;
    csr_cfg_err_uncor_in                  <= 0;     

    csr_cfg_flr_done                      <= 2'd0;
    csr_cfg_vf_flr_done                   <= 6'd0;    

    csr_cfg_link_training_enable          <= 1'b1;     

    csr_cfg_ds_port_number                <= 8'h9F ;
    csr_cfg_hot_reset_in                  <= 0;

    csr_cfg_ds_bus_number                 <= RP_BUS_DEV_FNS[15:8]; 
    csr_cfg_ds_device_number              <= RP_BUS_DEV_FNS[7:3];  
    csr_cfg_ds_function_number            <= RP_BUS_DEV_FNS[2:0];  
  end


  


  always @(posedge user_clk) begin
    if(user_reset) begin
      csr_cfg_mgmt_write        <=  1'd0;
      csr_cfg_mgmt_read         <=  1'd0;
      csr_cfg_mgmt_addr         <=  32'd0;
      csr_cfg_mgmt_write_data   <=  32'd0;
      csr_cfg_mgmt_byte_enable  <=  4'd0;

      scratch_data              <=  512'd0;
    end else begin
     
      // Read
      if(h2f_csr_read) begin
        case(h2f_csr_addr)
          32'h0000_0000:  f2h_csr_rdData  <=  scratch_data;
        endcase
      end // Read

      // Write
      else if(h2f_csr_write) begin
        case(h2f_csr_addr)
          32'h0000_0000:  scratch_data  <=  h2f_csr_wrData;
        endcase
      end // Write
    
    end
  end



endmodule
