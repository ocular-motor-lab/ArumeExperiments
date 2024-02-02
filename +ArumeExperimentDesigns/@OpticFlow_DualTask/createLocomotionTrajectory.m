function [deltax,deltaz] = createLocomotionTrajectory(data,exptparams)

    % walking = 1.31, jogging = 3.25, running = 5.76, driving = 13.41
    zinc = data.speedCondition/exptparams.fps; % gives the delta-z per frame
    deltaz = repmat(zinc,exptparams.fps*exptparams.trialduration,1);

    % the target angle is specified, per trial, in degrees
    ang = deg2rad(data.headingchange);

    % tangent is opposite/adjacent = ang, which we rearrange to opposite = adjacent*theta
    xinc = tan(ang)*zinc;

    % first specify the interval where we are just travelling straight
    xstraight = zeros(round(exptparams.fps*data.headingchangeonsettime),1);

    if strcmp(exptparams.Smoothing,'Gaussian')
        % gaussian ramp
        n = (exptparams.fps*exptparams.headingchangeDuration);
        mu = n/2;
        sigma = n/7;
        xcurve = (normcdf(1:n,mu,sigma).*xinc)';
    elseif strcmp(exptparams.Smoothing,'Linear')
        % linear x-velocity ramp
        xcurve = linspace(0,xinc,exptparams.fps*exptparams.headingchangeDuration)';
    elseif  strcmp(exptparams.Smoothing,'None')
        % sudden jump in x velocity
        xcurve = [zeros(exptparams.fps*exptparams.headingchangeDuration/2,1); ...
            repmat(xinc,exptparams.fps*exptparams.headingchangeDuration/2,1)];
    else
        error('Unknown Smoothing Type')
    end

    % then the final straight-ahead direction
    xstraight2 = repmat(xinc,round(exptparams.fps*(exptparams.trialduration-data.headingchangeonsettime-exptparams.headingchangeDuration)),1);
    deltax = [xstraight;xcurve;xstraight2];

end