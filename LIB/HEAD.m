% HEAD.m is the class container with functions required by the method.
classdef HEAD
 properties(Constant)
  minrho = 0.9;
  words = 1/10;
  Dictsize = 45;
  dframes = 15;
  Ngauss = 2;
  min_occ = 0.1;
  scY = 160;
  scX = 240;
 end
 
 methods(Static = true)

  %% Training
  
  function [OFbag,FBbag,n] = extract4VID(varargin)
   
   file   = varargin{1};
   OFbag  = varargin{2};
   FBbag  = varargin{3};
   ext    = varargin{4};
   n      = varargin{5};
   fgbg   = varargin{6};
   lr     = varargin{7};
   vis    = varargin{8};   % visualize
   
   extOF = ext.extOF;
   extFB = ext.extFB;
   
   if nargin > 8
    sf = varargin{9};      % start frame
    ef = varargin{10};     % end frame
   else
    sf = 1;
    ef = Inf;
   end
   
   videoFReader = vision.VideoFileReader(which(file),'ImageColorSpace','Intensity');
   step(videoFReader);
   
   scale = isequal(videoFReader.info.VideoSize,[HEAD.scX,HEAD.scY]);
   
   if ~ scale
    X = videoFReader.info.VideoSize(1);
    Y = videoFReader.info.VideoSize(2);
    scy = uint16(round(1:Y/HEAD.scY:Y));
    scx = uint16(round(1:X/HEAD.scX:X));
    scale = true;
   else
    scale = false;
   end
   
   if vis;videoPlayer = vision.VideoPlayer;end;
   
   k = 0;of = opticalFlowLK;
   Ip = step(videoFReader);
   if scale
    Ip = Ip(scy,scx);
   end
   estimateFlow(of,Ip);
   fgbg.apply(uint8(255*Ip),'LearningRate', lr);
   
   Frames = struct;
   Frames.O = zeros([size(Ip),HEAD.dframes]);
   Frames.I = zeros([size(Ip),HEAD.dframes]);
   Frames.F = zeros([size(Ip),HEAD.dframes]);
   Frames.B = false([size(Ip),HEAD.dframes]);
   
   while ~isDone(videoFReader) && k ~= ef
    k = k+1;n = n+1;
    In = step(videoFReader);
    if scale
     In = In(scy,scx);
    end
    I = abs(Ip-In);
    Ip = In;
    O = estimateFlow(of,In);
    O = O.Vx + 1j * O.Vy;
    %O = O.Magnitude + 1j*O.Orientation;
    O = double(O+1j*eps);
    B = fgbg.apply(uint8(255*In),'LearningRate', lr);
    
    Frames.O = HEAD.stackFrame(Frames.O,O);
    Frames.I = HEAD.stackFrame(Frames.I,I);
    Frames.F = HEAD.stackFrame(Frames.F,In);
    Frames.B = HEAD.stackFrame(Frames.B,B);
    
    if k >= sf && k <= ef
     if k < HEAD.dframes
      continue
     end
     
     xy = detectFASTFeatures(Frames.I(:,:,3));
     xy = xy.selectStrongest(40);
     xy = uint16(xy.Location);
     
     OFbag = HEAD.encode(xy,Frames.O,OFbag,extOF,n);
     
     FBbag = HEAD.encodeFG(Frames.B,FBbag,extFB,n);
     
