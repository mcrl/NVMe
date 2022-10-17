
`timescale 1ns/1ns

module nvme_pcie#
  ( 
  parameter [4:0]   PL_LINK_CAP_MAX_LINK_WIDTH     = 4,  // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16
  parameter         PL_LINK_CAP_MAX_LINK_SPEED     = 4,  // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4
  parameter         C_DATA_WIDTH                   = 256,  // RX/TX interface data width
  parameter         AXISTEN_IF_MC_RX_STRADDLE      = 1,
  parameter         KEEP_WIDTH                     = C_DATA_WIDTH / 32,
  parameter         REQUESTER_ID = 16'h0000,   // bus[7:0],dev[4:0],func[2:0] 
  parameter         COMPLETER_ID = 16'h0100,
  parameter       	AXI4_CQ_TUSER_WIDTH                   = 88,
  parameter       	AXI4_CC_TUSER_WIDTH                   = 33,
  parameter       	AXI4_RQ_TUSER_WIDTH                   = 62,
  parameter       	AXI4_RC_TUSER_WIDTH                   = 75,
  parameter         CSR_DATA_WIDTH = 256
  )
  (
    //-------------------------------------------------------
    // PCI Express (pci_exp) Interface
    //-------------------------------------------------------
    output [PL_LINK_CAP_MAX_LINK_WIDTH-1:0] pci_exp_txp,
    output [PL_LINK_CAP_MAX_LINK_WIDTH-1:0] pci_exp_txn,
    input  [PL_LINK_CAP_MAX_LINK_WIDTH-1:0] pci_exp_rxp,
    input  [PL_LINK_CAP_MAX_LINK_WIDTH-1:0] pci_exp_rxn,

    input                                   sys_clk_p,
    input                                   sys_clk_n,
    input 																	sys_reset,

    output                                  user_lnk_up,
    output                                  user_clk,
    output                                  user_reset,


    //-------------------------------------------------------
    // CSR Interface (Requests, Completions)
    //-------------------------------------------------------
    input       [CSR_DATA_WIDTH-1:0] csr_ioq_data,
    input                            csr_ioq_valid,
    output   	  [CSR_DATA_WIDTH-1:0] ioq_csr_data,
    output                           ioq_csr_valid
  );

  wire          rc_ioq_valid;
  wire [128:0]  rc_ioq_data;
  wire  [7:0]   rc_ioq_byten;
  wire  [7:0]   rc_ioq_tag;
  wire          rc_ioq_poison;
  wire  [3:0]   rc_ioq_errcode;
  wire  [2:0]   rc_ioq_status;
  wire          ioq_rc_ack;
  wire          icq_wfull;

  wire          ioq_rq_valid;
  wire   [3:0]  ioq_rq_reqType;
  wire  [63:0]  ioq_rq_addr;   
  wire [127:0]  ioq_rq_data;
  wire   [7:0]  ioq_rq_byten;
  wire  [10:0]  ioq_rq_dword;
  wire   [5:0]  ioq_rq_tag; 
  wire         	rq_ioq_ack;

  wire          [C_DATA_WIDTH-1:0]  s_axis_rq_tdata;
  wire            [KEEP_WIDTH-1:0]  s_axis_rq_tkeep;
  wire                              s_axis_rq_tlast;
  wire                       [3:0]  s_axis_rq_tready;
  wire   [AXI4_RQ_TUSER_WIDTH-1:0]  s_axis_rq_tuser;
  wire                              s_axis_rq_tvalid;

  wire         [C_DATA_WIDTH-1:0] 	m_axis_rc_tdata;
  wire           [KEEP_WIDTH-1:0] 	m_axis_rc_tkeep;
  wire                            	m_axis_rc_tlast;
  wire                            	m_axis_rc_tready;
  wire  [AXI4_RC_TUSER_WIDTH-1:0] 	m_axis_rc_tuser;
  wire                            	m_axis_rc_tvalid;

  //wire user_clk;
  //wire user_reset;
  //wire user_lnk_up;

  nvme_pcie_ioq #(

  ) pcie_ioq_inst (
    .user_clk                     (user_clk),
    .user_reset                   (user_reset),
    .user_lnk_up                 	(user_lnk_up),

    .csr_ioq_data 								(csr_ioq_data),
    .csr_ioq_valid								(csr_ioq_valid),
    .ioq_csr_data 								(ioq_csr_data),
    .ioq_csr_valid								(ioq_csr_valid),

    .ioq_rq_valid									(ioq_rq_valid),	
    .ioq_rq_reqType								(ioq_rq_reqType),	
    .ioq_rq_addr									(ioq_rq_addr),	
    .ioq_rq_data									(ioq_rq_data),	
    .ioq_rq_byten									(ioq_rq_byten),	
    .ioq_rq_dword									(ioq_rq_dword),	
    .ioq_rq_tag										(ioq_rq_tag),	
    .rq_ioq_ack										(rq_ioq_ack),	
//    .isq_wfull                    (isq_wfull),

    .rc_ioq_valid									(rc_ioq_valid),
    .rc_ioq_data									(rc_ioq_data),
    .rc_ioq_be										(rc_ioq_byten),
    .rc_ioq_tag										(rc_ioq_tag),
    .rc_ioq_poison								(rc_ioq_poison),
    .rc_ioq_errcode								(rc_ioq_errcode),
    .rc_ioq_status								(rc_ioq_status),
    .ioq_rc_ack										(ioq_rc_ack),
    .icq_wfull                    (icq_wfull)
   );


  nvme_pcie_rq #(

  ) pcie_rq_inst (
    .user_clk                     (user_clk),
    .user_reset                   (user_reset),
    .user_lnk_up                  (user_lnk_up),

    .s_axis_rq_tdata              (s_axis_rq_tdata),
    .s_axis_rq_tkeep              (s_axis_rq_tkeep),
    .s_axis_rq_tlast              (s_axis_rq_tlast),
    .s_axis_rq_tuser              (s_axis_rq_tuser),
    .s_axis_rq_tvalid             (s_axis_rq_tvalid),
    .s_axis_rq_tready             (s_axis_rq_tready),

    .ioq_rq_valid                 (ioq_rq_valid),
    .ioq_rq_reqType								(ioq_rq_reqType),
    .ioq_rq_addr                  (ioq_rq_addr),
    .ioq_rq_data                  (ioq_rq_data),
    .ioq_rq_byten                 (ioq_rq_byten),
    .ioq_rq_dword									(ioq_rq_dword),
    .ioq_rq_tag                   (ioq_rq_tag),
    .rq_ioq_ack                   (rq_ioq_ack)
  );
   

  nvme_pcie_rc #(

  ) pcie_rc_inst (
    .user_clk                    	(user_clk),
    .user_reset                   (user_reset),
    .user_lnk_up                  (user_lnk_up),

    .rc_ioq_valid                 (rc_ioq_valid),
    .rc_ioq_data                  (rc_ioq_data),
    .rc_ioq_be                    (rc_ioq_byten),
    .rc_ioq_tag                   (rc_ioq_tag),
    .rc_ioq_poison                (rc_ioq_poison),
    .rc_ioq_errcode               (rc_ioq_errcode),
    .rc_ioq_status                (rc_ioq_status),
    .ioq_rc_ack                   (ioq_rc_ack),
    .icq_wfull                    (icq_wfull),

    .m_axis_rc_tdata              (m_axis_rc_tdata),
    .m_axis_rc_tready             (m_axis_rc_tready),
    .m_axis_rc_tkeep              (m_axis_rc_tkeep),
    .m_axis_rc_tlast              (m_axis_rc_tlast),
    .m_axis_rc_tuser              (m_axis_rc_tuser),
    .m_axis_rc_tvalid             (m_axis_rc_tvalid)
  );

        
  nvme_pcie_ip_wrapper #(

  ) nvme_pcie_ip_wrapper_inst (
    .pci_exp_txp                    (pci_exp_txp),
    .pci_exp_txn                    (pci_exp_txn),
    .pci_exp_rxp                    (pci_exp_rxp),
    .pci_exp_rxn                    (pci_exp_rxn),
    .sys_clk_p              	 			(sys_clk_p),
    .sys_clk_n              	 			(sys_clk_n),        
    .sys_reset                    	(sys_reset),
    .user_clk                       (user_clk),
    .user_reset                     (user_reset),
    .user_lnk_up                    (user_lnk_up),
    .s_axis_rq_tdata                (s_axis_rq_tdata),
    .s_axis_rq_tkeep                (s_axis_rq_tkeep),
    .s_axis_rq_tlast                (s_axis_rq_tlast),
    .s_axis_rq_tready               (s_axis_rq_tready),
    .s_axis_rq_tuser                (s_axis_rq_tuser),
    .s_axis_rq_tvalid               (s_axis_rq_tvalid),
    .m_axis_rc_tdata                (m_axis_rc_tdata),
    .m_axis_rc_tkeep                (m_axis_rc_tkeep),
    .m_axis_rc_tlast                (m_axis_rc_tlast),
    .m_axis_rc_tready               (m_axis_rc_tready),
    .m_axis_rc_tuser                (m_axis_rc_tuser),
    .m_axis_rc_tvalid               (m_axis_rc_tvalid)
  );


   
endmodule


