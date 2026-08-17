%QPSK传输系统仿真
%设置参数-产生随机码元序列。串并转换-星座映射-脉冲成型-调制（上变频）-AWGN信道-解调（下变频）-匹配滤波接收-抽样判决-并串转换
%比较分析；发送端星座图，成型波形与PSD。叠加噪声与PSD，解调输出波形与PSD，眼图，接收端星座图，统计误码率
clc;
clear all;
close all;

%%设置参数%%
L_Desq=100000; %码元个数（误码率统计时数据长度足够长）
Fb=10e3;     %码元速率
Fs=400e3;    %采样频率
fc=100e3;    %载波频率
EbN0=10;     %比特信噪比（dB形式）

%% 生成码元序列，串并转换%%
Ms=4;                       %进制数
Desq=randi(Ms,1,L_Desq)-1;  %产生码元（0，1，2，3）

%%星座映射%%
SigBase=pskmod(Desq,Ms,pi/4,'gray');   %psk映射（输出复包络，格雷码）
SigBaseI=real(SigBase);                %复包络的实部（同向分量I）
SigBaseQ=imag(SigBase);                %复包络的虚部（正交分量Q）
%画出发送端星座图
figure(1);
subplot(121);plot(SigBaseI,SigBaseQ,'*');grid on;xlabel('实部');ylabel('虚部');
title('发送端星座图 ');axis([-1.5 1.5 -1.5 1.5]);

%%脉冲成型%%
span=20;     %当前码元影响周围码元的个数
Nsam=Fs/Fb;  %每个码元周期的采样次数
R=0.5;       %滚降系数
hsqrt=rcosdesign(R,span,Nsam,'sqrt');    %设计根升余弦脉冲成型滤波器
SigbaseInterpI=upsample(SigBaseI,Nsam);  %上采样，内插0，冲激脉冲
SigbaseInterpQ=upsample(SigBaseQ,Nsam);  
SigI=conv(SigbaseInterpI,hsqrt,'same');  %与ht卷积，脉冲成型
SigQ=conv(SigbaseInterpQ,hsqrt,'same');
figure(2);
subplot(421);plot(SigI(1:Nsam*10));grid on;title('I基带信号成形波形');
subplot(423);plot(SigQ(1:Nsam*10));grid on;title('Q基带信号成形波形');
%画功率谱（pwelch计算单边谱）
subplot(422);pf1=pwelch(SigI,[],[],[]);plot(10*log10(pf1),'.-');grid on;title('I基带信号功率谱');
subplot(424);pf1=pwelch(SigQ,[],[],[]);plot(10*log10(pf1),'.-');grid on;title('Q基带信号功率谱');

%%调制（上变频）%%
SigPassBandI=SigI.*cos(2*pi*fc*(0:length(SigI)-1)/Fs);
SigPassBandQ=SigQ.*(-sin(2*pi*fc*(0:length(SigI)-1)/Fs));
figure(3);
subplot(421);plot(SigPassBandI(1:Nsam*10));grid on;title('I带通信号波形');
subplot(423);plot(SigPassBandQ(1:Nsam*10));grid on;title('Q带通信号波形');
subplot(422);pf1=pwelch(SigPassBandI,[],[],[]);plot(10*log10(pf1),'.-');grid on;title('I带通信号功率谱');
subplot(424);pf1=pwelch(SigPassBandQ,[],[],[]);plot(10*log10(pf1),'.-');grid on;title('Q带通信号功率谱');
% figure;pf1=pwelch(SigPassBandQ,[],[],[]);plot(10*log10(pf1),'.-');grid on;
SigPassBand=SigPassBandI+SigPassBandQ;
subplot(425);plot(SigPassBand((1:Nsam*10)),'-');grid on;title('带通信号波形');
subplot(426);pf1=pwelch(SigPassBand,[],[],[]);plot(10*log10(pf1),'.-');grid on;title('带通信号功率谱');

%%AWGN信道%%（I.Q信号相加之后加噪声）
Snr=EbN0-10*log10(Nsam/2)+10*log10(log2(Ms));    %比特信噪比换算
SigPassBand=awgn(SigPassBand,Snr,'measured');    %加入高斯白噪声
subplot(427);plot(SigPassBand((1:Nsam*10)),'-');grid on;title('加噪带通信号波形');
subplot(428);pf1=pwelch(SigPassBand,[],[],[]);plot(10*log10(pf1),'.-');grid on;title('加噪带通信号功率谱');

%%解调（下变频）%%（乘以2的作用是使得解调后信号与原始基带信号幅度相同，即使得判决电平与映射电平相一致）
SigBaseDownI=2*SigPassBand.*cos(2*pi*fc*(0:length(SigPassBand)-1)/Fs);   %频谱搬移
SigBaseDownQ=2*SigPassBand.*(-sin(2*pi*fc*(0:length(SigPassBand)-1)/Fs));

%%接收滤波（匹配滤波）%%（接收滤波器也是低通滤波器，所以代码中可以省去带通滤波器和解调器的低通滤波器）
SigBaseDownI=conv(SigBaseDownI,hsqrt,'same');   %匹配滤波接收
SigBaseDownQ=conv(SigBaseDownQ,hsqrt,'same');
figure (2)
subplot(425);plot(SigBaseDownI(1:Nsam*10),'-');grid on;title('I解调输出波形');              %画出解调基带信号波形
subplot(426);pf1=pwelch(SigBaseDownI,[],[],[]);plot(10*log10(pf1),'.-');grid on;title('I解调输出信号功率谱');
subplot(427);plot(SigBaseDownQ(1:Nsam*10),'-');grid on;title('Q解调输出波形');              %画出解调基带信号波形
subplot(428);pf1=pwelch(SigBaseDownQ,[],[],[]);plot(10*log10(pf1),'.-');grid on;title('Q解调输出信号功率谱');
eyediagram(SigBaseDownI(1:10000),1*Nsam);title('I接收端眼图');                              %画出接收滤波后眼图（一个码元周期）
eyediagram(SigBaseDownQ(1:10000),1*Nsam);title('Q接收端眼图');                              %画出接收滤波后眼图（一个码元周期）

%%抽样%%
SigBaseEstI=downsample(SigBaseDownI,Nsam);    %最佳采样点抽样（下采样downsample）
SigBaseEstQ=downsample(SigBaseDownQ,Nsam); 
%画出接收端星座图
figure(1);
subplot(122);plot(SigBaseEstI,SigBaseEstQ,'*');grid on;xlabel('实部');ylabel('虚部');
title('接收端星座图');axis([-2 2 -2 2]);

%%判决%%
SigBaseEst=SigBaseEstI+SigBaseEstI*1i;  %复包络
Sig_dn=Desq(1:end);                     %发送符号序列
Sig_xn=SigBaseEst(1:end);
Sig_xn=pskdemod(Sig_xn,Ms,pi/4,'gray'); %判决，输出复包络的判决符号序列

%%并串转换%%误码率%%
[SymErrNum,Ser_est]=symerr(Sig_dn,Sig_xn)       %误码率统计值
[BitErrNum,Ber_est]=biterr(Sig_dn,Sig_xn,log2(Ms))  %误信率统计值
[BER,SER]=berawgn(EbN0,'psk',Ms,'nondiff')       %由berawgn函数计算误码率理论值