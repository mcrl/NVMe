##-----------------------------------------------------------------------------
##
## (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
##-----------------------------------------------------------------------------
##
## Project    : UltraScale+ FPGA PCI Express v4.0 Integrated Block
## File       : xilinx_pcie4_uscale_plus_x0y3.xdc
## Version    : 1.3
##-----------------------------------------------------------------------------
#
###############################################################################
# Vivado - PCIe GUI / User Configuration
###############################################################################
#
# Link Speed   - Gen3 - 8.0 Gb/s
# Link Width   - X4
# AXIST Width  - 128-bit
# AXIST Frequ  - 250 MHz = User Clock
# Core Clock   - 250 MHz
# Pipe Clock   - 125 MHz (Gen1) / 250 MHz (Gen2/Gen3/Gen4)
#
# Family       - zynquplus
# Part         - xczu19eg
# Package      - ffvd1760
# Speed grade  - -2
# PCIe Block   - X0Y3
# Xilinx BNo   - 0
#
#
#
# PLL TYPE     - QPLL1
#
###############################################################################
# User Time Names / User Time Groups / Time Specs
###############################################################################
set_false_path -from [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rst_n]
set_property PACKAGE_PIN AM16 [get_ports sys_rst_n]
#set_property LOC [get_package_pins -filter {PIN_FUNC =~ *_PERSTN0_65}] [get_ports sys_rst_n]

#
# 250-SOC OC_0A uses MGTREFCLK1 on Bank 131
create_clock -name pcie_0a_sys_clk -period 8 [get_ports pcie_0a_sys_clk_p]
#
set_property LOC [get_package_pins -of_objects [get_bels [get_sites -filter {NAME =~ *COMMON*} -of_objects [get_iobanks -of_objects [get_sites GTYE4_CHANNEL_X0Y19]]]/REFCLK1P]] [get_ports pcie_0a_sys_clk_p]
set_property LOC [get_package_pins -of_objects [get_bels [get_sites -filter {NAME =~ *COMMON*} -of_objects [get_iobanks -of_objects [get_sites GTYE4_CHANNEL_X0Y19]]]/REFCLK1N]] [get_ports pcie_0a_sys_clk_n]
#
#

#
# 250-SOC OC_0B uses MGTREFCLK1 on Bank 130
create_clock -name pcie_0b_sys_clk -period 10 [get_ports pcie_0b_sys_clk_p]
#
set_property LOC [get_package_pins -of_objects [get_bels [get_sites -filter {NAME =~ *COMMON*} -of_objects [get_iobanks -of_objects [get_sites GTYE4_CHANNEL_X0Y15]]]/REFCLK1P]] [get_ports pcie_0b_sys_clk_p]
set_property LOC [get_package_pins -of_objects [get_bels [get_sites -filter {NAME =~ *COMMON*} -of_objects [get_iobanks -of_objects [get_sites GTYE4_CHANNEL_X0Y15]]]/REFCLK1N]] [get_ports pcie_0b_sys_clk_n]
#
#

#
# 250-SOC OC_3A uses MGTREFCLK0 on Bank 228
create_clock -name pcie_3a_sys_clk -period 10 [get_ports pcie_3a_sys_clk_p]
#
set_property LOC [get_package_pins -of_objects [get_bels [get_sites -filter {NAME =~ *COMMON*} -of_objects [get_iobanks -of_objects [get_sites GTHE4_CHANNEL_X0Y19]]]/REFCLK0P]] [get_ports pcie_3a_sys_clk_p]
set_property LOC [get_package_pins -of_objects [get_bels [get_sites -filter {NAME =~ *COMMON*} -of_objects [get_iobanks -of_objects [get_sites GTHE4_CHANNEL_X0Y19]]]/REFCLK0N]] [get_ports pcie_3a_sys_clk_n]
#
#

#
# 250-SOC OC_3B uses MGTREFCLK0 on Bank 229
create_clock -name pcie_3b_sys_clk -period 10 [get_ports pcie_3b_sys_clk_p]
#
set_property LOC [get_package_pins -of_objects [get_bels [get_sites -filter {NAME =~ *COMMON*} -of_objects [get_iobanks -of_objects [get_sites GTHE4_CHANNEL_X0Y23]]]/REFCLK0P]] [get_ports pcie_3b_sys_clk_p]
set_property LOC [get_package_pins -of_objects [get_bels [get_sites -filter {NAME =~ *COMMON*} -of_objects [get_iobanks -of_objects [get_sites GTHE4_CHANNEL_X0Y23]]]/REFCLK0N]] [get_ports pcie_3b_sys_clk_n]
#
#

