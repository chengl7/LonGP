function genComPlots1(resDir, xImputeTable, iTarget, xInd, componentInds, colorVec, colorNames, plotGroupVec, plotGroupNames, outFigFileName)
% plot component figures
% resDir: directory storing results
% xImputeTable: X with missing values imputed
% xInd: index of age, x-axis
% iTarget: ith target for y
% compInds: index of components, y-axis
% colorVec: color for each data item, numeric vector
% colorNames: names for each color, cell array
% plotGroupVec: plot all data items within a data group at a time in
% ploting components, e.g. disease group
% plotGroupNames: names for each group, cell array

% genComPlots1('..', Xout, 550, 1, [ 7], Xout{:,8}, {'aab+nor','t1d'}, Xout{:,8}, {'aab+nor','t1d'})

%% step 1: data preparation
if isempty(colorVec)
    colorVec = ones(size(xImputeTable,1),1);
    colorNames = {'nocolor'};
end

if isempty(plotGroupVec)
    plotGroupVec = xImputeTable{:,end}; % idVec
    plotGroupNames = num2cell( num2str( (1:max(plotGroupVec))' ) )';
end

if min(colorVec)==0
    colorVec = colorVec + 1;
end

if min(plotGroupVec)==0
    plotGroupVec = plotGroupVec + 1;
end

dataFile = sprintf('%s%s%d%sdata.mat',resDir,filesep,iTarget,filesep);
assert(exist(dataFile,'file')>0,sprintf('Data file %s does not exist, quit!\n',dataFile));

resFile = sprintf('%s%s%d%sfinalResult.mat',resDir,filesep,iTarget,filesep);
assert(exist(resFile,'file')>0,sprintf('Final result file %s does not exist, quit!\n',resFile));

load(dataFile,'para','rawdata','yFlag','ystd');
load(resFile,'components');

xImputeTable = xImputeTable(yFlag,:);
colorVec = colorVec(yFlag,:);
plotGroupVec = plotGroupVec(yFlag,:);

plotAge = xImputeTable{:,xInd};

% handle other ploting cases, real data in the background, predicted
% components on the foreground
assert(all(componentInds<length(components.cfTerms)));

assert(xInd<=para.nConVar);

idVec = rawdata.X(:,end);
lw=2;


%% step 2: plot real data of individuals
styleArr = {'bo--','ro--','go--','co--','mo--','yo--','ko--'};
plotEff = rawdata.Y;  % centered, but not standardized
plotOneByOne(plotAge, plotEff, colorVec, colorNames, styleArr, idVec,  lw)

%% step 3: plot components
Eff = cell2mat(components.EfArr) * ystd;
plotEff = sum(Eff(:,componentInds),2);
styleArr = {'b-','r-','g-','c-','m-','y-','k-'};
lw=2*lw;
plotOneGroup(plotAge, plotEff, plotGroupVec, plotGroupNames, styleArr, lw)

%% step 4: add meta information
ylim(getBoundary(rawdata.Y));

xName = sprintf('target %d: %s | %s', iTarget, rawdata.targetName, rawdata.varNames{xInd});
xlabel(xName);

yName = 'target value (centered)';
ylabel(yName);

str1 = sprintf('Component %s VS real intensity',strjoin(components.cfTerms(componentInds),'+'));
% str2 = sprintf('Colored by %s',colorName);
% title({str1,str2});
title(str1)

% save figure
% comName = sprintf('%d+',componentInds);
% comName(end)=[];
% xName = rawdata.varNames{xInd};
% figName = sprintf('%s%s%d%sCom%s-%s', targetDir, filesep, iTarget, filesep, comName, xName);

if ~isempty(outFigFileName) && ~exist(strjoin(outFigFileName,'png'),'file')
    saveas(gcf,outFigFileName,'png');
end

function plotOneByOne(plotAge, plotEff, groupVec, groupNames, styleArr, idVec,  lw)

assert(all(size(plotAge)==size(plotEff)));

if isempty(groupVec)
    groupVec = ones(size(idVec));
end

assert(all(size(plotAge)==size(groupVec)));

uniqGrp = unique(groupVec);
uniqId = unique(idVec)';

assert(max(uniqGrp) <= length(groupNames));

if length(groupNames)>length(styleArr)
    tmpstr = sprintf('Number of unique groups (%d) larger than available line styles (%d).\n Using the same color.\n',length(uniqGrp),length(styleArr));
    warning(tmpstr);
    groupVec = ones(size(groupVec));    
    uniqGrp = 1;
    legendFlag = false;
else
    legendFlag = true;
end

nUG = length(uniqGrp);
fhArr = zeros(1,nUG);
labels = groupNames(1:nUG);

hold on

for i = uniqId
    tmpInds = find(idVec==i);
    if isempty(tmpInds)
        continue;
    end
    
    ic = find(groupVec(tmpInds(1))==uniqGrp);
    [~, tmpidx] = sort(plotAge(tmpInds));
    tmpInds = tmpInds(tmpidx);
    tmpfh = plot(plotAge(tmpInds), plotEff(tmpInds), styleArr{ic}, 'LineWidth',lw);
    
    if fhArr(ic)==0
        fhArr(ic) = tmpfh;
        labels{ic} = groupNames{uniqGrp(ic)};
    end
end

if nUG>1 && legendFlag
    legend(fhArr,labels)
end

function plotOneGroup(plotAge, plotEff, groupVec, groupNames, styleArr, lw)
assert(all(size(plotAge)==size(plotEff)));
assert(all(size(plotAge)==size(groupVec)));

uniqGrp = unique(groupVec);
assert(max(uniqGrp) <= length(groupNames));

if length(groupNames)>length(styleArr) 
    tmpstr = sprintf('Number of unique groups (%d) larger than available line styles (%d).\n All using the same color.\n',length(uniqGrp),length(styleArr));
    warning(tmpstr);
    styleArr = repmat(styleArr(1),1,max(uniqGrp));
    legendFlag = false;
else
    legendFlag = true;
end

nUG = max(uniqGrp);
fhArr = zeros(1,nUG);
labels = groupNames(1:nUG);

hold on

for i = uniqGrp(:)'
    tmpInds = find(groupVec==i);
    if isempty(tmpInds)
        continue;
    end
    
    [~, tmpidx] = sort(plotAge(tmpInds));
    tmpInds = tmpInds(tmpidx);
    tmpfh = plot(plotAge(tmpInds), plotEff(tmpInds), styleArr{i}, 'LineWidth',lw);
    
    if fhArr(i)==0 && legendFlag
        fhArr(i) = tmpfh;
        labels{i} = groupNames{i};
    end
end

if length(uniqGrp)<nUG
    fhArr = fhArr(uniqGrp);
    labels = labels(uniqGrp);
end

if nUG>1 && legendFlag
    legend(fhArr,labels)
end

function y = getBoundary(x)
tmpMax = max(x)*2;
tmpMin = min(x)*2;
tmpMax = ceil(tmpMax)/2;
tmpMin = floor(tmpMin)/2;

y = [tmpMin tmpMax];
