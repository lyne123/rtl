// ===========================================================================
// 简化的TDC测试平台（用于功能验证）
// 使用简化的时钟和延迟链模块
// ===========================================================================

`timescale 1ns / 1ps

module tb_simple;

    // 时钟参数
    parameter CLK_50M_PERIOD = 20;    // 50MHz时钟周期(ns)

    // 信号定义
    reg clk_50m;
    reg rst_n;
    reg pwm_in;
    wire [37:0] time_interval;
    wire valid;
    wire measurement_error;

    // 使用简化的顶层模块
    tdc_top_simple uut (
        .clk_50m(clk_50m),
        .rst_n(rst_n),
        .pwm_in(pwm_in),
        .time_interval(time_interval),
        .valid(valid),
        .measurement_error(measurement_error)
    );

    // 50MHz时钟生成
    initial begin
        clk_50m = 1'b0;
        forever #(CLK_50M_PERIOD/2) clk_50m = ~clk_50m;
    end

    // 测试流程
    initial begin
        // 初始化
        rst_n = 1'b0;
        pwm_in = 1'b0;

        $display("==========================================");
        $display("简化TDC功能测试开始");
        $display("==========================================");

        // 复位
        #100;
        rst_n = 1'b1;
        $display("[T=%0t] 复位结束", $time);

        // 等待系统稳定
        #200;

        // 测试1: 10ns脉冲
        $display("[T=%0t] 测试1: 10ns脉冲", $time);
        pwm_in = 1'b1;
        #10;
        pwm_in = 1'b0;

        // 等待测量完成
        @(posedge valid);
        $display("[T=%0t] 测量结果: %0d", $time, time_interval);

        #100;

        // 测试2: 100ns脉冲
        $display("[T=%0t] 测试2: 100ns脉冲", $time);
        pwm_in = 1'b1;
        #100;
        pwm_in = 1'b0;

        @(posedge valid);
        $display("[T=%0t] 测量结果: %0d", $time, time_interval);

        #100;

        // 测试3: 1000ns脉冲
        $display("[T=%0t] 测试3: 1000ns脉冲", $time);
        pwm_in = 1'b1;
        #1000;
        pwm_in = 1'b0;

        @(posedge valid);
        $display("[T=%0t] 测量结果: %0d", $time, time_interval);

        #200;
        $display("==========================================");
        $display("简化TDC功能测试完成");
        $display("==========================================");
        $finish;
    end

    // 波形生成
    initial begin
        $dumpfile("tb_simple.vcd");
        $dumpvars(0, tb_simple);
    end

endmodule

// ===========================================================================
// 简化的顶层模块
// ===========================================================================

module tdc_top_simple (
    input wire clk_50m,
    input wire rst_n,
    input wire pwm_in,
    output wire [37:0] time_interval,
    output wire valid,
    output wire measurement_error
);

    // 内部信号
    wire clk_400m;
    wire mmcm_locked;
    wire start_edge, stop_edge, start_sync, stop_sync;
    wire [31:0] start_coarse_ts, stop_coarse_ts;
    wire [79:0] thermometer_code_a, thermometer_code_b;
    wire [6:0] fine_count_a, fine_count_b;
    wire tdc_a_zero_flag, tdc_b_zero_flag;
    wire tdc_a_metastable, tdc_b_metastable;
    wire [37:0] timestamp_raw;
    reg [37:0] timestamp_reg;
    reg valid_reg;
    wire prev_clk_ref, next_clk_ref;

    // 简化的MMCM
    mmcm_50m_to_400m u_mmcm (
        .clk_in_50m(clk_50m),
        .rst_n(rst_n),
        .clk_out_400m(clk_400m),
        .locked(mmcm_locked)
    );

    // 边沿检测（简化）
    edge_detector_sync u_edge_sync (
        .clk_400m(clk_400m),
        .rst_n(rst_n && mmcm_locked),
        .pwm_in(pwm_in),
        .start_edge(start_edge),
        .stop_edge(stop_edge),
        .start_sync(start_sync),
        .stop_sync(stop_sync)
    );

    // 粗计数器
    coarse_counter_400m u_coarse_counter (
        .clk_400m(clk_400m),
        .rst_n(rst_n && mmcm_locked),
        .start_sync(start_sync),
        .stop_sync(stop_sync),
        .start_coarse_ts(start_coarse_ts),
        .stop_coarse_ts(stop_coarse_ts),
        .free_run_count()
    );

    // 时钟参考信号生成
    clock_reference_gen u_clk_ref (
        .clk_400m(clk_400m),
        .rst_n(rst_n && mmcm_locked),
        .start_sync(start_sync),
        .stop_sync(stop_sync),
        .prev_clk_ref(prev_clk_ref),
        .next_clk_ref(next_clk_ref)
    );

    // 简化的TDC-A
    carry4_delay_chain #(
        .CARRY4_COUNT(20),
        .TOTAL_STAGES(80)
    ) u_tdc_a (
        .clk_400m(clk_400m),
        .rst_n(rst_n && mmcm_locked),
        .start_signal(prev_clk_ref),
        .stop_signal(start_sync),
        .thermometer_code(thermometer_code_a),
        .zero_flag(tdc_a_zero_flag),
        .metastable_warning(tdc_a_metastable)
    );

    // 简化的TDC-B
    carry4_delay_chain #(
        .CARRY4_COUNT(20),
        .TOTAL_STAGES(80)
    ) u_tdc_b (
        .clk_400m(clk_400m),
        .rst_n(rst_n && mmcm_locked),
        .start_signal(stop_sync),
        .stop_signal(next_clk_ref),
        .thermometer_code(thermometer_code_b),
        .zero_flag(tdc_b_zero_flag),
        .metastable_warning(tdc_b_metastable)
    );

    // 温度计码解码器
    thermometer_decoder #(
        .INPUT_WIDTH(80),
        .OUTPUT_WIDTH(7)
    ) u_therm_decoder_a (
        .thermometer_in(thermometer_code_a),
        .binary_out(fine_count_a)
    );

    thermometer_decoder #(
        .INPUT_WIDTH(80),
        .OUTPUT_WIDTH(7)
    ) u_therm_decoder_b (
        .thermometer_in(thermometer_code_b),
        .binary_out(fine_count_b)
    );

    // 时间戳合成器
    timestamp_synthesizer_dual #(
        .COARSE_WIDTH(32),
        .FINE_WIDTH(7),
        .COARSE_PERIOD(2.5),
        .FINE_PERIOD(35.0)
    ) u_timestamp_synth (
        .start_coarse_ts(start_coarse_ts),
        .stop_coarse_ts(stop_coarse_ts),
        .fine_a(fine_count_a),
        .fine_b(fine_count_b),
        .timestamp(timestamp_raw)
    );

    // 输出寄存器
    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n || !mmcm_locked) begin
            timestamp_reg <= 38'd0;
            valid_reg <= 1'b0;
        end else begin
            if (stop_sync) begin
                timestamp_reg <= timestamp_raw;
                valid_reg <= 1'b1;
            end else begin
                valid_reg <= 1'b0;
            end
        end
    end

    assign time_interval = timestamp_reg;
    assign valid = valid_reg;
    assign measurement_error = tdc_a_metastable || tdc_b_metastable;

endmodule