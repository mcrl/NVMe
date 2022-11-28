module tx (
  // User Interface
  input   wire  user_clk,
  input   wire  user_reset,
  input   wire  user_lnk_up
);


  localparam  STATE_IDLE                = 4'd0;
  localparam  STATE_TYPE1_CFG_WRITE     = 4'd1;
  localparam  STATE_TYPE1_CFG_READ      = 4'd2;
  localparam  STATE_WAIT_FOR_READ_DATA  = 4'd3;

  reg [3:0] state;



endmodule
