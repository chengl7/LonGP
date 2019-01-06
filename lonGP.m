function lonGP(parentDir, targetInd)
% stepwise GP regression
% Lu Cheng
% 20.04.2018

global  resDir           % directory to store result
global  statefile        % file to store progress state
        
global  fixedVarInds   % inds prespecified by user
% global  workVarInds    % var inds that to be selected, sorted, 1:nConVar cont varibles; followd by nConVar+(1:nBinVar) bin variables
        
% global  nTotalVar
global  currVarFlagArr
global  currModelName
        
global  con  % structure related to continuous variables
global  bin  % structure related to binary variables
        
global  looCutoff
global  scvCutoff
global  nBBSample
        
global  nextFun
global  nextArg
global  nextArgArr

global  nLockTrial   % n times to try to get state lock
global  DEBUG

global para

if ischar(targetInd)
    targetInd = str2double(targetInd);
end

% enusre data files in parent directory are ready
assert(exist(parentDir,'dir')>0, sprintf('Result directory %s does not exist!\n',parentDir));

paraFile = sprintf('%s%sinput.para.txt',parentDir,filesep);
assert(exist(paraFile,'file')>0, sprintf('Parameter file %s does not exist!\n',paraFile));

preprocFile = sprintf('%s%spreprocData.mat',parentDir,filesep);
if ~exist(preprocFile,'file')
    [para,normData] = preprocData(paraFile);
else
    para=parseInputPara(paraFile);
    load(preprocFile,'normData');
end

% preparing data files for the given target
resDir0 = sprintf('%s%sResults',parentDir,filesep);
if ~exist(resDir0,'dir')
    mkdir(resDir0)
end
resDir = sprintf('%s%sResults%s%d',parentDir,filesep,filesep,targetInd);
statefile = sprintf('%s%sstate.mat',resDir,filesep);

if ~exist(resDir,'dir')
    mkdir(resDir);
end

parentRawDataFile = sprintf('%s%srawdata.mat',parentDir,filesep);

if exist(parentRawDataFile,'file')>0
    rawdata = load(parentRawDataFile);
else
    error('raw data file %s does not exit, quit!\n',parentRawDataFile);
end

fixedVarInds = para.fixedVarInds;

looCutoff = para.looCutOff;
scvCutoff = para.scvCutOff;
nBBSample = para.nBBSample;

maxRunTime = duration([Inf,Inf,Inf]); % in minutes
maxIdleTime = duration([Inf,Inf,Inf]); % in minutes

if isfield('maxRunTime',para)
    maxRunTime = duration([0, para.maxRunTime, 0]);
end

if isfield('maxIdleTime',para)
    maxIdleTime = duration([0, para.maxIdleTime, 0]);
end

startTime = datetime;
lastRunTime = datetime;

%% preproc data, saved as "data.mat" in resDir

iTarget = targetInd;
assert(iTarget<=normData.Y.nTarget);
yFlag = logical(normData.Y.yflag(:,iTarget));
ymn = normData.Y.Y(yFlag,iTarget);
xmn = normData.X.X(yFlag,:);
ystd = normData.Y.ystd(iTarget);

rawdata.X = rawdata.X(yFlag,:);
rawdata.Y = rawdata.Y(yFlag,iTarget)-normData.Y.ymean(iTarget);
rawdata.iTarget = iTarget;
rawdata.targetName = rawdata.targetNames{iTarget};

tmpid = normData.X.X(yFlag,end);
[trindex, tstindex] = genScvIndex(tmpid);
para.trindex = trindex;
para.tstindex = tstindex;

% if isfield('XT',normData.X) % in case user specified some text data
%     xmnt = XT;
% end

conMaskFlag = true(1,para.nConVar); % if mask needed for a covariate
for i=1:para.nConVar
    if all(logical(xmn(:,i*2-1)))
        conMaskFlag(i) = false;
    end
end

binMaskFlag = true(1,para.nBinVar); % if mask needed for a covariate
for i=1:para.nBinVar
    ivar = i + para.nConVar;
    if all(logical(xmn(:,ivar*2-1)))
        binMaskFlag(i) = false;
    end
end

para.kernel.conMaskFlag = conMaskFlag;
para.kernel.binMaskFlag = binMaskFlag;

para.nRep = 4;
workVarInds = para.workVarInds;
nConVar = para.nConVar;
nBinVar = para.nBinVar;
varNames = para.kernel.varName;

workConVarInds = intersect(workVarInds,1:nConVar);
workBinVarInds = intersect(workVarInds,nConVar+(1:nBinVar));

para.workConVarInds = workConVarInds;
para.workBinVarInds = workBinVarInds;

datafile = sprintf('%s%sdata.mat',resDir,filesep);
save(datafile,'para','xmn','ymn','ystd','iTarget','yFlag','rawdata');

% load(datafile,'workVarInds','workConVarInds','workBinVarInds')

nConVar = length(workConVarInds);
nBinVar = length(workBinVarInds);

%% run stepwise GP regression

% initialization

% if ~exist(statefile,'file')
%     initState(resDir, fixedVarInds, workVarInds, nConVar, nBinVar);
% end    
initState(resDir, fixedVarInds, workVarInds, nConVar, nBinVar);
load(statefile);

