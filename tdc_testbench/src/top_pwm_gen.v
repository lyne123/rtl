//2026年4月2日 9:41:00


module top_pwm_gen(
    input   sys_clk,    //系统时钟
    input   sys_rst_n,  //系统复位，低有效
    output   pwm_out    //PWM输出信号
);

// MMCM生成的四个相位时钟
wire clk_400m_144deg;
wire clk_400m;
wire rst_n;

assign rst_n = sys_rst_n & mmcm_locked;

clk_wiz_0 u_clk_0(
    // Clock out ports
    .clk_out1(clk_400m_144deg),     // output clk_out1
    .clk_out2(clk_400m),     // output clk_out1
    // Status and control signals
    .reset(~sys_rst_n), // input reset
    .locked(mmcm_locked),       // output locked
    // Clock in ports
    .clk_in1(sys_clk)        // input clk_in1

);     

pwm_auto_cycle_scan u_pwm_gen (
    .clk_400m_144deg(clk_400m_144deg),
    .rst_n(rst_n),
    .pwm_out(pwm_out)
);

endmodule