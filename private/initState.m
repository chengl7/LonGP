function initState(resDir_, fixedVarInds_, workVarInds, nConVar, nBinVar)

global  resDir           % directory to store result
global  statefile        % file to store progress state
        
global  fixedVarInds   % inds prespecified by user
% global  workVarInds    % var inds that to be selected, sorted, 1:nConVar cont varibles; followd by nConVar+(1:nBinVar) bin variables
        
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

resDir = resDir_;
fixedVarInds = fixedVarInds_;

statefile = sprintf('%s%sstate.mat',resDir,filesep);
nLockTrial = 120;
DEBUG = true;

% pre check
assert(~isempty(fixedVarInds)); % id need to be included at least
assert(issorted(fixedVarInds));
assert(issorted(workVarInds));
assert(isempty(intersect(fixedVarInds,workVarInds)));
assert(length(workVarInds)==(nConVar+nBinVar));
assert(exist(resDir,'dir')>0);

nTotalVar = max([fixedVarInds workVarInds]);
currVarFlagArr = false(1,nTotalVar);
currVarFlagArr(fixedVarInds) = true;
currModelName = [];

con.nVar = nConVar;
[con.modelMat, con.nModel] = genModelIndexMat(nConVar);
con.modelResArr = cell(1,con.nModel);
con.workVarInds = workVarInds(1:nConVar);
con.selVarInds = [];
con.toSelVarInds = 1:nConVar;
con.selModelPath = [];
con.finished = false;
con.ithVar = 0;
con.cmpResArr = cell(1,nConVar);

bin.nVar = nBinVar;
[bin.modelMat, bin.nModel] = genModelIndexMat(nBinVar);
bin.modelResArr = cell(1,bin.nModel);
bin.workVarInds = workVarInds(nConVar+(1:nBinVar));
bin.selVarInds = [];
bin.toSelVarInds = 1:nBinVar;
bin.selModelPath = [];
bin.finished = false;
bin.ithVar = 0;
bin.cmpResArr = cell(1,nBinVar);

if nConVar==0
    con.finished = true;
end

if nBinVar==0
    bin.finished = true;
end

nextFun = [];
nextArg = [];
nextArgArr = [];

if ~con.finished            
    nextFun = @conStep1;                
    nextArg = {0};
elseif ~bin.finished
    nextFun = @binStep1;                
    nextArg = {0};
else
    % finished, nothing to do
end

save(statefile,'resDir','statefile','fixedVarInds',...
        'nTotalVar','currVarFlagArr','currModelName','con','bin',...
        'looCutoff','scvCutoff','nBBSample','nextFun','nextArg','nextArgArr',...
        'nLockTrial','DEBUG');