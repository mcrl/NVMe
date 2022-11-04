-- Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2021.2 (win64) Build 3367213 Tue Oct 19 02:48:09 MDT 2021
-- Date        : Fri Nov  4 14:11:00 2022
-- Host        : DESKTOP-UAALCIP running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub c:/Users/js-shin/Desktop/NVMe/hw/IP/ila_cfg/ila_cfg_stub.vhdl
-- Design      : ila_cfg
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu19eg-ffvd1760-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ila_cfg is
  Port ( 
    clk : in STD_LOGIC;
    probe0 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe1 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe2 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    probe3 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe4 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe5 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe6 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe7 : in STD_LOGIC_VECTOR ( 74 downto 0 );
    probe8 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    probe9 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe10 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe11 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe12 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe13 : in STD_LOGIC_VECTOR ( 61 downto 0 );
    probe14 : in STD_LOGIC_VECTOR ( 5 downto 0 );
    probe15 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe16 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe17 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe18 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe19 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe20 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe21 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe22 : in STD_LOGIC_VECTOR ( 2 downto 0 );
    probe23 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe24 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe25 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    probe26 : in STD_LOGIC_VECTOR ( 5 downto 0 );
    probe27 : in STD_LOGIC_VECTOR ( 31 downto 0 )
  );

end ila_cfg;

architecture stub of ila_cfg is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe0[0:0],probe1[0:0],probe2[127:0],probe3[3:0],probe4[0:0],probe5[0:0],probe6[0:0],probe7[74:0],probe8[127:0],probe9[3:0],probe10[0:0],probe11[0:0],probe12[0:0],probe13[61:0],probe14[5:0],probe15[0:0],probe16[3:0],probe17[3:0],probe18[31:0],probe19[0:0],probe20[7:0],probe21[3:0],probe22[2:0],probe23[0:0],probe24[0:0],probe25[7:0],probe26[5:0],probe27[31:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "ila,Vivado 2021.2";
begin
end;
