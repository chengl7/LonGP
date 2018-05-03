function [EftArr, empMagArr, normEmpMagArr, cfTerms] = getComponentPredictions(modelResFile, xmnt)
% get predictions of the component on xmnt
% modelResFile: result file of a given model
% xmnt: test data to be predicted
% 
% EftArr: predictions of each component, 1xnCf 
% empMagArr: empirical variance of each component
% normEmpMagArr: normalized empMagArr
% cfTerms: names of the components
% 
% Lu Cheng
% 24.04.2018


assert(exist(modelResFile,'file')>0, sprintf('Model result file %s does not exist, quit!\n',modelResFile));
[resDir,name,ext] = fileparts(modelResFile);

datafile = sprintf('%s/data.mat',resDir);
assert(exist(datafile,'file')>0, sprintf('Data file %s does not exist, quit!\n',datafile))
load(datafile,'para','xmn','ymn');

load(modelResFile,'rfull','nCfVar','nInterCf','cfTerms');

nCf = nCfVar + nInterCf;

EftArr = cell(1,nCf);
empMagArr = zeros(1,nCf);

for iCf = 1:nCf
    EftArr{iCf} = gp_pred(rfull,xmn,ymn,xmnt,'predCf',iCf);
    empMagArr(iCf) = nanvar(EftArr{iCf}); % note the empirical variacne is calculated using xmnt
end

normEmpMagArr = empMagArr/sum(empMagArr);



