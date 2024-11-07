function stripped = stripdirs(path)
% strips ghost directories from directories at path
indir = dir(path);
dirs = {indir.name};
inds = zeros(1, length(dirs));
for i=1:length(dirs)
    if strcmp(dirs{i}, ".") || strcmp(dirs{i}, "..")
        inds(i) = 1;
    end
end
stripped = dirs(~inds);
stripped = convertCharsToStrings(stripped);
end

