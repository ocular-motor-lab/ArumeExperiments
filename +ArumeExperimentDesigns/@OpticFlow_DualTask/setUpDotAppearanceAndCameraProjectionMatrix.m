function exptparams = setUpDotAppearanceAndCameraProjectionMatrix(exptparams)

    exptparams.itemcol1 = uint8([1.0000    0.4118    0.1608] * 255);
    exptparams.itemcol2 = uint8([0.3922    0.8314    0.0745] * 255);
    exptparams.fixcol = [255, 255, 255];
    exptparams.hdotsz = round((exptparams.dotsz)/2);

    % area of circle versus square
    exptparams.dotarea = pi*(exptparams.hdotsz)^2;
    exptparams.hsquaresz = round(sqrt(exptparams.dotarea)/2);

    % how much additional space to have on the x-axis to account for
    % diagonal motion trajectories
    exptparams.widthfactor = 1.5;
    
    % Define camera parameters
    exptparams.ar = exptparams.wheight/exptparams.wwidth;
    exptparams.vfov = exptparams.hfov*exptparams.ar;

    % Set the max distance of the targets (so they aren't predominantly
    % hidden), and the max possibly frame-delay for the onset of the targets
    % (we do not want them to all appear at once). 
    exptparams.maxtargetzthreshold = min(75,exptparams.fcp); 
    exptparams.ntargets = 10;

    % dot coordinate grid resolution
    exptparams.nptsX = 500;
    exptparams.nptsZ = 500; 
    
    % set near and far clipping plane in meters. The near-clipping plane will
    % actually be constrained by the view frustum later on
    exptparams.ncp = 0.001;
    
    % standard perspective projection matrix
    exptparams.rhfov = deg2rad(exptparams.hfov / 2);
    exptparams.rvfov = deg2rad(exptparams.vfov / 2);
    exptparams.projection = [
        [1/tan(exptparams.rhfov), 0, 0, 0];
        [0, 1/tan(exptparams.rvfov), 0, 0];
        [0, 0, (-exptparams.ncp-exptparams.fcp)/(exptparams.ncp-exptparams.fcp), -1];
        [0, 0, (2*exptparams.fcp*exptparams.ncp)/(exptparams.ncp-exptparams.fcp), 0]
    ];
    
    % we will later convert our NDUs to pixels on the display
    exptparams.z_offset = [exptparams.wwidth/2, exptparams.wheight/2];
    
    % dot lifetime in frames.
    exptparams.ndotframes = round(exptparams.fps*exptparams.dotlifetime);
    
    % initialize our dots. treat z=depth distribution differently based on desired geometry
    exptparams.maxx = exptparams.fcp*tan(exptparams.rhfov);

    % if we are using the size cue, set up the distance-based scaling
    % factor
    if exptparams.dotsizecue
        exptparams.mindotszpx = 1;
        exptparams.dotscalfac = 1/exptparams.fcp;
    end

end