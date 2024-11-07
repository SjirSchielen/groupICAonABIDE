clear; close all; clc;
%% Input 

%It is best to use this script as a reference if you do not use windows
%subsystem for linux. 
maskPath = "D:\neurodynamics\data\ABIDE\groupMask.nii"; %replace, location of mask
out_dir_mel = 'D:/neurodynamics/data/ABIDE/MELODIC/'; %replace, output location of MELODIC
out_dir = 'D:/neurodynamics/data/ABIDE/Preprocessed/'; %replace, place of preprocessed files
rootRaw = 'D:/neurodynamics/data/ABIDE/Raw/'; %replace, place of raw files

numberOfCompontents = 10;

%% Data loading
excludeIDs = [28861, 28871, 28897, 29495, 29875, 29883, 29885, 30000, 50207, ...
       50286, 50287, 50292, 50299, 50305, 50307, 50317, 50325, 50404, ...
       50647, 50650, 50655, 50959, 51163, 51170, 51174];

% excluded because of motion:
toExclude = [50952,50185,50192,51161,51166,51195,50242,51136,50279,50281,...
    50296,50303,50304,50306,50308,50309,50311,50313,50323,50354,50359,...
    50376,50383,50615,50618,29873,29878,29880,29886,29889,29890,29893,...
    29894,29897,29900,29903,29910,29914,29917,28756,28773,28777,28781,...
    28784,28799,28812,28818,28819,28823,28831,28832,28834,28839,28840,...
    30177,29097,29098,29100,29102,29110,29126,29134,29999,30240,30241,...
    29503,29506,29510,29514];

% excluded after visual inspection:
newExclusions = [50296, 50303, 50308, 50653, 29880, 29887, 29888, 29151, ...
    29152, 29153, 29155, 29156, 29158, 29161, 29167, 29168, 29169, 29171, ...
    29172, 29174, 29175, 29176, 28901, 51167, 51176];
toExclude = unique([toExclude, newExclusions]);
alignmentExclusions = [50642, 50646, 50656, 50665, 50666, 50572, 50603, 50605, 50561];
toExclude = unique([toExclude, alignmentExclusions]);
IQexclusions = [50606, 50626];
toExclude = unique([toExclude, IQexclusions]);
excludeIDs = unique([excludeIDs, toExclude]);


fileArray = obtainFiles(rootRaw, [], false); % empty array triggers default value in function

% remove excluded IDs from file array
for i=1:length(excludeIDs)
    fileArray = fileArray(~contains(fileArray, string(excludeIDs(i))));
end

%split array into corresponding filetypes
csvFiles = splitFileArray(fileArray, ".csv", []);
rest_files = splitFileArray(fileArray, "rest", []);
anat_files = splitFileArray(fileArray, "anat", []);
if length(rest_files) ~= length(anat_files)
    error("\It appears we have an oopsie in the file structure." + ...
        " The rest and anat files are not both available for at least" + ...
        " one person. This error also occurs when preprocessed files are" + ...
        " placed in the 'raw' directory.")
end

files_inLin = strings(1,length(rest_files));
for i = 1:length(rest_files)
    files_inLin(i) = toLinux(replacePrepPath(obtainFilePath(rest_files(i), 'BPF', out_dir, true), 'truncated'));
end


%% Running MELODIC
outputDirectory = getICAOutputDir(out_dir_mel);
outputDirectoryLin = toLinux(outputDirectory);

maskPathLin = toLinux(maskPath);

inputFile = [outputDirectory, '\inputFiles.txt'];
fileID = fopen(inputFile, 'w');
for i = 1:length(files_inLin)
    fprintf(fileID, "%s\n", files_inLin(i));
end
fclose(fileID);
inputFile = toLinux(inputFile);

diary([outputDirectory '\MatlabInputs.txt'])
fprintf("Number of components: %s\n", string(numberOfCompontents))
fprintf("mask: %s\n", maskPathLin)
fprintf("output: %s\n", outputDirectoryLin)
fprintf("input: %s\n", inputFile)

%change the file locations according to where your fsl/bin/melodic is
%stored. Alternatively, adapt the command to how you run FSL
if isa(numberOfCompontents, 'double')
    cmdString = ['bash -c ". ~/.profile && /home/neurodynamics/fsl/bin/melodic -i ' inputFile ' -o ' char(outputDirectoryLin) ' -m ' char(maskPathLin) ' -d '...
    char(string(numberOfCompontents)) ' --report --verbose"'];
elseif strcmp(numberOfCompontents, 'default')
    cmdString = ['bash -c ". ~/.profile && /home/neurodynamics/fsl/bin/melodic -i ' inputFile ' -o ' char(outputDirectoryLin) ' -m ' char(maskPathLin) ' --report --verbose"'];    %#ok<*UNRCH>
end
fprintf(cmdString)
fprintf("\n")
diary off; 


system(cmdString)


function strout = toLinux(strin)
    strout = replace(strin, 'D:', '/mnt/d');
    strout = replace(strout, "\", "/");
    % if isa(strout, "string"), strout = char(strout); end
end
