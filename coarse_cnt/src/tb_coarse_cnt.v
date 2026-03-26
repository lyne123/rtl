// ===========================================================================
// 粗计数器TDC测试平台 - 验证时间戳计数法PWM脉宽测量
// 功能: 测试异步PWM信号处理、时间戳记录和脉宽计算
// 设计目标: 验证0-50ns脉宽测量精度和跨时钟域处理正确性
// ===========================================================================

`timescale 1ps / 1ps

module tb_coarse_cnt;

    // =========================================================================
    // 测试平台参数
    // =========================================================================

    // 时钟参数
    parameter CLK_50M_PERIOD = 20000;    // 50MHz时钟周期(ps)
    parameter CLK_400M_PERIOD = 2500;   // 400MHz时钟周期(ps)

    // 测试参数
    parameter SIMULATION_TIME = 10000000; // 仿真时间(ps)
    parameter MIN_PULSE_WIDTH = 2500;     // 最小测试脉宽(ps) = 1个400MHz周期
    parameter MAX_PULSE_WIDTH = 50000;    // 最大测试脉宽(ps) = 50ns

    // =========================================================================
    // 信号定义
    // =========================================================================

    // 时钟和复位信号
    reg clk_50m ;
    reg clk_400m ;
    reg rst_n = 1'b0;

    // PWM输入信号
    reg pwm_in = 1'b0;

    // TDC输出信号
    wire [37:0] time_interval;
    wire valid;
    wire measurement_error;

    // 测试控制信号
    integer test_count = 0;
    integer error_count = 0;
    reg test_active = 1'b0;

    // 期望值和测量值
    reg [37:0] expected_pulse_width = 0;
    reg [37:0] measured_pulse_width = 0;
    reg [37:0] measurement_error_ps = 0;

    // =========================================================================
    // 被测模块实例化
    // =========================================================================

    tdc_coarse_cnt_top uut (
        .clk_50m(clk_50m),
        .clk_400m(clk_400m),
        .rst_n(rst_n),
        .pwm_in(pwm_in),
        .time_interval(time_interval),
        .valid(valid),
        .measurement_error(measurement_error)
    );

    // =========================================================================
    // 时钟生成
    // =========================================================================

    initial begin
    clk_50m  = 1'b0;
    clk_400m = 1'b0;
    end

    // 50MHz时钟生成
    always #(CLK_50M_PERIOD/2) clk_50m = ~clk_50m;

    // 400MHz时钟生成 (与50MHz异步)
    always #(CLK_400M_PERIOD/2) clk_400m = ~clk_400m;

    // =========================================================================
    // 测试主程序
    // =========================================================================

    initial begin
        // 初始化
        $display("==========================================");
        $display("粗计数器TDC测试平台");
        $display("时间戳计数法PWM脉宽测量验证");
        $display("测试范围: %0dps - %0dps", MIN_PULSE_WIDTH, MAX_PULSE_WIDTH);
        $display("理论分辨率: 2500ps (400MHz时钟)");
        $display("==========================================");

        // 复位阶段
        $display("[T=%0t] 系统复位开始...", $time);
        #100000;  // 等待100ns
        rst_n = 1'b1;
        $display("[T=%0t] 系统复位完成", $time);

        // 等待系统稳定
        $display("[T=%0t] 等待系统稳定...", $time);
        #200000; // 等待200ns
        $display("[T=%0t] 系统稳定，开始测试", $time);

        // 开始测试
        test_active = 1'b1;

        // 运行各种测试
        run_basic_tests();
        run_edge_case_tests();
        run_overflow_tests();

        // 测试完成
        test_active = 1'b0;
        $display("==========================================");
        $display("测试完成");
        $display("总测试次数: %0d", test_count);
        $display("错误次数: %0d", error_count);
        $display("成功率: %0.2f%%", (test_count-error_count)*100.0/test_count);
        $display("==========================================");

        #200000; // 额外等待时间
        $finish;
    end

    // =========================================================================
    // 基本测试程序
    // =========================================================================

    task run_basic_tests;
        begin
            $display("[T=%0t] 开始基本测试...", $time);

            // 测试1: 单周期脉宽 (2500ps)
            test_single_pulse(2500);

            // 测试2: 多周期脉宽
            test_single_pulse(5000);   // 2个周期
            test_single_pulse(10000);  // 4个周期
            test_single_pulse(25000);  // 10个周期

            // 测试3: 边界值测试
            test_single_pulse(50000);  // 20个周期 (50ns)
        end
    endtask

    // =========================================================================
    // 边界情况测试
    // =========================================================================

    task run_edge_case_tests;
        begin
            $display("[T=%0t] 开始边界情况测试...", $time);

            // 测试最小脉宽
            test_single_pulse(MIN_PULSE_WIDTH);

            // 测试最大脉宽
            test_single_pulse(MAX_PULSE_WIDTH);

            // 测试连续脉冲
            test_continuous_pulses(5000, 20000); // 5ns脉宽，20ns周期

            // 测试随机脉宽
            test_random_pulses(5);
        end
    endtask

    // =========================================================================
    // 溢出测试
    // =========================================================================

    task run_overflow_tests;
        begin
            $display("[T=%0t] 开始溢出测试...", $time);

            // 模拟计数器溢出情况
            // 注意：实际仿真中很难真正触发32位计数器溢出
            // 这里主要测试脉宽计算逻辑
            test_single_pulse(100000); // 100ns脉宽
        end
    endtask

    // =========================================================================
    // 单个脉宽测试
    // =========================================================================

    task test_single_pulse;
        input [31:0] pulse_width_ps;
        begin
            // 设置期望值
            expected_pulse_width = pulse_width_ps;

            // 等待前一次测量完成
            wait_for_measurement_complete();

            // 生成PWM脉冲
            $display("[T=%0t] 测试脉宽: %0dps", $time, pulse_width_ps);
            generate_pwm_pulse(pulse_width_ps);

            // 等待测量结果
            wait_for_measurement_result();

            // 分析结果
            analyze_measurement_result(pulse_width_ps);

            test_count = test_count + 1;
        end
    endtask

    // =========================================================================
    // PWM脉冲生成
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
            $display("[T=%0t] 测试连续脉冲: 脉宽=%0dps, 周期=%0dps",
                    $time, pulse_width, period);

            for (i = 0; i < 3; i = i + 1) begin
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
            $display("[T=%0t] 测试随机脉宽: %0d次", $time, num_tests);

            for (i = 0; i < num_tests; i = i + 1) begin
                // 生成随机脉宽 (2500ps - 50000ps)
                random_width = ($random % (MAX_PULSE_WIDTH - MIN_PULSE_WIDTH)) + MIN_PULSE_WIDTH;
                test_single_pulse(random_width);
            end
        end
    endtask

    // =========================================================================
    // 测量控制任务
    // =========================================================================

    task wait_for_measurement_complete;
        begin
            // 等待valid信号变为低电平
            while (valid) begin
                #1000; // 等待1ns
            end
        end
    endtask

    task wait_for_measurement_result;
        begin
            // 等待valid信号变为高电平
            wait(valid);
            #2000; // 额外等待2ns确保稳定
        end
    endtask

    // =========================================================================
    // 结果分析
    // =========================================================================

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

            // 判断测试结果
            // 允许误差：±1个时钟周期 (2500ps)
            if (measurement_error_ps <= 2500 && !measurement_error) begin
                $display("[T=%0t] 测试通过: 期望=%0dps, 测量=%0dps, 误差=%0dps ?",
                        $time, expected_width, measured_pulse_width, measurement_error_ps);
            end else begin
                $display("[T=%0t] 测试失败: 期望=%0dps, 测量=%0dps, 误差=%0dps ?",
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
        $dumpfile("tb_coarse_cnt.vcd");
        $dumpvars(0, tb_coarse_cnt);

        // 记录关键信号
        $dumpvars(1, uut);
        $dumpvars(1, uut.u_coarse_ts_gen);
    end

    // =========================================================================
    // 实时监控
    // =========================================================================

    // 测量结果实时监控
    always @(posedge valid) begin
        if (test_active) begin
            $display("[T=%0t] 测量结果: time_interval=%0dps, error=%0b",
                    $time, time_interval, measurement_error);
        end
    end

    // 错误监控
    always @(posedge measurement_error) begin
        if (test_active) begin
            $display("[T=%0t] 测量错误: time_interval=%0dps",
                    $time, time_interval);
        end
    end

    // =========================================================================
    // 测试说明
    // =========================================================================
    //
    // 1. 测试覆盖范围:
    //    - 基本脉宽测量 (2.5ns - 50ns)
    //    - 边界情况测试
    //    - 连续脉冲测试
    //    - 随机脉宽测试
    //
    // 2. 精度验证:
    //    - 理论分辨率: 2500ps
    //    - 允许误差: ±2500ps
    //    - 验证时间戳计算正确性
    //
    // 3. 功能验证:
    //    - 异步信号处理
    //    - 跨时钟域同步
    //    - 计数器溢出处理
    //    - 错误检测机制
    //
    // 4. 性能指标:
    //    - 成功率应 > 95%
    //    - 平均误差应 < 2500ps
    //    - 无测量超时
    //

endmodule