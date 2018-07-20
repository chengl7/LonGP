function [predY, modelArr, rmse] = lmm(tbl, formula, nfold, trn_inds, tst_inds)

modelArr = cell(1,nfold);
npoint = size(tbl,1);
y = tbl{:,'y'};
predY = zeros(npoint,1);

for ifold=1:nfold
    fprintf('cross validation fold %d, in total %d folds.\n',ifold,nfold);
    trn_tbl = tbl(trn_inds{ifold},:);
    tst_tbl = tbl(tst_inds{ifold},:);
    
    tmpmdl = fitlme(trn_tbl,formula);
    
    modelArr{ifold} = tmpmdl;
    predY(tst_inds{ifold}) = predict(tmpmdl,tst_tbl);
end

rmse = sqrt(sum((y-predY).^2)/npoint);


