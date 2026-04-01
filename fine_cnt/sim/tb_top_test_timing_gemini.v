`timescale 1ps / 1fs  // 【核心重点】必须精确到皮秒(ps)，精度开到飞秒(fs)！

module tb_top_test_timing();

    // ==========================================
    // 1. 信号定义
    // ==========================================
    reg sys_clk;
    reg sys_rst_n;
    reg pwm_signal;
    wire [3:0] led_out;
    wire valid_out;
    
    // ==========================================
    // 2. 实例化顶层模块 (top_test)
    // 根据你的 XDC 约束推断的端口，如果有不同请自行修改
    // ==========================================
    top_test uut (
        .sys_clk    (sys_clk),
        .sys_rst_n  (sys_rst_n),
        .pwm_signal (pwm_signal),
        .led_out  (led_out) // 这里我们不关心 LED 输出，所以直接连接到常量  
    );

assign led_out = 4'b0000; // 这里我们不关心 LED 输出，所以直接连接到常量
    // ==========================================
    // 3. 产生 50MHz 系统主时钟
    // 周期 = 20ns = 20000ps -> 半周期 10000ps
    // ==========================================
    initial begin
        sys_clk = 0;
        forever #10000 sys_clk = ~sys_clk; 
    end

    // ==========================================
    // 4. 核心激励生成 (窄脉冲扫描测试)
    // ==========================================
    integer pulse_width;

    initial begin
        // 初始化信号
        sys_rst_n = 0;
        pwm_signal = 0;
        
        // 【避坑指南 1】：全局复位等待
        // 必须等 100ns 让底层全局复位网络 (GSR) 释放
        #100000; 
        sys_rst_n = 1;

        $display("Reset released. Waiting for MMCM to lock...");

        // 【避坑指南 2】：等待 MMCM 真实锁定
        // 在时序仿真中，PLL/MMCM 从 50MHz 倍频到 400MHz 需要很长的物理起振时间！
        // 如果不等它稳定就开始塞数据，TDC 采到的全是 X 态。
        // 这里强行等待 15us (15,000,000 ps)
        #15000000; 
        
        $display("MMCM Locked! Starting 200ps to 2500ps narrow pulse test...");

        // ==========================================
        // 自动扫描测试：从 200ps 扫到 2500ps，步进 100ps
        // ==========================================
        for (pulse_width = 200; pulse_width <= 2500; pulse_width = pulse_width + 100) begin
            
            // 对齐到 50MHz 系统时钟沿
            @(posedge sys_clk);
            
            // 【避坑指南 3】：极其关键的“不对齐偏移”
            // 你的内部工作时钟是 400MHz (周期 2500ps)。
            // 如果我们刚好在 0ps 或 2500ps 的倍数点产生脉冲，将会精准踩中触发器的采样沿！
            // 在时序仿真中，这会立刻触发 Setup/Hold Violation（建立保持违例），输出满屏的红线 (X态)。
            // 解决办法：加上一个不对齐的偏移量 (比如 1234ps)，错开危险区。
            #1234; 

            // 打印当前测试信息
            $display("-> Injecting Pulse Width: %0d ps", pulse_width);

            // 发送超窄脉冲
            pwm_signal = 1;
            #(pulse_width); // 核心：保持脉冲宽度为 pulse_width
            pwm_signal = 0;

            // 等待足够长的时间，让 TDC 处理完毕并输出结果 (等待 100ns)
            #100000; 
        end

        $display("All tests completed!");
        $finish; // 结束仿真
    end

endmodule