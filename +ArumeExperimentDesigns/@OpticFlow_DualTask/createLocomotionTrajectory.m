function this = createLocomotionTrajectory(thisTrialData,this)

    % walking = 1.31, jogging = 3.25, running = 5.76, driving = 13.41
    zinc = thisTrialData.speedCondition/this.camera.fps; % gives the delta-z per frame
    this.camera.deltaz = repmat(zinc,this.camera.fps*this.ExperimentOptions.TrialDuration,1);

    % the target angle is specified, per trial, in degrees
    ang = deg2rad(thisTrialData.headingchange);

    % tangent is opposite/adjacent = ang, which we rearrange to opposite = adjacent*theta
    xinc = tan(ang)*zinc;

    % first specify the interval where we are just travelling straight
    xstraight = zeros(round(this.camera.fps*thisTrialData.headingchangeonsettime),1);

    if strcmp(exptparams.Smoothing,'Gaussian')
        % gaussian ramp
        n = (this.camera.fps*thisTrialData.headingchangeDuration);
        mu = n/2;
        sigma = n/7;
        xcurve = (normcdf(1:n,mu,sigma).*xinc)';
    elseif strcmp(exptparams.Smoothing,'Linear')
        % linear x-velocity ramp
        xcurve = linspace(0,xinc,this.camera.fps*this.ExperimentOptions.headingchangeDuration)';
    elseif  strcmp(exptparams.Smoothing,'None')
        % sudden jump in x velocity
        xcurve = [zeros(this.camera.fps*this.ExperimentOptions.headingchangeDuration/2,1); ...
            repmat(xinc,this.camera.fps*this.ExperimentOptions.headingchangeDuration/2,1)];
    else
        error('Unknown Smoothing Type')
    end

    % then the final straight-ahead direction
    xstraight2 = repmat(xinc,round(this.camera.fps*(this.ExperimentOptions.trialduration-thisTrialData.headingchangeonsettime-thisTrialData.headingchangeDuration)),1);
    this.camera.deltax = [xstraight;xcurve;xstraight2];

end