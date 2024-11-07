function unzipFiles(filesIn)
% takes an array of paths or single path and un gunzips the files there
% it does not delete the gunzipped version

if isa(filesIn, 'char')
    filesIn = string(filesIn);
end

for i = 1:length(filesIn)
    if contains(filesIn(i), '.gz')
        unzippedName = char(filesIn(i));
        unzippedName = unzippedName(1:strfind(unzippedName, '.gz')-1);
        if ~isfile(unzippedName)
            gunzip(filesIn(i))
        end
    end
end


end