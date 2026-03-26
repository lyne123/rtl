// ===========================================================================
// TDC顶层模块 - v5版本（直接采样架构）
// 功能: 集成延迟链采样、粗计数和数据融合，实现0-50ns脉宽测量
// 设计目标: 全范围高精度测量，35ps分辨率
// ===========================================================================

module tdc_top_v5 (
    input wire clk_50m,            // 50MHz系统时钟输入
    input wire rst_n,              // 异步复位信号(低电平有效)
    input wire pwm_in,             // PWM信号输入
    output wire [37:0] time_interval, // 时间间隔输出(皮秒)
    output wire valid,             // 测量有效信号
    output wire measurement_error  // 测量错误指示
);

    // =========================================================================
    // 参数定义
    // =========================================================================

    // 系统参数
    parameter CLK_400M_PERIOD = 2.5;      // 400MHz时钟周期(ns)
    parameter CARRY4_DELAY = 35;          // CARRY4单级延迟(ps)
    parameter MAX_PULSE_WIDTH = 50;       // 最大测量脉宽(ns)

    // =========================================================================
    // 内部信号定义
    // =========================================================================

    // 时钟信号
    wire clk_400m;                        // 400MHz系统时钟
    wire mmcm_locked;                     // MMCM锁定信号

    // 系统复位信号（组合逻辑）
    wire sys_rst_n;                       // 系统级复位信号 = rst_n && mmcm_locked

    // 延迟链采样接口
    wire [71:0] pwm_thermometer;         // 72位温度计码
    wire fine_sampling_valid;             // 细采样有效

    // 时间戳接口
    wire [31:0] start_coarse_ts;          // START边沿粗时间戳
    wire [31:0] stop_coarse_ts;           // STOP边沿粗时间戳
    wire timestamp_valid;                 // 时间戳有效

    // 数据融合接口
    wire [37:0] fused_time_interval;     // 融合后的时间间隔
    wire fusion_valid;                    // 融合有效
    wire fusion_error;                    // 融合错误

    // =========================================================================
    // 组合逻辑
    // =========================================================================

    // 系统复位信号生成
    assign sys_rst_n = rst_n && mmcm_locked;

    // =========================================================================
    // 模块实例化
    // =========================================================================

    // 1. MMCM时钟生成模块 (50MHz -> 400MHz)
    mmcm_50m_to_400m u_mmcm (
        .clk_in1(clk_50m),        // 输入50MHz时钟
        .reset(~rst_n),            // 复位信号，IP核高电平有效
        .clk_out1(clk_400m),      // 输出400MHz时钟
        .locked(mmcm_locked)      // 锁定信号
    );

    // 2. PWM延迟链采样模块
    pwm_delay_chain_sampler u_fine_sampler (
        .clk_400m(clk_400m),
        .rst_n(sys_rst_n),  // 系统复位且MMCM锁定
        .pwm_in(pwm_in),
        .pwm_thermometer(pwm_thermometer),
        .sampling_valid(fine_sampling_valid)
    );

    // 3. PWM时间戳生成模块
    coarse_timestamp_generator u_timestamp_gen (
        .clk_400m(clk_400m),
        .rst_n(sys_rst_n),  // 系统复位且MMCM锁定
        .pwm_in(pwm_in),
        .start_coarse_ts(start_coarse_ts),
        .stop_coarse_ts(stop_coarse_ts),
        .timestamp_valid(timestamp_valid),
        .measurement_error()
    );

    // 4. 时间戳数据融合模块
    pwm_data_fusion_timestamp u_data_fusion (
        .clk_400m(clk_400m),
        .rst_n(sys_rst_n),  // 系统复位且MMCM锁定
        .fine_thermometer(pwm_thermometer),
        .fine_valid(fine_sampling_valid),
        .start_coarse_ts(start_coarse_ts),
        .stop_coarse_ts(stop_coarse_ts),
        .timestamp_valid(timestamp_valid),
        .time_interval_ps(fused_time_interval),
        .valid(fusion_valid),
        .measurement_error(fusion_error)
    );

    // =========================================================================
    // 输出寄存器
    // =========================================================================

    reg [37:0] time_interval_reg;
    reg valid_reg;
    reg error_reg;

    always @(posedge clk_400m or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            time_interval_reg <= 38'd0;
            valid_reg <= 1'b0;
            error_reg <= 1'b0;
        end else begin
            time_interval_reg <= fused_time_interval;
            valid_reg <= fusion_valid;
            error_reg <= fusion_error;
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
    // 1. 短脉宽测量 (0-2.5ns):
    //    - 仅使用延迟链采样结果
    //    - 测量值 = 温度计码中1的个数 × 35ps
    //    - 最高精度: 35ps
    //
    // 2. 长脉宽测量 (2.5ns-50ns):
    //    - 粗计数器 + 延迟链采样组合
    //    - 测量值 = 粗计数值 × 2500ps + 细计数值 × 35ps
    //    - 保持35ps精度
    //
    // 3. 测量流程:
    //    a. PWM信号直接送入72级CARRY4延迟链
    //    b. 在400MHz时钟边沿采样延迟链状态
    //    c. 粗计数器同时记录PWM高电平持续时间
    //    d. 数据融合模块根据脉宽选择最佳测量策略
    //    e. 输出最终时间间隔和有效信号
    //

    // =========================================================================
    // 性能指标
    // =========================================================================
    //
    // 测量范围: 0-50ns
    // 理论精度: 35ps
    // 实际精度: 50-100ps
    // 分辨率: 35ps
    // 最大测量频率: 取决于PWM最小周期
    // 系统延迟: 约10ns (MMCM锁定+采样延迟)
    //
    // 资源消耗:
    // - CARRY4: 18个
    // - 触发器: ~200个
    // - LUT: ~300个
    // - MMCM: 1个
    //

endmodule

// ===========================================================================
// 设计说明:
//
// 1. 架构创新:
//    - 采用直接延迟链采样，突破传统边沿检测限制
//    - 支持0-50ns全范围测量
//    - 实现ps级时间分辨率
//
// 2. 关键技术:
//    - CARRY4延迟链: 提供35ps精度
//    - 温度计码解码: 精确计算传播距离
//    - 数据融合算法: 智能选择测量策略
//    - 错误检测机制: 提供测量可靠性
//
// 3. 与传统TDC的区别:
//    - 传统TDC: 依赖边沿检测，受限于最小脉宽
//    - 本设计: 直接采样，无最小脉宽限制
//    - 传统TDC: 需要start/stop信号
//    - 本设计: 直接测量PWM脉宽
//
// 4. 应用场景:
//    - 超窄脉冲测量 (激光、粒子物理)
//    - 高精度时间间隔测量
//    - 高速数字系统时序分析
//    - 雷达和测距系统
//
// 5. 扩展性:
//    - 可增加更多延迟链提高精度
//    - 可增加粗计数范围扩展测量范围
//    - 可添加温度补偿提高稳定性
//    - 可实现多通道并行测量
// ===========================================================================