% this files performs the dual regression based on the output directory of
% MELODIC


clear; close all; clc;


melOutDir = 'D:\neurodynamics\data\ABIDE\MELODIC\run3'; %output directory of melodic


inputFiles = [melOutDir, '\inputFiles.txt'];
components = [melOutDir, '\melodic_IC.nii.gz'];
des_norm = '1'; %Only stage 1 is needed, which are the time series
design = '-1';
n_perm = '0';
outFolderBase = [melOutDir '\dual_reg'];

inputPaths = readlines(inputFiles);

a1Sites = ["Carnegie_Mellon_University", "NYU_Langone_Medical_Center",...
    "San_Diego_State_University", "Stanford_University", ...
    "Trinity_Centre_for_Health_Sciences", "University_of_Michigan_Sample_1", ...
    "University_of_Michigan_Sample_2", "Yale_Child_Study_Center"];
a2Sites = ["Erasmus_University_Medical_Center_Rotterdam", "Georgetown_University", ...
    "NYU_Langone_Medical_Center_Sample_1", "NYU_Langone_Medical_Center_Sample_2",...
    "San_Diego_State_University", "Stanford_University", ...
    "Trinity_Centre_for_Health_Sciences", "University_of_California_Davis", ...
    "University_of_Miami", "University_of_Utah_School_of_Medicine"];

a1Sites = append("ABIDE_I/", a1Sites);
a2Sites = append("ABIDE_II/", a2Sites);
sites = [a1Sites a2Sites];

%dual regressions for sites which fit in the command. 
for i=1:length(sites)
    outFolder = strjoin([outFolderBase '/', sites(i)], "");
    if ~isfolder(outFolder), mkdir(outFolder); end
    sitePaths = inputPaths(contains(inputPaths, sites(i)));
    cmdString = ['bash -c ". ~/.profile && /home/neurodynamics/fsl/bin/dual_regression ' char(toLinux(components)) ' ' des_norm ' ' design ' ' n_perm ' ' char(toLinux(outFolder)) ...
        ' ' char(strjoin(sitePaths)) '"'];
    a = system(cmdString);
    outputFiles = extractPaths(dir(outFolder));
    renameFiles = outputFiles(contains(outputFiles, 'subject'));
    for j=1:length(renameFiles)
        renameID = IDfrompath(renameFiles(j));
        replaceID = IDfrompath(sitePaths(str2num(renameID)+1)); %+1 for matlab indexing
        newPath = replace(renameFiles(j), renameID, replaceID);
        movefile(renameFiles(j), newPath)
    end
end

%Sites that were too large will stay empty, so here they are obtained
largeSites = strings();
for i = 1:length(sites)
    folder = strjoin([outFolderBase, "\", sites(i)], "");
    if isfolder(folder)
        if length(dir(folder)) == 2 %only wildcards
            largeSites(end+1) = sites(i);
        end
    end
end
largeSites = largeSites(largeSites ~= "");


%For some sites the command is too long, so it is split up in batches.
batchSize = 50;
for i=1:length(largeSites)
    fprintf("%s\n", largeSites(i))
    outFolder = strjoin([outFolderBase '/', largeSites(i)], "");
    if ~isfolder(outFolder), mkdir(outFolder); end
    sitePaths = inputPaths(contains(inputPaths, largeSites(i)));

    batchIterations = ceil(length(sitePaths)/batchSize);
    for bi =1:batchIterations
        upperBound = bi*batchSize;
        outFolderBatch = strjoin([outFolder '/batch' num2str(bi)], '');
        if upperBound > length(sitePaths), upperBound = length(sitePaths); end
        pathBatch = sitePaths( (bi-1)*batchSize + 1 : upperBound);
        cmdString = ['bash -c ". ~/.profile && /home/neurodynamics/fsl/bin/dual_regression ' char(toLinux(components)) ' ' des_norm ' ' design ' ' n_perm ' ' char(toLinux(outFolderBatch)) ...
            ' ' char(strjoin(pathBatch)) '"'];
        a = system(cmdString);
    
        outputFiles = extractPaths(dir(outFolderBatch));
        renameFiles = outputFiles(contains(outputFiles, 'subject'));

        for j=1:length(renameFiles) %files need to be renamed every batch to avoid overwriting
            renameID = IDfrompath(renameFiles(j));
            renameIDint = str2num(renameID);
            if renameIDint < batchSize
                replaceID = IDfrompath(pathBatch(renameIDint+1)); %+1 for matlab indexing
                newPath = replace(renameFiles(j), renameID, replaceID);
                movefile(renameFiles(j), newPath)
            end
        end
        

    end



end



function strout = toLinux(strin)
    strout = replace(strin, 'D:', '/mnt/d');
    strout = replace(strout, "\", "/");
    % if isa(strout, "string"), strout = char(strout); end
end

function pathList = extractPaths(structsIn)
    pathList = strings(length(structsIn), 1);
    for i = 1:length(structsIn)
        filePath = [structsIn(i).folder '\' structsIn(i).name];
        pathList(i) = filePath;
    end
end

function IDstr = IDfrompath(strin)
    strin = char(strin);
    if contains(strin, 'subject') %assume output file
        if contains(strin, '_Z')
            IDstr = strin(strfind(strin, 'subject') + length('subject'):strfind(strin, '_Z')-1);
        else
            IDstr = strin(strfind(strin, 'subject') + length('subject'):strfind(strin, '.')-1);
        end

    else %assume input file 
        strin = string(strin);
        split = strsplit(strin, '/');
        idInd = find(split == 'session_1')-1;
        IDstr = split(idInd);
    end        
end
