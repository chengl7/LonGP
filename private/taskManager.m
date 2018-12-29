function taskManager(resDir, varargin)

preprocFile = sprintf('%s%spreprocData.mat',resDir,filesep);
assert(exist(preprocFile,'file')>0, sprintf('Preproc file %s does not exist!\n',preprocFile));
load(preprocFile,'para','normData');

tmpConInds = setdiff(1:para.nConVar,para.fixedVarInds);
tmpBinInds = setdiff(para.nConVar+(1:para.nBinVar),para.fixedVarInds);
tmpSPT = max(length(tmpConInds), length(tmpBinInds));  % slave per target

nSlavePerTarget = tmpSPT;
nTarget = normData.Y.nTarget;

clear tmp* normData para

maxRunTime = duration([Inf,Inf,Inf]); % in minutes
resume = 0;
if nargin>3
    p = inputParser;
    if exist('OCTAVE_VERSION', 'builtin')
        p = iparser(p,'addParameter','maxRunTime',Inf,@isnumeric);
        p = iparser(p,'addParameter','resume',0,@isnumeric);
        p = iparser(p,'parse',varargin{:});
    else
        addParameter(p,'maxRunTime', Inf, @isnumeric);
        addParameter(p,'resume', 0, @isnumeric);
        parse(p,varargin{:});
    end
    maxRunTime = duration([0, p.Results.maxRunTime, 0]);
end
startTime = datetime;

global DEBUG

if DEBUG
    fprintf('in task manager. nTarget=%d. nSlavePerTarget=%d. resDir=%s\n',...
        nTarget, nSlavePerTarget, resDir);
end

stopSlaveFile = sprintf('%s%sstopslave.txt',resDir,filesep);  % randomly stop n slave according to numbers given in the file "stopSlaveFile"
stopSigFile = sprintf('%s%sstop.txt',resDir,filesep); % need to quit as soon as possible
if ~exist(resDir,'dir')
    mkdir(resDir);
else
    if resume==0
        % clear exist files or folders
        clearParaResults(resDir, nTarget);
    end    
    
    % delete stop file
    if exist(stopSigFile,'file')>0
        delete(stopSigFile);
    end
end

logfile = sprintf('%s%staskManagerLog.txt',resDir,filesep);
diary(logfile);

% initialize
resDir = sprintf('%s%sResults',resDir,filesep); % set resDir to the directory of all targets

resDirList = cell(1,nTarget);
finishFlagArr = false(1,nTarget);
stageFlagArr = false(1,nTarget);  % 1-final stage, 0-para stage
workerFlagArr = false(1,nTarget);  % 1-final stage, 0-para stage
for iTarget=1:nTarget
    resDirList{iTarget} = sprintf('%s%s%d',resDir,filesep,iTarget);
end

nMissingTarget = 0;

t = 1;

while true
    
    % check if stop file found
    stopSigFileFlag = exist(stopSigFile,'file')>0;
    if stopSigFileFlag
        fprintf('Stop file %s detected, quit!\n', stopSigFile);
        return;
    end    
    
    % check if maximum run time reached
    currTime = datetime;
    if currTime - startTime > maxRunTime
        fprintf('t= %d currTime=%s startTime=%s maxRunTime=%s\n max run time reached, quit!\n',...
            t, currTime, startTime, maxRunTime);
        fid = fopen(stopSigFile,'w');
        fclose(fid);
        return;
    end
        
    % buffer output
    if mod(t,10)==1
        diary off
        diary on
    end
    
