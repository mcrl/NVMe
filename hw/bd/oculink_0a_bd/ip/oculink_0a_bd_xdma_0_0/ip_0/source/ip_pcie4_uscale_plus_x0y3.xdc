##-----------------------------------------------------------------------------
##
## (c) Copyright 1995, 2007, 2023 Advanced Micro Devices, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of AMD, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## AMD, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) AMD shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or AMD had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## AMD products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of AMD products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
##-----------------------------------------------------------------------------
##
## Project    : UltraScale+ FPGA PCI Express v4.0 Integrated Block
## File       : ip_pcie4_uscale_plus_x0y3.xdc
## Version    : 1.3 
##-----------------------------------------------------------------------------
#
###############################################################################
# Vivado - PCIe GUI / User Configuration 
###############################################################################
#
# Family              # zynquplus
# Part                # xczu19eg
# Package             # ffvd1760
# Speed grade         # -2
# PCIe Block          # X0Y3
# Xilinx BNo          # 0
#
# Link Speed          # Gen3 - 8.0 Gb/s
# Link Width          # X4
# AXIST Width         # 256-bit
# AXIST Frequ         # 125 MHz = User Clock 
# Core Clock          # 250 MHz
# Pipe Clock          # 125 MHz (Gen1) : 250 MHz (Gen2/Gen3/Gen4)
# PLL TYPE            # QPLL1
# MSI-X TYPE          # HARD
#
# master_gt_quad_inx  # 3
# master_gt_container # 4
# gt_type             # gtye4
# SILICON : # Beta
# SILICON : # PRODUCTION
#
#

###############################################################################
# User Time Names / User Time Groups / Time Specs
###############################################################################

###############################################################################
# Pinout and Related I/O Constraints
###############################################################################
#
# Transceiver instance placement.  This constraint selects the
# transceivers to be used, which also dictates the pinout for the
# transmit and receive differential pairs.  Please refer to the
# Virtex-7 GT Transceiver User Guide (UG) for more information.
#
###############################################################################

###############################################################################
# Physical Constraints
###############################################################################
###############################################################################
#
# PCI Express Block placement. This constraint selects the PCI Express
# Block to be used.
#
###############################################################################

###############################################################################
# Buffer (BRAM) Placement Constraints
###############################################################################

#Request Buffer RAMB Placement

# Completion Buffer RAMB Placement

# Replay Buffer RAMB Placement

