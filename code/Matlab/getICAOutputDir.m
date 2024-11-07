function outputDir = getICAOutputDir(out_dir)

    outputDir = [out_dir 'run'];
    i = 1;
    while isfolder([outputDir, num2str(i)])
        i = i + 1;
    end
    outputDir = [outputDir, num2str(i)];
    mkdir(outputDir)

end