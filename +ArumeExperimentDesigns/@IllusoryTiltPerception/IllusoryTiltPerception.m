classdef IllusoryTiltPerception < ArumeExperimentDesigns.SVV2AFC
    %Illusotry tilt Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        texControl = [];
        texLeft = [];
        texRight = [];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.SVV2AFC(this, importing);
            
            dlg.StimulusContrast0to100 = 10;
            dlg.TestWithoutTilt = { {'{0}','1'} };
        end
        
        
        % Set up the trial table when a new session is created
        function trialTable = SetUpTrialTable( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Angle';
            conditionVars(i).values = -10:2:10;
            
            i = i+1;
            conditionVars(i).name   = 'Position';
            conditionVars(i).values = {'Up'};
            
            i = i+1;
            conditionVars(i).name   = 'Image';
            conditionVars(i).values = {'Left' 'Right'};
            
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Delay';
            trialTableOptions.trialsPerSession = 100;
            trialTableOptions.numberOfTimesRepeatBlockSequence = 5;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end
        
        function [trialResult, thisTrialData] = runPreTrial( this, thisTrialData )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
            if ( isempty(this.Session.currentRun.pastTrialTable) && this.ExperimentOptions.HeadAngle ~= 0 )
                [trialResult, thisTrialData] = this.TiltBiteBar(this.ExperimentOptions.HeadAngle, thisTrialData);
            end
            
            
            I = imread(fullfile(fileparts(mfilename('fullpath')),'TiltWithBlur.png'));
            Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
            
            Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');

            this.texLeft = Screen('MakeTexture', this.Graph.window, Isquare);
            this.texRight = Screen('MakeTexture', this.Graph.window, Isquare(end:-1:1,:,:));
                    
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
                
                
                t1 = this.ExperimentOptions.fixationDuration/1000;
                t2 = this.ExperimentOptions.fixationDuration/1000 +this.ExperimentOptions.targetDuration/1000;
                
                if ( secondsElapsed > t1 && (this.ExperimentOptions.Target_On_Until_Response || secondsElapsed < t2) )
                    %-- Draw target
                    
                    switch(thisTrialData.Image)
                        case 'Left'
                            tex = this.texLeft;
                        case 'Right'
                            tex = this.texRight;
                        case 'Control'
                            tex = this.texControl;
                    end
                    
                    if ( this.ExperimentOptions.TestWithoutTilt)
                        Screen('DrawTexture', this.Graph.window, tex);        
                    else
                        Screen('DrawTexture', this.Graph.window, tex, [],[],thisTrialData.Angle);        
                    end
        
        
                    % SEND TO PARALEL PORT TRIAL NUMBER
                    %write a value to the default LPT1 printer output port (at 0x378)
                    %outp(hex2dec('378'),7);
                end
                
                fixRect = [0 0 10 10];
                fixRect = CenterRectOnPointd( fixRect, mx, my );
                Screen('FillOval', graph.window,  this.targetColor, fixRect);
                
                this.Graph.Flip(this, thisTrialData, secondsRemaining);
                % -----------------------------------------------------------------
                % --- END Drawing of stimulus -------------------------------------
                % -----------------------------------------------------------------
                
                
                % -----------------------------------------------------------------
                % --- Collecting responses  ---------------------------------------
                % -----------------------------------------------------------------
                
                if ( secondsElapsed > max(t1,0.200)  )
                    reverse = thisTrialData.Position == 'Down';
                    response = this.CollectLeftRightResponse(reverse);
                    if ( ~isempty( response) )
                        thisTrialData.Response = response;
                        thisTrialData.ResponseTime = GetSecs;
                        thisTrialData.ReactionTime = thisTrialData.ResponseTime - thisTrialData.TimeStartLoop - t1;
                        
                        % SEND TO PARALEL PORT TRIAL NUMBER
                        %write a value to the default LPT1 printer output port (at 0x378)
                        %outp(hex2dec('378'),9);
                        
                        break;
                    end
                end
                
                % -----------------------------------------------------------------
                % --- END Collecting responses  -----------------------------------
                % -----------------------------------------------------------------
                
            end
            
            if ( isempty(response) )
                trialResult = Enum.trialResult.ABORT;
            else
                trialResult = Enum.trialResult.CORRECT;
            end
        end
          
    end
    
end