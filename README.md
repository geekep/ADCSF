# Real-time Video Anomaly Detection and Recognition
---

This code is meant to detect abnormal events in videos (e.g. robberies, accidents, car crashes, etc). 
The intructions are divided as follows:
1. Required dependencies
2. Datasets
3. Contents
4. Demo
5. Usage
6. Considerations
---

## 1. Required dependencies
- We use MATLAB R2018a computer vision package, older versions that contain this package should work as well.
- We use the background extractor provided by the _mexopencv-Master_ tool of (https://github.com/opencv/opencv_contrib/tree/master/modules/matlab) this will require _opencv 2.4.10_ however, we provide the package, but you refer and _thank_ to that site.
- install opencv 2.4.10, follow the instructions here for your respective OS (https://opencv.org/releases.html)
- After installing _opencv 2.4.10_ proceed to install _mexopencv-Master_, the tool is now available in /LIB/mexopencv-master.zip 
+ 1.1 unzip mexopencv-master.zip
+ 1.2 follow this instructions for you operating system ./LIB/mexopencv-master/README.markdown
- [Linux] We need h264 codec support to read the LV videos, _libav-tools_ should provided the preamble install as follows opening the terminal:
> $ sudo apt-get install libav-tools
---

## 2. Datasets 
- Datsets are listed on the paper, our code is aimed to process videos not images as it was originally given.
- It is necessary to convert images to avi files to test the code. We recommend _ffmpeg_ or _avconv_ to this end (see comments about compression). 
- We do not provide third parties datasets, libraries or code.
- The examples are here (https://yadi.sk/d/KcyrIAei3Sxubt). Download and unzip them. FUll dataset (https://cvrleyva.wordpress.com/2017/04/08/lv-dataset/)
- check these files inside /DATA/Sample/ folder i.e. Tr11.avi, Te36.avi and gTe36.avi used for demo purposes.
- [Linux] Our dataset is available on the site and our provided code has bash script converter to open any video format in MATLAB (avconv by default). To properly work firstly check if widely used formats decoders, e.g. h264, are installed e.g.:
> $ avconv -codecs
```
Codecs:
 D..... = Decoding supported < right-here >
 .E.... = Encoding supported  
 ..V... = Video codec
 ..A... = Audio codec
 ..S... = Subtitle codec
 ...I.. = Intra frame-only codec
 ....L. = Lossy compression
 .....S = Lossless compression
 DEV.L. mpeg1video           MPEG-1 video (decoders: mpeg1video mpeg1video_vdpau )
 DEV.L. mpeg2video           MPEG-1 video (decoders: mpeg2video mpegvideo_vdpau ) < supported-decoder >
 D.V.L. mpegvideo_xvmc       MPEG-1/2 video XvMC (X-Video Motion Compensation) < no-supported-encoder >
 ... etc ....
```
The check.m file do this process automatically, we recommend to convert all videos into mjpeg or rawvideo format as:
> avconv -i [input] -vcodec rawvideo [output]
or
> avconv -i [input] -vcodec mjpeg -q:v 0 [output]
```
for i in *.mp4
	avconv -i "$i" -vcodec [rawvideo] "out-$i";
```
- We warn that high compressed video might loss important information. To avoid this use lossless format conversion if required, for instance "rawvideo", "rgb24 and YUV" pixel formats. The detection should not be that different among codecs using our pre-trained model, however it is advised to extract features and construct the model all over again.
---

## 3. Contents
The main folder TIP-ADCSF has two subfolders: DATA and LIB.

### 3.1 DATA
+ it contains one pre-trained model to identify abnormal events of the UCSDP1 and LV dataset
+ it contains the UCSDP1 test files and train files in .mat file cell
+ it contains the LV dataset file names and number of frames used
+ it contains two videos from those datasets to run the demo

### 3.1 LIB
It contains the functions requried by the method and video processing.
+ HEAD.m is the class container with functions required by the method as a whole
+ PERS.m is the class container with functions to generate the active cells (see appendix)
+ HOF.c is the function to generate HOF descriptor 
+ VIDEO.m is the class container to handle video formats
+ MISC.m is the class container with aditional functions no related with the method but visualisation
---

## 4. Demo
- open check.m to verify that all depencies are met before execute any other function
- add the _mexopencv-Master_ path in Line 4 of P1.m and LV.m
- P1.m and LV.m are able to execute the respective demos, just open and run
---

## 5. Usage
- Testing different data is as follows:
+ If the video is a single piece and contains both abnormal and normal behaviour, we create one single database .mat file.
+ If is a set of videos proceed, we create two database files as it is P1Te.mat and P1Tr.mat (i.e. train and test files).
+ The code automatically will use the file path and number of frames specified for those files.
---

## 6. Considerations
- We use parallel MATLAB support only to speed up the model's training( for -> parfor) and it has nothing to do wih the frame processing time.
- The time required to load and check the ground truth, save detection frames and visualize is not considered when ranking processing times.
- The method was tested under OS linux ubuntu 14.04, CPU intel i5 and 16GB of RAM. This guide was written under a linux-based distribution scope, more precisely debian. Unfortunately we lack experience to address bugs or any problem that could emerge in non-linux OS, we will provide only linux OS help regarding execution problems, we apologise.
We tested this code on Windows10. We successfully install _opencv 2.4.10_ following this tutorial:http://www.learnopencv.com/install-opencv3-on-windows/
