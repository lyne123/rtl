// ===========================================================================
// 400MHz粗计数器模块 - 时间戳模式TDC设计
// 使用连续运行的32位计数器，记录START/STOP时刻的时间戳
// 支持大范围时间测量，避免启停计数器的稳定性问题
// ===========================================================================

module coarse_counter_400m (
    input wire clk_400m,          // 400MHz时钟 (2.5ns周期)
    input wire rst_n,             // 异步复位信号
    input wire start_sync,        // 同步后的START信号
    input wire stop_sync,         // 同步后的STOP信号
    output reg [31:0] start_coarse_ts, // START时刻粗时间戳
    output reg [31:0] stop_coarse_ts,  // STOP时刻粗时间戳
    output reg [31:0] free_run_count    // 自由运行计数器(用于监控)
);

    // =========================================================================
    // 内部信号定义
    // =========================================================================

    reg [31:0] continuous_counter; // 连续运行的32位计数器

    // 输入信号同步寄存器 (两级同步)
    reg start_sync_d1, start_sync_d2;
    reg stop_sync_d1, stop_sync_d2;

    // 边沿检测信号
    wire start_capture;
    wire stop_capture;

    // =========================================================================
    // 信号同步与边沿检测
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            // 同步寄存器清零
            start_sync_d1 <= 1'b0;
            start_sync_d2 <= 1'b0;
            stop_sync_d1 <= 1'b0;
            stop_sync_d2 <= 1'b0;

        end else begin
            // 两级同步器，减少亚稳态风险
            start_sync_d1 <= start_sync;
            start_sync_d2 <= start_sync_d1;
            stop_sync_d1 <= stop_sync;
            stop_sync_d2 <= stop_sync_d1;
        end
    end

    // 上升沿检测 (单周期脉冲)
    // 检测从0到1的跳变
    assign start_capture = start_sync_d1 && !start_sync_d2;
    assign stop_capture = stop_sync_d1 && !stop_sync_d2;

    // =========================================================================
    // 连续计数器逻辑
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            continuous_counter <= 32'd0;
            start_coarse_ts <= 32'd0;
            stop_coarse_ts <= 32'd0;
            free_run_count <= 32'd0;

        end else begin
            // 连续计数器递增 (自由运行)
            continuous_counter <= continuous_counter + 1'b1;
            free_run_count <= continuous_counter;

            // START信号时间戳捕获
            if (start_capture) begin
                start_coarse_ts <= continuous_counter;
            end

            // STOP信号时间戳捕获
            if (stop_capture) begin
                stop_coarse_ts <= continuous_counter;
            end

        end
    end

    // =========================================================================
    // 性能参数说明
    // =========================================================================

    // 时间戳TDC特性:
    // - 时钟频率: 400MHz
    // - 时钟周期: 2.5ns
    // - 时间戳范围: 0 ~ 2^32-1 × 2.5ns
    // - 最大时间跨度: ≈ 10.74秒
    // - 分辨率: 2.5ns

    // 应用场景:
    // - 高精度时间间隔测量
    // - 多事件时间戳记录
    // - 与细计数结合实现ps级精度

    // =========================================================================
    // 设计优势
    // =========================================================================

    // 1. 连续计数 vs 启停计数:
    //    - 避免启停计数器的时钟门控问题
    //    - 减少时钟抖动和偏斜
    //    - 提高系统稳定性

    // 2. 时间戳模式优势:
    //    - 支持多事件测量
    //    - 避免计数器溢出问题
    //    - 便于时间间隔计算

    // 3. 同步设计:
    //    - 两级同步器确保信号稳定
    //    - 边沿检测避免重复触发
    //    - 支持异步输入信号

    // =========================================================================
    // 时序约束建议
    // =========================================================================

    // set_false_path -from [get_ports start_sync] -to [get_registers start_sync_d1*]
    // set_false_path -from [get_ports stop_sync] -to [get_registers stop_sync_d1*]
    // set_multicycle_path 2 -setup -from [get_registers start_sync_d2*] -to [

endmodule