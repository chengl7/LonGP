function r = joinMCChain(rs,varargin)
% join several markov chains
% Lu Cheng
% 22.04.2018

assert(iscell(rs));

if isempty(rs{1})
    r = [];
    return;
end

if ischar(rs{1})
    r = rs{1};
    return;
end

if isa(rs{1},'function_handle')
    r = rs{1};
    return;
end
    

if isnumeric(rs{1}) && numel(rs{1})==1
    r = rs{1};
    return;
end

if isnumeric(rs{1}) && numel(rs{1})>=1
    r =cell2mat(rs(:));
    return;
end

if iscell(rs{1})
    r = cell(size(rs{1}));
    for i=1:length(rs{1})
        inPara = {};
        for j=1:length(rs)
            inPara{end+1} = rs{j}{i};
        end
        r{i} = joinMCChain(inPara);
    end
    return;
end

if isstruct(rs{1})
    r = struct();
    names = fieldnames(rs{1});
    for i=1:length(names)
        inPara = {};
        for j=1:length(rs)
            inPara{end+1} = rs{j}.(names{i});
        end
        r.(names{i}) = joinMCChain(inPara);
    end
    return;
end