classdef ANOMALY
 properties(Constant)
  reddyRhoth = 0.95;
 end
 
 methods(Static = true)

  %% Inference main
  
  function test = infcellHEAD(des,model,th)
   
   if isempty(model) || isempty(des)
    test = false;
    return
   end
   
   pof = model{1};
   pfg = model{2};
   bag = model{3};
   
   
   pof = pof.pdf(des(1));
   pfg = pfg.pdf(des(2));
   
   %rho = HEAD.bagrho(bag,des(3:end));
   rho = HEAD.bagrho(bag,des);

   pde = exp(-rho^2);
   
   x = [pof,pfg,pde];
   
   test = -log(prod(x(3))) > th;
   
   if test
    disp(-log(x))
   end
%    test = -log(sum(x)) > th;
   
   %{ 
   %individual thresholds
   test = pm < th(1) && ps < th(2);
   
   if test
    bag = model{3};
    rho = sum(abs(bsxfun(@minus,bag,des(3:end))),2);
    pd = min(rho)+eps;
    test = pd > th(3);
   end
   
   %}
   
   
  end
  
  function test = infcellREDDY(des,model,th)
   
   if isempty(model) || isempty(des)
    test = false;
    return
   end
   
   pm = model{1};
   ps = model{2};
   
   pm = pm.pdf(des(1));
   ps = ps.pdf(des(2));
   
   test = pm < th && ps < th;
   
   if test
    bg = model{3};
    rho = cellfun(@(var) REDDY.pearson(des(3:end),var),bg,'UniformOutput',false);
    rho = cell2mat(rho);
    p3 = max(rho);
    test = p3 < ANOMALY.reddyRhoth;
   end
   
  end
   
  %% Inference Neighbourhood
  
  function an = anomalnn(c,acs)
   c = cell2mat(c);
   an = zeros(numel(c),1);
   for k = 1:numel(c)
    if c(k) && nnz(c(acs{k})) > 1%2
     an(k) = nnz(c(acs{k}));
    else
     an(k) = 0;
    end
   end
  end
  
  function an = anomalnn3(cc)
   if isempty(cc{end})
    an = [];
    return
   end
   cc = cell2mat(cc);
   idx = sum(cc,2) > 1;%2
   an = mat2cell(idx,ones(size(idx)));
  end
  
  %% ROC Analysis
  
  function [TPR,FPR] = CorrectDetectionRate(GTD,CAD,IAD,th)
   
   TP = sum(CAD >= th * GTD + eps);
   
   FN = numel(GTD) - TP;
   
   FP = sum(and(GTD == 0, IAD > 0));
   
   TN = numel(GTD) - FP;
   
   TPR = TP/(TP+FN+eps);
   FPR = FP/(FP+TN+eps);

  end
  
  function AUC = ROCanalysis(TPR,FPR)
   
   labels = [true(numel(TPR),1);false(numel(FPR),1)];
   scores = [TPR;FPR];
   
   figure
   
   [X,Y,~,AUC] = perfcurve(labels,scores,true);
   
   plot(X,Y)
   ylabel('True Positive Rate')
   xlabel('False Positive Rate')
   title('ROC for Classification by Logistic Regression')
   %disp(AUC)
   
  end
  
  %% Improved
  
  function scores = inference(coding,model)
   
   evn = false(numel(coding{1}),numel(coding));
   
   for k = 1:numel(coding)
    evn(:,k) = cellfun(@isempty,coding{k});
   end
   
   t0 = sum(evn(:,1:HEAD.dframes-1),2) == 0;
   if nnz(t0) > 0
    x = {coding{1}{t0};coding{2}{t0};coding{3}{t0};coding{4}{t0}};%coding{5}{t0}};
    y0 = ANOMALY.anseq(t0,x,model);
   else
    y0 = [];
   end
   
   t1 = sum(evn(:,2:HEAD.dframes),2) == 0;
   if nnz(t1) > 0
    x = {coding{2}{t1};coding{3}{t1};coding{4}{t1};coding{5}{t1}};%coding{6}{t1}};
    y1 = ANOMALY.anseq(t1,x,model);
   else
    y1 = [];
   end
    
   scores = {t0,t1,y0,y1};
   
  end
  
  function y = anseq(idx,x,model)
   
   x = cell2mat(x);
   x = mat2cell(x,HEAD.dframes-1,4*ones(1,size(x,2)/4));
   x = x';
   y = cellfun(@(a,b) ANOMALY.localanomaly(a,b),x,model(idx,4),'UniformOutput',false);
   y = cell2mat(y);
   %idx = y;
   %idx = find(idx);
   %idx = idx(y);
   
  end
  
  function score = localanomaly(x,model)
   
   pof    = model{1};
   bagOF  = model{3};
   
   dof = x(:,1);
   
   
   a = pof.pdf(dof(1))+realmin;
   %a = prod(a);
   
   dof = dof'/sum(dof);
   
   b = HEAD.bagrho(bagOF,dof);
   b = exp(-b(1));
   
   c = prod(exp(-x(:,3)));
   
   
   score = -log([a,c]);

   
  end
  
  function [I,M,J] = AnomalousFrame(Frame,scores,model,th,vis)
   
   I = Frame.I{1};
   J = Frame.J{1};
   M = false(size(I));
   
   if numel(size(I)) ~= 3
    I = cat(3,I,I,I);
    J = cat(3,J,J,J);
   end
   
   idx = find(and(scores{1},scores{2}));
   
   if isempty(idx)
    I = [I,J];
    J = Frame.J{1};
    return
   end
   
   model = model(idx,:);
   
   idx = scores{2}(idx);
   
   model = model(idx,:);
   
   y0 = scores{3}(idx,:);
   y1 = scores{4}(idx,:);
   
   %y0 = [y0,y1];
   
   [Y,X,~] = size(I);
   
   for k = 1:size(model,1)
    ry = model{k,1};
    rx = model{k,2};
    
    p0 = prod(y0(k,:));
    p1 = prod(y1(k,:));
    
    I = insertText(I,...
     [rx(1),ry(1)],...
     [num2str(p0,2),num2str(p1,2)],...
     'BoxColor',0.0*rand(1,3),...
     'BoxOpacity',0,...
     'FontSize',8,...
     'TextColor','White');
    
    if p0 > th && p1 > th
     ry = [ry-5,ry+5];
     
     ry(or(ry < 1,ry > Y)) = [];
     
     rx = [rx-5,rx+5];
     
     rx(or(rx < 1,rx > X)) = [];

     disp(p0)
     I(ry,rx,1) = 1;
     M(ry,rx) = true;
    else
     I(ry,rx,3) = 1;
    end
    
   end
   
   I = [I,J];
   J = Frame.J{1};
   
  end
  
 end
end