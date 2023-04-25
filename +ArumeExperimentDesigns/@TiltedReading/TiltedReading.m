classdef TiltedReading < ArumeExperimentDesigns.EyeTracking
    % DEMO experiment for Arume
    %
    %   1. Copy paste the folder @Demo within +ArumeExperimentDesigns.
    %   2. Rename the folder with the name of the new experiment but keep that @ at the begining!
    %   3. Rename also the file inside to match the name of the folder (without the @ this time).
    %   4. Then change the name of the class inside the folder.
    %
    properties
        fixRad = 20;
        fixColor = [255 0 0];
        stimTexture = [];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            %% ADD new options
            dlg.StimSizeDeg = {30 '* (deg)' [1 100] };
            dlg.ImTilt = {45 '* (deg)' [0 90] };
            dlg.Initial_Fixation_Duration = {2 '* (s)' [1 100] };
            dlg.TargetSize = 0.5;
            
            dlg.NumberOfRepetitions = {1 '* (N)' [1 100] };
            
            dlg.BackgroundBrightness = 255;
            
            %% CHANGE DEFAULTS values for existing options
            
            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult Speed Stimulus'; % which variables to display every trial in the command line separated by spaces
            
            dlg.DisplayOptions.ScreenWidth = { 144 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 80 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 90 '* (cm)' [1 3000] };
            
            dlg.HitKeyBeforeTrial = 0;
            dlg.TrialDuration = 60;
            dlg.TrialsBeforeBreak = 1000;
            dlg.TrialAbortAction = 'Repeat';
        end
        
        function trialTable = SetUpTrialTable(this)
            
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Image';
            conditionVars(i).values = {'01' '02' '03' '04' '05' '06' '07' '08' '09' '10'};
            
            i = i+1;
            conditionVars(i).name   = 'ImTilt';
            conditionVars(i).values = [0 1] * this.ExperimentOptions.ImTilt;
            
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Delay';
            trialTableOptions.trialsPerSession = 1000;
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end
        
        function [trialResult, thisTrialData] = runPreTrial( this, thisTrialData )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
            
            test = string(thisTrialData.Image);
            imageFile = fullfile(fileparts(mfilename('fullpath')),[test + ".jpg"]);
            I = imread(imageFile);
            
            monitorWidthPix     = this.Graph.wRect(3);
            monitorWidthCm      = this.ExperimentOptions.DisplayOptions.ScreenWidth;
            monitorDistanceCm   = this.ExperimentOptions.DisplayOptions.ScreenDistance;
            stimSizeDeg         = this.ExperimentOptions.StimSizeDeg;
            
            % we will asume that pixels are square
            monitorWidthDeg     = 2*atand(monitorWidthCm/monitorDistanceCm/2);
            % asuming linearity (not completely true for very large displays
            %             pixelsPerDeg        = monitorWidthPix/monitorWidthDeg;
            %             stimSizePix         = pixelsPerDeg * stimSizeDeg;
            
            % non linear aproximation
            stimSizeCm  = 2*tand(stimSizeDeg/2)*monitorDistanceCm
            stimSizePix = (monitorWidthPix/monitorWidthCm)*stimSizeCm
            
            Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:)));
            Isquare = imresize(Isquare, [stimSizePix stimSizePix], 'bilinear');
            this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
            
        end
        
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            try
                
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;
                
                
                trialDuration = this.ExperimentOptions.TrialDuration;
                
                %-- add here the trial code
                Screen('FillRect', graph.window, 0);
                
                
                lastFlipTime                        = Screen('Flip', graph.window);
                secondsRemaining                    = trialDuration;
                thisTrialData.TimeStartLoop         = lastFlipTime;
                if ( ~isempty(this.eyeTracker) )
                    thisTrialData.EyeTrackerFrameStartLoop = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_LOOP %d %d', thisTrialData.TrialNumber, thisTrialData.Condition) );
                end
                response = []; %initialize this
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = trialDuration - secondsElapsed;
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);
                    fixRect = [0 0 10 10];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    
                    if ( secondsElapsed <= this.ExperimentOptions.Initial_Fixation_Duration )
                        % For the fixation dot
                        Screen('FillOval', graph.window,  this.fixColor, fixRect); % UPDATE FIXRECT TO BE THE FIXATION DOT SIZE FROM ABOVE
                    end
                    
                    if ( secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration )
                        % Show image
                        Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],thisTrialData.ImTilt);
                        
                    end
                    
                    this.Graph.Flip(this, thisTrialData, secondsRemaining);
                    
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                    % -----------------------------------------------------------------
                    % --- Collecting responses  ---------------------------------------
                    % -----------------------------------------------------------------
                    
                    [keyIsDown, secs, keyCode, ~] = KbCheck();
                    if ( keyIsDown )
                        keys = find(keyCode);
                        for i=1:length(keys)
                            KbName(keys(i));
                            switch(KbName(keys(i)))
                                case 'space'
                                    response = 1;
                            end
                        end
                        
                    end
                    if ( ~isempty( response) )
                        thisTrialData.ResponseTime = GetSecs;
                        thisTrialData.TrialDurInSec = secondsElapsed - this.ExperimentOptions.Initial_Fixation_Duration;
                        
                        break;
                    end
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------
                    
                    
                end
                
                
            catch ex
                rethrow(ex)
            end
            
        end
    end
    
end