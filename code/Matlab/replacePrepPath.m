function strout = replacePrepPath(strin, toReplaceWith)
% This function takes the path strin as input and replaces the
% preprocessing step in the path with toReplaceWith. If no preprocessing
% step is in the input string, it returns the input string.

    strout = strin; %#ok<*NASGU>
    preprocessedFolder = strin(1:strfind(strin, 'Preprocessed') + length('Preprocessed') - 1); %-1 for last slash
    if isa(toReplaceWith, 'string'), toReplaceWith = char(toReplaceWith); end
    if isa(preprocessedFolder, 'string'), preprocessedFolder = char(preprocessedFolder); end
    
    
    listPrepDir = dir(preprocessedFolder);
    prepSteps = strings(1, length(listPrepDir));
    for i = 1:length(listPrepDir)
        % no wildcards
        if ~(strcmp(listPrepDir(i).name, ".") | strcmp(listPrepDir(i).name, "..")), prepSteps(i) = listPrepDir(i).name; end
    end
    prepSteps = prepSteps(prepSteps ~= ""); %remove empty strings because of wildcards
    
    for i=1:length(prepSteps)
        if contains(fileparts(strin), prepSteps(i))
            [d, f, e] = fileparts(strin);
            strout = char(strrep(d, prepSteps(i), toReplaceWith));
            strout = [strout filesep f e]; %#ok<AGROW>
            break
        end
    end

    if strcmp(strout, strin), fprintf("Warning: No preprocessing step found in input string, the input string is returned."); end

end