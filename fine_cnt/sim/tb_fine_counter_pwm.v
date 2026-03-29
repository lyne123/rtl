/**
 * ϸ������ PWM �������ƽ̨
 * ���ɾ��� 0-2.5ns �����λ�� PWM �������ڲ���
 */

module tb_fine_counter_pwm;

// ��������
parameter CLK_400M_PERIOD = 2.5;  // 400MHz ʱ������ (2.5ns)
parameter PWM_PERIOD = 100;        // PWM ���� (100ns = 10MHz)
parameter SIM_TIME = 1000;         // ����ʱ�� (1000ns)

// �ź�����
reg clk_400m;
reg rst_n;
reg pwm_signal;
wire [6:0] fine_count_a;
wire [6:0] fine_count_b;
wire valid_out;

// �����λ����
real random_phase;
integer seed;

// ʵ��������ģ��
fine_counter_carry4 uut (
    .clk_400m(clk_400m),
    .rst_n(rst_n),
    .pwm_signal(pwm_signal),
    .fine_count_a(fine_count_a),
    .fine_count_b(fine_count_b),
    .valid_out(valid_out)
);

// 400MHz ʱ������
initial begin
    clk_400m = 1'b0;
    forever #(CLK_400M_PERIOD/2) clk_400m = ~clk_400m;
end

// �������������ʼ��
initial begin
    seed = 32'h12345678;  // ʹ�ù̶����ӣ���ʹ�� $random ��Ĭ������
end

// ���������λ�� PWM �ź�
task generate_random_pwm;
    input real phase_offset;
    real high_time;
    real low_time;
    begin
        // ���������λƫ�� (0-2.5ns)
        random_phase = phase_offset;

        // ����ߵ�ƽ�͵͵�ƽʱ��
        high_time = PWM_PERIOD/2 + random_phase;
        low_time = PWM_PERIOD/2 - random_phase;

        // ȷ��ʱ�䲻Ϊ��
        if (low_time < 0) begin
            high_time = PWM_PERIOD/2;
            low_time = PWM_PERIOD/2;
        end

        // ���� PWM ����
        pwm_signal = 1'b1;
        #high_time;
        pwm_signal = 1'b0;
        #low_time;
    end
endtask

// �����Գ���
initial begin
    // ��ʼ״̬
    rst_n = 1'b0;
    pwm_signal = 1'b0;

    // ��λ�ͷ�
    #20;
    rst_n = 1'b1;

    $display("��ʼ PWM �������...");
    $display("ʱ������: %0.1f ns", CLK_400M_PERIOD);
    $display("PWM ����: %0.1f ns", PWM_PERIOD);

    // ���ɶ����ͬ��λ�� PWM ����
    repeat(20) begin
        // ���� 0-2.5ns �������λƫ��
        random_phase = {$random(seed)} % 2500 / 1000.0; // 0-2.5ns

        $display("���� PWM - ��λƫ��: %0.3f ns", random_phase);

        // ����һ�� PWM ����
        generate_random_pwm(random_phase);

        // ����һЩ���ʱ��
        #10;
    end

    // ���� PWM �źŲ���
    $display("��ʼ���� PWM ����...");
    repeat(50) begin
        random_phase = {$random(seed)} % 2500 / 1000.0;
        generate_random_pwm(random_phase);
    end

    // ��������
    #100;
    $display("�������");
    $finish;
end

// ������
always @(posedge clk_400m) begin
    if (valid_out) begin
        $display("ʱ��: %0t ns, fine_count_a: %d, fine_count_b: %d",
                 $time, fine_count_a, fine_count_b);
    end
end

// ����ת��
initial begin
    $dumpfile("tb_fine_counter_pwm.vcd");
    $dumpvars(0, tb_fine_counter_pwm);

    // ת���ؼ��ź�
    $dumpvars(1, clk_400m);
    $dumpvars(1, rst_n);
    $dumpvars(1, pwm_signal);
    $dumpvars(1, fine_count_a);
    $dumpvars(1, fine_count_b);
    $dumpvars(1, valid_out);
end

// ����ʱ������
initial begin
    #SIM_TIME;
    $display("����ʱ��ﵽ %0d ns���Զ�����", SIM_TIME);
    $finish;
end

// ���Լ��
always @(posedge clk_400m) begin
    if (valid_out) begin
        // ������ֵ��Χ
        if (fine_count_a > 80) begin
            $error("fine_count_a ������Χ: %d", fine_count_a);
        end
        if (fine_count_b > 80) begin
            $error("fine_count_b ������Χ: %d", fine_count_b);
        end
    end
end

endmodule