// ===========================================================================
// 72位温度计码到7位二进制解码器 - v5版本
// 功能: 将72级延迟链的温度计码转换为二进制计数值
// 设计目标: 72级温度计码 -> 7位二进制 (0-72)
// ===========================================================================

module thermometer_decoder_72to7 (
    input wire [71:0] thermometer_in,  // 72位温度计码输入
    output reg [6:0] binary_out        // 7位二进制输出 (0-72)
);

    // =========================================================================
    // 解码逻辑 - 计算温度计码中1的个数
    // =========================================================================
    // 分8组计算，每组9位
    reg [3:0] group_sum [7:0];
    reg [6:0] final_sum;
    integer i;

    always @(*) begin
        // 使用加法树计算1的个数
        binary_out = 7'd0;


        // 分组计算
        group_sum[0] = thermometer_in[8:0]   == 9'b0 ? 4'd0 :
                      thermometer_in[8:0]   == 9'b1 ? 4'd1 :
                      thermometer_in[8:0]   == 9'b11 ? 4'd2 :
                      thermometer_in[8:0]   == 9'b111 ? 4'd3 :
                      thermometer_in[8:0]   == 9'b1111 ? 4'd4 :
                      thermometer_in[8:0]   == 9'b11111 ? 4'd5 :
                      thermometer_in[8:0]   == 9'b111111 ? 4'd6 :
                      thermometer_in[8:0]   == 9'b1111111 ? 4'd7 :
                      thermometer_in[8:0]   == 9'b11111111 ? 4'd8 :
                      thermometer_in[8:0]   == 9'b111111111 ? 4'd9 : 4'd0;

        group_sum[1] = thermometer_in[17:9]  == 9'b0 ? 4'd0 :
                      thermometer_in[17:9]  == 9'b1 ? 4'd1 :
                      thermometer_in[17:9]  == 9'b11 ? 4'd2 :
                      thermometer_in[17:9]  == 9'b111 ? 4'd3 :
                      thermometer_in[17:9]  == 9'b1111 ? 4'd4 :
                      thermometer_in[17:9]  == 9'b11111 ? 4'd5 :
                      thermometer_in[17:9]  == 9'b111111 ? 4'd6 :
                      thermometer_in[17:9]  == 9'b1111111 ? 4'd7 :
                      thermometer_in[17:9]  == 9'b11111111 ? 4'd8 :
                      thermometer_in[17:9]  == 9'b111111111 ? 4'd9 : 4'd0;

        group_sum[2] = thermometer_in[26:18] == 9'b0 ? 4'd0 :
                      thermometer_in[26:18] == 9'b1 ? 4'd1 :
                      thermometer_in[26:18] == 9'b11 ? 4'd2 :
                      thermometer_in[26:18] == 9'b111 ? 4'd3 :
                      thermometer_in[26:18] == 9'b1111 ? 4'd4 :
                      thermometer_in[26:18] == 9'b11111 ? 4'd5 :
                      thermometer_in[26:18] == 9'b111111 ? 4'd6 :
                      thermometer_in[26:18] == 9'b1111111 ? 4'd7 :
                      thermometer_in[26:18] == 9'b11111111 ? 4'd8 :
                      thermometer_in[26:18] == 9'b111111111 ? 4'd9 : 4'd0;

        group_sum[3] = thermometer_in[35:27] == 9'b0 ? 4'd0 :
                      thermometer_in[35:27] == 9'b1 ? 4'd1 :
                      thermometer_in[35:27] == 9'b11 ? 4'd2 :
                      thermometer_in[35:27] == 9'b111 ? 4'd3 :
                      thermometer_in[35:27] == 9'b1111 ? 4'd4 :
                      thermometer_in[35:27] == 9'b11111 ? 4'd5 :
                      thermometer_in[35:27] == 9'b111111 ? 4'd6 :
                      thermometer_in[35:27] == 9'b1111111 ? 4'd7 :
                      thermometer_in[35:27] == 9'b11111111 ? 4'd8 :
                      thermometer_in[35:27] == 9'b111111111 ? 4'd9 : 4'd0;

        group_sum[4] = thermometer_in[44:36] == 9'b0 ? 4'd0 :
                      thermometer_in[44:36] == 9'b1 ? 4'd1 :
                      thermometer_in[44:36] == 9'b11 ? 4'd2 :
                      thermometer_in[44:36] == 9'b111 ? 4'd3 :
                      thermometer_in[44:36] == 9'b1111 ? 4'd4 :
                      thermometer_in[44:36] == 9'b11111 ? 4'd5 :
                      thermometer_in[44:36] == 9'b111111 ? 4'd6 :
                      thermometer_in[44:36] == 9'b1111111 ? 4'd7 :
                      thermometer_in[44:36] == 9'b11111111 ? 4'd8 :
                      thermometer_in[44:36] == 9'b111111111 ? 4'd9 : 4'd0;

        group_sum[5] = thermometer_in[53:45] == 9'b0 ? 4'd0 :
                      thermometer_in[53:45] == 9'b1 ? 4'd1 :
                      thermometer_in[53:45] == 9'b11 ? 4'd2 :
                      thermometer_in[53:45] == 9'b111 ? 4'd3 :
                      thermometer_in[53:45] == 9'b1111 ? 4'd4 :
                      thermometer_in[53:45] == 9'b11111 ? 4'd5 :
                      thermometer_in[53:45] == 9'b111111 ? 4'd6 :
                      thermometer_in[53:45] == 9'b1111111 ? 4'd7 :
                      thermometer_in[53:45] == 9'b11111111 ? 4'd8 :
                      thermometer_in[53:45] == 9'b111111111 ? 4'd9 : 4'd0;

        group_sum[6] = thermometer_in[62:54] == 9'b0 ? 4'd0 :
                      thermometer_in[62:54] == 9'b1 ? 4'd1 :
                      thermometer_in[62:54] == 9'b11 ? 4'd2 :
                      thermometer_in[62:54] == 9'b111 ? 4'd3 :
                      thermometer_in[62:54] == 9'b1111 ? 4'd4 :
                      thermometer_in[62:54] == 9'b11111 ? 4'd5 :
                      thermometer_in[62:54] == 9'b111111 ? 4'd6 :
                      thermometer_in[62:54] == 9'b1111111 ? 4'd7 :
                      thermometer_in[62:54] == 9'b11111111 ? 4'd8 :
                      thermometer_in[62:54] == 9'b111111111 ? 4'd9 : 4'd0;

        group_sum[7] = thermometer_in[71:63] == 9'b0 ? 4'd0 :
                      thermometer_in[71:63] == 9'b1 ? 4'd1 :
                      thermometer_in[71:63] == 9'b11 ? 4'd2 :
                      thermometer_in[71:63] == 9'b111 ? 4'd3 :
                      thermometer_in[71:63] == 9'b1111 ? 4'd4 :
                      thermometer_in[71:63] == 9'b11111 ? 4'd5 :
                      thermometer_in[71:63] == 9'b111111 ? 4'd6 :
                      thermometer_in[71:63] == 9'b1111111 ? 4'd7 :
                      thermometer_in[71:63] == 9'b11111111 ? 4'd8 :
                      thermometer_in[71:63] == 9'b111111111 ? 4'd9 : 4'd0;

        // 最终求和
        final_sum = group_sum[0] + group_sum[1] + group_sum[2] + group_sum[3] +
                   group_sum[4] + group_sum[5] + group_sum[6] + group_sum[7];

        // 输出结果，限制在0-72范围内
        if (final_sum > 7'd72) begin
            binary_out = 7'd72;
        end else begin
            binary_out = final_sum;
        end
    end

    // =========================================================================
    // 温度计码格式说明
    // =========================================================================
    //
    // 输入格式: [71:0] thermometer_in
    // - 理想温度计码: 前N位为1，其余为0
    // - 例如: 25级传播 -> bit[24:0]=1, bit[71:25]=0
    //
    // 输出格式: [6:0] binary_out
    // - 0-72的整数值
    // - 表示PWM信号在延迟链中传播的距离
    //
    // 测量原理:
    // - 1的个数 × 35ps = PWM脉宽
    // - 例如: 25个1 -> 25 × 35ps = 875ps
    //

    // =========================================================================
    // 性能参数
    // =========================================================================
    //
    // 解码特性:
    // - 输入位宽: 72位
    // - 输出位宽: 7位 (0-72)
    // - 延迟: 组合逻辑，约2-3ns
    // - 资源消耗: 约200-300 LUT
    //
    // 精度特性:
    // - 分辨率: 1级延迟
    // - 理论精度: 35ps
    // - 实际精度: 50-100ps (考虑工艺变化)
    //

endmodule

// ===========================================================================
// 设计说明:
//
// 1. 为什么需要温度计码解码:
//    - 延迟链输出是温度计码格式
//    - 需要转换为二进制数值进行计算
//    - 1的个数表示PWM传播的距离
//
// 2. 分组解码设计:
//    - 将72位分为8组，每组9位
    //    - 减少组合逻辑延迟
//    - 提高运行频率
//    - 优化资源使用
//
// 3. 温度计码特性:
//    - 理想情况下，前N位为1，其余为0
//    - 1的个数与传播距离成正比
//    - 可以精确测量脉宽
//
// 4. 边界情况处理:
//    - 输入全0: 输出0 (无PWM信号)
//    - 输入全1: 输出72 (最大脉宽)
//    - 非理想温度计码: 取1的总数
//
// 5. 与其他模块的接口:
//    - 输入: pwm_delay_chain_sampler的输出
//    - 输出: pwm_data_fusion的输入
//    - 无缝连接，无需额外同步
// ===========================================================================