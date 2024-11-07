function realignSJCS(structIn, patInd, refvol, discardVolumes, protNum, realignmentFirst)
    % Based on a script by Jesper Pilmeyer
    % This script calls mcflirt
    % mcflirt is in the FSL package
    % This function takes the functional image and realignes
    % all images to volume at index refvol. If some volumes need to
    % be discarded first, the reference volume is interpreted as the index after
    % discarding.
    
    

    %% setup files
    if nargin < 6
        realignmentFirst = true;
    end
    if realignmentFirst
        % if secondProtocol
        %     fileIn = structIn.secondProtocol.rest(patInd);
        % else
        %     fileIn = structIn.rest(patInd);
        % end
        switch protNum
            case 0 %main protocol
                fileIn = structIn.rest(patInd);
            case 1
                fileIn = structIn.secondProtocol.rest(patInd);
            case 2
                fileIn = structIn.thirdProtocol.rest(patInd);
            case 3
                fileIn = structIn.fourthProtocol.rest(patInd);
            case 4
                fileIn = structIn.fifthProtocol.rest(patInd);
            case 5
                fileIn = structIn.sixthProtocol.rest(patInd);
        end
    end

    fileIn = char(fileIn);
    rawstring = 'Raw';
    newprepstring = 'Preprocessed/realigned';
    fileOut = strrep(fileIn, rawstring, newprepstring);
    
    % make directory if it does not exist
    if ~isfile(fileOut)
        outDirPath = stripFileName(fileOut);
        if ~isfolder(outDirPath)
            mkdir(outDirPath)
        end
    end

    %linux path versions
    fileInLin = ['/mnt/d' fileIn(3:end)];
    fileOutLin = ['/mnt/d' fileOut(3:end)];

    %% update reference volume based on the number of volumes to discard
    if discardVolumes ~= 0
        refvol = refvol+discardVolumes;
    end

    %%
    system(['bash -c ". ~/.profile && /home/neurodynamics/fsl/bin/mcflirt -in ' fileInLin ...
        ' -out ' fileOutLin ' -refvol ' num2str(refvol) ' -mats -sinc_final -cost leastsquares -plots"']);
    system(['bash -c "gzip -d -f ' fileOutLin '.gz"']); %unzip
    %% discard volumes
    if discardVolumes ~= 0
        discardFirstVolumes(fileOut, discardVolumes)
        updateMotionParameters([fileOut '.par'], discardVolumes);
        for i=1:discardVolumes %delete first matrices, MAT_xxxx
            numasstr = [repmat('0', [1, 4-length(num2str(i-1))]) num2str(i-1)];
            matpath = [fileOut '.mat\MAT_' numasstr];
            delete(matpath)
        end
        matpath = [fileOut '.mat'];
        listing = dir(matpath);
        for i =1:length(listing) %rename the matrices, MAT_xxxx -> MAT_(xxxx-discardVolumes)
            if listing(i).name(1) ~= '.' %avoid wildcard
                matpath = [fileOut '.mat\' listing(i).name];
                matnum = strfind(matpath, 'MAT_');
                matnum = str2double(matpath(matnum+length('MAT_'):end));
                newmatnum = matnum-discardVolumes;
                newmatnum = [repmat('0', [1, 4-length(num2str(newmatnum))]) num2str(newmatnum)];
                newmatpath = [fileOut '.mat\MAT_' newmatnum];
                movefile(matpath, newmatpath)
            end
        end
    else
        updateMotionParameters([fileOut '.par'])
    end
end