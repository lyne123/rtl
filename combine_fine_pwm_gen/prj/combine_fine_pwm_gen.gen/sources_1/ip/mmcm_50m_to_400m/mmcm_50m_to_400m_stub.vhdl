-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
-- Date        : Thu Apr  2 16:45:46 2026
-- Host        : lyne running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               d:/01-Codes/XilinxCode/Vernier_tdc/combine_fine_pwm_gen/prj/combine_fine_pwm_gen.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m_stub.vhdl
-- Design      : mmcm_50m_to_400m
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100tfgg484-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mmcm_50m_to_400m is
  Port ( 
    clk_out1 : out STD_LOGIC;
    clk_out2 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );

end mmcm_50m_to_400m;

architecture stub of mmcm_50m_to_400m is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_out1,clk_out2,reset,locked,clk_in1";
begin
end;
