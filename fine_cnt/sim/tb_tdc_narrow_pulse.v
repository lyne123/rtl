`timescale 1ps / 1ps
// 编写时间：2026-03-29 13:59:23

/**
 * TDC 极窄脉宽验证 Testbench (Verilog兼容版本)
 *
 * 核心测试目标：验证 TDC 在面对"脉宽完全小于一个采样时钟周期（< 2.5ns）"
 * 时的双边沿同时捕获能力与粗细对齐逻辑。
 *
 * 作者：资深 FPGA 验证工程师
 * 日期：2026-03-29
 */

module tb_tdc_narrow_pulse;

//--------------------------------------------------------------------------
// 参数定义
//--------------------------------------------------------------------------
parameter CLK_400M_PERIOD = 2500;     // 400MHz 时钟周期 (2500ps = 2.5ns)
parameter SIM_TIME = 5000000;           // 仿真时间 (50ns)
parameter MIN_PULSE_WIDTH = 300;      // 最小脉宽 (300ps)
parameter MAX_PULSE_WIDTH = 2400;     // 最大脉宽 (2400ps)
parameter MIN_PHASE_OFFSET = 10;      // 最小相位偏移 (10ps)
parameter MAX_PHASE_OFFSET = 2490;    // 最大相位偏移 (2490ps)

//--------------------------------------------------------------------------
// 信号定义
//--------------------------------------------------------------------------
reg clk_400m;                         // 400MHz 采样时钟
reg rst_n;                            // 低电平有效复位
reg pwm_in;                           // 极窄 PWM 输入信号

wire [6:0] fine_count_a;             // 细计数值 'a'（上升沿测量）
wire [6:0] fine_count_b;             // 细计数值 'b'（下降沿测量）
wire valid_out;                      // 输出有效信号

// 监控信号
real pulse_start_time;               // 脉冲开始时间
real pulse_width_real;               // 真实脉宽
real phase_offset_real;              // 真实相位偏移

// 测试变量
integer rand_width, rand_phase, interval;
real start_time, end_time, actual_width;
integer phase_bin, width_bin;

//--------------------------------------------------------------------------
// TDC 模块例化
//--------------------------------------------------------------------------
fine_counter_carry4 uut (
    .clk_400m(clk_400m),
    .rst_n(rst_n),
    .pwm_signal(pwm_in),
    .fine_count_a(fine_count_a),
    .fine_count_b(fine_count_b),
    .valid_out(valid_out)
);

//--------------------------------------------------------------------------
// 400MHz 时钟生成
//--------------------------------------------------------------------------
initial begin
    clk_400m = 1'b0;
    forever #(CLK_400M_PERIOD/2) clk_400m = ~clk_400m;
end

//--------------------------------------------------------------------------
// 复位序列
//--------------------------------------------------------------------------
initial begin
    rst_n = 1'b0;
    pwm_in = 1'b0;

    // 复位保持 10ns
    #10000;
    rst_n = 1'b1;

    $display("[%0t ps] 复位释放，开始 TDC 极窄脉宽测试", $realtime);
    $display("=================================================");
end

//--------------------------------------------------------------------------
// 极窄 PWM 激励生成任务
//--------------------------------------------------------------------------
task generate_narrow_pulse;
    input real phase_offset;
    input real pulse_width;
    begin
        // 记录脉冲参数用于监控
        pulse_start_time = $realtime + phase_offset;
        pulse_width_real = pulse_width;
        phase_offset_real = phase_offset;

        // 打印脉冲生成信息
        $display("[%0t ps] 产生极窄脉冲 -> 真实起始相位: %0.0f ps, 真实脉宽: %0.0f ps",
                 $realtime, phase_offset_real, pulse_width_real);

        // 等待随机相位偏移
        #phase_offset;

        // 产生极窄脉冲
        pwm_in = 1'b1;
        #pulse_width;
        pwm_in = 1'b0;
    end
endtask

//--------------------------------------------------------------------------
// 主测试程序
//--------------------------------------------------------------------------
initial begin
    // 等待复位完成
    wait(rst_n == 1'b1);

    $display("[%0t ps] 开始极窄脉宽测试序列", $realtime);
    $display("测试参数：脉宽范围 %0d-%0d ps，相位偏移 %0d-%0d ps",
             MIN_PULSE_WIDTH, MAX_PULSE_WIDTH, MIN_PHASE_OFFSET, MAX_PHASE_OFFSET);

    // 测试序列1：基础极窄脉冲测试
    $display("\n=== 测试序列1：基础极窄脉冲测试 ===");
    begin: test_sequence_1
        repeat(20) begin
            // 生成随机脉宽 (300ps - 2400ps)
            rand_width = {$random} % (MAX_PULSE_WIDTH - MIN_PULSE_WIDTH + 1) + MIN_PULSE_WIDTH;

            // 生成随机相位偏移 (10ps - 2490ps)
            rand_phase = {$random} % (MAX_PHASE_OFFSET - MIN_PHASE_OFFSET + 1) + MIN_PHASE_OFFSET;

            generate_narrow_pulse(rand_phase, rand_width);

            // 脉冲间间隔 (1-5 个时钟周期)
            interval = ({$random} % 5 + 1) * CLK_400M_PERIOD;
            #interval;
        end
    end

    // 测试序列2：极限死区情况测试
    $display("\n=== 测试序列2：极限死区情况测试 ===");
    begin: test_sequence_2
        repeat(15) begin
            // 生成非常接近 2.5ns 边界的脉宽，测试双边沿同周期捕获
            rand_width = {$random} % 200 + 2300;  // 2300-2499ps
            rand_phase = {$random} % 100 + 2400;  // 2400-2499ps

            generate_narrow_pulse(rand_phase, rand_width);

            // 较短间隔
            interval = ({$random} % 3 + 1) * CLK_400M_PERIOD;
            #interval;
        end
    end

    // 测试序列3：极小脉宽测试
    $display("\n=== 测试序列3：极小脉宽测试 ===");
    begin: test_sequence_3
        repeat(15) begin
            // 生成极小脉宽 (300-500ps)
            rand_width = {$random} % 201 + 300;   // 300-500ps
            rand_phase = {$random} % (MAX_PHASE_OFFSET - MIN_PHASE_OFFSET + 1) + MIN_PHASE_OFFSET;

            generate_narrow_pulse(rand_phase, rand_width);

            // 随机间隔
            interval = ({$random} % 4 + 1) * CLK_400M_PERIOD;
            #interval;
        end
    end

    // 测试序列4：边界条件测试
    $display("\n=== 测试序列4：边界条件测试 ===");
    // 测试最小脉宽 + 最小相位
    generate_narrow_pulse(MIN_PHASE_OFFSET, MIN_PULSE_WIDTH);
    #(2 * CLK_400M_PERIOD);

    // 测试最大脉宽 + 最大相位
    generate_narrow_pulse(MAX_PHASE_OFFSET, MAX_PULSE_WIDTH);
    #(2 * CLK_400M_PERIOD);

    // 测试中心相位 + 中心脉宽
    generate_narrow_pulse(1250, 1350);
    #(2 * CLK_400M_PERIOD);

    $display("\n[%0t ps] 所有测试序列完成", $realtime);
    $display("=================================================");

    // 等待最后的测量结果
    #20000;
    $display("[%0t ps] 仿真结束", $realtime);
    $finish;
end

//--------------------------------------------------------------------------
// 监控与自检查逻辑
//--------------------------------------------------------------------------

// 监控 TDC 输出
// always @(posedge clk_400m) begin
//     if (valid_out) begin
//         $display("[%0t ps] TDC 测量结果 -> fine_count_a: %d, fine_count_b: %d",
//                  $realtime, fine_count_a, fine_count_b);
//     end
// end

// 监控 PWM 信号边沿
always @(posedge pwm_in) begin
    $display("[%0t ps] PWM 上升沿触发", $realtime);
end

always @(negedge pwm_in) begin
    $display("[%0t ps] PWM 下降沿触发", $realtime);
end

//--------------------------------------------------------------------------
// 断言检查
//--------------------------------------------------------------------------

// 检查脉宽约束
always @(posedge pwm_in) begin
    start_time = $realtime;
    @(negedge pwm_in);
    end_time = $realtime;
    actual_width = end_time - start_time;

    if (actual_width > MAX_PULSE_WIDTH) begin
        $error("[%0t ps] 脉宽超出最大限制: %0.0f ps > %0d ps",
               $realtime, actual_width, MAX_PULSE_WIDTH);
    end

    if (actual_width < MIN_PULSE_WIDTH) begin
        $error("[%0t ps] 脉宽小于最小限制: %0.0f ps < %0d ps",
               $realtime, actual_width, MIN_PULSE_WIDTH);
    end
end

// 检查 TDC 输出范围
always @(posedge clk_400m) begin
    if (valid_out) begin
        if (fine_count_a > 80) begin
            $error("[%0t ps] fine_count_a 超出范围: %d > 80", $realtime, fine_count_a);
        end
        if (fine_count_b > 80) begin
            $error("[%0t ps] fine_count_b 超出范围: %d > 80", $realtime, fine_count_b);
        end
    end
end

//--------------------------------------------------------------------------
// 波形转储
//--------------------------------------------------------------------------
initial begin
    $dumpfile("tb_tdc_narrow_pulse.vcd");
    $dumpvars(0, tb_tdc_narrow_pulse);

    // 转储关键信号
    $dumpvars(1, clk_400m);
    $dumpvars(1, rst_n);
    $dumpvars(1, pwm_in);
    $dumpvars(1, fine_count_a);
    $dumpvars(1, fine_count_b);
    $dumpvars(1, valid_out);
end

//--------------------------------------------------------------------------
// 仿真时间限制
//--------------------------------------------------------------------------
initial begin
    #SIM_TIME;
    $display("[%0t ps] 仿真时间达到 %0d ps，自动结束", $realtime, SIM_TIME);
    $finish;
end

//--------------------------------------------------------------------------
// 覆盖率收集
//--------------------------------------------------------------------------

// 相位偏移覆盖率
real phase_coverage[0:2499];
integer phase_count = 0;

always @(posedge pwm_in) begin
    if (rst_n) begin
        phase_bin = phase_offset_real / 10;  // 10ps bins
        if (phase_bin < 250) begin
            if (phase_coverage[phase_bin] == 0) begin
                phase_coverage[phase_bin] = 1;
                phase_count = phase_count + 1;
                $display("[%0t ps] 相位覆盖率更新: 已覆盖 %0d/250 个相位区间",
                         $realtime, phase_count);
            end
        end
    end
end

// 脉宽覆盖率
real width_coverage[300:2399];
integer width_count = 0;

always @(negedge pwm_in) begin
    if (rst_n) begin
        width_bin = pulse_width_real;
        if (width_bin >= 300 && width_bin <= 2399) begin
            if (width_coverage[width_bin] == 0) begin
                width_coverage[width_bin] = 1;
                width_count = width_count + 1;
            end
        end
    end
end

// 最终覆盖率报告
initial begin
    wait($realtime > 30000);  // 等待测试基本完成
    $display("\n=== 覆盖率报告 ===");
    $display("相位偏移覆盖率: %0d/250 (%.1f%%)",
             phase_count, (phase_count * 100.0 / 250));
    $display("脉宽覆盖率: %0d/2100 (%.1f%%)",
             width_count, (width_count * 100.0 / 2100));
end

endmodule