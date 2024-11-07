function id = IDfromPath(inputPath)
% This function takes a path or array of paths as input and respectively
% yields the id in the path or ids in the paths. 
    
    % assume string inputs
    if isa(inputPath, "char")
        warning("Input is of type char, while string is expected." + ...
            "\nInput is parsed to string.")
        inputPath = string(inputPath);
    end

    
    if isa(inputPath, "string")
        if length(inputPath) == 1 %single string as input
            id = singleCase(inputPath);
        else %array of strings as input
            %check the type of slashes used to indicate folders
            forwardSlashes = contains(inputPath, '/');
            backwardSlashes = contains(inputPath, '\');
            finds = forwardSlashes;
            binds = backwardSlashes;
            if sum(forwardSlashes) + sum(backwardSlashes) ~= length(inputPath)
                % at least one string does not meet requirements
                error("One of the input strings is not a valid path.")
            end
            % vectorial implementation of the single-input case
            id = zeros(1, length(inputPath));
            if sum(forwardSlashes) ~= 0
                forwardSlashes = inputPath(forwardSlashes);
                dirs = split(forwardSlashes, "/");
                doublestring = str2double(dirs);
                notnans = ~isnan(doublestring);
                idsf = doublestring(notnans);
                id(finds) = idsf;
            end
            if sum(backwardSlashes) ~= 0
                backwardSlashes = inputPath(backwardSlashes);
                dirs = split(backwardSlashes, "\");
                doublestring = str2double(dirs);
                notnans = ~isnan(doublestring);
                idsb = doublestring(notnans);
                id(binds) = idsb;
            end
            
            
        end
    end




    
end

function id = singleCase(inputPath)
    %single case 
    if contains(inputPath, '/')
        dirs = split(inputPath, '/');
    elseif contains(inputPath, '\')
        dirs = split(inputPath, '\');
    else
        error("Specified string is not a valid path:\n%s", inputPath)
    end
    
    doublestring = str2double(dirs);
    notnans = ~isnan(doublestring);
    summed = sum(notnans);
    if summed == 1
        id = doublestring(notnans);
    elseif summed > 1
        error("More than one number found in string.")
    elseif summed == 0
        error("No parts containing only numbers found.")
    end
end