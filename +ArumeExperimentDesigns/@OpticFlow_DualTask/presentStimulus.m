function [this,thisTrialData, exitedEarly] = presentStimulus(this,thisTrialData)

    exitedEarly = false;

    % add a half-second trial buffer
    this.Graph.Flip(this, thisTrialData)
    WaitSecs(.5)

    % add a response prompt
    switch thisTrialData.Task
        case 'Visual Search'
            msg = sprintf( 'Search for the %s',thisTrialData.SearchTarget);
            DrawFormattedText(this.Graph.window, msg, 'center', 'center', [255,255,255])

        case 'Heading'
            msg = 'Estimate the heading';
            DrawFormattedText(this.Graph.window, msg, 'center', 'center', [255,255,255])
            
        case 'Both'
            msg = sprintf( 'Search for the %s, and estimate the heading',thisTrialData.SearchTarget);
            DrawFormattedText(this.Graph.window, msg, 'center', 'center', [255,255,255])
    end
    this.Graph.Flip(this, thisTrialData)
    WaitSecs(2)

    % show fixation until any button press
    Screen('FillRect', this.Graph.window, this.camera.fixcol, this.uicomponents.fixrects)
    this.Graph.Flip(this, thisTrialData)

    % check for response
    keyIsDown = false;
    while ~keyIsDown

        [keyIsDown, ~, keyCode, ~] = KbCheck();
        keys = find(keyCode);

        for i=1:length(keys)
            KbName(keys(i));

            switch(KbName(keys(i)))
                case 'ESCAPE'
                    exitedEarly = true;
                    return

                case 'c'
                    if this.ExperimentOptions.UseEyeTracker
                        EyelinkDoDriftCorrection(this.el);
                    end

            end
        end
    end

    % check what shape of stimulus, and what color, the targets and
    % distractors should be... 
    switch thisTrialData.SearchTarget
        case 'red squares'
            distractorsquarecol = this.camera.itemcol2;
            distractorcirclecol = this.camera.itemcol1;
            targetcol = this.camera.itemcol1;
            targetszpx = this.camera.hsquaresz;
            targetdrawtype = 'FillRect';

        case 'green squares'
            distractorsquarecol = this.camera.itemcol1;
            distractorcirclecol = this.camera.itemcol2;
            targetcol = this.camera.itemcol2;
            targetszpx = this.camera.hsquaresz;
            targetdrawtype = 'FillRect';

        case 'red circles'
            distractorsquarecol = this.camera.itemcol1;
            distractorcirclecol = this.camera.itemcol2;
            targetcol = this.camera.itemcol1;
            targetszpx = this.camera.hdotsz;
            targetdrawtype = 'FillOval';

        case 'green circles'
            distractorsquarecol = this.camera.itemcol2;
            distractorcirclecol = this.camera.itemcol1;
            targetcol = this.camera.itemcol2;
            targetszpx = this.camera.hdotsz;
            targetdrawtype = 'FillOval';
    end

    % set up the size ratio. Squares will be scaled down relatively
    shapesz = zeros(size(this.shapes.currentWorldCoords));
    shapesz(this.shapes.shapetype) = 2/sqrt(pi);
    shapesz(~this.shapes.shapetype) = 1;

    % start recording
    if this.ExperimentOptions.UseEyeTracker
        trialmsg = sprintf('Trial %i',i);
        Eyelink('Message',trialmsg)
        Eyelink('StartRecording');
    end

    % now we prepare for looping over the frames for a single trial
    nframesctr = 1;
    

    while (nframesctr <= this.camera.ntrialframes) 

        % check eyelink still connected
        if this.ExperimentOptions.UseEyeTracker
            error=Eyelink('CheckRecording');
            if(error~=0)
                break;
            end
        end
    
        % check if any dots have reached their lifetime
        ltidxs = this.shapes.lifetime > this.camera.ndotframes;
    
        % create new dot locations for these replacement locations
        nreplace = sum(ltidxs);
    
        switch thisTrialData.Density 
            case 'Uniform'
                error('Uniform Condition not set up')
            case 'NonUniform'
                % sample from all world locations
                sampleidxs = randi(this.shapes.nValidLocations, 1, nreplace);
                shapex = this.shapes.allValidWorldCoords(sampleidxs,1) + this.camera.pos(1);
                shapey = zeros(nreplace,1);
                shapez = this.shapes.allValidWorldCoords(sampleidxs,3) + this.camera.pos(3);
                shapea = ones(nreplace,1);
        end        

        replaceshapes = [shapex,shapey,shapez,shapea];
    
        % now we do the actual replacement
        this.shapes.currentWorldCoords(ltidxs,:) = replaceshapes;
    
        % and finally update the dot lifetime counters (breath life into
        % expired dots)
        this.shapes.lifetime(ltidxs) = -1; 

        % keep the dot/circle assignment random. we reinitialize when they
        % reach the end of their lifetime.
        this.shapes.shapetype(ltidxs) = rand(nreplace,1)>.5;
    
        % translate the camera forward and to the side by a small
        % predetermined x and z increment
        transshapes = this.shapes.currentWorldCoords-this.camera.pos;
        
        this.camera.pos(1) = this.camera.pos(1)+this.camera.deltax(nframesctr);
        this.camera.pos(3) = this.camera.pos(3)+this.camera.deltaz(nframesctr);
    
        % project dots and do z-divide
        projectedshapes = transshapes*this.camera.projection;
        projectedshapes = projectedshapes ./ projectedshapes(:, 4);
    
        % apply clipping (yz values should be within NDU coords).. We do
        % not care about x-coords, for the reason given above
        coordinbound = sum((projectedshapes(:,2:3) > -1) & (projectedshapes(:,2:3) < 1), 2);
        
        % If any coordinate falls outta bounds, redraw it at a new location on the next iteration
        outboundsidx = coordinbound < 2;
        this.shapes.lifetime(outboundsidx) = this.camera.ndotframes; % on next iteration, this will be replaced
        
        % only draw inbounds dots
        inboundsidx = find(coordinbound == 2);
        projectedshapesscreen = projectedshapes(inboundsidx,1:2) .* this.camera.z_offset +  this.camera.z_offset; % NDU to screen coords        
    
        % reformat this for PTB and draw
        circleidxs = this.shapes.shapetype(inboundsidx) & ~this.shapes.targetornot(inboundsidx);
        squareidxs = ~this.shapes.shapetype(inboundsidx) & ~this.shapes.targetornot(inboundsidx);
        targetidxs = this.shapes.targetornot(inboundsidx);
        
        if this.ExperimentOptions.DotSizeCue
            
            % sizes will vary based on z-distance AND the shape (with a
            % min rendering size of 1 pixel).
            szs =  ((1./(transshapes(inboundsidx,3) .* this.camera.dotscalfac)) .* this.camera.mindotszpx .* shapesz(inboundsidx))';

            circlerects = [projectedshapesscreen(circleidxs,:)'-szs(circleidxs);...
                projectedshapesscreen(circleidxs,:)'+szs(circleidxs)];
    
            squarerects = [projectedshapesscreen(squareidxs,:)'-szs(squareidxs);...
                projectedshapesscreen(squareidxs,:)'+szs(squareidxs)];
            
            targetrects = [projectedshapesscreen(targetidxs,:)'-szs(targetidxs);...
                projectedshapesscreen(targetidxs,:)'+szs(targetidxs)];


        else
            circlerects = [projectedshapesscreen(circleidxs,:)'-this.camera.hdotsz;...
                projectedshapesscreen(circleidxs,:)'+this.camera.hdotsz];
    
            squarerects = [projectedshapesscreen(squareidxs,:)'-this.camera.hsquaresz;...
                projectedshapesscreen(squareidxs,:)'+this.camera.hsquaresz];
            
            targetrects = [projectedshapesscreen(targetidxs,:)'-targetszpx;...
                projectedshapesscreen(targetidxs,:)'+targetszpx];
        end

        % distractor 1: RED/GREEN CIRCLES
        Screen('FillOval', this.Graph.window, distractorcirclecol, circlerects)

        % distractor 2: RED/GREEN SQUARES
        Screen('FillRect', this.Graph.window, distractorsquarecol, squarerects)

        % Target: RED/GREEN CIRCLES/SQUARES. Determined at start of loop.
        % this can be an empty array / do nothing, if the condition
        % specifies there is no target
        if thisTrialData.TargetPresent
            Screen(targetdrawtype, this.Graph.window, targetcol, targetrects)
        end

        this.Graph.Flip(this, thisTrialData)
        
        % increment dot lifetime
        this.shapes.lifetime = this.shapes.lifetime + 1;
        nframesctr = nframesctr + 1;

        % close experiment if requested
        % check for response
        [keyIsDown, ~, keyCode, ~] = KbCheck();
        if keyIsDown
            keys = find(keyCode);
            for i=1:length(keys)
                KbName(keys(i));
                switch(KbName(keys(i)))
                    case 'ESCAPE'
                        exitedEarly = true;
                        return
                end
            end
        end
    end

     % stop recording at end of trial
    if this.ExperimentOptions.UseEyeTracker
        Eyelink('StopRecording');
    end

end