// PCIe Arbiter

module pcie_arbiter   #(
  // AXIS Parameters
  parameter        AXI4_CQ_TUSER_WIDTH                    = 88,
  parameter        AXI4_CC_TUSER_WIDTH                    = 33,
  parameter        AXI4_RQ_TUSER_WIDTH                    = 62,
  parameter        AXI4_RC_TUSER_WIDTH                    = 75,
  parameter        C_DATA_WIDTH                           = 128,
  parameter        KEEP_WIDTH                             = C_DATA_WIDTH / 32
) (

  // System Interface
  
  input wire                user_clk,
  input wire                user_reset,
  input wire                user_lnk_up,

  // PCIe IP Interface

  output        [C_DATA_WIDTH-1:0]    s_axis_rq_tdata,
  output [AXI4_RQ_TUSER_WIDTH-1:0]    s_axis_rq_tuser,
  output          [KEEP_WIDTH-1:0]    s_axis_rq_tkeep,
  output                              s_axis_rq_tlast,
  output                              s_axis_rq_tvalid,
  input                     [3:0]     s_axis_rq_tready,

  input        [C_DATA_WIDTH-1:0]     m_axis_rc_tdata,
  input [AXI4_RC_TUSER_WIDTH-1:0]     m_axis_rc_tuser,
  input          [KEEP_WIDTH-1:0]     m_axis_rc_tkeep,
  input                               m_axis_rc_tlast,
  input                               m_axis_rc_tvalid,
  output                              m_axis_rc_tready,

  input        [C_DATA_WIDTH-1:0]     m_axis_cq_tdata,
  input [AXI4_CQ_TUSER_WIDTH-1:0]     m_axis_cq_tuser,
  input          [KEEP_WIDTH-1:0]     m_axis_cq_tkeep,
  input                               m_axis_cq_tlast,
  input                               m_axis_cq_tvalid,
  output                              m_axis_cq_tready,

  output        [C_DATA_WIDTH-1:0]    s_axis_cc_tdata,
  output [AXI4_CC_TUSER_WIDTH-1:0]    s_axis_cc_tuser,
  output          [KEEP_WIDTH-1:0]    s_axis_cc_tkeep,
  output                              s_axis_cc_tlast,
  output                              s_axis_cc_tvalid,
  input                     [3:0]     s_axis_cc_tready


);



  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

endmodule