################################################################################
# Oculink Interface
################################################################################
set_property IOSTANDARD LVTTL [get_ports oc?_?_perst_n]
set_property PACKAGE_PIN A14  [get_ports oc0_a_perst_n]
set_property PACKAGE_PIN A15  [get_ports oc0_b_perst_n]
set_property PACKAGE_PIN A13  [get_ports oc1_a_perst_n]
set_property PACKAGE_PIN B14  [get_ports oc1_b_perst_n]
set_property PACKAGE_PIN A10  [get_ports oc2_a_perst_n]
set_property PACKAGE_PIN A11  [get_ports oc2_b_perst_n]
set_property PACKAGE_PIN F14  [get_ports oc3_a_perst_n]
set_property PACKAGE_PIN F15  [get_ports oc3_b_perst_n]

set_property IOSTANDARD LVTTL [get_ports oc?_?_cprsnt]
set_property PACKAGE_PIN G14  [get_ports oc0_a_cprsnt]
set_property PACKAGE_PIN E13  [get_ports oc0_b_cprsnt]
set_property PACKAGE_PIN E15  [get_ports oc1_a_cprsnt]
set_property PACKAGE_PIN D14  [get_ports oc2_a_cprsnt]
set_property PACKAGE_PIN C15  [get_ports oc3_a_cprsnt]
set_property PACKAGE_PIN D12  [get_ports oc3_b_cprsnt]

set_property LOC "" [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC "" [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC "" [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe4_channel_inst[2].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC "" [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe4_channel_inst[3].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y16 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe4_channel_inst[3].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y17 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe4_channel_inst[2].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y18 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe4_channel_inst[1].GTHE4_CHANNEL_PRIM_INST}]
set_property LOC GTHE4_CHANNEL_X0Y19 [get_cells -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]

#
#
#
# CLOCK_ROOT LOCKing to Reduce CLOCK SKEW
# Add/Edit  Clock Routing Option to improve clock path skew
#
# BITFILE/BITSTREAM compress options
# ##############################################################################
# Flash Programming Example Settings: These should be modified to match the target board.
# ##############################################################################
#

# pcie_0a_sys_clk vs TXOUTCLK
set_clock_groups -name async18_0a -asynchronous -group [get_clocks {pcie_0a_sys_clk}] -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gtye4_channel_inst[*].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -name async19_0a -asynchronous -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gtye4_channel_inst[*].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]] -group [get_clocks {pcie_0a_sys_clk}]
#

# pcie_0b_sys_clk vs TXOUTCLK
set_clock_groups -name async18_0b -asynchronous -group [get_clocks {pcie_0b_sys_clk}] -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_channel_container[3].*gen_gtye4_channel_inst[*].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -name async19_0b -asynchronous -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_channel_container[3].*gen_gtye4_channel_inst[*].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]] -group [get_clocks {pcie_0b_sys_clk}]
#

# pcie_3a_sys_clk vs TXOUTCLK
set_clock_groups -name async18_3a -asynchronous -group [get_clocks {pcie_3a_sys_clk}] -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe4_channel_inst[*].GTHE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -name async19_3a -asynchronous -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_channel_container[4].*gen_gthe4_channel_inst[*].GTHE4_CHANNEL_PRIM_INST/TXOUTCLK}]] -group [get_clocks {pcie_3a_sys_clk}]
#

# pcie_3b_sys_clk vs TXOUTCLK
set_clock_groups -name async18_3b -asynchronous -group [get_clocks {pcie_3b_sys_clk}] -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_channel_container[5].*gen_gthe4_channel_inst[*].GTHE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -name async19_3b -asynchronous -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_channel_container[5].*gen_gthe4_channel_inst[*].GTHE4_CHANNEL_PRIM_INST/TXOUTCLK}]] -group [get_clocks {pcie_3b_sys_clk}]
#

