function outStruct = initializeSiteStruct(inStruct, siteName, rest_files, anat_files, csvFiles, ABIDE_version)
    outStruct = inStruct; 
    if strcmp(ABIDE_version, "ABIDE_I")
        shouldNotContain = "ABIDE_II";
        outStruct.ABIDE_version = 1;
    end

    if strcmp(ABIDE_version, "ABIDE_II")
        shouldNotContain = "ABIDE_I/";
        outStruct.ABIDE_version = 2;
    end

    outStruct.siteName = siteName;
    outStruct.rest = splitFileArray(rest_files, siteName, shouldNotContain);
    outStruct.anat = splitFileArray(anat_files, siteName, shouldNotContain);
    outStruct.csv = splitFileArray(csvFiles, siteName, shouldNotContain);
    outStruct.IDs = IDfromPath(outStruct.rest);
    outStruct.nrOfParticipants = length(outStruct.rest);
end