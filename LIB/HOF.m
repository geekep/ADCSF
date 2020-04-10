% HOF.c is the function to generate HOF descriptor.
classdef HOF
 
 properties(Constant)
  bins = HOF.genbins(10);
  K  = numel(HOF.bins)/2;
 end
 
 methods(Static = true)

  %%2D
  
  function des = encode2(G)
   %HOF.visualize(G,sv);
   des = HOF.binsHist(G);
   %des = des';
  end
  
  function his = binsHist(G)
   G = G(:);
   mag = abs(G);
   his = zeros(1,HOF.K);

   ang = G./(mag+eps);
   ang = abs(bsxfun(@minus,ang,HOF.bins));
   
   [~,ang] = min(ang,[],2);
   
   for k = 1:HOF.K
    idx = or(ang == k,ang == k+HOF.K);
    his(k) = sum(mag(idx));
   end
   
   his = his/(norm(his)+eps);
   
   %his(his > 0.2) = 0.2;
   
   %his = his/(norm(his)+eps);
   
   
  end
  
  
  function des = encode(varargin)
   
   sv = varargin{1};
   
   if nargin > 1
    bn = HOF.genbins(varargin{2});
   else
    bn = HOF.genbins(10);
   end
   
   G = HOF.svof(sv);
   
   %HOF.visualize(G,sv);
   
   Y = HOF.splitInt(size(G,1),3);
   X = HOF.splitInt(size(G,2),3);
   T = HOF.splitInt(size(G,3),2);
   
   G = mat2cell(G,Y,X,T);
   G = G(:);
   
   G = cellfun(@(x) HOF.binsHist(x,bn),G,'UniformOutput',false);
   
   des = cell2mat(G)';
  
  end
  
  function G = svof(sv)
   
   
   a = mat2cell(sv,size(sv,1),size(sv,2),ones(size(sv,3),1));
   a = squeeze(a);
   
   of = opticalFlowLK;
   
   G = cell(1,numel(a));
   
   for k = 1:numel(a)
    
    flow = estimateFlow(of,a{k});
    
    G{k} = flow.Vx + 1j * flow.Vy;
    
   end
   
   G = reshape(cell2mat(G),[size(G{1}),numel(G)]);
   
   G(:,:,1) = [];
   G(:,1,:) = [];G(:,end,:) = [];
   G(1,:,:) = [];G(end,:,:) = [];
   
%    b = a;
%    b(1) = [];
%    a(end) = [];
%    
%    G = cellfun(@(x,y)...
%     cv.calcOpticalFlowFarneback(x,y),a,b,'UniformOutput',false);
%    
%    G = cellfun(@(x) HOF.mat2cmpx(x),G,'UniformOutput',false);
%    
%    G = G';
%   
%    G = reshape(cell2mat(G),[size(G{1}),numel(G)]);
%    
%    G(:,1,:) = [];G(:,end,:) = [];
%    G(1,:,:) = [];G(end,:,:) = [];
   
  end
  
  function C = mat2cmpx(A)
   C = medfilt2(A(:,:,2)) + 1j* medfilt2(A(:,:,1));
  end
  
  function bn = genbins(n)
   
   bn = 0:2*pi/n:2*pi;
   bn(end) = [];
   bn = cos(bn) + 1j * sin(bn);
   %{
   clf
   for k = 1:numel(bn)
    quiver(real(bn(k)),imag(bn(k)))
    hold on
   end
   %}
  end
 
  function his = binsHistb(G,bins)
   
   G = G(:);
   mag = abs(G);
   K = numel(bins)/2;
   his = zeros(K,1);
 
   ang = G./(mag+eps);
   
   ang = abs(repmat(ang,[1,2*K]) - repmat(bins,[numel(ang),1]));
   
   [~,ang] = min(ang,[],2);
   for k = 1:K
    idx = or(ang == k,ang == k+K);
    his(k) = sum(mag(idx));
   end
   
   his = his/(norm(his)+eps);
   
   %his(his > 0.2) = 0.2;
   
   %his = his/(norm(his)+eps);
   
   
  end
  
  function s = splitInt(a,n)
   x = floor(a/n);
   s = x * ones(n,1);
   m = 0;
   while sum(s) ~= a
    m = m+1;
    s(m) = s(m)+1;
   end
  end
  
  function visualize(G,sv)
   
   sv = sv(:,:,1:end-1);
   
   figure
   for k = 1:size(G,3)
    imshow(uint8(255*sv(:,:,k)))
    hold on
    quiver(real(G(:,:,k)),imag(G(:,:,k)))
    pause(0.5)
   end
   
   clf
   [X,Y,Z] = meshgrid(1:size(G,1),1:size(G,2),1:size(G,3));
   quiver3(X,Y,Z,real(G),imag(G),zeros(size(G)));
   xlabel('y');ylabel('x');zlabel('t');
  end
  
  
 
  
 end
end