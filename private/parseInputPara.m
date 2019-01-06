function para=parseInputPara(paraFile,varargin)
% parse the input parameter file
% Lu Cheng
% 9.3.2018

assert(exist(paraFile,'file')>0)

filetext = fileread(paraFile);
lines = strsplit(filetext,'\n');

lines = cellfun(@strtrim,lines,'UniformOutput',false);
einds = cellfun(@isempty,lines);
lines(einds) = [];
lines = cellfun(@rmComments,lines,'UniformOutput',false);
einds = cellfun(@isempty,lines);
lines(einds) = [];

nl = length(lines);

for i=1:nl
    [keys, vals] = parseLine(lines{i});
    switch keys{1}
        case 'inputX'
            assert(strcmp(keys{2},'isCol'));
            para.inputX.file  = vals{1};
            para.inputX.isCol = str2double(vals{2});
            para.inputX.delimiter = '\t';
            
            assert(exist(para.inputX.file,'file')>0, sprintf('input file %s does not exist.\n',para.inputX.file));
            
            if length(keys)==3               
                assert(strcmp(keys{3},'delimiter'));
                para.inputX.delimiter = vals{3};
            end
            
        case 'inputY'
            assert(strcmp(keys{2},'isCol'));
            
            para.inputY.file  = vals{1};
            para.inputY.isCol = str2double(vals{2});
            para.inputY.delimiter = '\t';
            
            assert(exist(para.inputY.file,'file')>0, sprintf('input file %s does not exist.\n',para.inputY.file));

            if length(keys)==3               
                assert(strcmp(keys{3},'delimiter'));
                para.inputX.delimiter = vals{3};
            end
            
        case 'varIndex'
            assert(strcmp(keys{2},'varName'));
            assert(strcmp(keys{3},'interaction'));
            assert(strcmp(keys{4},'selected'));
            assert(strcmp(keys{5},'kernelType'));
            kl = length(keys);
            vi = str2double(vals{1});
            para.kernel.varName{vi} = vals{2};
            para.kernel.interArr(vi) = str2double(vals{3});
            para.kernel.varflag(vi) = str2double(vals{4});
            para.kernel.type(vi) = str2double(vals{5});
            tmp=[];
            for j=6:kl
                eval(sprintf('tmp.%s=%s;',keys{j},vals{j}));
            end
            para.kernel.meta{vi} = tmp;
        case 'plotFigure'
            para.figure.plot=logical(str2double(vals{1}));
            for ii=2:length(keys)
                eval(sprintf('para.figure.%s=%s;',keys{ii},vals{ii}));
            end
        case 'genTestX'
            para.test.flag=logical(str2double(vals{1}));
            para.test.delimiter='\t';
            for ii=2:length(keys)
                eval(sprintf('para.test.%s=%s;',keys{ii},vals{ii}));
            end
        case 'resDir'
            para.resDir=vals{1};
        case 'delInterTerms'
            para.kernel.delInterTerms = vals{1};
        case 'priorFile'
            para.priorFile = vals{1};
        case 'kernelFile'
            para.kernelFile = vals{1};
        otherwise
            eval(sprintf('para.%s;',lines{i}));
    end
end

if ~isfield(para.kernel,'delInterTerms')
    para.kernel.delInterTerms = {};
else
    para.kernel.delInterTerms = procInterTerms(para.kernel.delInterTerms, para.kernel.varName);
end

if ~isfield(para,'discreteCovariateInteraction')
    para.discreteCovariateInteraction = 0;
end

if ~isfield(para,'figure')
    para.figure.plot = false;
end

fixedVarInds = find(para.kernel.varflag);
workVarInds = find(para.kernel.varflag==0);

para.fixedVarInds = fixedVarInds;
para.workVarInds = workVarInds;

assert(~isempty(fixedVarInds), sprintf('No covariate is included in the base model.'))
assert(exist(para.priorFile,'file')>0, sprintf('Prior configuration file %s does not exist.\n',para.priorFile));
assert(exist(para.kernelFile,'file')>0, sprintf('Kernel configuration file %s does not exist.\n',para.kernelFile));

% par = parsePrior('./conf/prior.template.txt');
% [kerarr, kerinterarr, kernamearr] = parseKernel('./conf/kernel.template.txt',par);
par = parsePrior(para.priorFile);
[kerarr, kerinterarr, kernamearr] = parseKernel(para.kernelFile,par);
para.kernel.const = kerarr{strcmp('co',kernamearr)};
para.kernel.mask = kerarr{strcmp('bi',kernamearr)};
para.lik =  kerarr{strcmp('lik',kernamearr)};

conKerArr = cell(1,para.nConVar);
conInterKerArr = cell(1,para.nConVar);
binKerArr = cell(1,para.nBinVar);

conMaskKerArr = cell(1,para.nConVar);
binMaskKerArr = cell(1,para.nBinVar);

assert(length(para.kernel.type)==para.nConVar+para.nBinVar);

