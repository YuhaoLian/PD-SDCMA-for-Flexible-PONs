function [BER1,BER2,BER3]  = Platform_NOMA_Rx(input)

load('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TransceiverPara\Len_Matlab.mat'); 

Rx_Sample = input.band.E(1: Len_Matlab);

%% ------------------ Rx Signal Processing -----------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
load('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TransceiverPara\OFDM_Para.mat'); 
[BER,SER,RX] = NOMA_OFDM_Rx(OFDM_Para,Rx_Sample);

BER1 = BER(1);
BER2 = BER(2);
BER3= BER(3);