fprintf('processing target %d: %s.\n',iTarget, rawdata.targetName);

% main loop
currNextFun = nextFun;
currNextArg = nextArg;  % need to assign to a fixed value since obj will be change on the fly
currNextArgArr = nextArgArr;

while ~isempty(currNextFun)
        
    if isempty(currNextArgArr) && iscell(currNextArg)
        currNextFun(currNextArg{:});
        lastRunTime = datetime;
    elseif isnumeric(currNextArg) && ~isempty(currNextArgArr)        
        nextArgArr = [];  % nobody write state file now, only time of write is a batch of para tasks finished
                          % all para tasks finished in this condition
        save(statefile,'nextArgArr','-append');        
        
        varInd = currNextArgArr(1);
        
        tmpstr = func2str(currNextFun);
        if strcmp(tmpstr,'conStep2')
            contMode = true;
        elseif strcmp(tmpstr,'binStep2')
            contMode = false;
        else
            error('unknown function handle: %s. \n', tmpstr);
        end
        
        % generate para task files
        taskfile = sprintf('%s%stask',resDir,filesep);
        if obtainStateLock1(taskfile, nLockTrial)
            
            for tmpVarInd = currNextArgArr(2:end)
                if contMode
                    tmpModelInd = findModelIndex(con.modelMat, [con.selVarInds tmpVarInd]);
                    tmpResFile = sprintf('%s%scon-%d.mat',resDir, filesep, tmpModelInd);
                    if exist(tmpResFile,'file')
                        continue;
                    end
                    
                    tmpTaskFile = sprintf('%s%s0-task-con-%d-%d.mat',resDir,filesep,currNextArg,tmpVarInd);
                    save(tmpTaskFile, 'resDir', 'nLockTrial', 'statefile', ...
                        'currVarFlagArr','currModelName','con', ...
                        'nextFun', 'nextArg', 'nextArgArr','nBBSample','looCutoff','DEBUG');
                else
                    tmpModelInd = findModelIndex(bin.modelMat, [bin.selVarInds tmpVarInd]);
                    tmpResFile = sprintf('%s%sbin-%d.mat',resDir, filesep, tmpModelInd);
                    if exist(tmpResFile,'file')
                        continue;
                    end
                    
                    tmpTaskFile = sprintf('%s%s0-task-bin-%d-%d.mat',resDir,filesep,currNextArg,tmpVarInd);
                    save(tmpTaskFile, 'resDir', 'nLockTrial', 'statefile', ...
                        'currVarFlagArr','currModelName','bin', ...
                        'nextFun', 'nextArg', 'nextArgArr','nBBSample','scvCutoff','DEBUG');
                end
            end                        
            
            releaseStateLock1(taskfile);            
        else
            error('not able to obtain task lock after %d trials.\n', nLockTrial);
        end
        
        currNextFun(currNextArg, varInd);
        lastRunTime = datetime;
        
    elseif isnumeric(currNextArg) && isempty(currNextArgArr)
        
        signalFile = sprintf('%s%sfree.txt',resDir,filesep); % ready to run tasks
        signalFileFlag = exist(signalFile,'file')>0;
        
        % check if exist task files
        [flag, taskFileNames] = getTaskFileNames(resDir);
                
        if ~flag
            if ~signalFileFlag
                tmpfid = fopen(signalFile,'w');
                fclose(tmpfid);
            end
            pause(60);
        else            
            
            currStateFile = statefile;
            tmpTaskFile = sprintf('%s%s%s',resDir,filesep,taskFileNames{1});
            load(tmpTaskFile);    % global variable updated
            delete(tmpTaskFile);  % run the first task          
            [iTarget, nextArg, varInd] = parseTaskFileName(taskFileNames{1});
            
            if signalFileFlag
                delete(signalFile);
            end
            
            nextFun(nextArg,varInd);  % run the first task
            
            % restore global variables
            if iTarget~=0
                if obtainStateLock1(currStateFile,nLockTrial)  % iTarget==0 means local task
                    updateGlobalVar(currStateFile);
                    releaseStateLock1(currStateFile);
                else
                    error('not able to obtain state lock after %d trials.\n', nLockTrial);
                end
            end
            
            lastRunTime = datetime;
        end
    else
        currNextFun
        currNextArg
        currNextArgArr
        error('unknown situation\n');
    end
    
    % update global variables
    if obtainStateLock1(statefile, nLockTrial)
        load(statefile,'nextFun','nextArg','nextArgArr','currVarFlagArr','currModelName','con','bin');

        currNextFun = nextFun;
        currNextArg = nextArg;
        currNextArgArr = nextArgArr;
        
        releaseStateLock1(statefile);
    else
        error('not able to obtain state lock after %d trials.\n', nLockTrial);
    end
    
    % check if need to quit
    currTime = datetime;
    if currTime - lastRunTime > maxIdleTime
        fprintf('currTime=%s lastRunTime=%s maxIdleTime=%s\nmax Idle time reached, quit!\n',...
            currTime, lastRunTime, maxIdleTime);
        return;
    elseif currTime - startTime > maxRunTime
        fprintf('currTime=%s startTime=%s maxRunTime=%s\nmax Run time reached, quit!\n',...
            currTime, startTime, maxRunTime);
        return;
    end
    
