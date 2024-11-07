function fmrwhy_batch_BPF(structIn, patInd, protocolNumber, cutoffs, out_dir)
% %This function takes the structIn as input and band-pass filters the
% %temporal dimension of the scan of the person with number patInd of protocol protocolNumber. 

%% Setup files
    % addpath(util_dir)
    selectedProtocol = selectProtocol(structIn, protocolNumber);
    funcFn = obtainFilePath(selectedProtocol.rest(patInd), 'denoised', out_dir, true);
    [path, fn, ext] = fileparts(funcFn);
    if strcmp(ext, '.gz')
        gunzip(funcFn)
        funcFn = [path filesep fn];
    end
    info = niftiinfo(funcFn);
    funcVol = niftiread(info);

%% Setup filter
    TR = selectedProtocol.slice_acq.TR;
    if TR > 1000, TR = TR/1000; end % TR can be in s or ms, but assume that if larger than 1000, it is ms
    fs = 1/TR;
    wp = cutoffs/(fs/2);
    [b,a] = butter(2,wp,'bandpass');
%% check if temporal dimension is first or last
    shape = size(funcVol);
    volInd = find(shape == selectedProtocol.slice_acq.N_vol);
    permuted = false;
    if volInd == 4 % temporal should be first
        funcVol = permute(funcVol, [4 1 2 3]);
        permuted = true;
    end 

%% apply filter
    if ~anynan(funcVol)
        if contains(info.Datatype, 'int')
            funcVol = single(funcVol); %most are saved in 32 bit floats
            info.Datatype = 'single'; %update header
            info.BitsPerPixel = 32; %change this if needed
        end 
        m = mean(funcVol, 1);
        ts = funcVol - m; %floats cannot be subtracted from integers, so if funcVol is int, it should have been converted to float
        ts_bp = filtfilt(b, a, ts) + m;
    else
        error("Nans found in input.") %at this stage there shouldn't be any nans 
    end
    if permuted, ts_bp = permute(ts_bp, [2 3 4 1]); end %permute back if it was necessary
    
%% save
    writeFn = [replace(path, '/', '\') '/preprocessed.nii'];
    niftiwrite(ts_bp, writeFn, info);
    gzip(writeFn); %gzip
    delete(writeFn)
    writeFn = [writeFn '.gz'];
    newPath = replacePrepPath(writeFn, 'BPF');
    if ~isfolder(fileparts(newPath)), mkdir(fileparts(newPath)); end
    movefile(writeFn, newPath);
    

end   