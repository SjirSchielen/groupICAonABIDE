function pathOut = stripFileName(pathIn)
    % This function strips the filename (with extension) from the path. If
    % there is no . indicating an extension, it is assumed that the part
    % after the last / indicates a folder

    if isa(pathIn, 'string') %convert to char (may be unnecessary)
        pathIn = char(pathIn);
    end
    
    if ~contains(pathIn, '.') %assume last section is also a folder
        pathOut = pathIn;
    else
        if contains(pathIn, '/')
            delimiter = '/';
        elseif contains(pathIn, '\')
            delimiter = '\';
        end
        slashInds = strfind(pathIn, delimiter);
        pathOut = extractBefore(pathIn, slashInds(end));
    end
    
end