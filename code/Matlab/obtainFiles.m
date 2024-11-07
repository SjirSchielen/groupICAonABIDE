function patharray = obtainFiles(root, discard_files, verbose)
% Returns a string array containing all files with the right extension in
% whitelisted directories. It iterates over all whitelisted directories
% that succeed from root.
% Inputs: 
% - root: string of the path to be considered the root
% - discard_files: array of strings that define the extensions that should
% be discarded, e.g.: discard_files = [".tar", ".tgz", ".txt", ".docx", ".zip", ".pdf", ".gz"]
% - verbose: boolean, if true it prints the input root of this function on each recursion.

    if verbose
        fprintf(root); 
        fprintf("\n");
    end
    discard_dirs = "CMU_b"; % site that should be excluded (no TR of 2000 ms)
    patharray = [];
    filesindir = stripdirs(root);
    if isempty(discard_files)
        discard_files = [".tar", ".tgz", ".txt", ".docx", ".zip", ".pdf", ".gz"]; %here we assume they are ungzipped
    end
    checks = zeros(1, length(filesindir));
    for i = 1:length(filesindir) %check for folders
        checks(i) = i*isfolder(strcat(root, filesindir(i)));
    end
    dirs = filesindir(checks ~= 0); %directories
    files = filesindir(checks == 0); %files

    if ~isempty(files)
        for i = 1:length(discard_files)
            idx = strfind(files, discard_files(i));
            if ~isa(idx, 'cell')
                idx = {idx};
            end
            for j = length(idx):-1:1
                if ~isempty(idx{j})
                    files = removeFromCellArray(files, j);
                end
            end
        end
        patharray = strcat(root, files);
    end
    
    dirs = swhitelist(root, dirs);

    for i = 1:length(discard_dirs)
        dirs = dirs(~contains(dirs, discard_dirs(i)));
    end

    for i = 1:length(dirs)
        if dirs{i}(end) ~= '/' 
           dirs{i} = strcat(dirs{i}, '/'); 
        end
        newpath = strcat(root, dirs{i});
        patharray = horzcat(patharray, obtainFiles(newpath, discard_files, verbose));
    end
    
end