function delInterTerms = pruneInterTerms(modelResFile)
% remove interaction terms with small variances
% 
% Lu Cheng
% 23.04.2018

global resDir

assert(exist(modelResFile,'file')>0, sprintf('Model result file %s does not exist, quit!\n',modelResFile));

datafile = sprintf('%s%sdata.mat',resDir,filesep);
load(datafile, 'para','xmn','ymn');
load(modelResFile,'nCfVar','nInterCf');
xmnt = xmn;
[EfArr, ~, empMagArr, ~, cfTerms] = getComponentPredictions(modelResFile, xmnt);

EfArr{end+1} = ymn - sum(cell2mat(EfArr),2);
empMagArr(end+1) = nanvar(EfArr{end});
normEmpMagArr = empMagArr/sum(empMagArr);

nCf = nCfVar + nInterCf;

delInterTerms = {};
for iCf = (nCfVar+1):nCf
    if normEmpMagArr(iCf) < para.comVarCutOff
        delInterTerms{end+1} = cfTerms{iCf};
        fprintf('%s. Component %d %s explains %1.3f%% variance. To be deleted. \n',...
            modelResFile, iCf, cfTerms{iCf}, normEmpMagArr(iCf)*100);
        para.kernel.delInterTerms{end+1} = cfTerms{iCf};
    end
end

save(datafile,'para','-append')

if ~isempty(delInterTerms)
    save(modelResFile, 'delInterTerms', '-append');
end
