###############################################################################
# Timing Constraints
###############################################################################
# Add PCIe LOC Constraints Here
#
set_property LOC PCIE40E4_X0Y3 [get_cells oculink_0a_bd_xdma_0_0_pcie4_ip_pcie_4_0_pipe_inst/pcie_4_0_e4_inst]
#
# This is a slow running clock 1MHz drives small logic before perst only for delaying reference clock probation. 
create_clock -period 1000 [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_intclk/O]
#
#
#
# TXOUTCLKSEL switches during reset. Set the tool to analyze timing with TXOUTCLKSEL set to 'b101.
set_case_analysis 1 [get_pins -filter {REF_PIN_NAME=~TXOUTCLKSEL[2]} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~TXOUTCLKSEL[1]} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_case_analysis 1 [get_pins -filter {REF_PIN_NAME=~TXOUTCLKSEL[0]} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
#
# These pins are dynamic and added case analysis constrains. so that tool do not complain any warnings.
set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~TXRATE[0]} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~RXRATE[0]} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_case_analysis 1 [get_pins -filter {REF_PIN_NAME=~TXRATE[1]} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_case_analysis 1 [get_pins -filter {REF_PIN_NAME=~RXRATE[1]} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~TXRATE[2]} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_case_analysis 0 [get_pins -filter {REF_PIN_NAME=~RXRATE[2]} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
#
set_false_path -from [get_pins -filter {REF_PIN_NAME=~TXUSRCLK2} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]] -to [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_rst_i/sync_txresetdone/sync_vec[*].sync_cell_i/sync_reg[0]/D]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~RXUSRCLK2} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]] -to [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_rst_i/sync_phystatus/sync_vec[*].sync_cell_i/sync_reg[0]/D]
set_false_path -from [get_pins -filter {REF_PIN_NAME=~RXUSRCLK2} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]] -to [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_rst_i/sync_rxresetdone/sync_vec[*].sync_cell_i/sync_reg[0]/D]
#
#
# Make sure that tool gets the correct DIV value for pipe_clock during synthesis as these DIV pins are dynamic.
set_case_analysis 1 [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_pclk/DIV[0]]
set_case_analysis 0 [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_pclk/DIV[1]]
set_case_analysis 0 [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_pclk/DIV[2]]
set_case_analysis 1 [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_coreclk/DIV[0]]
set_case_analysis 0 [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_coreclk/DIV[1]]
set_case_analysis 0 [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_coreclk/DIV[2]]
set_case_analysis 1 [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/DIV[0]]
set_case_analysis 1 [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/DIV[1]]
set_case_analysis 0 [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/DIV[2]]
###############################################################################
# TIMING Exceptions - False Paths
###############################################################################
set_false_path -to [get_pins -hier *sync_reg[0]/D]
set_false_path -to [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/rst_psrst_n_r_reg[*]/CLR]
#set_false_path -to [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/rst_psrst_n_r_rep_reg/CLR]
set_false_path -to [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_rst_i/prst_n_r_reg[*]/CLR]
#set_false_path -to [get_pins oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_rst_i/prst_n_r_rep_reg/CLR]
#
# The below PINs are asynchronous inputs to the GT block.
set_false_path -through [get_pins -filter {REF_PIN_NAME=~RXELECIDLE} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_false_path -through [get_pins -filter {REF_PIN_NAME=~PCIERATEGEN3} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_false_path -through [get_pins -filter {REF_PIN_NAME=~RXPRGDIVRESETDONE} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_false_path -through [get_pins -filter {REF_PIN_NAME=~TXPRGDIVRESETDONE} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_false_path -through [get_pins -filter {REF_PIN_NAME=~PCIESYNCTXSYNCDONE} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_false_path -through [get_pins -filter {REF_PIN_NAME=~GTPOWERGOOD} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]
set_false_path -through [get_pins -filter {REF_PIN_NAME=~CPLLLOCK} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.* }]]

#
# The below PINs are asynchronous inputs to the PCIe block.
set_false_path -through [get_pins -filter {REF_PIN_NAME=~PIPETXMARGIN*} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.PCIE.* }]]
set_false_path -through [get_pins -filter {REF_PIN_NAME=~PIPETXSWING} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.PCIE.* }]]
set_false_path -through [get_pins -filter {REF_PIN_NAME=~PCIEPERST0B} -of_objects [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.PCIE.* }]]
# Async reset registers
set_false_path -to [get_pins user_lnk_up_reg/CLR]
set_false_path -to [get_pins user_reset_reg/PRE]
#
#
###############################################################################
# CLOCK_ROOT LOCKing to Reduce CLOCK SKEW
# Add/Edit  Clock Routing Option to improve clock path skew
###############################################################################
#set_property USER_CLOCK_ROOT X1Y7 [get_nets -of_objects [get_pins bufg_gt_sysclk/O]]
#set_property USER_CLOCK_ROOT X1Y7 [get_nets -of_objects [get_pins -hierarchical -filter NAME=~*/phy_clk_i/bufg_gt_intclk/O]]
#set_property USER_CLOCK_ROOT X1Y7 [get_nets -of_objects [get_pins -hierarchical -filter NAME=~*/phy_clk_i/bufg_gt_coreclk/O]]
#set_property USER_CLOCK_ROOT X1Y7 [get_nets -of_objects [get_pins -hierarchical -filter NAME=~*/phy_clk_i/bufg_gt_userclk/O]]
#
#
#
#
#
###############################################################################
#
###############################################################################
#
#
#

#create_waiver -type METHODOLOGY -id {LUTAR-1} -user "pcie4_uscaleplus" -desc "The rst_in is synchronized before used in logic so it is safe to ignore" -internal -scoped -tags 1024539  -objects [get_cells -hierarchical -filter { NAME =~ *rst_in_meta_i_1* }] -objects [get_pins -filter {REF_PIN_NAME=~ PRE } -of_objects [get_cells -hierarchical  {*rst_in_* }]]

