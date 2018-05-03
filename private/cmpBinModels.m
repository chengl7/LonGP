function [flag, selModelInd, scvVec] = cmpBinModels(baseModelInd, binModelInds, stepId)

global resDir
global nLockTrial
global statefile

global nBBSample
global scvCutoff

resfile = sprintf('%s/bin-cmp-base%d-tsm%s.mat',resDir, baseModelInd, num2str(binModelInds,'-%d'));
resfilename = sprintf('bin-cmp-base%d-tsm%s.mat', baseModelInd, num2str(binModelInds,'-%d'));

if exist(resfile,'file')>0
    load(resfile)
else
    % check results ready
    for mid = [baseModelInd binModelInds]
        tmpResFile = sprintf('%s/bin-%d.mat',resDir, mid);
        assert(exist(tmpResFile,'file')>0)
    end

    load(sprintf('%s/bin-%d.mat',resDir, baseModelInd),'lpy')
    baseLpy = lpy;

    lpyMat = zeros(length(lpy),length(binModelInds));
    scvVec = zeros(1,length(binModelInds));
    for i = 1:length(binModelInds)
        load(sprintf('%s/bin-%d.mat',resDir, binModelInds(i)),'lpy')
        lpyMat(:,i) = lpy;
        looPredDiff = lpy - baseLpy;
        lpydiff = bbmean(looPredDiff,nBBSample);
        scvVec(i) = mean(lpydiff>0); 
    end

    sigInds = find(scvVec>=scvCutoff);
    if isempty(sigInds)
        flag = 0;
        selModelInd = 0;
    elseif length(sigInds)==1
        flag = 1;
        selModelInd = binModelInds(sigInds);
        
        % remove interaction terms that have explained variance smaller
        % than predefined cutoff
        modelResFile = sprintf('%s/bin-%d.mat',resDir, selModelInd);
        pruneInterTerms(modelResFile);
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
        selModelInd = binModelInds(sigInds(tmpMaxInd));
        
        % remove interaction terms that have explained variance smaller
        % than predefined cutoff
        modelResFile = sprintf('%s/bin-%d.mat',resDir, selModelInd);
        pruneInterTerms(modelResFile);
    end
    save(resfile, 'flag', 'selModelInd', 'scvVec', 'sigInds');
end

if obtainStateLock1(statefile, nLockTrial)
    load(statefile,'bin');
    
    bin.cmpResArr{stepId} = resfilename;

    save(statefile,'bin','-append');
    releaseStateLock1(statefile);
else
    error('not able to obtain state lock after %d trials.\n', nLockTrial);
end

