function ageVec = calculateAge(dateFormat, inFile, birthDate, divideBy)
% calculate the age between a given list of dates to an event date
% parameters
% dateFormat: format of date, each line is a date, e.g. 4/3/2018
% inFile: input file for dates, or lines of the dates (UI)
% birthDate: birth date in string format or numeric format, 
% divideBy: number to be divided by, e.g. divideBy=30 to derive age in month

assert(isnumeric(divideBy));

if ischar(dateFormat)
    switch dateFormat
        case {"YYYY-MM-DD","YYYY/MM/DD"}
            dateFormat = 1;
        case {"DD-MM-YYYY","DD/MM/YYYY"}
            dateFormat = 2;
    end
else
    assert(dateFormat==1 || dateFormat==2);
end

if ischar(inFile)
    assert(exist(inFile,'file')>0, sprintf('input file %s does not exist!\n',inFile));
    dateMat = parseFile(inFile);
else
    assert(iscell(inFile)); % lines read from input file, used for user interface
    dateMat = parseLines(inFile);
end

if ischar(birthDate)
    birthDate = parseLine(birthDate);
else
    assert(isnumeric(birthDate) && length(birthDate)==3);
end

nDate = size(dateMat,1);

if dateFormat==2
    dateMat = dateMat(:,3:-1:1);
    birthDate = birthDate(3:-1:1);
end

ageVec = zeros(nDate,1);
birth = datetime(birthDate);
for i=1:nDate
    ageVec(i) = days(datetime(dateMat(i,:))-birth);
end

ageVec = ageVec/divideBy; 

function dateMat = parseLines(lines)

lines = cellfun(@strtrim,lines,'UniformOutput',false);
einds = cellfun(@isempty,lines);
lines(einds) = [];

nLine = length(lines);
dateMat = zeros(nLine,3);
for i=1:nLine
    dateMat(i,:) = parseLine(lines{i});
end


function dateMat = parseFile(inFile)
filetext = fileread(inFile);
lines = strsplit(filetext,'\n');
dateMat = parseLines(lines);


function arr = parseLine(str)
% parse date string into numbers
res = regexp(strip(str),'(\d+)[^0-9]+(\d+)[^0-9]+(\d+)','tokens');
assert(length(res{1})==3);

arr = zeros(1,3);
for i=1:3
    arr(i) = str2double(res{1}{i});
end
assert(arr(2)>=1 && arr(2)<=12, 'month should in 1 to 12. %s\n',str);

if length(res{1}{1})==4
    tmpday = arr(3);
    assert(tmpday>=1 && tmpday<=31, 'day should in 1 to 31. %s\n',str);
elseif length(res{1}{3})==4
    tmpday = arr(1);
    assert(tmpday>=1 && tmpday<=31, 'day should in 1 to 31. %s\n',str);
else
    error('year must have 4 digits. %s\n',str);
end