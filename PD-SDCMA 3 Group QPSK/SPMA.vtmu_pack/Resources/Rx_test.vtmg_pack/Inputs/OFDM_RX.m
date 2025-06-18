function [ber,ser,ss_Mapping,Rx_Eq]= OFDM_RX(OFDM_Para, Rx_Sample,Tx_Sym_FFT,strategy)%% OFDM_RX  OFDM接收机

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
N_Dimension = OFDM_Para.N_Dimension;
Sub_group = OFDM_Para.Sub_group;
K_sc_used =OFDM_Para.K_sc_used;

%% 去除循环前缀 + FFT

for k = 1: N_frm
    Rx_Temp = vec2mat(Rx_Sample(k, :), N_fft*(1 + CP));
    Rx_Temp = Rx_Temp(:,N_fft * CP + 1 - CPshift: N_fft*(1 + CP) - CPshift); % cut the CP
    OFDM_Rx_LTE = fft(Rx_Temp, N_fft, 2)/N_fft;
    Rx_Sym_FFT(:, :, k) = OFDM_Rx_LTE;    
end

%% 信道估计
%----------------- Channel Estimation-------------------%

Rx_Sym_SC_Eq = zeros(size(Rx_Sym_FFT, 1), N_fft, N_frm);
Rx_figure = zeros(size(Rx_Sym_FFT, 1), N_fft, N_frm);

Rx_FFT = Rx_Sym_FFT;
% Rx_FFT = circshift(Rx_FFT, [0, ceil((N_sc_used)/2)]);
Rx = Rx_FFT;

Rx_figure(:, :) =  Rx;
Tx_FFT = Tx_Sym_FFT;
% Tx_FFT = circshift(Tx_FFT, [0, ceil((N_sc_used)/2)]);
Tx = Tx_FFT;
CRdata = mean(Rx./Tx, 1);
Rx_Eq = Rx.*repmat(conj(CRdata)./abs(CRdata).^2, size(Rx, 1), 1);
Rx_Sym_SC_Eq = Rx_Eq;

% figure(); plot(Rx_Sym_SC_Eq(:), '.');

%% MQAM解调检测
for k = 1: N_frm
    Mod_Bit = Bit_Loading_SC(3);
    data = Rx_Sym_SC_Eq(:,:,k);
    ss_Mapping = zeros(N_Symbol, N_fft);   %N_sc_used列

    for k_SC =  3:K_sc_used: K_sc_used*N_sc_used/2+2
        if ceil(strategy(1)/2) == ceil(strategy(2)/2)
            dec_sc = data (:, k_SC-1+ceil(strategy(1)/2));             
        else
            dec_sc = imag(data (:, k_SC-1+ceil(strategy(1)/2)))*i + real(data (:, k_SC-1+ceil(strategy(2)/2))); 
        end
            ss_Mapping(:, k_SC) = qamdemod(dec_sc, 2^Mod_Bit, 'gray');%格雷编码
            flag =  (k_SC + K_sc_used-3)/K_sc_used;
            Rx_bin_sc(:, Mod_Bit*flag - Mod_Bit +1 : Mod_Bit* flag ) = de2bi(ss_Mapping(:,k_SC), Mod_Bit,'left-msb');%从左开始由二进制比特转化为符号 
    end    
end

% 发送端符号
TXss_Mapping  = zeros(N_Symbol,N_fft);
for k_SC = 3:K_sc_used: K_sc_used*N_sc_used/2+2
    if ceil(strategy(1)/2) == ceil(strategy(2)/2)
        dec_sc = Tx (:, k_SC-1+ceil(strategy(1)/2));
    else
        dec_sc = imag(Tx (:, k_SC-1+ceil(strategy(1)/2)))*i + real(Tx (:, k_SC-1+ceil(strategy(2)/2)));
    end
    TXss_Mapping(:, k_SC) = qamdemod(dec_sc, 2^Mod_Bit, 'gray');%格雷编码
     flag =  (k_SC + K_sc_used-3)/K_sc_used;
    Tx_bin_sc(:, Mod_Bit*flag - Mod_Bit +1 : Mod_Bit* flag) = de2bi(TXss_Mapping(:, k_SC), Mod_Bit,'left-msb');
end   


% for k_SC = 1: N_sc_used
%         Tx_bin_sc(:, Mod_Bit*k_SC - Mod_Bit +1 : Mod_Bit* k_SC ) = de2bi(TXss_Mapping(:, k_SC), Mod_Bit,'left-msb');
% end    

% scatterplot(Rx_Sym_SC_Eq(:));
% scatterplot(Tx(:));


ser = sum((N_fft - sum((TXss_Mapping == ss_Mapping),2)))/Sub_group/N_Symbol;
ber = sum(N_Bit_Symbol - sum((Tx_bin_sc == Rx_bin_sc),2))/N_Bit_Symbol/N_Symbol;
end

