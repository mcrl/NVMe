// NVMe Controller

module controller #(
  // AXIS Parameters
  parameter        AXI4_CQ_TUSER_WIDTH                    = 88,
  parameter        AXI4_CC_TUSER_WIDTH                    = 33,
  parameter        AXI4_RQ_TUSER_WIDTH                    = 62,
  parameter        AXI4_RC_TUSER_WIDTH                    = 75,
  parameter        C_DATA_WIDTH                           = 128,
  parameter        KEEP_WIDTH                             = C_DATA_WIDTH / 32
) (

  // System Interface
  
  input                 user_clk,
  input                 user_reset,
  input                 user_lnk_up,

  output reg  start_config,
  input       cfg_done,
  output reg [3:0] ctl_state
);

  // States
  localparam [3:0] ST_WAIT_LNKUP    = 4'd0;
  localparam [3:0] ST_START_CFG     = 4'd1;
  localparam [3:0] ST_WAIT_CFG_DONE = 4'd2;
  localparam [3:0] ST_IDLE          = 4'd3;

  //reg [3:0]    ctl_state;





  // pulse signal to start configuration 
  //reg start_config;
  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      start_config <= 1'b0;
    end
    else begin
      if(ctl_state == ST_START_CFG && user_lnk_up) start_config <= 1'b1;
      else start_config <= 1'b0;
    end
  end

  // Controller state-machine
  // ST_WAIT_LNKUP    : Wait for link comes up
  // ST_START_CFG     : Start configuration 
  // ST_WAIT_CFG_DONE : Wait for Configurator to finish configuring the NVMe SSD
  // ST_IDLE          : Idle state 

  // ST_WRITE         : Transmit write TLP to Endpoint 
  // ST_WRITE_WAIT    : Wait for write TLP to be transmitted
  // ST_READ          : Send a read TLP to Endpoint 
  // ST_READ_WAIT     : Wait for read TLP to be transmitted
  // ST_READ_CPL_WAIT : Wait for completion to be returned
  // ST_DONE          : Test passed successfully. Wait for restart to be requested
  // ST_ERROR         : Test failed. Wait for restart to be requested

  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      ctl_state <= ST_WAIT_LNKUP;
    end
    else begin
      case(ctl_state)
        ST_WAIT_LNKUP: begin
          if(user_lnk_up) begin
            ctl_state <= ST_START_CFG;
          end
        end

        ST_START_CFG: begin
          if(!user_lnk_up) begin
            ctl_state <= ST_WAIT_LNKUP;
          end
          else begin
            ctl_state <= ST_WAIT_CFG_DONE;
          end
        end

        ST_WAIT_CFG_DONE: begin
          if(!user_lnk_up) begin
            ctl_state <= ST_WAIT_LNKUP;
          end
          else begin
            if(cfg_done) begin
              ctl_state <= ST_IDLE;
            end
          end
        end

        ST_IDLE: begin

        end

      endcase
    end
  end

  

endmodule