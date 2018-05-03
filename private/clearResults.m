function clearResults(resDir)
% resDir is the running dir for a single target

tmpstatefile = sprintf('%s%sstate.mat',resDir,filesep);
tmpfinalfile = sprintf('%s%sfinalResult.mat',resDir,filesep);
tmpsummaryfile = sprintf('%s%ssummary.txt',resDir,filesep);
tmprunfile = sprintf('%s%sworker.run.txt',resDir,filesep);
if ~exist(tmpfinalfile,'file') && exist(tmpsummaryfile,'file')
    delete(tmpsummaryfile);
end

if ~exist(tmpfinalfile,'file') && exist(tmpstatefile,'file')
    delete(tmpstatefile);
end

if exist(tmprunfile,'file')>0
    delete(tmprunfile);
end

tmptaskfiles = sprintf('%s%s*task*.mat',resDir,filesep);
delete(tmptaskfiles);

tmplockfiles = sprintf('%s%s*.lock',resDir,filesep);
delete(tmplockfiles);

tmpfreefile = sprintf('%s%sfree.txt',resDir,filesep);
tmprunfile = sprintf('%s%srun.txt',resDir,filesep);
tmpstopfile = sprintf('%s%sstop.txt',resDir,filesep);


if exist(tmpfreefile,'file')
    delete(tmpfreefile);
end

if exist(tmprunfile,'file')
    delete(tmprunfile);
end

if exist(tmpstopfile,'file')
    delete(tmpstopfile);
end
