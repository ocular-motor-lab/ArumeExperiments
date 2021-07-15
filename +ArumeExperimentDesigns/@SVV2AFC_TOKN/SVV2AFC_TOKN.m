classdef SVV2AFC_TOKN < ArumeExperimentDesigns.SVV2AFC
    
    properties
        s = [];
        t = [];
        xymatrix = [];
        r = [];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.SVV2AFC(this, importing);
            
            
            dlg.Number_of_Dots = { 2000 '* (deg/s)' [10 10000] };
            dlg.Max_Radius = { 40 '* (deg)' [1 100] };
            dlg.Min_Radius = { 1 '* (deg)' [0 100] };

            dlg.Min_Dot_Diam = {0.1  '* (deg)' [0.01 100] };
            dlg.Max_Dot_Diam = {0.4  '* (deg)' [0.01 100] };
            dlg.Number_of_Dot_Sizes = {5 '* (N)' [1 100] };
            
            dlg.OKN_Speed = 20;
            
            
            %% CHANGE DEFAULTS 
            dlg.UseEyeTracker = 0;
            dlg.Debug.DebugMode = { {'{1}','0'} };
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult Speed Stimulus'; % which variables to display every trial in the command line separated by spaces
            
            dlg.HitKeyBeforeTrial = 0;
            dlg.TrialDuration = 10;
            dlg.TrialsBeforeBreak = 150;
            dlg.TrialAbortAction = 'Repeat';
            
            
            dlg.DisplayOptions.ScreenWidth          = { 121 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight         = { 68 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance       = { 60 '* (cm)' [1 3000] };
                dlg.DisplayOptions.ShowTrialTable       = { {'{0}','1'} };
                dlg.DisplayOptions.PlaySound            = { {'{0}','1'} };
            
            
            
            %% override defaults
            dlg.fixationDuration = { 500 '* (ms)' [1 3000] };
            dlg.targetDuration = { 100 '* (ms)' [100 30000] };
            dlg.Target_On_Until_Response = { {'0','{1}'} }; 
            dlg.responseDuration = { 1500 '* (ms)' [100 3000] };
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
            conditionVars(i).name   = 'OKN';
            conditionVars(i).values = {'CW' 'CCW'};
            
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Delay';
            trialTableOptions.trialsPerSession = 100;
            trialTableOptions.numberOfTimesRepeatBlockSequence = 5;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end
        
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            graph = this.Graph;
            
            trialDuration = this.ExperimentOptions.TrialDuration;
            
            
            
            mdir = 1;    % motion direction (in or out) for each dot
%             if ( thisTrialData.OKN == 'CCW' )
%                 mdir = -1;
%             end                 % change in theta per frame (radians)
            dot_speed   = this.ExperimentOptions.OKN_Speed;    % dot speed (deg/sec)
            dt = 2*pi/360/this.Graph.frameRate * dot_speed*mdir;
            
            if (isempty(this.xymatrix))
                % prepare dots
                
                mon_width   = this.Graph.pxWidth/this.ExperimentOptions.DisplayOptions.ScreenWidth;   % horizontal dimension of viewable screen (cm)
                v_dist      = this.ExperimentOptions.DisplayOptions.ScreenDistance ;   % viewing distance (cm)
                
                ndots       = this.ExperimentOptions.Number_of_Dots; % number of dots
                
                max_d       = this.ExperimentOptions.Max_Radius;   % maximum radius of  annulus (degrees)
                min_d       = this.ExperimentOptions.Min_Radius;    % minumum
                
                differentsizes = this.ExperimentOptions.Number_of_Dot_Sizes; % Use different sizes for each point if >= 1. Use one common size if == 0.
                dot_w       = this.ExperimentOptions.Min_Dot_Diam;  % width of dot (deg)
                                
                ppd = pi * (this.Graph.wRect(3)-this.Graph.wRect(1)) / atan(mon_width/v_dist/2) / 360;    % pixels per degree
                this.s = dot_w * ppd;                                        % dot size (pixels)
                
                rmax = max_d * ppd;	% maximum radius of annulus (pixels from center)
                rmin = min_d * ppd; % minimum
                this.r = rmin + (rmax-rmin) * sqrt(rand(ndots,1));	% r
                this.t = 2*pi*rand(ndots,1);                         % theta polar coordinate
                
                cs = [cos(this.t), sin(this.t)];
                xy = [this.r this.r] .* cs;   % dot positions in Cartesian coordinates (pixels from center)
                this.xymatrix = transpose(xy);
                 
                % Create a vector with different point sizes for each single dot, if
                % requested:
                if (differentsizes>0)
                    this.s=(1+rand(1, ndots)*(differentsizes-1))*this.s;
                end
                [center(1), center(2)] = RectCenter(this.Graph.wRect);
            
            
            
            
            end
            
            
            
            
            
            
            %-- add here the trial code
            
            % SEND TO PARALEL PORT TRIAL NUMBER
            %write a value to the default LPT1 printer output port (at 0x378)
            %nCorrect = sum(this.Session.currentRun.pastConditions(:,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT );
            %outp(hex2dec('378'),rem(nCorrect,100)*2);
            
            lastFlipTime                        = GetSecs;
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
                
                %-- Draw dots
           
                [center(1), center(2)] = RectCenter(this.Graph.wRect);
                        this.s( this.s>63) = 63;
                        Screen('DrawDots', graph.window, this.xymatrix, this.s, WhiteIndex(graph.window), center,1);  % change 1 to 0 to draw square dots
                
                
                this.t = this.t + dt;                         % update theta
                xy = [this.r this.r] .* [cos(this.t), sin(this.t)];     % compute new positions
                this.xymatrix = transpose(xy);
                
                
                
                
                
                %-- Find the center of the screen
                [mx, my] = RectCenter(graph.wRect);
                
                t1 = this.ExperimentOptions.fixationDuration/1000;
                t2 = this.ExperimentOptions.fixationDuration/1000 +this.ExperimentOptions.targetDuration/1000;
                
                if ( secondsElapsed > t1 && (this.ExperimentOptions.Target_On_Until_Response || secondsElapsed < t2) )
                    %-- Draw target
                    
                    this.DrawLine(thisTrialData.Angle, thisTrialData.Position, this.ExperimentOptions.Type_of_line);
                    
                    % SEND TO PARALEL PORT TRIAL NUMBER
                    %write a value to the default LPT1 printer output port (at 0x378)
                    %outp(hex2dec('378'),7);
                end
                
                fixRect = [0 0 10 10];
                fixRect = CenterRectOnPointd( fixRect, mx, my );
                Screen('FillOval', graph.window,  this.targetColor, fixRect);
                
                Screen('DrawingFinished', graph.window); % Tell PTB that no further drawing commands will follow before Screen('Flip')
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
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
      
        function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable, options)
            
            [right_spv, right_positionFiltered] = VOGAnalysis.GetSPV_Simple(this.Session.samplesDataTable.Time, this.Session.samplesDataTable.RightT);
            [left_spv, left_positionFiltered] = VOGAnalysis.GetSPV_Simple(this.Session.samplesDataTable.Time, this.Session.samplesDataTable.LeftT);
            
            
            sessionDataTable.AVG_leftSPV = nanmedian(left_spv);
            sessionDataTable.AVG_rightSPV = nanmedian(right_spv);
            sessionDataTable.AVG_leftTorsion = nanmedian(left_positionFiltered);
            sessionDataTable.AVG_rightTorsion = nanmedian(right_positionFiltered);
            
            torsion = (left_positionFiltered + right_positionFiltered )/2;
            medianTorsion = nanmedian(torsion);
            trialDataTable = this.Session.trialDataTable;
            
            avgTorsionPerTrial = nan(height(trialDataTable,1));
            % identify trials < median torsion and > median torsion
            for i=1:
                avgTorsionPerTrial(i)  = nanmean( trial start to trial end)
            end
            
            trialsAbove = avgTorsionPerTrial>medianTorsion;
            
            % then calculate SVV for those two groups of trials
        end
    end
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end