#create_waiver -type METHODOLOGY -id {LUTAR-1} -user "pcie4_uscaleplus" -desc "The PS reset is synchronized before used to it is safe to ignore" -internal -scoped -tags 1024539  -objects [get_cells -hierarchical -filter { NAME =~ *FSM_sequential_pwr_on_fsm_i_2* }] -objects [get_pins -filter {REF_PIN_NAME=~ CLR } -of_objects [get_cells -hierarchical  {*rst_psrst_n_r_reg* }]]

#create_waiver -type METHODOLOGY -id {LUTAR-1} -user "pcie4_uscaleplus" -desc "The user clk is used after user link up so it is safe to ignore" -internal -scoped -tags 1024539   -objects [get_cells -hierarchical -filter { NAME =~ *bufg_gt_userclk_i_2* }] -objects [get_pins -filter {REF_PIN_NAME=~ CLR } -of_objects [get_cells -hierarchical  {*BUFG_GT_SYNC* }]]

#create_waiver -type METHODOLOGY -id {LUTAR-1} -user "pcie4_uscaleplus" -desc "The one hot encoding is used in FSM so it is safe to ignore" -internal -scoped -tags 1024539   -objects [get_cells -hierarchical -filter { NAME =~ *FSM_onehot_fsm[0]_i_1* }] -objects [get_pins -filter {REF_PIN_NAME=~ CLR } -of_objects [get_cells -hierarchical  {*prst_n_r_reg* }]]

#create_waiver -type METHODOLOGY -id {LUTAR-1} -user "pcie4_uscaleplus" -desc "test" -internal -scoped -tags 1024539   -objects [get_cells -hierarchical -filter { NAME =~ *as_mac_in_detect_user_i_2* }] -objects [get_pins -filter {REF_PIN_NAME=~ PRE } -of_objects [get_cells -hierarchical  {*as_mac_in_detect* }]]

#create_waiver -type METHODOLOGY -id {LUTAR-1} -user "pcie4_uscaleplus" -desc "The user link up is synchrozed before used as reset to user clk so it is safe to ignore" -internal -scoped -tags 1024539  -objects [get_cells -hierarchical -filter { NAME =~ *user_lnk_up_i_1* }] -objects [get_pins -filter {REF_PIN_NAME=~ CLR } -of_objects [get_cells -hierarchical  {*user_lnk_up_reg* }]]

#create_waiver -type METHODOLOGY -id {LUTAR-1} -user "pcie4_uscaleplus" -desc "The user reset is generated from user link up and synchrozed so it is safe to ignore" -internal -scoped -tags 1024539   -objects [get_cells -hierarchical -filter { NAME =~ *user_reset_i_1* }] -objects [get_pins -filter {REF_PIN_NAME=~ PRE } -of_objects [get_cells -hierarchical  {*user_reset_reg* }]] -objects  [get_pins -filter {REF_PIN_NAME=~ PRE } -of_objects [get_cells -hierarchical  {*arststages_ff_reg* }]]

#create_waiver -type METHODOLOGY -id {TIMING-9} -internal -scoped -tags 1024539   -user "pcie4_uscaleplus" -desc "The CDC logic is used for clock domain crossing so it can be ignored"

