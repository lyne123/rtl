/**
 * 基于 CARRY4 延迟线的细计数模块 (TDC 时间-数字转换器)
 * 实现 Nutt 时间插值法，使用 DELAY_STAGES 级延迟线
 *
 * 该模块测量细时间间隔 'a' 和 'b'：
 * - 'a': PWM 上升沿到下一个系统时钟上升沿的时间
 * - 'b': PWM 下降沿到下一个系统时钟上升沿的时间
 *
 * 使用两条独立的 CARRY4 延迟链（各 DELAY_STAGES 级）实现高精度测量，
 * 不依赖同步计数器逻辑。
 */

module fine_counter_carry4 (
    input wire clk_400m,          // 400MHz 采样时钟
    input wire rst_n,             // 低电平有效复位信号
    input wire pwm_signal,        // PWM 输入信号（异步边沿）

    output reg [7:0] fine_count_a, // 细计数值 'a'（范围 0-DELAY_STAGES）
    output reg [7:0] fine_count_b, // 细计数值 'b'（范围 0-DELAY_STAGES）
    output reg valid_out         // 输出有效信号
);

// 参数定义
parameter DELAY_STAGES = 160;      // 延迟级数（160 级）
parameter CARRY4_BLOCKS = DELAY_STAGES/4;     // CARRY4 模块数量（160/4 = 40）

//--------------------------------------------------------------------------
// 异步极窄脉冲锁存器 (Pulse Stretching)
// 任务：只要边沿一到，立刻变高并保持，直到被 400MHz 时钟采完后才清零
//--------------------------------------------------------------------------

reg pwm_rise_latched;
reg pwm_fall_latched;
wire clr_rise;
wire clr_fall;

// 1. 捕捉上升沿（用原始异步信号当做时钟！）
always @(posedge pwm_signal or posedge clr_rise) begin
    if (clr_rise) 
        pwm_rise_latched <= 1'b0;
    else 
        pwm_rise_latched <= 1'b1; // 一旦脉冲到来，死死锁住 1
end

// 2. 捕捉下降沿
always @(negedge pwm_signal or posedge clr_fall) begin
    if (clr_fall) 
        pwm_fall_latched <= 1'b0;
    else 
        pwm_fall_latched <= 1'b1;
end

//--------------------------------------------------------------------------
// 采样后反馈清零机制
// 任务：400MHz 拍完照后，发送清零信号，释放锁存器准备迎接下一个脉冲
//--------------------------------------------------------------------------
reg [2:0] rise_clr_sync;
reg [2:0] fall_clr_sync;

always @(posedge clk_400m or negedge rst_n) begin
    if (!rst_n) begin
        rise_clr_sync <= 3'b000;
        fall_clr_sync <= 3'b000;
    end else begin
        // 打三拍同步，生成清零脉冲
        rise_clr_sync <= {rise_clr_sync[1:0], pwm_rise_latched};
        fall_clr_sync <= {fall_clr_sync[1:0], pwm_fall_latched};
    end
end

// 当同步到高电平后，立刻触发清零
assign clr_rise = ~rst_n | (rise_clr_sync[2] & rise_clr_sync[1]); 
assign clr_fall = ~rst_n | (fall_clr_sync[2] & fall_clr_sync[1]);

//--------------------------------------------------------------------------
// CARRY4 延迟链实现 - 使用进位链正确实现
//--------------------------------------------------------------------------
// 延迟链内部信号
(* keep = "true" *) wire [DELAY_STAGES:0] delay_chain_a;  // 上升沿延迟线
(* keep = "true" *) wire [DELAY_STAGES:0] delay_chain_b;  // 下降沿延迟线

