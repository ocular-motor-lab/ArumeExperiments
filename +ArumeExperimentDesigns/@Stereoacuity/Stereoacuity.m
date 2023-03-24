classdef Stereoacuity < ArumeExperimentDesigns.EyeTracking
    % DEMO experiment for Arume
    %
    %   1. Copy paste the folder @Demo within +ArumeExperimentDesigns.
    %   2. Rename the folder with the name of the new experiment but keep that @ at the begining!
    %   3. Rename also the file inside to match the name of the folder (without the @ this time).
    %   4. Then change the name of the class inside the folder.
    %
    properties
        stimTextureLeft = [];
        stimTextureRight = [];
        targetColor = [255 0 0];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            %% ADD new options
            dlg.InitDisparity = { 6 '* (arcmins)' [0 100] };
            dlg.InitStepSize = { 6 '* (arcmins)' [0 100] };
            dlg.Number_of_Dots = { 3000 '* (deg/s)' [10 10000] };
            dlg.Size_of_Dots = { 4 '* (pix)' [1 100] };
            dlg.visibleWindow_cm = {16 '* (cm)' [1 100] };
            dlg.FixationSpotSize = { 0.4 '* (diameter_in_deg)' [0 5] };
            dlg.RotateDots = { 0 '* (yes/no)' [0 1] }; % where 1 means to tilt the stim, and 0 means no tilt
            dlg.RotateDotsByThisMuch = { 10 '* (deg)' [0 90] }; 
            dlg.TimeStimOn = { 2 '* (sec)' [0 60] }; 
            
            dlg.NumberOfRepetitions = {100 '* (N)' [1 100] }; % 100 bc 100 * 2 (sign disparities) = 200 total trials (100 for front, 100 for back)
            dlg.BackgroundBrightness = 0;
            
            %% CHANGE DEFAULTS values for existing options
            
            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult Speed Stimulus'; % which variables to display every trial in the command line separated by spaces
            
            dlg.DisplayOptions.ScreenWidth = { 59.5 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 34 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 54 '* (cm)' [1 3000] };
            dlg.DisplayOptions.StereoMode = { 4 '* (mode)' [0 9] }; 
            dlg.DisplayOptions.SelectedScreen = { 1 '* (screen)' [0 5] };
            
            dlg.HitKeyBeforeTrial = 1;
            dlg.TrialDuration = 90;
            dlg.TrialsBeforeBreak = 200;
            dlg.TrialAbortAction = 'Repeat';
        end
        
        function trialTable = SetUpTrialTable(this)
            
            %-- condition variables ---------------------------------------
            i= 0;
             
            i = i+1;
            conditionVars(i).name   = 'SignDisparity';
            conditionVars(i).values = [-1 1]; 
            
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Repeat'; % Repeat, Delay, Drop
            trialTableOptions.trialsPerSession = 1000;
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end
        
        
        function [trialResult, thisTrialData] = runPreTrial( this, thisTrialData )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
            
            if thisTrialData.TrialNumber == 1
                  thisTrialData.DisparityArcMin = this.ExperimentOptions.InitDisparity *  thisTrialData.SignDisparity; % first trial's disparity will be the initial disparity
                            
                
            elseif thisTrialData.TrialNumber > 1
                
                switch (true)
                    
                    case thisTrialData.SignDisparity == 1 & ~isempty(find(this.Session.currentRun.pastTrialTable.SignDisparity == 1)) == 0 % if the disparity is positive and positive disparities have NOT happened before
                        thisTrialData.DisparityArcMin = this.ExperimentOptions.InitDisparity * thisTrialData.SignDisparity; % first disparity of this staircase will be the initial disparity
                        thisStaircaseExists = 0;
                        
                    case thisTrialData.SignDisparity == -1 & ~isempty(find(this.Session.currentRun.pastTrialTable.SignDisparity == -1)) == 0 % if the disparity is neg and neg disparities have NOT happened before
                        thisTrialData.DisparityArcMin = this.ExperimentOptions.InitDisparity * thisTrialData.SignDisparity;
                        thisStaircaseExists = 0;
                        
                    case thisTrialData.SignDisparity == 1 & ~isempty(find(this.Session.currentRun.pastTrialTable.SignDisparity == 1)) == 1 % if the disparity is pos and pos disparities HAVE happened before
                        % Get the last trial's disparity (in abs) ~for a staircase~ and calculate how
                        % many reversals have occured ~for that staircase~
                        thisidx = find(this.Session.currentRun.pastTrialTable.SignDisparity == 1,1,'last');
                        numReversals = sum(this.Session.currentRun.pastTrialTable.IsReversal((this.Session.currentRun.pastTrialTable.SignDisparity == 1)));
                        thisStaircaseExists = 1;
                        
                    case thisTrialData.SignDisparity == -1 & ~isempty(find(this.Session.currentRun.pastTrialTable.SignDisparity == -1)) == 1 % if the disparity is neg and neg disparities HAVE happened before
                        thisidx = find(this.Session.currentRun.pastTrialTable.SignDisparity == -1,1,'last');
                        numReversals = sum(this.Session.currentRun.pastTrialTable.IsReversal((this.Session.currentRun.pastTrialTable.SignDisparity == -1)));
                        thisStaircaseExists = 1;
                end

                if (~isempty(this.Session.currentRun.pastTrialTable.IsReversal))
                    if (thisStaircaseExists)
                        %numReversals = max(numReversals-2,0); % ignore the first two reversals since it may be likely that they hit a wrong key early on
                        % What the disparity will be on this trial, given the response on the last trial
                        lastAbsoluteTrialDisparity = abs(this.Session.currentRun.pastTrialTable.DisparityArcMin(thisidx));
                        lastTrialGuessedCorrectly = this.Session.currentRun.pastTrialTable.GuessedCorrectly(thisidx);
                        absoluteDisparityArcMin = lastAbsoluteTrialDisparity - (this.ExperimentOptions.InitStepSize / (numReversals+1)) * (lastTrialGuessedCorrectly - 0.75); % from Faes 2007, https://link.springer.com/article/10.3758/BF03193747
                        thisTrialData.DisparityArcMin = absoluteDisparityArcMin *  thisTrialData.SignDisparity;

                        if thisTrialData.DisparityArcMin == 0
                            thisTrialData.DisparityArcMin = 0.001 *  thisTrialData.SignDisparity;
                        end
                        
                        if thisTrialData.DisparityArcMin > 0 & thisTrialData.SignDisparity == -1 % if you went below/above zero when you weren't supposed to
                                thisTrialData.DisparityArcMin = 0.001 *  thisTrialData.SignDisparity;
                        elseif thisTrialData.DisparityArcMin < 0 & thisTrialData.SignDisparity == 1 % if you went below/above zero when you weren't supposed to
                                thisTrialData.DisparityArcMin = 0.001 *  thisTrialData.SignDisparity;
                        end
                        
                    end
                else
                    disp('past trial table doesnt exist:(')
                end
            end
            
        end
        
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            try
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;
                
                Screen('FillRect', graph.window, 0); % not sure if needed
                
                % Screen width and height of one of the two eye displays in pixels
                screenWidth = this.Graph.wRect(3);
                screenHeight = this.Graph.wRect(4);
                
                % Settings
                moniterWidth_cm =  this.ExperimentOptions.DisplayOptions.ScreenWidth;
                viewingDist = this.ExperimentOptions.DisplayOptions.ScreenDistance;
                moniterWidth_deg = (atan2d(moniterWidth_cm/2, viewingDist)) * 2;
                pixPerDeg = (screenWidth*2) / moniterWidth_deg;
                
                % Stimulus settings:
                numDots = this.ExperimentOptions.Number_of_Dots;
                dots = zeros(3, numDots);
                
                % How big should the window (entire dots stimulus) be in pix?
                visibleWindow_cm = this.ExperimentOptions.visibleWindow_cm; % in cm, this is how much of the screen you can see w one eye at a viewingDist of 20 (from haploscope calcs!)
                visibleWindow_pix = ((screenWidth*2) / moniterWidth_cm) * visibleWindow_cm;
                xmax = visibleWindow_pix / 2;
                ymax = xmax;
                
                % Disparity settings:
                disparity_deg = thisTrialData.DisparityArcMin/60;
                shiftNeeded_deg = viewingDist * tand(disparity_deg);
                shiftNeeded_pix = pixPerDeg * shiftNeeded_deg;
                dots(1, :) = 2*(xmax)*rand(1, numDots) - xmax; % SR x coords
                dots(2, :) = 2*(ymax)*rand(1, numDots) - ymax; % SR y coords
                
                % Get fixation spot size in pix
                fixSizePix = pixPerDeg * this.ExperimentOptions.FixationSpotSize;
                
                % Make the window (entire dot stimulus) circular :D 
                distFromCenter = sqrt((dots(1,:)).^2 + (dots(2,:)).^2);
                while isempty(distFromCenter(distFromCenter>ymax | distFromCenter<fixSizePix)) == 0 % while there are dots that are outside of the desired circle
                    idxs=find(distFromCenter>ymax | distFromCenter<fixSizePix);
                    dots(1, idxs) = 2*(xmax)*rand(1, length(idxs)) - xmax; % resample those dots
                    dots(2, idxs) = 2*(ymax)*rand(1, length(idxs)) - ymax; 
                    distFromCenter = sqrt((dots(1,:)).^2 + (dots(2,:)).^2);
                end
                dots(3, :) = (ones(size(dots,2),1)')*shiftNeeded_pix; % how much the dots will shift by in pixels
                
%                 % Stim Prep for shifting only the center dots of the stimulus (not the
%                 % whole thing). The inside center dots shifting is a
%                 % square, not circle. 
%                 vec_x = dots(1, :);
%                 vec_y = dots(2, :);
%                 vec_x(vec_x < -xmax/2) = 0;
%                 vec_x(vec_x > xmax/2) = 0;
%                 vec_y(vec_y < -ymax/2) = 0;
%                 vec_y(vec_y > ymax/2) = 0;
%                 idx_x = find(vec_x==0);
%                 idx_y = find(vec_y==0);
%                 dots(3,idx_x) = 0;
%                 dots(3,idx_y) = 0;
%                 
                % Right and left shifted dots
                leftStimDots = dots(1:2, :) + [dots(3, :)/2; zeros(1, numDots)]; % zeros here bc no shift in vertical dots 
                rightStimDots = dots(1:2, :) - [dots(3, :)/2; zeros(1, numDots)];
                
                % Rotating the dots if needed
                if this.ExperimentOptions.RotateDots == 1
                    leftDistFromCenter = sqrt((leftStimDots(1,:)).^2 + (leftStimDots(2,:)).^2); %where leftStimDots(1,:) is the x coord and leftStimDots(2,:) is the y coord
                    leftThetaDeg = atan2d(leftStimDots(2,:),leftStimDots(1,:));
                    leftPolarPtX = cosd(leftThetaDeg + this.ExperimentOptions.RotateDotsByThisMuch) .* leftDistFromCenter;
                    leftPolarPtY = sind(leftThetaDeg + this.ExperimentOptions.RotateDotsByThisMuch) .* leftDistFromCenter;
                    rightDistFromCenter = sqrt((rightStimDots(1,:)).^2 + (rightStimDots(2,:)).^2); %where leftStimDots(1,:) is the x coord and leftStimDots(2,:) is the y coord
                    rightThetaDeg = atan2d(rightStimDots(2,:),rightStimDots(1,:));
                    rightPolarPtX = cosd(rightThetaDeg + this.ExperimentOptions.RotateDotsByThisMuch) .* rightDistFromCenter;
                    rightPolarPtY = sind(rightThetaDeg + this.ExperimentOptions.RotateDotsByThisMuch) .* rightDistFromCenter;
                    % rotated dots
                    leftStimDots = [leftPolarPtX;leftPolarPtY];
                    rightStimDots = [rightPolarPtX;rightPolarPtY];
                end
                
                % What the response should be
                if thisTrialData.DisparityArcMin > 0
                    thisTrialData.CorrectResponse = 'F';
                elseif thisTrialData.DisparityArcMin < 0
                    thisTrialData.CorrectResponse = 'B';
                elseif thisTrialData.DisparityArcMin == 0
                    thisTrialData.DisparityArcMin
                    disp('Crashed here')
                    thisTrialData.DisparityArcMin
                end
                
                % For the while loop trial start
                trialDuration = this.ExperimentOptions.TrialDuration;
                lastFlipTime                        = Screen('Flip', graph.window);
                secondsRemaining                    = trialDuration;
                thisTrialData.TimeStartLoop         = lastFlipTime;
                
                response = []; %initialize this
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = trialDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                    if ( secondsElapsed <= this.ExperimentOptions.TimeStimOn ) % then show dots + fixation dot
                        % Select left-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        
                        % Draw left stim:
                        Screen('DrawDots', this.Graph.window, leftStimDots, this.ExperimentOptions.Size_of_Dots, [], this.Graph.wRect(3:4)/2, 1); % the 1 at the end means dot type where 1 2 or 3 is circular
                        Screen('DrawDots', this.Graph.window, [0;0], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);
                        
                        % Select right-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        
                        % Draw right stim:
                        Screen('DrawDots', this.Graph.window, rightStimDots, this.ExperimentOptions.Size_of_Dots, [], this.Graph.wRect(3:4)/2, 1);
                        Screen('DrawDots', this.Graph.window, [0;0], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);
                        
                    end
                    
                    if ( secondsElapsed > this.ExperimentOptions.TimeStimOn ) % then show only fixation dot
                        % Select left-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        
                        % Draw left stim:
                        Screen('DrawDots', this.Graph.window, [0;0], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);
                        
                        % Select right-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        
                        % Draw right stim:
                        Screen('DrawDots', this.Graph.window, [0;0], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);
                        
                        
                    end
                                        
                    
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------
                    
                    % -----------------------------------------------------------------
                    % -- Flip buffers to refresh screen -------------------------------
                    % -----------------------------------------------------------------
                    this.Graph.Flip(this, thisTrialData, secondsRemaining);
                    % -----------------------------------------------------------------
                    
                    
                    % -----------------------------------------------------------------
                    % --- Collecting responses  ---------------------------------------
                    % -----------------------------------------------------------------
                    
                    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                    if ( keyIsDown )
                        keys = find(keyCode);
                        for i=1:length(keys)
                            KbName(keys(i));
                            switch(KbName(keys(i)))
                                case 'RightArrow'
                                    response = 'F';
                                case 'LeftArrow'
                                    response = 'B';
                            end
                        end
                        if ( ~isempty(response) ) % if there is a response, break this trial and start the next
                            thisTrialData.Response = response;
                            thisTrialData.ResponseTime = GetSecs;
                            break;
                        end
                    end
                end
                
                if ( isempty(response) )
                    thisTrialData.Response = 'NoResponse';
                    thisTrialData.ResponseTime = GetSecs;
                    trialResult = Enum.trialResult.ABORT;
                else
                    trialResult = Enum.trialResult.CORRECT;
                end
                
                
            catch ex
                rethrow(ex)
            end
            
        end
        
       function [trialResult, thisTrialData] = runPostTrial( this, thisTrialData )
           % Record if the subject guessed correctly or not 
           if thisTrialData.Response == thisTrialData.CorrectResponse
               thisTrialData.GuessedCorrectly = 1;
           elseif thisTrialData.Response ~= thisTrialData.CorrectResponse
               thisTrialData.GuessedCorrectly = 0;
           end
           
           % Record if the trial was a reversal, may need to fix this????
          
           if thisTrialData.TrialNumber == 1
               thisTrialData.IsReversal = 0;
           elseif thisTrialData.SignDisparity == 1 & ~isempty(find(this.Session.currentRun.pastTrialTable.SignDisparity == 1)) == 0 % if the disparity is positive and positive disparities have NOT happened before
               thisTrialData.IsReversal = 0;
           elseif thisTrialData.SignDisparity == -1 & ~isempty(find(this.Session.currentRun.pastTrialTable.SignDisparity == -1)) == 0 % if the disparity is negative and negative disparities have NOT happened before
               thisTrialData.IsReversal = 0;
           elseif thisTrialData.TrialNumber > 1 
               posidx = find(this.Session.currentRun.pastTrialTable.SignDisparity == 1,1,'last');
               negidx = find(this.Session.currentRun.pastTrialTable.SignDisparity == -1,1,'last');
               if thisTrialData.SignDisparity == 1 & thisTrialData.GuessedCorrectly == this.Session.currentRun.pastTrialTable.GuessedCorrectly(posidx)
                   thisTrialData.IsReversal = 0;
               elseif thisTrialData.SignDisparity == 1 & thisTrialData.GuessedCorrectly ~= this.Session.currentRun.pastTrialTable.GuessedCorrectly(posidx)
                   thisTrialData.IsReversal = 1;
               elseif thisTrialData.SignDisparity == -1 & thisTrialData.GuessedCorrectly == this.Session.currentRun.pastTrialTable.GuessedCorrectly(negidx)
                   thisTrialData.IsReversal = 0;
               elseif thisTrialData.SignDisparity == -1 & thisTrialData.GuessedCorrectly ~= this.Session.currentRun.pastTrialTable.GuessedCorrectly(negidx)
                   thisTrialData.IsReversal = 1;
               end
           end
           
           % Move this forward
           trialResult = thisTrialData.TrialResult;
           
       end
            
       

                    
        
    end
    
end