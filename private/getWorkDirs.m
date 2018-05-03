function workSubDir = getWorkDirs(resDir)

lis = dir(resDir);

dirNames = {lis.name};
dirFlag = [lis.isdir];
dirNames = dirNames(dirFlag);

dirNames = cellfun(@str2double,dirNames);
dirNames(isnan(dirNames)) = [];
dirNames = sort(dirNames);

workSubDir = dirNames(:)';