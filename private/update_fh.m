function y = update_fh(rfull, gp)
% update the function handles in rfull, using the corresponding fhs in gp

if isfield(rfull,'p')
    rfull.p = gp.p;
end

if isfield(rfull,'fh')
    rfull.fh = gp.fh;
end

if isfield(rfull,'lik')
    rfull.lik = update_fh(rfull.lik, gp.lik);
end

if isfield(rfull,'cf')
    for i=1:length(rfull.cf)
        rfull.cf{i} = update_fh(rfull.cf{i}, gp.cf{i});
    end
end

y = full;