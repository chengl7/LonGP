function paraLonGP(resDir, iTarget, varargin)
% resDir: directory to store results, ith target variable will be stored in subdirectory "i" under resDir, i.e. "resDir/Results/i"
% iTarget: index of target, 0 is for task manager

% Lu Cheng
% 01.05.2018

%% pre check

global DEBUG
DEBUG=true;

assert(exist(resDir,'dir')>0, sprintf('Result directory %s does not exist!\n',resDir));

paraFile = sprintf('%s%sinput.para.txt',resDir,filesep);
assert(exist(paraFile,'file')>0, sprintf('Parameter file %s does not exist!\n',paraFile));

preprocFile = sprintf('%s%spreprocData.mat',resDir,filesep);
if ~exist(preprocFile,'file')
    preprocData(paraFile);
end

load(preprocFile,'normData');
nTarget = normData.Y.nTarget;
clear normData

if DEBUG
    fprintf('In paraLonGP, iTarget=%d\n',iTarget);
end

%% run appropriate jobs

targetDir = sprintf('%s%sResults%s%d',resDir,filesep,filesep,iTarget);

if iTarget==0
    taskManager(resDir, varargin{:});    
elseif iTarget>nTarget
    % run slave
    if DEBUG
        fprintf('run slave, sleep for 60 seconds to wait taskManager. iTarget=%d\n',iTarget);
    end    
    pause(60); % wait for task manager to get ready
    
    slave(targetDir,varargin{:});
else
    % run LonGP
    if DEBUG
        fprintf('run LonGP, sleep for 60 seconds to wait taskManager. iTarget=%d\n',iTarget);
    end
    pause(60); % wait for task manager to get ready
    
    if ~exist(targetDir,'dir')
        mkdir(targetDir);
    end
    
    createFile(sprintf('%s%sworker.run.txt',targetDir));
    lonGP(resDir,iTarget);
    delFile(sprintf('%s%sworker.run.txt',targetDir));
    
    slave(targetDir,varargin{:});
end

function createFile(filename)
fid = fopen(filename);
fclose(fid);

function delFile(filename)
if exist(filename,'file')>0
    delete(filename);
end
    






