function [modelIndMat, nModel] = genModelIndexMat(nVar)

if nVar==0
    modelIndMat=[];
    nModel=0;
    return;
end

nModel = 2^nVar;
tmpArr = de2bi(0:nModel-1,nVar,'left-msb');

tmpArr1 = [sum(tmpArr,2) tmpArr+0];
tmpArr1 = sortrows(tmpArr1);

modelIndMat = logical(tmpArr1(:,2:end));