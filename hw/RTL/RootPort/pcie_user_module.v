module pcie_user_module #(
    parameter AXIS_TDATA_WIDTH = 64
)(
    input   wire user_clk,
    input   wire user_reset,
    input   wire user_lnk_up,

    output  wire [9 : 0]    cfg_mgmt_addr,
    output  wire [7 : 0]    cfg_mgmt_function_number,
    output  wire            cfg_mgmt_write,
    output  wire [31 : 0]   cfg_mgmt_write_data,
    output  wire [3 : 0]    cfg_mgmt_byte_enable,
    output  wire            cfg_mgmt_read,
    input   wire [31 : 0]   cfg_mgmt_read_data,
    input   wire            cfg_mgmt_read_write_done,
    output  wire            cfg_mgmt_debug_access,
    
    output  wire [63 : 0]   s_axis_rq_tdata,
    output  wire [1 : 0]    s_axis_rq_tkeep,
    output  wire            s_axis_rq_tlast,
    input   wire [3 : 0]    s_axis_rq_tready,
    output  wire [61 : 0]   s_axis_rq_tuser,
    output  wire            s_axis_rq_tvalid,
    input   wire [63 : 0]   m_axis_rc_tdata,
    input   wire [1 : 0]    m_axis_rc_tkeep,
    input   wire            m_axis_rc_tlast,
    output  wire            m_axis_rc_tready,
    input   wire [74 : 0]   m_axis_rc_tuser,
    input   wire            m_axis_rc_tvalid
);

wire [31:0] cfg2ctr_status;
wire [9:0]	reg_number;
wire [15:0]	completer_id;
wire [3:0]	req_type;
wire [10:0]	dword_count;

wire [2:0]  cpl_status;
wire [10:0] cpl_dword_count;
wire [12:0] cpl_byte_count;
wire        cpl_req_completed;
wire recv_data;

pcie_cfg_mgmt pcie_cfg_mgmt_inst(
  .user_clk(user_clk),
  .user_reset(user_reset),
  .user_lnk_up(user_lnk_up),
  .cfg_mgmt_addr(cfg_mgmt_addr),
  .cfg_mgmt_function_number(cfg_mgmt_function_number),
  .cfg_mgmt_write(cfg_mgmt_write),
  .cfg_mgmt_write_data(cfg_mgmt_write_data),
  .cfg_mgmt_byte_enable(cfg_mgmt_byte_enable),
  .cfg_mgmt_read(cfg_mgmt_read),
  .cfg_mgmt_read_data(cfg_mgmt_read_data),
  .cfg_mgmt_read_write_done(cfg_mgmt_read_write_done),
  .cfg_mgmt_debug_access(cfg_mgmt_debug_access),
  .cfg2ctr_status(cfg2ctr_status)
);

pcie_tlp_controller pcie_tlp_controller_inst(
  .user_clk(user_clk),
  .user_reset(user_reset),
  .user_lnk_up(user_lnk_up),
  .cfg2ctr_status(cfg2ctr_status),
  .reg_number(reg_number),
  .completer_id(completer_id),
  .req_type(req_type),
  .dword_count(dword_count),
  .recv_data(recv_data)
);


pcie_tlp_encoder pcie_tlp_encoder_inst(
  .user_clk(user_clk),
  .user_reset(user_reset),
  .user_lnk_up(user_lnk_up),
  .reg_number(reg_number),
  .completer_id(completer_id),
  .req_type(req_type),
  .dword_count(dword_count),
  .s_axis_rq_tdata(s_axis_rq_tdata),
  .s_axis_rq_tkeep(s_axis_rq_tkeep),
  .s_axis_rq_tlast(s_axis_rq_tlast),
  .s_axis_rq_tready(s_axis_rq_tready),
  .s_axis_rq_tuser(s_axis_rq_tuser),
  .s_axis_rq_tvalid(s_axis_rq_tvalid)
);


pcie_tlp_decoder pcie_tlp_decoder_inst(
  .user_clk(user_clk),
  .user_reset(user_reset),
  .user_lnk_up(user_lnk_up),
  .cpl_status(cpl_status),
  .cpl_dword_count(cpl_dword_count),
  .cpl_byte_count(cpl_byte_count),
  .cpl_req_completed(cpl_req_completed),
  .recv_data(recv_data),
  .m_axis_rc_tdata(m_axis_rc_tdata),
  .m_axis_rc_tkeep(m_axis_rc_tkeep),
  .m_axis_rc_tlast(m_axis_rc_tlast),
  .m_axis_rc_tready(m_axis_rc_tready),
  .m_axis_rc_tuser(m_axis_rc_tuser),
  .m_axis_rc_tvalid(m_axis_rc_tvalid)
);





endmodule