%      [FBbag,aM] = HEAD.encodeBag(Frames.B,Frames.O,FBbag,extFB,n);
     
     if vis
      %I = cat(3,I,I,I);
      I = Frames.F(:,:,3);
      I = cat(3,I,I,I);
      for i = 1:size(xy,1)
       try
       ry = extOF{xy(i,2),xy(i,1)}{1};
       rx = extOF{xy(i,2),xy(i,1)}{2};
       I = insertShape(I,'FilledRectangle', [rx(1),ry(1),[numel(rx),numel(ry)]],'opacity',0.2);
       I = insertMarker(I,xy(i,:));
       catch
       end
      end
      step(videoPlayer, I);
     end
    end
   end
   release(videoFReader);
   if vis;release(videoPlayer);end;
   
  end
  
  %% Test
     
  function [GTD,CAD,IAD] = AnomalyDetection(varargin)
   
   file = varargin{1};     % video file name
   gfile= varargin{2};     % video file name GT
   Mdl  = varargin{3};     % model struct
   ext  = varargin{4};     % window extension (perpective correction)
   th   = varargin{5};     % anomaly threshold
   vis  = varargin{6};     % visualize
   fgbg = varargin{7};
   lr   = varargin{8};
   
   extOF = ext.extOF;
   extFG = ext.extFB;
   
   th_of = th.th_of;
   th_fg = th.th_fg;
   
   mrk   = Mdl.mrk;
   fgMdl = Mdl.fgMdl;
   Mdl   = Mdl.mdl;
   
   
   if nargin > 8
    sf = varargin{9};     % start frame
    ef = varargin{10};    % end frame
   else
    sf = 1;
    ef = Inf;
   end
   
   GTD = zeros(1e5,1);      % groundtruth detected
   CAD = zeros(1e5,1);      % correct anomaly detected
   IAD = zeros(1e5,1);      % incorrect anomaly detected
   
   videoFReader1 = vision.VideoFileReader(which(file), 'ImageColorSpace','Intensity');
   step(videoFReader1);
   
%   videoFWriter = vision.VideoFileWriter('out.avi','FrameRate',30);

   scale = isequal(videoFReader1.info.VideoSize,[HEAD.scX,HEAD.scY]);
   
   if ~ scale
    X = videoFReader1.info.VideoSize(1);
    Y = videoFReader1.info.VideoSize(2);
    scy = uint16(round(1:Y/HEAD.scY:Y));
    scx = uint16(round(1:X/HEAD.scX:X));
    scale = true;
   else
    scale = false;
   end
   
   try
    videoFReader2 = vision.VideoFileReader(which(gfile), 'ImageColorSpace','Intensity');
    step(videoFReader2);
    gtmask = true;
   catch
    if scale
     J = true(numel(scy),numel(scx));
    end
    gtmask = false;        % no groundtruth
   end
   
   if vis
    videoPlayer = vision.VideoPlayer;
   end
   
   k = 0;of = opticalFlowLK;
   Ip = step(videoFReader1);
   fgbg.apply(uint8(255*Ip),'LearningRate', lr);
   
   if scale
    Ip = Ip(scy,scx);
   end
   
   estimateFlow(of,Ip);
   
   Frames = cell(7,1);
   Frames{1} = zeros([size(Ip),HEAD.dframes]);
   Frames{2} = zeros([size(Ip),HEAD.dframes]);
   Frames{3} = zeros([size(Ip),HEAD.dframes]);
   Frames{4} = zeros([size(Ip),HEAD.dframes]);
   Frames{5} = zeros([size(Ip),HEAD.dframes]);
   Frames{6} = false([size(Ip),3]);
   Frames{7} = false([size(Ip),3]);
   
   
   while ~isDone(videoFReader1)
    
    In = step(videoFReader1);% Frame Video
    
    if scale
     In = In(scy,scx);
    end
    %disp('>>>>>>>>>>')
    
    if gtmask
     J = step(videoFReader2) > 0.5;% Mask Video (GT)
     if scale
      J = J(scy,scx);
     end
    end
    
    
    B = fgbg.apply(uint8(255*In),'LearningRate', lr);
    
    O = estimateFlow(of,In);
    O = O.Vx + 1j * O.Vy;
    % O = O.Magnitude + 1j*O.Orientation;
    O = double(O+1j*eps);
    I = abs(Ip-In);
    
    
    Frames{1} = HEAD.stackFrame(Frames{1},O);
    Frames{2} = HEAD.stackFrame(Frames{2},I);
    Frames{3} = HEAD.stackFrame(Frames{3},In);
    Frames{4} = HEAD.stackFrame(Frames{4},J);
    Frames{5} = HEAD.stackFrame(Frames{5},B);
    
    
    k = k+1;
    
    if k >= sf && k <= ef
     
     xy = detectFASTFeatures(Frames{2}(:,:,3));
     xy = xy.selectStrongest(40);
     xy = uint16(xy.Location);
     
     
     Amap = HEAD.ActiveMap(Frames{2}(:,:,3),xy,extOF);
     
     M_fg = HEAD.maskScoreFG(Frames{5},fgMdl,extFG,extOF);
     
     
     M_fg = -log(M_fg);
     
     M_of = HEAD.maskScoreOF(xy,Frames{1},Mdl,extOF,mrk);

     M_of = M_of .^ Amap;
     
     M_of = -log(M_of);
     
     M_fg = M_fg > th_fg;
     
     M_of = M_of > th_of;
     
     Frames{6} = HEAD.stackFrame(Frames{6},M_of);
     
     Frames{7} = HEAD.stackFrame(Frames{7},M_fg);
     
     M_of = and(Frames{6}(:,:,1),Frames{6}(:,:,2));
     M_of = and(Frames{6}(:,:,3),M_of);
     
     M_fg = and(Frames{7}(:,:,1),Frames{7}(:,:,2));
     M_fg = and(Frames{7}(:,:,3),M_fg);
     
     M_of = bwareaopen(M_of,50);
     
     
   
     if k < HEAD.dframes
      continue
     end
     
     M = or(M_of,M_fg);
     
     if vis
      %M = cat(3,M,M,M);
      I = Frames{3}(:,:,3);
      I = cat(3,I,I,I);
      
