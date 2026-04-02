// 需先通过 Clocking Wizard 生成 4 个相位的 400MHz 时钟：
// clk_0, clk_90 (偏移 625ps), clk_180 (偏移 1250ps), clk_270 (偏移 1875ps)

module high_prec_async_pwm (
    input  wire        clk_0,      // 400MHz, 0 degree
    input  wire        clk_90,     // 400MHz, 90 degree
    input  wire        clk_180,    // 400MHz, 180 degree
    input  wire        clk_270,    // 400MHz, 270 degree
    input  wire        rst_n,
    output reg         pwm_out
);

    // 1. LFSR 产生随机数 (控制占空比、整数延迟、分数相位)
    reg [15:0] lfsr;
    always @(posedge clk_0 or negedge rst_n) begin
        if (!rst_n) lfsr <= 16'h55AA;
        else        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13]};
    end

    // 2. 参数提取
    wire [4:0] rand_duty  = (lfsr[4:0] % 19) + 1; // 1~19个周期 (5%~95%)
    wire [2:0] rand_wait  = lfsr[7:5];             // 0~7个周期的粗延迟
    wire [1:0] rand_phase = lfsr[9:8];             // 选择 4 种相位

    // 3. 状态机控制
    reg [5:0] cnt;
    reg [3:0] state;
    localparam S_PWM = 0, S_WAIT = 1;

    // 为了在不同相位间切换而不产生毛刺，我们在 clk_0 下生成使能信号
    // 然后用选中的相位时钟去采样这个信号
    reg pwm_en;
    always @(posedge clk_0 or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            pwm_en <= 0;
            state <= S_PWM;
        end else begin
            case(state)
                S_PWM: begin
                    if (cnt < 19) begin
                        cnt <= cnt + 1;
                        pwm_en <= (cnt < rand_duty);
                    end else begin
                        cnt <= 0;
                        pwm_en <= 0;
                        state <= S_WAIT;
                    end
                end
                S_WAIT: begin
                    if (cnt < rand_wait) begin
                        cnt <= cnt + 1;
                    end else begin
                        cnt <= 0;
                        state <= S_PWM;
                    end
                end
            endcase
        end
    end

    // 4. 非对齐相位产生 (关键部分)
    // 根据随机结果选择不同的时钟来输出信号
    reg pwm_p0, pwm_p90, pwm_p180, pwm_p270;
    always @(posedge clk_0)   pwm_p0   <= pwm_en;
    always @(posedge clk_90)  pwm_p90  <= pwm_en;
    always @(posedge clk_180) pwm_p180 <= pwm_en;
    always @(posedge clk_270) pwm_p270 <= pwm_en;

    // 最后的输出选择
    always @(*) begin
        case(rand_phase)
            2'b00: pwm_out = pwm_p0;   // 与时钟完全对齐
            2'b01: pwm_out = pwm_p90;  // 延迟 625ps (不对齐)
            2'b10: pwm_out = pwm_p180; // 延迟 1250ps (半个周期)
            2'b11: pwm_out = pwm_p270; // 延迟 1875ps (不对齐)
            default: pwm_out = pwm_p0;
        endcase
    end

endmodule