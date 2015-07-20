function [pf_test,pd_test,pd]=detect_pf_unknow_colornoise(T,snr,pf)
%%%detect_pf_unknow__colornoise: 检测随机相位、频率信号---Monte Carlo 仿真(不进行预白化---跟WGN处理方法一样，只是噪声变成有色噪声即可)
%%%input                    T-----------观测时间
%%%                         snr---------信噪比(信号平均功率与噪声平均功率之比)，用数值表示10^(snr/10)
%%%                         pf----------限定的虚警概率  pf<=0.01
%%%output                   pd----------理论的正确检测概率
%%%                         pf_test-----仿真实验得到的虚警概率
%%%                         pd_test-----仿真实验得到的正确检测概率
%%%by tanjunhong,2011,6,30
%%%modified on 7.1,2011

% pf=0.01,T=0.01,snr=-5     %test this function

%%----信号参数设置----------------------------------------
fs=4000;                  %对接收数据的采样频率
ts=1/fs;                  %采样时间间隔
N=T/ts;                   %观测数据个数
t=(1:N)'*ts;              %采样时刻的列矢量
%%----色噪声功率谱参数设置---------------------------------
k=0.1;fm=200;f0=260;

%%%----求理论的正确检测概率--------------------------------
snr=10^(snr/10);          %信噪比Ps/Pn
d=sqrt(snr*N);            %d=sqrt(Ps*N/Pn)：由信噪比表示d
z0=sqrt(-2*log(pf));      %由虚警概率pf反求z0  
pd=marcumq(d,z0);         %理论的正确检测概率值----马库姆Q函数




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%  确定高斯噪声方差（信号幅度一定，改变噪声功率以满足信噪比）  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A=1;                      %信号幅度
% Ps=A^2/2;                 %信号的平均功率
% Es=Ps*T;                  %信号的能量
% Pn=Ps/snr;                 %噪声的平均功率
% sigma=sqrt(Pn);           %噪声的标准差（均值为0）
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  确定信号幅度（噪声功率不变，改变信号幅度以满足信噪比） %%%%%%%
Pn=1.8874;                  %噪声的平均功率
Ps=Pn*snr;                  %信号的平均功率
Es=Ps*T;                    %信号的能量
A=sqrt(Ps*2);               %信号幅度


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%  仿真相关器参考信号  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fl=220;                   %信号频率范围fl~fh
fh=260;
M=15;
f=linspace(fl,fh,M+1);    %将fl-fh范围划分成M个区域
f=f(2:end);               %信号频率具有的M个可能值

for m=1:M
    gs(:,m)=A*sin(2*pi*f(m)*t);      %相关器1参考信号矢量
    gc(:,m)=A*cos(2*pi*f(m)*t);      %
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%  确定仿真门限     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Z0=z0*sqrt(Pn*Es*ts);       %理论门限  n0*Es=Pn/fs*Ps*T=Pn*Ps*T*ts
Z0=z0*sqrt(Pn*Es*ts)*1.9;       %修改门限  n0*Es=Pn/fs*Ps*T=Pn*Ps*T*ts


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%   Monte Carlo  仿真   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pf_test=0;
pd_test=0;
N_exp=5000;                    %仿真次数
for ii=1:N_exp
    %%%%%%       仿真噪声信号      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    wn=color_produce(k,fm,f0,N);
%     Dn=wn'*wn/N;
%     wn=sigma*wn/sqrt(Dn);      %产生符合信噪比的噪声信号(信号幅度A=1时，需改变噪声方差以满足给定的信噪比)
    %%%%%%  仿真随机相位、频率信号  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fc=fl+(fh-fl)*rand(1);     %信号的随机频率
    phi=2*pi*rand(1);          %信号的随机相位
    s=A*sin(2*pi*fc*t+phi);    %列信号矢量
    
    %%% H1假设下
    x1=s+wn;
    GS1=gs'*x1*ts;             %相关器输出：M*1列矢量
    GC1=gc'*x1*ts;
    Z_1=sqrt(GS1.^2+GC1.^2);   %检测统计量
    if max(Z_1)>Z0
        pd_test=pd_test+1;
    end
    
    %%%% H0假设下
    x0=wn;
    GS0=gs'*x0*ts;             %相关器输出
    GC0=gc'*x0*ts;
    Z_0=sqrt(GS0.^2+GC0.^2);   %检测统计量
    if max(Z_0)>Z0
        pf_test=pf_test+1;
    end
    
end
pf_test=pf_test/N_exp;
pd_test=pd_test/N_exp;

% pd,pd_test,pf_test

