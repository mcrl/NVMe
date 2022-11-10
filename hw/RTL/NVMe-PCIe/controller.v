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

  output reg        write_sqtdbl,
  output reg [63:0] sqt_addr,
  output reg        write_cqhdbl,
  output reg [63:0] cqh_addr,
  input             write_sqtdbl_done,
  input             write_cqhdbl_done,

  output reg send_cmd,
  input send_cmd_done,

  output reg [3:0] ctl_state
);

  // States
  localparam [3:0] ST_WAIT_LNKUP    = 4'd0;
  localparam [3:0] ST_START_CFG     = 4'd1;
  localparam [3:0] ST_WAIT_CFG_DONE = 4'd2;
  localparam [3:0] ST_IDLE          = 4'd3;
  localparam [3:0] ST_SEND_CMD      = 4'd9;
  localparam [3:0] ST_WAIT_CMD      = 4'd10;
  localparam [3:0] ST_SQTDB         = 4'd4;
  localparam [3:0] ST_SQTDB_WAIT    = 4'd5;
  localparam [3:0] ST_CQHDB         = 4'd6;
  localparam [3:0] ST_CQHDB_WAIT    = 4'd7;
  localparam [3:0] ST_DONE          = 4'd8;

  //reg [3:0]    ctl_state;


  localparam [63:0] ASQ_BAR = 64'h0000_0000_8000_0000;
  localparam [63:0] ACQ_BAR = 64'h0000_0000_9000_0000;

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
  // ST_SQTDB         : Write SQ tail address to SQ Tail Doorbell 
  // ST_CQHDB         : Write CQ head address to CQ Head Doorbell 
  // ST_RDSQT         : Read ASQ Tail address
  // ST_RDCQH         : Read ACQ Head address

  reg flag;

  always@(posedge user_clk) begin
    if(user_reset || !user_lnk_up) begin
      ctl_state <= ST_WAIT_LNKUP;
      write_sqtdbl <= 1'b0;
      write_cqhdbl <= 1'b0;
      sqt_addr <= 64'h0;
      cqh_addr <= 64'h0;

      send_cmd <= 1'b0;
      flag <= 1'b0;
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
          //ctl_state <= ST_SQTDB;
          //ctl_state <= ST_SEND_CMD;
        end

        ST_SEND_CMD: begin
          ctl_state <= ST_WAIT_CMD;
          send_cmd <= 1'b1;
        end

        ST_WAIT_CMD: begin
          send_cmd <= 1'b0;
          //if(send_cmd_done) ctl_state <= ST_SQTDB;
          if(send_cmd_done) ctl_state <= ST_DONE;
        end

        ST_SQTDB: begin
          write_sqtdbl <= 1'b1;
          sqt_addr <= sqt_addr + 64'd1;
          ctl_state <= ST_SQTDB_WAIT;
        end

        ST_SQTDB_WAIT: begin
          write_sqtdbl <= 1'b0;
          if(write_sqtdbl_done) begin
            ctl_state <= ST_CQHDB;
          end
        end

        ST_CQHDB: begin
          write_cqhdbl <= 1'b1;
          cqh_addr <= cqh_addr + 64'd1;
          ctl_state <= ST_CQHDB_WAIT;
        end

        ST_CQHDB_WAIT: begin
          write_cqhdbl <= 1'b0;
          flag <= 1'b1;
          if(write_cqhdbl_done) begin
            if(flag) ctl_state <= ST_DONE;
            else ctl_state <= ST_SQTDB;
          end
        end

        ST_DONE: begin

        end

      endcase
    end
  end

  

endmodule