%     fprintf('\nstep %d. time %s.\n', t, datetime);
    if exist('OCTAVE_VERSION', 'builtin')
        fprintf('\nstep %d. time %s.\n', t, ctime(datetime));
    end
    
    % get all current folders
    workSubDirInt = getWorkDirs(resDir); % note workSubDir are sorted integers in acending order
    
    % scan slave pool
    slavePoolFlagArr = false(size(workSubDirInt));
    runSlavePoolFlagArr = false(size(workSubDirInt));
    for i=1:length(workSubDirInt)
        tmpdir = sprintf('%s%s%d',resDir,filesep,workSubDirInt(i));
        tmpfreefile = sprintf('%s%sfree.txt',tmpdir,filesep);
        tmprunfile = sprintf('%s%srun.txt',tmpdir,filesep);
        tmptaskflag = getTaskFileNames(tmpdir);
        tmpstopfile = sprintf('%s%sstop.txt',tmpdir,filesep);
                
        if exist(tmpfreefile,'file') && ~tmptaskflag && ~exist(tmpstopfile,'file')
            slavePoolFlagArr(i) = true;
        end
        
        if exist(tmprunfile,'file') && ~tmptaskflag && ~exist(tmpstopfile,'file')
            runSlavePoolFlagArr(i) = true;
        end
    end
    
    slavePool = workSubDirInt(slavePoolFlagArr);
    
    nWorkSubDir = length(workSubDirInt);
    nSlavePool = length(slavePool) + sum(runSlavePoolFlagArr);    
    
    nCurrParaTask = 0;
    
    % assign tasks to slaves
    for iTarget=1:nTarget
        
        workerFile = sprintf('%s%sworker.run.txt',resDirList{iTarget},filesep);
        if exist(workerFile,'file')>0
            workerFlagArr(iTarget)=true;
        else
            workerFlagArr(iTarget)=false;
        end
        
        finalFileName = sprintf('%s%sfinalResult.mat',resDirList{iTarget},filesep);
        if ~finishFlagArr(iTarget) && exist(finalFileName,'file')
            finishFlagArr(iTarget)=true;
            stageFlagArr(iTarget)=true;
        end
        
        summaryFile = sprintf('%s%ssummary.txt',resDirList{iTarget},filesep);
        if ~stageFlagArr(iTarget) && exist(summaryFile,'file')
            stageFlagArr(iTarget)=true;
        end
        
        if all(finishFlagArr)
            % stop all slaves and return 
            if DEBUG
                fprintf('all tasks finished.\n');
            end            
            stopSlave(workSubDirInt, resDir);
            return
        end
        
        if finishFlagArr(iTarget)
            continue;
        end       
        
        [tmptaskflag, tmptaskfiles] = getTaskFileNames(resDirList{iTarget});
        
        if tmptaskflag
            tmptaskdir = resDirList{iTarget};
            tmpTaskLock = sprintf('%s%stask.txt',tmptaskdir,filesep);
            
            for ifile = 1:length(tmptaskfiles)
                
                nCurrParaTask = nCurrParaTask + 1;
                
                if isempty(slavePool)
                    continue;
                end
                
                if exist(tmpTaskLock,'file')
                    continue;
                end
                
                tmpTaskFile = sprintf('%s%s%s',tmptaskdir,filesep,tmptaskfiles{ifile});
                tmpiTarget = parseTaskFileName(tmptaskfiles{ifile});
                tmpSlaveDir = sprintf('%s%s%d',resDir,filesep,slavePool(end));
                if tmpiTarget==0
                    tmpSlaveFile = sprintf('%s%s%d%s',tmpSlaveDir,filesep,iTarget,tmptaskfiles{ifile}(2:end));
                else
                    tmpSlaveFile = sprintf('%s%s%s',tmpSlaveDir,filesep,tmptaskfiles{ifile});
                end
                
				if DEBUG
                    fprintf('moved %s to %s.\n',tmpTaskFile, tmpSlaveFile);
                end 
				
                try
                    movefile(tmpTaskFile,tmpSlaveFile);
                catch ME
                    fprintf('%s\n',ME.message);
                end
                                    
                slavePool(end)=[];
            end
        end        
    end    
    
    % report current task and slave information 
    nCurrSlave = length(slavePool);
    nRunSlave = nSlavePool-nCurrSlave;
    nFinished = sum(finishFlagArr);
    nRemain = nTarget-nFinished;
    
    nFinalStage = sum(stageFlagArr);
    nParaStage = nTarget - nMissingTarget - nFinalStage;
    nMaxSlaveNeeded = nParaStage*(nSlavePerTarget-1);
    
    nRunningWorker = sum(workerFlagArr);
    
    fprintf('#runnning dirs: %d #slave: %d\n', nWorkSubDir, nSlavePool);  
    fprintf('nRunningWoker=%d\n',nRunningWorker);
    fprintf('nTodoParaTask=%d nCurrRunningSlave=%d nCurrIdleSlave=%d\n', nCurrParaTask, nRunSlave, nCurrSlave);
    fprintf('nFinalStageTarget=%d, nParaStageTarget=%d, nSlavePerTarget=%d, nMaxSlaveNeeded=%d \n', nFinalStage, nParaStage, nSlavePerTarget, nMaxSlaveNeeded);        
    fprintf('nFinishedTarget=%d, nRemainTarget=%d. \n', nFinished, nRemain);        
    
    if nFinished<=20 && nFinished>0
        fprintf('Finished Targets %s. \n', num2str(find(finishFlagArr)));        
    end
    
    if nRunningWorker<=20
        fprintf('Running workers %s. \n', num2str(find(workerFlagArr)));        
    end
    
    if nRemain<=20 && nRemain>0
        fprintf('Unfinished Targets %s. \n', num2str(find(~finishFlagArr)));        
    end
    
    if mod(t,60)==1
        fprintf('Finished Targets %s. \n', num2str(find(finishFlagArr)));
        fprintf('Unfinished Targets %s. \n', num2str(find(~finishFlagArr)));
        fprintf('curr running slave: %s. \n', num2str(find(runSlavePoolFlagArr)));
        fprintf('curr idle slave: %s. \n', num2str(find(slavePoolFlagArr)));
    end
    
    % shutdown slaves randomly
    if nCurrSlave>nMaxSlaveNeeded
        fprintf('Too many slaves. Shutdown %d slaves.\n', nCurrSlave-nMaxSlaveNeeded);
        tmpinds = randsample(slavePool,nCurrSlave-nMaxSlaveNeeded);
        stopSlave(tmpinds, resDir)
    end
    
    if t>10
        nRunningTarget = sum(workSubDirInt<=nTarget);
        nMissingTarget = nTarget - nRunningTarget;
    end
    
    % randomly stop n slave according to numbers given in the file "stopSlaveFile"    
    if exist(stopSlaveFile,'file')>0
        try
            tmpfid = fopen(stopSlaveFile,'r');
            tmpstr = fgetl(tmpfid);
            fclose(tmpfid);
            delete(stopSlaveFile);
            
            tmpinds = randsample(slavePool,str2num(tmpstr));
            stopSlave(tmpinds, resDir)
            
        catch ME
            fprintf('%s\n',ME.message);
        end
    end
    
    t = t + 1;
    
    pause(60);
    
end

diary off
