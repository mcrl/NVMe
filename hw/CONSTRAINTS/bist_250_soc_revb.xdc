# ------------------------------
# Pin Locations & I/O Standards
# ------------------------------
#set_property PACKAGE_PIN K20 [get_ports emcclk]

# Pin K20 is not a GC pin, so need to use non-dedicated clock routing.
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets emcclk]

#set_property IOSTANDARD LVCMOS18 [get_ports emcclk]


# Differential Global Clocks
set_property PACKAGE_PIN J19 [get_ports ddr4_clk_p]
set_property PACKAGE_PIN J18 [get_ports ddr4_clk_n]

set_property IOSTANDARD DIFF_SSTL12 [get_ports ddr4_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports ddr4_clk_n]
set_property ODT RTT_48 [get_ports ddr4_clk_p]
set_property ODT RTT_48 [get_ports ddr4_clk_n]

# PCIe Clocks and Reset
set_property PACKAGE_PIN AH9 [get_ports pcie_clk0_n]
set_property PACKAGE_PIN AH10 [get_ports pcie_clk0_p]

set_property PACKAGE_PIN AM16 [get_ports pcie_perst_n]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_perst_n]

# LEDs
set_property PACKAGE_PIN B11 [get_ports {user_led[3]}]
set_property PACKAGE_PIN B10 [get_ports {user_led[2]}]
set_property PACKAGE_PIN B13 [get_ports {user_led[1]}]
set_property PACKAGE_PIN B12 [get_ports {user_led[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {user_led[*]}]

# OCuLink
set_property PACKAGE_PIN F15 [get_ports {oc_perst_n[5]}]
set_property PACKAGE_PIN F14 [get_ports {oc_perst_n[4]}]
set_property PACKAGE_PIN A10 [get_ports {oc_perst_n[3]}]
set_property PACKAGE_PIN A13 [get_ports {oc_perst_n[2]}]
set_property PACKAGE_PIN A15 [get_ports {oc_perst_n[1]}]
set_property PACKAGE_PIN A14 [get_ports {oc_perst_n[0]}]

set_property PACKAGE_PIN C12 [get_ports {oc_bp_type[5]}]
set_property PACKAGE_PIN C14 [get_ports {oc_bp_type[4]}]
set_property PACKAGE_PIN D13 [get_ports {oc_bp_type[3]}]
set_property PACKAGE_PIN D15 [get_ports {oc_bp_type[2]}]
set_property PACKAGE_PIN E12 [get_ports {oc_bp_type[1]}]
set_property PACKAGE_PIN F13 [get_ports {oc_bp_type[0]}]

set_property PACKAGE_PIN D12 [get_ports {oc_cprsnt_n[5]}]
set_property PACKAGE_PIN C15 [get_ports {oc_cprsnt_n[4]}]
set_property PACKAGE_PIN D14 [get_ports {oc_cprsnt_n[3]}]
set_property PACKAGE_PIN E15 [get_ports {oc_cprsnt_n[2]}]
set_property PACKAGE_PIN E13 [get_ports {oc_cprsnt_n[1]}]
set_property PACKAGE_PIN G14 [get_ports {oc_cprsnt_n[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {oc_perst_n[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {oc_bp_type[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {oc_cprsnt_n[*]}]

# QSFP Sideband
set_property PACKAGE_PIN L12 [get_ports qsfp0_lp_mode]
set_property PACKAGE_PIN L13 [get_ports qsfp0_rst_n]
set_property PACKAGE_PIN J15 [get_ports qsfp0_mod_prs_n]
set_property PACKAGE_PIN K15 [get_ports qsfp0_int_n]
set_property PACKAGE_PIN K12 [get_ports qsfp1_lp_mode]
set_property PACKAGE_PIN K13 [get_ports qsfp1_rst_n]
set_property PACKAGE_PIN J13 [get_ports qsfp1_mod_prs_n]
set_property PACKAGE_PIN J14 [get_ports qsfp1_int_n]

set_property IOSTANDARD LVCMOS33 [get_ports qsfp0_lp_mode]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp0_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp0_mod_prs_n]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp0_int_n]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp1_lp_mode]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp1_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp1_mod_prs_n]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp1_int_n]

# I2C Interfaces
set_property PACKAGE_PIN H14 [get_ports smbclk_user_i2c]
set_property PACKAGE_PIN H15 [get_ports smbdat_user_i2c]
set_property PACKAGE_PIN P14 [get_ports rst_user_i2c_n]
set_property PACKAGE_PIN G12 [get_ports smbclk_tmp_prom]
set_property PACKAGE_PIN G13 [get_ports smbdat_tmp_prom]
set_property PACKAGE_PIN H12 [get_ports smbclk_user_ucd]
set_property PACKAGE_PIN J12 [get_ports smbdat_user_ucd]
set_property PACKAGE_PIN P15 [get_ports margin_en_n]
set_property PACKAGE_PIN N15 [get_ports margin_high]
set_property PACKAGE_PIN R15 [get_ports fpga_smbus_en_n]

set_property IOSTANDARD LVCMOS33 [get_ports smbclk_user_i2c]
set_property IOSTANDARD LVCMOS33 [get_ports smbdat_user_i2c]
set_property IOSTANDARD LVCMOS33 [get_ports rst_user_i2c_n]
set_property IOSTANDARD LVCMOS33 [get_ports smbclk_tmp_prom]
set_property IOSTANDARD LVCMOS33 [get_ports smbdat_tmp_prom]
set_property IOSTANDARD LVCMOS33 [get_ports smbclk_user_ucd]
set_property IOSTANDARD LVCMOS33 [get_ports smbdat_user_ucd]
set_property IOSTANDARD LVCMOS33 [get_ports margin_en_n]
set_property IOSTANDARD LVCMOS33 [get_ports margin_high]
set_property IOSTANDARD LVCMOS33 [get_ports fpga_smbus_en_n]

# UCD Control & Status
set_property PACKAGE_PIN M14 [get_ports volt_warn]
set_property IOSTANDARD LVCMOS33 [get_ports volt_warn]

# Aurora Clocks
set_property PACKAGE_PIN P33 [get_ports oc0_a_refclk_n]
set_property PACKAGE_PIN P32 [get_ports oc0_a_refclk_p]
set_property PACKAGE_PIN V33 [get_ports oc0_b_refclk_n]
set_property PACKAGE_PIN V32 [get_ports oc0_b_refclk_p]
set_property PACKAGE_PIN AF33 [get_ports oc1_a_refclk_n]
set_property PACKAGE_PIN AF32 [get_ports oc1_a_refclk_p]
set_property PACKAGE_PIN AB33 [get_ports oc1_b_refclk_n]
set_property PACKAGE_PIN AB32 [get_ports oc1_b_refclk_p]
set_property PACKAGE_PIN Y9 [get_ports oc2_a_refclk_n]
set_property PACKAGE_PIN Y10 [get_ports oc2_a_refclk_p]
set_property PACKAGE_PIN V9 [get_ports oc2_b_refclk_n]
set_property PACKAGE_PIN V10 [get_ports oc2_b_refclk_p]
set_property PACKAGE_PIN AD9 [get_ports oc3_a_refclk_n]
set_property PACKAGE_PIN AD10 [get_ports oc3_a_refclk_p]
set_property PACKAGE_PIN AB9 [get_ports oc3_b_refclk_n]
set_property PACKAGE_PIN AB10 [get_ports oc3_b_refclk_p]

set_property PACKAGE_PIN T33 [get_ports opca0_refclk_n]
set_property PACKAGE_PIN T32 [get_ports opca0_refclk_p]
set_property PACKAGE_PIN AH33 [get_ports opca1_refclk_n]
set_property PACKAGE_PIN AH32 [get_ports opca1_refclk_p]

set_property PACKAGE_PIN H33 [get_ports qsfp0_refclk_n]
set_property PACKAGE_PIN H32 [get_ports qsfp0_refclk_p]
set_property PACKAGE_PIN D33 [get_ports qsfp1_refclk_n]
set_property PACKAGE_PIN D32 [get_ports qsfp1_refclk_p]

# DDR4 SDRAM
set_property PACKAGE_PIN J17 [get_ports {ddr4_a[16]}]
set_property PACKAGE_PIN M16 [get_ports {ddr4_a[15]}]
set_property PACKAGE_PIN K18 [get_ports {ddr4_a[14]}]
set_property PACKAGE_PIN P20 [get_ports {ddr4_a[13]}]
set_property PACKAGE_PIN G19 [get_ports {ddr4_a[12]}]
set_property PACKAGE_PIN R20 [get_ports {ddr4_a[11]}]
set_property PACKAGE_PIN G16 [get_ports {ddr4_a[10]}]
set_property PACKAGE_PIN N17 [get_ports {ddr4_a[9]}]
set_property PACKAGE_PIN P19 [get_ports {ddr4_a[8]}]
set_property PACKAGE_PIN N20 [get_ports {ddr4_a[7]}]
set_property PACKAGE_PIN N19 [get_ports {ddr4_a[6]}]
set_property PACKAGE_PIN M19 [get_ports {ddr4_a[5]}]
set_property PACKAGE_PIN H16 [get_ports {ddr4_a[4]}]
set_property PACKAGE_PIN G18 [get_ports {ddr4_a[3]}]
set_property PACKAGE_PIN R18 [get_ports {ddr4_a[2]}]
set_property PACKAGE_PIN H17 [get_ports {ddr4_a[1]}]
set_property PACKAGE_PIN N16 [get_ports {ddr4_a[0]}]

set_property PACKAGE_PIN L19 [get_ports {ddr4_ba[1]}]
set_property PACKAGE_PIN L20 [get_ports {ddr4_ba[0]}]
set_property PACKAGE_PIN L16 [get_ports {ddr4_cke[0]}]
set_property PACKAGE_PIN F19 [get_ports {ddr4_cs_n[0]}]

set_property PACKAGE_PIN R27 [get_ports {ddr4_dm[8]}]
set_property PACKAGE_PIN L25 [get_ports {ddr4_dm[7]}]
set_property PACKAGE_PIN H25 [get_ports {ddr4_dm[6]}]
set_property PACKAGE_PIN C25 [get_ports {ddr4_dm[5]}]
set_property PACKAGE_PIN D22 [get_ports {ddr4_dm[4]}]
set_property PACKAGE_PIN D18 [get_ports {ddr4_dm[3]}]
set_property PACKAGE_PIN H20 [get_ports {ddr4_dm[2]}]
set_property PACKAGE_PIN R24 [get_ports {ddr4_dm[1]}]
set_property PACKAGE_PIN M21 [get_ports {ddr4_dm[0]}]

set_property PACKAGE_PIN P27 [get_ports {ddr4_dq[71]}]
set_property PACKAGE_PIN N27 [get_ports {ddr4_dq[70]}]
set_property PACKAGE_PIN P28 [get_ports {ddr4_dq[69]}]
set_property PACKAGE_PIN N26 [get_ports {ddr4_dq[68]}]
set_property PACKAGE_PIN P26 [get_ports {ddr4_dq[67]}]
set_property PACKAGE_PIN M28 [get_ports {ddr4_dq[66]}]
set_property PACKAGE_PIN R26 [get_ports {ddr4_dq[65]}]
set_property PACKAGE_PIN M27 [get_ports {ddr4_dq[64]}]
set_property PACKAGE_PIN K25 [get_ports {ddr4_dq[63]}]
set_property PACKAGE_PIN G28 [get_ports {ddr4_dq[62]}]
set_property PACKAGE_PIN K27 [get_ports {ddr4_dq[61]}]
set_property PACKAGE_PIN H26 [get_ports {ddr4_dq[60]}]
set_property PACKAGE_PIN K26 [get_ports {ddr4_dq[59]}]
set_property PACKAGE_PIN H27 [get_ports {ddr4_dq[58]}]
set_property PACKAGE_PIN K28 [get_ports {ddr4_dq[57]}]
set_property PACKAGE_PIN J25 [get_ports {ddr4_dq[56]}]
set_property PACKAGE_PIN F25 [get_ports {ddr4_dq[55]}]
set_property PACKAGE_PIN E25 [get_ports {ddr4_dq[54]}]
set_property PACKAGE_PIN F28 [get_ports {ddr4_dq[53]}]
set_property PACKAGE_PIN D27 [get_ports {ddr4_dq[52]}]
set_property PACKAGE_PIN F26 [get_ports {ddr4_dq[51]}]
set_property PACKAGE_PIN E26 [get_ports {ddr4_dq[50]}]
set_property PACKAGE_PIN G27 [get_ports {ddr4_dq[49]}]
set_property PACKAGE_PIN D28 [get_ports {ddr4_dq[48]}]
set_property PACKAGE_PIN B26 [get_ports {ddr4_dq[47]}]
set_property PACKAGE_PIN A25 [get_ports {ddr4_dq[46]}]
set_property PACKAGE_PIN C27 [get_ports {ddr4_dq[45]}]
set_property PACKAGE_PIN C24 [get_ports {ddr4_dq[44]}]
set_property PACKAGE_PIN A26 [get_ports {ddr4_dq[43]}]
set_property PACKAGE_PIN A24 [get_ports {ddr4_dq[42]}]
set_property PACKAGE_PIN B28 [get_ports {ddr4_dq[41]}]
set_property PACKAGE_PIN B24 [get_ports {ddr4_dq[40]}]
set_property PACKAGE_PIN B23 [get_ports {ddr4_dq[39]}]
set_property PACKAGE_PIN B22 [get_ports {ddr4_dq[38]}]
set_property PACKAGE_PIN C22 [get_ports {ddr4_dq[37]}]
set_property PACKAGE_PIN A23 [get_ports {ddr4_dq[36]}]
set_property PACKAGE_PIN C21 [get_ports {ddr4_dq[35]}]
set_property PACKAGE_PIN A20 [get_ports {ddr4_dq[34]}]
set_property PACKAGE_PIN D20 [get_ports {ddr4_dq[33]}]
set_property PACKAGE_PIN A21 [get_ports {ddr4_dq[32]}]
set_property PACKAGE_PIN A19 [get_ports {ddr4_dq[31]}]
set_property PACKAGE_PIN C17 [get_ports {ddr4_dq[30]}]
set_property PACKAGE_PIN B19 [get_ports {ddr4_dq[29]}]
set_property PACKAGE_PIN B16 [get_ports {ddr4_dq[28]}]
set_property PACKAGE_PIN A18 [get_ports {ddr4_dq[27]}]
set_property PACKAGE_PIN A16 [get_ports {ddr4_dq[26]}]
set_property PACKAGE_PIN C19 [get_ports {ddr4_dq[25]}]
set_property PACKAGE_PIN C16 [get_ports {ddr4_dq[24]}]
set_property PACKAGE_PIN G22 [get_ports {ddr4_dq[23]}]
set_property PACKAGE_PIN G21 [get_ports {ddr4_dq[22]}]
set_property PACKAGE_PIN G23 [get_ports {ddr4_dq[21]}]
set_property PACKAGE_PIN F21 [get_ports {ddr4_dq[20]}]
set_property PACKAGE_PIN G24 [get_ports {ddr4_dq[19]}]
set_property PACKAGE_PIN E22 [get_ports {ddr4_dq[18]}]
set_property PACKAGE_PIN E23 [get_ports {ddr4_dq[17]}]
set_property PACKAGE_PIN F20 [get_ports {ddr4_dq[16]}]
set_property PACKAGE_PIN M24 [get_ports {ddr4_dq[15]}]
set_property PACKAGE_PIN P22 [get_ports {ddr4_dq[14]}]
set_property PACKAGE_PIN M23 [get_ports {ddr4_dq[13]}]
set_property PACKAGE_PIN R23 [get_ports {ddr4_dq[12]}]
set_property PACKAGE_PIN N24 [get_ports {ddr4_dq[11]}]
set_property PACKAGE_PIN P23 [get_ports {ddr4_dq[10]}]
set_property PACKAGE_PIN M22 [get_ports {ddr4_dq[9]}]
set_property PACKAGE_PIN R22 [get_ports {ddr4_dq[8]}]
set_property PACKAGE_PIN J24 [get_ports {ddr4_dq[7]}]
set_property PACKAGE_PIN H24 [get_ports {ddr4_dq[6]}]
set_property PACKAGE_PIN K23 [get_ports {ddr4_dq[5]}]
set_property PACKAGE_PIN K22 [get_ports {ddr4_dq[4]}]
set_property PACKAGE_PIN J23 [get_ports {ddr4_dq[3]}]
set_property PACKAGE_PIN J22 [get_ports {ddr4_dq[2]}]
set_property PACKAGE_PIN H22 [get_ports {ddr4_dq[1]}]
set_property PACKAGE_PIN K21 [get_ports {ddr4_dq[0]}]


set_property PACKAGE_PIN E17 [get_ports {ddr4_odt[0]}]
set_property PACKAGE_PIN L18 [get_ports {ddr4_bg[0]}]
set_property PACKAGE_PIN G17 [get_ports ddr4_rst_n]
set_property PACKAGE_PIN F16 [get_ports ddr4_act_n]
#set_property PACKAGE_PIN  [get_ports ddr4_ten]

set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_a[*]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_ba[*]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_cke[0]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_cs_n[0]}]
set_property IOSTANDARD POD12_DCI [get_ports {ddr4_dm[*]}]
set_property IOSTANDARD POD12_DCI [get_ports {ddr4_dq[*]}]
set_property IOSTANDARD DIFF_POD12_DCI [get_ports {ddr4_dqs_p[*]}]
set_property IOSTANDARD DIFF_POD12_DCI [get_ports {ddr4_dqs_n[*]}]
set_property PACKAGE_PIN P25 [get_ports {ddr4_dqs_p[8]}]
set_property PACKAGE_PIN N25 [get_ports {ddr4_dqs_n[8]}]
set_property PACKAGE_PIN J27 [get_ports {ddr4_dqs_p[7]}]
set_property PACKAGE_PIN J28 [get_ports {ddr4_dqs_n[7]}]
set_property PACKAGE_PIN E27 [get_ports {ddr4_dqs_p[6]}]
set_property PACKAGE_PIN E28 [get_ports {ddr4_dqs_n[6]}]
set_property PACKAGE_PIN B27 [get_ports {ddr4_dqs_p[5]}]
set_property PACKAGE_PIN A28 [get_ports {ddr4_dqs_n[5]}]
set_property PACKAGE_PIN C20 [get_ports {ddr4_dqs_p[4]}]
set_property PACKAGE_PIN B21 [get_ports {ddr4_dqs_n[4]}]
set_property PACKAGE_PIN B18 [get_ports {ddr4_dqs_p[3]}]
set_property PACKAGE_PIN B17 [get_ports {ddr4_dqs_n[3]}]
set_property PACKAGE_PIN F23 [get_ports {ddr4_dqs_p[2]}]
set_property PACKAGE_PIN F24 [get_ports {ddr4_dqs_n[2]}]
set_property PACKAGE_PIN N21 [get_ports {ddr4_dqs_p[1]}]
set_property PACKAGE_PIN N22 [get_ports {ddr4_dqs_n[1]}]
set_property PACKAGE_PIN K20 [get_ports {ddr4_dqs_p[0]}]
set_property PACKAGE_PIN J20 [get_ports {ddr4_dqs_n[0]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_odt[0]}]
set_property IOSTANDARD SSTL12_DCI [get_ports {ddr4_bg[0]}]
set_property IOSTANDARD LVCMOS12 [get_ports ddr4_rst_n]
set_property IOSTANDARD SSTL12_DCI [get_ports ddr4_act_n]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports {ddr4_ck_p[0]}]
set_property IOSTANDARD DIFF_SSTL12_DCI [get_ports {ddr4_ck_n[0]}]
set_property PACKAGE_PIN K17 [get_ports {ddr4_ck_p[0]}]
set_property PACKAGE_PIN K16 [get_ports {ddr4_ck_n[0]}]
#set_property IOSTANDARD LVCMOS12 [get_ports ddr4_ten]
#set_property DRIVE 8 [get_ports ddr4_ten]

