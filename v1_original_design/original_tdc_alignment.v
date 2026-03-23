module tdc_alignment_core (
    input  wire        clk,            // 系统同步时钟 (Tx的基准)
    input  wire        rst_n,          // 复位信号
    input  wire        hit,            // 异步输入信号 (PWM边沿)
    input  wire [7:0]  fine_in,        // 细计时(进位链)解码后的量化值
    input  wire        fine_valid,     // 细计时数据有效标志
    output reg  [31:0] final_timestamp // 最终完美拼接的时间戳
);

    // 1. 粗计数器：一直在同步时钟下自由运行
    reg [31:0] coarse_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) coarse_cnt <= 0;
        else        coarse_cnt <= coarse_cnt + 1;
    end

    // 2. 数据捕获与抗亚稳态打拍 (你同门只做到了这一步，且没做完)
    reg [31:0] coarse_snap_q1, coarse_snap_q2;
    reg [7:0]  fine_snap_q1, fine_snap_q2;
    reg        valid_q1, valid_q2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            coarse_snap_q1 <= 0; coarse_snap_q2 <= 0;
            fine_snap_q1   <= 0; fine_snap_q2   <= 0;
            valid_q1 <= 0; valid_q2 <= 0;
        end else begin
            // 第一拍：锁存发生 Hit 时的粗、细计数值
            coarse_snap_q1 <= coarse_cnt;
            fine_snap_q1   <= fine_in;
            valid_q1       <= fine_valid;

            // 第二拍：打拍消除跨时钟域带来的亚稳态 (Metastability)
            coarse_snap_q2 <= coarse_snap_q1;
            fine_snap_q2   <= fine_snap_q1;
            valid_q2       <= valid_q1;
        end
    end

    // ---------------------------------------------------------
    // 3. 核心纠错逻辑：这就是"降维打击"的地方
    // 假设 fine_in 的满量程对应一个完整的 clk 周期 Tx (例如0~127)
    // 那么 fine_in 的最高位 (MSB = fine_snap_q2[7]) 就是一个天然的"半周期指示器"
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_timestamp <= 0;
        end else if (valid_q2) begin

            // 差一纠错判断 (Off-by-One Correction)
            // 如果 MSB 为 1，说明 hit 发生在时钟周期的前半段（离上一个 clk 沿近）
            // 此时粗计数器大概率由于布线延迟还没有来得及 +1，我们要主动借位补偿
            if (fine_snap_q2[7] == 1'b1) begin
                // 拼接时，粗计数主动减 1，完美修复对齐误差
                final_timestamp <= { (coarse_snap_q2 - 1'b1), fine_snap_q2 };

            // 如果 MSB 为 0，说明 hit 发生在时钟周期的后半段（离当前 clk 沿近）
            // 此时粗计数器的状态已经稳定，可以直接信任，无需补偿
            end else begin
                // 直接拼接
                final_timestamp <= { coarse_snap_q2, fine_snap_q2 };
            end
        end
    end

endmodule