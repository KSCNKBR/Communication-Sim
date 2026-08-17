%% QPSK 调制解调仿真（修正版）
% 直接在符号级加 AWGN，避免 rectpulse/intdump 带来的 SNR 换算问题
% 2026-08-16

clear; clc; close all;

%% 参数设置
M = 4;                  % QPSK
k = log2(M);            % 每符号比特数 = 2
EbNo = 0:2:12;          % 信噪比范围 (dB)
numBits = 2e6;          % 总比特数（加大样本量，保证高信噪比下有统计意义）
numSym = numBits / k;   % 总符号数

%% 1. 信源
dataBits = randi([0 1], numBits, 1);

%% 2. QPSK 调制（格雷编码）
% 00 -> 1+j, 01 -> -1+j, 11 -> -1-j, 10 -> 1-j
symMap = [1+1j; -1+1j; -1-1j; 1-1j];
bitGroups = bi2de(reshape(dataBits, k, numSym)', 'left-msb');
txSymbols = symMap(bitGroups + 1);

%% 3. AWGN 信道 + 解调 + BER 统计
ber_sim = zeros(size(EbNo));
ber_theory = zeros(size(EbNo));

for idx = 1:length(EbNo)
    % 直接在符号上加复高斯噪声
    % QPSK: 每符号能量 Es = |1+j|^2 = 2
    % 每比特能量 Eb = Es/k = 1
    % N0 = Eb / 10^(EbNo/10)
    % 复噪声: n = nI + j*nQ, 方差(Var) = N0/2 每个维度
    
    EbNo_lin = 10^(EbNo(idx)/10);
    N0 = 1 / EbNo_lin;              % 因为 Eb = 1
    noiseVar = N0 / 2;              % 每个维度噪声方差
    noise = sqrt(noiseVar) * (randn(numSym, 1) + 1j * randn(numSym, 1));
    
    rxSymbols = txSymbols + noise;
    
    % 判决解调（最小距离判决）
    rxBits = zeros(numBits, 1);
    for i = 1:numSym
        sym = rxSymbols(i);
        % 根据实部和虚部符号判决
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
    
    % QPSK 理论比特误码率: Pb = 0.5 * erfc(sqrt(EbNo))
    ber_theory(idx) = 0.5 * erfc(sqrt(EbNo_lin));
end

%% 4. 结果可视化
figure('Color', 'w', 'Position', [100 100 900 650]);

% 星座图 (EbNo=8dB 示例)
subplot(2,2,1);
EbNo_demo = 8;
EbNo_demo_lin = 10^(EbNo_demo/10);
N0_demo = 1 / EbNo_demo_lin;
noiseVar_demo = N0_demo / 2;
noise_demo = sqrt(noiseVar_demo) * (randn(numSym, 1) + 1j * randn(numSym, 1));
rxSym_demo = txSymbols + noise_demo;
scatter(real(rxSym_demo(1:2000)), imag(rxSym_demo(1:2000)), 8, 'b', 'filled');
hold on;
plot([1,-1,-1,1,1], [1,1,-1,-1,1], 'r-', 'LineWidth', 1.5);
title(sprintf('QPSK 接收星座图 (EbNo=%ddB)', EbNo_demo));
xlabel('实部'); ylabel('虚部');
axis equal; grid on; xlim([-2 2]); ylim([-2 2]);

% BER 曲线
subplot(2,2,2);
semilogy(EbNo, ber_sim, 'bo-', 'LineWidth', 1.5, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
hold on;
semilogy(EbNo, ber_theory, 'r--', 'LineWidth', 1.5);
grid on; axis tight;
xlabel('Eb/No (dB)'); ylabel('误码率 BER');
title('QPSK BER 性能曲线');
legend('仿真', '理论', 'Location', 'southwest');
ylim([1e-6 1]);

% 发送信号时域（取前50个符号）
subplot(2,2,3);
t = 0:0.01:50;
txWave = zeros(size(t));
for i = 1:50
    idx_t = t >= (i-1) & t < i;
    txWave(idx_t) = real(txSymbols(i)) * cos(2*pi*t(idx_t)) - imag(txSymbols(i)) * sin(2*pi*t(idx_t));
end
plot(t(1:5000), txWave(1:5000), 'b-', 'LineWidth', 0.8);
title('QPSK 发送信号波形（前50符号）');
xlabel('符号周期'); ylabel('幅度');
grid on;

% 功率谱密度
subplot(2,2,4);
Fs = 16;                    % 采样率
sps_psd = 16;               % 每符号采样点数
txSig_psd = rectpulse(txSymbols(1:10000), sps_psd);
[pxx, f] = pwelch(txSig_psd, [], [], [], Fs, 'centered');
plot(f, 10*log10(pxx), 'b-', 'LineWidth', 1.2);
title('QPSK 信号功率谱密度');
xlabel('归一化频率'); ylabel('功率谱密度 (dB)');
grid on; xlim([-8 8]);

sgtitle('QPSK 通信系统仿真结果（修正版）', 'FontSize', 14, 'FontWeight', 'bold');

% 保存结果
saveas(gcf, 'QPSK_Result_Final.png');
fprintf('仿真完成！\\n');
for i = 1:length(EbNo)
    fprintf('EbNo = %2d dB: 仿真 BER = %.2e, 理论 BER = %.2e\\n', ...
        EbNo(i), ber_sim(i), ber_theory(i));
end