// ===========================================================================
// CARRY4延迟链模块 - 实现高精度抽头延迟法
// 使用xc7a100t的CARRY4原语构建60级延迟链
// 每级延迟约35ps，总延迟约2.1ns
// ===========================================================================

module carry4_delay_chain #(
    parameter CARRY4_COUNT = 20,  // CARRY4原语数量
    parameter TOTAL_STAGES = 80   // 总延迟级数 (CARRY4_COUNT * 4)
)(
    input wire clk_400m,         // 400MHz采样时钟
    input wire rst_n,             // 异步复位
    input wire start_signal,      // START信号(进入延迟链)
    input wire stop_signal,       // STOP信号(触发采样)
    output reg [TOTAL_STAGES-1:0] thermometer_code, // 温度计码输出
    output reg zero_flag,         // 边界情况标记 (a=0或b=0)
    output reg metastable_warning // 亚稳态警告信号
);

    // =========================================================================
    // 内部信号定义
    // =========================================================================

    // 延迟链信号 (TOTAL_STAGES+1个节点)
    wire [TOTAL_STAGES:0] carry_chain;

    // 输入信号同步链（减少亚稳态风险）
    reg [2:0] start_sync_chain;   // 三级同步START信号
    reg [2:0] stop_sync_chain;    // 三级同步STOP信号

    // 采样寄存器 (三级同步，进一步减少亚稳态)
    reg [TOTAL_STAGES-1:0] sample_reg1;
    reg [TOTAL_STAGES-1:0] sample_reg2;
    reg [TOTAL_STAGES-1:0] sample_reg3;

    // 控制信号
    reg sampling_active;          // 采样状态标志
    reg stop_signal_d1;           // STOP信号延迟
    reg start_delayed;            // 延迟一个周期的START信号

    // 亚稳态检测信号
    reg metastable_warning;       // 亚稳态警告信号

    // =========================================================================
    // 延迟链连接
    // =========================================================================

    assign carry_chain[0] = start_delayed;  // 使用延迟后的START信号，确保可靠采样

    // =========================================================================
    // CARRY4延迟链生成 - 方案一：充分利用CARRY4内部4级延迟
    // =========================================================================

    genvar i;
    generate
        for (i = 0; i < CARRY4_COUNT; i = i + 1) begin : carry4_delay_chain

            // CARRY4原语实例化 - 利用内部4级延迟
            // 每个CARRY4提供4个独立的延迟级
            CARRY4 carry4_inst (
                .CO(carry_chain[(i+1)*4:i*4+1]), // CO[3:0] -> 4级延迟输出
                .O(),                         // 和输出(不使用)
                .CI(carry_chain[i*4]),        // 进位输入(来自前一个CARRY4)
                .CYINIT(i == 0 ? start_delayed : 1'b0), // 第一个CARRY4使用start信号
                .DI(4'b0000),                 // 数据输入(全0)
                .S(4'b1111)                   // 选择信号(全1确保进位传播)
            );

        end
    endgenerate

    // =========================================================================
    // 输入信号同步逻辑 - 三级同步减少亚稳态
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            start_sync_chain <= 3'b000;
            stop_sync_chain <= 3'b000;
            start_delayed <= 1'b0;
            stop_signal_d1 <= 1'b0;
        end else begin
            // 三级同步START信号
            start_sync_chain <= {start_sync_chain[1:0], start_signal};

            // 三级同步STOP信号
            stop_sync_chain <= {stop_sync_chain[1:0], stop_signal};

            // 使用同步后的信号
            start_delayed <= start_sync_chain[2];
            stop_signal_d1 <= stop_sync_chain[2];
        end
    end

    // =========================================================================
    // 采样控制逻辑 - 改进版本，支持边界情况处理
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            sampling_active <= 1'b0;
            sample_reg1 <= {TOTAL_STAGES{1'b0}};
            sample_reg2 <= {TOTAL_STAGES{1'b0}};
            thermometer_code <= {TOTAL_STAGES{1'b0}};
            zero_flag <= 1'b0;
        end else begin

            // 采样状态控制 - 使用延迟后的START信号
            if (start_delayed && !sampling_active) begin
                // 延迟后的START信号有效且未在采样中，开始新的采样
                sampling_active <= 1'b1;
            end else if (stop_signal && !stop_signal_d1 && sampling_active) begin
                // 检测到STOP信号的上升沿且正在采样中，完成采样
                sampling_active <= 1'b0;
            end

            // 三级同步采样，进一步减少亚稳态风险
            if (sampling_active) begin
                // 第一级采样 - 采样所有72级延迟
                sample_reg1 <= carry_chain[TOTAL_STAGES:1];

                // 第二级采样(进一步减少亚稳态)
                sample_reg2 <= sample_reg1;

                // 第三级采样(最终稳定)
                sample_reg3 <= sample_reg2;

                // 当STOP信号有效时，锁存最终结果
                if (stop_sync_chain[2] && !stop_signal_d1) begin
                    thermometer_code <= sample_reg3;
                    // 标记是否为0值情况（a=0或b=0的边界情况）
                    zero_flag <= (sample_reg3 == {TOTAL_STAGES{1'b0}});

                    // 检测可能的亚稳态情况
                    metastable_warning <= (sample_reg1 != sample_reg2) ||
                                       (sample_reg2 != sample_reg3);
                end
            end else begin
                // 非采样期间清零
                sample_reg1 <= {TOTAL_STAGES{1'b0}};
                sample_reg2 <= {TOTAL_STAGES{1'b0}};
                sample_reg3 <= {TOTAL_STAGES{1'b0}};
                zero_flag <= 1'b0;
                metastable_warning <= 1'b0;
            end

        end
    end

    // =========================================================================
    // 温度计码说明 (方案一优化版)
    // =========================================================================
    //
    // 温度计码格式: [71:0]
    // - bit[71]: 第18个CARRY4的第4级(最慢)
    // - bit[68:70]: 第18个CARRY4的第1-3级
    // - bit[67:0]: 前17个CARRY4的所有级别
    //
    // CARRY4内部延迟级分布:
    // CARRY4_0: bit[3:0]   = {CO[3], CO[2], CO[1], CO[0]}
    // CARRY4_1: bit[7:4]   = {CO[3], CO[2], CO[1], CO[0]}
    // ...
    // CARRY4_17: bit[71:68] = {CO[3], CO[2], CO[1], CO[0]}
    //
    // 例如，如果START信号传播到第25级:
    // - 第0-24级: 25个1
    // - 第25-71级: 47个0
    //

    // =========================================================================
    // 性能参数 (方案一优化后)
    // =========================================================================
    //
    // CARRY4延迟特性 (优化后):
    // - CARRY4数量: 18个 (原为72个)
    // - 总延迟级数: 72级 (保持不变)
    // - 单级延迟: 30-40ps (典型值35ps)
    // - 总延迟: 72 × 35ps = 2.52ns
    // - 覆盖粗计数周期: 2.5ns ✓
    // - 理论精度: 2.5ns / 72 = 34.7ps
    // - 资源节省: 75%的CARRY4使用量减少
    // - 线性度提升: 同一CARRY4内4级延迟更一致
    //

    // =========================================================================
    // 时序约束建议 (方案一)
    // =========================================================================
    //
    // 1. 延迟链内部连接优化:
    //    set_property DONT_TOUCH true [get_cells carry4_delay_chain*]
    //    set_property KEEP_HIERARCHY true [get_cells carry4_delay_chain*]
    //
    // 2. CARRY4布局约束:
    //    set_property LOC SLICE_X0Y0 [get_cells carry4_delay_chain[0].carry4_inst]
    //    set_property LOC SLICE_X0Y1 [get_cells carry4_delay_chain[1].carry4_inst]
    //    ... (连续布局在同一列)
    //
    // 3. 采样路径约束:
    //    set_multicycle_path 3 -setup -from [get_pins carry4_delay_chain*/carry_chain[*]] -to [get_registers sample_reg1*]
    //    set_multicycle_path 2 -hold -from [get_pins carry4_delay_chain*/carry_chain[*]] -to [get_registers sample_reg1*]
    //

endmodule

// ===========================================================================
// 设计优化说明:
//
// 1. 为什么选择CARRY4而不是LUT:
//    - 延迟更精确(35ps vs 100-200ps)
//    - 温度稳定性更好(±5% vs ±10%)
//    - 工艺一致性更好
//
// 2. 两级采样设计:
//    - 减少亚稳态风险
//    - 提高采样可靠性
//    - 确保数据稳定性
//
// 3. 60级延迟链选择:
//    - 覆盖2.5ns粗计数周期
//    - 留出温度漂移裕量
//    - 平衡精度和资源使用
// ===========================================================================