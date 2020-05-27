clc
addpath(genpath(strcat(pwd,'/LIB')))
addpath(genpath(strcat(pwd,'/DATA/ped2')))
addpath('C:/Users/admin/Documents/MATLAB/Add-Ons/mexopencv-3.4.0')

MISC.dockStyle;
visualise = true;

%% Prepare
load('P2Tr.mat')
% FG extractor
% Learning rate is set to 0.02.
% The number of frames for modeling background is set to 200.
fgbg = VIDEO.getfgbgmask(P2Tr{1},1e-2,200,visualise);

% Generate active cells
[ext,OFbag,FBbag,map] = PERS.genscan(4,0.02,visualise);

%% Train stage
n = 0;
for k = 1:size(P2Tr,1)

	File = fullfile('training_videos', P2Tr{k});

	% Feature extraction	
	[OFbag,FBbag,n] = HEAD.extract4VID(File, OFbag, FBbag, ext, n, fgbg, ...
        1e-3,visualise);
	
end

% Model generation
Mdl = HEAD.genMdlstr(OFbag,FBbag,map);

% Save model
save(strcat(pwd,'/DATA/ped2/P2Mdl.mat'), 'Mdl')

%% Test stage
load('P2Te.mat')
load('P2Mdl.mat')

th = struct;
th.th_of = 6.5;     % optical flow model threshold
th.th_fg = 90;      % foreground occupancy model threshold
R = cell(size(P2Te,1),1);

for k = 1:length(R)

	File  = fullfile('testing_videos', P2Te{k,1});     % test file
	gFile = fullfile('testing_videos', P2Te{k,2});     % groundtruth file

	% Anomaly detection
	[GTD,CAD,IAD] = HEAD.AnomalyDetection(File, gFile, Mdl, ext, ...
		th, visualise, fgbg, 1e-3);
 
	% Performance evaluation
	[TPR,FPR] = ANOMALY.CorrectDetectionRate(GTD,CAD,IAD,0.4);
	R{k} = [TPR,FPR];
 
end

%% Draw ROC
R = cell2mat(R);
TPR = R(:,1);
FPR = R(:,2);
AUC = ANOMALY.ROCanalysis(TPR,FPR);
title(strcat(num2str(th.th_of),'/',num2str(th.th_fg),'/',num2str(AUC)))
