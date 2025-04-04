%% Preprocess ABIDE
% Written by Sjir Schielen and Jesper Pilmeyer 2024
% In this file, the step-by-step approach to preprocess resting-state functional MRI
% scans is implemented in code using the libraries FSL (in Windows subsystem for Linux) and SPM.
% If you use run FSL in a different location, then you would have to change
% the system prompts involving FSL. 
% The script also requires the image processing toolbox. 
% Note that this script assumes the input nifti files are not gunzipped
% (just .nii)

%% Input
clear; close all; clc;
rootRaw = 'D:/neurodynamics/data/ABIDE/Raw/'; %location of data
out_dir = 'D:/neurodynamics/data/ABIDE/Preprocessed/'; %location of preprocessed output volumes
spm_dir = 'D:\Sjir_Schielen\MATLAB\preprocessing\spm12'; %location of SPM
scan_pars_I_file = 'D:/neurodynamics/data/ABIDE/ABIDE1_improt.xlsx'; %imaging parameters ABIDE 1 (ABIDE1_improt.xlsx)
scan_pars_II_file = 'D:/neurodynamics/data/ABIDE/ABIDE2_improt.xlsx'; %imaging parameters ABIDE 2 (ABIDE2_improt.xlsx)
mask_path = 'D:\neurodynamics\data\ABIDE\groupMask.nii'; % path of mask, only needed at the very end of the script

%preprocessing parameters

  %realignment and discard n first volumes
refvol = 0; %first volume in the dataset after discarded volumes
nrOfVolumesToDiscard = 4;

  %coregistration 
referenceMode = 'first'; %first volume of functional file acts as reference

  %spatial normalization
writeVoxelSize = [2 2 2]; % voxel size to interpolate to, in mm

  %smoothing
kernelSize = 5; %mm

  %Bandpass filter
cutoffs = [0.01 0.1]; %Hz

  %Truncation
nrOfTimePoints = 146;

%% Setup rerun and overwrite preferences
% can be used to run some steps only
keys = ["Realignment", "STC", "Coregistration", ...
    "Segmentation", "SN", "SegMNI", "Smoothing", ...
    "denoising", "BPF", "truncation", "masking"];
RerunValues = [true, true, true, ...
          true, true, true, true, ...
          true, true, true, true];
OverwriteValues = [false, false, false, ...
          false, false, false, false, ...
          false, false, false, false];
RerunSettings = dictionary(keys, RerunValues);
OverwriteSettings = dictionary(keys, OverwriteValues);
%% Exclusions
% Based on the influence on the central nervous system, participants that
% take valproic acid, oxcarbazepine, topiramate, risperidone, citalopram,
% lamotrigine are excluded. 

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

%% setup paths
% Obtain and setup file locations of and for data
% It is assumed that in the raw folder, two folders are present: ABIDE_I
% and ABIDE_II and in each of those there should be folders with the sites.
% Then the same structure as the downloaded data is followed. 

fileArray = obtainFiles(rootRaw, [], false); % empty array triggers default value in function

% remove excluded IDs from file array
for i=1:length(excludeIDs)
    fileArray = fileArray(~contains(fileArray, string(excludeIDs(i))));
end

%split array into corresponding filetypes
csvFiles = splitFileArray(fileArray, ".csv", []); %assuming phenotypic csv files are present
rest_files = splitFileArray(fileArray, "rest", []);
anat_files = splitFileArray(fileArray, "anat", []);
if length(rest_files) ~= length(anat_files) 
    error("\An error appeared in the file structure." + ...
        " The rest and anat files are not both available for at least" + ...
        " one person. This error also occurs when files are" + ...
        " written to the 'raw' directory.")
end


%if files are still gzipped, it cannot be loaded in SPM. The function below
%unzips every file, but this implies that the that the paths are now wrong
%(they lost .gz). So the script needs to be restarted if it used.
% unzipFiles(rest_files)
% unzipFiles(anat_files)


%obtain whitelisted sites
[a1Sites, a2Sites] = whitelisted_sites();
%Set up structures for data organization
a1Struct(length(a1Sites)) = structBluePrint(); %ABIDE I
a2Struct(length(a2Sites)) = structBluePrint(); %ABIDE II

