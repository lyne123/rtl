-makelib ies_lib/xpm -sv \
  "D:/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib ies_lib/xpm \
  "D:/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../combine_fine_pwm_gen.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m_clk_wiz.v" \
  "../../../../combine_fine_pwm_gen.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

