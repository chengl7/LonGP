# LonGP: An additive Gaussian process regression model for interpretable non-parametric analysis of longitudinal data

LonGP is a tool for performing Gaussian process regression analysis on logitudinal -omics data with complex study designs. It enables the user to 

* model different nonlinear effects with little effort 
* automatically select the best subset of covariates
* decompose complex data non-linear effects, as shown in the following example

![LonGP figure](./AdditiveGP-v8.png)

## Installation
### Requirement
* Linux system or MAC
* Matlab 2016a or later
* [GPstuff 4.7](https://github.com/gpstuff-dev/gpstuff)  or later 
* In case Matlab is not availble, you could use 
  * Compiled version of [LonGP](#install-compiled-longp)
  * Octave version of [LonGP](https://github.com/chengl7/LonGP/tree/LonGP_Octave)

### Steps
1. Install [GPstuff 4.7](https://github.com/gpstuff-dev/gpstuff), this takes ~10 minutes

```
# use the file "LonGP/util/gpcf_cat.m.bak" to replace the file "gpstuff/gp/gpcf_cat.m", then type
matlab_install()

# in mac you probably need to change several lines of "const int *dims;" into "const mwSize *dims;" in some c files under "linuxCsource" folders. You could use the following command in a terminal to find out the lines
# grep -rni "const int \*dims" GPstuff-4.7/

# Or you could use the tested version of GPstuff-4.7 where all modifications have been applied
https://github.com/chengl7/LonGP/blob/gpstuff/GPstuff-4.7.zip
```

2. Copy [LonGP](https://github.com/chengl7/LonGP/archive/master.zip) to the root folder of GPstuff
3. Replace the "startup.m" file in GPstuff root folder by "startup.m.bak" under the LonGP folder
4. test LonGP

```
# in matlab command window
cd('PATH_TO_GPstuff_INSTALLATION') 
startup
cd('LonGP')
lonGP('./test/output',1)  % run LonGP.m for test data
```
5. (Optional) Start Matlab, double click the "LonGP\_UI.mlappinstall" under folder "MatlabGUI\_installer" folder to install the App, this takes less than 10 seconds.

## Example Usage (Serial)
* Prepare the input data. The example data are located in the folder "./example/data" as tab delimited text file "X.txt" and "Y.txt".
* Generate the input parameter configuration file either using the GUI or manually edit using a text editor. The example input parameter file is located in "./example/input.para.txt". To start the GUI, click "APPS" in the top panel and then click "LonGP_UI".
* Run LonGP analysis. Start Matlab, type the following code. To shorten the running time for test purposes, modify file "private/runMCMC.m" to sample less MCMC samples in either of the following ways.  It takes around 8 hours to run for all targets. 
	*  Comment (use % sign) line 12 and uncomment line 13
	*  Delete "runMCMC.m" and rename "runMCMC1.m" to "runMCMC.m".

```
cd('PATH_TO_LONGP_INSTALLATION')  % change to LonGP directory
run('../startup.m')    % load GPstuff environment
lonGP('./example',1)   % run for target variable 1
lonGP('./example',2)   % run for target variable 2
```
* Collect the results in a spreadsheet file. Type the following command in matlab or using GUI. "finalResult.xlsx" and "varExplained.txt" will be generated under the output folder "./example". "varExplained.txt" contains the explained variances of the terms in the final model of each target. The user needs to manually copy it to the spreadsheet.


```
collectResult('./example') 
```
* Generate plots of components. The following code will plot the cumulative effects of the given components, against the real data.


```
targetResultDirectory='./example/Results/1';
xInd = 1; % index of covariate used as x-axis in the plot, here 1st covariate is age
colorInd = 5; % index of covariate used to color individuals, here 5th covariate is group
componentInds=[1 3]; % indexes of the components in the cumulative effect, final model can be seen in "summary.txt".
                     % Final model: model 2 ~ age+diseAge+group+id+age*id. 
                     % Terms 1 and 3 correspond to age+group
genComPlots(targetResultDirectory, xInd, colorInd, componentInds)
```
![Example plot](./example/target_1-com_1+3.png)

* The output directory "./example/Results/i" contains text files for making tailored plots according to users' needs.
  * Predictions for the original data points
     * ./example/rawdata.filled.txt: the original points for prediction, with certain covariates imputed when necessary 
     * rawData.pred.txt: each column is the predicted mean of each component, the last column is the noise
     * rawData.pred.std.txt: each column is the standard deviation of the predictive distribution 
  * Predictions for test data points
     * ./example/testdata.filled.txt: the imputed test data points for prediction
     * testData.pred.txt: each column is the predicted mean of each component, the last column is the residual
     * testData.pred.std.txt: each column is the standard deviation of the predictive distribution 
* Expected output can be found in [exmaple/expectedOutput.zip](./example/expectedOutput.zip)

## Example Usage (Parallel)
We assume a cluster system with shared file system to deploy the work, i.e. all nodes access the same file system. LonGP uses the shared file system to synchronize different task. The running time is ~2 hours with two workers and two slaves, each with 4GB memory.

```
% This part is the same for all nodes
cd('PATH_TO_LONGP_INSTALLATION')  % change to LonGP directory
run('../startup.m')    % load GPstuff environment

% start the task manager, need to run before the workers and slaves
paraLonGP('./example',0)   % run on node 1

% start a worker for target variable 1
paraLonGP('./example',1)   % run on node 2, worker become slave once finished

% start a worker for target variable 2
paraLonGP('./example',2)   % run on node 3, worker become slave once finished

% start a slave 
paraLonGP('./example',slaveId)   % slaveId=10 is a number larger than the total number of targets (2)
```

## Practical details
* Both input files "X.txt" and "Y.txt" must have headers.
* Both input files must be tab delimitered and end with ".txt" file suffix. 
* In "X.txt", the continuous covariates (specific to each time point such as age) should be placed in front of the discrete covariates (specific to each individual such as gender). 
* In "X.txt", the last covariate must be "id" covariate, which is a interger representing an individual.
* Missing values in "X.txt", e.g. diseAge for control, should be marked as "NaN".


## Install compiled LonGP
### Download the compiled LonGP
[LonGP\_linux\_R2017b.zip]()  or [LonGP\_mac\_R2018a.zip]()

### Install Matlab Runtime

Download and install 
[Matlab Runtime R2017b for Linux](http://ssd.mathworks.com/supportfiles/downloads/R2017b/deployment_files/R2017b/installers/glnxa64/MCR_R2017b_glnxa64_installer.zip)
 or 
[Matlab Runtime R2018a for Mac](http://ssd.mathworks.com/supportfiles/downloads/R2018a/deployment_files/R2018a/installers/maci64/MCR_R2018a_maci64_installer.dmg.zip)


### Configure LonGP
Unzip "LonGP\_linux\_R2017b.zip" or "LonGP\_mac\_R2018a.zip" to get the directory "LonGP\_binary"

In Line 16 of “LonGP.sh” in folder “LonGP\_binary” 
```
# Set PATH_TO_MCR_INSTALLATION to the directory where you installed MCR.
MCRROOT=“PATH_TO_MCR_INSTALLATION” 
```

### Run LonGP
A general command looks like 

`PATH_TO_LonGP_binary/LonGP.sh LONGP_CMD args`

It is the same as running the Matlab function
`LONGP_CMD(args)`

We have the following options
```
LONGP_CMD: lonGP, paraLonGP, genComPlots, collectResult, gui
args: arguments for the corresponding command of “LONGP_CMD”
```

### Example
```
LonGP.sh gui # start GUI to setup input parameter files “input.para.txt”
LonGP.sh lonGP ./test/output 1  # run serial lonGP for test dataset 
```

