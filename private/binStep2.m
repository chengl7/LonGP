function binStep2(stepId, varInd)

global currVarFlagArr
global currModelName
global bin

global resDir
global nLockTrial
global statefile

global nextFun
global nextArg
global nextArgArr

global DEBUG
if DEBUG
    fprintf('\nin binStep2, stepId=%d, varInd=%d\n',stepId, varInd);
end

modelInd = findModelIndex(bin.modelMat, [bin.selVarInds varInd]);
tmpCurrVarFlagArr = currVarFlagArr;
tmpCurrVarFlagArr(bin.workVarInds([bin.selVarInds varInd])) = true;
runScvInfer(tmpCurrVarFlagArr, modelInd);

% check if all results ready
binModelInds = [];
modelResArr = bin.modelResArr;
for iVar = bin.toSelVarInds
    modelInd = findModelIndex(bin.modelMat, [bin.selVarInds iVar]);
    binModelInds = [binModelInds modelInd];
    resfile = sprintf('%s/bin-%d.mat',resDir, modelInd);
    resfilename = sprintf('bin-%d.mat', modelInd);
    if ~exist(resfile,'file')
        return;
    else
        modelResArr{modelInd} = resfilename;
    end
end

% set next if all results ready
baseModelInd = bin.selModelPath(stepId);
[flag, selModelInd] = cmpBinModels(baseModelInd, binModelInds, stepId);

if flag==0
    % no var selected
    fprintf('\nNo variables selected in this round. Stop binary phase. \n\n');
    
    if obtainStateLock1(statefile, nLockTrial)
        load(statefile,'bin','nextFun','nextArg','nextArgArr');
        
        bin.modelResArr = modelResArr;
        bin.ithVar = stepId - 1;
        bin.finished = true;
        nextFun = [];
        nextArg = [];
        nextArgArr = [];
        
        save(statefile,'bin','nextFun','nextArg','nextArgArr','-append');
        releaseStateLock1(statefile);
    else
        error('not able to obtain state lock after %d trials.\n', nLockTrial);
    end               

elseif flag==1

    selVarInd = bin.toSelVarInds(binModelInds==selModelInd);

    fprintf('\nbin Variable %d, model %d selected.\n\n', bin.workVarInds(selVarInd), selModelInd);

    if obtainStateLock1(statefile, nLockTrial)
        load(statefile,'bin','nextFun','nextArg','nextArgArr');
        
        bin.modelResArr = modelResArr;
        bin.selVarInds(end+1) = selVarInd;
        bin.toSelVarInds = bin.toSelVarInds(binModelInds~=selModelInd);            
        bin.selModelPath(end+1) = selModelInd;
        bin.ithVar = stepId + 1;
        currVarFlagArr(bin.workVarInds(selVarInd)) = true;

        resfile = sprintf('%s/bin-%d.mat',resDir,selModelInd);
        load(resfile,'modelName');
        currModelName = modelName;

        nextFun = @binStep1;
        nextArg = {stepId+1};
        nextArgArr = [];
        
        save(statefile,'bin','nextFun','nextArg','nextArgArr','currModelName','currVarFlagArr','-append');
        releaseStateLock1(statefile);
    else
        error('not able to obtain state lock after %d trials.\n', nLockTrial);
    end
                  
else
    error('flag should be 0 or 1.')
end
            
