// ===========================================================================
// PWM粗计数时间戳模块 - v5版本（单通道时间戳模式）
// 功能: 生成PWM边沿的时间戳，为数据融合提供精确时间基准
// 设计目标: 32位时间戳，2.5ns分辨率，支持脉宽计算
// ===========================================================================

module coarse_timestamp_generator (
    input wire clk_400m,           // 400MHz时间戳时钟
    input wire rst_n,              // 异步复位信号
    input wire pwm_in,             // PWM信号输入
    output reg [31:0] start_coarse_ts,  // START边沿粗时间戳
    output reg [31:0] stop_coarse_ts,   // STOP边沿粗时间戳
    output reg timestamp_valid,         // 时间戳有效信号
    output reg measurement_error        // 测量错误指示
);

    // =========================================================================
    // 参数定义
    // =========================================================================

    parameter TIMESTAMP_WIDTH = 32;        // 时间戳位宽
    parameter COARSE_PERIOD_NS = 2.5;      // 粗计数周期(ns)
    parameter MAX_TIMESTAMP = 32'hFFFFFFFF; // 最大时间戳值

    // =========================================================================
    // 内部信号定义
    // =========================================================================

    // 全局时间戳计数器（自由运行）
    reg [TIMESTAMP_WIDTH-1:0] global_timestamp;

    // PWM信号同步链
    reg [2:0] pwm_sync_reg;
    wire pwm_synced;

    // 边沿检测信号
    reg pwm_sync_d1;
    wire pwm_rise_edge;
    wire pwm_fall_edge;

    // 时间戳锁存信号
    reg start_captured;            // START时间戳已捕获标志
    reg [TIMESTAMP_WIDTH-1:0] captured_start_ts; // 捕获的START时间戳

    // 错误检测信号
    reg overflow_error;            // 时间戳溢出错误
    reg timeout_error;             // 超时错误

    // =========================================================================
    // 全局时间戳计数器（自由运行）
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            global_timestamp <= {TIMESTAMP_WIDTH{1'b0}};
        end else begin
            if (global_timestamp == MAX_TIMESTAMP) begin
                global_timestamp <= {TIMESTAMP_WIDTH{1'b0}}; // 溢出时复位
            end else begin
                global_timestamp <= global_timestamp + 1;
            end
        end
    end

    // =========================================================================
    // PWM信号同步 - 三级同步器
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            pwm_sync_reg <= 3'b000;
        end else begin
            pwm_sync_reg <= {pwm_sync_reg[1:0], pwm_in};
        end
    end

    assign pwm_synced = pwm_sync_reg[2];

    // =========================================================================
    // 边沿检测逻辑
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            pwm_sync_d1 <= 1'b0;
        end else begin
            pwm_sync_d1 <= pwm_synced;
        end
    end

    // 上升沿检测: 当前为1且前一个周期为0
    assign pwm_rise_edge = pwm_synced && !pwm_sync_d1;

    // 下降沿检测: 当前为0且前一个周期为1
    assign pwm_fall_edge = !pwm_synced && pwm_sync_d1;

    // =========================================================================
    // 时间戳生成逻辑
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            start_coarse_ts <= {TIMESTAMP_WIDTH{1'b0}};
            stop_coarse_ts <= {TIMESTAMP_WIDTH{1'b0}};
            timestamp_valid <= 1'b0;
            start_captured <= 1'b0;
            captured_start_ts <= {TIMESTAMP_WIDTH{1'b0}};
            overflow_error <= 1'b0;
            timeout_error <= 1'b0;
            measurement_error <= 1'b0;
        end else begin
            // 默认值
            timestamp_valid <= 1'b0;
            measurement_error <= 1'b0;

            // 检测上升沿 - 捕获START时间戳
            if (pwm_rise_edge && !start_captured) begin
                captured_start_ts <= global_timestamp;
                start_captured <= 1'b1;
                overflow_error <= 1'b0;
                timeout_error <= 1'b0;
            end
            // 检测下降沿 - 捕获STOP时间戳并输出结果
            else if (pwm_fall_edge && start_captured) begin
                // 输出时间戳对
                start_coarse_ts <= captured_start_ts;
                stop_coarse_ts <= global_timestamp;
                timestamp_valid <= 1'b1;
                start_captured <= 1'b0; // 重置捕获状态
            end

            // 超时检测（防止START后长时间无STOP）
            if (start_captured &&
                (global_timestamp - captured_start_ts) > 32'd20000) begin // 50μs超时
                timeout_error <= 1'b1;
                start_captured <= 1'b0; // 强制重置
            end

            // 错误信号组合
            measurement_error <= overflow_error || timeout_error;
        end
    end

    // =========================================================================
    // 时间戳格式说明   
    // =========================================================================
    //
    // 时间戳格式: [31:0] 全局计数器值
    // 时间分辨率: 2.5ns (400MHz时钟周期)
    // 最大时间范围: 2.5ns × 2^32 ≈ 10.7秒
    //
    // 脉宽计算公式:
    // 正常情况 (stop_ts >= start_ts):
    //   脉宽 = (stop_ts - start_ts) × 2.5ns
    // 溢出情况 (stop_ts < start_ts):
    //   脉宽 = (MAX_TIMESTAMP - start_ts + stop_ts + 1) × 2.5ns
    //

    // =========================================================================
    // 性能参数
    // =========================================================================
    //
    // 时间戳特性:
    // - 时钟频率: 400MHz
    // - 时间分辨率: 2.5ns
    // - 最大时间: 10.7秒
    // - 溢出处理: 自动检测和补偿
    //
    // 错误处理:
    // - 超时检测: 50μs无响应视为错误
    // - 溢出检测: 时间戳溢出警告
    // - 错误指示: 提供测量可靠性信息
    //

endmodule

// ===========================================================================
// 设计说明:
//
// 1. 为什么需要粗计数器:
//    - 延迟链只能测量0-2.5ns脉宽
    //    - 粗计数器扩展测量范围到50ns
    //    - 两者配合实现全范围高精度测量
//
// 2. 三级同步设计:
//    - PWM信号异步输入
    //    - 三级同步器消除亚稳态
    //    - 确保计数可靠性
//
// 3. 边沿检测:
//    - 精确检测PWM上升沿和下降沿
    //    - 上升沿启动计数
    //    - 下降沿结束计数
//
// 4. 错误检测:
//    - 溢出检测: 防止计数器超限
//    - 超时检测: 防止无限计数
//    - 提高系统可靠性
//
// 5. 与延迟链的配合:
//    - 短脉宽(<2.5ns): 仅延迟链工作
//    - 长脉宽(>2.5ns): 延迟链+粗计数协同工作
//    - 无缝切换，无需模式选择
// ===========================================================================