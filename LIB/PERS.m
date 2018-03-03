classdef PERS
 
 properties(Constant)
  scY  = 160;
  scX  = 240;
  fgst = 16;
 end
 
 methods(Static = true)

  function [v,f] = videoidx()
   
   Y = PERS.scY;
   X = PERS.scX;
   T = HEAD.dframes;
   
   v = zeros(Y,X,T);
   n = 0;
   for t = 1:T
    for x = 1:X
     for y = 1:Y
      n = n+1;
      v(y,x,t) = n;
     end
    end
   end
   v = uint32(v);
   
   f = zeros(Y,X);
   n = 0;
   for x = 1:X
    for y = 1:Y
     n = n+1;
     f(y,x) = n;
    end
   end
   f = uint32(f);
   
  end
  
  function x = fillgap(x,n)
   k = numel(x);
   i = 0;
   while sum(x) ~= n
    i = i+1;
    if k-i < 1
     i = 0;
    end
    for j = k:-1:k-i
     x(j) = x(j)+1;
     if sum(x) == n
      break;
     end
    end
    
   end   
  end  
  
  function cstr = cellext(ext,scy,vis)
   
   [Y,X] = size(ext);
   
   cstr = cell(1e3,1);
   
   if vis;I = zeros(Y,X);end;
   
   n = round(log(Y/12*(scy-1)+1)/log(scy)-1);
   
   y0 = floor((scy-1)/(scy^(n+1)-1)*Y);
   
   [v,f] = PERS.videoidx();
   
   y = 1;
   bzy = y0 * scy;
   
   ry = zeros(20,1);
   k = 0;
   
   while y + bzy < Y
    k = k+1;
    ry(k) = numel(round(y:y+bzy));
    y = y+bzy;
    bzy = scy * bzy;
   end
   
   bzy = ry(1:k);
   
   bzy = PERS.fillgap(bzy,Y);
   
   y0 = bzy(1)+1;
   n = 0;
   
   for k = 2:numel(bzy)
    m = floor((X/2)/bzy(k));
    bzx = bzy(k) * ones(m,1);
    bzx = PERS.fillgap(bzx,floor(X/2));
    x0 = floor(X/2);
    for j = 1:m
     rx = x0:x0+bzx(j);
     ry = y0:y0+bzy(k);
     x0 = x0+bzx(j);
     n = n+1;
     
     ry = intersect(ry,1:Y);
     rx = intersect(rx,1:X);
     
     a = v(ry,rx,:);
     b = f(ry,rx);
     cstr{n} = {b(:),a(:),{ry,rx}};
     %cstr{n} = {uint16(ry),uint16(rx),a(:)};
     if vis
      I = insertShape(I,'Rectangle',[rx(1),ry(1),numel(rx),numel(ry)],'Color',rand(1,3));
      %I = insertText(I,[rx(1),ry(1)],numel(rx),'FontSize',8);
      imshow(I)
      pause(eps)
     end
    end
    y0 = y0 + bzy(k);
   end
   
   y0 = bzy(1)+1;
   
   for k = 2:numel(bzy)
    m = floor((X/2)/bzy(k));
    bzx = bzy(k) * ones(m,1);
    bzx = PERS.fillgap(bzx,floor(X/2));
    x0 = floor(X/2);
    for j = 1:m
     rx = x0-bzx(j):x0;
     ry = y0:y0+bzy(k);
     x0 = x0-bzx(j);
     n = n+1;
     
     ry = intersect(ry,1:Y);
     rx = intersect(rx,1:X);
     
     a = v(ry,rx,:);
     b = f(ry,rx);
     cstr{n} = {b(:),a(:),{ry,rx}};
     %cstr{n} = {uint16(ry),uint16(rx),a(:)};
     
     if vis
      I = insertShape(I,'Rectangle',[rx(1),ry(1),numel(rx),numel(ry)],'Color',rand(1,3));
      %I = insertText(I,[rx(1),ry(1)],numel(rx),'FontSize',8);
      imshow(I)
      pause(eps)
     end
    end
    y0 = y0 + bzy(k);
   end
   
   cstr = cstr(1:n,:);
   
  end
  
  
  %% Perspective Structures Generation
  
  function [ext,OFbag,FBbag,map] = genscan(alpha_,sf,vis)
   
   [map,extOF] = PERS.genmap(alpha_,sf);
   %extFB = PERS.genfgext(extOF);
   extFB = PERS.cellext(extOF,1.06,vis);
   OFbag = PERS.genbag(map,0);
   FBbag = PERS.genbag(map,numel(extFB));
   
   extFB = PERS.connect(extFB);
   
   ext = struct;
   ext.extOF = extOF;
   ext.extFB = extFB;
   
  end
  
  function extFB = connect(extFB)
   
   cnn = cell(numel(extFB),1);
   
   for k = 1:numel(extFB)
    idx = zeros(1,10);
    n = 0;
    for j = 1:numel(extFB)
     if j ~= k
      rya = extFB{k}{3}{1};
      rya = rya(1)-3:rya(end)+3;
      rxa = extFB{k}{3}{2};
      rxa = rxa(1)-3:rxa(end)+3;
      
      ryb = extFB{j}{3}{1};
      ryb = ryb(1)-3:ryb(end)+3;
      rxb = extFB{j}{3}{2};
      rxb = rxb(1)-3:rxb(end)+3;
      
      if ~isempty(intersect(rya,ryb)) && ~isempty(intersect(rxa,rxb))
       n = n+1;
       idx(n) = j;
      
      end
     end
    end
    cnn{k} = [k,idx(1:n)];
   end
   
   for k = 1:numel(extFB)
    extFB{k}{3} = uint16(cnn{k});
   end
   
  end
  
  function [map,ext] = genmap(alpha_,sf)
   
   Y = PERS.scY;
   X = PERS.scX;
   
   map = zeros(Y,X);
   ext = cell(Y,X);
   
   for y = 1:Y
    alpha_ = alpha_ + sf;
    map(y,:) = alpha_;
   end
   
   n = 0;
   v = zeros(Y,X);
   
   for t = 1:HEAD.dframes
    for x = 1:X
     for y = 1:Y
      n = n+1;
      v(y,x,t) = n;
     end
    end
   end
   
   for x = 1:X
    for y = 1:Y
     rx = x - 1.5 * map(y,x) : x + 1.5 * map(y,x);
     ry = y - 1.5 * map(y,x) : y + 1.5 * map(y,x);
     rx = round(rx);
     ry = round(ry);
     try
      map(ry,rx);
      w = v(ry,rx,:);
      ext{y,x} = {ry,rx,w(:)};
     catch
      map(y,x) = 0;
     end
    end
   end
   
  end
  
  function fgext = genfgext(ext)
   fgext = cell(100,1);
   [Y,X] = size(ext);
   
   v = PERS.videoidx();
   
   n = 0;
   J = zeros(Y,X);
   
   for x = 1:PERS.fgst:X
    for y = 1:PERS.fgst:Y
     if isempty(ext{y,x})
      continue
     end
     ry = ext{y,x}{1};
     rx = ext{y,x}{2};
     n = n+1;
     w = v(ry,rx,:);
     fgext{n} = {ry,rx,w(:)};
     J = insertShape(J,'FilledRectangle',[rx(1),ry(1),numel(rx),numel(ry)],'Color',rand(1,3));
    end
   end
   fgext = fgext(1:n);
   imagesc(J)
  end
  
  function bag = genbag(map,n)
   if n == 0 
    bag = cell(size(map));
    for x = 1:size(map,2)
     for y = 1:size(map,1)
      if map(y,x) > 0
       bag{y,x} = cell(10e3,1);
      end
     end
    end
   else
    bag = cell(n,1);
    for k = 1:n
     bag{k} = cell(10e3,1);
    end
   end   
  end
  
  function bag = cleanbag(bag)
   for y = 1:size(bag,1)
    for x = 1:size(bag,2)
     c = bag{y,x};
     if isempty(c)
      continue
     end
     idx = cellfun(@isempty,c);
     c(idx) = [];
     bag{y,x} = cell2mat(c);
    end
   end
  end
  
  %% Model Structures
  
  function Mdl = structMdl(bag,map)
   
   Mdl = cell(size(bag));
   [Y,X]= size(map);
   
   for y = 1:Y
    for x = 1:X
     if map(y,x) == 0
      continue
     end
     x0 = x - map(y,x) : x + map(y,x);
     y0 = y - map(y,x) : y + map(y,x);
     x0 = round(x0);
     y0 = round(y0);
     x0(or(x0 < 1,x0 > X)) = [];
     y0(or(y0 < 1,y0 > Y)) = [];
     subcell = bag(y0,x0);
     subcell = subcell(:);
     idx = cellfun(@isempty,subcell);
     subcell(idx) = [];
     subcell = cell2mat(subcell);
     if isempty(subcell)
      continue
     end
     Mdl{y,x} = subcell;
    end
   end
   
  end
  
 end
 
end