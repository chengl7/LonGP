function [predYArr, modelMat, rmseArr, mind, mModelName] = lmm_main(testfile)

% main script for linear mixed model

%load('test.mat')
X = [y ageVec seroAgeVec groupVec locVec genderVec idVec];
varNames = {'y','age','dise','group','loc','gen','id'};

load(testfile, 'y','age','dise','group','loc','gen','id');

tbl = array2table(X);
% tbl{:,3} = NaN;
tbl.Properties.VariableNames = varNames;


% formula = 'y ~ age + (dise-1|group) + (age|id) + (age|loc) + (age|gen) +(age|group)';
% lme = fitlme(tbl,formula);

% % plot fitting against real value
% predY = fitted(lme);
% clf
% hold on
% for i=1:40
%     tmpinds = idVec==i;
%     plot(ageVec(tmpinds),predY(tmpinds),'b-')
%     plot(ageVec(tmpinds),y(tmpinds),'ro')
% end

% cross validation
nfold=10;
npoint = length(idVec);
[trn_inds, tst_inds] = genCVinds(npoint,nfold);

% all 32 models
formulaArr = {'y ~ 1 + (1|id)',...
    'y ~ age + (age|id)',...
    'y ~ 1 + (dise-1|group) + (1|id)',...
    'y ~ age + (dise-1|group) + (age|id)',...
    'y ~ 1 + (1|id) + (1|loc)',...
    'y ~ age + (age|id) + (age|loc)',...
    'y ~ 1 + (dise-1|group) + (1|id) + (1|loc)',...
    'y ~ age + (dise-1|group) + (age|id) + (age|loc)',...
    'y ~ 1 + (1|id)+ (1|gen)',...
    'y ~ age + (age|id) + (age|gen)',...
    'y ~ 1 + (dise-1|group) + (1|id) + (1|gen)',...
    'y ~ age + (dise-1|group) + (age|id) + (age|gen)',...
    'y ~ 1 + (1|id) + (1|loc) + (1|gen)',...
    'y ~ age + (age|id) + (age|loc) + (age|gen)',...
    'y ~ 1 + (dise-1|group) + (1|id) + (1|loc) + (1|gen)',...
    'y ~ age + (dise-1|group) + (age|id) + (age|loc) + (age|gen)',...
    'y ~ 1 + (1|id)+(1|group)',...
    'y ~ age + (age|id)+(age|group)',...
    'y ~ 1 + (dise-1|group) + (1|id) + (1|group)',...
    'y ~ age + (dise-1|group) + (age|id) + (age|group)',...
    'y ~ 1 + (1|id) + (1|loc) + (1|group)',...
    'y ~ age + (age|id) + (age|loc) + (age|group)',...
    'y ~ 1 + (dise-1|group) + (1|id) + (1|loc) + (1|group)',...
    'y ~ age + (dise-1|group) + (age|id) + (age|loc) + (age|group)',...
    'y ~ 1 + (1|id)+ (1|gen) + (1|group)',...
    'y ~ age + (age|id) + (age|gen) + (age|group)',...
    'y ~ 1 + (dise-1|group) + (1|id) + (1|gen) + (1|group)',...
    'y ~ age + (dise-1|group) + (age|id) + (age|gen) + (age|group)',...
    'y ~ 1 + (1|id) + (1|loc) + (1|gen) + (1|group)',...
    'y ~ age + (age|id) + (age|loc) + (age|gen) + (age|group)',...
    'y ~ 1 + (dise-1|group) + (1|id) + (1|loc) + (1|gen) + (1|group)',...
    'y ~ age + (dise-1|group) + (age|id) + (age|loc) + (age|gen) + (age|group)',...
    };

varNames = {'group','gen','loc','sero','age'};
varFlagArr = zeros(32,5);
modelNameArr = cell(32,1);
k = 1;
tmpVarFlag = zeros(1,5);
for i1 = 0:1
    tmpVarFlag(1)=i1;
    for i2 = 0:1
        tmpVarFlag(2)=i2;
        for i3 = 0:1
            tmpVarFlag(3)=i3;
            for i4 = 0:1
                tmpVarFlag(4)=i4;
                for i5 = 0:1
                    tmpVarFlag(5)=i5;
                    varFlagArr(k,:) = tmpVarFlag;
                    modelNameArr{k} = strjoin(varNames(tmpVarFlag>0),',');
                    k=k+1;
                end
            end
        end
    end
end

% formula = 'y ~ age + (dise-1|group) + (age|id) + (age|loc) + (age|gen) +(age|group)';
% [predY, modelArr, rmse] = lmm(tbl, formula, nfold, trn_inds, tst_inds);

nModel = 32;
predYArr = cell(nModel,1);
modelMat = cell(nModel,nfold);
rmseArr = cell(nModel,1);

for i = 1:nModel
    fprintf('\nmodel %d. \n',i);
    [predYArr{i}, modelMat(i,:), rmseArr{i}] = lmm(tbl, formulaArr{i}, nfold, trn_inds, tst_inds);
end

% choose the best model based on rmse
[mval, mind]=min(cell2mat(rmseArr));
mModelName = modelNameArr{mind};
fprintf('The best model is model %d: y~%s, rmse=%.3f.\n',mind, modelNameArr{mind}, mval);