%       for i = 1%:size(xy,1)
%        try
%        ry = extOF{xy(i,2),xy(i,1)}{1};
%        rx = extOF{xy(i,2),xy(i,1)}{2};
%        
%        I = insertShape(I,...
%         'FilledRectangle', [rx(1),ry(1),[numel(rx),numel(ry)]],...
%         'opacity',0.2,...
%         'Color','green');
%        I = insertMarker(I,xy(i,:));
%        catch
%        end
%        %I(:,:,1) = I(:,:,1) + 0.5*M;
%       end
      I(:,:,1) = I(:,:,1) + 0.5*M;
      %I = insertShape(I,'circle', [xy,5*ones(size(xy,1),1)]);
      step(videoPlayer,I);
%       step(videoFWriter, I);
     end
%      
%      if sum(M(:)) > 0
%       imwrite(I,strcat('./DATA/York/',num2str(k),'.jpg'))
%      end

     if gtmask
      J = Frames{4}(:,:,3);
      x = and(M,J);
      y = and(M,~J);
      GTD(k) = sum(J(:));     % groundtruth
      CAD(k) = sum(x(:));     % correct anomaly detected
      IAD(k) = sum(y(:));     % incorrect anomaly detected
     else
      CAD(k) = 1;
     end
     
     Ip = In;

    end
    
   end
   
   if gtmask
    GTD = GTD(1:k);
    CAD = CAD(1:k);
    IAD = IAD(1:k);
   end
   
   release(videoFReader1);
   if gtmask
    release(videoFReader2);
   end

   if vis
    release(videoPlayer);
   end
