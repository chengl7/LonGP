function genComPlots(resDir, xInd, colorInd, componentInds)
% generate plots for components
% plot the real data together with the predicted components
%
% parentDir: parent directory for all targets  
% targetInd: target to be ploted
% xInd: covariate index for x-axis
% colorInd: covariate index for coloring individuals
% componentInds: index of components to be plotted
% 
% Lu Cheng
% 25.04.2018

xInd = mystr2num(xInd);
colorInd = mystr2num(colorInd);
componentInds = mystr2num(componentInds);

dataFile = sprintf('%s%sdata.mat',resDir,filesep);
assert(exist(dataFile,'file')>0,sprintf('Data file %s does not exist, quit!\n',dataFile));

testFile = sprintf('%s%spredData.mat',resDir,filesep);
assert(exist(testFile,'file')>0,sprintf('Prediction data file %s does not exist, quit!\n',testFile));

resFile = sprintf('%s%sfinalResult.mat',resDir,filesep);
assert(exist(resFile,'file')>0,sprintf('Final result file %s does not exist, quit!\n',resFile));

load(dataFile,'para','rawdata','yFlag','ystd');
load(testFile,'Xt_mf','yt','XR_mf');
load(resFile,'components');

if isempty(colorInd)
    uniqGrp = 1;
    colorName = 'none';
else
    uniqGrp = unique(Xt_mf(:,colorInd));
    assert(colorInd>para.nConVar && colorInd<=para.nConVar+para.nBinVar);
    colorName = rawdata.varNames{colorInd};
end

% plot noise only
if length(componentInds)==1 && componentInds==length(components.cfTerms)
    clf
    plotAge = XR_mf(yFlag);
    plotEff = components.EfArr{end}*ystd;  % missing values have been deleted in Y in data.mat
    
    plot(plotAge, plotEff, '.');
    
    hold on 
    plot(xlim,[0 0])
    
    title(components.cfTerms{end});
    ylim(getBoundary(rawdata.Y));

    xName = sprintf('%s | %s',rawdata.targetName, rawdata.varNames{xInd});
    xlabel(xName);
    
    yName = 'target value (centered)';
    ylabel(yName);
    
    figName = sprintf('%s%snoise-vs-%s', resDir, filesep, rawdata.varNames{xInd});

    saveas(gcf,figName,'png');
    saveas(gcf,figName,'epsc');
    
    return;
end

% handle other ploting cases, real data in the background, predicted
% components on the foreground
assert(all(componentInds<length(components.cfTerms)));

assert(xInd<=para.nConVar);

clf

% plot real data
plotAge = XR_mf(yFlag);
plotEff = rawdata.Y;  % missing values have been deleted in Y in data.mat
groupVec = rawdata.X(:,colorInd);
styleArr = {'bo--','ro--','go--','co--','mo--','yo--','ko--'};
idVec = rawdata.X(:,end);
lw=2;
plotOneByOne(plotAge, plotEff, groupVec, uniqGrp, styleArr, idVec,  lw)

% plot components
plotAge = Xt_mf(:,xInd);
plotEff = sum(yt(:,componentInds),2);
groupVec = Xt_mf(:,colorInd);
styleArr = {'b-','r-','g-','c-','m-','y-','k-'};
idVec = Xt_mf(:,end);
lw=2*2;
plotOneByOne(plotAge, plotEff, groupVec, uniqGrp, styleArr, idVec,  lw)

ylim(getBoundary(rawdata.Y));

xName = sprintf('%s | %s',rawdata.targetName, rawdata.varNames{xInd});
xlabel(xName);

yName = 'target value (centered)';
ylabel(yName);

str1 = sprintf('Component %s VS real intensity',strjoin(components.cfTerms(componentInds),'+'));
str2 = sprintf('Colored by %s',colorName);
title({str1,str2});

% save figure
comName = sprintf('%d+',componentInds);
comName(end)=[];
xName = rawdata.varNames{xInd};
figName = sprintf('%s%sCom%s-%s-by-%s', resDir, filesep, comName, xName, colorName);

saveas(gcf,figName,'png');
saveas(gcf,figName,'epsc');

function plotOneByOne(plotAge, plotEff, groupVec, uniqGrp, styleArr, idVec,  lw)

assert(all(size(plotAge)==size(plotEff)));

if isempty(groupVec)
    groupVec = ones(size(idVec));
end

assert(all(size(plotAge)==size(groupVec)));

% uniqGrp = unique(groupVec);
uniqId = unique(idVec)';

if length(uniqGrp)>length(styleArr)
    tmpstr = sprintf('Number of unique groups (%d) larger than available line styles (%d).\n Start using the same color.\n',length(uniqGrp),length(styleArr));
    warning(tmpstr);
    groupVec = ones(size(groupVec));    
    uniqGrp = 1;
end

nUG = length(uniqGrp);
fhArr = zeros(1,nUG);
labels = cell(1,nUG);

hold on

for i = uniqId
    tmpInds = find(idVec==i);
    if isempty(tmpInds)
        continue;
    end
    
    ic = find(groupVec(tmpInds(1))==uniqGrp);
    tmpfh = plot(plotAge(tmpInds), plotEff(tmpInds), styleArr{ic}, 'LineWidth',lw);
    
    if fhArr(ic)==0
        fhArr(ic) = tmpfh;
        labels{ic} = sprintf('groupVal=%d',uniqGrp(ic));
    end
end

if nUG>1
    legend(fhArr,labels)
end


function y = mystr2num(x)

if ischar(x)
    y = str2num(x);
else
    y =x;
end

function y = getBoundary(x)
tmpMax = max(x)*2;
tmpMin = min(x)*2;
tmpMax = ceil(tmpMax)/2;
tmpMin = floor(tmpMin)/2;

y = [tmpMin tmpMax];



