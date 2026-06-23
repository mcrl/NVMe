# Build the fpga-nvme-driver bitstream: open project, ensure tagfifo.sv + nvme_bringup.sv are in the
# source set, then synth + impl + write_bitstream. Run: vivado -mode batch -source hw/scripts/build.tcl
set root /home/junsik/workspace/NVMe
set xpr  $root/hw/synth/fpga-nvme-driver/fpga-nvme-driver.xpr
set ::env(XILINXD_LICENSE_FILE) /home/junsik/Xilinx.lic
open_project $xpr
puts "BUILD: opened part=[get_property PART [current_project]] top=[get_property TOP [current_fileset]]"

# ---- ensure the non-project RTL added after project creation is present ----
foreach f {tagfifo.sv nvme_bringup.sv dpram_be.sv ddr4_engine.sv copy_engine.sv ddr4_test.sv} {
  if {[llength [get_files -quiet $f]] == 0} {
    add_files -norecurse -fileset sources_1 $root/hw/rtl/$f
    puts "BUILD: added $f"
  }
}
# PL DDR4 pin LOC constraints (IOSTANDARD/byte-groups come from the ddr4_0 IP's own xdc)
if {[llength [get_files -quiet ddr4_loc.xdc]] == 0} {
  add_files -norecurse -fileset constrs_1 $root/hw/constraints/ddr4_loc.xdc
  puts "BUILD: added ddr4_loc.xdc"
}
# create the PL DDR4 IP if the project doesn't have it (custom 4 GB DDR4-2400 part, 300 MHz ref, 256-bit AXI, ECC)
if {[llength [get_ips -quiet ddr4_0]] == 0} {
  create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name ddr4_0
  set_property -dict [list \
    CONFIG.C0.DDR4_TimePeriod {833} CONFIG.C0.DDR4_InputClockPeriod {3332} \
    CONFIG.C0.DDR4_MemoryType {Components} CONFIG.C0.DDR4_isCustom {true} \
    CONFIG.C0.DDR4_CustomParts "$root/hw/ddr/DDR4_2400_250SP.csv" \
    CONFIG.C0.DDR4_MemoryPart {DDR4_2400_250SP} CONFIG.C0.DDR4_DataWidth {72} \
    CONFIG.C0.DDR4_DataMask {NO_DM_NO_DBI} CONFIG.C0.DDR4_Ecc {true} \
    CONFIG.C0.DDR4_CasLatency {17} CONFIG.C0.DDR4_CasWriteLatency {12} \
    CONFIG.C0.DDR4_AxiSelection {true} CONFIG.C0.DDR4_AxiDataWidth {256} \
    CONFIG.C0.DDR4_AxiAddressWidth {32} CONFIG.C0.DDR4_AxiIDWidth {4} \
    CONFIG.C0.DDR4_AxiNarrowBurst {false} ] [get_ips ddr4_0]
  generate_target {synthesis instantiation_template} [get_ips ddr4_0]
  puts "BUILD: created ddr4_0 IP"
}
update_compile_order -fileset sources_1

catch {set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs synth_1]}
catch {set_property INCREMENTAL_CHECKPOINT {} [get_runs synth_1]}
if {[catch {upgrade_ip -quiet [get_ips]} err]} { puts "BUILD: upgrade_ip note: $err" }
foreach bd [get_files -quiet *.bd] { catch {generate_target all [get_files $bd]} }
catch {generate_target all [get_ips]}

puts "BUILD: SYNTH-START"
foreach r [get_runs] { catch {reset_run $r} }
launch_runs synth_1 -jobs 16
wait_on_run synth_1
set sp [get_property PROGRESS [get_runs synth_1]]
if {$sp ne "100%"} { puts "BUILD-FATAL: synthesis failed ($sp)"; exit 1 }
puts "BUILD: SYNTH-COMPLETE"

puts "BUILD: IMPL-START"
launch_runs impl_1 -to_step write_bitstream -jobs 16
wait_on_run impl_1
set ipr [get_property PROGRESS [get_runs impl_1]]
if {$ipr ne "100%"} { puts "BUILD-FATAL: implementation/bitstream failed ($ipr)"; exit 1 }
puts "BUILD: IMPL-COMPLETE"
set rundir [get_property DIRECTORY [get_runs impl_1]]
puts "BUILD: bitstream = [glob -nocomplain $rundir/*.bit]"
catch { open_run impl_1; puts "BUILD: timing WNS=[get_property STATS.WNS [get_runs impl_1]] WHS=[get_property STATS.WHS [get_runs impl_1]]" }
puts "BUILD: DONE"
exit 0
