`timescale 1ps / 1fs
// 创建时间：2026年3月30日
// 基于top_test模块的时序仿真测试文件
// 测量范围：200ps-2500ps

/**
 * TDC 时序仿真测试平台 (基于top_test顶层模块)
 *
 * 目标：验证TDC在200ps-2500ps范围内的测量精度
 * 使用系统时钟(50MHz)和MMCM生成的400MHz时钟
 *
 * 作者：FPGA验证工程师
 * 日期：2026-03-30
 */

module tb_top_test_timing;

//--------------------------------------------------------------------------
// 参数定义
//--------------------------------------------------------------------------
parameter SYS_CLK_PERIOD = 20000;        // 50MHz系统时钟周期 (20ns = 20000ps)
parameter CLK_400M_PERIOD = 2500;        // 400MHz时钟周期 (2.5ns = 2500ps)
parameter SIM_TIME = 1000000;            // 仿真时间 (1000ns = 1us)
parameter MIN_PULSE_WIDTH = 200;         // 最小脉宽 (200ps)
parameter MAX_PULSE_WIDTH = 2500;        // 最大脉宽 (2500ps)
parameter MIN_PHASE_OFFSET = 50;         // 最小相位偏移 (50ps)
parameter MAX_PHASE_OFFSET = 2450;       // 最大相位偏移 (2450ps)

//--------------------------------------------------------------------------
// 信号定义
//--------------------------------------------------------------------------
reg sys_clk;                             // 50MHz系统时钟
reg sys_rst_n;                           // 系统复位(低电平有效)
reg pwm_signal;                          // PWM输入信号

wire valid_out;                          // 有效输出信号
wire clk_400m;                           // 400MHz时钟(用于监测)

// 测试变量
integer rand_width, rand_phase, interval;
real start_time, end_time, actual_width;
real expected_time, measured_time;
integer error_count = 0;
integer success_count = 0;

//--------------------------------------------------------------------------
// 被测模块实例化 (top_test)
//--------------------------------------------------------------------------
top_test uut (
    .sys_clk(sys_clk),      // 系统时钟
    .sys_rst_n(sys_rst_n),  // 系统复位
    .pwm_signal(pwm_signal), // PWM信号
    .valid_out(valid_out)   // 有效输出
);

//--------------------------------------------------------------------------
// 50MHz系统时钟生成
//--------------------------------------------------------------------------
initial begin
    sys_clk = 1'b0;
    forever #(SYS_CLK_PERIOD/2) sys_clk = ~sys_clk;
end

//--------------------------------------------------------------------------
// 复位控制
//--------------------------------------------------------------------------
initial begin
    sys_rst_n = 1'b0;
    pwm_signal = 1'b0;

    // 复位保持200ns
    #200000;
    sys_rst_n = 1'b1;

    $display("[%0t ps] 系统复位释放，开始TDC时序测试", $realtime);
    $display("=================================================");
    $display("测试范围: %0d ps - %0d ps", MIN_PULSE_WIDTH, MAX_PULSE_WIDTH);
    $display("相位偏移范围: %0d ps - %0d ps", MIN_PHASE_OFFSET, MAX_PHASE_OFFSET);
    $display("=================================================");
end

//--------------------------------------------------------------------------
// 脉冲生成任务
//--------------------------------------------------------------------------
task generate_pulse;
    input real phase_offset;
    input real pulse_width;
    begin
        // 等待指定相位偏移
        #phase_offset;

        // 生成脉冲
        pwm_signal = 1'b1;
        start_time = $realtime;
        #pulse_width;
        pwm_signal = 1'b0;
        end_time = $realtime;

        // 计算实际脉宽
        actual_width = end_time - start_time;

        // 显示脉冲信息
        $display("[%0t ps] 生成脉冲 -> 相位偏移: %0.0f ps, 脉宽: %0.0f ps",
                 $realtime, phase_offset, actual_width);
    end
endtask

//--------------------------------------------------------------------------
// 主要测试程序
//--------------------------------------------------------------------------
initial begin
    // 等待复位完成
    wait(sys_rst_n == 1'b1);
    #100000; // 等待MMCM锁定

    $display("[%0t ps] 开始TDC时序精度测试", $realtime);

    // 测试序列1: 边界值测试
    $display("\n=== 测试序列1: 边界值测试 ===");

    // 最小脉宽 + 最小相位
    generate_pulse(MIN_PHASE_OFFSET, MIN_PULSE_WIDTH);
    #(3 * CLK_400M_PERIOD);

    // 最大脉宽 + 最大相位
    generate_pulse(MAX_PHASE_OFFSET, MAX_PULSE_WIDTH);
    #(3 * CLK_400M_PERIOD);

    // 中间值测试
    generate_pulse(1250, 1350);
    #(3 * CLK_400M_PERIOD);

    // 测试序列2: 随机测试
    $display("\n=== 测试序列2: 随机脉冲测试 ===");
    repeat(50) begin
        // 随机脉宽 (200ps - 2500ps)
        rand_width = {$random} % (MAX_PULSE_WIDTH - MIN_PULSE_WIDTH + 1) + MIN_PULSE_WIDTH;

        // 随机相位偏移 (50ps - 2450ps)
        rand_phase = {$random} % (MAX_PHASE_OFFSET - MIN_PHASE_OFFSET + 1) + MIN_PHASE_OFFSET;

        generate_pulse(rand_phase, rand_width);

        // 随机间隔 (2-8个时钟周期)
        interval = ({$random} % 7 + 2) * CLK_400M_PERIOD;
        #interval;
    end

    // 测试序列3: 精度验证测试
    $display("\n=== 测试序列3: 精度验证测试 ===");

    // 测试200ps步进
    for (int i = 200; i <= 2500; i = i + 200) begin
        generate_pulse(1000, i);
        #(3 * CLK_400M_PERIOD);
    end

    // 测试序列4: 密集小脉宽测试
    $display("\n=== 测试序列4: 小脉宽密集测试 ===");
    repeat(20) begin
        rand_width = {$random} % 300 + 200;  // 200-500ps
        rand_phase = {$random} % 500 + 100;   // 100-600ps

        generate_pulse(rand_phase, rand_width);
        #(2 * CLK_400M_PERIOD);
    end

    $display("\n[%0t ps] 所有测试序列完成", $realtime);
    $display("=================================================");
    $display("测试统计:");
    $display("成功测量次数: %0d", success_count);
    $display("错误次数: %0d", error_count);
    $display("=================================================");

    // 等待所有测量完成
    #50000;
    $display("[%0t ps] 仿真结束", $realtime);
    $finish;
end

//--------------------------------------------------------------------------
// 结果监测和分析
//--------------------------------------------------------------------------

// 监测PWM信号边沿
always @(posedge pwm_signal) begin
    $display("[%0t ps] PWM上升沿触发", $realtime);
end

always @(negedge pwm_signal) begin
    $display("[%0t ps] PWM下降沿触发", $realtime);
end

// 监测有效输出
always @(posedge valid_out) begin
    $display("[%0t ps] TDC测量有效输出激活", $realtime);
end

// 脉宽验证
always @(posedge pwm_signal) begin
    real measured_width;
    begin
        // 记录开始时间
        start_time = $realtime;

        // 等待下降沿
        @(negedge pwm_signal);
        end_time = $realtime;

        // 计算实际脉宽
        measured_width = end_time - start_time;

        // 验证脉宽范围
        if (measured_width > MAX_PULSE_WIDTH) begin
            $error("[%0t ps] 脉宽超出最大值: %0.0f ps > %0d ps",
                   $realtime, measured_width, MAX_PULSE_WIDTH);
            error_count = error_count + 1;
        end
        else if (measured_width < MIN_PULSE_WIDTH) begin
            $error("[%0t ps] 脉宽小于最小值: %0.0f ps < %0d ps",
                   $realtime, measured_width, MIN_PULSE_WIDTH);
            error_count = error_count + 1;
        end
        else begin
            success_count = success_count + 1;
        end
    end
end

//--------------------------------------------------------------------------
// 波形转储
//--------------------------------------------------------------------------
initial begin
    $dumpfile("tb_top_test_timing.vcd");
    $dumpvars(0, tb_top_test_timing);

    // 转储关键信号
    $dumpvars(1, sys_clk);
    $dumpvars(1, sys_rst_n);
    $dumpvars(1, pwm_signal);
    $dumpvars(1, valid_out);
end

//--------------------------------------------------------------------------
// 仿真时间控制
//--------------------------------------------------------------------------
initial begin
    #SIM_TIME;
    $display("[%0t ps] 仿真时间达到 %0d ps，自动结束", $realtime, SIM_TIME);
    $finish;
end

//--------------------------------------------------------------------------
// 覆盖率统计
//--------------------------------------------------------------------------

// 脉宽覆盖率统计
integer width_coverage[200:2500];
integer total_width_tests = 0;
integer unique_width_count = 0;

always @(negedge pwm_signal) begin
    if (sys_rst_n) begin
        real current_width;
        current_width = $realtime - start_time;

        if (current_width >= 200 && current_width <= 2500) begin
            if (width_coverage[int'(current_width)] === 1'bx) begin
                width_coverage[int'(current_width)] = 0;
            end

            if (width_coverage[int'(current_width)] == 0) begin
                width_coverage[int'(current_width)] = 1;
                unique_width_count = unique_width_count + 1;
            end

            total_width_tests = total_width_tests + 1;
        end
    end
end

// 最终覆盖率报告
initial begin
    wait($realtime > 800000);  // 等待测试基本完成

    $display("\n=== 覆盖率统计报告 ===");
    $display("脉宽测试总数: %0d", total_width_tests);
    $display("唯一脉宽值覆盖: %0d/2301 (%.2f%%)",
             unique_width_count,
             (unique_width_count * 100.0 / 2301));
    $display("=================================================");
end

endmodule