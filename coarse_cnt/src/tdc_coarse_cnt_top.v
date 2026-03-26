// ===========================================================================
// TDC粗计数顶层模块 - 时间戳计数法PWM脉宽测量系统
// 功能: 集成粗时间戳生成器，提供完整的脉宽测量解决方案
// 设计目标: 50MHz输出时钟域同步，支持0-50ns脉宽测量
// ===========================================================================

module tdc_coarse_cnt_top (
    input wire clk_50m,             // 50MHz系统时钟
    input wire clk_400m,            // 400MHz采样时钟
    input wire rst_n,               // 异步复位信号(低电平有效)
    input wire pwm_in,              // PWM信号输入
    output wire [37:0] time_interval, // 时间间隔输出(皮秒)
    output wire valid,              // 测量有效信号
    output wire measurement_error   // 测量错误指示
);

    // =========================================================================
    // 参数定义
    // =========================================================================

    // 时钟周期参数
    parameter CLK_400M_PERIOD_PS = 2500;  // 400MHz时钟周期(皮秒)
    parameter CLK_50M_PERIOD_PS = 20000;   // 50MHz时钟周期(皮秒)

    // 时间戳位宽
    parameter TIMESTAMP_WIDTH = 32;

    // =========================================================================
    // 内部信号定义
    // =========================================================================

    // 粗时间戳接口
    wire [TIMESTAMP_WIDTH-1:0] start_coarse_ts;
    wire [TIMESTAMP_WIDTH-1:0] stop_coarse_ts;
    wire timestamp_valid_400m;
    wire timestamp_error_400m;

    // 数据同步接口
    wire [TIMESTAMP_WIDTH-1:0] start_ts_sync;
    wire [TIMESTAMP_WIDTH-1:0] stop_ts_sync;
    wire valid_sync;
    wire error_sync;

    // 脉宽计算结果
    wire [37:0] pulse_width_ps;
    wire calc_valid;
    wire calc_error;

    // =========================================================================
    // 模块实例化
    // =========================================================================

    // 1. 粗时间戳生成器 (400MHz域)
    coarse_timestamp_generator u_coarse_ts_gen (
        .clk_400m(clk_400m),
        .rst_n(rst_n),
        .pwm_in(pwm_in),
        .start_coarse_ts(start_coarse_ts),
        .stop_coarse_ts(stop_coarse_ts),
        .timestamp_valid(timestamp_valid_400m),
        .measurement_error(timestamp_error_400m)
    );

    // 2. 跨时钟域同步器 (400MHz -> 50MHz)
    timestamp_cdc_sync u_cdc_sync (
        .clk_400m(clk_400m),
        .clk_50m(clk_50m),
        .rst_n(rst_n),
        .start_ts_in(start_coarse_ts),
        .stop_ts_in(stop_coarse_ts),
        .valid_in(timestamp_valid_400m),
        .error_in(timestamp_error_400m),
        .start_ts_out(start_ts_sync),
        .stop_ts_out(stop_ts_sync),
        .valid_out(valid_sync),
        .error_out(error_sync)
    );

    // 3. 脉宽计算模块 (50MHz域)
    pulse_width_calculator u_pulse_calc (
        .clk_50m(clk_50m),
        .rst_n(rst_n),
        .start_timestamp(start_ts_sync),
        .stop_timestamp(stop_ts_sync),
        .timestamp_valid(valid_sync),
        .timestamp_error(error_sync),
        .pulse_width_ps(pulse_width_ps),
        .calc_valid(calc_valid),
        .calc_error(calc_error)
    );

    // =========================================================================
    // 输出寄存器
    // =========================================================================

    reg [37:0] time_interval_reg;
    reg valid_reg;
    reg error_reg;

    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            time_interval_reg <= 38'd0;
            valid_reg <= 1'b0;
            error_reg <= 1'b0;
        end else begin
            time_interval_reg <= pulse_width_ps;
            valid_reg <= calc_valid;
            error_reg <= calc_error;
        end
    end

    // =========================================================================
    // 输出赋值
    // =========================================================================

    assign time_interval = time_interval_reg;
    assign valid = valid_reg;
    assign measurement_error = error_reg;

    // =========================================================================
    // 测量原理说明
    // =========================================================================
    //
    // 1. 时间戳记录:
    //    - 在400MHz时钟域维护全局自由运行计数器
    //    - 捕获PWM上升沿时间戳 T_rise
    //    - 捕获PWM下降沿时间戳 T_fall
    //
    // 2. 脉宽计算:
    //    - Pulse_Width = T_fall - T_rise
    //    - 实际时间 = Pulse_Width * 2500ps (400MHz周期)
    //    - 支持计数器溢出处理
    //
    // 3. 跨时钟域处理:
    //    - 异步信号同步避免亚稳态
    //    - 数据同步确保50MHz域数据一致性
    //    - 错误信号同步传递异常状态
    //
    // 4. 精度分析:
    //    - 理论分辨率: 2500ps (400MHz时钟周期)
    //    - 实际精度: 2500ps (受限于时钟分辨率)
    //    - 测量范围: 0 - 10.7秒 (32位计数器)
    //

endmodule

// ===========================================================================
// 跨时钟域同步器模块
// ===========================================================================

