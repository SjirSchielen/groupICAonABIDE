function fmrwhy_batch_normalizeSegmentationMaps_SS(structIn, patInd, protocolNumber, voxelSize, out_dir)
% This function takes the segmentation maps gray matter, white matter, and
% CSF and normalizes them to MNI space using the forwrard transform. 
    selectedProtocol = selectProtocol(structIn, protocolNumber);
    inputAnatfn = selectedProtocol.anat(patInd);
    def_fn =  string(obtainFilePath(inputAnatfn, 'segmentation', out_dir, true));
    [dirName, fileName, ext] = fileparts(def_fn);
    fileName = char(fileName);
    strippedFileName = fileName(3:end); %assuming it is just called y_
    PathInStructural = join([dirName  '/m' strippedFileName ext], "");
    PathInGM = join([dirName '/gm_' strippedFileName ext], "");
    PathInWM = join([dirName  '/wm_' strippedFileName ext], "");
    PathInCSF = join([dirName  '/csf_' strippedFileName ext], "");
    toNormalize = [PathInStructural, PathInGM, PathInWM, PathInCSF];
    % toNormalize = [PathInStructural];
    
    for i = 1:length(toNormalize)    
        %% Setup SPM normalise write
        spm('defaults','fmri');
        spm_jobman('initcfg');
        
        matlabbatch{1}.spm.spatial.normalise.write.subj.def =  {char(def_fn)};
        matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {char(toNormalize(i))};
        matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = voxelSize;
        matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [[-90 -126 -72]; [90 90 108]];
        matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'MNI_';
        matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
        
        % Run 
        spm_jobman('run',matlabbatch);
    end
end