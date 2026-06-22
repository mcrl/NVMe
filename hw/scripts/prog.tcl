# Program card 0's PL over JTAG with the built bitstream.
# Prereqs: sudo modprobe -r ftdi_sio usbserial ; sudo setsid <vivado>/bin/hw_server -d
# Run: sudo vivado -mode batch -source hw/scripts/prog.tcl
proc say {m} { puts $m; flush stdout }
set bitfile /home/junsik/workspace/NVMe/hw/synth/fpga-nvme-driver/fpga-nvme-driver.runs/impl_1/top.bit
set tgt {localhost:3121/xilinx_tcf/Digilent/210249BE4B03}
say "PROG: start bit=$bitfile"
if {[catch {open_hw_manager} e]} { say "PROG-ERR open_hw_manager: $e"; exit 2 }
if {[catch {connect_hw_server -url localhost:3121} e]} { say "PROG-ERR connect: $e"; exit 2 }
say "PROG: targets=[get_hw_targets -quiet]"
if {[catch {open_hw_target -quiet $tgt} e]} { say "PROG-ERR open_target: $e"; exit 2 }
set dev [lindex [get_hw_devices -quiet xczu19*] 0]
current_hw_device $dev
refresh_hw_device -quiet -update_hw_probes false $dev
set_property PROGRAM.FILE $bitfile $dev
say "PROG: programming PL (~1-2 min over JTAG)..."
if {[catch {program_hw_devices $dev} e]} { say "PROG-ERR program: $e"; exit 3 }
refresh_hw_device -quiet $dev
catch {close_hw_target -quiet}
say "PROG: COMPLETE"
exit 0
