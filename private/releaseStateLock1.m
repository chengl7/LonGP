function releaseStateLock1(statefile)

statefilelock = sprintf('%s.lock',statefile);
delete(statefilelock);