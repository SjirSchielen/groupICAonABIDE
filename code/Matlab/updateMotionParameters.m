function updateMotionParameters(parpath, nrOfVolumesToDiscard)
% This function opens the .par file saved at imPath and discards the first
% nrOfVolumesToDiscard*6 parameters from the file. It then saves the file 
% as a .txt file because it is easier to work with. It then deletes the old
% file to avoid reading the version that 
    if nargin == 1
        nrOfVolumesToDiscard = 0;
        if ~(isa(parpath, 'string') || isa(parpath, 'char'))
            error("Please provide a path of either string of char type")
        end
    end
    transparams = load(parpath);
    transparams = transparams(1+nrOfVolumesToDiscard:end, :);
    txtpath = [parpath '.txt'];
    writematrix(transparams, txtpath)
    % delete(parpath)
end