#create_waiver -type CDC -id {CDC-11} -tags "1019576" -desc "properly_synced" -from [get_pins {pcie4_uscale_plus_0_i/inst/oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/pcie4_uscale_plus_0_gt_i/inst/gen_gtwizard_gtye4_top.pcie4_uscale_plus_0_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_cpll_cal_gtye4.gen_cpll_cal_inst[0].gen_inst_cpll_cal.gtwizard_ultrascale_v1_7_5_gtye4_cpll_cal_inst/gtwizard_ultrascale_v1_7_19_5_gtye4_cpll_cal_tx_i/U_TXOUTCLK_FREQ_COUNTER/state_reg[0]/C}] -to [get_pins {pcie4_uscale_plus_0_i/inst/oculink_0a_bd_xdma_0_0_pcie4_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/pcie4_uscale_plus_0_gt_i/inst/gen_gtwizard_gtye4_top.pcie4_uscale_plus_0_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_cpll_cal_gtye4.gen_cpll_cal_inst[0].gen_inst_cpll_cal.gtwizard_ultrascale_v1_7_5_gtye4_cpll_cal_inst/gtwizard_ultrascale_v1_7_19_5_gtye4_cpll_cal_tx_i/U_TXOUTCLK_FREQ_COUNTER/reset_synchronizer_testclk_rst_inst/rst_in_meta_reg/PRE}]
# Power Analysis # Power 33-332
set_switching_activity -toggle_rate 1.000 -static_probability 0.010 [get_nets {user_reset}]
set_switching_activity -toggle_rate 1.000 -static_probability 0.010 [get_nets {sync_sc_clr}]
set_switching_activity -toggle_rate 1.000 -static_probability 0.010 [get_nets {oculink_0a_bd_xdma_0_0_pcie4_ip_pcie_4_0_pipe_inst/src_arst*}]
set_switching_activity -toggle_rate 1.000 -static_probability 0.010 [get_nets {oculink_0a_bd_xdma_0_0_pcie4_ip_pcie_4_0_pipe_inst/sys_reset*}]

# -------------- Adding Waiver ----------------------#

create_waiver -type DRC -id {REQP-1839} -scope -internal -tags "1167240" -user "pcie4_uscale_plus" -desc "DRC expects synchronous pins to be provided to BRAM inputs. Since synchronization is present one stage before, it is safe to ignore" -objects [get_cells -hierarchical -filter {NAME =~ {*inst/debug_wrapper_U/*.ram}}]

create_waiver -type DRC -id {REQP-1840} -scope -internal -tags "1167240" -user "pcie4_uscale_plus" -desc "DRC expects synchronous pins to be provided to BRAM inputs. Since synchronization is present one stage before, it is safe to ignore" -objects [get_cells -hierarchical -filter {NAME =~ {*inst/debug_wrapper_U/*.mem_reg_bram_0} && PRIMITIVE_TYPE =~ {*BRAM*}}]

create_waiver -type DRC -id {REQP-1857} -scope -internal -tags "1167240" -user "pcie4_uscale_plus" -desc "Suggestion to change mode from WRITE_FIRST to NO_CHANGE, safe to waive off based on usecase" -objects [get_cells -hier -filter {NAME =~ {*inst/debug_wrapper_U/*.ram}}]

create_waiver -type DRC -id {REQP-1858} -scope -internal -tags "1167240" -user "pcie4_uscale_plus" -desc "Suggestion to change mode from WRITE_FIRST to NO_CHANGE, safe to waive off based on usecase" -objects [list [get_cells -hier -filter {NAME =~ {*_pipe_inst/pcie_4_0_bram_inst/*.ramb36e2_inst}}] [get_cells -hier -filter {NAME =~ {*inst/debug_wrapper_U/*.ram}}]]

## */ CDC Waivers */ ##
create_waiver -type CDC -id CDC-10 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe user_reset path        - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/sys_reset_in_async_rst_inst/arststages_ff_reg[1]/C}}]  -to [get_pins -hier -filter {NAME =~ {*/inst/sys_or_hot_rst_pclk_inst/arststages_ff_reg[0]/PRE}}]
create_waiver -type CDC -id CDC-10 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe perst logic            - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/sys_reset_in_async_rst_inst/arststages_ff_reg[1]/C}}]  -to [get_pins -hier -filter {NAME =~ {*/inst/sys_or_hot_rst_uclk_inst/arststages_ff_reg[0]/PRE}}]
create_waiver -type CDC -id CDC-10 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe perst logic            - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/sys_reset_in_async_rst_inst/arststages_ff_reg[1]/C}}]  -to [get_pins -hier -filter {NAME =~ {*/inst/user_lnk_up_cdc/arststages_ff_reg[0]/CLR}}]        
create_waiver -type CDC -id CDC-7  -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe user_lnk_up logic      - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/sys_reset_in_async_rst_inst/arststages_ff_reg[1]/C}}]  -to [get_pins -hier -filter {NAME =~ {*/inst/user_lnk_up_reg/CLR}}]                              
create_waiver -type CDC -id CDC-11 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe Phy Wrapper pipeline   - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/phy_pipeline/as_mac_in_detect_chain/with_ff_chain.ff_chain_gen[0].sync_rst.ff_chain_reg[1][0]/C}}]  -to [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_lane[*].receiver_detect_termination_i/sync_mac_in_detect/sync_vec[0].sync_cell_i/sync_reg[0]/D}}] 
create_waiver -type CDC -id CDC-11 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe Phy Wrapper pipeline   - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/phy_pipeline/phy_rate_chain/with_ff_chain.ff_chain_gen[0].sync_rst.ff_chain_reg[1][1]/C}}]          -to [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_lane[*].cdr_ctrl_on_eidle_i/sync_gen34/sync_vec[0].sync_cell_i/sync_reg[0]/D}}]                         
create_waiver -type CDC -id CDC-11 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe Phy Wrapper pipeline   - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/gen4_64b_convert.phy_rate_32b_ff_reg[1]/C}}] -to [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_lane[*].cdr_ctrl_on_eidle_i/sync_gen34/sync_vec[0].sync_cell_i/sync_reg[0]/D}}]
create_waiver -type CDC -id CDC-11 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe Phy Wrapper pipeline   - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/gen4_64b_convert.phy_rate_32b_ff_reg[1]/C}}] -to [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_lane[*].cdr_ctrl_on_eidle_i/sync_gen34/sync_vec[0].sync_cell_i/sync_reg[0]/D}}] 
create_waiver -type CDC -id CDC-10 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe user_reset path        - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/*_pipe_inst/pcie_4_0_e4_inst/CORECLK}}]  -to [get_pins -hier -filter {NAME =~ {*/inst/sys_or_hot_rst_pclk_inst/arststages_ff_reg[0]/PRE}}]
create_waiver -type CDC -id CDC-11 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe Phy Wrapper pipeline   - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/phy_rxcdrhold_pclk2_reg/C}}]  -to [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_lane[*].cdr_ctrl_on_eidle_i/sync_rxcdrreset_in/sync_vec[0].sync_cell_i/sync_reg[0]/D}}]  