module timestamp_cdc_sync (
    input wire clk_400m,            // 400MHz源时钟
    input wire clk_50m,             // 50MHz目标时钟
    input wire rst_n,               // 异步复位
    input wire [31:0] start_ts_in,  // 起始时间戳输入
    input wire [31:0] stop_ts_in,   // 结束时间戳输入
    input wire valid_in,            // 有效信号输入
    input wire error_in,            // 错误信号输入
    output reg [31:0] start_ts_out, // 同步后起始时间戳
    output reg [31:0] stop_ts_out,  // 同步后结束时间戳
    output reg valid_out,           // 同步后有效信号
    output reg error_out            // 同步后错误信号
);

    // 握手信号
    reg req_400m;
    reg ack_50m;
    reg req_sync1, req_sync2;
    reg ack_sync1, ack_sync2;

    // 数据锁存
    reg [31:0] start_ts_latch;
    reg [31:0] stop_ts_latch;
    reg error_latch;

    // 400MHz域：请求生成
    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            req_400m <= 1'b0;
            start_ts_latch <= 32'd0;
            stop_ts_latch <= 32'd0;
            error_latch <= 1'b0;
        end else begin
            if (valid_in && !req_400m) begin
                // 锁存数据并发出请求
                start_ts_latch <= start_ts_in;
                stop_ts_latch <= stop_ts_in;
                error_latch <= error_in;
                req_400m <= 1'b1;
            end else if (ack_sync2) begin
                // 收到确认，清除请求
                req_400m <= 1'b0;
            end
        end
    end

    // 50MHz域：请求同步和响应
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            req_sync1 <= 1'b0;
            req_sync2 <= 1'b0;
            ack_50m <= 1'b0;
            start_ts_out <= 32'd0;
            stop_ts_out <= 32'd0;
            valid_out <= 1'b0;
            error_out <= 1'b0;
        end else begin
            // 同步请求信号
            req_sync1 <= req_400m;
            req_sync2 <= req_sync1;

            if (req_sync2 && !ack_50m) begin
                // 收到请求，输出数据并确认
                start_ts_out <= start_ts_latch;
                stop_ts_out <= stop_ts_latch;
                error_out <= error_latch;
                valid_out <= 1'b1;
                ack_50m <= 1'b1;
            end else if (!req_sync2) begin
                // 请求结束，清除确认和有效信号
                ack_50m <= 1'b0;
                valid_out <= 1'b0;
            end
        end
    end

    // 400MHz域：确认同步
    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            ack_sync1 <= 1'b0;
            ack_sync2 <= 1'b0;
        end else begin
            ack_sync1 <= ack_50m;
            ack_sync2 <= ack_sync1;
        end
    end

endmodule

// ===========================================================================
// 脉宽计算模块
// ===========================================================================

module pulse_width_calculator (
    input wire clk_50m,             // 50MHz时钟
    input wire rst_n,               // 异步复位
    input wire [31:0] start_timestamp, // 起始时间戳
    input wire [31:0] stop_timestamp,  // 结束时间戳
    input wire timestamp_valid,      // 时间戳有效
    input wire timestamp_error,      // 时间戳错误
    output reg [37:0] pulse_width_ps,  // 脉宽(皮秒)
    output reg calc_valid,           // 计算有效
    output reg calc_error            // 计算错误
);

    // 时钟周期参数
    parameter CLK_400M_PERIOD_PS = 2500;

    // 中间计算结果
    reg [31:0] timestamp_diff;
    reg overflow_detected;

    // 脉宽计算主逻辑
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            pulse_width_ps <= 38'd0;
            calc_valid <= 1'b0;
            calc_error <= 1'b0;
            timestamp_diff <= 32'd0;
            overflow_detected <= 1'b0;
        end else begin
            // 默认值
            calc_valid <= 1'b0;
            calc_error <= timestamp_error;

            if (timestamp_valid) begin
                // 检测计数器溢出
                overflow_detected <= (stop_timestamp < start_timestamp);

                if (stop_timestamp >= start_timestamp) begin
                    // 正常情况：无溢出
                    timestamp_diff <= stop_timestamp - start_timestamp;
                end else begin
                    // 溢出情况：计数器已回绕
                    timestamp_diff <= (32'hFFFFFFFF - start_timestamp) + stop_timestamp + 1;
                end

                // 计算实际时间 (时间戳差值 * 时钟周期)
                pulse_width_ps <= {6'd0, timestamp_diff} * CLK_400M_PERIOD_PS;
                calc_valid <= 1'b1;

                // 错误检测：脉宽超出预期范围
                if (timestamp_diff > 32'd20000000) begin // 50ms上限
                    calc_error <= 1'b1;
                end
            end
        end
    end

endmodule

// ===========================================================================
// 设计特点:
//
// 1. 完整的时间戳计数法实现:
//    - 全局自由运行计数器
//    - 精确的边沿时间戳记录
//    - 自动溢出处理
//
// 2. 安全的跨时钟域处理:
//    - 异步信号同步
//    - 握手协议数据传递
//    - 亚稳态防护
//
// 3. 高精度测量:
//    - 400MHz时钟提供2.5ns分辨率
//    - 32位计数器支持长时间测量
//    - 皮秒级时间输出
//
// 4. 可靠性和错误检测:
//    - 多重错误检测机制
//    - 异常状态指示
//    - 数据完整性验证
//
// 5. 易于集成:
//    - 标准化接口
//    - 参数化设计
//    - 模块化结构
// ===========================================================================