function [flag, selModelInd, looVec] = cmpConModels(baseModelInd, conModelInds, stepId)

global resDir
global nLockTrial
global statefile

global nBBSample
global looCutoff
global para

resfile = sprintf('%s/con-cmp-base%d-tsm%s.mat', resDir, baseModelInd, num2str(conModelInds,'-%d')); % tsm: to select model
resfilename = sprintf('con-cmp-base%d-tsm%s.mat', baseModelInd, num2str(conModelInds,'-%d'));

delInterTerms = {};

if exist(resfile,'file')>0
    load(resfile);
else

    % check results ready
    for mid = [baseModelInd conModelInds]
        tmpResFile = sprintf('%s/con-%d.mat',resDir, mid);
        assert(exist(tmpResFile,'file')>0)
    end

    load(sprintf('%s/con-%d.mat',resDir, baseModelInd),'lpy')
    baseLpy = lpy;

    lpyMat = zeros(length(lpy),length(conModelInds));
    looVec = zeros(1,length(conModelInds));
    for i = 1:length(conModelInds)
        load(sprintf('%s/con-%d.mat',resDir, conModelInds(i)),'lpy')
        lpyMat(:,i) = lpy;
        looPredDiff = lpy - baseLpy;
        lpydiff = bbmean(looPredDiff,nBBSample);
        looVec(i) = mean(lpydiff>0); 
    end

    sigInds = find(looVec>=looCutoff);
    if isempty(sigInds)
        flag = 0;
        selModelInd = 0;
    elseif length(sigInds)==1
        flag = 1;
        selModelInd = conModelInds(sigInds);
        
        % remove interaction terms that have explained variance smaller
        % than predefined cutoff
        modelResFile = sprintf('%s/con-%d.mat',resDir, selModelInd);
        delInterTerms = pruneInterTerms(modelResFile);
    else
        tmpNSig = length(sigInds);
        tmpLpyMat = lpyMat(:,sigInds);
        bbweights = dirrand(length(baseLpy),nBBSample);

        mLpyMat = zeros(tmpNSig,nBBSample);
        for j=1:tmpNSig
            mLpyMat(j,:) = wmean(tmpLpyMat(:,j),bbweights);
        end

        [~, maxInd] = max(mLpyMat,[],1);
        tmpRankVec = histc(maxInd,1:tmpNSig);
        [~, tmpMaxInd] = max(tmpRankVec);

        flag = 1;
        selModelInd = conModelInds(sigInds(tmpMaxInd));
        
        % remove interaction terms that have explained variance smaller
        % than predefined cutoff
        modelResFile = sprintf('%s/con-%d.mat',resDir, selModelInd);
        delInterTerms = pruneInterTerms(modelResFile);
    end

    save(resfile, 'flag', 'selModelInd', 'looVec', 'sigInds');
end

para.kernel.delInterTerms = delInterTerms;

if obtainStateLock1(statefile, nLockTrial)
    load(statefile,'con');
    
    con.cmpResArr{stepId} = resfilename;

    save(statefile,'con','-append');
    releaseStateLock1(statefile);
else
    error('not able to obtain state lock after %d trials.\n', nLockTrial);
end
