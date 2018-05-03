function X = transX(X,para)

for i=1:para.nConVar
    if strcmp(para.kernel.name{i},'se')
        continue;
    end
          
    tmpFlag = logical(X(:,i*2-1));
    tmpVal = X(:,i*2);
    
    if strcmp(para.kernel.name{i},'ns')
        tmpVal(tmpFlag) = para.kernel.conKerArr{i}.nstran(tmpVal(tmpFlag));
        X(:,i*2) = tmpVal;
        continue;
    end
    
    if strcmp(para.kernel.name{i},'pe')
        tmpVal(tmpFlag) = mod(tmpVal(tmpFlag),para.kernel.conKerArr{i}.period);
        X(:,i*2) = tmpVal;
        continue;
    end
end