//--------------------------------------------------------------------------
// 上升沿延迟链（用于测量 'a'）
//--------------------------------------------------------------------------
genvar i;
generate
    for (i = 0; i < CARRY4_BLOCKS; i = i + 1) begin : rising_delay_chain

        // CARRY4原语实例化 - 利用内部4级延迟
        // 每个CARRY4提供4个独立的延迟级
        CARRY4 carry4_rising_inst (
            .CO(delay_chain_a[(i+1)*4:i*4+1]), // CO[3:0] -> 4级延迟输出
            .O(),                         // 和输出(不使用)
            .CI(i == 0 ? 1'b0 : delay_chain_a[i*4]), // 第一个CARRY4的CI接地，后续连接前一个CO
            .CYINIT(i == 0 ? pwm_rise_latched : 1'b0), // 第一个CARRY4使用start信号
            .DI(4'b0000),                 // 数据输入(全0)
            .S(4'b1111)                   // 选择信号(全1确保进位传播)
        );

    end
endgenerate

//--------------------------------------------------------------------------
// 下降沿延迟链（用于测量 'b'）
//--------------------------------------------------------------------------
generate
    for (i = 0; i < CARRY4_BLOCKS; i = i + 1) begin : falling_delay_chain

        // CARRY4原语实例化 - 利用内部4级延迟
        // 每个CARRY4提供4个独立的延迟级
        CARRY4 carry4_falling_inst (
            .CO(delay_chain_b[(i+1)*4:i*4+1]), // CO[3:0] -> 4级延迟输出
            .O(),                         // 和输出(不使用)
            .CI(i == 0 ? 1'b0 : delay_chain_b[i*4]), // 第一个CARRY4的CI接地，后续连接前一个CO
            .CYINIT(i == 0 ? pwm_fall_latched : 1'b0), // 第一个CARRY4使用start信号
            .DI(4'b0000),                 // 数据输入(全0)
            .S(4'b1111)                   // 选择信号(全1确保进位传播)
        );

    end
endgenerate
//--------------------------------------------------------------------------
// 采样寄存器 - 在时钟边沿捕获延迟线状态
// 注意：这里采样的是CARRY4的 CO 真实进位输出，形成温度计码
//--------------------------------------------------------------------------

// 采样寄存器 //强制把这些触发器紧紧贴在 CARRY4 的旁边
(* ASYNC_REG = "TRUE" *)reg [DELAY_STAGES-1:0] sampled_chain_a;
(* ASYNC_REG = "TRUE" *)reg [DELAY_STAGES-1:0] sampled_chain_b;

always @(posedge clk_400m or negedge rst_n) begin
    if (!rst_n) begin
        sampled_chain_a <= {DELAY_STAGES{1'b0}};
        sampled_chain_b <= {DELAY_STAGES{1'b0}};
    end else begin
        // 采样延迟链以捕获温度计码（从第1级开始，跳过第0级起始信号）
        sampled_chain_a <= delay_chain_a[DELAY_STAGES:1];
        sampled_chain_b <= delay_chain_b[DELAY_STAGES:1];
    end
end

//--------------------------------------------------------------------------
// 温度计码到二进制转换器（加法器树 / 胖树编码器）
// 通过统计温度计码中 1 的个数来消除气泡错误
//--------------------------------------------------------------------------

// =========================================================================
// 第一步：用组合逻辑把 160 位拆成 8 个小组（每组 20 位）分别求和
// =========================================================================
// 因为每组最多有 20 个 1，所以 5 个 bit 就足够存了 (2^5 - 1 = 31 > 20)
reg [4:0] sum_group_a [0:7]; 
reg [4:0] sum_group_b [0:7];

integer idx, jdx; 

always @(*) begin
    for (idx = 0; idx < 8; idx = idx + 1) begin
        sum_group_a[idx] = 5'd0;
        sum_group_b[idx] = 5'd0;
        for (jdx = 0; jdx < 20; jdx = jdx + 1) begin
            sum_group_a[idx] = sum_group_a[idx] + sampled_chain_a[idx*20 + jdx];
            sum_group_b[idx] = sum_group_b[idx] + sampled_chain_b[idx*20 + jdx];
        end
    end
end

// =========================================================================
// 第二步：流水线第 1 拍
// =========================================================================
reg [4:0] pipe1_sum_a [0:7];
reg [4:0] pipe1_sum_b [0:7];
reg       pipe1_valid_a;
reg       pipe1_valid_b;

wire a_data_valid = rise_clr_sync[0] & ~rise_clr_sync[1];
wire b_data_valid = fall_clr_sync[0] & ~fall_clr_sync[1];

always @(posedge clk_400m or negedge rst_n) begin
    if (!rst_n) begin
        for (idx = 0; idx < 8; idx = idx + 1) begin
            pipe1_sum_a[idx] <= 5'd0;
            pipe1_sum_b[idx] <= 5'd0;
        end
        pipe1_valid_a <= 1'b0;
        pipe1_valid_b <= 1'b0;
    end else begin
        for (idx = 0; idx < 8; idx = idx + 1) begin
            pipe1_sum_a[idx] <= sum_group_a[idx];
            pipe1_sum_b[idx] <= sum_group_b[idx];
        end
        
        pipe1_valid_a <= a_data_valid;
        pipe1_valid_b <= b_data_valid;
    end
end
// =========================================================================
// 第三步：流水线第 2 拍（最终汇总与输出）
// =========================================================================
always @(posedge clk_400m or negedge rst_n) begin
    if (!rst_n) begin
        fine_count_a <= 8'd0;
        fine_count_b <= 8'd0;
        valid_out    <= 1'b0;
    end else begin
        // 只有当“打过一拍”的有效信号到来时，才进行最终的汇总加法
        if (pipe1_valid_a) begin
            fine_count_a <= pipe1_sum_a[0] + pipe1_sum_a[1] + pipe1_sum_a[2] + pipe1_sum_a[3] +
                            pipe1_sum_a[4] + pipe1_sum_a[5] + pipe1_sum_a[6] + pipe1_sum_a[7];
        end
        
        if (pipe1_valid_b) begin
            fine_count_b <= pipe1_sum_b[0] + pipe1_sum_b[1] + pipe1_sum_b[2] + pipe1_sum_b[3] +
                            pipe1_sum_b[4] + pipe1_sum_b[5] + pipe1_sum_b[6] + pipe1_sum_b[7];
        end
        
        // 最终的有效脉冲输出（依然只保持一个时钟周期的高电平）
        valid_out <= pipe1_valid_a | pipe1_valid_b;
    end
end
//--------------------------------------------------------------------------
// 综合时序约束说明
//--------------------------------------------------------------------------
// delay_chain_a 和 delay_chain_b 上的 (* keep = "true" *) 属性
// 防止 Vivado 在综合阶段优化掉延迟线。
//
// 需要添加额外的 XDC 约束：
// 1. 设置从 pwm_signal 到延迟链的伪路径
// 2. 设置从 CARRY4 到采样寄存器的 FALSE PATH (异步豁免)
// 3. 防止 CARRY4 链的布局优化

endmodule