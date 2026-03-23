`timescale 1ns / 1ps

module tb_tdc_top;

// 参数定义
parameter CLK_PERIOD = 10;  // 100MHz时钟，10ns周期
parameter COARSE_WIDTH = 24;
parameter FINE_WIDTH = 8;

// 测试信号
reg clk;
reg rst_n;
reg pwm;
wire [COARSE_WIDTH+FINE_WIDTH-1:0] timestamp;
wire valid;

// 预期精度和量程计算
real expected_resolution = 25e-3; // 25ps理论分辨率
real expected_range = (2**COARSE_WIDTH) * CLK_PERIOD / 1000; // ms量程

// 实例化被测模块
tdc_top #(
    .COARSE_WIDTH(COARSE_WIDTH),
    .FINE_WIDTH(FINE_WIDTH)
) uut (
    .clk(clk),
    .rst_n(rst_n),
    .pwm(pwm),
    .timestamp(timestamp),
    .valid(valid)
);

// 时钟生成
always #(CLK_PERIOD/2) clk = ~clk;

// 测试过程
initial begin
    $display("========================================");
    $display("TDC性能测试报告");
    $display("========================================");
    $display("理论指标:");
    $display("- 分辨率: %.2f ps", expected_resolution * 1000);
    $display("- 最大量程: %.2f ms", expected_range);
    $display("- 时钟频率: %.0f MHz", 1000.0/CLK_PERIOD);
    $display("========================================");

    // 初始化
    clk = 0;
    rst_n = 0;
    pwm = 0;

    // 复位
    #100 rst_n = 1;

    // 测试用例1: 1ns时间差
    test_time_diff(1.0);

    // 测试用例2: 5ns时间差
    test_time_diff(5.0);

    // 测试用例3: 边界测试
    test_boundary_conditions();

    // 测试用例4: 长时间稳定性测试
    test_long_term_stability();

    $display("========================================");
    $display("所有测试完成!");
    $display("========================================");
    $finish;
end

// 测试特定时间差的task
task test_time_diff;
    input real time_diff_ns;
    real start_time, end_time;
    reg [COARSE_WIDTH+FINE_WIDTH-1:0] captured_timestamp;
    real measured_diff;
    real error_ps;

begin
    $display("\n测试 %.1f ns时间差:", time_diff_ns);

    // 记录开始时间
    start_time = $realtime;

    // 生成PWM信号
    @(posedge clk);
    pwm = 1;

    // 等待指定时间
    #(time_diff_ns);

    // 在时钟上升沿采样
    @(posedge clk);
    captured_timestamp = timestamp;

    // 计算测量结果
    measured_diff = calculate_actual_time(captured_timestamp);
    error_ps = (measured_diff - time_diff_ns) * 1000;

    // 显示结果
    $display("预期: %.1f ns", time_diff_ns);
    $display("测量: %.3f ns", measured_diff);
    $display("误差: %.1f ps", error_ps);

    // 验证精度要求
    if (error_ps <= 100) begin  // 100ps精度要求
        $display("✓ 精度测试通过");
    end else begin
        $display("✗ 精度测试失败");
    end

    pwm = 0;
    #50; // 等待稳定
end
endtask

// 边界条件测试
task test_boundary_conditions;
    integer i;
    reg [COARSE_WIDTH+FINE_WIDTH-1:0] prev_timestamp;
    reg [COARSE_WIDTH+FINE_WIDTH-1:0] curr_timestamp;

begin
    $display("\n边界条件测试:");

    // 测试连续测量的一致性
    prev_timestamp = 0;

    for (i = 0; i < 10; i = i + 1) begin
        @(posedge clk);
        pwm = 1;
        #1; // 1ns延迟
        @(posedge clk);

        curr_timestamp = timestamp;

        if (curr_timestamp > prev_timestamp) begin
            $display("✓ 测量 %0d: 时间戳正常增加", i+1);
        end else begin
            $display("✗ 测量 %0d: 时间戳异常", i+1);
        end

        prev_timestamp = curr_timestamp;
        pwm = 0;
        #20;
    end
end
endtask

// 长期稳定性测试
task test_long_term_stability;
    integer i;
    real timestamp_sum;
    real timestamp_avg;

begin
    $display("\n长期稳定性测试:");
    timestamp_sum = 0;

    // 进行100次连续测量
    for (i = 0; i < 100; i = i + 1) begin
        @(posedge clk);
        pwm = 1;
        #2; // 2ns固定延迟
        @(posedge clk);

        if (valid) begin
            timestamp_sum = timestamp_sum + calculate_actual_time(timestamp);
        end

        pwm = 0;
        #10;
    end

    timestamp_avg = timestamp_sum / 100;
    $display("平均测量值: %.3f ns", timestamp_avg);
    $display("✓ 稳定性测试完成");
end
endtask

// 计算实际时间的函数
function real calculate_actual_time;
    input [COARSE_WIDTH+FINE_WIDTH-1:0] ts;
    real coarse_part, fine_part, total_time;
begin
    // 分离粗计数和细计数
    coarse_part = $itor(ts[COARSE_WIDTH+FINE_WIDTH-1:FINE_WIDTH]) * CLK_PERIOD;
    fine_part = $itor(ts[FINE_WIDTH-1:0]) * expected_resolution;
    total_time = coarse_part + fine_part;

    calculate_actual_time = total_time;
end
endfunction

// 波形显示
initial begin
    $dumpfile("tdc_waveform.vcd");
    $dumpvars(0, tb_tdc_top);
end

// 监控输出
always @(posedge valid) begin
    $display("时间: %t, 时间戳: %h, 实际时间: %.3f ns",
             $realtime, timestamp, calculate_actual_time(timestamp));
end

endmodule