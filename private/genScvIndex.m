function [trindex, tstindex] = genScvIndex(id)
% id is a column vector, each element represents a time point,
% the time point belongs to a certain individual
% 
% Lu Cheng
% 16.03.2016

uniqIdVec = unique(id)';
nIndividual = length(uniqIdVec);
trindex = cell(1,nIndividual);
tstindex = cell(1,nIndividual);
tmpCnt = zeros(1,nIndividual);
for k = uniqIdVec
    tmpTst = id==k;
    tmpCnt(k) = sum(tmpTst);
    trindex{k} = find(~tmpTst);
    tstindex{k} = find(tmpTst);
end    
trindex(tmpCnt==1) = [];  % not good for kfcv
tstindex(tmpCnt==1) = [];
