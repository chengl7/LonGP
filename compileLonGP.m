fileDir = 'conf';
outDir = 'LonGP_binary';

if ~exist(outDir,'dir')
    mkdir(outDir);
else
    rmdir(outDir,'s');
    mkdir(outDir);
end

list = {'lonGP.m','paraLonGP.m','collectResult.m','genComPlots.m'};
for i=1:length(list)
    mcc('-m',list{i},...
        '-a','../diag','-a','../dist',...
        '-a','../gp','-a','../mc','-a','../optim',...
        '-a','../misc','-a','./private','-a','./util',...
        '-d',outDir);
end

mcc('-v','./GUI/init_window.mlapp','-o','gui','-W','main:gui','-T','link:exe','-d',outDir,'-a','./GUI')

str =  computer;
if strcmp(str,'GLNXA64')
%     delete([outDir filesep '*.c']);
%     delete([outDir filesep '*.prj']);
%     delete([outDir filesep '*.log']);
%     delete([outDir filesep '*.sh']);
% 
%     movefile([outDir filesep 'readme.txt'],[outDir filesep 'mcr_readme.txt']);
%     
%     sysName = 'linux';
%     
%     copyfile([fileDir filesep 'hierBAPS_' sysName '.sh'], [outDir filesep 'hierBAPS.sh']);
%     copyfile([fileDir filesep 'readme_' sysName '.txt'], [outDir filesep]);
%     copyfile([fileDir filesep 'seqs.fa'], [outDir filesep]);
%         
%     zip(['hierBAPS_' sysName '_64bit.zip'],outDir);
    
elseif strcmp(str,'MACI64')
    delete([outDir filesep '*.log']);
    delete([outDir filesep '*.sh']);
    delete([outDir filesep '*.txt']);
    
    sysName = 'mac';
    
    copyfile([fileDir filesep 'LonGP_' sysName '.sh'], [outDir filesep 'LonGP.sh']);
    zip(['LonGP_' sysName '_64bit.zip'],outDir);
else
    error('%s is not supported yet.\n',str);
end