%Fill the paths data in in the fields of the structs
for i = 1:length(a1Sites)
    a1Struct(i) = initializeSiteStruct(a1Struct(i), a1Sites(i), ...
       rest_files, anat_files, csvFiles, "ABIDE_I");
end

for i = 1:length(a2Sites)
    a2Struct(i) = initializeSiteStruct(a2Struct(i), a2Sites(i), ...
       rest_files, anat_files, csvFiles, "ABIDE_II");
end

%special cases where some individuals were scanned differently than the
%rest of the site 
a1twoProtocols = dictionary();
a2twoProtocols = dictionary();
a1spec_sites = ["Stanford_University"]; 
a2spec_sites = ["University_of_Miami",  "University_of_California_Davis", ...
    "University_of_Utah_School_of_Medicine", "NYU_Langone_Medical_Center_Sample_1", ...
     "Trinity_Centre_for_Health_Sciences"];
a1spec_ids = {{[51180 51181 51182 51183 51184 51185 51186 51187 51188 51189 51190 51191 51192 51193 51194 51197 51198], ...
               [51175 51177 51178 51179], [51196 51199]} %Stanford, 
    
  }; 
a2spec_ids = {[30230 30231 30232], 30004, 29504, 29217, 29104};
if ~isempty(a1spec_sites)
    a1twoProtocols = dictionary(a1spec_sites, a1spec_ids);
end
if ~isempty(a2spec_sites)
    a2twoProtocols = dictionary(a2spec_sites, a2spec_ids);
end


%File locations of code 

addpath(spm_dir)

%% Scanning parameters

scan_pars_I = readtable(scan_pars_I_file);
scan_pars_II = readtable(scan_pars_II_file);

% create struct containing acquisition information and fill it in in the
% existing structs

for i = 1:length(a1Sites)
    [rowInd, nrOfProtocols] = findTableIndex(a1Sites(i), scan_pars_I);
    a1Struct(i) = fillInScanPars(a1Struct(i), scan_pars_I, rowInd, nrOfProtocols);

    if nrOfProtocols > 1
        a1Struct(i) = updateProtocols(a1Struct(i), a1twoProtocols, scan_pars_I);
    end
end

for i = 1:length(a2Sites)
    [rowInd, nrOfProtocols] = findTableIndex(a2Sites(i), scan_pars_II);
    a2Struct(i) = fillInScanPars(a2Struct(i), scan_pars_II, rowInd, nrOfProtocols);

    if nrOfProtocols > 1
        a2Struct(i) = updateProtocols(a2Struct(i), a2twoProtocols, scan_pars_II);
    end
end


%% Realignment
% The first four volumes of each sequence are discarded to minimize large
% signal changes before steady state. Rather than removing the first four
% volumes of each scan and then saving these separately, the reference
% volume in realignment is set to four and the first four volumes are
% discarded afterwards. 



%Overwrite existing files
reDoRealignment = RerunSettings("Realignment"); %skip this altogether if false
overwriteRealignments = OverwriteSettings("Realignment"); %overwrite file if there is already one with the name
if reDoRealignment
    %Set up loops for realignment per individual
    fprintf("\n--------- Realignment ---------")
    fprintf("\nRealignment for ABIDE I");
    for i = 1:length(a1Struct)  
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a1Struct(i).siteName), nestCounter)
                        
        for j = 0:a1Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a1Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteRealignments
                    realignSJCS(a1Struct(i), k, refvol, nrOfVolumesToDiscard, j)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'realignment', out_dir) %check if file already exists
                    realignSJCS(a1Struct(i), k, refvol, nrOfVolumesToDiscard, j)
                else
                    fprintf("\nRealignment skipped.")
                end
            end
        end
    end
    
    fprintf("\n\n Realignment for ABIDE II");
    for i = 1:length(a2Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a2Struct(i).siteName), nestCounter)
                        
        for j = 0:a2Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a2Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteRealignments
                    realignSJCS(a2Struct(i), k, refvol, nrOfVolumesToDiscard, j)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'realignment', out_dir) %check if file already exists
                    realignSJCS(a2Struct(i), k, refvol, nrOfVolumesToDiscard, j)
                else
                    fprintf("\nRealignment skipped.")
                end
            end
        end
    
    end
    fprintf("\n")
