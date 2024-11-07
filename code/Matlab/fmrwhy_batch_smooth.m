function fmrwhy_batch_smooth(structIn, patInd, protocolNumber, fwhm, out_dir)
%This function takes the structIn as input and performs smoothing on the
%person with number patInd of protocol protocolNumber. 

%% Setup files
    % addpath(util_dir)
    selectedProtocol = selectProtocol(structIn, protocolNumber);
    funcFn = obtainFilePath(selectedProtocol.rest(patInd), 'SN', out_dir, true);

%% Create cell array of scan names
    scans = cell(1,selectedProtocol.slice_acq.N_vol);
    for i = 1:selectedProtocol.slice_acq.N_vol
        scans{i} = [funcFn ',' num2str(i)];
    end

%% Setup matlabbatch
    if length(fwhm) == 1 %if input is a single number, expect it to be cubed
        kernel = [fwhm, fwhm, fwhm];
    end
    spm('defaults','fmri');
    spm_jobman('initcfg');
    prefix = 'smoothed_';
    matlabbatch{1}.spm.spatial.smooth.data = scans';
    matlabbatch{1}.spm.spatial.smooth.fwhm = kernel;
    matlabbatch{1}.spm.spatial.smooth.dtype = 0;
    matlabbatch{1}.spm.spatial.smooth.im = 0;
    matlabbatch{1}.spm.spatial.smooth.prefix = prefix;

%% Run
    cfg_util('run', {matlabbatch});
 
%% Move files
    [d, f, e] = fileparts(funcFn);
    sourcePath = [d filesep prefix f e];
    destinationPath = replacePrepPath(sourcePath, "smoothed");
    if ~isfolder(fileparts(destinationPath)), mkdir(fileparts(destinationPath)); end
    movefile(sourcePath, destinationPath)
    

end