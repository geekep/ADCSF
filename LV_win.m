clc;
addpath(genpath(strcat(pwd,'/LIB')))
addpath(genpath(strcat(pwd,'/DATA/LV')))
addpath('C:/Users/admin/Documents/MATLAB/Add-Ons/mexopencv-3.4.0')

% load('LVcrash0Mdl.mat')
load('LVparms.mat');
R = cell(size(LVparms,1), 1);

%% Train stage
for k = 1:length(R)

    File = LVparms{k,1};    % test file
    gFile = LVparms{k,2};   % ground truth file
    t0 = LVparms{k,3};      % train/test frames

    MISC.dockStyle;
    visualise = true;

    % FG extractor
    % Learning rate is set to 0.02.
    % The number of frames for modeling background is set to 300.
    fgbg = VIDEO.getfgbgmask(File,1e-2,300,visualise);
    
    % Generate active cells
    [ext,OFbag,FBbag,map] = PERS.genscan(4,0.02,visualise);

    % Feature extraction
    n = 0;
    [OFbag,FBbag,~] = HEAD.extract4VID(File, OFbag, FBbag, ext, n, fgbg, ...
        1e-3, visualise, 1, t0);
    
    % Model generation
    Mdl = HEAD.genMdlstr(OFbag,FBbag,map);
    % Save model
end

%% Test stage
th = struct;
th.th_of = 6.5;       % optical flow model threshold
th.th_fg = 90;        % foreground occupancy model threshold
for k = 1:length(R)
  
    % Anomaly detection
    [GTD,CAD,IAD] = HEAD.AnomalyDetection(File, gFile, Mdl, ext, th, true, ...
        fgbg, 1e-3, t0, Inf);
    
    % Performance evaluation
    [TPR,FPR] = ANOMALY.CorrectDetectionRate(GTD,CAD,IAD,0.2);
    R{k} = [TPR,FPR];

end

%% Draw ROC
R = cell2mat(R);
TPR = R(:,1);
FPR = R(:,2);
AUC = ANOMALY.ROCanalysis(TPR,FPR);
title(strcat(num2str(th.th_of),'/',num2str(th.th_fg),'/',num2str(AUC)))
