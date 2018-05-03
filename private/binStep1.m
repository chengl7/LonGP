function binStep1(stepId)

global DEBUG
if DEBUG
    fprintf('\nin binStep1\n');
end

global bin
global nextFun
global nextArg
global nextArgArr

global resDir
global statefile

global currModelName
global currVarFlagArr

if stepId>bin.nVar
    fprintf('\nAll variables selected. Stop binary phase. \n\n');

    bin.ithVar = stepId - 1;
    bin.finished = true;

    nextFun = [];
    nextArg = [];
    nextArgArr = [];
    
    save(statefile,'bin','nextFun','nextArg','nextArgArr','-append');
    
    if DEBUG
        fprintf('\nin binStep1, exit 1\n');
    end
    
    return
end

fprintf('\nSelecting %dth binary variable.\ntoSelVarInds: %s\n',stepId,...
    num2str(bin.workVarInds(bin.toSelVarInds),'%d '));

%------ run for base model ----%
if stepId==0
    runScvInfer(currVarFlagArr, 1);

    resfile = sprintf('%s%sbin-%d.mat',resDir, filesep, 1);
    load(resfile,'modelName');
    currModelName = modelName;

    bin.selModelPath = 1;
    bin.ithVar = 1;

    nextFun = @binStep1;
    nextArg = {stepId+1};
    
    save(statefile,'bin','nextFun','nextArg','currModelName','-append');
    
    if DEBUG
        fprintf('\nin binStep1, exit 2\n');
    end

    return;
end

nextFun = @binStep2;
nextArg = stepId;
nextArgArr = bin.toSelVarInds;

save(statefile,'nextFun','nextArg','nextArgArr','-append');