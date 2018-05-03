function genComPrediction(parentDir,targetInd)

if ischar(targetInd)
    targetInd = str2double(targetInd);
end

resDir = sprintf('%s%sResults%s%d', parentDir, filesep, filesep, targetInd);

dataFile = sprintf('%s%sdata.mat', resDir, filesep);
predFile = sprintf('%s%spredData.mat', resDir, filesep);
testFile = sprintf('%s%stestData.mat', parentDir, filesep);
modelResFile = sprintf('%s%scon-0.mat', resDir, filesep);

if exist(predFile,'file')>0
    fprintf('Prediction file %s exist. Quit making new predictions.\n',predFile);
    return;
else
    fprintf('Making new predictions for test data file %s.\n',testFile);
end

load(dataFile,'ystd');
load(testFile,'xmnt','Xt_mf','XR_mf');

[EftArr, empMagArr, normEmpMagArr, cfTerms] = getComponentPredictions(modelResFile, xmnt);

EffArr = EftArr(:)';

for i=1:length(EftArr)
    EffArr{i} = EftArr{i}*ystd;
end

yt = cell2mat(EffArr);
save(predFile,'Xt_mf','XR_mf','yt');

predTextFile = sprintf('%s%stestData.pred.txt', resDir, filesep);
dlmwrite(predTextFile,yt,'delimiter','\t');