#
#
#
#
# ASYNC CLOCK GROUPINGS
#
#
# Timing improvement
# Add/Edit Pblock slice constraints for init_ctr module to improve timing
#create_pblock init_ctr_rst; add_cells_to_pblock [get_pblocks init_ctr_rst] [get_cells cgator_wrapper_i/pcie4_uscale_plus_0_i/inst/pcie_4_0_pipe_inst/pcie_4_0_init_ctrl_inst]
# Keep This Logic Left/Right Side Of The PCIe Block (Whichever is near to the FPGA Boundary)
#resize_pblock [get_pblocks init_ctr_rst] -add {SLICE_X0Y400:SLICE_X12Y479}

#
set_clock_groups -name async24_0a -asynchronous -group [get_clocks -of_objects [get_pins rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_intclk/O]] -group [get_clocks {pcie_0a_sys_clk}]
#

#
set_clock_groups -name async24_0b -asynchronous -group [get_clocks -of_objects [get_pins rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_intclk/O]] -group [get_clocks {pcie_0b_sys_clk}]
#

#
set_clock_groups -name async24_3a -asynchronous -group [get_clocks -of_objects [get_pins rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_intclk/O]] -group [get_clocks {pcie_3a_sys_clk}]
#

#
set_clock_groups -name async24_3b -asynchronous -group [get_clocks -of_objects [get_pins rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_intclk/O]] -group [get_clocks {pcie_3b_sys_clk}]
#

#create_waiver -type METHODOLOGY -id {LUTAR-1} -user "pcie4_uscale_plus" -desc "user link up is synchroized in the user clk so it is safe to ignore"  -internal -scoped -tags 1024539  -objects [get_cells { pcie_app_uscale_i/PIO_i/len_i[5]_i_4 }] -objects [get_pins { pcie4_uscale_plus_0_i/inst/user_lnk_up_cdc/arststages_ff_reg[0]/CLR pcie4_uscale_plus_0_i/inst/user_lnk_up_cdc/arststages_ff_reg[1]/CLR }]



