
`timescale 1ps / 1ps
(* DowngradeIPIdentifiedWarnings = "yes" *)
module nvme_top (
  // Oculink ch0 Interface
  output  [3 : 0]  pcie_0a_txp,
  output  [3 : 0]  pcie_0a_txn,
  input   [3 : 0]  pcie_0a_rxp,
  input   [3 : 0]  pcie_0a_rxn,
  input            pcie_0a_sys_clk_p,
  input            pcie_0a_sys_clk_n,
  output           oc0_a_perst_n,
  input            oc0_a_cprsnt,

  // System Interface
  input            sys_rst_n
  );


  // System(SYS) Interface 
  wire sys_rst_n_c;
  IBUF sys_reset_n_ibuf (
    .I(sys_rst_n),
    .O(sys_rst_n_c)
  );


  oculink_port oculink_ch0 (
    .pci_exp_txp       (pcie_0a_txp),
    .pci_exp_txn       (pcie_0a_txn),
    .pci_exp_rxp       (pcie_0a_rxp),
    .pci_exp_rxn       (pcie_0a_rxn),
    .sys_clk_p         (pcie_0a_sys_clk_p),
    .sys_clk_n         (pcie_0a_sys_clk_n),
    .sys_rst_n_c       (sys_rst_n_c),
    .perst_n           (oc0_a_perst_n),
    .cprsnt            (oc0_a_cprsnt)
  );


endmodule