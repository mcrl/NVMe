# Create + configure the PL DDR4 (MIG) IP for the 250-SoC board: custom 4 GB DDR4-2400 part (CSV), 300 MHz
# input ref clock (J19), 256-bit AXI, ECC (72-bit). Validate the config + dump the IP ports (no synth).
# Run: vivado -mode batch -source hw/scripts/mk_ddr4.tcl
set root /home/junsik/workspace/NVMe
set ::env(XILINXD_LICENSE_FILE) /home/junsik/Xilinx.lic
open_project $root/hw/synth/fpga-nvme-driver/fpga-nvme-driver.xpr
puts "DDR4: part=[get_property PART [current_project]]"

if {[llength [get_ips -quiet ddr4_0]] == 0} {
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name ddr4_0
}
set_property -dict [list \
  CONFIG.C0.DDR4_TimePeriod {833} \
  CONFIG.C0.DDR4_InputClockPeriod {3332} \
  CONFIG.C0.DDR4_MemoryType {Components} \
  CONFIG.C0.DDR4_isCustom {true} \
  CONFIG.C0.DDR4_CustomParts "$root/hw/ddr/DDR4_2400_250SP.csv" \
  CONFIG.C0.DDR4_MemoryPart {DDR4_2400_250SP} \
  CONFIG.C0.DDR4_DataWidth {72} \
  CONFIG.C0.DDR4_DataMask {NO_DM_NO_DBI} \
  CONFIG.C0.DDR4_Ecc {true} \
  CONFIG.C0.DDR4_CasLatency {17} \
  CONFIG.C0.DDR4_CasWriteLatency {12} \
  CONFIG.C0.DDR4_AxiSelection {true} \
  CONFIG.C0.DDR4_AxiDataWidth {256} \
  CONFIG.C0.DDR4_AxiAddressWidth {32} \
  CONFIG.C0.DDR4_AxiIDWidth {4} \
  CONFIG.C0.DDR4_AxiNarrowBurst {false} \
] [get_ips ddr4_0]

puts "DDR4: config applied; generating..."
generate_target {instantiation_template synthesis} [get_ips ddr4_0]
puts "DDR4: ports ="
foreach p [lsort [get_property -quiet PORTS [get_ips ddr4_0]]] { puts "   $p" }
# also dump the top-level interface ports via the instantiation template if present
set veo [glob -nocomplain $root/hw/synth/fpga-nvme-driver/fpga-nvme-driver.gen/sources_1/ip/ddr4_0/*.veo]
puts "DDR4: veo = $veo"
puts "DDR4: DONE"
exit 0
