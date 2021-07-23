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
            dlg.Dot_Brightness = {255 '* (0-255)' [0 255] };
            %dlg.Target_Brightness = {255 '* (0-255)' [0 255] };
            
            dlg.OKN_Speed = 20;
            
            
            %% CHANGE DEFAULTS 
            dlg.UseEyeTracker = 0;
            dlg.Debug.DebugMode = { {'{1}','0'} };
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult Speed Stimulus'; % which variables to display every trial in the command line separated by spaces
            
            dlg.HitKeyBeforeTrial = 0;
            dlg.TrialDuration = 10;
%             dlg.Total
            dlg.TrialsBeforeBreak = 150;
            dlg.TrialAbortAction = 'Repeat';
            
            
            dlg.DisplayOptions.ScreenWidth          = { 144 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight         = { 82.4 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance       = { 84.5 '* (cm)' [1 3000] };
                dlg.DisplayOptions.ShowTrialTable       = { {'{0}','1'} };
                dlg.DisplayOptions.PlaySound            = { {'{0}','1'} };
            
            
            
            %% override defaults
            dlg.fixationDuration = { 500 '* (ms)' [1 3000] };
            dlg.targetDuration = { 100 '* (ms)' [30 30000] };
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
            trialTableOptions.trialsPerSession = 200;
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
                
                mon_width   = this.ExperimentOptions.DisplayOptions.ScreenWidth;   % horizontal dimension of viewable screen (cm)
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
                        Screen('DrawDots', graph.window, this.xymatrix, this.s, this.ExperimentOptions.Dot_Brightness, center,1);  % change 1 to 0 to draw square dots
                
                
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
      
        %Trial Data Table Preparation
        function trialDataTable = PrepareTrialDataTable( this, trialDataTable, options)
            trialDataTable = this.PrepareTrialDataTable@ArumeExperimentDesigns.EyeTracking(trialDataTable, options);
            
            samplesDataTable = this.Session.samplesDataTable;
            
             
            % identify trials < median torsion and > median torsion
             
             for j = 1:height(trialDataTable)
                 Rowoftrialstart = trialDataTable.SampleStartTrial(j);
                 Rowoftrialend = trialDataTable.SampleStopTrial(j);
                 %Calculation Torsion Average per trial
                 trialDataTable.TorsionAvg(j) = nanmean((samplesDataTable.RightT(Rowoftrialstart:Rowoftrialend)+samplesDataTable.LeftT(Rowoftrialstart:Rowoftrialend))/2);

                % Find duration of time stimulus is being shown 
                Timetrialstart = samplesDataTable.Time(Rowoftrialstart);
                %Will need to change 0.5 to Fixation Duration from options
                %of the session
                Timestimulusstart = Timetrialstart + 0.5;
                %Will need to change 0.3 to Target Duration from options
                Timestimulusend = Timetrialstart + 0.5 + 0.03;
                %Finding the times between the start and end of the
                %stimulus in the Sample Data Table.
                samplesDuringStim = Timestimulusstart < samplesDataTable.Time & samplesDataTable.Time < Timestimulusend;
                %Adding a column to the Trial Data Table that lists the
                %average Torsion only during stimulus presentation 
                trialDataTable.TorsionAvgDuringStim(j) = nanmean((samplesDataTable.RightT(samplesDuringStim) + samplesDataTable.LeftT(samplesDuringStim))/2);

             end
            
             %Adding a Column to TrialDataTable that indicates whether
             %Torsion average during trial for stimulus was above or below
             %the average for all trials during stimulus presentation
             trialDataTable.AboveStimTorsionAvg(trialDataTable.TorsionAvgDuringStim < nanmean(trialDataTable.TorsionAvgDuringStim)) = 0;
             trialDataTable.AboveStimTorsionAvg(trialDataTable.TorsionAvgDuringStim > nanmean(trialDataTable.TorsionAvgDuringStim)) = 1;
             
             %Adding a column to the table that indicates above or below
             %average per trial for total torsion.
             trialDataTable.AboveTotalTorsionAvg(trialDataTable.TorsionAvg < nanmean(trialDataTable.TorsionAvg)) = 0;
             trialDataTable.AboveTotalTorsionAvg(trialDataTable.TorsionAvg > nanmean(trialDataTable.TorsionAvg)) = 1;
        end
        
        
        function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable, options)
            % Session Data Table preparation
            [right_spv, right_positionFiltered] = VOGAnalysis.GetSPV_Simple(this.Session.samplesDataTable.Time, this.Session.samplesDataTable.RightT);
            [left_spv, left_positionFiltered] = VOGAnalysis.GetSPV_Simple(this.Session.samplesDataTable.Time, this.Session.samplesDataTable.LeftT);
            
            % Addition of Average slowphase velocity and filtered torsion
            % amplitude of all trials into session data table
            sessionDataTable.AVG_leftSPV = nanmedian(left_spv);
            sessionDataTable.AVG_rightSPV = nanmedian(right_spv);
            sessionDataTable.AVG_leftTorsion = nanmedian(left_positionFiltered);
            sessionDataTable.AVG_rightTorsion = nanmedian(right_positionFiltered);
            
            % Identifying completed trials, classified as "CORRECT"
            correctTrials = this.Session.trialDataTable.TrialResult=='CORRECT';
            
            angles = this.GetAngles();
            responses = this.GetLeftRightResponses();
            
            % Assigning the trial data table to a variable
            trialDataTable = this.Session.trialDataTable;
            
            % Stimulus Angles for Torsion above and below average for all
            % trials
            anglesHighTorsion = angles(correctTrials & trialDataTable.AboveStimTorsionAvg);
            responsesHighTorsion = responses(correctTrials & trialDataTable.AboveStimTorsionAvg);
            %Low classification = for trials NOT (~) "AboveStimTorsionAvg"
            anglesLowTorsion = angles(correctTrials & ~trialDataTable.AboveStimTorsionAvg);
            responsesLowTorsion = responses(correctTrials & ~trialDataTable.AboveStimTorsionAvg);
            
            % Determining average torsion during stimulus for trials that
            % were on above average vs. below average.
            THighTorsion = nanmean(trialDataTable.TorsionAvgDuringStim( correctTrials & trialDataTable.AboveStimTorsionAvg));
            TLowTorsion = nanmean(trialDataTable.TorsionAvgDuringStim( correctTrials & ~trialDataTable.AboveStimTorsionAvg));
            
            %Calculating SVV for the trials above and below average
            [SVVHighTorsion, aHighTorsion, pHighTorsion, allAnglesHighTorsion, allResponsesHighTorsion,trialCountsHighTorsion, SVVthHighTorsion, SVVstdHighTorsion] = ...
                ArumeExperimentDesigns.SVV2AFC.FitAngleResponses(anglesHighTorsion, responsesHighTorsion);
            [SVVLowTorsion, aLowTorsion, pLowTorsion, allAnglesLowTorsion, allResponsesLowTorsion,trialCountsLowTorsion, SVVthLowTorsion, SVVstdLowTorsion] = ...
                ArumeExperimentDesigns.SVV2AFC.FitAngleResponses(anglesLowTorsion, responsesLowTorsion);
            
            % Storing SVV and Torsion info from all trials into session
            % table
            sessionDataTable.SVV_HighTorsion = SVVHighTorsion;
            sessionDataTable.SVV_LowTorsion = SVVLowTorsion;
            sessionDataTable.T_HighTorsion = THighTorsion;
            sessionDataTable.T_LowTorsion = TLowTorsion;
            
        end
    end
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        %Plotting SVV Sigmoid curve
        function Plot_Sigmoid_By_Torsion(this, angles, responses)
            
            %Defining correct trials and getting angles, responses
            correctTrials = this.Session.trialDataTable.TrialResult=='CORRECT';
            
            angles = this.GetAngles();
            responses = this.GetLeftRightResponses();
            
            %Loading trial Data Table into variable 
            trialDataTable = this.Session.trialDataTable;
            
            %Calculating same values as above, angles and responses for trials above and below average torsion during stimulus presentation
            anglesHighTorsion = angles(correctTrials & trialDataTable.AboveStimTorsionAvg);
            responsesHighTorsion = responses(correctTrials & trialDataTable.AboveStimTorsionAvg);
            anglesLowTorsion = angles(correctTrials & ~trialDataTable.AboveStimTorsionAvg);
            responsesLowTorsion = responses(correctTrials & ~trialDataTable.AboveStimTorsionAvg);
            
            % Calculating average torsion for trials above and below
            % average torsion during stimulus presentation
            THighTorsion = nanmean(trialDataTable.TorsionAvgDuringStim( correctTrials & trialDataTable.AboveStimTorsionAvg));
            TLowTorsion = nanmean(trialDataTable.TorsionAvgDuringStim( correctTrials & ~trialDataTable.AboveStimTorsionAvg));
            
            
            %Calculating SVV
            [SVVHighTorsion, aHighTorsion, pHighTorsion, allAnglesHighTorsion, allResponsesHighTorsion,trialCountsHighTorsion, SVVthHighTorsion, SVVstdHighTorsion] = ...
                ArumeExperimentDesigns.SVV2AFC.FitAngleResponses(anglesHighTorsion, responsesHighTorsion);
            [SVVLowTorsion, aLowTorsion, pLowTorsion, allAnglesLowTorsion, allResponsesLowTorsion,trialCountsLowTorsion, SVVthLowTorsion, SVVstdLowTorsion] = ...
                ArumeExperimentDesigns.SVV2AFC.FitAngleResponses(anglesLowTorsion, responsesLowTorsion);
            
            
            % Making the figure 
            figure('position',[400 400 600 400],'color','w','name',this.Session.name)
            set(gca,'nextplot','add', 'fontsize',12);
            
            %Plotting all angles above average torsion during stimulus
            %presentation as a red sigmoid
            plot( allAnglesHighTorsion, allResponsesHighTorsion,'^', 'color', [1 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(aHighTorsion,pHighTorsion, 'color', 'r','linewidth',2);
            %Plotting the SVV line for high torsion
            line([SVVHighTorsion,SVVHighTorsion], [0 100], 'color','r','linewidth',2);
            plot(SVVHighTorsion, 0,'^', 'markersize',10, 'markerfacecolor','r', 'color','r','linewidth',2);
            
            %Plotting all angles below average torsion during stimulus
            %presentation as a blue sigmoid
            plot( allAnglesLowTorsion, allResponsesLowTorsion,'^', 'color', [0.7 0.7 1], 'markersize',10,'linewidth',2)
            plot(aLowTorsion,pLowTorsion, 'color', 'b','linewidth',2);
            %Plotting the average SVV line for low torsion trials
            line([SVVLowTorsion,SVVLowTorsion], [0 100], 'color','b','linewidth',2);
            plot(SVVLowTorsion, 0,'^', 'markersize',10, 'markerfacecolor','b', 'color','b','linewidth',2);
            
            
            
            % Adding text to plots
            
            % Average SVV for high and low torsion trials, with 2 decimal
            % places and threshold in parentheses
            text(30, 80, sprintf('SVV high T: %0.2f°(%0.2f)',SVVHighTorsion,SVVthHighTorsion), 'fontsize',16,'HorizontalAlignment','right');
            text(30, 70, sprintf('SVV low T: %0.2f°(%0.2f)',SVVLowTorsion,SVVthLowTorsion), 'fontsize',16,'HorizontalAlignment','right');
            
            % Including the average of torsion for the session as the
            % average for trials above average vs. below average with two
            % decimal places 
            text(30, 55, sprintf('T high T: %0.2f°',THighTorsion), 'fontsize',16,'HorizontalAlignment','right');
            text(30, 45, sprintf('T low T: %0.2f°',TLowTorsion), 'fontsize',16,'HorizontalAlignment','right');
            
            % Customizing the grid for the plot (defining axes, labels,
            % etc.)
            set(gca,'xlim',[-30 +30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'ytick',[0:25:100])
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            xlabel('Angle (deg)', 'fontsize',16);
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end

