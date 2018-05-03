function conStep2(stepId, varInd)

global currVarFlagArr
global currModelName
global con

global resDir
global nLockTrial
global statefile

global nextFun
global nextArg
global nextArgArr

assert(~isempty(varInd))

global DEBUG
if DEBUG
    fprintf('\nin conStep2, stepId=%d, varInd=%d\n',stepId, varInd);
end

% run for the chosen model
modelInd = findModelIndex(con.modelMat, [con.selVarInds varInd]);
tmpCurrVarFlagArr = currVarFlagArr;
tmpCurrVarFlagArr(con.workVarInds([con.selVarInds varInd])) = true;
runMcmcInfer(tmpCurrVarFlagArr, modelInd);

% check if all results ready
conModelInds = [];
modelResArr = con.modelResArr;
for iVar = con.toSelVarInds
    modelInd = findModelIndex(con.modelMat, [con.selVarInds iVar]);
    conModelInds = [conModelInds modelInd];
    resfile = sprintf('%s%scon-%d.mat',resDir, filesep,modelInd);
    resfilename = sprintf('con-%d.mat', modelInd);
    if ~exist(resfile,'file')
        return;
    else
        modelResArr{modelInd} = resfilename;
    end
end

% set next if all results ready
baseModelInd = con.selModelPath(stepId);
[flag, selModelInd] = cmpConModels(baseModelInd, conModelInds, stepId);

if flag==0
    % no var selected
    fprintf('\nNo variables selected in this round. Stop continuous phase. \n\n');
    
    if obtainStateLock1(statefile, nLockTrial)
        load(statefile,'con','nextFun','nextArg','nextArgArr');
        
        con.modelResArr = modelResArr;
        con.ithVar = stepId - 1;
        con.finished = true;
        nextFun = @binStep1;
        nextArg = {0};
        nextArgArr = [];
        
        save(statefile,'con','nextFun','nextArg','nextArgArr','-append');
        releaseStateLock1(statefile);
    else
        error('not able to obtain state lock after %d trials.\n', nLockTrial);
    end

elseif flag==1

    selVarInd = con.toSelVarInds(conModelInds==selModelInd);

    fprintf('\ncon Variable %d, model %d selected.\n\n', con.workVarInds(selVarInd), selModelInd);
    
    if obtainStateLock1(statefile, nLockTrial)
        load(statefile,'con','nextFun','nextArg','nextArgArr');
        
        con.modelResArr = modelResArr;
        con.selVarInds(end+1) = selVarInd;
        con.toSelVarInds = con.toSelVarInds(conModelInds~=selModelInd);            
        con.selModelPath(end+1) = selModelInd;
        con.ithVar = stepId + 1;
        currVarFlagArr(con.workVarInds(selVarInd)) = true;

        resfile = sprintf('%s%scon-%d.mat', resDir, filesep, selModelInd);
        load(resfile,'modelName');
        currModelName = modelName;

        nextFun = @conStep1;
        nextArg = {stepId+1};
        nextArgArr = [];
        
        save(statefile,'con','nextFun','nextArg','nextArgArr','currModelName','currVarFlagArr','-append');
        releaseStateLock1(statefile);
    else
        error('not able to obtain state lock after %d trials.\n', nLockTrial);
    end

else
    error('flag should be 0 or 1.')
end



