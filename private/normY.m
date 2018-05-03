function yn = normY(Y)
% normalize Y, each column vector is a target variable and can contain
% missing values
% Lu Cheng
% 16.03.2018

[~, tmpn] = size(Y);

nTarget = tmpn;
ymean = zeros(1,nTarget);
ystd = ones(1,nTarget);
yflag = zeros(size(Y));

newY = Y;
for i=1:nTarget
    tmpy = Y(:,i);
    tmpflag = ~isnan(tmpy);
    yflag(:,i) = tmpflag;
    ymean(i) = mean(tmpy(tmpflag));
    ystd(i) = std(tmpy(tmpflag));
    tmpy(tmpflag) = (tmpy(tmpflag)-ymean(i))/ystd(i);
    newY(:,i) = tmpy;
end

yn.nTarget = nTarget;
yn.Y = newY;
yn.ymean = ymean;
yn.ystd = ystd;
yn.yflag = yflag;