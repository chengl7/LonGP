function [R, rfull, flag] = runMCMC(gp,x,y,nRep,statefile)
% run MCMC inference, resumable
%
% Lu Cheng
% 15.05.2018

nMCSample = 2500;
nMCDisplay = 500;
nMCBurnIn = 501;
nMCThin = 5;

TEST = [];     % real mode
% TEST = 'test';   % test mode
if strcmp(TEST,'test')
    nMCSample = 500;
    nMCDisplay = 100;
    nMCBurnIn = 10;
    nMCThin = 2;
    nRep = 4;
end

% nRep = 1;
assert(nRep>=1 && nRep<=4);

stateFileFlag = exist(statefile,'file')>0;

if stateFileFlag
    try 
        % update relevant variables, jump to the correct section
        load(statefile,'rep','ri','replicateRecArr','replicateThetaArr','recArr');
    catch ME
        fprintf('%s %s\n', ME.identifier, ME.message);
        fprintf('Delete file %s.\n', statefile);
        delete(statefile);
        stateFileFlag = false;
    end
    
    srep = rep;
    sri = ri+1;
    
    fprintf('Resuming from rep=%d mcmc_round=%d.\n',rep,ri);
end

if ~stateFileFlag
    replicateRecArr = cell(1,nRep);
    replicateThetaArr = cell(1,nRep);
    recArr = cell(4,4);
    srep = 1;
    sri = 1;
end

for rep = srep:nRep
    
    for ri = sri:4
        try
            gpw=gp_pak(gp,'covariance');
            gp=gp_unpak(gp,gpw+rand(size(gpw))*2-1,'covariance');  % initialize with different values
            recArr{rep,ri} = gp_mc(gp, x, y, 'nsamples', nMCSample, 'display', nMCDisplay);
        catch
            recArr{rep,ri} = [];
        end
        
        % save key variables into file for resuming
        if exist(statefile,'file')>0
            save(statefile,'rep','ri','recArr','-append');
        else
            save(statefile,'rep','ri','recArr','replicateRecArr','replicateThetaArr');
        end
    end
    
    sri=1;
    
    tmprecArr = recArr(rep,:);
    tmprecArr = tmprecArr(~cellfun(@isempty,tmprecArr));
    nChain = length(tmprecArr);
    tmpThetaArr = cell(1,nChain);
    
    for ii = 1:nChain
        tmprecArr{ii} = thin(tmprecArr{ii}, nMCBurnIn, nMCThin);
        [tmpThetaArr{ii},~] = gp_pak(tmprecArr{ii});
    end    
    
    replicateThetaArr{rep} = thin(cell2mat(tmpThetaArr'),0,2);
    replicateRecArr{rep} = thin(joinMCChain(tmprecArr),0,2);
    
    % save key variables into file for resuming
    save(statefile,'replicateRecArr','replicateThetaArr','-append');
    
    if rep==1
        thetaArr = tmpThetaArr;
    else
        thetaArr = replicateThetaArr(1:rep);
    end

    %[R,neff,Vh,W,B,tau,thin1] = psrf(thetaArr{:});
    R = psrf(thetaArr{:});
    
    if strcmp(TEST,'test')
        R = ones(size(R));
        break;
    end
    
    if any(abs(R-1)>0.1)        
        fprintf('MCMC does not converge well in repitition %d, continue sampling.\n',rep);
        continue;
    else
        break;
    end
    
end


if any(abs(R-1)>0.2)
    flag=0;
    fprintf('R=[%s]; MCMC does not converge after %d repetition.\n',num2str(R,'%1.2f '),nRep);
elseif any(abs(R-1)>0.1)
    flag=1;
    fprintf('R=[%s]; MCMC does not converge well after %d repetition.\n',num2str(R,'%1.2f '),nRep);
else
    flag=2;
end

if rep==1
    rfull = joinMCChain(tmprecArr);
elseif rep>1
    recArr = replicateRecArr;
    recArr = recArr(~cellfun(@isempty,recArr));
    rfull = joinMCChain(recArr);
else
    error('rep=%d is not accepted.\n',rep);
end

