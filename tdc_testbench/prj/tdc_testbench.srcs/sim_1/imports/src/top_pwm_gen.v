//2026年4月2日 9:41:00


module top_pwm_gen(
    input   sys_clk,    //系统时钟
    input   sys_rst_n,  //系统复位，低有效
    output   pwm_out //输出信号
);

// MMCM生成的四个相位时钟
wire clk_400m_0, clk_400m_90, clk_400m_180, clk_400m_270;
wire rst_n;

assign rst_n = sys_rst_n & mmcm_locked;

clk_wiz_0 instance_name(
    // Clock out ports
    .clk_out1(clk_400m_0),     // output clk_out1
    .clk_out2(clk_400m_90),     // output clk_out2
    .clk_out3(clk_400m_180),     // output clk_out3
    .clk_out4(clk_400m_270),     // output clk_out4
    // Status and control signals
    .reset(~sys_rst_n), // input reset
    .locked(mmcm_locked),       // output locked
    // Clock in ports
    .clk_in1(sys_clk)        // input clk_in1

);     

tdc_stimulus_generator_simple uut (
    .clk_400m(clk_400m_0),
    .clk_400m_90(clk_400m_90),
    .clk_400m_180(clk_400m_180),
    .clk_400m_270(clk_400m_270),
    .rst_n(rst_n),
    .pwm_out(pwm_out)
);

endmodule