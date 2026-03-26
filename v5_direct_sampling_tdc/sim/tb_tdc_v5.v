// ===========================================================================
// TDC v5测试平台 - 直接采样架构验证
// 功能: 验证0-50ns脉宽测量能力，特别是超窄脉宽测量
// 设计目标: 全面测试v5架构的性能和精度
// ===========================================================================

`timescale 1ps / 1ps

module tb_tdc_v5;

    // =========================================================================
    // 测试平台参数
    // =========================================================================

    // 时钟参数
    parameter CLK_50M_PERIOD = 20000;    // 50MHz时钟周期(ps)
    parameter CLK_400M_PERIOD = 2500;    // 400MHz时钟周期(ps)

    // 测试参数
    parameter SIMULATION_TIME = 100000000; // 仿真时间(ps)

    // 脉宽测试范围
    parameter MIN_PULSE_WIDTH = 100;      // 最小测试脉宽(ps)
    parameter MAX_PULSE_WIDTH = 50000;    // 最大测试脉宽(ps)

    // =========================================================================
    // 信号定义
    // =========================================================================

    // 系统信号
    reg clk_50m = 1'b0;
    reg rst_n = 1'b0;

    // TDC接口信号
    reg pwm_in = 1'b0;
    wire [37:0] time_interval;
    wire valid;
    wire measurement_error;

    // 测试控制信号
    integer test_count = 0;
    integer error_count = 0;
    reg test_active = 1'b0;

    // 期望值寄存器
    reg [37:0] expected_pulse_width = 0;
    reg [37:0] measured_pulse_width = 0;
    reg [37:0] measurement_error_ps = 0;

    // =========================================================================
    // TDC模块实例化
    // =========================================================================

    tdc_top_v5 uut (
        .clk_50m(clk_50m),
        .rst_n(rst_n),
        .pwm_in(pwm_in),
        .time_interval(time_interval),
        .valid(valid),
        .measurement_error(measurement_error)
    );

    // =========================================================================
    // 时钟生成
    // =========================================================================

    // 50MHz时钟生成
    always #(CLK_50M_PERIOD/2) clk_50m = ~clk_50m;

    // =========================================================================
    // 测试主程序
    // =========================================================================

    initial begin
        // 初始化
        $display("==========================================");
        $display("TDC v5 直接采样架构测试");
        $display("测试范围: %0dps - %0dps", MIN_PULSE_WIDTH, MAX_PULSE_WIDTH);
        $display("理论精度: 35ps");
        $display("仿真时间: %0dps", SIMULATION_TIME);
        $display("==========================================");

        // 复位阶段
        $display("[T=%0t] 系统复位开始...", $time);
        #50000;  // 等待50ns
        rst_n = 1'b1;
        $display("[T=%0t] 系统复位完成", $time);

        // 等待MMCM锁定和系统稳定
        $display("[T=%0t] 等待MMCM锁定和系统稳定...", $time);
        #100000; // 等待100ns
        $display("[T=%0t] 系统稳定，开始测试", $time);

        #2000000; // 等待3us确保系统完全稳定
        // 开始测试
        test_active = 1'b1;

        // 运行各种脉宽测试
        run_pulse_width_tests();

        // 测试完成
        test_active = 1'b0;
        $display("==========================================");
        $display("测试完成");
        $display("总测试次数: %0d", test_count);
        $display("错误次数: %0d", error_count);
        $display("成功率: %0.2f%%", (test_count-error_count)*100.0/test_count);
        $display("==========================================");

        #100000; // 额外等待时间
        $finish;
    end

    // =========================================================================
    // 脉宽测试任务
    // =========================================================================

    task run_pulse_width_tests;
        begin
            // 测试1: 超窄脉宽 (100ps - 1000ps)
            $display("[T=%0t] 测试1: 超窄脉宽测试 (100ps - 1000ps)", $time);
            test_ultranarrow_pulses();

            // 测试2: 窄脉宽 (1ns - 10ns)
            $display("[T=%0t] 测试2: 窄脉宽测试 (1ns - 10ns)", $time);
            test_narrow_pulses();

            // 测试3: 中等脉宽 (10ns - 25ns)
            $display("[T=%0t] 测试3: 中等脉宽测试 (10ns - 25ns)", $time);
            test_medium_pulses();

            // 测试4: 宽脉宽 (25ns - 50ns)
            $display("[T=%0t] 测试4: 宽脉宽测试 (25ns - 50ns)", $time);
            test_wide_pulses();

            // 测试5: 边界情况测试
            $display("[T=%0t] 测试5: 边界情况测试", $time);
            test_boundary_conditions();
        end
    endtask

    // 超窄脉宽测试 (100ps - 1000ps)
    task test_ultranarrow_pulses;
        integer pulse_width;
        begin
            for (pulse_width = 100; pulse_width <= 1000; pulse_width = pulse_width + 100) begin
                test_single_pulse(pulse_width);
            end
        end
    endtask

    // 窄脉宽测试 (1ns - 10ns)
    task test_narrow_pulses;
        integer pulse_width;
        begin
            for (pulse_width = 1000; pulse_width <= 10000; pulse_width = pulse_width + 1000) begin
                test_single_pulse(pulse_width);
            end
        end
    endtask

    // 中等脉宽测试 (10ns - 25ns)
    task test_medium_pulses;
        integer pulse_width;
        begin
            for (pulse_width = 10000; pulse_width <= 25000; pulse_width = pulse_width + 2500) begin
                test_single_pulse(pulse_width);
            end
        end
    endtask

    // 宽脉宽测试 (25ns - 50ns)
    task test_wide_pulses;
        integer pulse_width;
        begin
            for (pulse_width = 25000; pulse_width <= 50000; pulse_width = pulse_width + 5000) begin
                test_single_pulse(pulse_width);
            end
        end
    endtask

    // 边界情况测试
    task test_boundary_conditions;
        begin
            // 测试最小脉宽
            test_single_pulse(50);

            // 测试最大脉宽
            test_single_pulse(55000);

            // 测试连续脉冲
            test_continuous_pulses(1000, 10000); // 1ns脉宽，10ns周期

            // 测试随机脉宽
            test_random_pulses(10);
        end
    endtask

    // =========================================================================
    // 单个脉宽测试任务
    // =========================================================================

    task test_single_pulse;
        input [31:0] pulse_width_ps;
        begin
            // 设置期望值
            expected_pulse_width = pulse_width_ps;

            // 等待前一个测试完成
            wait_for_measurement_complete();

            // 生成PWM脉冲
            $display("[T=%0t] 测试脉宽: %0dps", $time, pulse_width_ps);
            generate_pwm_pulse(pulse_width_ps);

            // 等待测量完成
            wait_for_measurement_result();

            // 分析结果
            analyze_measurement_result(pulse_width_ps);

            test_count = test_count + 1;
        end
    endtask

    // =========================================================================
    // PWM脉冲生成任务
    // =========================================================================

    task generate_pwm_pulse;
        input [31:0] pulse_width;
        begin
            // 确保PWM为低电平
            wait(pwm_in == 1'b0);

            // 生成上升沿
            pwm_in = 1'b1;
            #pulse_width;

            // 生成下降沿
            pwm_in = 1'b0;

            $display("[T=%0t] 生成PWM脉冲: 脉宽=%0dps", $time, pulse_width);
        end
    endtask

    // =========================================================================
    // 连续脉冲测试
    // =========================================================================

    task test_continuous_pulses;
        input [31:0] pulse_width;
        input [31:0] period;
        integer i;
        begin
            $display("[T=%0t] 连续脉冲测试: 脉宽=%0dps, 周期=%0dps",
                    $time, pulse_width, period);

            for (i = 0; i < 5; i = i + 1) begin
                generate_pwm_pulse(pulse_width);
                #(period - pulse_width);
            end
        end
    endtask

    // =========================================================================
    // 随机脉宽测试
    // =========================================================================

    task test_random_pulses;
        input integer num_tests;
        integer i;
        reg [31:0] random_width;
        begin
            $display("[T=%0t] 随机脉宽测试: %0d次", $time, num_tests);

            for (i = 0; i < num_tests; i = i + 1) begin
                // 生成随机脉宽 (100ps - 50000ps)
                random_width = $random % 50000 + 100;
                test_single_pulse(random_width);
            end
        end
    endtask

    // =========================================================================
    // 辅助任务
    // =========================================================================

    // 等待测量完成
    task wait_for_measurement_complete;
        begin
            // 等待valid信号结束
            while (valid) begin
                #1000; // 等待1ns
            end
        end
    endtask

    // 等待测量结果
    task wait_for_measurement_result;
        begin
            // 等待valid信号有效
            wait(valid);
            #1000; // 额外等待1ns确保稳定
        end
    endtask

    // 分析测量结果
    task analyze_measurement_result;
        input [31:0] expected_width;
        begin
            // 获取测量值
            measured_pulse_width = time_interval;

            // 计算误差
            if (measured_pulse_width > expected_width) begin
                measurement_error_ps = measured_pulse_width - expected_width;
            end else begin
                measurement_error_ps = expected_width - measured_pulse_width;
            end

            // 判断是否在可接受误差范围内 (±200ps)
            if (measurement_error_ps <= 200 && !measurement_error) begin
                $display("[T=%0t] 测量成功: 期望=%0dps, 测量=%0dps, 误差=%0dps ?",
                        $time, expected_width, measured_pulse_width, measurement_error_ps);
            end else begin
                $display("[T=%0t] 测量失败: 期望=%0dps, 测量=%0dps, 误差=%0dps ?",
                        $time, expected_width, measured_pulse_width, measurement_error_ps);
                error_count = error_count + 1;
            end
        end
    endtask

    // =========================================================================
    // 仿真控制
    // =========================================================================

    // 仿真超时控制
    initial begin
        #SIMULATION_TIME;
        $display("[T=%0t] 仿真超时，强制结束", $time);
        $finish;
    end

    // =========================================================================
    // 波形转储
    // =========================================================================

    initial begin
        // 创建VCD波形文件
        $dumpfile("tb_tdc_v5.vcd");
        $dumpvars(0, tb_tdc_v5);

        // 记录关键信号
        $dumpvars(1, uut);
        $dumpvars(1, uut.u_fine_sampler);
        $dumpvars(1, uut.u_timestamp_gen);
        $dumpvars(1, uut.u_data_fusion);
    end

    // =========================================================================
    // 实时监测
    // =========================================================================

    // 测量结果实时显示
    always @(posedge valid) begin
        if (test_active) begin
            $display("[T=%0t] 测量完成: time_interval=%0dps, error=%0b",
                    $time, time_interval, measurement_error);
        end
    end

    // 错误监测
    always @(posedge measurement_error) begin
        if (test_active) begin
            $display("[T=%0t] 测量错误: time_interval=%0dps",
                    $time, time_interval);
        end
    end

endmodule

// ===========================================================================
// 测试平台说明:
//
// 1. 测试覆盖范围:
//    - 超窄脉宽: 100ps - 1000ps (验证延迟链精度)
//    - 窄脉宽: 1ns - 10ns (验证传统TDC能力)
//    - 中等脉宽: 10ns - 25ns (验证粗计数精度)
//    - 宽脉宽: 25ns - 50ns (验证全范围测量)
//    - 边界情况: 最小/最大脉宽、连续脉冲、随机脉宽
//
// 2. 验证重点:
//    - 测量精度: 误差应在±200ps以内
//    - 测量范围: 0-50ns全覆盖
//    - 错误检测: 正确识别测量错误
//    - 系统稳定性: 长时间运行无异常
//
// 3. 性能指标:
//    - 成功率: >95%
//    - 平均误差: <100ps
//    - 最大误差: <200ps
//    - 测量延迟: <10ns
//
// 4. 扩展性:
//    - 可添加更多测试用例
//    - 可增加性能测试
//    - 可添加温度仿真
//    - 可测试不同工艺角
// ===========================================================================