create_waiver -type CDC -id CDC-7 -scope  -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe perst logic            - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/sys_reset_in_async_rst_inst/arststages_ff_reg[1]/C}}]  -to [get_pins -hier -filter {NAME =~ {*/inst/debug_wrapper_U/debug_probes_inst/cur_ltssm_st_reg[*]/CLR}}]
create_waiver -type CDC -id CDC-7 -scope  -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe perst logic            - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/sys_reset_in_async_rst_inst/arststages_ff_reg[1]/C}}]  -to [get_pins -hier -filter {NAME =~ {*/inst/debug_wrapper_U/debug_probes_inst/pre_ltssm_st_reg[*]/CLR}}]

create_waiver -type CDC -id CDC-11 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe Phy Wrapper pipeline   - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_lane[*].diablo_gt_eyescanreset_drp_i/rate_change_extend_pclk_reg/C}}] -to [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_lane[*].diablo_gt_eyescanreset_drp_i/sync_rate_change/sync_vec[0].sync_cell_i/sync_reg[0]/D}}]
create_waiver -type CDC -id CDC-11 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe Phy Wrapper pipeline   - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/phy_pipeline/phy_rate_chain/with_ff_chain.ff_chain_gen[0].sync_rst.ff_chain_reg[1][1]/C}}]               -to [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_lane[*].phy_rxeq_i/*dfe_lpm_auto_switch_i/sync_rate/sync_vec[0].sync_cell_i/sync_reg[0]/D}}]
create_waiver -type CDC -id CDC-11 -scope -internal -tags "1165868" -user "pcie4_uscale_plus" -desc "PCIe Phy Wrapper pipeline   - safe to waive" -from [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_rst_i/prst_n_r_rep_reg/C}}]                                          -to [get_pins -hier -filter {NAME =~ {*/inst/*_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_lane[*].phy_rxeq_i/*dfe_lpm_auto_switch_i/sync_reset/sync_vec[0].sync_cell_i/sync_reg[0]/D}}]
