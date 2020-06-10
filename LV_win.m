clc
addpath(genpath(strcat(pwd,'/LIB')))
addpath(genpath(strcat(pwd,'/DATA/LV')))
addpath(genpath('C:/Users/admin/Documents/MATLAB/Add-Ons/mexopencv'))
addpath(genpath('C:\Users\admin\Documents\MATLAB\Add-Ons\mexopencv\opencv_contrib'))

MISC.dockStyle;
visualise = true;

%% Prepare
load('LVparms.mat');
R = cell(size(LVparms,1), 1);

th_of = 5.5:8.5;
th_fg = 80:10:125;

%% Train and Test
th = struct;
th.th_of = th_of(2);                % optical flow model threshold
th.th_fg = th_fg(2);                % foreground occupancy model threshold

for k = 1:length(R)

    File = LVparms{k,1};     % train&test file
    gFile = LVparms{k,2};    % groundtruth file
    t0 = LVparms{k,3};       % train/test frames

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
    save([pwd,'/DATA/LV/MODELS/',File(1:end-4),'.mat'], 'Mdl')
    
    % Anomaly detection
    [GTD,CAD,IAD] = HEAD.AnomalyDetection(File, gFile, Mdl, ext, th, true, ...
        fgbg, 1e-3, t0, Inf);
    
    % Performance evaluation
    [TPR,FPR] = ANOMALY.CorrectDetectionRate(GTD,CAD,IAD,0.2);
    R{k} = [TPR,FPR];

end

%% Test using existing models
for i = 1:length(th_of)
    for j = 1:length(th_fg)
        
        th = struct;
        th.th_of = th_of(i);          % optical flow model threshold
        th.th_fg = th_fg(j);          % foreground occupancy model threshold
        
        for k = 1:length(R)

            File  = LVparms{k,1};      % train&test file
            gFile = LVparms{k,2};      % groundtruth file
            t0    = LVparms{k,3};      % train/test frames
            load([pwd,'/DATA/LV/MODELS/',File(1:end-4),'.mat']);

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

        % Draw ROC
        R = cell2mat(R);
        TPR = R(:,1);
        FPR = R(:,2);
        figure
        AUC = ANOMALY.ROCanalysis(TPR,FPR);
        title(strcat(num2str(th.th_of),'/',num2str(th.th_fg),'/',num2str(AUC)))

    end
end
