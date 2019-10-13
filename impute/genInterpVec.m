function testY = genInterpVec(origAgeVec, origYVec, testAgeVec)
% interpolate the missing values linearly

assert(length(origAgeVec)==length(origYVec));
tmpinds = ~isnan(origYVec);

origAgeVec = origAgeVec(tmpinds);
origYVec = origYVec(tmpinds);

if isempty(origAgeVec)
    warning('all Nan.')
    testY = nan(size(testAgeVec));
    return
end

testY = interp1(origAgeVec, origYVec, testAgeVec,'linear','extrap');