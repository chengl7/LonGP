function X = denormX(xn)
% xn: normData.X

nvar = size(xn.X,2)/2;

X = xn.X;
for i=1:nvar
    tmpflag = X(:,i*2-1)==1;
    X(tmpflag,2*i) = xn.X(tmpflag,i*2)*xn.xstd(i) + xn.xmean(i);
end