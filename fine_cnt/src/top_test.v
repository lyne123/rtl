
//用于跑实现仿真所写的顶层测试模块，连接MMCM和TDC模块，并提供必要的时钟和复位信号。
//同时包含在线逻辑分析仪的连接（注释掉了ILA实例化部分

//2026年3月30日 9:41:00


module top_test(
    input   sys_clk,    //系统时钟
    input   sys_rst_n,  //系统复位，低有效
    input   pwm_signal, //外部输入信号
    output  valid_out   //输出有效信号指示（连接led灯（led高亮低灭
);

//50m->400mhz
wire     rst_n;
wire     mmcm_locked;//PLL时钟锁定信号
wire     clk_400m;
wire    [6:0] fine_count_a;
wire    [6:0] fine_count_b;
// =========================================================================
// 模块实例化
// =========================================================================
assign rst_n = sys_rst_n & mmcm_locked;

// 1. MMCM倍频模块 (50MHz -> 400MHz) - Vivado IP核
mmcm_50m_to_400m u_mmcm (
    .clk_in1(sys_clk),      // 输入50MHz时钟
    .reset(~sys_rst_n),         // 复位信号（IP核高电平有效）
    .clk_out1(clk_400m),    // 输出400MHz时钟
    .locked(mmcm_locked)    // 锁定信号
);

//2. TDC 模块实例化
fine_counter_carry4 u_fine_counter (
    .clk_400m(clk_400m),
    .rst_n(rst_n),
    .pwm_signal(pwm_signal),
    .fine_count_a(fine_count_a),
    .fine_count_b(fine_count_b),
    .valid_out(valid_out)
); 

//3.在线逻辑分析仪 - 连接到TDC输出信号
ila_0 u_ila (
    .clk(clk_400m),          // 连接到400MHz时钟
    .probe0(fine_count_a),   // 监视细计数值 'a'
    .probe1(fine_count_b),   // 监视细计数值 'b'
    .probe2(valid_out)      // 监视输出有效信号
);

endmodule