%    release(videoFWriter);
  end
  
  function M = testBag(B,O,Mdl,fbext,M,th)
   B0= B(:,:,3);
   B = B(:);
   O = O(:);
   for k = 1:numel(Mdl)
    ry = fbext{k}{1};
    rx = fbext{k}{2};
    rt = fbext{k}{3};
    sB = B(rt);
    N = numel(sB);
    sB = nnz(sB);
    if HEAD.min_occ * numel(B0(ry,rx)) > sB || isempty(Mdl{k})
     continue
    end
    sO = O(rt);
    
    pfg = Mdl{k}{1};
    pof = Mdl{k}{2};
    bag = Mdl{k}{3};
    %gmm = Mdl{k}{4};
    %x = [sB,sum(abs(sO)),mexhof(sO)];
    
    [rho,~] = HEAD.bagrho(bag,mexhof(sO));
    
    pfg = HEAD.GMMposterior(sB,pfg);
    pof = HEAD.GMMposterior(sum(abs(sO)),pof);

    try
    %if -log(gmm.pdf(x)) > th
    if -log(pfg * pof * rho) > th
     ry = fbext{k}{1};
     rx = fbext{k}{2};
     M(ry,rx) = true;
    end
    catch
    end
   end
  end
  
  function M_fg = maskScoreFG(B,fgMdl,extFG,extOF)
   M_fg = ones(size(extOF));
   B0 = B(:,:,end);
   B0 = B0(:);
   B = B(:);
   
   K = numel(fgMdl);
   
   pos = ones(K,1);
   
   for k = 1:K
    sB = sum(B0(extFG{k}{1}));
    lmdl = fgMdl{k};
    if sB < HEAD.min_occ
     continue
    end
    
    if isempty(lmdl)
     M_fg(extFG{k}{1}) = 0;
     continue
    end
    
    if lmdl{1} == -1
     continue
    end
    sB = B(extFG{k}{2});
    sB = sum(sB);
    pos(k) = HEAD.GMMposterior(sB,lmdl);
   end
   
   for k = 1:K
    if pos(k) == 0
     continue
    end
    idx = extFG{k}{3};
    idx = pos(idx);
    idx(2:end) = 0.2*idx(2:end);
    M_fg(extFG{k}{1}) = prod(idx);
   end
   
  end
   
  function M_fg = maskScoreFGb(B,fgMdl,extFG,extOF)
   M_fg = ones(size(extOF));
   B = B(:);
   for k = 1:numel(fgMdl)
    sB = sum(B(extFG{k}{3}));
    lmdl = fgMdl{k};
    if sB < HEAD.min_occ
     continue
    end
    
    if isempty(lmdl)
     M_fg(extFG{k}{1},extFG{k}{2}) = 0;
     continue
    end
    
    if lmdl{1} == -1
     continue
    end

    M_fg(extFG{k}{1},extFG{k}{2}) = HEAD.GMMposterior(sB,lmdl);
   end
  end
  
  function M_of = maskScoreOF(xy,O,Mdl,ext,mrk)
   
   M_of = ones(size(ext));
   P = (HEAD.Dictsize+1) * ones(size(ext));
   Q = ones(size(ext));
   
   O = O(:);
   
   for k = 1:size(xy,1)
    st = Mdl{xy(k,2),xy(k,1)};
    if isempty(st)
     continue
    end
    
    ry = ext{xy(k,2),xy(k,1)}{1};
    rx = ext{xy(k,2),xy(k,1)}{2};
    sO = O(ext{xy(k,2),xy(k,1)}{3});
    %sO = sO(:);
    
    x = [sum(abs(sO)),mexhof(sO)];
    
    bag = st{end};
    
    [rho,cls] = HEAD.bagrho(bag,x(2:end));
    
    p = mrk(P(ry,rx),cls);
    
    p = reshape(p,[numel(ry),numel(rx)]);
    
    Q(ry,rx) = Q(ry,rx) .* p;
    
    P(ry,rx) = cls;
    
    M_of(ry,rx) = M_of(ry,rx) * HEAD.GMMposterior(x(1),st(1:3)) * rho;
    
   end
   
   M_of = M_of .* Q;
   
  end
  
  function Amap = ActiveMap(I,xy,ext)
   Amap = ones(size(I));
   for k = 1:size(xy,1)
    if isempty(ext{xy(k,2),xy(k,1)})
     continue
    end
    ry = ext{xy(k,2),xy(k,1)}{1};
    rx = ext{xy(k,2),xy(k,1)}{2};
    Amap(ry,rx) = Amap(ry,rx) + 1;
   end
   Amap = 1./Amap;
  end

  %% encoding
  
  function [Bag,aM] = encodeBag(B,O,Bag,fbext,n)
   B0 = B(:,:,3);
   B = B(:);
   O = O(:);
   aM = fbext;
   for k = numel(fbext):-1:1
    ry = fbext{k}{1};
    rx = fbext{k}{2};
    rt = fbext{k}{3};
    sB = B(rt);
    N = numel(sB);
    sB = nnz(sB);
    if HEAD.min_occ * numel(B0(ry,rx)) > nnz(B0(ry,rx))
     aM(k) = [];
     continue
    end
    aM{k}(3) = [];
    sO = O(rt);
    Bag{k}{n} = [sB,sum(abs(sO)),mexhof(sO),n];
   end  
  end
  
  function FGbag = encodeFG(B,FGbag,fbext,n)
   B0 = B(:,:,end);
   B0 = B0(:);
   B = B(:);
   for k = 1:numel(fbext)
    sB = B0(fbext{k}{1});
    sB = sum(sB);
    if HEAD.min_occ > sB
     continue
    end
    sB = B(fbext{k}{2});
    sB = sum(sB);
    FGbag{k}{n} = sB;
   end
  end
  
  function FGbag = encodeFGb(B,FGbag,fbext,n)
   B = B(:);
   for k = 1:numel(fbext)
    sB = B(fbext{k}{3});
    sB = sum(sB);
    if HEAD.min_occ > sB
     continue
    end
    FGbag{k}{n} = sB;
   end
  end
  
  function OFbag = encode(xy,O,OFbag,ext,n)
   O = O(:);
   for k = 1:size(xy,1)
    if isempty(ext{xy(k,2),xy(k,1)})
     continue
    end
    sP = O(ext{xy(k,2),xy(k,1)}{3});
    OFbag{xy(k,2),xy(k,1)}{n} = [sum(abs(sP)),mexhof(sP),n];%feature vector;
    
   end
  end
  
  function Frames = stackFrame(Frames,F)
   Frames = circshift(Frames,1,3);
   Frames(:,:,end) = F;
   