## Cooker
set_property PACKAGE_PIN T15 [get_ports sreg_cook_out]
set_property PACKAGE_PIN L14 [get_ports bram_cook_out]
set_property PACKAGE_PIN L15 [get_ports dsp_cook_out]

set_property IOSTANDARD LVCMOS33 [get_ports sreg_cook_out]
set_property IOSTANDARD LVCMOS33 [get_ports bram_cook_out]
set_property IOSTANDARD LVCMOS33 [get_ports dsp_cook_out]

# --------------------------------
# Pblock snapping for tandem boot
# --------------------------------
set_property SNAPPING_MODE ON [get_pblocks *_Stage1_main]

# ---------------
# CONFIG_VOLTAGE
# ---------------
set_property CONFIG_VOLTAGE 1.8 [current_design]
#where 'value' is the voltage provided to configuration bank 0


# -------------------
# Timing Constraints
# -------------------
set_input_jitter [get_clocks -of_objects [get_ports ddr4_clk_p]] 0.100

create_clock -period 10.000 -name pcie_clk0 -waveform {0.000 5.000} [get_ports pcie_clk0_p]
set_input_jitter [get_clocks -of_objects [get_ports pcie_clk0_p]] 0.200

create_clock -period 10.000 -name oc0_a_refclk -waveform {0.000 5.000} [get_ports oc0_a_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports oc0_a_refclk_p]] 0.200

