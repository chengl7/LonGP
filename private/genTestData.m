function [xmnt, Xt, Xt_mf, XR_mf] = genTestData(parentDir,varargin)
% generate test data for plotting
%
% 
% xmnt: new X in normalized scale
% Xt: new X in original scale
% Xt_mf: new X in original scale with missing values filled in
% XR_mf: real X value with missing value filled in
% 
% add supports for octave 
%
% Lu Cheng
% 29.12.2018

paraFile = sprintf('%s%spreprocData.mat',parentDir,filesep);
assert(exist(paraFile,'file')>0,sprintf('Parameter file %s does not exist, quit!\n',paraFile));

load(paraFile,'para','normData');

p = inputParser;

if exist('OCTAVE_VERSION', 'builtin')
    p = iparser(p,'addParamValue', 'nTimePointPerId', [], @isnumeric);
    p = iparser(p,'addParamValue', 'ageInd', [], @isnumeric);
    p = iparser(p,'addParamValue', 'RawXFilledFile', [], @ischar);
    
    p = iparser(p,'parse', varargin{:});
    
else
    p.addParamValue('nTimePointPerId', [], @isnumeric);
    p.addParamValue('ageInd', [], @isnumeric);
    p.addParamValue('RawXFilledFile', [], @ischar);

    p.parse(varargin{:});
end

inputs = p.Results;

if isempty(inputs.RawXFilledFile)
    X = denormX(normData.X);  % denormalize to the transformed scale
    X = detransX(X,para);   % detransform to the original scale, only apply to ns kernel, not pe kernel
else
    assert(exist(inputs.RawXFilledFile,'file')>0, sprintf('Raw X file %s with missing value imputed does not exist.\n',inputs.RawXFilledFile));
    X = load(inputs.RawXFilledFile);
    assert(size(X,2)==2*(para.nConVar+para.nBinVar));
    assert(~any(isnan(X(:))), sprintf('All missing values need to be imputed in file %s. \n',inputs.RawXFilledFile));
end

nFC = 10;
idVec = X(:,end);
uniqId = unique(idVec);
origTimePoint = max(histc(idVec,uniqId));
nTimePoint = nFC * origTimePoint;

if ~isempty(inputs.nTimePointPerId)
    nTimePoint = inputs.nTimePointPerId;
end

periodVarInds = find(strcmp(para.kernel.name,'pe'));
if ~isempty(periodVarInds)
    tmpN = length(periodVarInds);
    period = zeros(1,tmpN);
    for ivar = periodVarInds
        assert(ivar<=para.nConVar);
        period(ivar) = para.kernel.conKerArr{ivar}.period;
    end
end

if ~isempty(inputs.ageInd)
    ageInd = inputs.ageInd;
elseif any(strcmp(para.kernel.varName,'age'))
    ageInd = find(strcmp(para.kernel.varName,'age'));
else
    error('Cannot find covariate age, quit!\n');
end

ageVec = X(:,ageInd*2);
minAge = min(ageVec);
maxAge = max(ageVec);

tstAge = linspace(minAge,maxAge,nTimePoint)';

nIndividual = length(uniqId);
data = cell(nIndividual,1);
data1 = cell(nIndividual,1);

nConVar = para.nConVar;
nBinVar = para.nBinVar;

for i=1:nIndividual
    id = uniqId(i);
    tmpInds = idVec==id;
    tmpdata = zeros(nTimePoint,2*(nConVar+nBinVar));
    tmpagevec = ageVec(tmpInds);
    tmpdata1 = tmpdata;
    
    for ivar = 1:nConVar
        tmpVarInds = ivar*2-1:ivar*2;
        
        if any(strcmp(para.kernel.name{ivar},{'se','ns'}))
            
            if ~isempty(inputs.RawXFilledFile) && exist(inputs.RawXFilledFile,'file')>0
                tmpdata1(:,tmpVarInds) = procSEVar2(X(tmpInds,tmpVarInds), tmpagevec, tstAge);  % user provide imputed values for missing values
            else
                ttflag = logical(X(:,ivar*2-1));
                tmpdiff = nanmean(X(ttflag,ivar*2) - X(ttflag,ageInd*2));            
                % fill missing values, e.g. disease age of controls, disease date of control is set to the average of all cases 
                tmpdata1(:,tmpVarInds) = procSEVar1(X(tmpInds,tmpVarInds), tmpagevec, tstAge, tmpdiff); 
            end
            
            tmpdata(:,tmpVarInds) = procSEVar(X(tmpInds,tmpVarInds), tmpagevec, tstAge);
        end
        
        if any(strcmp(para.kernel.name{ivar},{'pe'}))
            tmpdata(:,tmpVarInds) = procPeriod(X(tmpInds,tmpVarInds), tmpagevec, tstAge, period(ivar));
            tmpdata1(:,tmpVarInds) = tmpdata(:,tmpVarInds);
        end
    end
    
    for ivar = nConVar+(1:nBinVar)
        tmpVarInds = ivar*2-1:ivar*2;
        tmpdata(:,tmpVarInds) = procBinVar(X(tmpInds,tmpVarInds), nTimePoint);
        tmpdata1(:,tmpVarInds) = tmpdata(:,tmpVarInds);
    end
    
    data{i} = tmpdata;
    data1{i} = tmpdata1;
