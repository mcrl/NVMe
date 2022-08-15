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

  // Host to FPGA, FPGA to Host signals
  reg           h2f_csr_read;
  reg           h2f_csr_write;
  reg   [31:0]  h2f_csr_addr;
  reg   [511:0] h2f_csr_wrData;
  wire  [511:0] f2h_csr_rdData;



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


  // sys_reset : active HIGH
  initial begin
    sys_reset = 1'b0;
    repeat (1) @(posedge rp_sys_clk_p);

    sys_reset = 1'b1;
    $display("[%t] : System Reset Is Asserted...", $realtime);
    repeat (10) @(posedge rp_sys_clk_p);
   
    $display("[%t] : System Reset Is De-Asserted...", $realtime);
    sys_reset = 1'b0;
  end



  // TESTs
  //


  initial begin
    wait(sys_reset == 1'b1);
    repeat (500) @(posedge rp_sys_clk_p);
    $display("[%t] : *** Tests start ***", $realtime);  

    h2f_csr_addr    = 32'h0000_0000;
    h2f_csr_wrData  = 512'd10;
    h2f_csr_write   = 1'b1;
    h2f_csr_read    = 1'b0;
    $display("[%t] : Write Data [%x] in CSR reg addr [%x]", $realtime, h2f_csr_wrData, h2f_csr_addr);  
    repeat (10) @(posedge rp_sys_clk_p);
    h2f_csr_write   = 1'b0;
    h2f_csr_wrData  = 512'd0;
    repeat (10) @(posedge rp_sys_clk_p);

    h2f_csr_addr    = 32'h0000_0000;
    h2f_csr_read    = 1'b1;
    repeat (10) @(posedge rp_sys_clk_p);
    $display("[%t] : Read Data [%x]  in CSR reg addr [%x]", $realtime, f2h_csr_rdData, h2f_csr_addr);  

    h2f_csr_read    = 1'b0;
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



  // Simulation Root Port Model
  // PCI-Express Model Root Port Instance
  RootComplex RC (
    // SYS Inteface
    .sys_clk(rp_sys_clk_p),
    .sys_reset(sys_reset),

    // Host to FPGA signals
    .h2f_csr_read(h2f_csr_read),                                          // input  wire          h2f_csr_read
    .h2f_csr_write(h2f_csr_write),                                        // input  wire          h2f_csr_write
    .h2f_csr_addr(h2f_csr_addr),                                          // input  wire [31:0]   h2f_csr_addr
    .h2f_csr_wrData(h2f_csr_wrData),                                      // input  wire [511:0]  h2f_csr_wrData
    
    // FPGA to Host signals
    .f2h_csr_rdData(f2h_csr_rdData),                                      // output wire [511:0]  f2h_csr_rdData

    // PCI-Express Serial Interface
    .pci_exp_txn(rp_pci_exp_txn),
    .pci_exp_txp(rp_pci_exp_txp),
    .pci_exp_rxn(ep_pci_exp_txn),
    .pci_exp_rxp(ep_pci_exp_txp)
  );



endmodule // Testbench
