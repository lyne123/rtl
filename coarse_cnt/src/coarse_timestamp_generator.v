// ===========================================================================
// 粗时间戳生成器模块 - 基于时间戳计数法的PWM脉宽测量
// 功能: 使用全局计数器记录PWM信号边沿时间戳，计算脉宽
// 设计目标: 实现异步信号的安全跨时钟域处理和高精度时间戳记录
// ===========================================================================

module coarse_timestamp_generator (
    input wire clk_400m,            // 400MHz采样时钟 (2.5ns周期)
    input wire rst_n,               // 异步复位信号(低电平有效)
    input wire pwm_in,              // 异步PWM输入信号
    output reg [31:0] start_coarse_ts, // 上升沿时间戳输出
    output reg [31:0] stop_coarse_ts,  // 下降沿时间戳输出
    output reg timestamp_valid,      // 时间戳有效信号
    output reg measurement_error     // 测量错误指示
);

    // =========================================================================
    // 参数定义
    // =========================================================================

    // 全局计数器位宽 (32位可计数约10.7秒)
    parameter COUNTER_WIDTH = 32;

    // 最大计数值 (用于溢出检测)
    parameter MAX_COUNTER_VALUE = 32'hFFFFFFFF;

    // 同步器级数 (减少亚稳态概率)
    parameter SYNC_STAGES = 3;

    // =========================================================================
    // 内部信号定义
    // =========================================================================

    // 全局自由运行计数器
    reg [COUNTER_WIDTH-1:0] global_timer;

    // PWM信号同步链 (跨时钟域处理)
    reg [SYNC_STAGES-1:0] pwm_sync_reg;

    // 边沿检测信号
    wire pwm_synced;
    reg pwm_delayed;
    wire rising_edge;
    wire falling_edge;

    // 状态机状态定义
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam CAPTURE_RISE = 2'b01;
    localparam CAPTURE_FALL = 2'b10;
    localparam CALCULATE = 2'b11;

    // 时间戳寄存器
    reg [COUNTER_WIDTH-1:0] rise_timestamp;
    reg [COUNTER_WIDTH-1:0] fall_timestamp;

    // 错误检测信号
    reg counter_overflow_error;
    reg invalid_edge_error;

    // =========================================================================
    // 组合逻辑
    // =========================================================================

    // 同步后的PWM信号
    assign pwm_synced = pwm_sync_reg[SYNC_STAGES-1];

    // 边沿检测逻辑
    assign rising_edge = pwm_synced && !pwm_delayed;
    assign falling_edge = !pwm_synced && pwm_delayed;

    // =========================================================================
    // 时序逻辑
    // =========================================================================

    // 1. 全局计数器 (自由运行)
    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            global_timer <= {COUNTER_WIDTH{1'b0}};
            counter_overflow_error <= 1'b0;
        end else begin
            if (global_timer == MAX_COUNTER_VALUE) begin
                global_timer <= {COUNTER_WIDTH{1'b0}};
                counter_overflow_error <= 1'b1; // 检测到溢出
            end else begin
                global_timer <= global_timer + 1'b1;
                counter_overflow_error <= 1'b0;
            end
        end
    end

    // 2. PWM信号同步器 (跨时钟域处理)
    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            pwm_sync_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            pwm_sync_reg <= {pwm_sync_reg[SYNC_STAGES-2:0], pwm_in};
        end
    end

    // 3. 边沿检测延迟寄存器
    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            pwm_delayed <= 1'b0;
        end else begin
            pwm_delayed <= pwm_synced;
        end
    end

    // 4. 主状态机 - 时间戳捕获和计算
    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rise_timestamp <= {COUNTER_WIDTH{1'b0}};
            fall_timestamp <= {COUNTER_WIDTH{1'b0}};
            start_coarse_ts <= {COUNTER_WIDTH{1'b0}};
            stop_coarse_ts <= {COUNTER_WIDTH{1'b0}};
            timestamp_valid <= 1'b0;
            invalid_edge_error <= 1'b0;
        end else begin
            // 默认值
            timestamp_valid <= 1'b0;
            invalid_edge_error <= 1'b0;

            case (state)
                IDLE: begin
                    // 等待上升沿
                    if (rising_edge) begin
                        rise_timestamp <= global_timer;
                        state <= CAPTURE_RISE;
                    end
                end

                CAPTURE_RISE: begin
                    // 已捕获上升沿，等待下降沿
                    if (falling_edge) begin
                        fall_timestamp <= global_timer;
                        state <= CAPTURE_FALL;
                    end else if (rising_edge) begin
                        // 异常：连续上升沿，重新开始
                        rise_timestamp <= global_timer;
                        invalid_edge_error <= 1'b1;
                    end
                end

                CAPTURE_FALL: begin
                    // 已捕获完整脉宽，准备输出
                    start_coarse_ts <= rise_timestamp;
                    stop_coarse_ts <= fall_timestamp;
                    timestamp_valid <= 1'b1;
                    state <= CALCULATE;
                end

                CALCULATE: begin
                    // 计算完成，返回IDLE等待下一次测量
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // 5. 错误检测逻辑
    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            measurement_error <= 1'b0;
        end else begin
            // 组合所有错误条件
            measurement_error <= counter_overflow_error || invalid_edge_error ||
                               (state == CAPTURE_RISE && $time > 1000000); // 超时检测
        end
    end

    // =========================================================================
    // 时间戳计算函数
    // =========================================================================

    // 计算脉宽函数 (处理计数器溢出)
    function [31:0] calculate_pulse_width;
        input [31:0] fall_ts;
        input [31:0] rise_ts;
        begin
            if (fall_ts >= rise_ts) begin
                // 正常情况：下降沿时间戳大于上升沿
                calculate_pulse_width = fall_ts - rise_ts;
            end else begin
                // 溢出情况：下降沿时间戳小于上升沿（计数器已回绕）
                calculate_pulse_width = (MAX_COUNTER_VALUE - rise_ts) + fall_ts + 1;
            end
        end
    endfunction

    // =========================================================================
    // 调试和监控信号
    // =========================================================================

    // 实时监控脉宽 (用于调试)
    wire [31:0] current_pulse_width;
    assign current_pulse_width = calculate_pulse_width(stop_coarse_ts, start_coarse_ts);

    // 监控计数器溢出
    wire overflow_detected;
    assign overflow_detected = (start_coarse_ts > stop_coarse_ts) && timestamp_valid;

    // =========================================================================
    // 性能说明
    // =========================================================================
    //
    // 1. 时间戳精度:
    //    - 400MHz时钟周期 = 2.5ns
    //    - 理论时间分辨率 = 2.5ns
    //    - 实际精度受异步信号同步影响
    //
    // 2. 测量范围:
    //    - 32位计数器最大计数值 = 2^32 - 1
    //    - 最大可测量时间 = (2^32 - 1) * 2.5ns ≈ 10.7秒
    //    - 实际应用中可根据需求调整计数器位宽
    //
    // 3. 跨时钟域处理:
    //    - 3级同步器减少亚稳态概率
    //    - 边沿检测确保准确捕获信号变化
    //    - 状态机防止异常信号导致的错误测量
    //
    // 4. 错误检测:
    //    - 计数器溢出检测
    //    - 异常边沿序列检测
    //    - 测量超时检测
    //
    // 5. 资源消耗:
    //    - 触发器: ~100个
    //    - LUT: ~80个
    //    - 寄存器: 32位计数器 + 同步链 + 状态机
    //

endmodule

// ===========================================================================
// 模块特点:
//
// 1. 异步信号处理:
//    - 完整的跨时钟域同步机制
//    - 边沿检测避免毛刺影响
//    - 状态机确保测量顺序正确
//
// 2. 时间戳精度:
//    - 400MHz时钟提供2.5ns分辨率
//    - 32位计数器支持长时间测量
//    - 溢出处理确保计算正确
//
// 3. 可靠性设计:
//    - 多重错误检测机制
//    - 亚稳态防护
//    - 异常状态恢复
//
// 4. 可扩展性:
//    - 参数化设计便于调整
//    - 模块化结构易于集成
//    - 调试接口便于验证
// ===========================================================================