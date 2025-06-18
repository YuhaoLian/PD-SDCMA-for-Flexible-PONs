function [output ,Tx_Sym_FFT]= OFDM_TX(OFDM_Para,strategy)
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
N_Dimension = OFDM_Para.N_Dimension;
Sub_group = OFDM_Para.Sub_group;
K_sc_used =OFDM_Para.K_sc_used;
N_sc_used_all = OFDM_Para.N_sc_used_all;


%% 基带数据数据产生
P_data = bits_test(N_Bit_Symbol,N_Symbol,N_frm);
Date_bits = reshape(P_data,N_frm,[]);


%% QAM调制(N_Symbol个信号并行同时调制)

Tx_Sym_FFT = zeros(N_Symbol, N_fft/2, N_frm);
for k = 1: N_frm
    Data_Bin = Date_bits(k, :);
    ss_mat = vec2mat(Data_Bin, N_Bit_Symbol);%将向量拆开转化为矩阵，N_Bit_Symbol列,最后补零
    ss_Mapping = zeros(N_Symbol, N_fft/2);   %N_fft列
    k_start = 1;
    for k_SC = 3:K_sc_used: K_sc_used*N_sc_used/2+2
        Mod_Bit = Bit_Loading_SC(k_SC);
        if Mod_Bit == 0    % dropped subcarrier
            ss_Mapping(:, k_SC) = zeros(N_Symbol, 1);
        else               % adaptive modulation
            k_end = k_start + Mod_Bit - 1;
            bin_sc = ss_mat(:, k_start: k_end);   
            dec_sc = bi2de(bin_sc, 'left-msb');%从左开始由二进制比特转化为符号
            if ceil(strategy(1)/2) == ceil(strategy(2)/2)
                ss_Mapping(:, k_SC-1+ceil(strategy(1)/2)) = qammod(dec_sc, 2^Mod_Bit, 'gray');%格雷编码
            else
                ss_Mapping(:, k_SC-1+ceil(strategy(1)/2)) = imag(qammod(dec_sc, 2^Mod_Bit, 'gray'))*i;%格雷编码
                ss_Mapping(:, k_SC-1+ceil(strategy(2)/2)) = real(qammod(dec_sc, 2^Mod_Bit, 'gray'));%格雷编码
            end            
            k_start = k_end + 1;
        end  
    end
    Tx_Sym_FFT(:, :, k) = ss_Mapping;      
end 
% save('Tx_Sym_FFT', 'Tx_Sym_FFT'); % save transmitted complex matrix

Tx_Sym_FFT = [Tx_Sym_FFT circshift(fliplr(conj(Tx_Sym_FFT)), [0, 1])];

%% 功率归一化
% --------------Power-loading/Tx_Sym_FFT-----------------%
for k = 1: N_frm
    for k_SC = 1: N_fft
        Mod_Bit = Bit_Loading_SC(k_SC);
        switch Mod_Bit
            case 0
                P_mean = 1;
            case 2
                P_mean = 2;
            case 3
                P_mean = 5;
            case 4
                P_mean = 10;     % normalized powers for different QAM modulation formats归一化功率
            case 5
                P_mean = 20;
            case 6
                P_mean = 42;
            case 7
                P_mean = 82;
            case 8
                P_mean = 170;
            otherwise
                error('Incorrect Subcarrier Modulation Format!')
        end 
        Tx_Sym(:, k_SC, k) = Tx_Sym_FFT(:, k_SC, k); 
    end
end
% scatterplot(Tx_Sym_FFT(:));




%% IFFT + 循环前缀

OFDM_Sample = zeros(N_frm, N_Symbol * N_fft * (1 + CP));

for k = 1: N_frm
    FFT_Window = Tx_Sym(:, :, k);   
    OFDM_Window = real(ifft(FFT_Window , N_fft, 2));   % row wise FFT 每一行的FFT
    N_CP = CP * N_fft;                        % sample length of cyclic prefix 循环前缀采样长度
    CP_Samples = OFDM_Window(:, N_fft - N_CP + 1: N_fft);  % cyclic prefix samples 取出循环前缀
    OFDM_Window_CP = [CP_Samples, OFDM_Window];    % add CP
    OFDM_Signal = reshape(OFDM_Window_CP.', 1, numel(OFDM_Window_CP));     % change to a row vector 
    % numel()数组元素的数目
    % 10帧OFDM帧（6个）符号
    OFDM_Sample(k, :) = OFDM_Signal;    
end

output = OFDM_Sample;


end



