% VIDEO.m is the class container to handle video formats.
classdef VIDEO
 
 methods(Static = true)
   
  function fgbg = getfgbgmask(varargin)
   file = varargin{1};
   lr   = varargin{2};%learning rate
   flr  = varargin{3};% frames for learning
   vis  = varargin{4};
   
   fgbg = cv.BackgroundSubtractorMOG();
   
   videoFReader = vision.VideoFileReader(file,'ImageColorSpace','Intensity');
   step(videoFReader);
   
   scale = isequal(videoFReader.info.VideoSize,[HEAD.scX,HEAD.scY]);
   
   if ~ scale
    X = videoFReader.info.VideoSize(1);
    Y = videoFReader.info.VideoSize(2);
    sc{1} = uint16(round(1:Y/HEAD.scY:Y));
    sc{2} = uint16(round(1:X/HEAD.scX:X));
    scale = true;
   else
    scale = false;
   end
   
   if vis
    videoPlayer = vision.VideoPlayer;
   end

   for k = 1:flr
    I = step(videoFReader);
    if scale
     I = I(sc{1},sc{2});
    end
    B = fgbg.apply(uint8(255*I),'LearningRate', lr);
    if vis
     step(videoPlayer,[B,I])
     pause(0.05)
    end
   end
   
  end
  
  function testfgbgmask(varargin)
   file = varargin{1};
   lr   = varargin{2};%learning rate
   fgbg = varargin{3};% gmm model
   scale = false;
   if nargin > 3
    scale = true;
    sc = varargin{4};
   end
   videoFReader = vision.VideoFileReader(file,'ImageColorSpace','Intensity');
   videoPlayer = vision.VideoPlayer;
   
   while ~isDone(videoFReader)
    I = step(videoFReader);
    if scale
     I = I(sc{1},sc{2});
    end
    B = fgbg.apply(uint8(255*I),'LearningRate', lr);
    step(videoPlayer,[B,I])
    pause(0.05)
   end
  end
  
 end
end
