function discardFirstVolumes(imPath, nrOfVolumesToDiscard)
% This function opens the nifti saved at imPath and discards the first
% nrOfVolumesToDiscard volumes from the nifti. The header is then updated
% and the new nifti replaces the old one. 
    info = niftiinfo(imPath);
    volumes = niftiread(info);
    sz = size(volumes);
    timeIndex = find(info.ImageSize(end) == sz);
    if timeIndex == 4
        newVolumes = volumes(:,:,:,1+nrOfVolumesToDiscard:end);
        info.ImageSize(4) = info.ImageSize(4)-nrOfVolumesToDiscard;
    elseif timeIndex == 1
        newVolumes = volumes(1+nrOfVolumesToDiscard:end, :, :, :);
        info.ImageSize(1) = info.ImageSize(1)-nrOfVolumesToDiscard;
    end
    niftiwrite(newVolumes, imPath, info)
end