for i=1:para.nConVar
    tmpker = kerarr{para.kernel.type(i)};
    tmpinterker = kerinterarr{para.kernel.type(i)};
    
    tmpkername = kernamearr{para.kernel.type(i)};
    assert(any(strcmp(tmpkername,{'se','pe','ns'})),...
        sprintf('kernel type %s for continuous covariate %s not supported.\n',...
        tmpkername, para.kernel.varName{i}));
    
    if ~isempty(para.kernel.meta{i}) && strcmp(tmpkername,'ns')
        a = para.kernel.meta{i}.a; 
        b = para.kernel.meta{i}.b;
        c = para.kernel.meta{i}.c;
        tmpker.nstran = str2func(sprintf('@(x) nstran(x, %f, %f, %f)', a, b, c));
        tmpker.invnstran = str2func(sprintf('@(x) invnstran(x, %f, %f, %f)', a, b, c));
        tmpker = rmfield(tmpker,{'a','b','c'});
        tmpinterker.nstran = tmpker.nstran;
        tmpinterker.invnstran = tmpker.invnstran;
        tmpinterker = rmfield(tmpinterker,{'a','b','c'});
    end
    
    if ~isempty(para.kernel.meta{i}) && strcmp(tmpkername,'pe')
        tmpker.period = para.kernel.meta{i}.period;
        tmpinterker.period = para.kernel.meta{i}.period;
    end
    
    tmpker.selectedVariables = i*2;
    tmpinterker.selectedVariables = i*2;
    
    tmpmaskker = para.kernel.mask;
    tmpmaskker.selectedVariables = i*2-1;
    
    conKerArr{i} = tmpker;
    conInterKerArr{i} = tmpinterker;
    conMaskKerArr{i} = tmpmaskker;
end

for i=1:para.nBinVar
    
    tmpker = kerarr{para.kernel.type(para.nConVar+i)};
    tmpker.selectedVariables = (para.nConVar+i)*2;
    binKerArr{i} = tmpker;
    
    tmpkername = kernamearr{para.kernel.type(para.nConVar+i)};
    assert(any(strcmp(tmpkername,{'ca','bi'})));
     
    tmpmaskker = para.kernel.mask;
    tmpmaskker.selectedVariables = (para.nConVar+i)*2-1;
    binMaskKerArr{i} = tmpmaskker;
end

para.kernel.name = kernamearr(para.kernel.type);
para.kernel.conKerArr = conKerArr;
para.kernel.conInterKerArr = conInterKerArr;
para.kernel.binKerArr = binKerArr;

para.kernel.conMaskKerArr = conMaskKerArr;
para.kernel.binMaskKerArr = binMaskKerArr;

if ~isfield(para,'comVarCutOff')
    para.comVarCutOff = 0;
end

if ~isfield(para,'maxRunTime')
    para.maxRunTime = Inf;
end

if ~isfield(para,'maxIdleTime')
    para.maxRunTime = Inf;
end

assert(strcmp(para.kernel.varName{end},'id'),...
    sprintf('The last covariate is %s, it must be id.\n',para.kernel.varName{end}));

% output mode
isSilent = nargin>1 && strcmp(varargin{1},'silent');
if isSilent
    return
end

% output information of the parsed kernels, base model
intOutArr = {'intearction=No','intearction=Yes'};
incOutArr = {'','included in base model'};
fprintf('Kernel configurations for covariates.\n');
for i=1:para.nConVar+para.nBinVar
    fprintf('%d\t%s\tkernelType=%d\tkernelName=%s\t%s\t%s\n',...
        i,para.kernel.varName{i},para.kernel.type(i), para.kernel.name{i},...
        intOutArr{para.kernel.interArr(i)+1},incOutArr{para.kernel.varflag(i)+1});
end
fprintf('\n');

if ~isempty(para.kernel.delInterTerms)
    fprintf('Interactions excluded: %s.\n',strjoin(para.kernel.delInterTerms,','));
end


function outline = rmComments(line)
% remove comments (#...) from the input line
i=strfind(line,'#');
if ~isempty(i)
    line=line(1:i-1);
end

outline=strtrim(line);

function [keys, vals] = parseLine(str)
% parse the line to construct the prior

% fprintf('%s\n',str);

toks = strsplit(str,{' ','\t'});

ntok = length(toks);

keys = cell(1,ntok);
vals = cell(1,ntok);

for i=1:ntok
    res = regexp(toks{i},'(.+)=(.+)','tokens');
    keys{i} = res{1}{1};
    vals{i} = res{1}{2};
end


function rval = procInterTerms(line, varNames)
line = strtrim(line);
toks = strsplit(line,',');

nTok = length(toks);
for iTok = 1:nTok
    tmp = strsplit(toks{iTok},'*');
    tmp1 = find(strcmp(tmp{1},varNames));
    tmp2 = find(strcmp(tmp{2},varNames));
    
    assert(~isempty(tmp1),sprintf('Interaction term %s does not exist.\n',tmp{1}));
    assert(~isempty(tmp2),sprintf('Interaction term %s does not exist.\n',tmp{2}));
    
    if tmp1>tmp2
        toks{iTok} = sprintf('%s*%s',tmp{2},tmp{1});
    end
end

rval = toks;

