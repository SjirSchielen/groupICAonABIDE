function splits = splitFileArray(fileArray, shouldContain, shouldNotContain)
% This function takes an array of file paths as input and filters them
% based on whether the path contains 'shouldContain'.
% It returns an array of all paths that contain 'shouldContain'


    % check if fileArray is a string array
    if ~isa(fileArray, 'string')
        splits = fileArray;
        warning('Input was not of type string')
        return
    elseif length(fileArray) == 1
        splits = fileArray;
        warning('Input string array had a length of 1')
        return
    end
    

    splits = fileArray(contains(fileArray, shouldContain));
    if ~isempty(shouldNotContain)
        takeOut = splits(contains(splits, shouldNotContain));
        splits = splits(~contains(splits, shouldNotContain));
        % for i=1:length(takeOut)
        %     fprintf("\n%s", takeOut(i))
        % end
    end

    if isempty(splits)
        warning("No paths contain '%s'. Empty array is returned.", shouldContain)
        splits = [];
    end
end