function [ind, nrOfOccurrences] = findTableIndex(siteName, tab)
    % Finds the row index of the site siteName in table tab
    % also gives the number of rows that contained the substring siteName
    rowNames = table2array(tab(:, 'Site'));
    whereifthere = strcmp(rowNames, siteName);
    summed = sum(whereifthere);
    if summed == 0
        error('"%s" is not a row in table', siteName);
    else
        ind = find(whereifthere); 
    end
    nrOfOccurrences = sum(contains(rowNames, siteName));
end