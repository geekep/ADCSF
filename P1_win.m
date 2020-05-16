clc
addpath(genpath(strcat(pwd,'/LIB')))
addpath(genpath(strcat(pwd,'/DATA/ped1')))
addpath('C:/Users/admin/Documents/MATLAB/Add-Ons/mexopencv-3.4.0')

MISC.dockStyle;

%% Train stage
load('P1Tr.mat')

for k = 1:size(P1Tr,1)

	File = P1Tr{k};

	visualise = true;

	% FG extractor
	% Learning rate is set to 0.02.
    % The number of frames for modeling background is set to 200.
	fgbg = VIDEO.getfgbgmask(file,1e-2,200,visualise);

	% Generate active cells
	[ext,OFbag,FBbag,map] = PERS.genscan(4,0.02,visualise);
	
	% Feature extraction
	n = 0;
	[OFbag,FBbag,n] = HEAD.extract4VID(File,OFbag,FBbag,ext,n,fgbg,1e-3,visualise);
	
	% Model generation
	Mdl = HEAD.genMdlstr(OFbag,FBbag,map);
	models = [models, Mdl]

end

% Save model
save(models, 'P1Mdl.mat')

%% Test stage
load('P1Te.mat')
load('P1Mdl.mat')
R = cell(size(P1Te,1),1);
th = struct;
th.th_of = 6.5;     % optical flow model threshold
th.th_fg = 90;      % foreground occupancy model threshold

for k = 1:length(R)

	File  = P1Te{k,1};     % test file
	gFile = P1Te{k,2};     % groundtruth file
	Mdl   = P1Mdl{k};      % model

	% FG extractor
	% Learning rate is set to 0.03.
    % The number of frames for modeling background is set to 200.
	fgbg = VIDEO.getfgbgmask(file,1e-3,200,visualise);

	% Generate active cells
	[ext,OFbag,FBbag,map] = PERS.genscan(4,0.02,visualise);

	% Anomaly detection
	[GTD,CAD,IAD] = HEAD.AnomalyDetection(File, gFile, Mdl, ext, ...
		th, visualise, fgbg, 1e-3);
 
	% Performance evaluation
	[TPR,FPR] = ANOMALY.CorrectDetectionRate(GTD,CAD,IAD,0.4);
	R{k} = [TPR,FPR]
 
end

%% Draw ROC
R = cell2mat(R);
TPR = R(:,1);
FPR = R(:,2);
AUC = ANOMALY.ROCanalysis(TPR,FPR);
title(strcat(num2str(th.th_of),'/',num2str(th.th_fg),'/',num2str(AUC)))
