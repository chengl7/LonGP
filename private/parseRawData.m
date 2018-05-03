function outFile = parseRawData(xfile, xIsCol, xdelimiter, yfile, yIsCol, ydelimiter, resDir)
% process raw data
% Lu Cheng
% 06.03.2018
%
% xfile: input file of x, must have a header row/column, NaN for missing
% value
% xIsCol: 1 - column vectors, 0 - row vectors
% yfile: input file of y, must have a header row/column, Nan for missing
% value
% yIsCol: 1 - column vectors, 0 - row vectors
% delimiter: delimeter for the elements

assert(exist(xfile,'file')>0);
assert(exist(yfile,'file')>0);
assert(~strcmp(xfile,yfile));

fprintf('\nStart processing raw data.\n');

if ischar(xIsCol)
    xIsCol = str2double(xIsCol);
end

if ischar(yIsCol)
    yIsCol = str2double(yIsCol);
end

assert(xIsCol==0 | xIsCol==1);
assert(yIsCol==0 | yIsCol==1);

if ~exist(resDir,'dir')>0
    mkdir(resDir)
end

outFile = 'rawdata.mat';
outFile = sprintf('%s%s%s',resDir,filesep,outFile);

% process x
A = importdata(xfile,xdelimiter);
if xIsCol==1
    varNames = A.colheaders;
    X = A.data;
else
    varNames = A.rowheaders';
    X = A.data';
end

A = importdata(yfile,ydelimiter);
if yIsCol==1
    targetNames = A.colheaders;
    y = A.data;
else
    targetNames = A.rowheaders';
    y = A.data';
end

fprintf('%d covarites: ',length(varNames));
for i=1:length(varNames)
    fprintf('%s\t',varNames{i});
    if mod(i,10)==0
        fprintf('\n');
    end
end
fprintf('\n');

fprintf('%d target variables: ',length(targetNames));
for i=1:length(targetNames)
    fprintf('%s\t',targetNames{i});
    if mod(i,10)==0
        fprintf('\n');
    end
end
fprintf('\n');

nSampleX = size(X,1);
nSampleY = size(y,1);
if nSampleX ~= nSampleY
    error('number of samples in X=%d and y=%d do not agree.\n',nSampleX,nSampleY);
end

Y = y;
save(outFile,'X','Y','varNames','targetNames')

fprintf('Processed raw file %s is ready.\n',outFile);