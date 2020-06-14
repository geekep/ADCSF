clc
addpath(genpath(strcat(pwd,'/LIB')))
addpath(genpath(strcat(pwd,'/DATA/Avenue')))
addpath(genpath('C:/Users/admin/Documents/MATLAB/Add-Ons/mexopencv'))
addpath(genpath('C:\Users\admin\Documents\MATLAB\Add-Ons\mexopencv\opencv_contrib'))

MISC.dockStyle;
visualise = true;

%% Prepare
load('AvenueTr.mat')
% FG extractor
% Learning rate is set to 0.02.
% The number of frames for modeling background is set to 200.
fgbg = VIDEO.getfgbgmask(['training_videos\',AvenueTr{1}], 1e-2, 200, visualise);

% Generate active cells
[ext,OFbag,FBbag,map] = PERS.genscan(4,0.02,visualise);

%% Train stage
n = 0;
for k = 1:size(AvenueTr,1)

	File = fullfile('training_videos', AvenueTr{k});
	
	% Feature extraction
	[OFbag,FBbag,n] = HEAD.extract4VID(File, OFbag, FBbag, ext, n, fgbg, ...
        1e-3, visualise);
    
end

% Model generation
Mdl = HEAD.genMdlstr(OFbag,FBbag,map);

% Save model
save(strcat(pwd,'/DATA/Avenue/AvenueMdl.mat'), 'Mdl')

%% Test stage
load('AvenueTe.mat')
R = cell(size(AvenueTe,1),1);
load('AvenueMdl.mat'); % load model

th_of = 5.5:8.5;
th_fg = 80:10:125;

for i = 1:length(th_of)
    for j = 1:length(th_fg)

        th = struct;
        th.th_of = th_of(i);      % optical flow model threshold
        th.th_fg = th_fg(j);      % foreground occupancy model threshold
        
        for k = 1:length(R)
            
            File  = fullfile('testing_videos', AvenueTe{k,1});   % test file
            gFile = fullfile('testing_videos', AvenueTe{k,2});   % groundtruth file
            
            % Anomaly detection
            [GTD,MAD,GAD,CAD,IAD] = HEAD.AnomalyDetection(File, gFile, Mdl, ext, ...
                th, visualise, fgbg, 1e-3);
            
            % Performance evaluation
            [TPR,FPR] = ANOMALY.CorrectDetectionRate(GTD,MAD,GAD,CAD,IAD,0.4);
            R{k} = [TPR,FPR];
            
        end
        
        % Draw ROC
        R = cell2mat(R);
        TPR = R(:,1);
        FPR = R(:,2);
        AUC = ANOMALY.ROCanalysis(TPR,FPR);
        title(strcat(num2str(th.th_of),'/',num2str(th.th_fg),'/',num2str(AUC)))

    end
end