create_clock -period 10.000 -name oc0_b_refclk -waveform {0.000 5.000} [get_ports oc0_b_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports oc0_b_refclk_p]] 0.200

create_clock -period 10.000 -name oc1_a_refclk -waveform {0.000 5.000} [get_ports oc1_a_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports oc1_a_refclk_p]] 0.200

create_clock -period 10.000 -name oc1_b_refclk -waveform {0.000 5.000} [get_ports oc1_b_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports oc1_b_refclk_p]] 0.200

create_clock -period 10.000 -name oc2_a_refclk -waveform {0.000 5.000} [get_ports oc2_a_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports oc2_a_refclk_p]] 0.200

create_clock -period 10.000 -name oc2_b_refclk -waveform {0.000 5.000} [get_ports oc2_b_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports oc2_b_refclk_p]] 0.200

create_clock -period 10.000 -name oc3_a_refclk -waveform {0.000 5.000} [get_ports oc3_a_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports oc3_a_refclk_p]] 0.200

create_clock -period 10.000 -name oc3_b_refclk -waveform {0.000 5.000} [get_ports oc3_b_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports oc3_b_refclk_p]] 0.200

create_clock -period 6.400 -name opca0_refclk -waveform {0.000 3.200} [get_ports opca0_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports opca0_refclk_p]] 0.200

