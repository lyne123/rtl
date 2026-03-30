// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Mon Mar 30 10:17:16 2026
// Host        : lyne running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/01-Codes/XilinxCode/Vernier_tdc/fine_cnt/prj/fine_cnt.gen/sources_1/ip/mmcm_50m_to_400m/mmcm_50m_to_400m_stub.v
// Design      : mmcm_50m_to_400m
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tfgg484-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module mmcm_50m_to_400m(clk_out1, reset, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,reset,locked,clk_in1" */;
  output clk_out1;
  input reset;
  output locked;
  input clk_in1;
endmodule
