function fmrwhy_batch_coregEst_SS(structIn, patInd, referenceMode, previousStep, protocolNumber, out_dir, changeOffset)
    % Based on a script by Jesper Pilmeyer
    % This script uses SPM's coregistration estimate and saves the new
    % affine transformation matrix in the header file of a copy of the
    % original anatomical file. 
    % Reference mode 'first' uses the first volume of the realigned
    % functional file and 'mean' uses the time average of the realigned
    % functional file. It is best to match realignment, i.e. if it was
    % realigned to the first volume then first and if it was realigned to
    % the mean then mean. 

    
    %% setup files
    selectedProtocol = selectProtocol(structIn, protocolNumber);
    anat_fn = selectedProtocol.anat(patInd);
    rest_fn = obtainFilePath(selectedProtocol.rest(patInd), previousStep, out_dir, true);

    if strcmp(previousStep, 'realignment')
        resubstring = 'realigned'; %previous step
        strSliceInds = strfind(rest_fn, resubstring);
        fileOut = rest_fn;
            for i = length(strSliceInds):-1:1 %obtain output file name
                ind = strSliceInds(i);
                fileOut = [fileOut(1:ind-1) 'coregistered' fileOut(ind+length(resubstring):end)];
            end
    elseif strcmp(previousStep, 'STC')
        resubstring = 'sliceTimingCorrected'; %previous step
        strSliceInds = strfind(rest_fn, resubstring);
        fileOut = rest_fn;
            for i = length(strSliceInds):-1:1 %obtain output file name
                ind = strSliceInds(i);
                fileOut = [fileOut(1:ind-1) 'coregistered' fileOut(ind+length(resubstring):end)];
            end
    end
        
        % make directory if it does not exist
        if       ~isfile(fileOut)
            outDirPath = stripFileName(fileOut);
            if ~isfolder(outDirPath)
                mkdir(outDirPath)
            end
        end
    
    % Make a copy of the anatomical file for which the header change is allowed
    [anat_a, ~, ~] = fileparts(fileOut);
    [~, anat_b, anat_c] = fileparts(anat_fn);
    anat_copy_fn =strjoin([anat_a '/copy_' anat_b anat_c], '');
    if ~isfile(anat_copy_fn)
        status = copyfile(anat_fn, anat_copy_fn); %#ok<NASGU>
    end
    
    if strcmp(referenceMode, 'first')
        % Obtain a mean functional image for SPM's coregistration
        V = spm_vol(rest_fn);
        Vdata = spm_read_vols(V);
        firstVdata = Vdata(:,:,:, 1);
        structFirst = V(1);
        [fn_a, ~, fn_c] = fileparts(fileOut);
        rest_fn = [fn_a '/first_functional' fn_c];
        structFirst.fname = rest_fn;
        spm_write_vol(structFirst, firstVdata);
    elseif strcmp(referenceMode, 'mean')
    % Obtain a mean functional image for SPM's coregistration
        V = spm_vol(rest_fn);
        Vdata = spm_read_vols(V);
        meanVdata = mean(Vdata, 4);
        structMean = V(1);
        [mean_fn_a, ~, mean_fn_c] = fileparts(fileOut);
        rest_fn = [mean_fn_a '/mean_functional' mean_fn_c];
        structMean.fname = rest_fn;
        spm_write_vol(structMean, meanVdata);
    end    
    
    %% setup coregistration using SPM
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    coreg_estimate = struct; 
    % reference
    coreg_estimate.matlabbatch{1}.spm.spatial.coreg.estimate.ref = {char(rest_fn)};
    % source
    coreg_estimate.matlabbatch{1}.spm.spatial.coreg.estimate.source = {char(anat_copy_fn)};
    % estimate options
    %Normalized mutual information as cost function
    coreg_estimate.matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
    % Distance between sampled points for registration. Vector means multiple
    % coregistrations
    coreg_estimate.matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2]; 
    % Estimate tolerances, iterations stop once estimates are lower than these
    % numbers.
    coreg_estimate.matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    %Gaussian smoothing for joint histogram, not for anat or rest files. 
    coreg_estimate.matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
    
    % Run
    spm_jobman('run', coreg_estimate.matlabbatch);
    % The new affine transformation matrix is saved in the header of the output
    % file

end
