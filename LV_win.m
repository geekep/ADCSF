clc
addpath(genpath(strcat(pwd,'/LIB')))
addpath(genpath(strcat(pwd,'/DATA/LV')))
addpath('C:/Users/admin/Documents/MATLAB/Add-Ons/mexopencv-3.4.0')

MISC.dockStyle;

load('LVparms.mat');
R = cell(size(LVparms,1), 1);
models = cell(length(R), 1);

%% Train stage
for k = 1:length(R)

    File = LVparms{k,1};    % train&test file
    t0 = LVparms{k,3};      % train/test frames
    
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
    models{k} = Mdl;

end

% Save model
save(strcat(pwd,'/DATA/LV/LVMdl.mat'), 'models')

%% Test stage
load('LVMdl.mat')
th = struct;
th.th_of = 6.5;               % optical flow model threshold
th.th_fg = 90;                % foreground occupancy model threshold

for k = 1:length(R)

    File  = LVparms{k,1};      % train&test file
    gFile = LVparms{k,2};      % groundtruth file
    t0    = LVparms{k,3};      % train/test frames
    Mdl   = models{k};         % model struct

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
