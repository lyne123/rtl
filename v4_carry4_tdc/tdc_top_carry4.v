// ===========================================================================
// TDC顶层模块 - 基于CARRY4进位链的高精度时间数字转换器
// 设计目标: 50MHz -> 400MHz, 粗计数+细计数, PWM输入
// 精度: 理论42ps, 实际50-100ps
// ===========================================================================

module tdc_top_carry4 (
    input wire clk_50m,           // 50MHz系统时钟输入
    input wire rst_n,             // 异步复位信号(低电平有效)
    input wire pwm_in,            // PWM信号输入
    output wire [37:0] time_interval, // 时间间隔测量结果[37:0]
    output wire valid             // 数据有效信号
);

    // =========================================================================
    // 参数定义
    // =========================================================================

    // 细计数相关参数
    parameter CARRY4_STAGES = 72;     // CARRY4延迟链级数 (修正: 60->72)
    parameter FINE_WIDTH = 7;         // 细计数输出位宽(72<128=2^7)

    // 粗计数相关参数
    parameter COARSE_WIDTH = 32;      // 粗计数位宽

    // 时间计算参数
    parameter COARSE_PERIOD = 2.5;    // 粗计数周期(ns)
    parameter FINE_PERIOD = 34.7;     // 细计数周期(ns) = 2.5ns/72

    // =========================================================================
    // 内部信号定义
    // =========================================================================

    // 时钟信号
    wire clk_400m;                    // 400MHz时钟(由MMCM生成)
    wire mmcm_locked;                 // MMCM锁定信号

    // PWM处理信号
    wire start_edge;                  // PWM上升沿检测
    wire stop_edge;                   // PWM下降沿检测
    wire start_sync;                  // 同步后的start信号
    wire stop_sync;                   // 同步后的stop信号

    // 粗计数信号 (时间戳模式)
    wire [COARSE_WIDTH-1:0] start_coarse_ts;  // START时刻粗时间戳
    wire [COARSE_WIDTH-1:0] stop_coarse_ts;   // STOP时刻粗时间戳

    // 细计数信号
    wire [CARRY4_STAGES-1:0] thermometer_code; // 温度计码
    wire [FINE_WIDTH-1:0] fine_count;  // 细计数值

    // 时间合成信号
    wire [37:0] timestamp_raw;        // 原始时间戳
    reg [37:0] timestamp_reg;         // 时间戳寄存器
    reg valid_reg;                    // 有效信号寄存器

    // =========================================================================
    // 模块实例化
    // =========================================================================

    // 1. MMCM倍频模块 (50MHz -> 400MHz)
    mmcm_50m_to_400m u_mmcm (
        .clk_in_50m(clk_50m),
        .rst_n(rst_n),
        .clk_out_400m(clk_400m),
        .locked(mmcm_locked)
    );

    // 2. PWM边沿检测与同步模块
    edge_detector_sync u_edge_sync (
        .clk_400m(clk_400m),
        .rst_n(rst_n && mmcm_locked),
        .pwm_in(pwm_in),
        .start_edge(start_edge),
        .stop_edge(stop_edge),
        .start_sync(start_sync),
        .stop_sync(stop_sync)
    );

    // 3. 400MHz粗计数器 (时间戳模式)
    // 记录START和STOP时刻的独立时间戳
    coarse_counter_400m u_coarse_counter (
        .clk_400m(clk_400m),
        .rst_n(rst_n && mmcm_locked),
        .start_sync(start_sync),
        .stop_sync(stop_sync),
        .start_coarse_ts(start_coarse_ts),
        .stop_coarse_ts(stop_coarse_ts),
        .free_run_count()
    );

    // 4. CARRY4延迟链细计数
    carry4_delay_chain #(
        .CHAIN_LENGTH(CARRY4_STAGES)
    ) u_carry4_chain (
        .clk_400m(clk_400m),
        .rst_n(rst_n && mmcm_locked),
        .start_signal(start_sync),
        .stop_signal(stop_sync),
        .thermometer_code(thermometer_code)
    );

    // 5. 温度计码解码器
    thermometer_decoder #(
        .INPUT_WIDTH(CARRY4_STAGES),
        .OUTPUT_WIDTH(FINE_WIDTH)
    ) u_therm_decoder (
        .thermometer_in(thermometer_code),
        .binary_out(fine_count)
    );

    // 6. 时间戳合成器
    timestamp_synthesizer #(
        .COARSE_WIDTH(COARSE_WIDTH),
        .FINE_WIDTH(FINE_WIDTH),
        .COARSE_PERIOD(COARSE_PERIOD),
        .FINE_PERIOD(FINE_PERIOD)
    ) u_timestamp_synth (
        .start_coarse_ts(start_coarse_ts),
        .stop_coarse_ts(stop_coarse_ts),
        .fine_count(fine_count),
        .timestamp(timestamp_raw)
    );

    // =========================================================================
    // 输出寄存器
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n || !mmcm_locked) begin
            timestamp_reg <= 38'd0;
            valid_reg <= 1'b0;
        end else begin
            // 当stop_sync有效时，锁存时间戳
            if (stop_sync) begin
                timestamp_reg <= timestamp_raw;
                valid_reg <= 1'b1;
            end else begin
                valid_reg <= 1'b0;
            end
        end
    end

    // =========================================================================
    // 输出赋值
    // =========================================================================

    assign time_interval = timestamp_reg;
    assign valid = valid_reg;

    // =========================================================================
    // 调试信号 (可选)
    // =========================================================================

    // 用于ILA调试的信号
    `ifdef DEBUG
    // 可以在这里添加调试信号，用于Vivado ILA
    `endif

endmodule

// ===========================================================================
// 设计说明:
//
// 1. 时钟架构: 50MHz -> MMCM -> 400MHz
// 2. 测量原理: PWM上升沿启动，下降沿停止
// 3. 粗计数: 400MHz时钟计数 (2.5ns精度)
// 4. 细计数: 60级CARRY4延迟链 (理论42ps精度)
// 5. 总精度: 理论42ps，实际50-100ps
//
// 时序流程:
// 1. PWM上升沿 -> start_edge -> 启动粗计数器和CARRY4链
// 2. PWM下降沿 -> stop_edge -> 停止粗计数器，采样CARRY4链
// 3. 温度计码解码 -> 细计数值
// 4. 时间合成 -> 最终时间间隔
// ===========================================================================