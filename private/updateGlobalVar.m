function updateGlobalVar(inFile)
% use the variables stored in "inFile" to update the global variables in
% the current workspace
% Lu Cheng
% 09.11.2017

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

if DEBUG
    fprintf('update global variables using %s.\n',inFile);
end

load(inFile);


