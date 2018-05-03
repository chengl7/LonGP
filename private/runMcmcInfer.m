function runMcmcInfer(currVarFlagArr, modelInd)

global resDir
global nLockTrial
global statefile

modelStem = num2str(modelInd);
resfile = sprintf('%s%scon-%s.mat', resDir, filesep, modelStem);
resfilename = sprintf('con-%s.mat', modelStem);

if ~exist(resfile,'file')
    % load data
    datafile = sprintf('%s%sdata.mat',resDir, filesep);
    load(datafile, 'para','xmn','ymn');
    lik = para.lik;
    nRep = para.nRep;

    % run MCMC inference
    [cf, cfName, modelName, cfTerms, cfPara, cfMagnParaInds, nCfVar, nInterCf] = genCf(currVarFlagArr, para, modelStem);

    gp = gp_set('lik',lik,'cf',cf);

%     [R, rfull, flag] = runMCMC(gp,xmn,ymn,nRep);
    tmpresfile = sprintf('%s.part.mat',resfile);
    [R, rfull, flag] = runMCMC(gp,xmn,ymn,nRep,tmpresfile);

    [~,~,lpy,~,~] =  gpmc_loopred(rfull, xmn, ymn);

    % output in result file
    save(resfile,'R','rfull','flag','lpy','cf*','gp','modelName','nCfVar','nInterCf','currVarFlagArr','modelInd');
    
    % delete temporary file for MCMC
    delete(tmpresfile);
    
else
    load(resfile, 'modelName');
end

fprintf('\ncon %s Finished.\n\n',modelName);

if modelInd==0
    return;
end

if obtainStateLock1(statefile, nLockTrial)
    load(statefile,'con');
    con.modelResArr{modelInd} = resfilename;
    save(statefile,'con','-append');
    releaseStateLock1(statefile);
else
    error('not able to obtain state lock after %d trials.\n', nLockTrial);
end
