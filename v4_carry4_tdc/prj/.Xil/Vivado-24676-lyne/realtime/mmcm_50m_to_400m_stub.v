// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module mmcm_50m_to_400m(clk_out1, reset, locked, clk_in1);
  output clk_out1;
  input reset;
  output locked;
  input clk_in1;
endmodule
