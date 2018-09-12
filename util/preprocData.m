function [para, normData]=preprocData(paraFile)
% process parameter file, raw data
% Lu Cheng
% 12.03.2018

% parse parameter file
para=parseInputPara(paraFile);

% parse raw data
resDir = para.resDir;
assert(exist(resDir,'dir')>0, sprintf('Result directory %s does not exist!\n',resDir));

% require paraFile to be in resDir
[~,tmpfn,tmpsuf]=fileparts(paraFile);
tmpfile = sprintf('%s%s%s%s',resDir,filesep,tmpfn,tmpsuf);
assert(exist(tmpfile,'file')>0, sprintf('The input parameter file %s is not in the specified directory %s.\n',paraFile,resDir));
    
rawfile=parseRawData(para.inputX.file, para.inputX.isCol, para.inputX.delimiter,...
    para.inputY.file, para.inputY.isCol, para.inputY.delimiter, resDir);

% check consistency of the input data with the specifed parameters
rawdata = load(rawfile);

assert(length(rawdata.varNames)==para.nConVar+para.nBinVar,...
    'covariates number does not agree between parameter file and raw data.\n');
for i=1:para.nConVar+para.nBinVar
    assert(strcmp(para.kernel.varName{i},rawdata.varNames{i}),...
        sprintf('covariate %d do not agree between parameter file (%s) and raw data (%s).\n',...
        i, para.kernel.varName{i}, rawdata.varNames{i}));
end

% construct new data
nConVar = para.nConVar;
nBinVar = para.nBinVar;

[nTime, nVar] = size(rawdata.X);
nTarget = length(rawdata.targetNames);

X = zeros(nTime,nVar*2);
targetMat = rawdata.Y;

fixedVarInds = find(para.kernel.varflag);
workVarInds = find(para.kernel.varflag==0);

xFlag = zeros(nTime,nVar);
for i=1:nVar
    tmpflag = ~isnan(rawdata.X(:,i));
    xFlag(:,i) = tmpflag;
    X(:,i*2-1) = tmpflag;
    X(tmpflag,i*2) = rawdata.X(tmpflag,i);
end

% check the the cat/bin covariates
tmpid = X(:,end);
tmpuniqid = unique(tmpid);
for tmp1 = tmpuniqid(:)'
    tmpIdInds = find(tmpid==tmp1);
    for tmpivar = nConVar+(1:nBinVar)
        tmpFlag = X(tmpIdInds,tmpivar*2-1)==1;
        tmpInds = tmpIdInds(tmpFlag);
        if ~isempty(tmpInds) && ~all(X(tmpInds,tmpivar*2)==X(tmpInds(1),tmpivar*2))
            fprintf('uniqid=%d ivar=%d %s\n',tmp1,tmpivar,para.kernel.varNames{tmpivar});
            X(tmpIdInds,tmpivar*2)
            error('The binary/categorical variable for the same individual do not have the same value.\n');
        end
    end
end

clear tmp*

% transform in case of ns kernel, periodic kernel
X = transX(X, para);

% normalization X
normData.X = normX(X, nConVar);

% normalize Y
normData.Y = normY(targetMat);
normData.Y.targetNames = rawdata.targetNames;

para.fixedVarInds = fixedVarInds;
para.workVarInds = workVarInds;

outFile = sprintf('%s%spreprocData.mat',resDir,filesep);
save(outFile,'para','normData');

% generate test file
if para.test.flag
    if ~isempty(para.test.RawXFilledFile) && isempty(para.test.testXFilledFile)
        genTestData(para.resDir,'ageInd',para.test.ageInd,'RawXFilledFile',para.test.RawXFilledFile);
    elseif ~isempty(para.test.RawXFilledFile) && ~isempty(para.test.testXFilledFile)
        xtfFile = para.test.testXFilledFile;
        xrfFile = para.test.RawXFilledFile;
        parseTestData(xtfFile, xrfFile, para.test.delimiter, para.resDir);
    else
        genTestData(para.resDir,'ageInd',para.test.ageInd);
    end
end
