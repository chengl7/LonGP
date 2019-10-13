function y = genShiftVec(ageVec, offset)
% generate a vector by shifting "ageVec" by "offset"
% suitable for "sero", where "offset" is the seroconversion age
y = ageVec - offset;