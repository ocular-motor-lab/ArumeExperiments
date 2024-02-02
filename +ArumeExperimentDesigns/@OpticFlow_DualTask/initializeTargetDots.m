function [dots,fctr,dotsorcircles,targetornot] = initializeTargetDots(dots,deltax,deltaz,exptparams, cam_pos, data)

    % pre-determine the set of x-z target locations, relative to the camera
    % position, such that when the target appears, it will (i) not appear
    % at the horizon, where it could be occluded, (ii) it does not appear
    % low in the screen, where it will disappear quickly, (iii) it does not
    % appear too close to the edges, where it will also disappear too
    % quickly. Given that the heading directions are actually relatively
    % small, we can draw a dense grid of dots,
    % translate by x and z, given by the condition, and just find which
    % ones fall out of the NDU plane. This would be super easy. We probably
    % wouldn't need the full 5000x5000 resolution either.. Just a, say,
    % 500x500 matrix of locations, pruned to remove out-of-bounds
    % coordinates, then we randomly sample a subset of these locations.
    % Also, we could do this on a per-trial basis where we set the onset
    % time of the targets, then look up the total x and z change, based on
    % the above settings. I'll do that!

    if data.targetpresent
        % begin by getting the total translation in x and z, from when the
        % targets might appear, to the end of the trial.

        % we can adjust the period during which we are guaranteed to have
        % the dots visible, and continuously moving (without disappearing).
        % This is when all coords are in the frame for a certain period of
        % time. We may want to have the dots disappear before the end,
        % because this means that the targets are more evenly spread
        % vertically, and may draw fixation downward. 
        proportioncontinuousmotion = .5; % Set to 1 if we want the dots to be alive the whole trial
        startidx = 1; endidx = round(length(deltaz)*proportioncontinuousmotion);

        totalzdisplacement = sum(deltaz(startidx:endidx));
        totalxdisplacement = sum(deltax(startidx:endidx));
    
        % then turn these into screen coords, and find all of them that stay
        % inside the NDU plane the entire time
    
        % first we add a small increment to the dots array so that our target
        % coordinates are never identical to the distractor coordinates
        zsamprate = (exptparams.fcp-exptparams.minzWorld)/exptparams.nptsZ;
        xsamprate = (exptparams.maxx*(exptparams.widthfactor*2))/exptparams.nptsX;
        candidatedots = dots;
        candidatedots(:,1) = candidatedots(:,1)+xsamprate/2;
        candidatedots(:,3) = candidatedots(:,3)+zsamprate/2;
    
        % then we project to the start and end camera position
        targetstrans_dots = candidatedots-cam_pos;
        targetsprojected_dots = targetstrans_dots*exptparams.projection;
        targetsprojected_dots = targetsprojected_dots ./ targetsprojected_dots(:, 4);
        targetscoordinbound = sum((targetsprojected_dots(:,1:3) > -1) & (targetsprojected_dots(:,1:3) < 1), 2);
        inboundsidxstart = targetscoordinbound == 3;
    
        targetstrans_dots = candidatedots - cam_pos - [totalxdisplacement,0,totalzdisplacement,0]; % add total offset at end
        targetsprojected_dots = targetstrans_dots*exptparams.projection;
        targetsprojected_dots = targetsprojected_dots ./ targetsprojected_dots(:, 4);
        targetscoordinbound = sum((targetsprojected_dots(:,1:3) > -1) & (targetsprojected_dots(:,1:3) < 1), 2);
        inboundsidxend = targetscoordinbound == 3;
    
        % indices of the dots that never disappear, with the added condition
        % that we don't want them too far away?
        inboundsidxall = find(inboundsidxend & inboundsidxstart & (dots(:,3) < exptparams.maxtargetzthreshold));
    
        % randomly sample n points from this grid
        targetidxs = inboundsidxall(randperm(length(inboundsidxall)));
        targetdots = candidatedots(targetidxs(1:exptparams.ntargets),:);
    
        % and sub them in
        dots(1:exptparams.ntargets,:) = targetdots;
    
        % while we are here, set up our lifetime variables
        fctr = randi(exptparams.dotlifetime*exptparams.fps, exptparams.num_dots, 1);
        fctr(1:exptparams.ntargets) = 0;
        
        % draw dots or draw circles
        dotsorcircles = rand(exptparams.num_dots, 1)>.5;
    
        % set up a vector which encodes which shapes are the targets
        % (initialized to zero because no targets are presented until a minimum
        % temporal delay
        targetornot = false(exptparams.num_dots,1);
        targetornot(1:exptparams.ntargets) = true;

    else

        % all distractors!
        fctr = randi(exptparams.dotlifetime*exptparams.fps, exptparams.num_dots, 1);
        fctr(1:exptparams.ntargets) = 0;
        
        % draw dots or draw circles
        dotsorcircles = rand(exptparams.num_dots, 1)>.5;
    
        % set up a vector which encodes which shapes are the targets
        % (initialized to zero because no targets are presented until a minimum
        % temporal delay
        targetornot = false(exptparams.num_dots,1);

    end

end