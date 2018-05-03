function slave(workDir, varargin)
% stepwise GP regression, slave to help computing
% Lu Cheng
% 8.11.2017

global  resDir           % directory to store result
global  statefile        % file to store progress state
        
global  fixedVarInds   % inds prespecified by user
        
global  nTotalVar
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


maxRunTime = duration([Inf,Inf,Inf]); % in minutes
maxIdleTime = duration([Inf,Inf,Inf]); % in minutes
if nargin>1
    p = inputParser;
    addParameter(p,'maxRunTime',Inf,@isnumeric);
    addParameter(p,'maxIdleTime',Inf,@isnumeric);
    parse(p,varargin{:});
    maxRunTime = duration([0, p.Results.maxRunTime, 0]);
    maxIdleTime = duration([0, p.Results.maxIdleTime, 0]);
end

startTime = datetime;
lastRunTime = datetime;

if DEBUG
    fprintf('in slave. workDir=%s\n maxRunTime=%s maxIdleTime=%s start time=%s.\n',...
        workDir, maxRunTime, maxIdleTime, startTime);
end

if ~exist(workDir,'dir')
    mkdir(workDir);    
end
pause(60); % wait for task manager to get ready

freeSigFile = sprintf('%s%sfree.txt',workDir,filesep); % ready to run tasks
stopSigFile = sprintf('%s%sstop.txt',workDir,filesep); % need to quit as soon as possible
runSigFile = sprintf('%s%srun.txt',workDir,filesep); % file indicating running

t = 1;
while true
    
    runSigFileFlag = exist(runSigFile,'file')>0;
    freeSigFileFlag = exist(freeSigFile,'file')>0;
    stopSigFileFlag = exist(stopSigFile,'file')>0;

    % check if exist task files
    [taskFlag, taskFileNames] = getTaskFileNames(workDir);
    
    if stopSigFileFlag
        % delete available file
        if freeSigFileFlag            
            delete(freeSigFile);
        end
        
        % delete available file
        if runSigFileFlag            
            delete(runSigFile);
        end
        
        % run remaining tasks
        if taskFlag
            for i=1:length(taskFileNames)
                tmpTaskFile = sprintf('%s%s%s', workDir, filesep, taskFileNames{i});
                updateGlobalVar(tmpTaskFile);
                delete(tmpTaskFile);
                [iTarget, nextArg, varInd] = parseTaskFileName(taskFileNames{i});
                nextFun(nextArg,varInd);
            end            
        end
        
        % return according to stop.txt signal
        return
    end

    if ~taskFlag
        if DEBUG && mod(t,10)==1
            fprintf('step %d: no task assigned, sleep for 45 seconds. \n',t);
        end
        
        if ~freeSigFileFlag
            tmpfid = fopen(freeSigFile,'w');
            fclose(tmpfid);
        end
        pause(45);
    else            
        tmpTaskFile = sprintf('%s%s%s',workDir,filesep,taskFileNames{1});
        updateGlobalVar(tmpTaskFile);
        
        if freeSigFileFlag
            movefile(freeSigFile, runSigFile);
        else
            tmpfid = fopen(runSigFile,'w');
            fclose(tmpfid);
        end
        
        delete(tmpTaskFile);
        
        [iTarget, nextArg, varInd] = parseTaskFileName(taskFileNames{1});        
        
        if DEBUG
            fprintf('run for iTarget=%d %s(%d,%d)\n',iTarget,func2str(nextFun),nextArg,varInd)
        end

        nextFun(nextArg,varInd);  % run the first task  
        
        if exist(runSigFile,'file')>0
            movefile(runSigFile, freeSigFile);
        else
            tmpfid = fopen(freeSigFile,'w');
            fclose(tmpfid);
        end        
        
        lastRunTime = datetime; % record the end time of runing a task
        
    end
    
    % check if need to quit
    currTime = datetime;
    if currTime - lastRunTime > maxIdleTime
        fprintf('t= %d currTime=%s lastRunTime=%s maxIdleTime=%s\nmax Idle time reached, quit!\n',...
            t, currTime, lastRunTime, maxIdleTime);
        quitSlave(workDir);
        return;
    elseif currTime - startTime > maxRunTime
        fprintf('t= %d currTime=%s startTime=%s maxRunTime=%s\nmax Run time reached, quit!\n',...
            t, currTime, startTime, maxRunTime);
        quitSlave(workDir);
        return;
    end
    
    t = t + 1;
end

function quitSlave(workDir)

freeSigFile = sprintf('%s%sfree.txt',workDir,filesep); % ready to run tasks
freeSigFileFlag = exist(freeSigFile,'file')>0;
    
stopSigFile = sprintf('%s%sstop.txt',workDir,filesep); % need to quit as soon as possible
stopSigFileFlag = exist(stopSigFile,'file')>0;

runSigFile = sprintf('%s%srun.txt',workDir,filesep); % file indicating running
runSigFileFlag = exist(runSigFile,'file')>0;

if freeSigFileFlag            
    delete(freeSigFile);
end

if runSigFileFlag
    delete(runSigFile);
end

if ~stopSigFileFlag
    fid = fopen(stopSigFile,'w');
    fclose(fid);
end