else
    fprintf("\nRealignment is skipped.\n") %#ok<*UNRCH>
end

%update number of volumes in slice_acq struct
if nrOfVolumesToDiscard ~= 0
    for i = 1:length(a1Struct)
        for j = 0:a1Struct(i).nrOfProtocols-1
            selectedProtocol = selectProtocol(a1Struct(i), j);
            selectedProtocol.slice_acq.N_vol = selectedProtocol.slice_acq.N_vol - ...
                nrOfVolumesToDiscard;
            switch j
                case 0
                    a1Struct(i) = selectedProtocol;
                case 1
                    a1Struct(i).secondProtocol = selectedProtocol;
                case 2
                    a1Struct(i).thirdProtocol = selectedProtocol;
                case 3
                    a1Struct(i).fourthProtocol = selectedProtocol;
                case 4
                    a1Struct(i).fifthProtocol = selectedProtocol;
                case 5
                    a1Struct(i).sixthProtocol = selectedProtocol;
            end
        end
    end

    for i = 1:length(a2Struct)
        for j = 0:a2Struct(i).nrOfProtocols-1
            selectedProtocol = selectProtocol(a2Struct(i), j);
            selectedProtocol.slice_acq.N_vol = selectedProtocol.slice_acq.N_vol - ...
                nrOfVolumesToDiscard;
            switch j
                case 0
                    a2Struct(i) = selectedProtocol;
                case 1
                    a2Struct(i).secondProtocol = selectedProtocol;
                case 2
                    a2Struct(i).thirdProtocol = selectedProtocol;
                case 3
                    a2Struct(i).fourthProtocol = selectedProtocol;
                case 4
                    a2Struct(i).fifthProtocol = selectedProtocol;
                case 5
                    a2Struct(i).sixthProtocol = selectedProtocol;
            end
        end
    end
end

%% Slice timing correction 

%obtain slice timings and store in structs
for i=1:length(a1Struct)
    for j=0:a1Struct(i).nrOfProtocols-1
        selectedProtocol = selectProtocol(a1Struct(i), j);
        updatedSliceTimings = get_slice_timings(selectedProtocol);
        switch j
            case 0
                a1Struct(i).slice_acq.slice_timings = updatedSliceTimings;
            case 1
                a1Struct(i).secondProtocol.slice_acq.slice_timings = updatedSliceTimings;
            case 2
                a1Struct(i).thirdProtocol.slice_acq.slice_timings = updatedSliceTimings;
            case 3
                a1Struct(i).fourthProtocol.slice_acq.slice_timings = updatedSliceTimings;
            case 4
                a1Struct(i).fifthProtocol.slice_acq.slice_timings = updatedSliceTimings;
            case 5
                a1Struct(i).sixthProtocol.slice_acq.slice_timings = updatedSliceTimings;
        end
    end
end

for i=1:length(a2Struct)
    for j=0:a2Struct(i).nrOfProtocols-1
        selectedProtocol = selectProtocol(a2Struct(i), j);
        updatedSliceTimings = get_slice_timings(selectedProtocol);
        switch j
            case 0
                a2Struct(i).slice_acq.slice_timings = updatedSliceTimings;
            case 1
                a2Struct(i).secondProtocol.slice_acq.slice_timings = updatedSliceTimings;
            case 2
                a2Struct(i).thirdProtocol.slice_acq.slice_timings = updatedSliceTimings;
            case 3
                a2Struct(i).fourthProtocol.slice_acq.slice_timings = updatedSliceTimings;
            case 4
                a2Struct(i).fifthProtocol.slice_acq.slice_timings = updatedSliceTimings;
            case 5
                a2Struct(i).sixthProtocol.slice_acq.slice_timings = updatedSliceTimings;
        end
    end
end


