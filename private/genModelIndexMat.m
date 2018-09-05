function [modelIndMat, nModel] = genModelIndexMat(nVar)

if nVar==0
    modelIndMat=[];
    nModel=0;
    return;
end

nModel = 2^nVar;
% tmpArr = de2bi(0:nModel-1,nVar,'left-msb');
tmpArr = myde2bi(nVar);

tmpArr1 = [sum(tmpArr,2) tmpArr+0];
tmpArr1 = sortrows(tmpArr1);

modelIndMat = logical(tmpArr1(:,2:end));

function y = myde2bi(nVar)

nModel = 2^nVar;
y = zeros(nModel, nVar);

for i=0:nModel-1
    val = i;
    for j=nVar:-1:1
        y(i+1,j) = rem(val,2);
        val = floor(val/2);
    end
end

% testy = de2bi(0:nModel-1,nVar,'left-msb');
% assert(all(all(y==testy)))