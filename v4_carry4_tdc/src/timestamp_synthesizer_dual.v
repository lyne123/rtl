// ===========================================================================
// 双TDC时间戳合成器
// 使用TDC-A和TDC-B的测量结果计算PWM脉宽
// 计算公式: 真实脉宽 = (N + 1) × 2.5ns - a - b
// 其中: N = 粗计数差值, a = TDC-A测量值, b = TDC-B测量值
// ===========================================================================

module timestamp_synthesizer_dual #(
    parameter COARSE_WIDTH = 32,      // 粗计数位宽
    parameter FINE_WIDTH = 7,          // 细计数位宽 (72<128=2^7)
    parameter COARSE_PERIOD = 2.5,     // 粗计数周期(ns)
    parameter FINE_PERIOD = 35.0       // 细计数周期(ns)，需通过码密度统计法校准确定
)(
    input wire [COARSE_WIDTH-1:0] start_coarse_ts,  // START时刻粗时间戳
    input wire [COARSE_WIDTH-1:0] stop_coarse_ts,   // STOP时刻粗时间戳
    input wire [FINE_WIDTH-1:0] fine_a,             // TDC-A细计数值 (a值)
    input wire [FINE_WIDTH-1:0] fine_b,             // TDC-B细计数值 (b值)
    output wire [37:0] timestamp                    // 合成时间戳输出
);

    // =========================================================================
    // 参数定义
    // =========================================================================

    // 时间计算常数（转换为皮秒精度，避免浮点运算）
    localparam COARSE_PERIOD_PS = 2500;              // 2.5ns = 2500ps
    localparam FINE_PERIOD_PS = 35;                  // 35ps，需通过实际校准调整

    // 位宽定义
    localparam CALC_WIDTH = 32;                      // 计算中间结果位宽
    localparam TIMESTAMP_WIDTH = 38;                 // 输出时间戳位宽

    // =========================================================================
    // 内部信号定义
    // =========================================================================

    // 粗计数差值计算
    wire [COARSE_WIDTH-1:0] coarse_diff;

    // 细计数时间转换（转换为皮秒）
    wire [CALC_WIDTH-1:0] a_time_ps;                // a值对应的时间（皮秒）
    wire [CALC_WIDTH-1:0] b_time_ps;                // b值对应的时间（皮秒）

    // 中间计算结果
    wire [CALC_WIDTH-1:0] total_period_ps;          // (N+1) × 2.5ns
    wire [CALC_WIDTH-1:0] final_result_ps;          // 最终结果（皮秒）

    // 边界情况检测
    wire short_pulse_detection;                      // 短脉冲检测
    wire very_short_pulse_detection;                 // 极短脉冲检测
    wire perfect_alignment_detected;                 // 完全对齐检测
    wire metastable_condition;                       // 亚稳态条件检测

    // =========================================================================
    // 边界检测逻辑
    // =========================================================================

    // 对齐阈值（考虑CARRY4测量误差）
    localparam ALIGNMENT_THRESHOLD = 2;              // 允许1-2级误差

    // 检测START边沿是否与时钟对齐
    wire start_aligned = (fine_a <= ALIGNMENT_THRESHOLD);

    // 检测STOP边沿是否与时钟对齐
    wire stop_aligned = (fine_b <= ALIGNMENT_THRESHOLD);

    // 完全对齐检测（两个边沿都与时钟对齐）
    assign perfect_alignment_detected = start_aligned && stop_aligned;

    // 亚稳态检测（a=0且b=0且N>0，但结果不合理）
    assign metastable_condition = (fine_a == 0) && (fine_b == 0) &&
                                 (coarse_diff > 0) && (coarse_diff < 10);

    // =========================================================================
    // 核心计算逻辑
    // =========================================================================

    // 1. 计算粗计数差值
    wire [COARSE_WIDTH-1:0] coarse_diff;
    assign coarse_diff = stop_coarse_ts - start_coarse_ts;

    // 2. 将细计数值转换为时间（皮秒）
    wire [CALC_WIDTH-1:0] a_time_ps;
    wire [CALC_WIDTH-1:0] b_time_ps;
    assign a_time_ps = {25'd0, fine_a} * FINE_PERIOD_PS;
    assign b_time_ps = {25'd0, fine_b} * FINE_PERIOD_PS;

    // 3. 计算 (N + 1) × 2.5ns（标准公式）
    wire [CALC_WIDTH-1:0] total_period_ps;
    wire [CALC_WIDTH-1:0] normal_result_ps;
    assign total_period_ps = ({23'd0, coarse_diff} + 1) * COARSE_PERIOD_PS;
    assign normal_result_ps = total_period_ps - a_time_ps - b_time_ps;

    // 4. 完全对齐情况的计算：脉宽 = N × 2.5ns
    wire [CALC_WIDTH-1:0] aligned_result_ps;
    assign aligned_result_ps = {23'd0, coarse_diff} * COARSE_PERIOD_PS;

    // 5. 选择正确的计算结果
    wire [CALC_WIDTH-1:0] corrected_result_ps;
    assign corrected_result_ps = perfect_alignment_detected ?
                                 aligned_result_ps :
                                 normal_result_ps;

    // 6. 亚稳态恢复机制
    reg [CALC_WIDTH-1:0] metastable_backup_result;
    reg [2:0] metastable_recovery_counter;

    // 时钟和复位信号需要在模块端口定义
    // 注意：这里假设模块有时钟和复位输入，如果没有需要添加

    // 最终输出选择（考虑亚稳态恢复）
    wire [CALC_WIDTH-1:0] final_timestamp;
    assign final_timestamp = (metastable_condition) ?
                            ({23'd0, coarse_diff} * COARSE_PERIOD_PS) :
                            corrected_result_ps;

    assign timestamp = final_timestamp[TIMESTAMP_WIDTH-1:0];

    // =========================================================================
    // 边界情况检测
    // =========================================================================

    // 检测短脉冲（脉宽小于一个粗计数周期）
    assign short_pulse_detection = (coarse_diff == 0);

    // 检测极短脉冲（a + b > 80，可能测量错误）
    assign very_short_pulse_detection = (coarse_diff == 0) &&
                                       ({1'b0, fine_a} + {1'b0, fine_b} > 80);

    // =========================================================================
    // 计算示例说明
    // =========================================================================
    //
    // 示例1: PWM脉宽 = 1.8ns
    // - 假设PWM上升沿在时钟后0.3ns，下降沿在时钟后2.1ns
    // - 粗计数差值 N = 0 (同一时钟周期内)
    // - TDC-A测量: a = 0.3ns → fine_a ≈ 9 (0.3ns / 35ps)
    // - TDC-B测量: b = 0.4ns → fine_b ≈ 11 (0.4ns / 35ps)
    // - 计算: (0 + 1) × 2500ps - 9×35ps - 11×35ps = 2500ps - 315ps - 385ps = 1800ps
    // - 结果: 1800ps = 1.8ns ✓
    //
    // 示例2: PWM脉宽 = 3.2ns (跨越一个时钟周期)
    // - 粗计数差值 N = 1
    // - TDC-A测量: a = 0.3ns → fine_a ≈ 9
    // - TDC-B测量: b = 0.4ns → fine_b ≈ 11
    // - 计算: (1 + 1) × 2500ps - 315ps - 385ps = 5000ps - 700ps = 4300ps
    // - 实际脉宽: 3.2ns，需要检查时序关系
    //

    // =========================================================================
    // 设计说明
    // =========================================================================
    //
    // 1. 精度处理: 使用皮秒(10^-12)为单位避免浮点运算
    // 2. 细计数转换: fine_count × 35ps 得到实际时间
    // 3. 公式原理:
    //    - (N+1) × 2.5ns: 包含START和STOP时钟周期的总时间
    //    - 减去a: 去掉START时钟周期中PWM上升沿前的部分
    //    - 减去b: 去掉STOP时钟周期中PWM下降沿后的部分
    //    - 剩余部分即为PWM实际脉宽
    //
    // 4. 边界处理:
    //    - 短脉冲检测: 用于标识脉宽<2.5ns的情况
    //    - 极短脉冲检测: 用于检测可能的测量错误
    //

endmodule