%Overwrite existing files
reDoSliceTimings = RerunSettings("STC"); %skip this altogether if false
overwriteSliceTimings = OverwriteSettings("STC"); %overwrite file if there is already one with the name
if reDoSliceTimings
    %Set up loops for slice timing correction per individual
    fprintf("\n--------- Slice timing correction ---------")
    fprintf("\nSlice timing correction for ABIDE I");

    for i = 1:length(a1Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a1Struct(i).siteName), nestCounter)
                        
        for j = 0:a1Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a1Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteSliceTimings
                    fmrwhy_batch_sliceTiming_SS(a1Struct(i), k, j, true, out_dir, true)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'STC', out_dir) %check if file already exists
                    fmrwhy_batch_sliceTiming_SS(a1Struct(i), k, j, true, out_dir, true)
                else
                    fprintf("\nSlice timing correction skipped.")
                end
            end
        end
    end
    
    fprintf("\n\n Slice timing correction for ABIDE II");
    
    for i = 1:length(a2Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a2Struct(i).siteName), nestCounter)
                        
        for j = 0:a2Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a2Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteSliceTimings
                    fmrwhy_batch_sliceTiming_SS(a2Struct(i), k, j, true, out_dir, true)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'STC', out_dir) %check if file already exists
                    fmrwhy_batch_sliceTiming_SS(a2Struct(i), k, j, true, out_dir, true)
                else
                    fprintf("\nSlice timing correction skipped.")
                end
            end
        end
    end

    fprintf("\n")
else
    fprintf("\nSlice timing correction is skipped.\n") %#ok<*UNRCH>
end

%% Coregistration

%Overwrite existing files
reDoCoregistration = RerunSettings("Coregistration") ; %skip this altogether if false
overwriteCoregistration = OverwriteSettings("Coregistration"); %overwrite file if there is already one with the name
if reDoCoregistration
    %Set up loops for coregistration per individual
    fprintf("\n--------- Coregistration ---------")
    fprintf("\nCoregistration for ABIDE I");

    for i = 1:length(a1Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a1Struct(i).siteName), nestCounter)
                        
        for j = 0:a1Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a1Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteCoregistration
                    fmrwhy_batch_coregEst_SS(a1Struct(i), k, referenceMode, 'STC', j, out_dir)
                elseif ~checkFilePath(selectedProtocol.anat(k), 'coregistration', out_dir) %check if file already exists
                    fmrwhy_batch_coregEst_SS(a1Struct(i), k, referenceMode, 'STC', j, out_dir)
                else
                    fprintf("\nCoregistration skipped.")
                end
            end
        end
    end 
    fprintf("\n\n Coregistration for ABIDE II");
    
    for i = 1:length(a2Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a2Struct(i).siteName), nestCounter)
                        
        for j = 0:a2Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a2Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteCoregistration
                    fmrwhy_batch_coregEst_SS(a2Struct(i), k, referenceMode, 'STC', j, out_dir)
                elseif ~checkFilePath(selectedProtocol.anat(k), 'coregistration', out_dir) %check if file already exists
                    fmrwhy_batch_coregEst_SS(a2Struct(i), k, referenceMode, 'STC', j, out_dir)
                else
                    fprintf("\nCoregistration skipped.")
                end
            end
        end
    end 

    fprintf("\n")
else
    fprintf("\nCoregistration is skipped.\n") %#ok<*UNRCH>
end

%% Segmentation
% The coregistered anatomical image is segmented into gray matter, white
% matter, cerebrospinal fluid, bone, soft tissue and air. The affine
% transformation to MNI space is also calculated. 

