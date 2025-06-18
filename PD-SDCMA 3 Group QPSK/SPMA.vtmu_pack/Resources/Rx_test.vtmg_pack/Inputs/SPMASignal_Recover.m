function [OFDM_Signal] = SPMASignal_Recover(OFDM_Para,Rx)
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

%%
OFDM_Sample = zeros(1,N_Symbol * N_fft * (1 + CP));
Rx(find(isnan(Rx)==1))=0;
FFT_Window = Rx;
OFDM_Window = real(ifft(FFT_Window , N_fft, 2));   % row wise FFT 每一行的FFT
N_CP = CP * N_fft;                        % sample length of cyclic prefix 循环前缀采样长度
CP_Samples = OFDM_Window(:, N_fft - N_CP + 1: N_fft);  % cyclic prefix samples 取出循环前缀
OFDM_Window_CP = [CP_Samples, OFDM_Window];    % add CP
OFDM_Signal = reshape(OFDM_Window_CP.', 1, numel(OFDM_Window_CP));     % change to a row vector

end

