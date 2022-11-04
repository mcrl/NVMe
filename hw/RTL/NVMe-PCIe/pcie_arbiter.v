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
/*
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
  input                     [3:0]     s_axis_cc_tready,
*/
  input                              cfg_done,
  input        [C_DATA_WIDTH-1:0]    cfg_s_axis_rq_tdata,
  input [AXI4_RQ_TUSER_WIDTH-1:0]    cfg_s_axis_rq_tuser,
  input          [KEEP_WIDTH-1:0]    cfg_s_axis_rq_tkeep,
  input                              cfg_s_axis_rq_tlast,
  input                              cfg_s_axis_rq_tvalid,
  output                     [3:0]   cfg_s_axis_rq_tready,

  output        [C_DATA_WIDTH-1:0]   cfg_m_axis_rc_tdata,
  output [AXI4_RC_TUSER_WIDTH-1:0]   cfg_m_axis_rc_tuser,
  output          [KEEP_WIDTH-1:0]   cfg_m_axis_rc_tkeep,
  output                             cfg_m_axis_rc_tlast,
  output                             cfg_m_axis_rc_tvalid,
  input                              cfg_m_axis_rc_tready,

  input        [C_DATA_WIDTH-1:0]    db_s_axis_rq_tdata,
  input [AXI4_RQ_TUSER_WIDTH-1:0]    db_s_axis_rq_tuser,
  input          [KEEP_WIDTH-1:0]    db_s_axis_rq_tkeep,
  input                              db_s_axis_rq_tlast,
  input                              db_s_axis_rq_tvalid,
  output                     [3:0]   db_s_axis_rq_tready
);


  // Requester reQuest Mux
  assign s_axis_rq_tdata = (cfg_done) ? db_s_axis_rq_tdata : cfg_s_axis_rq_tdata;
  assign s_axis_rq_tuser = (cfg_done) ? db_s_axis_rq_tuser : cfg_s_axis_rq_tuser;
  assign s_axis_rq_tkeep = (cfg_done) ? db_s_axis_rq_tkeep : cfg_s_axis_rq_tkeep;
  assign s_axis_rq_tvalid = (cfg_done) ? db_s_axis_rq_tvalid : cfg_s_axis_rq_tvalid;
  assign s_axis_rq_tlast = (cfg_done) ? db_s_axis_rq_tlast : cfg_s_axis_rq_tlast;
  assign cfg_s_axis_rq_tready = (cfg_done) ? 1'b0 : s_axis_rq_tready;
  assign db_s_axis_rq_tready = (cfg_done) ? s_axis_rq_tready : 1'b0;
  
  // Requester Completion Mux
  assign cfg_m_axis_rc_tdata = m_axis_rc_tdata;
  assign cfg_m_axis_rc_tuser = m_axis_rc_tuser;
  assign cfg_m_axis_rc_tkeep = m_axis_rc_tkeep;
  assign cfg_m_axis_rc_tlast = m_axis_rc_tlast;
  assign cfg_m_axis_rc_tvalid = m_axis_rc_tvalid;
  assign m_axis_rc_tready = cfg_m_axis_rc_tready;
  

endmodule