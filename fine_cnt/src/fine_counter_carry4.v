/**
 * 基于 CARRY4 延迟线的细计数模块 (TDC 时间-数字转换器)
 * 实现 Nutt 时间插值法，使用 80 级延迟线
 *
 * 该模块测量细时间间隔 'a' 和 'b'：
 * - 'a': PWM 上升沿到下一个系统时钟上升沿的时间
 * - 'b': PWM 下降沿到下一个系统时钟上升沿的时间
 *
 * 使用两条独立的 CARRY4 延迟链（各 80 级）实现高精度测量，
 * 不依赖同步计数器逻辑。
 */

module fine_counter_carry4 (
    input wire clk_400m,          // 400MHz 采样时钟
    input wire rst_n,             // 低电平有效复位信号
    input wire pwm_signal,        // PWM 输入信号（异步边沿）

    output reg [6:0] fine_count_a, // 细计数值 'a'（7 位，范围 0-80）
    output reg [6:0] fine_count_b, // 细计数值 'b'（7 位，范围 0-80）
    output reg valid_out          // 输出有效信号
);

// 参数定义
parameter DELAY_STAGES = 80;      // 延迟级数（80 级 CARRY4）
parameter CARRY4_BLOCKS = 20;     // CARRY4 模块数量（80/4 = 20）

// 延迟链内部信号
(* keep = "true" *) wire [DELAY_STAGES-1:0] delay_chain_a;  // 上升沿延迟线
(* keep = "true" *) wire [DELAY_STAGES-1:0] delay_chain_b;  // 下降沿延迟线

// 采样寄存器
reg [DELAY_STAGES-1:0] sampled_chain_a;
reg [DELAY_STAGES-1:0] sampled_chain_b;

// 边沿检测信号
reg pwm_d1, pwm_d2;
wire rising_edge;
wire falling_edge;

// 生成上升沿和下降沿脉冲
assign rising_edge = pwm_signal & ~pwm_d1;
assign falling_edge = ~pwm_signal & pwm_d1;

// 边沿检测流水线
always @(posedge clk_400m or negedge rst_n) begin
    if (!rst_n) begin
        pwm_d1 <= 1'b0;
        pwm_d2 <= 1'b0;
    end else begin
        pwm_d1 <= pwm_signal;
        pwm_d2 <= pwm_d1;
    end
end

//--------------------------------------------------------------------------
// CARRY4 延迟链实现 - 使用进位链正确实现
//--------------------------------------------------------------------------

// 进位链信号 - 每个 CARRY4 有一个进位输出
(* keep = "true" *) wire [CARRY4_BLOCKS:0] carry_chain_a;
(* keep = "true" *) wire [CARRY4_BLOCKS:0] carry_chain_b;

// 进位链初始化 - 实际上通过CYINIT连接输入信号，这里保持悬空
// 因为CYINIT已经直接连接了输入信号

//--------------------------------------------------------------------------
// 上升沿延迟链（用于测量 'a'）
//--------------------------------------------------------------------------
genvar i;
generate
    for (i = 0; i < CARRY4_BLOCKS; i = i + 1) begin : rising_delay_chain
        // 实例化 CARRY4 模块用于延迟链
        CARRY4 carry4_rising_inst (
            .CO(carry_chain_a[i+1]),                // ✅ 进位输出连接到下一级
            .O(delay_chain_a[i*4 +: 4]),            // 4位输出直接作为延迟抽头
            .CI(i == 0 ? 1'b0 : carry_chain_a[i]),  // 第一级CI=0，后续级CI来自前级CO
            .CYINIT(i == 0 ? rising_edge : 1'b0),   // 第一级CYINIT接输入信号
            .DI(4'h0),                              // 数据输入全0
            .S(4'hF)                                // 选择输入全1以获得最大延迟
        );
    end
endgenerate

//--------------------------------------------------------------------------
// 下降沿延迟链（用于测量 'b'）
//--------------------------------------------------------------------------
generate
    for (i = 0; i < CARRY4_BLOCKS; i = i + 1) begin : falling_delay_chain
        // 实例化 CARRY4 模块用于延迟链
        CARRY4 carry4_falling_inst (
            .CO(carry_chain_b[i+1]),                // ✅ 进位输出连接到下一级
            .O(delay_chain_b[i*4 +: 4]),           // 4位输出直接作为延迟抽头
            .CI(i == 0 ? 1'b0 : carry_chain_b[i]),  // 第一级CI=0，后续级CI来自前级CO
            .CYINIT(i == 0 ? falling_edge : 1'b0),  // 第一级CYINIT接输入信号
            .DI(4'h0),                             // 数据输入全0
            .S(4'hF)                               // 选择输入全1以获得最大延迟
        );
    end
endgenerate

//--------------------------------------------------------------------------
// 采样寄存器 - 在时钟边沿捕获延迟线状态
// 注意：这里采样的是CARRY4的O输出，形成温度计码
//--------------------------------------------------------------------------
always @(posedge clk_400m or negedge rst_n) begin
    if (!rst_n) begin
        sampled_chain_a <= {DELAY_STAGES{1'b0}};
        sampled_chain_b <= {DELAY_STAGES{1'b0}};
        valid_out <= 1'b0;
    end else begin
        // 采样延迟链以捕获温度计码
        sampled_chain_a <= delay_chain_a;
        sampled_chain_b <= delay_chain_b;
        valid_out <= 1'b1;
    end
end

//--------------------------------------------------------------------------
// 温度计码到二进制转换器（加法器树 / 胖树编码器）
// 通过统计温度计码中 1 的个数来消除气泡错误
//--------------------------------------------------------------------------

// 上升沿计数器（用于 'a'）
function [6:0] count_ones_80bit;
    input [79:0] thermometer_code;
    integer j;
    reg [6:0] count;
    begin
        count = 7'd0;
        for (j = 0; j < 80; j = j + 1) begin
            count = count + thermometer_code[j];
        end
        count_ones_80bit = count;
    end
endfunction

// 下降沿计数器（用于 'b'）
function [6:0] count_ones_80bit_b;
    input [79:0] thermometer_code;
    integer j;
    reg [6:0] count;
    begin
        count = 7'd0;
        for (j = 0; j < 80; j = j + 1) begin
            count = count + thermometer_code[j];
        end
        count_ones_80bit_b = count;
    end
endfunction

//--------------------------------------------------------------------------
// 输出寄存器级
//--------------------------------------------------------------------------
always @(posedge clk_400m or negedge rst_n) begin
    if (!rst_n) begin
        fine_count_a <= 7'd0;
        fine_count_b <= 7'd0;
    end else begin
        // 将温度计码转换为二进制计数值
        fine_count_a <= count_ones_80bit(sampled_chain_a);
        fine_count_b <= count_ones_80bit_b(sampled_chain_b);
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
// 2. 设置延迟链传播的多周期路径
// 3. 防止 CARRY4 链的布局优化

endmodule