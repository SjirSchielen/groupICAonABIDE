function whitelisted = swhitelist(root, dirs)

    %Returns the whitelisted directories based on information in the root
    %path and the whitelisted sites in the function whitelisted_sites
    [swhitelist1, swhitelist2] = whitelisted_sites();

    A1 = contains(root, "ABIDE_I") && ~contains(root, "ABIDE_II");
    A2 = contains(root, "ABIDE_II");

    if A1 && ~A2 %ABIDE_I whitelist
        if contains(root, swhitelist1) %already whitelisted
            whitelisted = dirs;
        else %only include the whitelisted directories
            whitelisted = dirs(contains(dirs, swhitelist1));
        end
    elseif A2 && ~A1 %ABIDE_II whitelist
        if contains(root, swhitelist2) 
            whitelisted = dirs;
        else
            whitelisted = dirs(contains(dirs, swhitelist2));
        end
    elseif A1 && A2
        %should not be possible
        warning("Both 'ABIDE_I' and 'ABIDE_II' in path")
    else %both zero
        % directories occur before whilelist is necessary
        whitelisted = dirs;
    end

    if any(contains(whitelisted, "dti"))
        whitelisted = whitelisted(~contains(whitelisted, "dti"));
    end
    
end