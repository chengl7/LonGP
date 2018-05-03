function [kernelArr, kernelInterArr, kernelNameArr] = parseKernel(kernelFile, priorArr)
% get kernel array
% Lu Cheng
% 8.3.2017

assert(exist(kernelFile,'file')>0)

filetext = fileread(kernelFile);
lines = strsplit(filetext,'\n');

lines = cellfun(@strtrim,lines,'UniformOutput',false);
einds = cellfun(@isempty,lines);
lines(einds) = [];

nl = length(lines);

kernelArr = cell(1,nl);
kernelInterArr = cell(1,nl);
kernelNameArr = cell(1,nl);

for i=1:nl
    [kernel, kernelind, kernelname, interFlag] = parseLine(lines{i}, priorArr);
    assert(kernelind<=nl);
    
    if interFlag
        kernelInterArr{kernelind} = kernel;
    else
        kernelArr{kernelind} = kernel;
    end
    
    kernelNameArr{kernelind} = kernelname;
end

einds = cellfun(@isempty,kernelNameArr);
kernelArr(einds) = [];
kernelInterArr(einds) = [];
kernelNameArr(einds) = [];


function [kernel, kernelind, kernelname, intFlag] = parseLine(str, priorArr)
% parse the line to construct the prior

toks = strsplit(str);

res = regexp(toks{1},'(.+)=(.+)','tokens');
assert(strcmp(res{1}{1},'kernelType'));
kernelind = str2double(res{1}{2});

res = regexp(toks{2},'(.+)=(.+)','tokens');
assert(strcmp(res{1}{1},'kernelName'));

intFlag = ~isempty(regexp(res{1}{2},'_inter$','ONCE'));
if intFlag
    kernelname = res{1}{2}(1:2);
    assert(any(strcmp(kernelname,{'se','pe','ns'})));
else
    kernelname = res{1}{2};
end

res = regexp(toks{3},'(.+)=(.+)','tokens');
assert(strcmp(res{1}{1},'kernelFunc'));
kernel = eval(sprintf('%s;',res{1}{2}));

checkKernelName(kernelname, res{1}{2});

for i=4:length(toks)
    res = regexp(toks{i},'(.+)=(.+)','tokens');
    if ~isempty(regexp(res{1}{1},'_prior$','ONCE'))
        
        eval(sprintf('kernel.p.%s=priorArr{%s};',res{1}{1}(1:end-6),res{1}{2}));
    else
        eval(sprintf('kernel.%s;',toks{i}));
    end
end

% process non stationary
if strcmp(kernelname, 'ns')
    kernel.nstran = str2func(sprintf('@(x) nstran(x, %f, %f, %f)', kernel.a, kernel.b, kernel.c));
    kernel.invnstran = str2func(sprintf('@(x) invnstran(x, %f, %f, %f)', kernel.a, kernel.b, kernel.c));
end

function checkKernelName(kernelname, funcName)
% check kernel name and function agrees
switch kernelname
    case 'se'
        assert(strcmp(funcName,'gpcf_sexp()'))
    case 'ns'
        assert(strcmp(funcName,'gpcf_sexp()'))
    case 'pe'
        assert(strcmp(funcName,'gpcf_periodic()'))
    case 'co'
        assert(strcmp(funcName,'gpcf_constant()'))
    case 'ca'
        assert(strcmp(funcName,'gpcf_cat()'))
    case 'bi'
        assert(strcmp(funcName,'gpcf_mask()'))
    case 'lik'
        assert(strcmp(funcName,'lik_gaussian()'))
end