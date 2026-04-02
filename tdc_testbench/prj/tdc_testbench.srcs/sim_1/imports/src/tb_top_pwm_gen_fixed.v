// 顶层PWM生成器模块测试平台
// 针对顶层模块top_pwm_gen的测试文件

`timescale 1ps/1ps

module tb_top_pwm_gen_fixed;

// 顶层模块接口信号
reg sys_clk;           // 系统时钟输入
reg sys_rst_n;         // 系统复位输入
wire pwm_signal;       // PWM信号输出

// 测试监控信号
integer simulation_time = 0;
integer pwm_period_count = 0;
integer pwm_high_count = 0;
reg last_pwm_state = 1'b0;
real measured_frequency;
real measured_duty_cycle;

// 随机性分析变量
integer phase_changes = 0;
integer duty_changes = 0;
reg [1:0] last_phase = 2'b00;
reg [7:0] last_duty = 8'd0;

// 性能监控变量
time start_time, end_time;
integer periods_in_window = 0;

// 时钟生成 - 假设输入是50MHz系统时钟
initial begin
    sys_clk = 1'b0;
    forever #10000 sys_clk = ~sys_clk; // 50MHz = 20ns周期 = 10000ps
end

// 复位生成
initial begin
    sys_rst_n = 1'b0;
    #100000;              // 保持复位100ns
    sys_rst_n = 1'b1;     // 释放复位
    $display("复位信号释放，时间：%0t ps", $time);
end

// 实例化顶层模块
top_pwm_gen uut (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .pwm_signal(pwm_signal)
);

// PWM信号监测和分析
always @(posedge uut.clk_400m_0 or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        pwm_period_count <= 0;
        pwm_high_count <= 0;
        last_pwm_state <= 1'b0;
    end else begin
        // 统计高电平周期
        if (pwm_signal) begin
            pwm_high_count <= pwm_high_count + 1;
        end

        // 检测PWM周期结束（下降沿）
        if (last_pwm_state && !pwm_signal) begin
            pwm_period_count <= pwm_period_count + 1;

            // 计算测量值
            if (pwm_period_count > 0) begin
                measured_frequency = 400.0 / pwm_period_count; // MHz
                measured_duty_cycle = (pwm_high_count * 100.0) / (20.0 * pwm_period_count);

                $display("时间=%0t: 第%0d个PWM周期完成", $time, pwm_period_count);
                $display("  当前占空比: %0d/255 (%.2f%%)", uut.duty_cycle, measured_duty_cycle);
                $display("  当前相位: %b", uut.phase_sel);
                $display("  高电平周期数: %0d", pwm_high_count);
            end

            pwm_high_count <= 0;
        end

        last_pwm_state <= pwm_signal;
    end
end

// 仿真时间计数器
always @(posedge uut.clk_400m_0) begin
    if (sys_rst_n) begin
        simulation_time <= simulation_time + 1;
    end
end

// 随机性分析
initial begin
    wait(sys_rst_n == 1'b1);
    #100000; // 等待系统稳定

    forever begin
        @(posedge uut.clk_400m_0);

        // 监测相位变化
        if (uut.phase_sel != last_phase) begin
            phase_changes <= phase_changes + 1;
            last_phase <= uut.phase_sel;

            if (phase_changes <= 10) begin
                $display("检测到相位变化: %b -> %b，时间：%0t",
                        last_phase, uut.phase_sel, $time);
            end
        end

        // 监测占空比变化
        if (uut.duty_cycle != last_duty) begin
            duty_changes <= duty_changes + 1;
            last_duty <= uut.duty_cycle;

            if (duty_changes <= 10) begin
                $display("检测到占空比变化: %0d -> %0d，时间：%0t",
                        last_duty, uut.duty_cycle, $time);
            end
        end

        // 每1000个周期打印一次统计信息
        if (simulation_time % 1000 == 0 && simulation_time > 0) begin
            $display("仿真进度: %0d个时钟周期，%0d个PWM周期，%0d次相位变化",
                    simulation_time, pwm_period_count, phase_changes);
        end
    end
end

// 参数范围检查
always @(posedge uut.clk_400m_0) begin
    if (sys_rst_n) begin
        // 检查占空比范围（应该在5%-95%之间，即13-242）
        if (uut.duty_cycle < 8'd13 || uut.duty_cycle > 8'd242) begin
            $warning("占空比超出预期范围: %0d，时间：%0t",
                    uut.duty_cycle, $time);
        end

        // 检查相位选择是否有效
        if (uut.phase_sel > 2'b11) begin
            $error("无效的相位选择: %b，时间：%0t", uut.phase_sel, $time);
        end
    end
end

// 仿真控制和结束
initial begin
    // 等待复位完成
    wait(sys_rst_n == 1'b1);

    // 运行足够时间观察随机特性（约1000个PWM周期）
    #5000000; // 5微秒

    // 打印最终结果
    $display("\n=== 仿真完成 ===");
    $display("总仿真时间: %0t ps", $time);
    $display("总PWM周期数: %0d", pwm_period_count);
    $display("平均频率: %.3f MHz", (pwm_period_count * 1000.0) / ($time / 1000.0));
    $display("预期频率: 20 MHz (50ns周期)");

    if (pwm_period_count > 0) begin
        $display("频率精度: %.2f%%",
                ((pwm_period_count * 1000.0) / ($time / 1000.0) - 20.0) / 20.0 * 100.0);
    end

    // 结束仿真
    $finish;
end

// 性能监控
initial begin
    wait(sys_rst_n == 1'b1);
    #200000; // 等待稳定

    forever begin
        start_time = $time;
        periods_in_window = pwm_period_count;

        #100000; // 100ns窗口

        end_time = $time;
        periods_in_window = pwm_period_count - periods_in_window;

        if (periods_in_window > 0) begin
            $display("频率测量: %.3f MHz (在%0t ps时间窗口内)",
                    (periods_in_window * 1000.0) / ((end_time - start_time) / 1000.0),
                    end_time - start_time);
        end
    end
end

endmodule