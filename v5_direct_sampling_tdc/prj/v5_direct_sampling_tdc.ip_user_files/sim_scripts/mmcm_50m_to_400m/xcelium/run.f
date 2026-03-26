-makelib xcelium_lib/xpm -sv \
  "D:/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "D:/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../v5_direct_sampling_tdc.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m_clk_wiz.v" \
  "../../../../v5_direct_sampling_tdc.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

