function outFile = parseTestData(xtfFile, xrfFile, xdelimiter, parentDir)
% parse test data with missing values filled in, so plotting is easy
%
% xtfFile: file for test data with missing values filled in, 2x(nConVar+nBinVar) columns
% xrfFile: file for real data with missing values filled in, 2x(nConVar+nBinVar) columns
%
% Lu Cheng
% 30.04.2018

assert(exist(xtfFile,'file')>0);
assert(exist(xrfFile,'file')>0);
assert(exist(parentDir,'dir')>0);

fprintf('\nStart processing test data files: %s and %s.\n', xtfFile, xrfFile);

preprocFile = 'preprocData.mat';
preprocFile = sprintf('%s%s%s',parentDir,filesep,preprocFile);
assert(exist(preprocFile,'file')>0);

outFile = 'testData.mat';
outFile = sprintf('%s%s%s',parentDir,filesep,outFile);

% process xt and xr
XT = dlmread(xtfFile,xdelimiter);  % no headers
assert(~any(isnan(XT(:))),sprintf('Missing values need to be manually imputed in the test data file %s.\n', xtfFile));

XR = dlmread(xrfFile,xdelimiter);  % no headers
assert(~any(isnan(XR(:))),sprintf('Missing values need to be manually imputed in the test data file %s.\n', xrfFile));

load(preprocFile,'normData','para');
nConVar = para.nConVar;
[nr,nc] = size(XT);
assert(nc == 2*(para.nConVar+para.nBinVar));
[nr,nc] = size(XR);
assert(nc == 2*(para.nConVar+para.nBinVar));

newXn = transX(XT, para);
xmnt = normX(newXn,nConVar,normData.X.xmean, normData.X.xstd);

Xt = XT;
for i = 1:(para.nConVar+para.nBinVar)
    fflag = logical(XT(:,2*i-1));
    Xt(~fflag,2*i) = 0;  % remove imputed missing values
end

Xt_mf = XT(:,2:2:end);  % missing value filled

XR_mf = XR(:,2:2:end);

save(outFile,'xmnt','Xt','Xt_mf','XR_mf');

fprintf('Processed test file %s is ready.\n',outFile);