end

newX = cell2mat(data);
newXn = transX(newX, para);
xmnt = normX(newXn,nConVar,normData.X.xmean, normData.X.xstd);

Xt = newX;
Xt_mf = cell2mat(data1);

outTestFile = sprintf('%s%stestdata.filled.txt',parentDir,filesep);
dlmwrite(outTestFile, Xt_mf,'\t');

Xt_mf = Xt_mf(:,2:2:end);  % missing value filled

XR = X;  % X raw
for ivar=1:nConVar
    ttflag = logical(X(:,ivar*2-1));
    tmpdiff = nanmean(X(ttflag,ivar*2) - X(ttflag,ageInd*2));
    XR(~ttflag,ivar*2) = X(~ttflag,ageInd*2)+tmpdiff;
end

outRawFile = sprintf('%s%srawdata.filled.txt',parentDir,filesep);
dlmwrite(outRawFile, XR,'\t');

XR_mf = XR(:,2:2:end);

testdataFile = sprintf('%s%stestData.mat',parentDir,filesep);
save(testdataFile,'Xt','Xt_mf','XR_mf','xmnt');

end

function y = procSEVar2(origX, origAgeVec, newAgeVec)
xVec = origX(:,2);
tmpdiff = nanmean(xVec - origAgeVec);

assert(all(xVec - origAgeVec - tmpdiff < 1e-2));

newX = newAgeVec + tmpdiff;
newFlag = ones(size(newAgeVec));

y = [newFlag newX];
end

function y = procSEVar1(origX, origAgeVec, newAgeVec, avgDiff)
flagVec = origX(:,1);
xVec = origX(:,2);

% cases, disease related 
if all(flagVec==0)
    y = zeros(length(newAgeVec),2);
    y(:,2) = newAgeVec + avgDiff;
    return;
end

tmpdiff = nanmean(xVec - origAgeVec);

assert(all(xVec - origAgeVec - tmpdiff < 1e-2));

newX = newAgeVec + tmpdiff;
newFlag = ones(size(newAgeVec));

y = [newFlag newX];
end

function y = procSEVar(origX, origAgeVec, newAgeVec)
flagVec = origX(:,1);
xVec = origX(:,2);

% cases, disease related 
if all(flagVec==0)
    y = zeros(length(newAgeVec),2);
    return;
end

tmpdiff = nanmean(xVec - origAgeVec);

assert(all(xVec - origAgeVec - tmpdiff < 1e-2));

newX = newAgeVec + tmpdiff;
newFlag = ones(size(newAgeVec));

y = [newFlag newX];
end

function y = procPeriod(origX, origAgeVec, newAgeVec, period)
flagVec = origX(:,1);
xVec = origX(:,2);

% cases, disease related 
if all(flagVec==0)
    y = zeros(length(newAgeVec),2);
    return;
end

tmpdiff = nanmean(mod(xVec - origAgeVec, period));

assert(all(mod(xVec - origAgeVec, period) - tmpdiff < 1e-1));

newX = newAgeVec + tmpdiff;
newFlag = ones(size(newAgeVec));

y = [newFlag newX];
end

function y = procBinVar(origX, nTimePoint)
flagVec = origX(:,1);
xVec = origX(:,2);

assert(all(xVec==xVec(1)))

% cases, disease related 
if all(flagVec==0)
    y = zeros(nTimePoint,2);
    return;
end

newFlag = ones(nTimePoint, 1);
newX = xVec(1) + zeros(nTimePoint, 1);

y = [newFlag newX];
end





