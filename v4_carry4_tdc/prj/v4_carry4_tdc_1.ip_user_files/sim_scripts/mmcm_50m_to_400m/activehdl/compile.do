vlib work
vlib activehdl

vlib activehdl/xpm
vlib activehdl/xil_defaultlib

vmap xpm activehdl/xpm
vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xpm  -sv2k12 "+incdir+../../../ipstatic" \
"D:/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93 \
"D:/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../ipstatic" \
"../../../../v4_carry4_tdc_1.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m_clk_wiz.v" \
"../../../../v4_carry4_tdc_1.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m.v" \

vlog -work xil_defaultlib \
"glbl.v"

