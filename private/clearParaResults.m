function clearParaResults(resDir, nTarget)

logfile = sprintf('%s%staskManagerLog.txt',resDir,filesep);
if exist(logfile,'file')
    delete(logfile);
end

% remove old state and lock file
resDir = sprintf('%s%sResults',resDir,filesep);
workSubDirInt = getWorkDirs(resDir); % note workSubDir are sorted integers in acending order

for i=1:length(workSubDirInt)
    tmpdir = sprintf('%s%s%d',resDir,filesep,workSubDirInt(i));
    
    if workSubDirInt(i)>nTarget || workSubDirInt(i)<1
        tmpallfiles = sprintf('%s%s*',tmpdir,filesep);
        delete(tmpallfiles);
        continue;
    else
        clearResults(tmpdir);
    end
    
end