create_clock -period 6.400 -name opca1_refclk -waveform {0.000 3.200} [get_ports opca1_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports opca1_refclk_p]] 0.200

create_clock -period 3.103 -name qsfp0_refclk -waveform {0.000 1.552} [get_ports qsfp0_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports qsfp0_refclk_p]] 0.100

create_clock -period 3.103 -name qsfp1_refclk -waveform {0.000 1.552} [get_ports qsfp1_refclk_p]
set_input_jitter [get_clocks -of_objects [get_ports qsfp1_refclk_p]] 0.100

# Asynchronous Clocks

# GTY Tx
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u0/inst/clock_module_i/ultrascale_tx_userclk_1/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u2/inst/clock_module_i/ultrascale_tx_userclk_1/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u4/inst/clock_module_i/ultrascale_tx_userclk_1/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u6/inst/clock_module_i/ultrascale_tx_userclk_1/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk_inst/O]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u16/inst/clock_module_i/ultrascale_tx_userclk_1/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u18/inst/clock_module_i/ultrascale_tx_userclk_1/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk_inst/O]]

# GTY Rx
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u0/inst/aurora_64b66b_0_core_i/aurora_64b66b_0_wrapper_i/aurora_64b66b_0_multi_gt_i/ultrascale_rx_userclk/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u2/inst/aurora_64b66b_1_core_i/aurora_64b66b_1_wrapper_i/aurora_64b66b_1_multi_gt_i/ultrascale_rx_userclk/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u4/inst/aurora_64b66b_2_core_i/aurora_64b66b_2_wrapper_i/aurora_64b66b_2_multi_gt_i/ultrascale_rx_userclk/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u6/inst/aurora_64b66b_3_core_i/aurora_64b66b_3_wrapper_i/aurora_64b66b_3_multi_gt_i/ultrascale_rx_userclk/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u16/inst/aurora_64b66b_8_core_i/aurora_64b66b_8_wrapper_i/aurora_64b66b_8_multi_gt_i/ultrascale_rx_userclk/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u18/inst/aurora_64b66b_9_core_i/aurora_64b66b_9_wrapper_i/aurora_64b66b_9_multi_gt_i/ultrascale_rx_userclk/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O]]

