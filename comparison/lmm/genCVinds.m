function [trn_inds, tst_inds] = genCVinds(npoint,nfold)
% cross validation index

randinds = randperm(npoint);
trn_inds = cell(1,nfold);
tst_inds = cell(1,nfold);
blockinds = round(linspace(0,npoint,nfold+1));
stinds = blockinds(1:nfold)+1;
eninds = blockinds(2:end);
for i=1:nfold
    tst_inds{i} = randinds(stinds(i):eninds(i));
    trn_inds{i} = setdiff(1:npoint,tst_inds{i});
end