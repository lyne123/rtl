vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm  -incr -sv "+incdir+../../../ipstatic" \
"D:/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm  -93 \
"D:/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr "+incdir+../../../ipstatic" \
"../../../../combine_fine_pwm_gen.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m_clk_wiz.v" \
"../../../../combine_fine_pwm_gen.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m.v" \

vlog -work xil_defaultlib \
"glbl.v"

