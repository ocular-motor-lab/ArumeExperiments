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
            conditionVars(i).values = {'Left' 'Right' 'Control'};
            
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
            
            white=255;
            black=128;
            
            % Round gray to integral number, to avoid roundoff artifacts with some
            % graphics cards:
            gray=round((white+black)/2);
            
            % This makes sure that on floating point framebuffers we still get a
            % well defined gray. It isn't strictly neccessary in this demo:
            if gray == white
                gray=white / 2;
            end
            
            % Contrast 'inc'rement range for given white and gray values:
            inc=white-gray;
            
            phase=0;
            % grating
            [x,y]=meshgrid(-300:300,-300:300);
            angle=0*pi/180; % 30 deg orientation.
            f=0.05*2*pi; % cycles/pixel
            a=cos(angle)*f;
            b=sin(angle)*f;
            m=exp(-((x/90).^2)-((y/90).^2)).*sin(a*x+b*y+phase);
        
            Images = load(fullfile(fileparts(mfilename('fullpath')),'Images.mat'));
            this.texControl = Screen('MakeTexture', this.Graph.window, Images.Images.Control.cdata);
            this.texLeft = Screen('MakeTexture', this.Graph.window, Images.Images.Left.cdata);
            this.texRight = Screen('MakeTexture', this.Graph.window, Images.Images.Right.cdata);
                    
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
                    Screen('DrawTexture', this.Graph.window, tex, [],[],thisTrialData.Angle);        
        
        
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