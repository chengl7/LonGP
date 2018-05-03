function priorArr = parsePrior(priorFile)
% get prior array
% Lu Cheng
% 7.3.2017

assert(exist(priorFile,'file')>0)

filetext = fileread(priorFile);
lines = strsplit(filetext,'\n');

lines = cellfun(@strtrim,lines,'UniformOutput',false);
einds = cellfun(@isempty,lines);
lines(einds) = [];

nl = length(lines);

priorArr = cell(1,nl);
for i=1:nl
    [p,pind] = parseLine(lines{i});
    assert(pind<=nl);
    priorArr{pind}=p;
end


function [p, pind] = parseLine(str)
% parse the line to construct the prior

toks = strsplit(str);

res = regexp(toks{1},'(.+)=(.+)','tokens');
assert(strcmp(res{1}{1},'priorID'));
pind = str2double(res{1}{2});

res = regexp(toks{2},'(.+)=(.+)','tokens');
assert(strcmp(res{1}{1},'priorFunc'));
p = eval(sprintf('%s;',res{1}{2}));

for i=3:length(toks)
    eval(sprintf('p.%s;',toks{i}));
end




