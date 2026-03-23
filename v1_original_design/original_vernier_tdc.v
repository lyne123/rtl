module vernier_tdc #(
    parameter STAGES    = 5,  // 延迟级数 (对应图中 5 个阶段)
    parameter DELAY_DIV = 12, // 上边 Delay 延迟值 (举例)
    parameter DELAY_REF = 10  // 下边 Delay2 延迟值 (稍快)
)(
    input  wire div_t,                    // 除信号 (输入)
    input  wire ref_t,                    // 参考信号 (输入)
    output wire [STAGES-1:0] therm_code,  // 温度计编码输出 (对应图中的 e[k])
    output reg  [7:0] tdc_out             // 细分时间输出 (对应图中的 ⊿t)
);

    localparam RESOLUTION = DELAY_DIV - DELAY_REF;

    // 各级延迟节点定义
    // 分为 STAGES级，每个信号在每级的节点
    wire [STAGES-1:0] delay_div_node;
    wire [STAGES-1:0] delay_ref_node;

    // --- 第 0 级直接连接输入 (对应图中的第一个 Reg 之前) ---
    assign delay_div_node[0] = div_t;
    assign delay_ref_node[0] = ref_t;

    // --- 第 1 到 STAGES-1 级包含延迟单元和触发器 ---
    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : vernier_stage

            // --- 延迟链 1 (Delay) ---
            delay_element #(.DELAY_VAL(DELAY_DIV)) d1 (
                .in(delay_div_node[i]),
                .out(delay_div_node[i+1])
            );

            // --- 延迟链 2 (Delay2) ---
            delay_element #(.DELAY_VAL(DELAY_REF)) d2 (
                .in(delay_ref_node[i]),
                .out(delay_ref_node[i+1])
            );

            // --- D触发器采样 (Reg) ---
            d_ff_reg stage_reg (
                .d(delay_div_node[i+1]),
                .clk(delay_ref_node[i+1]),
                .q(therm_code[i])
            );
        end
    endgenerate

    // 将异步温度计码直接使用组合逻辑跟踪 e_k 的变化
    always @(*) begin
        case(therm_code)
            8'b00000000: tdc_out = 0 * RESOLUTION;
            8'b00000001: tdc_out = 1 * RESOLUTION;
            8'b00000011: tdc_out = 2 * RESOLUTION;
            8'b00000111: tdc_out = 3 * RESOLUTION;
            8'b00001111: tdc_out = 4 * RESOLUTION;
            8'b00011111: tdc_out = 5 * RESOLUTION;
            8'b00111111: tdc_out = 6 * RESOLUTION;
            8'b01111111: tdc_out = 7 * RESOLUTION;
            8'b11111111: tdc_out = 8 * RESOLUTION;
            // 默认情况处理非理想状态毛刺
            default:  tdc_out = 8'd0;
        endcase
    end


endmodule

// ==========================================
// 基本单元定义
// ==========================================

// 延迟单元 (参数化)
module delay_element #(parameter DELAY_VAL = 1) (
    input  wire in,
    output wire out
);
    // 综合时会被忽略，实际硬件替换为单位延迟 IDELAY
    assign #DELAY_VAL out = in;
endmodule

// D 触发器
module d_ff_reg (
    input  wire d,
    input  wire clk,
    output reg  q
);
    initial q = 1'b0;

    // 时钟上升沿采样行为
    always @(posedge clk) begin
        q <= d;
    end
endmodule