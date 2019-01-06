function [EftArr, VftArr, empMagArr, normEmpMagArr, cfTerms] = getComponentPredictions(modelResFile, xmnt)
% get predictions of the component on xmnt
% modelResFile: result file of a given model
% xmnt: test data to be predicted
% 
% EftArr: predictions of each component, 1xnCf 
% empMagArr: empirical variance of each component
% normEmpMagArr: normalized empMagArr
% cfTerms: names of the components
% 
% added variance output
% 
% Lu Cheng
% 24.04.2018


assert(exist(modelResFile,'file')>0, sprintf('Model result file %s does not exist, quit!\n',modelResFile));
[resDir,name,ext] = fileparts(modelResFile);

idx = strfind(resDir,filesep);
parentDir = resDir(1:idx(end-1));
paraFile = sprintf('%sinput.para.txt',parentDir);
% fprintf('resdir:%s. file: %s\n',resDir,paraFile);

tmppara=parseInputPara(paraFile,'silent');

datafile = sprintf('%s/data.mat',resDir);
assert(exist(datafile,'file')>0, sprintf('Data file %s does not exist, quit!\n',datafile))
load(datafile,'para','xmn','ymn');

delInterTerms = para.kernel.delInterTerms;
conMaskFlag = para.kernel.conMaskFlag;
binMaskFlag = para.kernel.binMaskFlag;
para.kernel = tmppara.kernel;
para.kernel.delInterTerms = delInterTerms;
para.kernel.conMaskFlag = conMaskFlag;
para.kernel.binMaskFlag = binMaskFlag;
para.lik = tmppara.lik;

% fprintf('loading precomputed results, %s.\n',modelResFile);
% tic

if strcmp(name(1:3),'con')
    isCon=true;
    load(modelResFile,'rfull','nCfVar','nInterCf','currVarFlagArr','modelInd');
elseif strcmp(name(1:3),'bin')
    isCon=false;
    load(modelResFile,'p_theta','theta','nCfVar','nInterCf','currVarFlagArr','modelInd');
else
    error('file name %s should either start with "con" or "bin".\n',name);
end

[cf, cfName, modelName, cfTerms, cfPara, cfMagnParaInds, nVar, nInteraction] = genCf(currVarFlagArr, para, num2str(modelInd));
gp = gp_set('lik',para.lik,'cf',cf);
assert(length(cf)== nCfVar + nInterCf)

if isCon
    rfull = update_fh(rfull,gp);
else
    [nr, nc] = size(theta);
    rfull = cell(1,nr);
    for i=1:nr
        rfull{i} = gp_unpak(gp,theta(i,:));
        rfull{i}.ia_weight = p_theta(i);
    end
end
% toc
    
nCf = nCfVar + nInterCf;
EftArr = cell(1,nCf);
VftArr = cell(1,nCf);
empMagArr = zeros(1,nCf);

fprintf('Make predictions for each component.\n')
tic
for iCf = 1:nCf
    [EftArr{iCf}, VftArr{iCf}] = gp_pred(rfull,xmn,ymn,xmnt,'predCf',iCf);
    empMagArr(iCf) = nanvar(EftArr{iCf}); % note the empirical variacne is calculated using xmnt
end
fprintf('Predictions made. ')
t=toc


normEmpMagArr = empMagArr/sum(empMagArr);



