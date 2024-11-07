function outStruct = fillInScanPars(structIn, scan_pars, rowInd, nrOfProtocols)
    %This function fills the scanning parameters into the input struct
    slice_acq.MB_enable = 'no'; % or 'no' for no multiband
    scan_order = scan_pars{rowInd, "sequence"};
    sequence_direction = scan_pars{rowInd, "sequenceDirection"};
    if strcmp(scan_order, "interleaved")
        %in this code implementation interleaved is default
        if strcmp(sequence_direction, "FH")
            slice_acq.scan_order = 'default'; 
        elseif strcmp(sequence_direction, "HF")
            slice_acq.scan_order = 'interleavedHF';
        end
    elseif strcmp(scan_order, "sequential")
        slice_acq.scan_order = sequence_direction;
    end
    slice_acq.TR = 2000; % repetition time in ms (same for all sites), for some nifti headers the TR is 0 or 1 but it should be 2 s, so it is hard coded here
    slice_acq.N_slices = scan_pars{rowInd, 'ZSlices'};
    slice_acq.N_vol = scan_pars{rowInd, 'Nv'};
    slice_acq.MB_factor = 1;
    slice_acq.shot_dur = slice_acq.TR/slice_acq.N_slices; %No Multiband
    slice_acq.voxelSize = ...
    voxelSizeFromCellArray(scan_pars{rowInd, 'voxelSize'});
    structIn.slice_acq = slice_acq;
    if ~isempty(nrOfProtocols)
        structIn.nrOfProtocols = nrOfProtocols;
    end
    outStruct = structIn;
end

function voxelSize = voxelSizeFromCellArray(vSize)
    % function to read in the voxel size field from cell array to double
    % array
    if contains(vSize, 'x') && contains(vSize, 'X')
        error("Two types of delimiter used.\n")
    elseif contains(vSize, 'X')
        splitArray = strsplit(vSize{1}, 'X');
    elseif contains(vSize, 'x')
        splitArray = strsplit(vSize{1}, 'x');
    end
    voxelSize = str2double(splitArray);
end