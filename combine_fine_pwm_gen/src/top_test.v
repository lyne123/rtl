
//用于跑实现仿真所写的顶层测试模块，连接MMCM和TDC模块，并提供必要的时钟和复位信号。
//同时包含在线逻辑分析仪的连接（注释掉了ILA实例化部分

//2026年3月30日 9:41:00


module top_test(
    input   sys_clk,    //系统时钟
    input   sys_rst_n  //系统复位，低有效
);

//50m->400mhz
wire     rst_n;
wire     tdc_rst_n;
wire     mmcm_locked;//PLL时钟锁定信号
wire     clk_400m;
wire     clk_400m_144deg;
wire    [7:0] fine_count_a;
wire    [7:0] fine_count_b;
wire          valid_out;
// =========================================================================
// 模块实例化
// =========================================================================
assign rst_n = sys_rst_n & mmcm_locked;


// 1. MMCM倍频模块 (50MHz -> 400MHz) - Vivado IP核
mmcm_50m_to_400m u_mmcm (
    .clk_in1(sys_clk),      // 输入50MHz时钟
    .reset(~sys_rst_n),         // 复位信号（IP核高电平有效）
    .clk_out1(clk_400m),    // 输出400MHz时钟
    .clk_out2(clk_400m_144deg),    // 输出400MHz时钟
    .locked(mmcm_locked)    // 锁定信号
);

// 2. PWM生成模块
pwm_auto_cycle_scan u_pwm_gen (
    .clk_400m_144deg(clk_400m_144deg),
    .rst_n(rst_n),
    .pwm_out(pwm_out)
);

// 3. TDC 模块实例化
fine_counter_carry4 u_fine_counter (
    .clk_400m(clk_400m),
    .rst_n(rst_n),
    .pwm_signal(pwm_out),
    .fine_count_a(fine_count_a),
    .fine_count_b(fine_count_b),
    .valid_out(valid_out)
); 


endmodule