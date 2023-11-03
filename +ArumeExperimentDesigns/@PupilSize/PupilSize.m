classdef PupilSize < ArumeExperimentDesigns.EyeTracking
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
        targetColor = [150 150 150];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            %% ADD new options
            dlg.Number_of_Dots = { 1500 '* (deg/s)' [10 10000] };
            dlg.Size_of_Dots = { 2 '* (pix)' [1 100] };
            dlg.stimWindow_deg = {2 '* (deg)' [1 100] };
            dlg.FixationSpotSize = { 0.4 '* (diameter_in_deg)' [0 5] };
            dlg.TimeStimOn = { 10 '* (sec)' [0 60] };
            dlg.InitFixDuration = { 0.25 '* (sec)' [0 60] };
            dlg.EndFixDuration = { 0.25 '* (sec)' [0 60] };
            
            dlg.NumberOfRepetitions = {1 '* (N)' [1 200] };
            dlg.BackgroundBrightness = 0;
            
            %% CHANGE DEFAULTS values for existing options
            
            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult RotateDots DisparityArcMin GuessedCorrectly'; % which variables to display every trial in the command line separated by spaces
            
            dlg.DisplayOptions.ScreenWidth = { 59.5 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 34 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 57.5 '* (cm)' [1 3000] };
            dlg.DisplayOptions.StereoMode = { 4 '* (mode)' [0 9] };
            dlg.DisplayOptions.SelectedScreen = { 1 '* (screen)' [0 5] };
            
            dlg.HitKeyBeforeTrial = 1;
            dlg.TrialDuration = 90;
            dlg.TrialsBeforeBreak = 1200;
            dlg.TrialAbortAction = 'Repeat';
        end
        
        function trialTable = SetUpTrialTable(this)
            
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Disparities';
            conditionVars(i).values = [.1 .5 1 1.5 2 2.5 3 3.5 4];
                        
            i = i+1;
            conditionVars(i).name   = 'SignDisparity';
            conditionVars(i).values = [-1 1];
            
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Sequential'; % Random, Sequential
            trialTableOptions.trialAbortAction = 'Repeat'; % Repeat, Delay, Drop
            trialTableOptions.trialsPerSession = 1000;
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            try
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;
                Screen('FillRect', graph.window, 0); % not sure if needed
                ShowCursor();
                
                % Screen and monitor settings
                screenWidth_pix = this.Graph.wRect(3); % screen width of one of the two eyes in pix
                moniterWidth_deg = (atan2d(this.ExperimentOptions.DisplayOptions.ScreenWidth/2, this.ExperimentOptions.DisplayOptions.ScreenDistance)) * 2;
                pixPerDeg = (screenWidth_pix*2) / moniterWidth_deg;
                
                % Get fixation spot size in pix
                fixSizePix = pixPerDeg * this.ExperimentOptions.FixationSpotSize;
                
                % How big should the dots stimulus be in pix
                dots = zeros(3, this.ExperimentOptions.Number_of_Dots);
                stimWindow_pix = this.ExperimentOptions.stimWindow_deg * pixPerDeg;
                
                % Disparity settings:
                thisTrialData.DisparityArcMin = thisTrialData.Disparities * thisTrialData.SignDisparity;
                disparity_deg = thisTrialData.DisparityArcMin/60;
                disparityNeeded_pix = pixPerDeg*disparity_deg;
                dots(1, :) = stimWindow_pix*rand(1, this.ExperimentOptions.Number_of_Dots) - (stimWindow_pix/2); % SR x coords
                dots(2, :) = stimWindow_pix*rand(1, this.ExperimentOptions.Number_of_Dots) - (stimWindow_pix/2); % SR y coords
                
                % Make the dot stimulus circular :D
                distFromCenter = sqrt((dots(1,:)).^2 + (dots(2,:)).^2);
                while isempty(distFromCenter(distFromCenter>stimWindow_pix/2)) == 0 % while there are dots that are outside of the desired circle
                    idxs=find(distFromCenter>stimWindow_pix/2);
                    dots(1, idxs) = stimWindow_pix*rand(1, length(idxs)) - (stimWindow_pix/2); % resample those dots
                    dots(2, idxs) = stimWindow_pix*rand(1, length(idxs)) - (stimWindow_pix/2);
                    distFromCenter = sqrt((dots(1,:)).^2 + (dots(2,:)).^2);
                end
                dots(3, :) = (ones(size(dots,2),1)')*disparityNeeded_pix; % how much the dots will shift by in pixels
                
                % Right and left shifted dots % SR DOES IT MATTER PLUS LEFT/RIGHT OR MINUS?
                leftStimDots = [dots(1,:)+(dots(3,:)/2); dots(2,:)]; %dots(1:2, :) + [dots(3, :)/2; zeros(1, numDots)];
                rightStimDots = [dots(1,:)-(dots(3,:)/2); dots(2,:)];
               
                % What the response should be
                if thisTrialData.DisparityArcMin > 0
                    thisTrialData.CorrectResponse = 'F';
                elseif thisTrialData.DisparityArcMin < 0
                    thisTrialData.CorrectResponse = 'B';
                end
                
                % For the while loop trial start
                lastFlipTime                        = Screen('Flip', graph.window);
                secondsRemaining                    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop         = lastFlipTime;
                
                response = []; %initialize this
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                    % If it's during the time when the stimulus (dots) is on, then snow the stimulus plus the fixation dot
                    if ( secondsElapsed > this.ExperimentOptions.InitFixDuration && secondsElapsed < this.ExperimentOptions.TimeStimOn ) % then show dots + fixation dot
                        % Select left-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        
                        % Draw left stim:
                        Screen('DrawDots', this.Graph.window, leftStimDots, this.ExperimentOptions.Size_of_Dots, [], this.Graph.wRect(3:4)/2, 1); % the 1 at the end means dot type where 1 2 or 3 is circular
                        Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);
                        
                        % Select right-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        
                        % Draw right stim:
                        Screen('DrawDots', this.Graph.window, rightStimDots, this.ExperimentOptions.Size_of_Dots, [], this.Graph.wRect(3:4)/2, 1);
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
            
            % Move this forward
            trialResult = thisTrialData.TrialResult;
        end
        
        
    end
    
end