vlib work
vlib riviera

vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -sv2k12 "+incdir+../../../ipstatic" \
"D:/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93 \
"D:/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../ipstatic" \
"../../../../combine_fine_pwm_gen.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m_clk_wiz.v" \
"../../../../combine_fine_pwm_gen.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m.v" \

vlog -work xil_defaultlib \
"glbl.v"

