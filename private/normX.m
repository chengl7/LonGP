function xn = normX(X,nConVar,varargin)
% normalize processed X, 2*(nConVar+nBinVar), no missing values
% Lu Cheng
% 24.04.2018

[~, tmpn] = size(X);
assert(mod(tmpn,2)==0);
assert(tmpn/2>nConVar);

% normalize given specified mean and std
if nargin>2
    for i = 1:nConVar
        xmean = varargin{1};
        xstd = varargin{2};
        tmpflag = X(:,i*2-1)==1;
        X(tmpflag,i*2) = (X(tmpflag,i*2)-xmean(i))/xstd(i);
    end
    xn = X;
    return;
end


nVar = tmpn/2;
xmean = zeros(1,nVar);
xstd = ones(1,nVar);

newX = X;
for i=1:nConVar
    tmpflag = X(:,i*2-1)==1;
    tmpx = X(tmpflag,i*2);
    xmean(i) = mean(tmpx);
    xstd(i) = std(tmpx);
    tmpx = (tmpx-xmean(i))/xstd(i);
    newX(tmpflag,i*2) = tmpx;
end

xn.nConVar = nConVar;
xn.X = newX;
xn.xmean = xmean;
xn.xstd = xstd;