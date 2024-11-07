function fmrwhy_batch_normaliseWriteSS(structIn, patInd, protocolNumber, voxelSize, out_dir)
    %% Setup files
    selectedProtocol = selectProtocol(structIn, protocolNumber);
    inputAnatfn = selectedProtocol.anat(patInd);
    inputFuncfn = selectedProtocol.rest(patInd);
    nrVol = selectedProtocol.slice_acq.N_vol;
    
    % location of forward deformation field
    def_fn =  obtainFilePath(inputAnatfn, 'segmentation', out_dir, true);
    % location of slice timing corrected function file
    func_fn = obtainFilePath(inputFuncfn, 'STC', out_dir, true);
    % cell array of volumes (numbered) of functional file (as SPM input)
    volumesToNormalize = cell([1, nrVol]);
    for v = 1:nrVol
        volumesToNormalize{v} = [func_fn ',' num2str(v)];
    end
    
    %% Setup SPM normalise write
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    
    %Reference 
    normalizeWrite.matlabbatch{1}.spm.spatial.normalise.write.subj.def = {def_fn};
    %Data
    normalizeWrite.matlabbatch{1}.spm.spatial.normalise.write.subj.resample = volumesToNormalize';
    %Write options
    %default bounding box
    normalizeWrite.matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [[-90 -126 -72]; [90 90 108]];
    normalizeWrite.matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = voxelSize;
    % 4th order B-spline interpolation
    normalizeWrite.matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
    % prefix for save file name
    prefix = 'w';
    normalizeWrite.matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = prefix;
    
    %% Run
    spm_jobman('run', normalizeWrite.matlabbatch);
    
    %% Move files
    [outdir, outfname, outext] = fileparts(func_fn);
    outPath = [outdir filesep prefix outfname outext];
    underscoreInd = strfind(outfname, '_');
    outFileNewName = [outdir filesep 'MNI' outfname(underscoreInd:end) outext];
    movefile(outPath, outFileNewName) %rename output file
    outPathNew = strrep(outFileNewName, 'sliceTimingCorrected', 'spatiallyNormalized');
    mkdir(fileparts(outPathNew))
    movefile(outFileNewName, outPathNew)
end