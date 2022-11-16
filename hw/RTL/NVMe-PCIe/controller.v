// FPGA Controller

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

  output reg            start_config,
  input                 cfg_done,

  output reg            write_sqtdbl,
  output reg [63:0]     sqt_addr,
  output reg            write_cqhdbl,
  output reg [63:0]     cqh_addr,
  input                 write_sqtdbl_done,
  input                 write_cqhdbl_done,

  input [31:0]          vio_sqt_addr,
  input                 vio_write_sqtdbl,
  input                 vio_send_cmd,

  output reg            send_cmd,
  input                 send_cmd_done,

  output reg [3:0] ctl_state
);

  // States
  localparam [3:0] ST_WAIT_LNKUP    = 4'd0;
  localparam [3:0] ST_START_CFG     = 4'd1;
  localparam [3:0] ST_WAIT_CFG_DONE = 4'd2;
  localparam [3:0] ST_IDLE          = 4'd3;
  localparam [3:0] ST_SQTDB         = 4'd4;
  localparam [3:0] ST_SQTDB_WAIT    = 4'd5;
  localparam [3:0] ST_SEND_CMD      = 4'd6;
  localparam [3:0] ST_WAIT_CMD      = 4'd7;
  localparam [3:0] ST_DONE          = 4'd8;


  // pulse signal to start configuration 
  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      start_config <= 1'b0;
    end
    else begin
      if(ctl_state == ST_START_CFG) start_config <= 1'b1;
      else start_config <= 1'b0;
    end
  end

  // Controller state-machine
  // ST_WAIT_LNKUP    : Wait for link comes up
  // ST_START_CFG     : Start configuration 
  // ST_WAIT_CFG_DONE : Wait for Configurator to finish configuring the NVMe SSD
  // ST_IDLE          : Idle state 
  // ST_SQTDB         : Write SQ tail address to SQ Tail Doorbell 

  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      ctl_state <= ST_WAIT_LNKUP;
      write_sqtdbl <= 1'b0;
      write_cqhdbl <= 1'b0;
      sqt_addr <= 64'h0;
      cqh_addr <= 64'h0;

      send_cmd <= 1'b0;
    end
    else begin
      case(ctl_state)
        ST_WAIT_LNKUP: begin
          ctl_state <= ST_START_CFG;
        end

        ST_START_CFG: begin
          ctl_state <= ST_WAIT_CFG_DONE;
        end

        ST_WAIT_CFG_DONE: begin
          if(cfg_done) begin
            ctl_state <= ST_IDLE;
          end
        end

        ST_IDLE: begin
          if(vio_write_sqtdbl) ctl_state <= ST_SQTDB;
          if(vio_send_cmd) ctl_state <= ST_SEND_CMD;
        end

        ST_SQTDB: begin
          write_sqtdbl <= 1'b1;
          sqt_addr <= {32'h0, vio_sqt_addr};
          ctl_state <= ST_SQTDB_WAIT;
        end

        ST_SQTDB_WAIT: begin
          write_sqtdbl <= 1'b0;
          if(write_sqtdbl_done) begin
            ctl_state <= ST_DONE;
          end
        end

        ST_SEND_CMD: begin
          send_cmd <= 1'b1;
          ctl_state <= ST_WAIT_CMD;
        end

        ST_WAIT_CMD: begin
          send_cmd <= 1'b0;
          if(send_cmd_done && !vio_send_cmd) ctl_state <= ST_IDLE;
        end

        ST_DONE: begin
          if(!vio_write_sqtdbl) ctl_state <= ST_IDLE;
        end

      endcase
    end
  end

  

endmodule