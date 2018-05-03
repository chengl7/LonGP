function conStep1(stepId)

global DEBUG
if DEBUG
    fprintf('\nin conStep1\n');
end

global con
global nextFun
global nextArg
global nextArgArr

global resDir
global statefile

global currModelName
global currVarFlagArr

if stepId>con.nVar
    fprintf('\nAll variables selected. Stop continuous phase. \n\n');

    con.ithVar = stepId - 1;
    con.finished = true;

    nextFun = @binStep1;
    nextArg = {0};
    nextArgArr = [];
    
    save(statefile,'con','nextFun','nextArg','nextArgArr','-append');
    
    if DEBUG
        fprintf('\nin conStep1, exit 1\n');
    end
    
    return
end

fprintf('\nSelecting %dth continuous variable.\ntoSelVarInds: %s\n',stepId,...
    num2str(con.workVarInds(con.toSelVarInds),'%d '));

%------ run for base model ----%
if stepId==0
    
    runMcmcInfer(currVarFlagArr, 1);

    resfile = sprintf('%s%scon-%d.mat',resDir,filesep,1);
    load(resfile,'modelName');    
    currModelName = modelName;
    
    con.selModelPath = 1;
    con.ithVar = 1;

    nextFun = @conStep1;
    nextArg = {stepId+1};
    
    save(statefile,'con','nextFun','nextArg','currModelName','-append');
    
    if DEBUG
        fprintf('\nin conStep1, exit 2\n');
    end

    return;
end

nextFun = @conStep2;
nextArg = stepId;
nextArgArr = con.toSelVarInds;

save(statefile,'nextFun','nextArg','nextArgArr','-append');