%Overwrite existing files
reDoSegmentation = RerunSettings("Segmentation"); %skip this altogether if false
overwriteSegmentation = OverwriteSettings("Segmentation"); %overwrite file if there is already one with the name
if reDoSegmentation
    %Set up loops for coregistration per individual
    fprintf("\n--------- Segmentation ---------")
    fprintf("\nSegmentation for ABIDE I");

    for i = 1:length(a1Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a1Struct(i).siteName), nestCounter)

        for j = 0:a1Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a1Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteSegmentation
                    fmrwhy_batch_segment_SS(a1Struct(i), k, spm_dir, out_dir, j)
                elseif ~checkFilePath(selectedProtocol.anat(k), 'segmentation', out_dir) %check if file already exists
                    fmrwhy_batch_segment_SS(a1Struct(i), k, spm_dir, out_dir, j)
                else
                    fprintf("\nSegmentation skipped.")
                end
            end
        end
    end
    
    fprintf("\n\n Segmentation for ABIDE II");

    for i = 1:length(a2Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a2Struct(i).siteName), nestCounter)
                        
        for j = 0:a2Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a2Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteSegmentation
                    fmrwhy_batch_segment_SS(a2Struct(i), k, spm_dir, out_dir, j)
                elseif ~checkFilePath(selectedProtocol.anat(k), 'segmentation', out_dir) %check if file already exists
                    fmrwhy_batch_segment_SS(a2Struct(i), k, spm_dir, out_dir, j)
                else
                    fprintf("\nSegmentation skipped.")
                end
            end
        end
    end

    fprintf("\n")
else
    fprintf("\nSegmentation is skipped.\n") %#ok<*UNRCH>
end


%% Spatial normalization (SN)
% The volumes of the functional scans are normalized to MNI space. This is
% vital for group comparisons. The
% forward transform of the previous step is used. 





%Overwrite existing files
reDoNormalization = RerunSettings("SN"); %skip this altogether if false
overwriteNormalization = OverwriteSettings("SN"); %overwrite file if there is already one with the name
if reDoNormalization
    %Set up loops for spatial normalization per individual
    fprintf("\n--------- Spatial normalization ---------")
    fprintf("\nNormalization for ABIDE I");

    for i = 1:length(a1Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a1Struct(i).siteName), nestCounter)
                        
        for j = 0:a1Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a1Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteNormalization
                    fmrwhy_batch_normaliseWriteSS(a1Struct(i), k, j, writeVoxelSize, out_dir)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'SN', out_dir) %check if file already exists
                    fmrwhy_batch_normaliseWriteSS(a1Struct(i), k, j, writeVoxelSize, out_dir)
                else
                    fprintf("\nNormalization skipped.")
                end
            end
        end
    end
    
    fprintf("\n\n Normalization for ABIDE II");
    
    for i = 1:length(a2Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a2Struct(i).siteName), nestCounter)
                        
        for j = 0:a2Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a2Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteNormalization
                    fmrwhy_batch_normaliseWriteSS(a2Struct(i), k, j, writeVoxelSize, out_dir)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'SN', out_dir) %check if file already exists
                    fmrwhy_batch_normaliseWriteSS(a2Struct(i), k, j, writeVoxelSize, out_dir)
                else
                    fprintf("\nNormalization skipped.")
                end
            end
        end
    end

    fprintf("\n")
else
    fprintf("\nSpatial normalization is skipped.\n") %#ok<*UNRCH>
end

%% Smoothing

reDoSmoothing = RerunSettings("Smoothing"); %skip this altogether if false
overwriteSmoothing = OverwriteSettings("Smoothing");


if reDoSmoothing
    %Set up loops for smoothing per individual
    fprintf("\n--------- Smoothing ---------")
    fprintf("\nSmoothing of ABIDE I");

    for i = 1:length(a1Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a1Struct(i).siteName), nestCounter)
                        
        for j = 0:a1Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a1Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteSmoothing
                    fmrwhy_batch_smooth(a1Struct(i), k, j, kernelSize, out_dir)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'smoothing', out_dir) %check if file already exists
                    fmrwhy_batch_smooth(a1Struct(i), k, j, kernelSize, out_dir)
                else
                    fprintf("\nSmoothing skipped.")
                end
            end
        end
    end
    
    fprintf("\n\n Smoothing of ABIDE II");
    
    for i = 1:length(a2Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a2Struct(i).siteName), nestCounter)
                        
        for j = 0:a2Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a2Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteNormalization
                    fmrwhy_batch_smooth(a2Struct(i), k, j, kernelSize, out_dir)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'smoothing', out_dir) %check if file already exists
                    fmrwhy_batch_smooth(a2Struct(i), k, j, kernelSize, out_dir)
                else
                    fprintf("\nSmoothing skipped.")
                end
            end
        end
    end

    fprintf("\n")
else
    fprintf("\nSmoothing is skipped.\n") %#ok<*UNRCH>
end



