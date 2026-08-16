%% QPSK 调制解调仿真
% 完整的 QPSK 通信链路仿真
% 包含：调制、AWGN信道、解调、BER性能分析

clear; clc; close all;

%% 参数设置
M = 4;                  % QPSK，4进制
k = log2(M);            % 每符号比特数
EbNo = 0:2:12;          % 信噪比范围 (dB)
numBits = 1e5;          % 总比特数
numSym = numBits / k;   % 总符号数

%% 1. 信源：生成随机比特流
dataBits = randi([0 1], numBits, 1);

%% 2. 串并转换 + 符号映射（格雷编码）
dataSymbols = zeros(numSym, 1);
for i = 1:numSym
    bits = dataBits(2*i-1:2*i);
    if bits == [0; 0]
        dataSymbols(i) = 1 + 1j;
    elseif bits == [0; 1]
        dataSymbols(i) = -1 + 1j;
    elseif bits == [1; 1]
        dataSymbols(i) = -1 - 1j;
    else
        dataSymbols(i) = 1 - 1j;
    end
end

%% 3. 上采样（脉冲成型简化：矩形脉冲）
sps = 8;                % 每符号采样点数
txSignal = rectpulse(dataSymbols, sps);

%% 4. AWGN 信道 + 解调 + BER 统计
ber_sim = zeros(size(EbNo));
ber_theory = zeros(size(EbNo));

for idx = 1:length(EbNo)
    rxSignal = awgn(txSignal, EbNo(idx), 'measured');
    rxSymbols = intdump(rxSignal, sps);

    rxBits = zeros(numBits, 1);
    for i = 1:numSym
        sym = rxSymbols(i);
        if real(sym) >= 0 && imag(sym) >= 0
            rxBits(2*i-1:2*i) = [0; 0];
        elseif real(sym) < 0 && imag(sym) >= 0
            rxBits(2*i-1:2*i) = [0; 1];
        elseif real(sym) < 0 && imag(sym) < 0
            rxBits(2*i-1:2*i) = [1; 1];
        else
            rxBits(2*i-1:2*i) = [1; 0];
        end
    end

    [~, ber_sim(idx)] = biterr(dataBits, rxBits);
    ber_theory(idx) = erfc(sqrt(10^(EbNo(idx)/10)*k)) / k;
end

%% 5. 结果可视化
figure('Color', 'w', 'Position', [100 100 800 600]);

subplot(2,2,1);
rxSignal_demo = awgn(txSignal, 10, 'measured');
rxSym_demo = intdump(rxSignal_demo, sps);
scatter(real(rxSym_demo(1:1000)), imag(rxSym_demo(1:1000)), '.');
hold on;
plot([1,-1,-1,1,1], [1,1,-1,-1,1], 'r-', 'LineWidth', 1.5);
title('QPSK 接收星座图 (EbNo=10dB)');
xlabel('实部'); ylabel('虚部');
axis equal; grid on;

subplot(2,2,2);
semilogy(EbNo, ber_sim, 'bo-', 'LineWidth', 1.5, 'MarkerSize', 8);
hold on;
semilogy(EbNo, ber_theory, 'r--', 'LineWidth', 1.5);
grid on;
xlabel('Eb/No (dB)'); ylabel('误码率 BER');
title('QPSK BER 性能曲线');
legend('仿真', '理论', 'Location', 'southwest');

subplot(2,2,3);
t = (0:length(txSignal)-1)/sps;
plot(t(1:200), real(txSignal(1:200)), 'b-', 'LineWidth', 1);
hold on;
plot(t(1:200), imag(txSignal(1:200)), 'r--', 'LineWidth', 1);
title('QPSK 发送信号波形（前200采样点）');
xlabel('符号周期'); ylabel('幅度');
legend('I路', 'Q路'); grid on;

subplot(2,2,4);
[pxx, f] = pwelch(txSignal, [], [], [], sps, 'centered');
plot(f, 10*log10(pxx), 'b-', 'LineWidth', 1.5);
title('QPSK 信号功率谱密度');
xlabel('归一化频率'); ylabel('功率谱密度 (dB)');
grid on;

sgtitle('QPSK 通信系统仿真结果', 'FontSize', 14, 'FontWeight', 'bold');

saveas(gcf, 'QPSK_Simulation_Results.png');
disp('仿真完成！结果已保存为 QPSK_Simulation_Results.png');
