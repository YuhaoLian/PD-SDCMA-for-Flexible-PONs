function [output]= NOMA_OFDM_Tx(OFDM_Para)
%% OFDM_TX  OFDM传输机

%% ---------- OFDM Parameters
N_Symbol = OFDM_Para.N_Symbol;
N_frm = OFDM_Para.N_frm;
Nb_fft = OFDM_Para.Nb_fft;
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

%% OFDM数据产生
for user = 1:user_number
    [OFDM_signal(user,:),NOMA_Sym_FFT(:,:,user)] = OFDM_TX(OFDM_Para,strategy(user,:));
end

save('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TxComplexMat\NOMA_Sym_FFT', 'NOMA_Sym_FFT'); % save transmitted complex matrix
save('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TxComplexMat\OFDM_signal', 'OFDM_signal'); % save transmitted complex matrix

%% PD-NOMA合成
NOMA_OFDM = zeros(1,N_Symbol * N_fft * (1 + CP));
NOMA_OFDM_ZF = zeros(N_Symbol, N_fft);
for user = 1: user_number
    NOMA_OFDM = NOMA_OFDM + sqrt(power_allcation(user))* OFDM_signal(user,:);    
    NOMA_OFDM_ZF  = NOMA_OFDM_ZF+ sqrt(power_allcation(user))*NOMA_Sym_FFT(:,:,user);
end

save('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TxComplexMat\NOMA_OFDM_ZF', 'NOMA_OFDM_ZF'); % save transmitted complex matrix

%% ----------------------- Upsampling ----------------------------%
len = length(NOMA_OFDM);
NOMA_OFDM_fft = fft(NOMA_OFDM,len);
M_sampling = (M_upsampling-1)*len;
NOMA_OFDM_fft = [NOMA_OFDM_fft(1:len/2)  zeros(1,M_sampling) NOMA_OFDM_fft(len/2+1:len)];
NOMA_OFDM = real(ifft(NOMA_OFDM_fft));

%% 限幅减小均峰比
if Clipping_Agg ~= 0
    
    Sig_Temp = NOMA_OFDM;
    
     P_Agg_mean = mean(abs(Sig_Temp).^2,2);
     V_max = sqrt(10^(Clipping_Agg/10)*P_Agg_mean);    % Clipping stage, which defines the maximum amplitude values

    Sig_Upsampled = (Sig_Temp > V_max).*V_max + (Sig_Temp < (-V_max)).*(-V_max) + ...
                        ((Sig_Temp <= V_max) & (Sig_Temp >= (-V_max))).*Sig_Temp; 
end

%% ------------DAC---------------%
NOMA_OFDM = NOMA_OFDM - mean(NOMA_OFDM);         
V_max = max(abs(NOMA_OFDM));
        
% N_bits = 8; % 8-bits DAC/ADC
dv= V_max*2/(2^N_bits);
SigOut_DAC = (floor(Sig_Upsampled ./ dv) + 1/2) .* dv;
output = SigOut_DAC;
% output = NOMA_OFDM;  %%测试

end



