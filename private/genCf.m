function [cf, cfName, modelName, cfTerms, cfPara, cfMagnParaInds, nVar, nInteraction] = genCf(currVarFlagArr, para, modelStem)
% generate the coveriance structure for given input covariance functions in
% GPstuff
% INPUT:
%       currVarFlagArr: a vector indicating covariates to be included 
%                 para: parameter configuration
%            modelStem: string, stem of the generated model
% OUTPUT
%       cf: cf (cell array) used by GPstuff
%       cfName: string, only the variable names
%       modelName: string, full model description
% 
% Lu Cheng
% 20.04.2018

modelID = modelStem;

currVarFlagArr = logical(currVarFlagArr);
kerVarFlagArr = logical(para.kernel.varflag);

assert(length(kerVarFlagArr)==length(currVarFlagArr));
assert(all((kerVarFlagArr&currVarFlagArr)==kerVarFlagArr));

nConVar = para.nConVar;
nBinVar = para.nBinVar;

conInds = find(currVarFlagArr(1:nConVar));
binInds = find(currVarFlagArr(nConVar+(1:nBinVar)));

ncon = length(conInds);
nbin = length(binInds);

conInterArr = para.kernel.interArr(1:nConVar);
binInterArr = para.kernel.interArr(nConVar+(1:nBinVar));

conVarName = para.kernel.varName(1:nConVar);
binVarName = para.kernel.varName(nConVar+(1:nBinVar));

% prespecified interaction terms not to be included
if isfield('delInterTerms',para.kernel)
    delInterTerms = para.kernel.delInterTerms;
else
    delInterTerms = [];
end

% kernels for shared continuous covariates
cf1 = cell(1,ncon);
cfname1 = conVarName(conInds);
for i=1:ncon
    iCon = conInds(i);
    cf1{i} = getMaskKernel(para,1,iCon);
end

% kernels for shared binary covariates
cf2 = cell(1,nbin);
cfname2 = binVarName(binInds);
for i=1:nbin
    iBin = binInds(i);
    cf2{i} = getMaskKernel(para,0,iBin);
    cf2{i} = gpcf_prod('cf',{cf2{i}, para.kernel.const});
end

% kernels for interactions between continuous and binary covariates
cf3 = {};
cfname3 = {};
for i=1:ncon
    iCon = conInds(i);
    if conInterArr(iCon)==0
        continue;
    end
    for j=1:nbin
        iBin = binInds(j);
        if binInterArr(iBin)==0
            continue;
        end
        
        tmpProdCfName = sprintf('%s*%s',conVarName{iCon},binVarName{iBin});
        if any(strcmp(tmpProdCfName,delInterTerms))
            continue;
        end
        
        % construct interactions
        tmpcfcon = getMaskKernel(para,1,iCon);
        tmpcfbin = getMaskKernel(para,0,iBin);
        tmpcf = gpcf_prod('cf',{tmpcfcon, tmpcfbin});
        
        cf3{end+1} = tmpcf; 
        cfname3{end+1} = tmpProdCfName;
    end
end


% kernels for interactions between two binary covariates
% last binary covariate is id, so no interaction allowed
cf4 = {};
cfname4 = {};
for i=1:nbin-2
    iBin1 = binInds(i);
    if binInterArr(iBin1)==0
        continue;
    end
    
    for j=i+1:nbin-1
        iBin2 = binInds(j);
        if binInterArr(iBin2)==0
            continue;
        end
        
        tmpProdCfName = sprintf('%s*%s',binVarName{iBin1},binVarName{iBin2});
        if any(strcmp(tmpProdCfName,delInterTerms))
            continue
        end
        
        % construct interactions
        tmpcfbin1 = getMaskKernel(para,0,iBin1);
        tmpcfbin2 = getMaskKernel(para,0,iBin2);
        
        cf4{end+1} = gpcf_prod('cf',{tmpcfbin1,tmpcfbin2,para.kernel.const});
        cfname4{end+1} = tmpProdCfName;
    end    
end

cf = [cf1 cf2 cf3 cf4];
terms = [cfname1 cfname2 cfname3 cfname4];
modelName = sprintf('model %s ~ %s', modelID, strjoin(terms,'+'));
cfTerms = terms;

cfName = sprintf('model %s ~ %s', modelID, strjoin(para.kernel.varName(currVarFlagArr),','));

nVar = sum(currVarFlagArr);

nInteraction = length(cf)-nVar;
nVarModel = nVar+nInteraction;

cfPara = cell(1,nVarModel+1);
cfMagnParaInds = cell(1,nVarModel+1);
for i=1:nVarModel
    [~,cfPara{i}]=cf{i}.fh.pak(cf{i});
    tmpInds = zeros(1,length(cfPara{i}));
    for j = 1:length(tmpInds)
        if ~isempty(strfind(cfPara{i}{j},'magnSigma2'))
            tmpInds(j)=i;
        end
        if ~isempty(strfind(cfPara{i}{j},'constSigma2'))
            tmpInds(j)=i;
        end
    end
    cfMagnParaInds{i} = tmpInds;
end
cfPara{end} = {'log(sigma2)'};
cfMagnParaInds{end} = nVarModel+1;

cfMagnParaInds = cell2mat(cfMagnParaInds);
cfMagnParaInds(cfMagnParaInds<=nVar) = -1 * cfMagnParaInds(cfMagnParaInds<=nVar);


function mker = getMaskKernel(para,isConKer,ind)
% handle the mask for a kernel

if isConKer>0
    if para.kernel.conMaskFlag(ind)
        mker = gpcf_prod('cf',{para.kernel.conKerArr{ind}, para.kernel.conMaskKerArr{ind}});
    else
        mker = para.kernel.conKerArr{ind};
    end
else
    if para.kernel.binMaskFlag(ind)
        mker = gpcf_prod('cf',{para.kernel.binKerArr{ind}, para.kernel.binMaskKerArr{ind}});
    else
        mker = para.kernel.binKerArr{ind};
    end
end



























