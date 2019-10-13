function runScvInfer(currVarFlagArr, modelInd)

global resDir
global nLockTrial
global statefile

% global para

modelStem = num2str(modelInd);
resfile = sprintf('%s%sbin-%s.mat',resDir, filesep, modelStem);
resfilename = sprintf('bin-%s.mat', modelStem);

if ~exist(resfile,'file')
    % load data
    datafile = sprintf('%s%sdata.mat',resDir, filesep);
    %load(datafile, 'xmn','ymn');
    load(datafile, 'xmn','ymn','para');
    lik = para.lik;
    trindex = para.trindex;
    tstindex = para.tstindex;
    
    % run CCD cross validation
    [cf, cfName, modelName, cfTerms, cfPara, cfMagnParaInds, nCfVar, nInterCf] = genCf(currVarFlagArr, para, modelStem);
    gp = gp_set('lik',lik,'cf',cf);

    [~, cvpreds] = gp_kfcv(gp, xmn, ymn, 'inf_method','IA','display','off','k',length(trindex),'trindex',trindex,'tstindex',tstindex,'pred','lp');
    lpy = cvpreds.lpyt;
    
    rfull = gp_ia(gp, xmn, ymn);

    % output in result 
    save(resfile,'rfull','lpy','cf*','modelName','nCfVar','nInterCf','currVarFlagArr', 'modelInd');
else
    load(resfile,'modelName');
end

fprintf('\n\nbin %s Finished.\n\n',modelName);

if obtainStateLock1(statefile,nLockTrial)
    load(statefile,'bin');
    bin.modelResArr{modelInd} = resfilename;
    save(statefile,'bin','-append');
    releaseStateLock1(statefile);
else
    error('not able to obtain state lock after %d trials.\n', nLockTrial);
end
