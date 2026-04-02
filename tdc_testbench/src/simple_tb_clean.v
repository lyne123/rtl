`timescale 1ps/1ps

/**
 * 简单PWM生成器测试平台（清理版）
 * 配合top_pwm_gen.v和pwm_auto_cycle_scan模块
 */

module simple_tb_clean();

// ============================================================================
// 测试信号定义
// ============================================================================

// 系统信号
reg sys_clk;
reg sys_rst_n;

// 输出信号
wire pwm_out;

// ============================================================================
// 时钟生成 (50MHz)
// ============================================================================

initial begin
    sys_clk = 1'b0;
    forever #10000 sys_clk = ~sys_clk;  // 20ns周期 = 50MHz
end

// ============================================================================
// 复位控制
// ============================================================================

initial begin
    // 初始复位状态
    sys_rst_n = 1'b0;

    // 20ns后释放复位
    #20000;
    sys_rst_n = 1'b1;

    $display("[%t] 复位释放，系统开始工作", $time);
end

// ============================================================================
// 被测顶层模块实例化
// ============================================================================

top_pwm_gen uut (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .pwm_out(pwm_out)
);

// ============================================================================
// 信号监控
// ============================================================================

// 主监控进程
initial begin
    $monitor("[%t] PWM=%b", $time, pwm_out);
end

// ============================================================================
// PWM信号分析
// ============================================================================

// 检测PWM周期和脉宽变化
reg last_pwm;
reg [31:0] cycle_count;
reg [31:0] high_count;

time last_rise_edge;
real pwm_period;
real high_time_ns;

always @(posedge sys_clk) begin
    last_pwm <= pwm_out;

    // 检测PWM上升沿
    if (!last_pwm && pwm_out) begin
        cycle_count <= cycle_count + 1;

        // 计算周期
        if (last_rise_edge > 0) begin
            pwm_period = $realtime - last_rise_edge;
            $display("[%t] PWM周期%d: %0.1fns", $time, cycle_count, pwm_period);
        end
        last_rise_edge = $realtime;

        // 计算高电平时间
        if (high_count > 0) begin
            high_time_ns = (high_count * 20.0);  // 20ns per sys_clk cycle
            $display("[%t] 高电平时间: %0.1fns (%d cycles)",
                    $time, high_time_ns, high_count);
        end

        high_count <= 0;
    end

    // 统计高电平时间
    if (pwm_out) begin
        high_count <= high_count + 1;
    end
end

// ============================================================================
// 自动验证
// ============================================================================

// 验证PWM周期是否为50ns
real expected_period = 50.0;  // 50ns
real period_tolerance = 2.0;  // ±2ns容差

always @(cycle_count) begin
    if (cycle_count > 0 && cycle_count <= 10) begin
        if (pwm_period < (expected_period - period_tolerance) ||
            pwm_period > (expected_period + period_tolerance)) begin
            $display("WARNING: PWM周期%0.1fns超出预期范围(50ns±2ns)", pwm_period);
        end else begin
            $display("INFO: PWM周期%0.1fns在正常范围内", pwm_period);
        end
    end
end

// ============================================================================
// 仿真控制
// ============================================================================

// 仿真时间控制
initial begin
    // 运行足够长时间观察PWM变化
    #10000000;  // 10us
    $display("[%t] 仿真完成", $time);
    $finish;
end

// ============================================================================
// 波形输出
// ============================================================================

initial begin
    $dumpfile("simple_tb_clean.vcd");
    $dumpvars(0, simple_tb_clean);
end

// ============================================================================
// 错误检测
// ============================================================================

// 检查信号是否有效
always @(posedge sys_clk) begin
    if (pwm_out === 1'bx || pwm_out === 1'bz) begin
        $display("ERROR: PWM信号出现无效状态");
        $stop;
    end
end

// 超时检测
initial begin
    #20000000;  // 20us超时
    $display("[%t] 仿真超时", $time);
    $finish;
end

endmodule
