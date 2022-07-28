module tb;
 
  localparam REF_CLK_FREQ = 0;  // 0 : 100MHz, 1 : 125 MHz, 2 : 250 MHz
  localparam REF_CLK_HALF_CYCLE = (REF_CLK_FREQ == 0) ? 5000 :
                                  (REF_CLK_FREQ == 1) ? 4000 :
                                  (REF_CLK_FREQ == 2) ? 2000 : 0;

  // System signals
  reg sys_rst_n;
  wire rp_sys_clk_p;
  wire rp_sys_clk_n;
  wire ep_sys_clk_p;
  wire ep_sys_clk_n;

  // PCIe serial 
  wire pci_exp_txp;
  wire pci_exp_txn;
  wire pci_exp_rxp;
  wire pci_exp_rxn;

  // simulation clock & reset signal generation
  sys_clk_gen_ds #(
    .halfcycle(REF_CLK_HALF_CYCLE),
    .offset(0)
  ) CLK_GEN_RP (
    .sys_clk_p(rp_sys_clk_p),
    .sys_clk_n(rp_sys_clk_n)
  );
  
  sys_clk_gen_ds #(
    .halfcycle(REF_CLK_HALF_CYCLE),
    .offset(0)
  ) CLK_GEN_EP (
    .sys_clk_p(ep_sys_clk_p),
    .sys_clk_n(ep_sys_clk_n)
  );

  initial begin
    $display("System Reset Is Asserted");
    sys_rst_n = 1'b0;
    repeat (500) @(posedge rp_sys_clk_p);
    $display("System Reset Is De-asserted");
    sys_rst_n = 1'b1;
  end

  // PCIe RootPort Device (FPGA + NVMe IP + DMA engine)
  top top_inst(
    // System Interface
    .sys_clk_p(rp_sys_clk_p),
    .sys_clk_n(rp_sys_clk_n),
    .sys_rst_n(sys_rst_n),

    // PCIe Serial Interface
    .pci_exp_txp(pci_exp_txp),
    .pci_exp_txn(pci_exp_txn),
    .pci_exp_rxp(pci_exp_rxp),
    .pci_exp_rxn(pci_exp_rxn)
  );


  // PCIe Endpoint Device (hope to be NVMe Controller + NVM)
  xilinx_dma_pcie_ep EP(
    // System Interface
    .sys_clk_p(ep_sys_clk_p),
    .sys_clk_n(ep_sys_clk_n),
    .sys_rst_n(sys_rst_n),
    
    // PCIe Serial Interface
    .pci_exp_txp(pci_exp_rxp),
    .pci_exp_txn(pci_exp_rxn),
    .pci_exp_rxp(pci_exp_txp),
    .pci_exp_rxn(pci_exp_txn)
  );


endmodule // tb
