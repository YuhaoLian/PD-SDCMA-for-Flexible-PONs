function output = Platform_NOMA_Tx(input, M_upsampling, Clipping_Agg, N_bits)

%% ---------------- Control Parameters ---------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N_Symbol = 100;                         % Number of OFDM symbols to be transmitted   (OFDM_Para)需要传递的OFDM的符号个数
CPshift = 0;                            % CP offset for OFDM demodulation  (OFDM_Para)
N_frm = 1;          %帧数、frame

N_Dimension = 3; % 占用维度数
K_sc_used = ceil(N_Dimension/2);
 
% M_upsampling = 2;

% N_bits = 8;

% 占用维度策略
%  strategy = [1,2;2,3];
 strategy = [1,2;2,3;3,1];
%  strategy = [1,2;4,3;3,1];
% strategy = [1,2;2,3;1,4];
% strategy = [1,2;2,3;3,4];
 
%  strategy = [1,2;3,5;2,4;3,1]; %16QAM

% strategy = [1,2;2,3;3,4;4,5];
% strategy = [1,2;2,3;3,4;4,5];

% strategy = [1,2;3,4;5,6];

% strategy = [1,2;2,3;3,4;4,5;5,6];
% 
% strategy = [1,2;2,3;3,4;4,5;5,6;6,1];
% strategy = [1,2;2,3;3,4;4,5;5,6;6,7;7,8;8,9;9,10;10,1];

%% ---------------- NOMA User Parameters ---------------%
% user_number = 1;
% power_allcation = [1];
% user_number = 2;
% power_allcation = [0.985 0.015];%64QAM
% power_allcation = [0.945 0.055];%16QAM
% power_allcation = [0.8 0.2];%4QAM
user_number = 3;
power_allcation = [16/21 4/21 1/21];%4QAM
% power_allcation = [16/21 12/21 1/21];%4QAM
% power_allcation = [1 1 1];%4QAM
% power_allcation = [0.945 0.05425 0.0025];%4QAM
% user_number = 4;
% power_allcation = [64/85 32/85 16/85 7/85];
% user_number = 5;
% power_allcation = [128/213 64/213 16/213 4/213 1/213];
% user_number = 6;
% power_allcation = [128/213 64/213 16/213 4/213 1/213 64/213];
% user_number = 6;
% power_allcation = [250 150 90 54 32 20];
% 
% user_number = 10;
% power_allcation = [99.23 59.54 35.72 21.43 12.86 7.72 4.63 2.8 1.7 1]/sum([99.23 59.54 35.72 21.43 12.86 7.72 4.63 2.8 1.7 1]);

%% ---------------- OFDM Parameters ------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
M_QAM =  2;                          % 一个QAM符号所携带的比特个数
BW_OFDM = 2e9;                   %  sampling rate LTE采样率
Nb_fft = 1;                          % oversampling ratio when generating the OFDM signal OFDM信号的过采样率
CP = 1/4;                            % length ratio of the cyclic prefix 循环前缀的长度比
ClippingRatio = 0.0000001;                   % PAPR coefficient: '0'- w/o clipping  峰均比系数：0代表不限幅
Clipping_Agg = 14; % Clipping_Agg is 14dB.限幅14dB


N_sc_used = 40;                      % data-carrying subcarrier number   数据携带载波个数
N_fft = 2^nextpow2(K_sc_used *N_sc_used);       % FFT/IFFT size  FFT/IFFT的大小
N_sc_used_all = K_sc_used *N_sc_used;      %总的子载波数
Sub_group = floor(N_fft/K_sc_used);


%按照惯例，nextpow2(0) 返回零。
%您可以使用 nextpow2 填充传递到 fft 的信号。
%当信号长度并非 2 次幂时，这样做可以加快 FFT 的运算速度。

%---- Bitloading
Bit_Loading_SC = zeros(1, N_fft);
Bit_Loading_SC(3: N_sc_used/2+2) = M_QAM * ones(1, N_sc_used/2);
Bit_Loading_SC(3:K_sc_used*N_sc_used/2+2) = upsample(Bit_Loading_SC(3: N_sc_used/2+2),K_sc_used);
% Bit_Loading_SC = circshift(Bit_Loading_SC, [0, -ceil(N_sc_used/2)]);
     
%---- Powerloading
Power_Loading_SC = zeros(1, N_fft);
Power_Loading_SC(1: N_sc_used) = ones(1, N_sc_used);
% Power_Loading_SC = circshift(Power_Loading_SC, [0, -ceil(N_sc_used/2)]);
 
Power_Loading_SC = repmat(Power_Loading_SC, length(N_frm), 1);

N_Bit_Symbol = sum(Bit_Loading_SC);                % number of transmitted bits in each OFDM symbol每个OFDM符号传输的比特数量

OFDM_Para = struct('N_Symbol', N_Symbol, 'CPshift', CPshift,'N_frm',N_frm, 'BW_OFDM', BW_OFDM,'N_bits',N_bits,...
                   'Nb_fft', Nb_fft, 'CP', CP, 'ClippingRatio', ClippingRatio, 'N_sc_used', N_sc_used,...
                   'N_fft', N_fft, 'Bit_Loading_SC', Bit_Loading_SC,'Power_Loading_SC', Power_Loading_SC,'N_sc_used_all',N_sc_used_all,...
                   'N_Bit_Symbol', N_Bit_Symbol,'Clipping_Agg',Clipping_Agg,'user_number',user_number,'M_upsampling',M_upsampling,...
                   'power_allcation',power_allcation,'N_Dimension',N_Dimension,'strategy',strategy,'Sub_group',Sub_group,'K_sc_used',K_sc_used);
                          
save('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TransceiverPara\OFDM_Para', 'OFDM_Para'); 

% fs = BW_OFDM*M_upsampling*2; 

%% ------------------ Tx Signal Generation -----------------%
[NOMA_OFDM_Signal] = NOMA_OFDM_Tx(OFDM_Para);
save('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TransceiverPara\NOMA_OFDM_Signal','NOMA_OFDM_Signal'); 
Len_Matlab = length(NOMA_OFDM_Signal);
save('F:\学习\科研——数字信号\OFDM-IM\code\VPI\SPMA\VPIData\TransceiverPara\Len_Matlab','Len_Matlab'); 
Samples = input.band.E;
Len_VPI = length(Samples);


Temp1 = repmat(NOMA_OFDM_Signal, 1, ceil(Len_VPI/Len_Matlab));
Temp2 = Temp1(1: Len_VPI);
output = input;
output.band.E = Temp2;
