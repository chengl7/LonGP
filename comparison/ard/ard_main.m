function [gprMdl,normCoef, selModelName] = ard_main()
% https://se.mathworks.com/help/stats/fitrgp.html#namevaluepairarguments
% Fit GPR Model Using Custom Kernel Function

testfile = 'data1.mat';
varNames = {'age','dise','group','loc','gen','id'};
load(testfile, 'y','ageVec','seroAge_original','gVec','locVec','genderVec','idVec');

groupVec = ~gVec;

seroAgeVec = zeros(520,1);
% tmp = seroAge';
tmp = seroAge_original';
[seroagen, seromu, serostd] = normalize(tmp(:));
seroAgeVec(261:end) = seroagen;

[yn, ymu, ystd] = normalize(y);
[agen, agemu, agestd] = normalize(ageVec);
X = [agen seroAgeVec locVec genderVec groupVec idVec];

theta0 = [log(0.5)*ones(1,6) log(1)];

kfcn = @(XN,XM,theta) myker(XN,XM,theta);

gprMdl = fitrgp(X,yn,'KernelFunction',kfcn,'KernelParameters',theta0,'Sigma',0.2);

estTheta = exp(gprMdl.KernelInformation.KernelParameters)';
fprintf('sigma2_f=%.2f  sigma2_noise=%.2f.\n',estTheta(end), gprMdl.Sigma^2);
fprintf('Squared length scales for %s\n',strjoin(varNames,','));
fprintf('%s\n',num2str(sqrt(estTheta(1:end-1)),'%.2f  '));

tmpeta = 1./estTheta(1:end-1);
tmpeta = tmpeta/sum(tmpeta);
fprintf('Normalized ARD coefficients (percent): %s.\n',num2str(tmpeta*100,'%.2f '));

normCoef = tmpeta;
cutoff = 0.05;
tmpinds = normCoef>cutoff;
selVarNames = varNames(tmpinds); % first is y
selModelName = strjoin(selVarNames,',');
fprintf('selected model: %s\n',selModelName);

figure
ypred = resubPredict(gprMdl);
clf
hold on
for i=1:20
    tmpinds = idVec==i;
    plot(ageVec(tmpinds),ypred(tmpinds),'bs-');
    plot(ageVec(tmpinds),yn(tmpinds),'rx');
end
title('prediction of ard kernel')


function [xx, xmu, xstd] = normalize(x)
xmu = mean(x);
xstd = std(x);
xx = (x - xmu)/xstd;