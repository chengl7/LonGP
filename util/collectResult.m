function collectResult(parentDir)
% collect all results in mat file into an excel file
% 
% Lu Cheng
% 30.04.2018

assert(exist(parentDir,'dir')>0);
preprocFile = sprintf('%s%spreprocData.mat',parentDir,filesep);
load(preprocFile,'para','normData');
nTarget = length(normData.Y.targetNames);

outFile = sprintf('%s%sfinalResult.xlsx',parentDir,filesep);

targetNames = normData.Y.targetNames';
nVar = para.nConVar + para.nBinVar;
selVarMat = zeros(nTarget,nVar);
modelArr = cell(nTarget,1);
finalFlagArr = zeros(nTarget,1);

for iTarget=1:nTarget
    tmpResFile = sprintf('%s/Results/%d/finalResult.mat',parentDir,iTarget);
    
    if exist(tmpResFile,'file')==0
        fprintf('Result file %s is not ready, skip.\n',tmpResFile);
        modelArr{iTarget} = 'none';
        finalFlagArr(iTarget) = 0;
        continue;
    end
    
    load(tmpResFile,'currVarFlagArr','model','finalFlag','varNames');
    selVarMat(iTarget,:) = currVarFlagArr;
    modelArr{iTarget} = model.description.long;
    finalFlagArr(iTarget) = finalFlag;
end

[~,idx] = sort(modelArr);
colNames = [{'targetID','targetName','modelName','convergeFlag'} varNames];

tmpMat = cell(1,nVar);
for i=1:nVar
    tmpMat{i} = selVarMat(idx,i);
end

tbl = table(idx, targetNames(idx),modelArr(idx),finalFlagArr(idx),tmpMat{:});
tbl.Properties.VariableNames = colNames;

writetable(tbl, outFile);

outVarFile = sprintf('%s%svarExplained.txt',parentDir,filesep);
fid = fopen(outVarFile,'w+');
for iTarget=idx'
    tmpResFile = sprintf('%s/Results/%d/finalResult.mat',parentDir,iTarget);
    
    if exist(tmpResFile,'file')==0
        fprintf(fid,'\n');
        continue;
    end
    
    load(tmpResFile,'components');
    fprintf(fid,'%s\n',num2str(components.normEmpMagArr*100,'%2.1f%%\t'));
end
fclose(fid);

% copy tbl1 and 'varExplained.txt' to the excel file

