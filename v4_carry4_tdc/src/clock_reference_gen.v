// ===========================================================================
// 时钟参考信号生成模块
// 为TDC-A和TDC-B生成正确的参考时钟信号
// TDC-A: 测量从"前一个时钟边沿"到PWM上升沿的延迟(a)
// TDC-B: 测量从PWM下降沿到"下一个时钟边沿"的提前(b)
// ===========================================================================

module clock_reference_gen (
    input wire clk_400m,          // 400MHz时钟
    input wire rst_n,             // 异步复位
    input wire start_sync,        // 同步后的PWM上升沿
    input wire stop_sync,         // 同步后的PWM下降沿
    output reg prev_clk_ref,      // TDC-A参考信号（前时钟边沿）
    output reg next_clk_ref       // TDC-B参考信号（后时钟边沿）
);

    // =========================================================================
    // 内部信号
    // =========================================================================

    reg [1:0] start_sync_d;       // START信号延迟链
    reg [1:0] stop_sync_d;        // STOP信号延迟链

    wire start_pulse;             // START单周期脉冲
    wire stop_pulse;              // STOP单周期脉冲

    reg prev_clk_active;          // 前时钟参考激活标志
    reg next_clk_active;          // 后时钟参考激活标志

    // =========================================================================
    // 信号延迟和边沿检测
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            start_sync_d <= 2'b00;
            stop_sync_d <= 2'b00;
        end else begin
            start_sync_d <= {start_sync_d[0], start_sync};
            stop_sync_d <= {stop_sync_d[0], stop_sync};
        end
    end

    // 检测上升沿（单周期脉冲）
    assign start_pulse = start_sync && !start_sync_d[0];
    assign stop_pulse = stop_sync && !stop_sync_d[0];

    // =========================================================================
    // 前时钟参考生成 (TDC-A)
    // 生成PWM上升沿前最近的时钟边沿信号
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            prev_clk_ref <= 1'b0;
            prev_clk_active <= 1'b0;
        end else begin
            if (start_pulse) begin
                // 检测到PWM上升沿，激活前时钟参考
                prev_clk_active <= 1'b1;
                prev_clk_ref <= 1'b0;
            end else if (prev_clk_active) begin
                // 生成一个时钟周期的参考脉冲
                prev_clk_ref <= ~prev_clk_ref;
                if (prev_clk_ref) begin
                    // 脉冲结束，去激活
                    prev_clk_active <= 1'b0;
                    prev_clk_ref <= 1'b0;
                end
            end else begin
                prev_clk_ref <= 1'b0;
            end
        end
    end

    // =========================================================================
    // 后时钟参考生成 (TDC-B)
    // 生成PWM下降沿后最近的时钟边沿信号
    // =========================================================================

    always @(posedge clk_400m or negedge rst_n) begin
        if (!rst_n) begin
            next_clk_ref <= 1'b0;
            next_clk_active <= 1'b0;
        end else begin
            if (stop_pulse) begin
                // 检测到PWM下降沿，设置标志等待下一个时钟
                next_clk_active <= 1'b1;
                next_clk_ref <= 1'b0;
            end else if (next_clk_active && !next_clk_ref) begin
                // 在下一个时钟上升沿生成参考脉冲
                next_clk_ref <= 1'b1;
            end else if (next_clk_active && next_clk_ref) begin
                // 脉冲结束，去激活
                next_clk_active <= 1'b0;
                next_clk_ref <= 1'b0;
            end else begin
                next_clk_ref <= 1'b0;
            end
        end
    end

    // =========================================================================
    // 时序说明
    // =========================================================================
    //
    // TDC-A时序:
    // PWM上升沿:     ___|‾‾‾|________________
    // prev_clk_ref:  _______|‾|_______________
    //                ↑       ↑
    //            PWM上升沿  前时钟参考
    //
    // TDC-B时序:
    // PWM下降沿:     ________________|‾‾‾|___
    // next_clk_ref:  _______________|‾|______
    //                                ↑
    //                            后时钟参考
    //
    // 测量目标:
    // a = prev_clk_ref到PWM上升沿的时间
    // b = PWM下降沿到next_clk_ref的时间
    //

endmodule