# PCIe 100MHz refclk
set_property PACKAGE_PIN AH10 [get_ports host_refclk_clk_p]
create_clock -period 10.000 -name host_refclk -waveform {0.000 5.000} [get_ports host_refclk_clk_p]
set_input_jitter [get_clocks -of_objects [get_ports host_refclk_clk_p]] 0.200

# PCIe reset
set_property PACKAGE_PIN AM16 [get_ports host_perstn]
set_property IOSTANDARD LVCMOS18 [get_ports host_perstn]
set_false_path -from [get_ports host_perstn]

# Oculink0 100MHz refclk
set_property PACKAGE_PIN P32 [get_ports oc0a_refclk_clk_p]
create_clock -period 10.000 -name oc0a_refclk -waveform {0.000 5.000} [get_ports oc0a_refclk_clk_p]
set_input_jitter [get_clocks -of_objects [get_ports oc0a_refclk_clk_p]] 0.200

# Oculink0 reset
set_property PACKAGE_PIN A14 [get_ports oc0a_perstn]
set_property IOSTANDARD LVCMOS33 [get_ports oc0a_perstn]
set_false_path -to [get_ports oc0a_perstn]

# false_path on reset signals
# TODO kernel/driver_rstn
#set_false_path -from [get_cells design_1_inst/kernel_inst/ocu_rstn_reg]
#set_false_path -from [get_cells bd0_inst/xdma_0/inst/pcie4_ip_i/inst/user_reset_reg]