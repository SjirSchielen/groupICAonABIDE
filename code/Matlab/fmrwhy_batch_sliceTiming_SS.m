function fmrwhy_batch_sliceTiming_SS(structIn, id, protocolNumber, moveFile, out_dir, realignmentFirst)
% This function performs slice timing correction for a batch.
% Based on a script made by Jesper Pilmeyer. 


% Load required options
selectedProtocol = selectProtocol(structIn, protocolNumber);
functional_fn = selectedProtocol.rest(id);
st = selectedProtocol.slice_acq.slice_timings;
N_slices = selectedProtocol.slice_acq.N_slices;
ref = selectedProtocol.slice_acq.shot_dur * ceil(N_slices / 2); % reference is around middle slice 
[~, min_ind] = min(abs(ref-st)); %find index of slice timing that is closest to reference

if realignmentFirst %take the realigned file
    functional_fn = obtainFilePath(functional_fn, 'realignment', out_dir, true);
end
fprintf(strcat("\n", functional_fn))
func_spm = spm_vol(char(functional_fn));
Nt = numel(func_spm);
TR = selectedProtocol.slice_acq.TR; %Same for all protocols as per selection criteria
prefix = 'sliceTimingCorrected_';

% Create cell array of file names per volume
vol_names = cell(1, Nt);
for i = 1:Nt
    vol_names{i} = [functional_fn, ',', char(num2str(i))];
end

% Create SPM12 batch job
spm('defaults', 'fmri')
spm_jobman('initcfg');
slice_timing.matlabbatch{1}.spm.temporal.st.scans = {vol_names'};
slice_timing.matlabbatch{1}.spm.temporal.st.nslices = N_slices;
slice_timing.matlabbatch{1}.spm.temporal.st.tr = TR;
slice_timing.matlabbatch{1}.spm.temporal.st.ta = 0;
slice_timing.matlabbatch{1}.spm.temporal.st.so = st; %in ms
slice_timing.matlabbatch{1}.spm.temporal.st.refslice = st(min_ind);  %obtain reference sliced from array  
slice_timing.matlabbatch{1}.spm.temporal.st.prefix = prefix;

% Run
spm_jobman('run', slice_timing.matlabbatch)

%Move File to new location if specified to do so
if moveFile
    outFileName = outputFilePath(functional_fn, prefix);
    if structIn.ABIDE_version == 1
        movePath = [out_dir 'sliceTimingCorrected/ABIDE_I/'];
    elseif structIn.ABIDE_version == 2
        movePath = [out_dir 'sliceTimingCorrected/ABIDE_II/'];
    end
    pathEnd = outFileName;
    if ~isa(pathEnd, "char")
        pathEnd = char(pathEnd);
    end
    pathEnd = pathEnd(strfind(outFileName, structIn.siteName):end);
    movePath = [movePath pathEnd];
    [dirPath, ~, ~] = fileparts(movePath);
    if ~isfolder(dirPath)
        mkdir(dirPath)
    end
    movefile(outFileName, dirPath)

end

end

function fileOut = outputFilePath(pathIn, prefix)
    if contains(pathIn, "/") && contains(pathIn, "\")
        error("\nFile path contains two types of slashes.\n")
    elseif contains(pathIn, "/")
        slashInds = strfind(pathIn, "/");
    elseif contains(pathIn, "\")
        slashInds = strfind(pathIn, "\");
    end
    pathChar = char(pathIn);
    path = pathChar(1:slashInds(end));
    fname = pathChar(slashInds(end)+1:end);
    if ~isa(prefix, 'char')
        prefix = char(prefix);
    end
    fileOut = [path prefix fname];
end