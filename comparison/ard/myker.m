function y = myker(XN, XM, theta)
% https://se.mathworks.com/help/stats/fitrgp.html#namevaluepairarguments
% Fit GPR Model Using Custom Kernel Function

origTheta = exp(theta);

lenVar = origTheta(1:end-1);
sigVar = origTheta(end);


[n,d1] = size(XN);
[m,d2] = size(XM);

assert(d1==d2);
nConVar = 2;
nBinVar = 4;

assert(d1==(nConVar+nBinVar));

y = zeros(n,m);

% age,sero,loc,gen,group,id
flagVec1 = XN(:,5)>0;
flagVec2 = XM(:,5)>0;

% age
for i=1:nConVar-1
    tmpval1 = XN(:,i);
    tmpval2 = XM(:,i);
    tmpdist = pdist2(tmpval1,tmpval2).^2;
    y = y - 0.5 * tmpdist/lenVar(i);
end

% dise
for i=nConVar
    tmpval1 = XN(:,i);
    tmpval2 = XM(:,i);
    
    tmpflagdist = calBinDist(flagVec1, flagVec2);
    tmpdist = pdist2(tmpval1,tmpval2).^2;
    tmpdist(~tmpflagdist) = 4;
        
    y = y - 0.5 * tmpdist/lenVar(i);
end

isBinArr = [0 0 1 1 1 0]>0; % age,sero,loc,gen,group,id
for i=nConVar+(1:nBinVar)

    tmpval1 = XN(:,i);
    tmpval2 = XM(:,i);
    
    if isBinArr(i)
        tmpflagdist = calBinDist(tmpval1,tmpval2)>0;
    else
        tmpflagdist = calCatDist(tmpval1,tmpval2)>0;
    end
    
    tmpdist(tmpflagdist) = 0;
    tmpdist(~tmpflagdist) = 4;
    
    y = y - 0.5 * tmpdist/lenVar(i);
end

y = sigVar * exp(y);


function y = calBinDist(x1,x2)
% return the pairwise binary distance
% return 1 only when both x1 and x2 equal 1

y = bsxfun(@and,x1,x2');


function y = calCatDist(x1,x2)
% return the pairwise categorical distance
% return 1 only when x1 equals x2 

y = bsxfun(@eq,x1,x2');