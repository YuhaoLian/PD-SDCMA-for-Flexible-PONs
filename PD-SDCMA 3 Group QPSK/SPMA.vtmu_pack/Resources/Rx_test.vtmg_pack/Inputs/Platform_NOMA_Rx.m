function output = Platform_NOMA_Rx(input)

load('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TransceiverPara\Len_Matlab.mat'); 

Rx_Sample = input.band.E(1: Len_Matlab);

%% ------------------ Rx Signal Processing -----------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
load('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TransceiverPara\OFDM_Para.mat'); 
[BER,SER,RX] = NOMA_OFDM_Rx(OFDM_Para,Rx_Sample);
plot(1:length(BER),BER);
output =input;