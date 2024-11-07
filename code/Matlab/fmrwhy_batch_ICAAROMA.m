function fmrwhy_batch_ICAAROMA(structIn, patInd, protNum, out_dir)
    % structIn = a1Struct(2);
    % patInd = 1;
    % protNum = 0; 
    
    selectedProtocol = selectProtocol(structIn, protNum);
    funcFN = obtainFilePath(selectedProtocol.rest(patInd), 'smoothing', out_dir, true);
    [funcPath, funcName, funcExt] = fileparts(funcFN);
    copyFN = [funcPath, filesep, 'gzipped_', funcName, funcExt];
    parFilePath = obtainFilePath(selectedProtocol.rest(patInd), 'realignment', out_dir, true);
    parFilePath = [parFilePath '.par']; %par files are named by appending .par to original file name (file name with extension). 
    
    %zip again. It is a bit obnoxious to zip even though it was unzipped after
    %realignment, but FSL wants .nii.gz and SPM .nii. 
    copyfile(funcFN, copyFN);
    gzip(copyFN);
    copyFNgz = [copyFN, '.gz'];
    delete(copyFN)
    prefix = 'denoised_';
    outfilename = [prefix, funcName, '.nii.gz'];
    outFN = [funcPath, filesep, outfilename];
    
    %To create mask (whole brain)
    forwardPath = obtainFilePath(selectedProtocol.anat(patInd), 'segmentation', out_dir, true);
    [ypath, anatName, anatExt] = fileparts(forwardPath);
    anatName = anatName(2:end); %first part should be y
    MNI_csf_path = [ypath filesep 'MNI_csf' anatName anatExt];
    MNI_gm_path = [ypath filesep 'MNI_gm' anatName anatExt];
    MNI_wm_path = [ypath filesep 'MNI_wm' anatName anatExt];
    csfVolr = spm_vol(MNI_csf_path);
    csfVol = spm_read_vols(csfVolr);
    gmVolr = spm_vol(MNI_gm_path);
    gmVol = spm_read_vols(gmVolr);
    wmVolr = spm_vol(MNI_wm_path);
    wmVol = spm_read_vols(wmVolr);
    summedVol = wmVolr;
    summedVol.fname = [ypath filesep 'mask.nii'];
    sumVol = (csfVol + gmVol + wmVol) > 0; %mask
    spm_write_vol(summedVol, sumVol); %save
    gzip(summedVol.fname); %gzip
    maskPath = [funcPath '/mask.nii.gz'];
    movefile([summedVol.fname '.gz'], maskPath);
    
    
    %to check if nans go into melodic
    info = niftiinfo(funcFN);
    funcVol = niftiread(info);
    if anynan(funcVol)
        fprintf("Nans in input. Nans are set to 0 to avoid MELODIC not converging.\n");
        funcVol(isnan(funcVol)) = 0;
        % save copy of original before it is overwritten
        copyFuncFN = [funcPath filesep 'original_' funcName funcExt];
        copyfile(funcFN, copyFuncFN)
        niftiwrite(funcVol, funcFN, info);
        gzip(funcFN)
        movefile([funcFN '.gz'], copyFNgz)
    end
    %end check
    
    % specify the location of your python environment and the script here
    pythonPath = 'C:\ProgramData\Miniconda3\envs\main\python';
    pythonScriptPath = 'D:\Sjir_Schielen\MATLAB\preprocessing\Code\Python_scripts\ICA_AROMA.py';
    copyFNgz = changeDelimiter(copyFNgz);
    outFN = changeDelimiter(outFN);
    parFilePath = changeDelimiter(parFilePath);
    
    % system('bash -c ". ~/.profile && /home/neurodynamics/fsl/bin/fslmaths"')
    system([pythonPath, ' ', pythonScriptPath, ' -in ', copyFNgz, ' -out ', outFN, ' -mc ', parFilePath, ' -m ', maskPath, ' -ow', ' -tr 2'])
    
    destination = replacePrepPath(outFN, 'denoised');
    movefile(outFN, destination);
    destination = char(destination);
    newFolderNameOut = [fileparts(destination) filesep 'ICA_AROMA'];
    movefile(destination, newFolderNameOut); %destination is source in this case because of renaming
    funcFileOut = [newFolderNameOut filesep 'denoised_func_data_nonaggr.nii.gz'];
    movefile(funcFileOut, [fileparts(destination) filesep 'denoised_func_data_nonaggr.nii.gz'])
end

function strout = changeDelimiter(strin)
    if contains(strin, "\")
        strout = strrep(strin, "\", "/");
    elseif contains(strin, "/")
        strout = strrep(strin, "/", "\");
    end
    strout = char(strout);
end

