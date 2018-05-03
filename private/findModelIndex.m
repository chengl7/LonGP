function modelInd = findModelIndex(modelMat, selVarInds)
            
[~, nc] = size(modelMat);
selVec = zeros(1,nc);
selVec(selVarInds) = 1;
modelInd = find(ismember(modelMat,selVec,'rows'));