%% normalize segmentation maps (needed for masking)


%Overwrite existing files
reDoMNIseg = RerunSettings("SegMNI"); %skip this altogether if false
overwriteMNIseg = OverwriteSettings("SegMNI"); %overwrite file if there is already one with the name

if reDoMNIseg %bring segmentation maps to MNI space
    %Set up loops for spatial normalization per individual
    fprintf("\n--------- Normalization of Segmentation Maps ---------")
    fprintf("\nNormalization for ABIDE I");

    for i = 1:length(a1Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a1Struct(i).siteName), nestCounter)

        for j = 0:a1Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a1Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteMNIseg
                    fmrwhy_batch_normalizeSegmentationMaps_SS(a1Struct(i), k, j, writeVoxelSize, out_dir)
                elseif ~checkFilePath(selectedProtocol.anat(k), 'SegMNI', out_dir) %check if file already exists
                    fmrwhy_batch_normalizeSegmentationMaps_SS(a1Struct(i), k, j, writeVoxelSize, out_dir)
                else
                    fprintf("\nNormalization skipped.")
                end
            end
        end
    end

    fprintf("\n\n Normalization for ABIDE II");

    for i = 1:length(a2Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a2Struct(i).siteName), nestCounter)

        for j = 0:a2Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a2Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteMNIseg
                    fmrwhy_batch_normalizeSegmentationMaps_SS(a2Struct(i), k, j, writeVoxelSize, out_dir)
                elseif ~checkFilePath(selectedProtocol.anat(k), 'SegMNI', out_dir) %check if file already exists
                    fmrwhy_batch_normalizeSegmentationMaps_SS(a2Struct(i), k, j, writeVoxelSize, out_dir)
                else
                    fprintf("\nNormalization skipped.")
                end
            end
        end
    end

    fprintf("\n")
else
    fprintf("\nSpatial normalization is skipped.\n") %#ok<*UNRCH>
end


%% Denoising (regressing out confounders using ICA-AROMA)
% We suggest to use the provided python scripts only if you use windows
% subsystem for Linux. Otherwise, it is better to follow the original
% version: https://github.com/maartenmennes/ICA-AROMA

%Overwrite existing files
reDoDenoising = RerunSettings("denoising"); %skip this altogether if false
overwriteDenoising = OverwriteSettings("denoising"); %overwrite file if there is already one with the name

if reDoDenoising %bring segmentation maps to MNI space
    %Set up loops for spatial normalization per individual
    fprintf("\n--------- Denoising (ICA-AROMA) ---------")
    fprintf("\nDenoising of ABIDE I");

    for i = 1:length(a1Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a1Struct(i).siteName), nestCounter)

        for j = 0:a1Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a1Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteDenoising
                    fmrwhy_batch_ICAAROMA(a1Struct(i), k, j, out_dir)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'denoised', out_dir) %check if file already exists
                    fmrwhy_batch_ICAAROMA(a1Struct(i), k, j, out_dir)
                else
                    fprintf("\nDenoising skipped.")
                end
            end
        end
    end

    fprintf("\n\n Denoising of ABIDE II");

    for i = 1:length(a2Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a2Struct(i).siteName), nestCounter)

        for j = 0:a2Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a2Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteDenoising
                    fmrwhy_batch_ICAAROMA(a2Struct(i), k, j, out_dir)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'denoised', out_dir) %check if file already exists
                    fmrwhy_batch_ICAAROMA(a2Struct(i), k, j, out_dir)
                else
                    fprintf("\nDenoising skipped.")
                end
            end
        end
    end

    fprintf("\n")
else
    fprintf("\nDenoising is skipped.\n") %#ok<*UNRCH>
end


%% Band-pass filter 

%Overwrite existing files
reDoBPF = RerunSettings("BPF"); %skip this altogether if false
overwriteBPF = OverwriteSettings("BPF"); %overwrite file if there is already one with the name

