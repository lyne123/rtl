`timescale 10ps / 1ps  // 10ps时间精度

module tb_10ps_test;

parameter CLK_PERIOD = 5000; // 200MHz = 5000ps
parameter COARSE_WIDTH = 24;
parameter FINE_WIDTH = 8;

// 测试信号
reg clk;
reg rst_n;
reg start;
reg stop;
wire [COARSE_WIDTH+FINE_WIDTH-1:0] time_interval;
wire valid;

// 实例化10ps TDC
vernier_tdc_10ps #(
    .COARSE_WIDTH(COARSE_WIDTH)
) uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .stop(stop),
    .time_interval(time_interval),
    .valid(valid)
);

// 200MHz时钟生成
always #(CLK_PERIOD/2) clk = ~clk;

// 精度测试任务
task test_precision;
    input [31:0] expected_ps;
    real actual_time, error;
    reg [COARSE_WIDTH+FINE_WIDTH-1:0] measured;
begin
    $display("测试 %0d ps 时间间隔:", expected_ps);

    // 生成测试信号
    @(posedge clk);
    start = 1'b1;

    // 精确延迟
    #(expected_ps);

    @(posedge clk);
    stop = 1'b1;

    // 等待结果
    @(posedge valid);
    measured = time_interval;

    // 计算实际时间和误差
    actual_time = calculate_time_ps(measured);
    error = actual_time - expected_ps;

    $display("  预期: %0d ps", expected_ps);
    $display("  测量: %.1f ps", actual_time);
    $display("  误差: %.1f ps", error);

    // 验证10ps精度要求
    if ($abs(error) <= 10.0) begin
        $display("  ✓ 10ps精度测试通过");
    end else begin
        $display("  ✗ 10ps精度测试失败 (误差 %.1f ps)", error);
    end

    start = 1'b0;
    stop = 1'b0;
    #10000; // 等待稳定
end
endtask

// 计算实际时间(皮秒)
function real calculate_time_ps;
    input [COARSE_WIDTH+FINE_WIDTH-1:0] ts;
    real coarse_ps, fine_ps;
begin
    coarse_ps = $itor(ts[COARSE_WIDTH+FINE_WIDTH-1:FINE_WIDTH]) * 5000.0; // 5ns = 5000ps
    fine_ps = $itor(ts[FINE_WIDTH-1:0]) * 10.0; // 10ps分辨率
    calculate_time_ps = coarse_ps + fine_ps;
end
endfunction

// 主测试过程
initial begin
    $display("====================================");
    $display("10ps精度TDC验证测试");
    $display("====================================");

    // 初始化
    clk = 0;
    rst_n = 0;
    start = 0;
    stop = 0;

    // 复位
    #100000 rst_n = 1; // 100ns复位

    $display("\n开始精度测试...");

    // 测试各种时间间隔
    test_precision(10);   // 10ps
    test_precision(50);   // 50ps
    test_precision(100);  // 100ps
    test_precision(500);  // 500ps
    test_precision(1000); // 1ns
    test_precision(5000); // 5ns

    $display("\n边界条件测试...");
    test_boundary_conditions();

    $display("\n长时间稳定性测试...");
    test_stability();

    $display("\n====================================");
    $display("所有测试完成!");
    $display("====================================");
    $finish;
end

// 边界条件测试
task test_boundary_conditions;
    integer i;
    real prev_time, curr_time, diff;
begin
    prev_time = 0;

    for (i = 0; i < 20; i = i + 1) begin
        // 测试随机时间间隔
        test_precision(10 + i * 5); // 10ps到105ps步进

        curr_time = calculate_time_ps(time_interval);
        diff = curr_time - prev_time;

        if (diff >= 0) begin
            $display("  测量值单调增加: OK");
        end else begin
            $display("  测量值异常: 前次 %.1f ps, 本次 %.1f ps", prev_time, curr_time);
        end

        prev_time = curr_time;
    end
end
endtask

// 稳定性测试
task test_stability;
    integer i;
    real time_sum, time_avg, time_var;
    real measurements_0, measurements_1, measurements_2, measurements_3, measurements_4;
    real measurements_5, measurements_6, measurements_7, measurements_8, measurements_9;
begin
    time_sum = 0;

    // 进行10次相同条件测量 (简化版本)
    for (i = 0; i < 10; i = i + 1) begin
        start = 1'b1;
        #200; // 200ps固定延迟
        @(posedge clk);
        stop = 1'b1;

        @(posedge valid);
        case (i)
            0: measurements_0 = calculate_time_ps(time_interval);
            1: measurements_1 = calculate_time_ps(time_interval);
            2: measurements_2 = calculate_time_ps(time_interval);
            3: measurements_3 = calculate_time_ps(time_interval);
            4: measurements_4 = calculate_time_ps(time_interval);
            5: measurements_5 = calculate_time_ps(time_interval);
            6: measurements_6 = calculate_time_ps(time_interval);
            7: measurements_7 = calculate_time_ps(time_interval);
            8: measurements_8 = calculate_time_ps(time_interval);
            9: measurements_9 = calculate_time_ps(time_interval);
        endcase

        case (i)
            0: time_sum = time_sum + measurements_0;
            1: time_sum = time_sum + measurements_1;
            2: time_sum = time_sum + measurements_2;
            3: time_sum = time_sum + measurements_3;
            4: time_sum = time_sum + measurements_4;
            5: time_sum = time_sum + measurements_5;
            6: time_sum = time_sum + measurements_6;
            7: time_sum = time_sum + measurements_7;
            8: time_sum = time_sum + measurements_8;
            9: time_sum = time_sum + measurements_9;
        endcase

        start = 1'b0;
        stop = 1'b0;
        #50000; // 等待
    end

    time_avg = time_sum / 10.0;
    time_var = 0;

    // 计算方差 (简化版本)
    time_var = time_var + (measurements_0 - time_avg) * (measurements_0 - time_avg);
    time_var = time_var + (measurements_1 - time_avg) * (measurements_1 - time_avg);
    time_var = time_var + (measurements_2 - time_avg) * (measurements_2 - time_avg);
    time_var = time_var + (measurements_3 - time_avg) * (measurements_3 - time_avg);
    time_var = time_var + (measurements_4 - time_avg) * (measurements_4 - time_avg);
    time_var = time_var + (measurements_5 - time_avg) * (measurements_5 - time_avg);
    time_var = time_var + (measurements_6 - time_avg) * (measurements_6 - time_avg);
    time_var = time_var + (measurements_7 - time_avg) * (measurements_7 - time_avg);
    time_var = time_var + (measurements_8 - time_avg) * (measurements_8 - time_avg);
    time_var = time_var + (measurements_9 - time_avg) * (measurements_9 - time_avg);

    time_var = $sqrt(time_var / 10.0);

    $display("  平均值: %.2f ps", time_avg);
    $display("  标准差: %.2f ps", time_var);

    if (time_var <= 5.0) begin
        $display("  ✓ 稳定性测试通过 (σ ≤ 5ps)");
    end else begin
        $display("  ✗ 稳定性测试失败 (σ = %.2f ps)", time_var);
    end
end
endtask

// 波形生成
initial begin
    $dumpfile("10ps_tdc_waveform.vcd");
    $dumpvars(0, tb_10ps_test);
end

// 实时监控
always @(posedge valid) begin
    $display("[%t] 测量结果: %h (%.1f ps)",
             $realtime, time_interval, calculate_time_ps(time_interval));
end

endmodule