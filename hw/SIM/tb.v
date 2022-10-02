//---------------------------------------
// Description: Top level testbench
//---------------------------------------
`timescale 1ps/1ps

module tb;
  parameter   REF_RP_CLK_FREQ       = 1;   // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  parameter   REF_EP_CLK_FREQ       = 0;   // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  parameter   LINK_WIDTH            = 1;   // 1 - x1
  parameter   REF_RP_CLK_HALF_CYCLE = (REF_RP_CLK_FREQ == 0) ? 5000 :
                                      (REF_RP_CLK_FREQ == 1) ? 4000 :
                                      (REF_RP_CLK_FREQ == 2) ? 2000 : 0;
  
  parameter   REF_EP_CLK_HALF_CYCLE = (REF_EP_CLK_FREQ == 0) ? 5000 :
                                      (REF_EP_CLK_FREQ == 1) ? 4000 :
                                      (REF_EP_CLK_FREQ == 2) ? 2000 : 0;


  integer            i;

  // System-level clock and reset
  reg     sys_rst_n;
  reg     sys_reset;

  wire    ep_sys_clk;
  wire    rp_sys_clk;
  wire    ep_sys_clk_p;
  wire    ep_sys_clk_n;
  wire    rp_sys_clk_p;
  wire    rp_sys_clk_n;

  // PCI-Express Serial Interconnect
  wire  [(LINK_WIDTH-1):0]  ep_pci_exp_txn;
  wire  [(LINK_WIDTH-1):0]  ep_pci_exp_txp;
  wire  [(LINK_WIDTH-1):0]  rp_pci_exp_txn;
  wire  [(LINK_WIDTH-1):0]  rp_pci_exp_txp;




  // Generate system clock and system-level reset signal
  sys_clk_gen_ds # (
    .halfcycle(REF_RP_CLK_HALF_CYCLE), 
    .offset(0)
  )
  CLK_GEN_RP (
    .sys_clk_p(rp_sys_clk_p),
    .sys_clk_n(rp_sys_clk_n)
  );

  sys_clk_gen_ds # (
    .halfcycle(REF_EP_CLK_HALF_CYCLE),
    .offset(0)
  )
  CLK_GEN_EP (
    .sys_clk_p(ep_sys_clk_p),
    .sys_clk_n(ep_sys_clk_n)
  );


  // Generate sys_reset
  initial begin
    sys_reset = 1'b0;
    repeat (1) @(posedge rp_sys_clk_p);

    sys_reset = 1'b1;
    $display("[%t] : System Reset Is Asserted...", $realtime);
    repeat (10) @(posedge rp_sys_clk_p);
   
    $display("[%t] : System Reset Is De-Asserted...", $realtime);
    sys_reset = 1'b0;
  end


  // DUT
  

  // EndPoint DUT with PIO Slave
  // PCI-Express Endpoint Instance
  xilinx_dma_pcie_ep EP (
    // SYS Inteface
    .sys_clk_n(ep_sys_clk_n),
    .sys_clk_p(ep_sys_clk_p),
    .sys_rst_n(!sys_reset),

    // PCI-Express Serial Interface
    .pci_exp_txn(ep_pci_exp_txn),
    .pci_exp_txp(ep_pci_exp_txp),
    .pci_exp_rxn(rp_pci_exp_txn),
    .pci_exp_rxp(rp_pci_exp_txp)
  );


  // PCI-Express Model Root Port Instance
  pcie_rp_top RP (
    // SYS Inteface
    .sys_clk_p(rp_sys_clk_p),
    .sys_clk_n(rp_sys_clk_n),
    .sys_rst_n(!sys_reset),

    // PCI-Express Serial Interface
    .pci_exp_txn(rp_pci_exp_txn),
    .pci_exp_txp(rp_pci_exp_txp),
    .pci_exp_rxn(ep_pci_exp_txn),
    .pci_exp_rxp(ep_pci_exp_txp)
  );



endmodule // Testbench
