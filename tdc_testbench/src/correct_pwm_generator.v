
//生成相位在 144° 的 400MHz 时钟，配合 ODDR 实现 1.25ns 步进的 PWM 输出
//输入 duty_slots 定义高电平持续的时间片数量，每个时间片为 1.25ns
//例如：duty_slots=2 代表高电平持续 2.5ns，duty_slots=3 代表高电平持续 3.75ns，以此类推，最大支持 40 个时间片（50ns 周期） 
module pwm_auto_cycle_scan (
    input  wire        clk_400m_144deg, // 400MHz, 静态移相144° (提供1ns起始偏移)
    input  wire        rst_n,
    output wire        pwm_out
);

    // --- 1. 20MHz 周期计数器 (50ns) ---
    reg [4:0] pwm_period_cnt; 

    // --- 2. 步进速度控制器 (分频器) ---
    // 如果想要肉眼/普通示波器看到变宽过程，需要让它变慢
    // 假设每 1000 个 PWM 周期（即 50us）脉宽增加 1.25ns
    reg [15:0] step_prescaler;
    parameter  STEP_RATE = 16'd0; 

    // --- 3. 内部占空比寄存器 (1.25ns ~ 48.75ns) ---
    reg [5:0] duty_slots_internal; 

    always @(posedge clk_400m_144deg or negedge rst_n) begin
        if (!rst_n) begin
            pwm_period_cnt      <= 5'd0;
            step_prescaler      <= 16'd0;
            duty_slots_internal <= 6'd1;  // 从 1.25ns 开始
        end else begin
            if (pwm_period_cnt == 5'd19) begin // 每到一个 PWM 周期末尾
                pwm_period_cnt <= 5'd0;
                
                // 速度控制逻辑
                if (step_prescaler >= STEP_RATE) begin
                    step_prescaler <= 16'd0;
                    
                    // --- 核心：达到最大值后从头开始 ---
                    if (duty_slots_internal >= 6'd39) begin
                        duty_slots_internal <= 6'd1;  // 回到 1.25ns
                    end else begin
                        duty_slots_internal <= duty_slots_internal + 1'b1; // 增加 1.25ns
                    end
                end else begin
                    step_prescaler <= step_prescaler + 1'b1;
                end
                
            end else begin
                pwm_period_cnt <= pwm_period_cnt + 1'b1;
            end
        end
    end

    // --- 4. 这里的逻辑保持不变 (1.25ns 精细切分) ---
    wire [5:0] slot_idx_d1 = {pwm_period_cnt, 1'b0};      
    wire [5:0] slot_idx_d2 = {pwm_period_cnt, 1'b0} | 6'd1; 

    reg d1_reg, d2_reg;
    always @(posedge clk_400m_144deg or negedge rst_n) begin
        if (!rst_n) begin
            d1_reg <= 1'b0; d2_reg <= 1'b0;
        end else begin
            d1_reg <= (slot_idx_d1 < duty_slots_internal);
            d2_reg <= (slot_idx_d2 < duty_slots_internal);
        end
    end

    // --- 5. ODDR 硬件原语 ---
    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"), // 允许在同一上升沿抓取 D1 和 D2
        .INIT(1'b0),
        .SRTYPE("SYNC")
    ) ODDR_inst (
        .Q  (pwm_out),          // 直接连接到 FPGA 输出引脚
        .C  (clk_400m_144deg),  // 带有 1ns 物理相移的 400MHz 时钟
        .CE (1'b1),
        .D1 (d1_reg),           // 周期内的前 1.25ns 状态
        .D2 (d2_reg),           // 周期内的后 1.25ns 状态
        .R  (1'b0),
        .S  (1'b0)
    );

endmodule