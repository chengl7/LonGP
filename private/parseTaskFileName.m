function [iTarget, nextArg, varInd] = parseTaskFileName(taskFileName)

iTarget = [];
nextArg = [];
varInd = [];

res = regexp(taskFileName,'^(\d+)-task-[bc][io]n-(\d+)-(\d+)\.mat$','tokens');

if ~isempty(res)
    iTarget = str2double(res{1}{1});
    nextArg = str2double(res{1}{2});
    varInd = str2double(res{1}{3});
end