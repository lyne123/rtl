`timescale 1ns / 1ps

module tdc_top #(
    parameter COARSE_WIDTH = 24,  // 粗计数位宽，支持大范围测量
    parameter FINE_WIDTH = 8       // 细计数位宽
)(
    input wire clk,                // 系统时钟
    input wire rst_n,              // 复位
    input wire pwm,                // PWM输入信号
    output wire [COARSE_WIDTH+FINE_WIDTH-1:0] timestamp, // 完整时间戳
    output wire valid              // 数据有效
);

    // 内部信号
    wire [COARSE_WIDTH-1:0] coarse_count;
    wire [FINE_WIDTH-1:0] fine_count;
    wire hit_sync;
    wire fine_valid;

    // 同步PWM信号到时钟域
    sync_ff u_sync (
        .clk(clk),
        .rst_n(rst_n),
        .async_in(pwm),
        .sync_out(hit_sync)
    );

    // 粗计数器
    coarse_counter #(
        .WIDTH(COARSE_WIDTH)
    ) u_coarse (
        .clk(clk),
        .rst_n(rst_n),
        .count(coarse_count)
    );

    // 进位链TDC
    carry_chain_tdc #(
        .WIDTH(FINE_WIDTH)
    ) u_fine (
        .clk(clk),
        .rst_n(rst_n),
        .hit(hit_sync),
        .fine_out(fine_count),
        .valid(fine_valid)
    );

    // 时间戳对齐和纠错
    timestamp_aligner #(
        .COARSE_WIDTH(COARSE_WIDTH),
        .FINE_WIDTH(FINE_WIDTH)
    ) u_align (
        .clk(clk),
        .rst_n(rst_n),
        .coarse_in(coarse_count),
        .fine_in(fine_count),
        .fine_valid(fine_valid),
        .timestamp(timestamp),
        .valid(valid)
    );

endmodule

// 同步触发器链
module sync_ff (
    input wire clk,
    input wire rst_n,
    input wire async_in,
    output reg sync_out
);
    reg sync_q1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_q1 <= 1'b0;
            sync_out <= 1'b0;
        end else begin
            sync_q1 <= async_in;
            sync_out <= sync_q1;
        end
    end
endmodule

// 粗计数器
module coarse_counter #(
    parameter WIDTH = 24
)(
    input wire clk,
    input wire rst_n,
    output reg [WIDTH-1:0] count
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= {WIDTH{1'b0}};
        else
            count <= count + 1'b1;
    end
endmodule

// 进位链TDC实现
module carry_chain_tdc #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire hit,
    output reg [WIDTH-1:0] fine_out,
    output reg valid
);

    // 使用FPGA进位链实现延迟
    wire [WIDTH:0] carry_chain;

    assign carry_chain[0] = hit;

    // 生成进位链
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : carry_delay
            CARRY4 carry_inst (
                .CO(carry_chain[i+1:i+1]), // 进位输出
                .O(),                      // 和输出（不使用）
                .CI(i == 0 ? 1'b0 : carry_chain[i]), // 进位输入
                .CYINIT(1'b0),
                .DI(4'b0000),
                .S(4'b1111)
            );
        end
    endgenerate

    // 采样进位链状态
    reg [WIDTH:0] sampled_chain;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sampled_chain <= {(WIDTH+1){1'b0}};
            fine_out <= {WIDTH{1'b0}};
            valid <= 1'b0;
        end else begin
            sampled_chain <= carry_chain;
            valid <= 1'b1;

            // 温度计码转二进制（改进版本）
            fine_out <= therm_to_bin(sampled_chain);
        end
    end

    // 温度计码转二进制函数（更鲁棒）
    function [WIDTH-1:0] therm_to_bin;
        input [WIDTH:0] therm;
        reg [WIDTH-1:0] count;
        integer j;
    begin
        count = 0;
        // 统计1的个数，但需要检测跳变点
        for (j = 0; j < WIDTH; j = j + 1) begin
            if (therm[j] && !therm[j+1]) begin
                count = j + 1;
            end
        end
        therm_to_bin = count;
    end
    endfunction

endmodule

// 时间戳对齐器（改进的纠错逻辑）
module timestamp_aligner #(
    parameter COARSE_WIDTH = 24,
    parameter FINE_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [COARSE_WIDTH-1:0] coarse_in,
    input wire [FINE_WIDTH-1:0] fine_in,
    input wire fine_valid,
    output reg [COARSE_WIDTH+FINE_WIDTH-1:0] timestamp,
    output reg valid
);

    reg [COARSE_WIDTH-1:0] coarse_q1, coarse_q2;
    reg [FINE_WIDTH-1:0] fine_q1, fine_q2;
    reg valid_q1, valid_q2;

    // 两级同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            coarse_q1 <= {COARSE_WIDTH{1'b0}};
            coarse_q2 <= {COARSE_WIDTH{1'b0}};
            fine_q1 <= {FINE_WIDTH{1'b0}};
            fine_q2 <= {FINE_WIDTH{1'b0}};
            valid_q1 <= 1'b0;
            valid_q2 <= 1'b0;
        end else begin
            coarse_q1 <= coarse_in;
            fine_q1 <= fine_in;
            valid_q1 <= fine_valid;

            coarse_q2 <= coarse_q1;
            fine_q2 <= fine_q1;
            valid_q2 <= valid_q1;
        end
    end

    // 改进的纠错逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timestamp <= {(COARSE_WIDTH+FINE_WIDTH){1'b0}};
            valid <= 1'b0;
        end else if (valid_q2) begin
            // 更精确的边界判断
            if (fine_q2 > (2**(FINE_WIDTH-1))) begin
                // 细计数大于一半，说明在时钟周期前半段
                timestamp <= {(coarse_q2 - 1'b1), fine_q2};
            end else begin
                // 细计数小于等于一半，直接使用
                timestamp <= {coarse_q2, fine_q2};
            end
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule