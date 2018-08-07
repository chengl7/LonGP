function [predYArr, modelMat, rmseArr, mind, mModelName] = lmm_main1(testfile)

% main script for linear mixed model with second polynomial

% load(testfile, 'y','age','dise','group','loc','gen','id');

load('test.mat')
X = [y ageVec seroAgeVec groupVec locVec genderVec idVec];
varNames = {'y','age','dise','group','loc','gen','id'};

tbl = array2table(X);
% tbl{:,3} = NaN;
tbl.Properties.VariableNames = varNames;
tbl.group = nominal(tbl.group);
tbl.loc = nominal(tbl.loc);
tbl.gen = nominal(tbl.gen);
tbl.id = nominal(tbl.id);

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
    'y ~ age^2 + (age^2|id)',...
    'y ~ dise^2 + (1|id)',...
    'y ~ age^2 + dise^2 + (age^2|id)',...
    'y ~ loc + (1|id)',...
    'y ~ age^2 + loc*age + (age^2 | id)',...
    'y ~ dise^2 + loc + (1|id)',...
    'y ~  age^2 + dise^2 + loc*age + (age^2 | id)',...
    'y ~ gen + (1|id)',...
    'y ~ age^2 + gen*age + (age^2 | id)',...
    'y ~ dise^2 + gen + (1|id)',...
    'y ~ age^2 + dise^2 + gen*age + (age^2 | id)',...
    'y ~ loc + gen + (1|id)',...
    'y ~ age^2 + loc*age + gen*age + (age^2 | id)',...
    'y ~ dise^2 + loc + gen + (1|id)',...
    'y ~ age^2 + dise^2 + loc*age + gen*age + (age^2 | id)',...
    'y ~ group + (1|id)',...
    'y ~ age^2 + group*age + (age^2 | id)',...
    'y ~ dise^2 + group + (1|id)',...
    'y ~ age^2 + dise^2 + group*age + (age^2 | id)',...
    'y ~ loc + group + (1|id)',...
    'y ~ age^2 + loc*age + group*age + (age^2 | id)',...
    'y ~ dise^2 + loc + group + (1|id)',...
    'y ~ age^2 + dise^2 + loc*age + group*age + (age^2 | id)',...
    'y ~ gen + group + (1|id)',...
    'y ~ age^2 + gen*age + group*age + (age^2 | id)',...
    'y ~ dise^2 + gen + group + (1|id)',...
    'y ~ age^2 + dise^2 + gen*age + group*age + (age^2 | id)',...
    'y ~ loc + gen + group + (1|id)',...
    'y ~ age^2 + loc*age + gen*age + group*age + (age^2 | id)',...
    'y ~ dise^2 + loc + gen + group + (1|id)',...
    'y ~ age^2 + dise^2 + loc*age + gen*age + group*age + (age^2 | id)',...
    };

varNames = {'group','gen','loc','dise','age'};
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
                    modelNameArr{k} = strjoin([varNames(tmpVarFlag>0) {'id'}],',');
                    k=k+1;
                end
            end
        end
    end
end

% formula = 'y ~ age + loc*age + gen*age + group*age + (age|id)';
% tmpmdl = fitlme(tbl,formula);
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
