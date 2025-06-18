function [BER,SER,RX]= NOMA_OFDM_Rx(OFDM_Para,Rx_Sample)
%% OFDM_RX  OFDM接收机

%% ---------- OFDM Parameters
N_Symbol = OFDM_Para.N_Symbol;
N_frm = OFDM_Para.N_frm;
Nb_fft = OFDM_Para.Nb_fft;
CPshift = OFDM_Para.CPshift;                          % CP offset for OFDM demodulation
CP = OFDM_Para.CP;
ClippingRatio = OFDM_Para.ClippingRatio;
N_sc_used = OFDM_Para.N_sc_used;
N_fft = OFDM_Para.N_fft;
Bit_Loading_SC = OFDM_Para.Bit_Loading_SC;
Power_Loading_SC = OFDM_Para.Power_Loading_SC;
N_Bit_Symbol = OFDM_Para.N_Bit_Symbol;
BW_OFDM = OFDM_Para.BW_OFDM;
Clipping_Agg = OFDM_Para.Clipping_Agg;
user_number = OFDM_Para.user_number;
power_allcation = OFDM_Para.power_allcation;
strategy = OFDM_Para.strategy;
N_Dimension = OFDM_Para.N_Dimension;
M_upsampling =OFDM_Para.M_upsampling;
N_bits = OFDM_Para.N_bits;

%% --------------------ADC--------------------------%
ss = Rx_Sample;
ss = ss - mean(ss);
V_max = max(abs(ss));
d_V = 2 * V_max / 2^N_bits;
Rx_Sample = (floor(ss/d_V) + 1/2) * d_V; % ADC


%% ----------------------- Downsampling ----------------------------%
len = length(Rx_Sample) ;
Rx_Sample_fft = fft(Rx_Sample,len);
Rx_fft = [Rx_Sample_fft(1:len/M_upsampling/2) Rx_Sample_fft(len-len/M_upsampling/2+1:len)];
RX_Sample = real(ifft(Rx_fft));

RX = RX_Sample(1:N_Symbol * N_fft * (1 + CP));


%% NOMA-SIC解调
load('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TxComplexMat\NOMA_Sym_FFT.mat');
load('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TxComplexMat\NOMA_OFDM_ZF.mat');
SIC =zeros(1, N_Symbol *N_fft * (1 + CP));
NOMA_Rx_user = zeros(user_number, N_Symbol *N_fft * (1 + CP));
for user = 1:user_number
    if user == 1
        NOMA_Rx_user(user,:) = RX/sqrt(power_allcation(user));
    else
        NOMA_Rx_user(user,:) = (RX - SIC)/sqrt(power_allcation(user));
    end
    [BER(:,user),SER(:,user),demodSignal,Rx_Eq] = OFDM_RX(OFDM_Para,NOMA_Rx_user(user,:),NOMA_OFDM_ZF,strategy(user,:));
    if user == 1
        RX = SPMASignal_Recover(OFDM_Para,Rx_Eq);
    end
    [OFDM_signal_recover] = SIC_recover(OFDM_Para,demodSignal,strategy(user,:));
    SIC = SIC + sqrt(power_allcation(user)) * OFDM_signal_recover;
    NOMA_OFDM_ZF = NOMA_OFDM_ZF - sqrt(power_allcation(user)).*NOMA_Sym_FFT(:,:,user);
end
end