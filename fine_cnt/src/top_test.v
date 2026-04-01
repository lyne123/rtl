
//用于跑实现仿真所写的顶层测试模块，连接MMCM和TDC模块，并提供必要的时钟和复位信号。
//同时包含在线逻辑分析仪的连接（注释掉了ILA实例化部分

//2026年3月30日 9:41:00


module top_test(
    input   sys_clk,    //系统时钟
    input   sys_rst_n,  //系统复位，低有效
    input   pwm_signal, //外部输入信号
    output  reg [3:0] led_out   //输出有效信号指示（连接led灯（led高亮低灭
);

//50m->400mhz
wire     rst_n;
wire     mmcm_locked;//PLL时钟锁定信号
wire     clk_400m;
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

//4. LED指示灯控制逻辑
// led_out[0]: fine_count_a 有值指示 (led0)
// led_out[1]: fine_count_b 有值指示 (led1)
// led_out[2]: 输出有效指示 (led2)
// led_out[3]: 复位结束指示 (led3)
always @(posedge clk_400m or negedge rst_n) begin
    if (!rst_n) begin
        led_out <= 4'b0000;  // 复位时熄灭所有灯
    end else begin
        // led0: 检测 fine_count_a 是否有值（非零）
        led_out[0] <= (fine_count_a != 8'd0);

        // led1: 检测 fine_count_b 是否有值（非零）
        led_out[1] <= (fine_count_b != 8'd0);

        // led2: 输出有效信号指示
        led_out[2] <= valid_out;

        // led3: 复位结束指示（复位结束后常亮）
        led_out[3] <= 1'b1;
    end
end

endmodule