if reDoBPF %bring segmentation maps to MNI space
    %Set up loops for spatial normalization per individual
    fprintf("\n--------- band-pass filtering ---------")
    fprintf("\nBPF on ABIDE I");

    for i = 1:length(a1Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a1Struct(i).siteName), nestCounter)

        for j = 0:a1Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a1Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteBPF
                    fmrwhy_batch_BPF(a1Struct(i), k, j, cutoffs, out_dir)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'BPF', out_dir) %check if file already exists
                    fmrwhy_batch_BPF(a1Struct(i), k, j, cutoffs, out_dir)
                else
                    fprintf("\nBPF skipped.")
                end
            end
        end
    end

    fprintf("\n\n BPF on ABIDE II");

    for i = 1:length(a2Struct)
        nestCounter = 1;
        nestedLoopPrint(sprintf("Site: %s", a2Struct(i).siteName), nestCounter)

        for j = 0:a2Struct(i).nrOfProtocols-1 %loop over protocols
            nestCounter = 2;
            selectedProtocol = selectProtocol(a2Struct(i), j);
            if j > 0
                nestedLoopPrint(sprintf("Protocol %d:", j+1), nestCounter)
            end
            for k = 1:selectedProtocol.nrOfParticipants
                nestCounter = 3;
                nestedLoopPrint(sprintf("ID: %d", selectedProtocol.IDs(k)), nestCounter) 
                if overwriteBPF
                    fmrwhy_batch_BPF(a2Struct(i), k, j, cutoffs, out_dir)
                elseif ~checkFilePath(selectedProtocol.rest(k), 'BPF', out_dir) %check if file already exists
                    fmrwhy_batch_BPF(a2Struct(i), k, j, cutoffs, out_dir)
                else
                    fprintf("\nBPF skipped.")
                end
            end
        end
    end

    fprintf("\n")
else
    fprintf("\nBPF is skipped.\n") %#ok<*UNRCH>
end

%% Trunctation
redoTruncation = RerunSettings("truncation"); %skip this altogether if false
overwriteTruncation = OverwriteSettings("truncation"); %overwrite file if there is already one with the name

if redoTruncation
    for i = 1:length(rest_files)
        if checkFilePath(rest_files(i), 'BPF', out_dir, true)
            BPFpath = obtainFilePath(rest_files(i), 'BPF', out_dir, true);
            truncPath = replacePrepPath(BPFpath, 'truncated');
            fprintf("%s\n", truncPath)
            if ~isfolder(fileparts(truncPath))
                mkdir(fileparts(truncPath))
            end
            if (isfile(truncPath) || isfile(truncPath(1:end-3))) && ~overwriteTruncation
                fprintf("Skipped, already truncated: %s\n", truncPath)
            else 
                copyfile(BPFpath, truncPath)
                if contains(truncPath, '.gz')
                    gunzip(truncPath)
                    delete(truncPath)
                    truncPath = truncPath(1:end-3);     
                    fprintf("Trunctating: %s\n", rest_files(i))
                    funcInfo = niftiinfo(truncPath);
                    funcDat = niftiread(funcInfo);
                    funcDat = funcDat(:,:,:,1:nrOfTimePoints);
                    newImSize = [funcInfo.ImageSize(1:3), nrOfTimePoints];
                    funcInfo.ImageSize = newImSize;
                    niftiwrite(funcDat, funcInfo.Filename, funcInfo);
                end
        
            end
    
    
        else
            fprintf("No BPF file: %s\n", rest_files(i))
        end
    end
end

%% mask output 
% (if desired) This only masks before ICA. 

redoMasking = RerunSettings("masking"); %skip this altogether if false
overwriteMasking = OverwriteSettings("masking"); %overwrite file if there is already one with the name
if redoMasking 
    for i = 1:length(rest_files)
        BPFpath = obtainFilePath(rest_files(i), 'BPF', out_dir, true);
        truncPath = replacePrepPath(BPFpath, 'truncated');
        if contains(truncPath, '.gz'), truncPath = truncPath(1:end-3); end
    
        if isfile(truncPath)
            fprintf('%s\n', truncPath)
            ninfo = niftiinfo(truncPath);
            nvol = niftiread(ninfo);
            mask = niftiread(mask_path);
            maskedVol = nvol.*mask;
            niftiwrite(maskedVol, truncPath, ninfo)
            gzip(truncPath)
            delete(truncPath)
        end
    end
end    