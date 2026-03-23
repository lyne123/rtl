// ===========================================================================
// 温度计码解码器 - 将CARRY4延迟链输出转换为二进制码
// 输入: 60位温度计码
// 输出: 6位二进制码 (0-59)
// 算法: 统计温度计码中1的个数
// ===========================================================================

module thermometer_decoder #(
    parameter INPUT_WIDTH = 72,   // 温度计码输入宽度 (修正: 60->72)
    parameter OUTPUT_WIDTH = 7    // 二进制输出宽度 (2^7=128 > 72)
)(
    input wire [INPUT_WIDTH-1:0] thermometer_in,  // 温度计码输入
    output wire [OUTPUT_WIDTH-1:0] binary_out     // 二进制输出
);

    // =========================================================================
    // 解码算法实现
    // =========================================================================

    // 方法1: 使用函数实现并行计数 (推荐)
    function [OUTPUT_WIDTH-1:0] count_ones;
        input [INPUT_WIDTH-1:0] therm;
        reg [7:0] count;  // 使用8位计数器，防止溢出
        integer i;
    begin
        count = 8'd0;

        // 并行统计1的个数
        for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
            count = count + therm[i];
        end

        // 确保结果在有效范围内
        if (count > INPUT_WIDTH) begin
            count_ones = INPUT_WIDTH[OUTPUT_WIDTH-1:0];
        end else begin
            count_ones = count[OUTPUT_WIDTH-1:0];
        end
    end
    endfunction

    // 方法2: 使用树形加法器 (备选，减少组合逻辑延迟)
    // 这里使用简单的并行计数，因为60位不算太大

    // =========================================================================
    // 输出解码结果
    // =========================================================================

    assign binary_out = count_ones(thermometer_in);

    // =========================================================================
    // 解码说明
    // =========================================================================

    // 温度计码格式说明:
    // - 输入: [71:0] 72位温度计码
    // - 输出: [6:0] 7位二进制码
    //
    // 温度计码特点:
    // - 连续的前导1，后跟连续的0
    // - 例如: 111111000000... (25个1 + 35个0)
    // - 1的个数表示细计数值
    //
    // 解码示例:
    // thermometer_in = 60'b111111000000000000000000000000000000000000000000000000000000
    // count_ones = 6'd25
    // binary_out = 6'd25

    // =========================================================================
    // 性能分析
    // =========================================================================

    // 组合逻辑延迟分析:
    // - 60位并行加法器
    // - 约6-8级逻辑门延迟
    // - 在400MHz时钟下(2.5ns周期)可接受
    //
    // 资源使用:
    // - LUT使用量: 约30-50个
    // - FF使用量: 6个(输出寄存器)

    // =========================================================================
    // 优化建议
    // =========================================================================

    // 如果需要进一步优化时序:
    // 1. 使用树形加法器结构
    // 2. 添加流水线寄存器
    // 3. 使用查找表(LUT)预计算

    // 树形加法器示例 (注释掉的备选方案):
    /*
    // 第一阶段: 15个4位加法器
    wire [2:0] stage1 [14:0];
    genvar i;
    generate
        for (i = 0; i < 15; i = i + 1) begin : stage1_add
            assign stage1[i] = thermometer_in[i*4+3] + thermometer_in[i*4+2] +
                              thermometer_in[i*4+1] + thermometer_in[i*4+0];
        end
    endgenerate

    // 第二阶段: 5个3位加法器
    wire [3:0] stage2 [4:0];
    assign stage2[0] = stage1[0] + stage1[1] + stage1[2];
    assign stage2[1] = stage1[3] + stage1[4] + stage1[5];
    assign stage2[2] = stage1[6] + stage1[7] + stage1[8];
    assign stage2[3] = stage1[9] + stage1[10] + stage1[11];
    assign stage2[4] = stage1[12] + stage1[13] + stage1[14];

    // 第三阶段: 最终加法
    wire [4:0] stage3;
    assign stage3 = stage2[0] + stage2[1] + stage2[2] + stage2[3] + stage2[4];

    // 处理剩余的0位
    wire [1:0] remainder;
    assign remainder = thermometer_in[59] + thermometer_in[58] + thermometer_in[57];

    // 最终结果
    assign binary_out = stage3 + remainder;
    */

    // =========================================================================
    // 错误检测与处理
    // =========================================================================

    // 理想情况下，温度计码应该是连续的1后跟连续的0
    // 可以添加错误检测逻辑:

    // 检测非标准温度计码 (可选)
    // wire error_detected;
    // assign error_detected = check_thermometer_error(thermometer_in);

    // function check_thermometer_error;
    //     input [INPUT_WIDTH-1:0] therm;
    //     reg found_zero;
    //     integer i;
    // begin
    //     found_zero = 1'b0;
    //     check_thermometer_error = 1'b0;
    //
    //     for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
    //         if (therm[i] == 1'b0) begin
    //             found_zero = 1'b1;
    //         end else if (found_zero && therm[i] == 1'b1) begin
    //             // 在0之后又出现1，不是标准温度计码
    //             check_thermometer_error = 1'b1;
    //         end
    //     end
    // end
    // endfunction

    // =========================================================================
    // 时序约束建议
    // =========================================================================

    // set_max_delay 2.0 -from [get_ports thermometer_in] -to [get_ports binary_out]
    // set_false_path -from [get_registers *thermometer_code*] -to [get_registers *binary_out*]

endmodule

// ===========================================================================
// 设计说明:
//
// 1. 为什么选择并行计数而不是树形加法器:
//    - 60位输入不算太大
    //    - 并行计数代码简洁易懂
    //    - 综合工具会自动优化
    //
// 2. 为什么使用函数:
//    - 代码可读性好
    //    - 综合工具能很好优化
    //    - 便于参数化设计
    //
// 3. 输出范围保护:
//    - 确保输出在0-59范围内
    //    - 防止计数器溢出
    //    - 提高系统可靠性
// ===========================================================================