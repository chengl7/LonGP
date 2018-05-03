function [flag, fileNames] = getTaskFileNames(resDir)

flag = false;
fileNames = {};

lis = dir(sprintf('%s%s*task*.mat',resDir,filesep));

if isempty(lis)
    return
else
    nFile = length(lis);
    flag = true;
    fileNames = cell(1,nFile);
    for i=1:nFile
        fileNames{i} = lis(i).name;
    end    
end
