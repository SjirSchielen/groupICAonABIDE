function nestedLoopPrint(inputString, counter)
% This function prints the input string after the amounf of tabs specified
% by the counter.
    tabs = strjoin(repmat("\t", [1, counter]), "");
    fprintf(strjoin(["\n", tabs, inputString]));
end