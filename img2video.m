%% UCSD groundtruth
input_folder = 'D:\UCSD_Anomaly_Dataset.v1p2\UCSDped2\Test';
fileList_gt = dir(fullfile(input_folder, '*_gt'));
output_folder = 'C:\Users\admin\MATLAB-workspace\ADCSF\DATA\ped2\testing_videos';

for k = 1:length(fileList_gt)
    
    video_gt = VideoWriter(fullfile(output_folder, strcat(fileList_gt(k).name(end-4:end), '.avi')));
    video_gt.FrameRate = 25;
    open(video_gt);
    
    imageNames = dir(fullfile(input_folder, fileList_gt(k).name, '*.bmp'));
    for i = 1:length(imageNames)
        img = imread(fullfile(input_folder, fileList_gt(k).name, imageNames(i).name));
        writeVideo(video_gt, img);
    end
    close(video_gt)
    
end

%% UCSD Ped1 train&test
videoCount = 34;
input_folder = 'D:\UCSD_Anomaly_Dataset.v1p2\UCSDped1\Train';
output_folder = 'C:\Users\admin\MATLAB-workspace\ADCSF\DATA\ped1\training_videos';

for videoIdx = 1:videoCount
    
    video = VideoWriter(fullfile(output_folder, [sprintf('%02d', videoIdx), '.avi']));
    video.FrameRate = 25;
    open(video);
    
    imageList = dir(fullfile(input_folder, ['Train', sprintf('%03d', videoIdx)], '*.tif'));
    for i = 1:length(imageList)
        img = imread(fullfile(input_folder, ['Train', sprintf('%03d', videoIdx)], imageList(i).name));
%         img = im2double(img);
        writeVideo(video, img);
    end
    close(video);
    
end

%% Avenue
input_folder = 'D:\Avenue Dataset\ground_truth_demo\testing_label_mask';
fileList_gt = dir(fullfile(input_folder, '*_label.mat'));
output_folder = 'C:\Users\admin\MATLAB-workspace\ADCSF\DATA\Avenue\testing_videos';

for k = 1:length(fileList_gt)
    
    video_gt = VideoWriter(fullfile(output_folder, strcat(fileList_gt(k).name(1:end-4), '.avi')));
    video_gt.FrameRate = 25;
    open(video_gt);
    load(fullfile(input_folder,fileList_gt(k).name))
    for i = 1:length(volLabel)
        img = im2uint8(volLabel{i});
        writeVideo(video_gt, img);
    end
    close(video_gt)
    
end