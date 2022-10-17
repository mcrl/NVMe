`timescale 1ns/1ns

module nvme_top#
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
    // OcuLink0 Interface
    //-------------------------------------------------------
    //output [PL_LINK_CAP_MAX_LINK_WIDTH-1:0] oc0_pcie_tx,
    
    output [PL_LINK_CAP_MAX_LINK_WIDTH-1:0] pcie_0a_txp,
    output [PL_LINK_CAP_MAX_LINK_WIDTH-1:0] pcie_0a_txn,

    input  [PL_LINK_CAP_MAX_LINK_WIDTH-1:0] pcie_0a_rxp,
    input  [PL_LINK_CAP_MAX_LINK_WIDTH-1:0] pcie_0a_rxn,

    input   oc0_cprsnt_n,
    output   oc0_perst_n,
    //input   pcie_0a_sys_clk_p,
    //input   pcie_0a_sys_clk_n
    input pcie_0a_sys_clk,
    input sys_rst_n
  );
/*
  assign oc0_perst_n = 1'b1;
  wire sys_clk;
  
  IBUFDS_GTE4 sys_clk_ibuf(
    .I(pcie_0a_sys_clk_p),
    .IB(pcie_0a_sys_clk_n),
    .CEB(1'b0),
    .O(sys_clk),
    .ODIV2()
  );

  reg sys_reset;
  initial begin
    sys_reset = 1'b1;
    repeat (500) @(posedge sys_clk);
    sys_reset = 1'b0;
  end
  
  assign oc_perst_n = sys_reset;
*/

  wire [255:0]  csr_ioq_data;
  wire          csr_ioq_valid;
  wire user_lnk_up;
  wire user_reset;
  wire user_clk;

  csr csr_inst(
    .user_lnk_up(user_lnk_up),
    .user_clk(user_clk),
    .user_reset(user_reset),
    .csr_ioq_data(csr_ioq_data),
    .csr_ioq_valid(csr_ioq_valid)    
  );


  nvme_pcie RP (
    // SYS Inteface
    .sys_clk_n(!pcie_0a_sys_clk),
    .sys_clk_p(pcie_0a_sys_clk),
    .sys_reset(!sys_rst_n),

    .user_lnk_up(user_lnk_up),
    .user_clk(user_clk),
    .user_reset(user_reset),
    .csr_ioq_data(csr_ioq_data),
    .csr_ioq_valid(csr_ioq_valid),

    // PCI-Express Serial Interface
    .pci_exp_txn(pcie_0a_txn),
    .pci_exp_txp(pcie_0a_txp),
    .pci_exp_rxn(pcie_0a_rxn),
    .pci_exp_rxp(pcie_0a_rxp)
  );
  

endmodule