# GTH Tx
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u8/inst/clock_module_i/ultrascale_tx_userclk_1/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u10/inst/clock_module_i/ultrascale_tx_userclk_1/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u12/inst/clock_module_i/ultrascale_tx_userclk_1/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u14/inst/clock_module_i/ultrascale_tx_userclk_1/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O]]

# GTH Rx
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u8/inst/aurora_64b66b_4_core_i/aurora_64b66b_4_wrapper_i/aurora_64b66b_4_multi_gt_i/ultrascale_rx_userclk/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u10/inst/aurora_64b66b_5_core_i/aurora_64b66b_5_wrapper_i/aurora_64b66b_5_multi_gt_i/ultrascale_rx_userclk/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u12/inst/aurora_64b66b_6_core_i/aurora_64b66b_6_wrapper_i/aurora_64b66b_6_multi_gt_i/ultrascale_rx_userclk/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u60/u14/inst/aurora_64b66b_7_core_i/aurora_64b66b_7_wrapper_i/aurora_64b66b_7_multi_gt_i/ultrascale_rx_userclk/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O]]

# Misc
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u50/u0/inst/u_ddr4_infrastructure/u_bufg_divClk/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u20/pcie_ps_i/xdma_0/inst/pcie4_ip_i/inst/pcie_ps_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks ddr4_clk_p]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u10/clk_out3]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u32c/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u10/clk_out1]] -group [get_clocks -of_objects [get_pins u33c/O]]

