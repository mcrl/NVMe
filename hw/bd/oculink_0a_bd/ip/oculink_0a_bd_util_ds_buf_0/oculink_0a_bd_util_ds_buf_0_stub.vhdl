-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
-- Date        : Mon Jun 22 08:56:51 2026
-- Host        : aespa running 64-bit Ubuntu 20.04.5 LTS
-- Command     : write_vhdl -force -mode synth_stub -rename_top oculink_0a_bd_util_ds_buf_0 -prefix
--               oculink_0a_bd_util_ds_buf_0_ host_xdma_bd_util_ds_buf_0_stub.vhdl
-- Design      : host_xdma_bd_util_ds_buf_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu19eg-ffvd1760-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity oculink_0a_bd_util_ds_buf_0 is
  Port ( 
    IBUF_DS_P : in STD_LOGIC_VECTOR ( 0 to 0 );
    IBUF_DS_N : in STD_LOGIC_VECTOR ( 0 to 0 );
    IBUF_OUT : out STD_LOGIC_VECTOR ( 0 to 0 );
    IBUF_DS_ODIV2 : out STD_LOGIC_VECTOR ( 0 to 0 )
  );

  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of oculink_0a_bd_util_ds_buf_0 : entity is "host_xdma_bd_util_ds_buf_0,util_ds_buf,{}";
  attribute core_generation_info : string;
  attribute core_generation_info of oculink_0a_bd_util_ds_buf_0 : entity is "host_xdma_bd_util_ds_buf_0,util_ds_buf,{x_ipProduct=Vivado 2024.2,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=util_ds_buf,x_ipVersion=2.2,x_ipCoreRevision=7,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_SIZE=1,C_BUF_TYPE=ibufdsgte4,C_BUFGCE_DIV=1,C_BUFG_GT_SYNC=0,C_OBUFDS_GTE5_ADV=00,C_REFCLK_ICNTL_TX=00000,C_SIM_DEVICE=VERSAL_AI_CORE_ES1}";
  attribute downgradeipidentifiedwarnings : string;
  attribute downgradeipidentifiedwarnings of oculink_0a_bd_util_ds_buf_0 : entity is "yes";
end oculink_0a_bd_util_ds_buf_0;

architecture stub of oculink_0a_bd_util_ds_buf_0 is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "IBUF_DS_P[0:0],IBUF_DS_N[0:0],IBUF_OUT[0:0],IBUF_DS_ODIV2[0:0]";
  attribute x_interface_info : string;
  attribute x_interface_info of IBUF_DS_P : signal is "xilinx.com:interface:diff_clock:1.0 CLK_IN_D CLK_P";
  attribute x_interface_mode : string;
  attribute x_interface_mode of IBUF_DS_P : signal is "slave CLK_IN_D";
  attribute x_interface_parameter : string;
  attribute x_interface_parameter of IBUF_DS_P : signal is "XIL_INTERFACENAME CLK_IN_D, BOARD.ASSOCIATED_PARAM DIFF_CLK_IN_BOARD_INTERFACE, CAN_DEBUG false, FREQ_HZ 100000000";
  attribute x_interface_info of IBUF_DS_N : signal is "xilinx.com:interface:diff_clock:1.0 CLK_IN_D CLK_N";
  attribute x_interface_info of IBUF_OUT : signal is "xilinx.com:signal:clock:1.0 IBUF_OUT CLK";
  attribute x_interface_mode of IBUF_OUT : signal is "master IBUF_OUT";
  attribute x_interface_parameter of IBUF_OUT : signal is "XIL_INTERFACENAME IBUF_OUT, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN host_xdma_bd_util_ds_buf_0_IBUF_OUT, INSERT_VIP 0";
  attribute x_interface_info of IBUF_DS_ODIV2 : signal is "xilinx.com:signal:clock:1.0 IBUF_DS_ODIV2 CLK";
  attribute x_interface_mode of IBUF_DS_ODIV2 : signal is "master IBUF_DS_ODIV2";
  attribute x_interface_parameter of IBUF_DS_ODIV2 : signal is "XIL_INTERFACENAME IBUF_DS_ODIV2, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN host_xdma_bd_util_ds_buf_0_IBUF_DS_ODIV2, INSERT_VIP 0";
  attribute x_core_info : string;
  attribute x_core_info of stub : architecture is "util_ds_buf,Vivado 2024.2";
begin
end;
