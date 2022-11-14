module top (
  input logic [15:0] pcie_mgt_rxn,
  input logic [15:0] pcie_mgt_rxp,
  output logic [15:0] pcie_mgt_txn,
  output logic [15:0] pcie_mgt_txp,
  input logic pcie_perstn,
  input logic pcie_refclk_clk_n,
  input logic pcie_refclk_clk_p
);

logic [14:0] host_bram_addr;
logic host_bram_clk;
logic [31:0] host_bram_din;
logic [31:0] host_bram_dout;
logic host_bram_en;
logic host_bram_rst;
logic [3:0] host_bram_we;

bd0 bd0_inst (
  .host_bram_addr(host_bram_addr),
  .host_bram_clk(host_bram_clk),
  .host_bram_din(host_bram_din),
  .host_bram_dout(host_bram_dout),
  .host_bram_en(host_bram_en),
  .host_bram_rst(host_bram_rst),
  .host_bram_we(host_bram_we),
  .pcie_mgt_rxn(pcie_mgt_rxn),
  .pcie_mgt_rxp(pcie_mgt_rxp),
  .pcie_mgt_txn(pcie_mgt_txn),
  .pcie_mgt_txp(pcie_mgt_txp),
  .pcie_perstn(pcie_perstn),
  .pcie_refclk_clk_n(pcie_refclk_clk_n),
  .pcie_refclk_clk_p(pcie_refclk_clk_p)
);

kernel kernel_inst (
  .host_addr(host_bram_addr),
  .host_clk(host_bram_clk),
  .host_din(host_bram_din),
  .host_dout(host_bram_dout),
  .host_en(host_bram_en),
  .host_rst(host_bram_rst),
  .host_we(host_bram_we)
);

endmodule
