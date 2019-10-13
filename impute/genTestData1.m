function genTestData1(xfile, xoutfile, imputeType)
% fill in the missing values in X
% imputeType: 0-no impute, 1-shift impute, 2-linear interpolate

tbl = readtable(xfile);
ncol = size(tbl,2);

assert(length(imputeType)==ncol)
ageInd = 1;
idInd = ncol;
warning('We implicitly assume age is column %d and id is last column %d.\n',ageInd, idInd);

idVec = tbl{:, idInd};
ageVec = tbl{:, ageInd};

tbl_out = tbl;

uniqId = unique(idVec);
for i=1:ncol
    tmpvec = tbl{:, i};
    if imputeType(i)==0
        continue
        
    elseif imputeType(i)==1
        tmpinds = isnan(tmpvec);
        avg_diff = nanmean(ageVec - tmpvec);
        tmpvec(tmpinds) = ageVec(tmpinds) - avg_diff;
        tbl_out{:,i} = tmpvec;
        
    elseif imputeType(i)==2
        for uid=uniqId(:)'
            tmpinds = idVec==uid;
            tmpvec(tmpinds) = genInterpVec(ageVec(tmpinds), tmpvec(tmpinds), ageVec(tmpinds));
            if all(isnan(tmpvec(tmpinds)))
                warning('imputation for id=%d and column %d (%s) are all NaN.', uid, i, tbl.Properties.VariableNames{i});
            end
        end
        tbl_out{:,i} = tmpvec;
        
    else
        error('Unknown impute type: %d\n')
    end
end

writetable(tbl_out,xoutfile,'Delimiter','\t')




