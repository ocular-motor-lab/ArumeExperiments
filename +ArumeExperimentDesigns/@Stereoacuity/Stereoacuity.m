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
            dlg.InitStepSize = { 0.5 '* (arcmins)' [0 100] };
            dlg.Number_of_Dots = { 3000 '* (deg/s)' [10 10000] };
            dlg.Size_of_Dots = { 4 '* (pix)' [1 100] };
            dlg.visibleWindow_cm = {12 '* (cm)' [1 100] };
            
            dlg.NumberOfRepetitions = {50 '* (N)' [1 100] }; % 50 bc 50 * 2 (sign disparities) = 100 total trials
            dlg.BackgroundBrightness = 0;
            
            %% CHANGE DEFAULTS values for existing options
            
            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult Speed Stimulus'; % which variables to display every trial in the command line separated by spaces
            
            dlg.DisplayOptions.ScreenWidth = { 59.5 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 34 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 37 '* (cm)' [1 3000] };
            dlg.DisplayOptions.StereoMode = { 4 '* (mode)' [0 9] }; 
            
            dlg.HitKeyBeforeTrial = 1;
            dlg.TrialDuration = 20;
            dlg.TrialsBeforeBreak = 100;
            dlg.TrialAbortAction = 'Repeat';
        end
        
        function trialTable = SetUpTrialTable(this)
            
            %-- condition variables ---------------------------------------
            i= 0;
             
            i = i+1;
            conditionVars(i).name   = 'SignDisparity';
            conditionVars(i).values = [-1 1]; %* this.ExperimentOptions.Disparity;
            
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
            
            if thisTrialData.TrialNumber > 1
%                 lastTrialCorrResp = this.Session.currentRun.pastTrialTable.CorrectResponse(end);
%                 lastTrialResponse = this.Session.currentRun.pastTrialTable.Response(end);
                lastAbsoluteTrialDisparity = abs(this.Session.currentRun.pastTrialTable.DisparityArcMin(end));
                lastTrialGuessedCorrectly = this.Session.currentRun.pastTrialTable.GuessedCorrectly(end);
                numReversals = sum(this.Session.currentRun.pastTrialTable.IsReversal);
                
                absoluteDisparityArcMin = lastAbsoluteTrialDisparity - (this.ExperimentOptions.InitStepSize / (numReversals+1)) * (lastTrialGuessedCorrectly - 0.75);
                thisTrialData.DisparityArcMin = absoluteDisparityArcMin *  thisTrialData.SignDisparity;
                
                
                
%                 if lastTrialCorrResp == lastTrialResponse % if they guessed correctly
%                     thisTrialData.DisparityArcMin = (this.ExperimentOptions.InitStepSize*(1 - 0.75) / thisTrialData.TrialNumber) *  thisTrialData.SignDisparity; %lastTrialDisparity / 2;
%                 elseif lastTrialCorrResp ~= lastTrialResponse
%                     thisTrialData.DisparityArcMin = (this.ExperimentOptions.InitStepSize*(0 - 0.75) / thisTrialData.TrialNumber) *  thisTrialData.SignDisparity;
%                 end

            end
            
        end
        
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            try
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;
                
                trialDuration = this.ExperimentOptions.TrialDuration;
                lastFlipTime                        = Screen('Flip', graph.window);
                secondsRemaining                    = trialDuration;
                thisTrialData.TimeStartLoop         = lastFlipTime;
                
                Screen('FillRect', graph.window, 0); % not sure if needed
                
                % Define response key mappings:
                space = KbName('space');
                escape = KbName('ESCAPE');
                
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
                
                % How big should the window be in pix?
                visibleWindow_cm = this.ExperimentOptions.visibleWindow_cm; % in cm, this is how much of the screen you can see w one eye at a viewingDist of 20 (from haploscope calcs!)
                visibleWindow_pix = ((screenWidth*2) / moniterWidth_cm) * visibleWindow_cm;
                xmax = visibleWindow_pix / 2;
                ymax = xmax;
                
                % Disparity settings:
                if thisTrialData.TrialNumber == 1
                    disparity_arcmin = this.ExperimentOptions.InitDisparity *  thisTrialData.SignDisparity; % first trial's disparity will be half the max disparity
                    thisTrialData.DisparityArcMin = disparity_arcmin; % record the actual disparity in trial table. in future trials, this will already be recorded in the pre-trail phase
                else
                    disparity_arcmin = thisTrialData.DisparityArcMin; 
                end
                disparity_deg = disparity_arcmin/60;
                shiftNeeded_deg = viewingDist * tand(disparity_deg);
                shiftNeeded_pix = pixPerDeg * shiftNeeded_deg;
                dots(1, :) = 2*(xmax)*rand(1, numDots) - xmax; % SR x coords
                dots(2, :) = 2*(ymax)*rand(1, numDots) - ymax; % SR y coords
                dots(3, :) = (ones(size(dots,2),1)')*shiftNeeded_pix; % how much the dots will shift by in pixels
                
                % Stim Prep for shifting only the center dots of the stimulus (not the
                % whole thing)
                vec_x = dots(1, :);
                vec_y = dots(2, :);
                vec_x(vec_x < -xmax/2) = 0;
                vec_x(vec_x > xmax/2) = 0;
                vec_y(vec_y < -ymax/2) = 0;
                vec_y(vec_y > ymax/2) = 0;
                idx_x = find(vec_x==0);
                idx_y = find(vec_y==0);
                dots(3,idx_x) = 0;
                dots(3,idx_y) = 0;
                
                % What the response should be
                if disparity_arcmin > 0
                    thisTrialData.CorrectResponse = 'F';
                elseif disparity_arcmin < 0
                    thisTrialData.CorrectResponse = 'B';
                end
                
                response = []; %initialize this
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = trialDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    % Right and left shifted dots
                    leftStimDots = dots(1:2, :) + [dots(3, :)/2; zeros(1, numDots)];
                    rightStimDots = dots(1:2, :) - [dots(3, :)/2; zeros(1, numDots)];
                    
                    % Select left-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                    
                    % Draw left stim:
                    Screen('DrawDots', this.Graph.window, leftStimDots, this.ExperimentOptions.Size_of_Dots, [], this.Graph.wRect(3:4)/2, 1);
                    Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);
                    
                    % Select right-eye image buffer for drawing:
                    Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                    
                    % Draw right stim:
                    Screen('DrawDots', this.Graph.window, rightStimDots, this.ExperimentOptions.Size_of_Dots, [], this.Graph.wRect(3:4)/2, 1);
                    Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);
                    
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
           
           % Record if the trial was a reversal
           if thisTrialData.TrialNumber > 1
               if thisTrialData.GuessedCorrectly == this.Session.currentRun.pastTrialTable.GuessedCorrectly(end)
                   thisTrialData.IsReversal = 0;
               elseif thisTrialData.GuessedCorrectly ~= this.Session.currentRun.pastTrialTable.GuessedCorrectly(end)
                   thisTrialData.IsReversal = 1;
               end
           elseif thisTrialData.TrialNumber == 1
               thisTrialData.IsReversal = 0;
           end
           
           % Move this forward
           trialResult = thisTrialData.TrialResult;
           
       end
            
       

                    
        
    end
    
end