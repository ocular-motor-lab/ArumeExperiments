function [exptparams, dots, valididxs,xWorldFlatten,zWorldFlatten] = initializeDotPlacement(data,exptparams, cam_pos)

    % render dot locations based on 2d or 3d uniformity condition
    if data.densityCondition
    
        % the current approach is to define a grid of equally spaced points in the image-plane, then project
        % to 3D space and get the x and z values (knowing the y value to be fixed based on eye-height).
        % then we can simply sample this grid uniformly.
        % first find z-world coordinates based on y-coordinate
        % yScreenfcp = 1/tan(rvfov)/-exptparams.fcp;
        % 
        % nptsX = 1000;
        % nptsY = round(nptsX*exptparams.ar/2);
        % yScreen = linspace(-1, yScreenfcp, nptsY)';
        % yScreen = repmat(yScreen, 1,nptsX);
        % zWorld = -exptparams.observerheight*(1/tan(rvfov))./yScreen;
        % 
        % % now we find the x-coordinate
        % xScreen = linspace(-1,1,nptsX);
        % xScreen = repmat(xScreen, nptsY,1);
        % xWorld = (xScreen.*-zWorld)./(1/tan(rhfov));
        % 
        % % now set it up so that we randomly sample from this distribution
        % xWorldFlatten = reshape(xWorld,1,[]);
        % zWorldFlatten = reshape(zWorld,1,[]);
        % 
        % sampleidxs = randi(nptsX*nptsY, 1, exptparams.num_dots);
        % dotx = xWorldFlatten(sampleidxs) + cam_pos(1);
        % dotz = zWorldFlatten(sampleidxs) + cam_pos(3);
    
    else
    
        % define a linearly spaced grid of points in x-y space and identify all points that fall outside clipping plane
        exptparams.minzWorld = 1/tan(exptparams.rvfov)*exptparams.observerheight;
        
        zWorld = repmat(linspace(exptparams.minzWorld, exptparams.fcp, exptparams.nptsZ)', 1, exptparams.nptsX);

        % note, if maxx is multiplied by a scalar, the number of dots WILL
        % differ from the specified number above. It's just that it would
        % be pretty complicated to figure out just how many we would need, and how
        % widely distributed in X, when we are co-varying locomotion
        xWorld = repmat(linspace(-exptparams.maxx*exptparams.widthfactor,exptparams.maxx*exptparams.widthfactor,exptparams.nptsX),exptparams.nptsZ,1); 
        yWorld = repmat(-exptparams.observerheight,exptparams.nptsZ,exptparams.nptsX);
        
        xScreen = xWorld .* 1/tan(exptparams.rhfov)./-zWorld;
        yScreen = yWorld .* 1/tan(exptparams.rvfov)./-zWorld;
        
        outofbounds = ones(size(xScreen)); % ((xScreen > -1) & (xScreen < 1)) & ((yScreen > -1) & (yScreen < 1));
        
        % now get indices
        xWorldFlatten = reshape(xWorld,1,[]);
        zWorldFlatten = reshape(zWorld,1,[]);
        
        valididxs = find(reshape(outofbounds,1,[]));
        sampleidxs = randi(numel(valididxs), 1, exptparams.num_dots);
        
        dotx = xWorldFlatten(valididxs(sampleidxs)) + cam_pos(1);
        dotz = zWorldFlatten(valididxs(sampleidxs)) + cam_pos(3);
    
    end
    
    doty = zeros(size(dotx));
    dots = [dotx',doty',dotz',ones(size(doty))'];

end