%    Frames(:,:,1) = [];
%    Frames(:,:,end+1) = F;
  end
 
  
  %% Model
  
  function Bag = genSMdl(Bag)
   
   for j = 1:numel(Bag)
    des = Bag{j};
    if isempty(des)
     continue
    end
    fb = des(:,1);
    warning('off','all')
    pfb = HEAD.bestGMM(fb,4);
    m = pfb.mu;
    s = pfb.Sigma(:);
    w = pfb.ComponentProportion;
    thfb = {m,s,w};
    
    of = des(:,2);
    warning('off','all')
    pof = HEAD.bestGMM(of,4);
    m = pof.mu;
    s = pof.Sigma(:);
    w = pof.ComponentProportion;
    thof = {m,s,w};
    try
     %bag = des(:,3:end-1);
     k = ceil(2*sqrt(size(des,1)));
     [~,bag] = kmeans(des(:,3:end-1),k,'start','sample','EmptyAction','drop','Replicates',3);
    catch
     bag = des;
    end
    
    gmmFull = HEAD.bestGMM(des(:,1:end-1),4);
    
    warning('on','all')
    
    Bag{j} = {thfb,thof,bag,gmmFull};
   end
   
  end
  
  function Mdl = genMdlstr(OFbag,FBbag,map)
   disp('Building Models ... up to 40mins')
   OFbag = PERS.cleanbag(OFbag);
   MdlOF = HEAD.genMdlOF(OFbag,map);
   disp('Realign Optical Flow Model ...')
   MdlOF = HEAD.resMdl(MdlOF);
   disp('Markov Model ...')
   Lblbag = HEAD.basket2Lbl(OFbag,MdlOF);
   mrk = HEAD.genmrk(Lblbag);
   disp('Building Foreground Model ...')
   fbMdl = HEAD.genfgMdl(FBbag);
   Mdl = struct;
   Mdl.mrk = mrk;
   Mdl.mdl = MdlOF;
   Mdl.fgMdl = fbMdl;
   disp('Finished.')
  end
  
  function MdlOF = genMdlOF(OFbag,map)
   MdlOF = PERS.structMdl(OFbag,map);
   for x = 1:size(MdlOF,2)
    parfor y = 1:size(MdlOF,1)
     des = MdlOF{y,x};
     if size(des,1) < 120
      MdlOF{y,x} = [];
      continue
     end
     of = des(:,1);
     des = des(:,2:end-1);
     warning('off','all')
     pof = HEAD.bestGMM(of,4);
     
     k = HEAD.Dictsize;%k = ceil(2*sqrt(size(des,1)));
     [~,bag] = kmeans(des,k,'start','sample','EmptyAction','drop','Replicates',3);
     warning('on','all')
     
     m = pof.mu;
     s = pof.Sigma(:);
     w = pof.ComponentProportion;
     MdlOF{y,x} = {m,s,w,bag};
    end
   end
  end
  
  function Mdl = resMdl(Mdl)
   ry = 1:size(Mdl,1);
   bagp = [];
   for x = 1:size(Mdl,2)
    ry = fliplr(ry);
    for y = ry
     if isempty(Mdl{y,x})
      continue
     end
     bagn = Mdl{y,x}{4};
     if ~isempty(bagp)
      bagn = HEAD.realignbag(bagn,bagp);
      %subplot(1,2,1)%imagesc(bagp)
     end
     bagp = bagn;
     %subplot(1,2,2)%imagesc(bagn)
     Mdl{y,x}{4} = bagn;
    end
   end
  end

  function fbMdl = genfgMdl(FBbag)
   
   fbMdl = cell(numel(FBbag),1);
   
   parfor k = 1:numel(FBbag)
    c = FBbag{k};
    idx = cellfun(@isempty,c);
    c(idx) = [];
    c = cell2mat(c);
    if isempty(c)
     continue
    end
    warning('off','all')
    GMM = HEAD.bestGMM(c,4);
    warning('on','all')
    
    try
     m = GMM.mu;
     s = GMM.Sigma(:);
     w = GMM.ComponentProportion;
     fbMdl{k} = {m,s,w};
    catch
     fbMdl{k} = {-1,-1,-1};
    end
    
   end
   
  end
  
  function Lblbag = basket2Lbl(OFbag,Mdl)
   Lblbag = cell(size(Mdl));
   for y = 1:size(Mdl,1)
    for x = 1:size(Mdl,2)
     if isempty(Mdl{y,x}) || isempty(OFbag{y,x})
      continue
     end
     des = OFbag{y,x}(:,2:end-1);
     lbl = zeros(size(des,1),1);
     for k = 1:size(des,1)
      idx = abs(bsxfun(@minus,Mdl{y,x}{4},des(k,:)));
      [~,idx] = min(sum(idx,2));
      lbl(k) = idx;
     end
     t = OFbag{y,x}(:,end);
     Lblbag{y,x} = [lbl,t];
    end
   end
  end
  
  function mrk = genmrk(lblbasket)
   
   X = cell2mat(lblbasket(:));
   
   mrk = zeros(HEAD.Dictsize);
   
   if isempty(X)
    mrk = Inf(HEAD.Dictsize);
    return
   end
   
   X = X(:,1);
   
   h = hist(X,1:HEAD.Dictsize);
   
   for k = 1:HEAD.Dictsize
    for j = 1:HEAD.Dictsize
     mrk(j,k) = mrk(j,k) + h(j) + h(k);
    end
   end
   
   mrk = mrk/max(mrk(:));
   
   mrk(:,end+1) = 1;
   mrk(end+1,:) = 1;
   
  end
  
  function bagn = realignbag(bagn,bagp)
   c = zeros(HEAD.Dictsize,1);
   
   idx = isnan(bagn(:,1));
   bagn(idx,:) = 0;
   cbagn = bagn;
   
   for k = 1:HEAD.Dictsize
    idx = abs(bsxfun(@minus,bagn,bagp(k,:)));
    [~,idx] = min(sum(idx,2));
    bagn(idx,:) = NaN;
    c(k) = idx;
   end
   
   bagn = cbagn(c,:);
   
  end
   
  function GMM = bestGMM(X,N)
   
   AIC = Inf(1,N);
   GMModels = cell(1,N);
   options = statset('MaxIter',100);
   for k = 1:N
    try
     GMModels{k} = fitgmdist(X,k,'Options',options,'CovarianceType','diagonal');
     AIC(k)= GMModels{k}.AIC;
    catch
    end
   end
   
   [~,numComponents] = min(AIC);
   
   GMM = GMModels{numComponents};
   
  end

  %% Eval fnc
  
  function p = GMMposterior(x,th)
   m = th{1};
   s = th{2};
   w = th{3};
   x = x-m;
   p = 0;
   for k = 1:numel(m)
    p = p + w(k) * 1/(sqrt(2*pi*s(k))) * exp(-x(k)^2/(2*s(k)));
   end
  end
    
  function [rho,cls] = bagrho(bag,x)
   rho = bsxfun(@minus,bag,x);
   rho = sum(rho.^2,2);
   [rho,cls] = min(rho);
   rho = exp(-rho);
  end
  
  
  %% Visual
    
  function vislcell(I,O,B)
   clf
   subplot(1,2,1)
   imshow(I{2,2})
   hold on
   quiver(real(O{2,2}),imag(O{2,2}))
   subplot(1,2,2)
   imshow(B{2,2})
  end
 
  
 end
end
