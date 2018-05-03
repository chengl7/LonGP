function stopSlave(inds, resDir)

global DEBUG

if DEBUG
    fprintf('in stopSlave. stop inds=%s.\n',num2str(inds));
end

for i=1:length(inds)
    tmpdir = sprintf('%s%s%d',resDir,filesep,inds(i));
    tmpstopfile = sprintf('%s%sstop.txt',tmpdir,filesep);
    
    fid = fopen(tmpstopfile,'w');
    fclose(fid);
    
end