# False Paths
set_false_path -to [get_ports {user_led[*]}]
set_false_path -to [get_ports smbclk_user_i2c]
set_false_path -to [get_ports smbdat_user_i2c]
set_false_path -to [get_ports rst_user_i2c_n]
set_false_path -to [get_ports smbclk_tmp_prom]
set_false_path -to [get_ports smbdat_tmp_prom]
set_false_path -to [get_ports smbclk_user_ucd]
set_false_path -to [get_ports smbdat_user_ucd]
set_false_path -to [get_ports margin_en_n]
set_false_path -to [get_ports margin_high]

set_false_path -to [get_ports ddr4_rst_n]
set_false_path -to [get_ports sreg_cook_out]
set_false_path -to [get_ports bram_cook_out]
set_false_path -to [get_ports dsp_cook_out]

set_false_path -to [get_ports oc_perst_n]

set_false_path -to [get_ports qsfp0_lp_mode]
set_false_path -to [get_ports qsfp0_rst_n]
set_false_path -to [get_ports qsfp1_lp_mode]
set_false_path -to [get_ports qsfp1_rst_n]

set_false_path -from [get_ports pcie_perst_n]

set_false_path -from [get_ports smbclk_user_i2c]
set_false_path -from [get_ports smbdat_user_i2c]
set_false_path -from [get_ports smbclk_tmp_prom]
set_false_path -from [get_ports smbdat_tmp_prom]
set_false_path -from [get_ports smbclk_user_ucd]
set_false_path -from [get_ports smbdat_user_ucd]
set_false_path -from [get_ports fpga_smbus_en_n]

set_false_path -from [get_ports oc_bp_type]
set_false_path -from [get_ports oc_cprsnt_n]

set_false_path -from [get_ports qsfp0_mod_prs_n]
set_false_path -from [get_ports qsfp0_int_n]
set_false_path -from [get_ports qsfp1_mod_prs_n]
set_false_path -from [get_ports qsfp1_int_n]

set_false_path -from [get_ports volt_warn]


# -------------------
# BitGen Constraints
# -------------------
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
