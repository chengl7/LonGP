function flag = obtainStateLock1(statefile, nTrial)

statefilelock = sprintf('%s.lock',statefile);

flag = true;

for t = 1:nTrial
    if ~exist(statefilelock,'file')
        fid = fopen(statefilelock,'w'); % obtain file lock
        fclose(fid);
        return;
    else
        pause(1+rand(1));
    end
end
flag = false;