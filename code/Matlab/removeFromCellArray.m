%Function that removes an indexed value specified by removeind from cell
%array cells

function newcells = removeFromCellArray(cells, removeind)
    if removeind == 1
        newcells = cells(2:end);
    elseif removeind == length(cells)
        newcells = cells(1:end-1);
    else
        newcells = [cells(1:removeind-1) cells(removeind+1:end)];
    end
end