###
#################################
###### ILA for debug of OC-0A ###
#################################
###
###create_debug_core ila_0a ila
###
###set_property ALL_PROBE_SAME_MU true [get_debug_cores ila_0a]
###set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores ila_0a]
###set_property C_ADV_TRIGGER false [get_debug_cores ila_0a]
###set_property C_DATA_DEPTH 1024 [get_debug_cores ila_0a]
###set_property C_EN_STRG_QUAL false [get_debug_cores ila_0a]
###set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores ila_0a]
###set_property C_TRIGIN_EN false [get_debug_cores ila_0a]
###set_property C_TRIGOUT_EN false [get_debug_cores ila_0a]
###
###set_property port_width 1 [get_debug_ports ila_0a/clk]
####connect_debug_port ila_0a/clk [get_nets [list rp_x4_0a/user_clk]]
###connect_debug_port u_ila_0/clk [get_nets [list rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0_i/inst/mcap_clk]]
###
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0a/probe0]
###set_property port_width 6 [get_debug_ports ila_0a/probe0]
###connect_debug_port ila_0a/probe0 [get_nets [list {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_ltssm_state[0]} {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_ltssm_state[1]} {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_ltssm_state[2]} {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_ltssm_state[3]} {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_ltssm_state[4]} {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_ltssm_state[5]}]]
###
###create_debug_port ila_0a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0a/probe1]
###set_property port_width 2 [get_debug_ports ila_0a/probe1]
###connect_debug_port ila_0a/probe1 [get_nets [list {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_tx_pm_state[0]} {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_tx_pm_state[1]}]]
###
###create_debug_port ila_0a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0a/probe2]
###set_property port_width 2 [get_debug_ports ila_0a/probe2]
###connect_debug_port ila_0a/probe2 [get_nets [list {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_rx_pm_state[0]} {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_rx_pm_state[1]}]]
###
###create_debug_port ila_0a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0a/probe3]
###set_property port_width 2 [get_debug_ports ila_0a/probe3]
###connect_debug_port ila_0a/probe3 [get_nets [list {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_phy_link_status[0]} {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_phy_link_status[1]}]]
###
###create_debug_port ila_0a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0a/probe4]
###set_property port_width 3 [get_debug_ports ila_0a/probe4]
###connect_debug_port ila_0a/probe4 [get_nets [list {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_negotiated_width[0]} {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_negotiated_width[1]} {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_negotiated_width[2]}]]
###
###create_debug_port ila_0a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0a/probe5]
###set_property port_width 2 [get_debug_ports ila_0a/probe5]
###connect_debug_port ila_0a/probe5 [get_nets [list {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_current_speed[0]} {rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_current_speed[1]}]]
###
###create_debug_port ila_0a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0a/probe6]
###set_property port_width 1 [get_debug_ports ila_0a/probe6]
###connect_debug_port ila_0a/probe6 [get_nets [list rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/cfg_phy_link_down]]
###
###create_debug_port ila_0a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0a/probe7]
###set_property port_width 1 [get_debug_ports ila_0a/probe7]
###connect_debug_port ila_0a/probe7 [get_nets [list rp_x4_0a/cgator_wrapper_0a/pcie4_uscale_plus_0a/inst/store_ltssm]]
###
###create_debug_port ila_0a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0a/probe8]
###set_property port_width 1 [get_debug_ports ila_0a/probe8]
###connect_debug_port ila_0a/probe8 [get_nets [list sys_rst_n_c]]
###
####create_debug_port ila_0a probe
####set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0a/probe9]
####set_property port_width 1 [get_debug_ports ila_0a/probe9]
####connect_debug_port ila_0a/probe9 [get_nets [list rp_x4_0a/vio_reset_n]]
###
###
#################################
###### ILA for debug of OC-0B ###
#################################
###
###create_debug_core ila_0b ila
###
###set_property ALL_PROBE_SAME_MU true [get_debug_cores ila_0b]
###set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores ila_0b]
###set_property C_ADV_TRIGGER false [get_debug_cores ila_0b]
###set_property C_DATA_DEPTH 1024 [get_debug_cores ila_0b]
###set_property C_EN_STRG_QUAL false [get_debug_cores ila_0b]
###set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores ila_0b]
###set_property C_TRIGIN_EN false [get_debug_cores ila_0b]
###set_property C_TRIGOUT_EN false [get_debug_cores ila_0b]
###
###set_property port_width 1 [get_debug_ports ila_0b/clk]
####connect_debug_port ila_0b/clk [get_nets [list rp_x4_0b/user_clk]]
###connect_debug_port u_ila_0/clk [get_nets [list rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0_i/inst/mcap_clk]]
###
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0b/probe0]
###set_property port_width 6 [get_debug_ports ila_0b/probe0]
###connect_debug_port ila_0b/probe0 [get_nets [list {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_ltssm_state[0]} {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_ltssm_state[1]} {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_ltssm_state[2]} {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_ltssm_state[3]} {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_ltssm_state[4]} {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_ltssm_state[5]}]]
###
###create_debug_port ila_0b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0b/probe1]
###set_property port_width 2 [get_debug_ports ila_0b/probe1]
###connect_debug_port ila_0b/probe1 [get_nets [list {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_tx_pm_state[0]} {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_tx_pm_state[1]}]]
###
###create_debug_port ila_0b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0b/probe2]
###set_property port_width 2 [get_debug_ports ila_0b/probe2]
###connect_debug_port ila_0b/probe2 [get_nets [list {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_rx_pm_state[0]} {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_rx_pm_state[1]}]]
###
###create_debug_port ila_0b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0b/probe3]
###set_property port_width 2 [get_debug_ports ila_0b/probe3]
###connect_debug_port ila_0b/probe3 [get_nets [list {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_phy_link_status[0]} {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_phy_link_status[1]}]]
###
###create_debug_port ila_0b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0b/probe4]
###set_property port_width 3 [get_debug_ports ila_0b/probe4]
###connect_debug_port ila_0b/probe4 [get_nets [list {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_negotiated_width[0]} {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_negotiated_width[1]} {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_negotiated_width[2]}]]
###
###create_debug_port ila_0b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0b/probe5]
###set_property port_width 2 [get_debug_ports ila_0b/probe5]
###connect_debug_port ila_0b/probe5 [get_nets [list {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_current_speed[0]} {rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_current_speed[1]}]]
###
###create_debug_port ila_0b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0b/probe6]
###set_property port_width 1 [get_debug_ports ila_0b/probe6]
###connect_debug_port ila_0b/probe6 [get_nets [list rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/cfg_phy_link_down]]
###
###create_debug_port ila_0b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0b/probe7]
###set_property port_width 1 [get_debug_ports ila_0b/probe7]
###connect_debug_port ila_0b/probe7 [get_nets [list rp_x4_0b/cgator_wrapper_0b/pcie4_uscale_plus_0b/inst/store_ltssm]]
###
###create_debug_port ila_0b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0b/probe8]
###set_property port_width 1 [get_debug_ports ila_0b/probe8]
###connect_debug_port ila_0b/probe8 [get_nets [list sys_rst_n_c]]
###
####create_debug_port ila_0b probe
####set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_0b/probe9]
####set_property port_width 1 [get_debug_ports ila_0b/probe9]
####connect_debug_port ila_0b/probe9 [get_nets [list rp_x4_0b/vio_reset_n]]
###
###
#################################
###### ILA for debug of OC-3A ###
#################################
###
###create_debug_core ila_3a ila
###
###set_property ALL_PROBE_SAME_MU true [get_debug_cores ila_3a]
###set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores ila_3a]
###set_property C_ADV_TRIGGER false [get_debug_cores ila_3a]
###set_property C_DATA_DEPTH 1024 [get_debug_cores ila_3a]
###set_property C_EN_STRG_QUAL false [get_debug_cores ila_3a]
###set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores ila_3a]
###set_property C_TRIGIN_EN false [get_debug_cores ila_3a]
###set_property C_TRIGOUT_EN false [get_debug_cores ila_3a]
###
###set_property port_width 1 [get_debug_ports ila_3a/clk]
####connect_debug_port ila_3a/clk [get_nets [list rp_x4_3a/user_clk]]
###connect_debug_port u_ila_0/clk [get_nets [list rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_0_i/inst/mcap_clk]]
###
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3a/probe0]
###set_property port_width 6 [get_debug_ports ila_3a/probe0]
###connect_debug_port ila_3a/probe0 [get_nets [list {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_ltssm_state[0]} {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_ltssm_state[1]} {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_ltssm_state[2]} {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_ltssm_state[3]} {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_ltssm_state[4]} {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_ltssm_state[5]}]]
###
###create_debug_port ila_3a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3a/probe1]
###set_property port_width 2 [get_debug_ports ila_3a/probe1]
###connect_debug_port ila_3a/probe1 [get_nets [list {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_tx_pm_state[0]} {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_tx_pm_state[1]}]]
###
###create_debug_port ila_3a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3a/probe2]
###set_property port_width 2 [get_debug_ports ila_3a/probe2]
###connect_debug_port ila_3a/probe2 [get_nets [list {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_rx_pm_state[0]} {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_rx_pm_state[1]}]]
###
###create_debug_port ila_3a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3a/probe3]
###set_property port_width 2 [get_debug_ports ila_3a/probe3]
###connect_debug_port ila_3a/probe3 [get_nets [list {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_phy_link_status[0]} {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_phy_link_status[1]}]]
###
###create_debug_port ila_3a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3a/probe4]
###set_property port_width 3 [get_debug_ports ila_3a/probe4]
###connect_debug_port ila_3a/probe4 [get_nets [list {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_negotiated_width[0]} {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_negotiated_width[1]} {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_negotiated_width[2]}]]
###
###create_debug_port ila_3a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3a/probe5]
###set_property port_width 2 [get_debug_ports ila_3a/probe5]
###connect_debug_port ila_3a/probe5 [get_nets [list {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_current_speed[0]} {rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_current_speed[1]}]]
###
###create_debug_port ila_3a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3a/probe6]
###set_property port_width 1 [get_debug_ports ila_3a/probe6]
###connect_debug_port ila_3a/probe6 [get_nets [list rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/cfg_phy_link_down]]
###
###create_debug_port ila_3a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3a/probe7]
###set_property port_width 1 [get_debug_ports ila_3a/probe7]
###connect_debug_port ila_3a/probe7 [get_nets [list rp_x4_3a/cgator_wrapper_3a/pcie4_uscale_plus_3a/inst/store_ltssm]]
###
###create_debug_port ila_3a probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3a/probe8]
###set_property port_width 1 [get_debug_ports ila_3a/probe8]
###connect_debug_port ila_3a/probe8 [get_nets [list sys_rst_n_c]]
###
####create_debug_port ila_3a probe
####set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3a/probe9]
####set_property port_width 1 [get_debug_ports ila_3a/probe9]
####connect_debug_port ila_3a/probe9 [get_nets [list rp_x4_3a/vio_reset_n]]
###
###
#################################
###### ILA for debug of OC-3B ###
#################################
###
###create_debug_core ila_3b ila
###
###set_property ALL_PROBE_SAME_MU true [get_debug_cores ila_3b]
###set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores ila_3b]
###set_property C_ADV_TRIGGER false [get_debug_cores ila_3b]
###set_property C_DATA_DEPTH 1024 [get_debug_cores ila_3b]
###set_property C_EN_STRG_QUAL false [get_debug_cores ila_3b]
###set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores ila_3b]
###set_property C_TRIGIN_EN false [get_debug_cores ila_3b]
###set_property C_TRIGOUT_EN false [get_debug_cores ila_3b]
###
###set_property port_width 1 [get_debug_ports ila_3b/clk]
####connect_debug_port ila_3b/clk [get_nets [list rp_x4_3b/user_clk]]
###connect_debug_port u_ila_0/clk [get_nets [list rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_0_i/inst/mcap_clk]]
###
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3b/probe0 ]
###set_property port_width 6 [get_debug_ports ila_3b/probe0]
###connect_debug_port ila_3b/probe0 [get_nets [list {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_ltssm_state[0]} {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_ltssm_state[1]} {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_ltssm_state[2]} {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_ltssm_state[3]} {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_ltssm_state[4]} {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_ltssm_state[5]}]]
###
###create_debug_port ila_3b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3b/probe1]
###set_property port_width 2 [get_debug_ports ila_3b/probe1]
###connect_debug_port ila_3b/probe1 [get_nets [list {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_tx_pm_state[0]} {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_tx_pm_state[1]}]]
###
###create_debug_port ila_3b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3b/probe2]
###set_property port_width 2 [get_debug_ports ila_3b/probe2]
###connect_debug_port ila_3b/probe2 [get_nets [list {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_rx_pm_state[0]} {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_rx_pm_state[1]}]]
###
###create_debug_port ila_3b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3b/probe3]
###set_property port_width 2 [get_debug_ports ila_3b/probe3]
###connect_debug_port ila_3b/probe3 [get_nets [list {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_phy_link_status[0]} {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_phy_link_status[1]}]]
###
###create_debug_port ila_3b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3b/probe4]
###set_property port_width 3 [get_debug_ports ila_3b/probe4]
###connect_debug_port ila_3b/probe4 [get_nets [list {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_negotiated_width[0]} {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_negotiated_width[1]} {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_negotiated_width[2]}]]
###
###create_debug_port ila_3b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3b/probe5]
###set_property port_width 2 [get_debug_ports ila_3b/probe5]
###connect_debug_port ila_3b/probe5 [get_nets [list {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_current_speed[0]} {rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_current_speed[1]}]]
###
###create_debug_port ila_3b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3b/probe6]
###set_property port_width 1 [get_debug_ports ila_3b/probe6]
###connect_debug_port ila_3b/probe6 [get_nets [list rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/cfg_phy_link_down]]
###
###create_debug_port ila_3b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3b/probe7]
###set_property port_width 1 [get_debug_ports ila_3b/probe7]
###connect_debug_port ila_3b/probe7 [get_nets [list rp_x4_3b/cgator_wrapper_3b/pcie4_uscale_plus_3b/inst/store_ltssm]]
###
###create_debug_port ila_3b probe
###set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3b/probe8]
###set_property port_width 1 [get_debug_ports ila_3b/probe8]
###connect_debug_port ila_3b/probe8 [get_nets [list sys_rst_n_c]]
###
####create_debug_port ila_3b probe
####set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports ila_3b/probe9]
####set_property port_width 1 [get_debug_ports ila_3b/probe9]
####connect_debug_port ila_3b/probe9 [get_nets [list rp_x4_3b/vio_reset_n]]
###
###
###################################
###### DBG_HUB Clock Connection ###
###################################
###
####set_property C_CLK_INPUT_FREQ_HZ 100000000 [get_debug_cores dbg_hub]
####set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
####set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
####connect_debug_port dbg_hub/clk [get_nets ref_clk]
###

set_property IOSTANDARD LVCMOS33 [get_ports oc0_cprsnt_n]
set_property IOSTANDARD LVCMOS33 [get_ports oc0_perst_n]
set_property PACKAGE_PIN G14 [get_ports oc0_cprsnt_n]
set_property PACKAGE_PIN A14 [get_ports oc0_perst_n]
