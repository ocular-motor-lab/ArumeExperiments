classdef IllusoryTilt < ArumeExperimentDesigns.EyeTracking
    %Illusotry tilt Summary of this class goes here
    %   Detailed explanation goes here

    properties
        stimTexture = [];
        targetColor = [255 0 0];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            dlg.Trial_Duration  =  { 20 '* (s)' [1 100] };
            
            dlg.NumberOfRepetitions = {8 '* (N)' [1 100] };
                         
            dlg.TargetSize = 0.5;
            
            dlg.BackgroundBrightness = 0;
            
            dlg.StimulusContrast0to100 = 10;
            dlg.SmallTilt = 10;
            dlg.LargeTilt = 30;
        end
        
        % Set up the trial table when a new session is created
        function trialTable = SetUpTrialTable( this )
            %-- condition variables ---------------------------------------
            i= 0;
                                    
            i = i+1;
            conditionVars(i).name   = 'Image';
            conditionVars(i).values = {'IlusoryTiltRight' 'IllusoryTiltLeft' 'RealSmallTiltLeft' 'RealSmallTiltRight' 'RealLargeTiltLeft' 'RealLargeTiltRight'};
            
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Delay';
            trialTableOptions.trialsPerSession = 100;
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end
        
        
        function [trialResult, thisTrialData] = runPreTrial( this, thisTrialData )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
            
            switch(thisTrialData.Image)
                case 'IlusoryTiltRight'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'TiltWithBlur.png'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare(end:-1:1,:,:));
                    
                case 'IllusoryTiltLeft'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'TiltWithBlur.png'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
                case 'RealSmallTiltLeft'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'NaturalImage.jpg'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
                case 'RealSmallTiltRight'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'NaturalImage.jpg'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
                case 'RealLargeTiltLeft'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'NaturalImage.jpg'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
                case 'RealLargeTiltRight'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'NaturalImage.jpg'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
            end
            
        end
            
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            graph = this.Graph;
            
            trialDuration = this.ExperimentOptions.TrialDuration;
            
            %-- add here the trial code
            Screen('FillRect', graph.window, 0);
            
            % SEND TO PARALEL PORT TRIAL NUMBER
            %write a value to the default LPT1 printer output port (at 0x378)
            %nCorrect = sum(this.Session.currentRun.pastConditions(:,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT );
            %outp(hex2dec('378'),rem(nCorrect,100)*2);
            
            lastFlipTime                        = Screen('Flip', graph.window);
            secondsRemaining                    = trialDuration;
            thisTrialData.TimeStartLoop         = lastFlipTime;
            if ( ~isempty(this.eyeTracker) )
                thisTrialData.EyeTrackerFrameStartLoop = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_LOOP %d %d', thisTrialData.TrialNumber, thisTrialData.Condition) );
            end
            while secondsRemaining > 0
                
                secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                secondsRemaining    = trialDuration - secondsElapsed;
                
                % -----------------------------------------------------------------
                % --- Drawing of stimulus -----------------------------------------
                % -----------------------------------------------------------------
                
                %-- Find the center of the screen
                [mx, my] = RectCenter(graph.wRect);
                                
                switch(thisTrialData.Image)
                    case 'IlusoryTiltRight'
                        Screen('DrawTexture', this.Graph.window, this.stimTexture);
                    case 'IllusoryTiltLeft'
                        Screen('DrawTexture', this.Graph.window, this.stimTexture);
                    case 'RealSmallTiltLeft'
                        Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],-this.ExperimentOptions.SmallTilt);
                    case 'RealSmallTiltRight'
                        Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],this.ExperimentOptions.SmallTilt);
                    case 'RealLargeTiltLeft'
                        Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],-this.ExperimentOptions.LargeTilt);
                    case 'RealLargeTiltRight'
                        Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],this.ExperimentOptions.LargeTilt);
                end
                
                %-- Draw target
                
                
                fixRect = [0 0 10 10];
                fixRect = CenterRectOnPointd( fixRect, mx, my );
                Screen('FillOval', graph.window,  this.targetColor, fixRect);
                
                this.Graph.Flip(this, thisTrialData, secondsRemaining);
                % -----------------------------------------------------------------
                % --- END Drawing of stimulus -------------------------------------
                % -----------------------------------------------------------------
                
                
            end
            
            trialResult = Enum.trialResult.CORRECT;
        end
          
    end
    
end