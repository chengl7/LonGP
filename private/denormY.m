function Y = denormY(yn)
% denormalize yn, each column vector is a target variable and can contain
% missing values
%
% yn: normData.Y
%
% Lu Cheng
% 16.03.2018

Y = yn.Y;
for i=1:yn.nTarget
    Y(:,i) = yn.Y(:,i)*yn.ystd(i) + yn.ymean(i);
end

