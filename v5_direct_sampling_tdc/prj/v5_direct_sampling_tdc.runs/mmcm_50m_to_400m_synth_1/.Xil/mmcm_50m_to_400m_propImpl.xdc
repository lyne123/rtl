set_property SRC_FILE_INFO {cfile:d:/01-Codes/XilinxCode/Vernier_tdc/v5_direct_sampling_tdc/prj/v5_direct_sampling_tdc.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m.xdc rfile:../../../v5_direct_sampling_tdc.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
current_instance inst
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.2
