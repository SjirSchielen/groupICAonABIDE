function slice_timings = get_slice_timings(selectedProtocol)
    %% This function only works for interleaved (feet to head and head to feet) and sequential feet to head acquisitions. 
    % It returns the slice timings based on the input protocol.
    nslices = selectedProtocol.slice_acq.N_slices;
    
    if strcmp(selectedProtocol.slice_acq.scan_order, 'default') || strcmp(selectedProtocol.slice_acq.scan_order, 'interleaved')
        %interleaved FH skipping one slice
        % slice_timings_one = zeros([1, selectedProtocol.slice_acq.N_slices]);
        % slice_timings_one(1:2:end) = 0:floor(selectedProtocol.slice_acq.N_slices/2);
        part1 = 0:2:(nslices-1);
        part2 = 1:2:(nslices-1);
        slice_order = [part1, part2];
        aranged = 0:length(slice_order)-1;
        [~, i] = sort(slice_order);
        slice_timings = aranged(i) * selectedProtocol.slice_acq.shot_dur;
    

    elseif strcmp(selectedProtocol.slice_acq.scan_order, 'interleavedHF')

        part1 = (nslices-1):-2:1;
        part2 = (nslices):-2:1;
        slice_order = [part2, part1];
        aranged = 0:length(slice_order)-1;
        [~, i] = sort(slice_order);
        slice_timings = aranged(i) * selectedProtocol.slice_acq.shot_dur;  

    elseif strcmp(selectedProtocol.slice_acq.scan_order, 'FH')
        slice_timings = (0:nslices-1)*selectedProtocol.slice_acq.shot_dur;
    end

end