module top (
  input logic [15:0] host_mgt_rxn,
  input logic [15:0] host_mgt_rxp,
  output logic [15:0] host_mgt_txn,
  output logic [15:0] host_mgt_txp,
  input logic host_perstn,
  input logic host_refclk_clk_n,
  input logic host_refclk_clk_p,
  input logic [3:0] oc0a_mgt_rxn,
  input logic [3:0] oc0a_mgt_rxp,
  output logic [3:0] oc0a_mgt_txn,
  output logic [3:0] oc0a_mgt_txp,
  input logic oc0a_refclk_clk_n,
  input logic oc0a_refclk_clk_p,
  output logic oc0a_perstn
);

design_1 design_1_inst (
  .host_mgt_rxn(host_mgt_rxn),
  .host_mgt_rxp(host_mgt_rxp),
  .host_mgt_txn(host_mgt_txn),
  .host_mgt_txp(host_mgt_txp),
  .host_perstn(host_perstn),
  .host_refclk_clk_n(host_refclk_clk_n),
  .host_refclk_clk_p(host_refclk_clk_p),
  .oc0a_mgt_rxn(oc0a_mgt_rxn),
  .oc0a_mgt_rxp(oc0a_mgt_rxp),
  .oc0a_mgt_txn(oc0a_mgt_txn),
  .oc0a_mgt_txp(oc0a_mgt_txp),
  .oc0a_refclk_clk_n(oc0a_refclk_clk_n),
  .oc0a_refclk_clk_p(oc0a_refclk_clk_p),
  .oc0a_perstn(oc0a_perstn)
);

endmodule