end

outstr = strjoin(varNames(currVarFlagArr),',');
fprintf('final variables: %s\n', outstr);
fprintf('run mcmc for final model: %s\n', currModelName);

summaryFile = sprintf('%s%ssummary.txt',resDir,filesep);
fid = fopen(summaryFile,'w');
fprintf(fid,'final variables: %s\n', outstr);
fprintf(fid,'final model: %s\n', currModelName);
fclose(fid);

%% generate final results
finalFileName = sprintf('%s%sfinalResult.mat',resDir,filesep);

if exist(finalFileName,'file')
    load(finalFileName,'finalFlag','model','components')
    fprintf('final model ready. flag=%d, %s\n', finalFlag, model.description.long);
else
    % runMCMC for the final selected model
    % check if only continuous
    if isempty(bin.selVarInds)
        if isempty(con.selModelPath)
            filename1 = sprintf('%s%scon-%d.mat', resDir, filesep, 1);
        else
            filename1 = sprintf('%s%scon-%d.mat', resDir, filesep, con.selModelPath(end));
        end
        filename = sprintf('%s%scon-%d.mat', resDir, filesep, 0);
        copyfile(filename1,filename);
    else
        runMcmcInfer(currVarFlagArr, 0);
        filename = sprintf('%s%scon-%d.mat',resDir, filesep, 0);
    end

    load(filename,'R','flag','gp','rfull','currVarFlagArr','modelName','cf','cfName','cfTerms','cfPara','cfMagnParaInds','nCfVar','nInterCf');
    cfName = regexprep(cfName,'model \d+ ','model 0 ');
    modelName = regexprep(modelName,'model \d+ ','model 0 ');

    nCf = length(cf);

    model.description.short = cfName;
    model.description.long = modelName;
    model.cf.cf = cf;
    model.cf.terms = cfTerms;
    model.cf.paras = cfPara;
    model.cf.magParaInds = cfMagnParaInds;
    model.cf.nCf = nCf;
    model.cf.nInterCf = nInterCf;
    model.flag = flag;

    finalFlag = flag;
    save(statefile,'finalFlag','-append');

    if flag==0
        fprintf('final model does not converge. R=%s. \n',num2str(R,'%1.2f '));    
    end

    load(datafile,'xmn','ymn','yFlag');

    modelResFile = filename;
    [EfArr, VfArr, empMagArr, ~, cfTerms] = getComponentPredictions(modelResFile, xmn);
    EfArr{end+1} = ymn - sum(cell2mat(EfArr),2);
    empMagArr(end+1) = nanvar(EfArr{end});
    cfTerms{end+1} = 'noise';
    normEmpMagArr = empMagArr/sum(empMagArr);

    components.EfArr = EfArr;
    components.VfArr = VfArr;
    components.empMagArr = empMagArr;
    components.normEmpMagArr = normEmpMagArr;
    components.cfTerms = cfTerms; 

    save(finalFileName,'model','components','currVarFlagArr','varNames','finalFlag');
    
    % save predictions for rawdata in text format
    rawPredMat = cell2mat(components.EfArr)*ystd;
    rawPredTextFile = sprintf('%s%srawData.pred.txt',resDir,filesep);
    dlmwrite(rawPredTextFile, rawPredMat, 'delimiter', '\t');
    
    fprintf('final model ready. flag=%d, %s\n', finalFlag, currModelName);
    
end



% generate predictions for test data
testFile = sprintf('%s%stestData.mat', parentDir, filesep);
if exist(testFile,'file')>0
    fprintf('Generate predictions for test file %s.\n',testFile);
    genComPrediction(parentDir,targetInd);
end

if para.figure.plot
    fprintf('Generate figures.\n');
    for iCom=1:model.cf.nCf-model.cf.nInterCf
        xInd = find(strcmp(model.cf.terms{iCom},varNames(1:para.nConVar)));
        if isempty(xInd)
            xInd = para.figure.xInd;
        end
        colorInd = find(strcmp(model.cf.terms{iCom},varNames(para.nConVar+(1:para.nBinVar-1))));  % id should be avoided
        if isempty(colorInd)
            colorInd = para.figure.colorInd;
        end
        genComPlots(resDir, xInd, colorInd, iCom);
    end
    
    for iCom=(model.cf.nCf-model.cf.nInterCf+1):model.cf.nCf
        tmp = strsplit(model.cf.terms{iCom},'*');
        xInd = find(strcmp(tmp{1},varNames(1:para.nConVar)));
        if isempty(xInd)
            xInd = para.figure.xInd;
        end
        colorInd = find(strcmp(tmp{2},varNames(para.nConVar+(1:para.nBinVar-1))));
        if isempty(colorInd)
            colorInd = para.figure.colorInd;
        end
        genComPlots(resDir, xInd, colorInd, iCom);
    end
    
    % noise
    genComPlots(resDir, xInd, colorInd, model.cf.nCf+1);
end


