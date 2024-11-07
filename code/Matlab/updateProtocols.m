function structIn = updateProtocols(structIn, twoProtDict, scan_pars)
        %if a site specified more than 1 protocol, the participants need to be
        %placed with the correct protocol. The largest group stays in the
        %main struct and the ones that were scanned differently go to the
        %subsequent structs secondProtocol, thirdProtocol, etc.


        if structIn.nrOfProtocols > 1
            %newProtNumber refers to the new protocol number. The second protocol is newProtNumber 1, the third is 2, etc.
            for newProtNumber = 1:structIn.nrOfProtocols-1
                changeIds = twoProtDict{structIn.siteName};
                if isa(changeIds, 'cell')
                    changeIds = changeIds{newProtNumber};
                end
                inds = ismember(structIn.IDs, changeIds);
                switch newProtNumber
                    case 1
                        structIn.secondProtocol = addProtocol(structIn, scan_pars, inds, changeIds);
                    case 2
                        structIn.thirdProtocol = addProtocol(structIn, scan_pars, inds, changeIds);
                    case 3
                        structIn.fourthProtocol = addProtocol(structIn, scan_pars, inds, changeIds);
                    case 4
                        structIn.fifthProtocol = addProtocol(structIn, scan_pars, inds, changeIds);
                    case 5
                        structIn.sixthProtocol = addProtocol(structIn, scan_pars, inds, changeIds);
                end
                structIn.rest = structIn.rest(~inds);
                structIn.anat = structIn.anat(~inds);
                structIn.IDs = structIn.IDs(~inds);
                structIn.nrOfParticipants = ...
                structIn.nrOfParticipants - length(changeIds);
            end
        end
end

function newProt = addProtocol(structIn, scan_pars, inds, changeIds)
    newProt.rest = structIn.rest(inds);
    newProt.anat = structIn.anat(inds);
    newProt.IDs = structIn.IDs(inds);
    newProt.nrOfParticipants = length(changeIds);
    [rowInd, ~] = findTableIndex(...
           join([structIn.siteName, string(changeIds)], "_"), scan_pars);    
    newProt = fillInScanPars(newProt, scan_pars, rowInd, []);
end