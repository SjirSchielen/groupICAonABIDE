function exists = checkFilePath(pathIn, prepstep, outdir, realignmentFirst)
% function checks if a file with a name corresponding to the generated and
% moved output file name exists and returns it. 

% prepstep: - 1 realignment
%           - 2 slice timing correction
%           - 3 coregistration
%           - 4 segmentation
%           - 5 spatial normalization
%           - 6 segmentation normalization
%           - 7 smoothing
%           - 8 nuisance regression
%           - 9 band-pass filter

    if nargin < 4
        realignmentFirst = true;
    end

    if isa(pathIn, "string")
        pathIn = char(pathIn);
    elseif ~isa(pathIn, 'char')
        error("Please provide input path as type string or char");
    end
    
    prepPath = outdir;
    if contains(pathIn, "/")
        delimiter = '/';
    elseif contains(pathIn, "\")
        delimiter = '\';
    end

    switch prepstep
        case {1, 'realignment', 'Realignment'}
            prefix = [delimiter, 'realigned_'];
            if realignmentFirst, prefix = [delimiter, '']; end
            dirName = [delimiter 'realigned' delimiter];
        case {2, 'STC', 'slice timing correction'}
            prefix = [delimiter, 'sliceTimingCorrected_'];
            dirName = [ delimiter 'sliceTimingCorrected' delimiter];
        case {3, 'coregistration', 'Coregistration'}
            prefix = [delimiter, 'copy_'];
            dirName = [delimiter 'coregistered' delimiter];
        case {4, 'segmentation', 'Segmentation'}
            prefix = [delimiter, 'y_copy_'];
            dirName = [delimiter 'segmented' delimiter];
        case {5, 'SN', 'spatial normalization'}
            prefix = [delimiter, 'MNI_'];
            dirName = [delimiter 'spatiallyNormalized' delimiter];
        case{6, 'segmentationMNI', 'SegMNI', 'segmni'}
            prefix = [delimiter, 'MNI_gm_copy_'];
            dirName = [delimiter 'segmented' delimiter];
        case {7, 'smoothing', 'Smoothing'}
            prefix = [delimiter, 'smoothed_MNI_'];
            dirName = [delimiter 'smoothed' delimiter];
        case {8, 'regression', 'Regression', 'denoised'}
            prefix = [delimiter, 'denoised_smoothed_MNI_'];
            dirName = [delimiter 'denoised' delimiter];
        case {9, 'band-pass filter', 'band pass filter', 'BPF'}
            prefix = [delimiter, 'preprocessed'];
            dirName = [delimiter 'BPF' delimiter];        
    end


    split = strfind(pathIn, "Raw");
    base = ['Raw', delimiter];
    combined = [prepPath dirName pathIn(split+length(base):end)];
    [fpath, fname, fext] = fileparts(combined);
    fpath = char(fpath);
    fname = char(fname);
    fext = char(fext);
    toCheck = [fpath prefix fname fext];
    switch prepstep
        case {3, 'coregistration', 'Coregistration', ...
              4, 'segmentation', 'Segmentation', ...
              6, 'SegMNI', 'segmni', 'segmentationMNI'}
            anatind = strfind(toCheck, delimiter); %last slashes indicate anat_1
            toCheck = [toCheck(1:anatind(end-1)) 'rest_1' toCheck(anatind(end):end)]; 
        case {8, 'regression', 'denoised'}
            toCheck = [fileparts(toCheck) filesep 'denoised_func_data_nonaggr.nii.gz'];
        case {9, 'band-pass filter', 'band pass filter', 'BPF'}
            toCheck = [fileparts(toCheck) filesep 'preprocessed.nii.gz'];
    end
    exists = isfile(toCheck);
end