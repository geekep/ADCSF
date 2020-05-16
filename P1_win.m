clc
addpath(genpath(strcat(pwd,'/LIB')))
addpath(genpath(strcat(pwd,'/DATA')))
addpath('C:/Users/admin/Documents/MATLAB/Add-Ons/mexopencv-3.4.0')

load('P1Tr.mat')
load('P1Te.mat')
% load('P1Mdl.mat')

MISC.dockStyle;

visualise = true;

file = 'Tr11.avi';

% Generate active cells and FG extractor
fgbg = VIDEO.getfgbgmask(file,1e-2,200,visualise);
% fgbg = VIDEO.getfgbgmask(file,1e-3,200,visualise);
[ext,OFbag,FBbag,map] = PERS.genscan(4,0.02,visualise);

%{
% Feature extraction and model generation
n = 0;
for k = 1:size(P1Tr,1)
 File = P1Tr{k};
 disp(File)
 [OFbag,FBbag,n] = HEAD.extract4VID(File,OFbag,FBbag,ext,n,fgbg,1e-3,visualise);
 clc
end

Mdl = HEAD.genMdlstr(OFbag,FBbag,map);
%}

th = struct;
th.th_of = 6.5;
th.th_fg = 90;

TestFile = P1Te{36,1};
gTestFile = P1Te{36,2};

[GTD,CAD,IAD] = HEAD.AnomalyDetection(TestFile,gTestFile,Mdl,ext,th,visualise,fgbg,1e-3);
[TPR,FPR] = ANOMALY.CorrectDetectionRate(GTD,CAD,IAD,0.4);


% Full test
%{
R = cell(36,1);

for k = 1:size(P1Te,1)
 
 [GTD,CAD,IAD] = HEAD.AnomalyDetection(P1Te{k,1},P1Te{k,2},Mdl,ext,th,visualise,fgbg,1e-3);
 
 [TPR,FPR] = ANOMALY.CorrectDetectionRate(GTD,CAD,IAD,0.4);
 
 R{k} = [TPR,FPR];
 
 clc
 
end

R = cell2mat(R);
TPR = R(:,1);
FPR = R(:,2);

AUC = ANOMALY.ROCanalysis(TPR,FPR);
title(strcat(num2str(th_of),'/',num2str(th_fg),'/',num2str(AUC)))
%}