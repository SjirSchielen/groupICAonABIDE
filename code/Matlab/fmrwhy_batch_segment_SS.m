function fmrwhy_batch_segment_SS(structIn, patInd, spm_dir, out_dir, protocolNumber)
    %% setup files
    selectedProtocol = selectProtocol(structIn, protocolNumber);
    anat_fn = selectedProtocol.anat(patInd);
    fileIn = obtainFilePath(anat_fn, 'coregistration', out_dir, true); %coregistered anatomical file
    [inDir, filenameIn, extIn] = fileparts(fileIn);
    corInd = strfind(inDir, 'coregistered');
    corLen = length('coregistered');
    outDir = [inDir(1:corInd-1) 'segmented' inDir(corInd+corLen:end)];
    
    %% setup run
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    segmentation = struct;
    
    % Channel
    % light bias regularisation (default) against MRI artifact that
    % modulates image intensity (field bias)
    segmentation.matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
    % 60 mm cutoff
    segmentation.matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
    segmentation.matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1];
    segmentation.matlabbatch{1}.spm.spatial.preproc.channel.vols = {fileIn};
    
    %Tissue
    % TPM nifti has probability maps for 6 types of tissues/textures, in order:
    % grey matter, white matter, CSF, bone, soft tissue, air
    ngauses = [2, 2, 2, 3, 4, 2]; %nr of Gaussians for each of the tissues (SPM manual)
    for t = 1:6
        %select tissue map from nifti
        segmentation.matlabbatch{1}.spm.spatial.preproc.tissue(t).tpm = {[spm_dir filesep 'tpm' filesep 'TPM.nii,' num2str(t)]};
        %As voxels may not purely represent one tissue type, a different
        %number of Gaussians represents the different number of potential
        %tissues
        segmentation.matlabbatch{1}.spm.spatial.preproc.tissue(t).ngaus = ngauses(t);
        segmentation.matlabbatch{1}.spm.spatial.preproc.tissue(t).native = [1 0];
        segmentation.matlabbatch{1}.spm.spatial.preproc.tissue(t).warped = [0 0];
    end

    % Warp

    %Strength of Markov Random Field
    segmentation.matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
    % Clean up routine, extracts the brain. If parts are missing tone down
    % or disable
    segmentation.matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
    % warping regularisation parameters for aboslute displacement, membrane
    % energy, bending energy, linear elasticity 1, linear elasticity 2
    segmentation.matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
    % Affine registration into standard (mni) space
    segmentation.matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
    % for fMRI value is 0 (SPM manual)
    segmentation.matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
    segmentation.matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
    segmentation.matlabbatch{1}.spm.spatial.preproc.warp.write=[1 1];

    %% Run
    spm_jobman('run', segmentation.matlabbatch)
    
    %% Move files
    fs = '/';
    if contains(inDir, '\'), fs = '\'; end
    inDir(end+1) = fs;
    %segmentation prefixes
    prefspre = ["c1", "c2", "c3", "c4", "c5", "c6", "iy_", "m", "y_", ""];
    prefspost = ["gm_", "wm_", "csf_", "bone_", "soft_tissue_", "air_", "iy_", "m", "y_", ""];
    %segmentation suffixes
    suffs = [repmat(string(extIn), [1,9]) "_seg8.mat"];
    outputFileNames = join([repmat(string(inDir), [1,10])', prefspre', ...
        repmat(string(filenameIn), [1,10])', suffs'], ""); 
    desiredFileNames = join([repmat(string(inDir), [1,10])', prefspost', ...
        repmat(string(filenameIn), [1,10])', suffs'], "");
    %rename
    for i = 1:length(outputFileNames)
        if ~isfile(desiredFileNames(i))
            movefile(outputFileNames(i), desiredFileNames(i));
        end
    end
    
    %move
    if ~isfolder(outDir), mkdir(outDir); end
    for i = 1:length(outputFileNames)
        movefile(desiredFileNames(i), outDir);
    end
end    