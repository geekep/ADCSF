%% ped1
folder = 'C:\Users\admin\MATLAB-workspace\ADCSF\DATA\ped1';

% ped1_train
fileList = dir(strcat(folder, '\training_videos\*.avi'));
P1Tr = {fileList.name}';
save(strcat(folder, '\P1Tr.mat'), 'P1Tr');

% ped1_test
fileList_gt = dir(fullfile(folder, 'testing_videos\*_gt.avi'));

P1Te = {fileList.name; fileList_gt.name}';
save(strcat(folder, '\P1Te.mat'), 'P1Te')

%% ped2
folder = 'C:\Users\admin\MATLAB-workspace\ADCSF\DATA\ped2';

% ped2_train
fileList = dir(fullfile(strcat(folder, '\training_videos\*.avi')));
P2Tr = {fileList.name}';
save(strcat(folder, '\P2Tr.mat'), 'P2Tr');

% ped2_test
fileList_gt = dir(fullfile(folder, 'testing_videos\*_gt.avi'));

P1Te = {fileList.name; fileList_gt.name}';
save(strcat(folder, '\P1Te.mat'), 'P1Te')

%% 
