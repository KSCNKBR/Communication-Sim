% 清除数据
clear;clc;close all;
% 生成数据
x=0:0.1:2*pi;
y=sin(x);
% 绘图
plot(x,y,'b-','LineWidth',1.5);
title('测试');
xlabel('x');
ylabel('sin(x)');
grid on;% 添加网格线

