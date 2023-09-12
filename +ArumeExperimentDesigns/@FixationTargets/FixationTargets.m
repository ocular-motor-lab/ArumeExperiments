classdef FixationTargets < ArumeExperimentDesigns.EyeTracking
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here

    properties
        fixRad = 20;
        fixColor = [255 0 0];
    end

    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            if( ~exist( 'importing', 'var' ) )
                importing = 0;
            end
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult TargetPosition'; % which variables to display every trial in the command line separated by spaces

            dlg.DisplayOptions.ScreenWidth = { 142.8 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 80 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 85 '* (cm)' [1 3000] };

            dlg.TrialDuration =  { 20 '* (s)' [1 100] };
            dlg.NumberRepetitions = 10;

            dlg.TargetSize = 1;
%             dlg.Calibration_Distance_H = { 20 '* (deg)' [1 3000] };
%             dlg.Calibration_Distance_V = { 15 '* (deg)' [1 3000] };

            dlg.BackgroundBrightness = 0;
        end


        function trialTable = SetUpTrialTable(this)


            targets = 1;%:9;

            %-- condition variables ---------------------------------------
            i= 0;

            i = i+1;
            conditionVars(i).name   = 'TargetPosition';
            conditionVars(i).values = targets;


            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Delay';
            trialTableOptions.trialsPerSession = (length(targets)+1)*this.ExperimentOptions.NumberRepetitions;

            trialTableOptions.blockSequence       = 'Sequential';	% Sequential, Random, Random with repetition, ...numberOfTimesRepeatBlockSequence = 1;
            trialTableOptions.blocksToRun         = 3;
            trialTableOptions.blocks                = struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1 );
            trialTableOptions.blocks(2)             = struct( 'fromCondition', 2, 'toCondition', length(targets), 'trialsToRun', length(targets)-1 );
            trialTableOptions.blocks(3)             = struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1 );
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberRepetitions;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end

        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )

%             h = this.ExperimentOptions.Calibration_Distance_H;
%             v = this.ExperimentOptions.Calibration_Distance_V;
            targetPositions = {[0,0]};%,[h,0],[-h,0],[0,v],[0,-v],[h,v],[h,-v],[-h,v],[-h,-v]};

            try

                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;


                lastFlipTime        = GetSecs;
                secondsRemaining    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;
                
                secondsRemainingGap = 5;

                if ( ~isempty(this.eyeTracker) )
                    thisTrialData.EyeTrackerFrameStartLoop = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_LOOP %d %d %d', thisTrialData.TrialNumber, thisTrialData.Condition, thisTrialData.TargetPosition) );
                end

                while secondsRemaining > -5

                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;

                    if secondsRemaining > 0 
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    Screen('FillRect', graph.window, this.ExperimentOptions.BackgroundBrightness);

                    %-- Draw fixation spot
                    [mx, my] = RectCenter(this.Graph.wRect);
                    % this.Graph.pxWidth
                    % targetHPix
                    targetPix = this.Graph.pxWidth/this.ExperimentOptions.DisplayOptions.ScreenWidth * this.ExperimentOptions.DisplayOptions.ScreenDistance * tand(this.ExperimentOptions.TargetSize);
                    targetHPix = this.Graph.pxWidth/this.ExperimentOptions.DisplayOptions.ScreenWidth * this.ExperimentOptions.DisplayOptions.ScreenDistance * tand(targetPositions{thisTrialData.TargetPosition}(1));
                    targetYPix = this.Graph.pxWidth/this.ExperimentOptions.DisplayOptions.ScreenWidth * this.ExperimentOptions.DisplayOptions.ScreenDistance * tand(targetPositions{thisTrialData.TargetPosition}(2));
                    fixRect = [0 0 targetPix/2 targetPix/2];
                    fixRect = CenterRectOnPointd( fixRect, mx+targetHPix/2, my+targetYPix/2 );
                    Screen('FillOval', graph.window, this.fixColor, fixRect);

                    fixRect2 = CenterRectOnPointd( fixRect./2, mx+targetHPix/2, my+targetYPix/2 );
                    Screen('FillOval', graph.window, [250,250,250], fixRect2);

                    Screen('DrawingFinished', graph.window); % Tell PTB that no further drawing commands will follow before Screen('Flip')

                    else
                        Screen('FillRect', graph.window, this.ExperimentOptions.BackgroundBrightness);
                        Screen('DrawingFinished', graph.window);
                    end


                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------

                    % -----------------------------------------------------------------
                    % -- Flip buffers to refresh screen -------------------------------
                    % -----------------------------------------------------------------
                    this.Graph.Flip();
                    % -----------------------------------------------------------------


                    % -----------------------------------------------------------------
                    % --- Collecting responses  ---------------------------------------
                    % -----------------------------------------------------------------

                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------

                end
                


            catch ex
                rethrow(ex)
            end

        end
    end

    methods ( Access = public )
        function [analysisResults, samplesDataTable, trialDataTable, sessionDataTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable, sessionDataTable, options)

            [analysisResults, samplesDataTable, trialDataTable, sessionDataTable]  = RunDataAnalyses@ArumeExperimentDesigns.EyeTracking(this, analysisResults, samplesDataTable, trialDataTable, sessionDataTable, options);


%             h = this.ExperimentOptions.Calibration_Distance_H/2;
%             v = -this.ExperimentOptions.Calibration_Distance_V/2;
            targetPositions = {[0,0]};%,[h,0],[-h,0],[0,v],[0,-v],[h,v],[h,-v],[-h,v],[-h,-v]};
            targetPositions = cell2mat(targetPositions');

            calibrationPointsX = targetPositions(trialDataTable.TargetPosition,1);
            calibrationPointsY = targetPositions(trialDataTable.TargetPosition,2);

            fstart = round(trialDataTable.SampleStartTrial + 0.500*samplesDataTable.Properties.UserData.sampleRate);
            fstops = trialDataTable.SampleStopTrial;

            t = nan(size(samplesDataTable,1),2);

            for i=1:length(fstart)
                t(fstart(i):fstops(i),1) = calibrationPointsX(i);
                t(fstart(i):fstops(i),2) = calibrationPointsY(i);
            end

            targetPosition = table();
            targetPosition.x = t(:,1);
            targetPosition.y = t(:,2);
            targetPosition.LeftX = t(:,1);
            targetPosition.LeftY = t(:,2);
            targetPosition.RightX = t(:,1);
            targetPosition.RightY = t(:,2);

            analysisResults.calibrationTableCR = VOGAnalysis.CalculateCalibrationCR(samplesDataTable, targetPosition);
            analysisResults.calibrationTable = VOGAnalysis.CalculateCalibration(samplesDataTable, targetPosition);

        end
    end

    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        function [out, options] = PlotAggregate_MicroCorrelations(this, sessions, options)


            out = [];
            if ( nargin == 1 )
                options = this.PlotAggregate_MicroCorrelations('get_defaults');
            end

            if ( ischar(sessions) )
                command = sessions;
                switch( command)
                    case 'get_options'
                        options =[];
                        return
                    case 'get_defaults'
                        optionsDlg = VOGAnalysis.PlotAggregate_MicroCorrelations('get_options');
                        options = StructDlg(optionsDlg,'',[],[],'off');
                        return
                end
            end


            data = [];
            % for each subj, ignoring 000
            for subj = 1:length(sessions)
                %load data
                AnalysisResults_QuickPhases = sessions(subj).analysisResults.QuickPhases;

                % pick the center positions
                center_indx = AnalysisResults_QuickPhases.Left_X_MeanPosition <= 2 &...
                    AnalysisResults_QuickPhases.Left_X_MeanPosition >= -2 &...
                    AnalysisResults_QuickPhases.Left_Y_MeanPosition <= 2 &...
                    AnalysisResults_QuickPhases.Left_Y_MeanPosition >= -2;

                d = AnalysisResults_QuickPhases(center_indx,:);

                % create the table
                data(subj).X_Vergence = d.Left_X_Displacement - d.Right_X_Displacement;
                data(subj).Y_Vergence = d.Left_Y_Displacement - d.Right_Y_Displacement;
                data(subj).T_Vergence = d.Left_T_Displacement - d.Right_T_Displacement;

                data(subj).X_Version = (d.Left_X_Displacement + d.Right_X_Displacement)./2;
                data(subj).Y_Version = (d.Left_Y_Displacement + d.Right_Y_Displacement)./2;
                data(subj).T_Version = (d.Left_T_Displacement + d.Right_T_Displacement)./2;
            end


            %% create the corr table

            % combine all data
            dataAll.X_Vergence = [];
            dataAll.Y_Vergence = [];
            dataAll.T_Vergence = [];

            dataAll.X_Version = [];
            dataAll.Y_Version = [];
            dataAll.T_Version = [];

            for subj = 1:length(data)
                dataAll.X_Vergence = [dataAll.X_Vergence; data(subj).X_Vergence];
                dataAll.Y_Vergence = [dataAll.Y_Vergence; data(subj).Y_Vergence];
                dataAll.T_Vergence = [dataAll.T_Vergence; data(subj).T_Vergence];

                dataAll.Y_Version = [dataAll.Y_Version; data(subj).Y_Version];
                dataAll.X_Version = [dataAll.X_Version; data(subj).X_Version];
                dataAll.T_Version = [dataAll.T_Version; data(subj).T_Version];
            end

            dataAll_ = [...
                dataAll.X_Vergence,...
                dataAll.Y_Vergence,...
                dataAll.T_Vergence,...
                dataAll.X_Version,...
                dataAll.Y_Version,...
                dataAll.T_Version...
                ];

            [R,P] = corr(dataAll_,'rows','complete');

            c = 0;
            figure,
            for i = 1:6
                for j = 1:6
                    c = c + 1;
                    h(i,j) = subplot(6,6,c);
                    if i >= j, continue; end
                    plot(dataAll_(:,j),dataAll_(:,i),'.');
                    xlim([-1,1])
                    ylim([-1,1])
                    title(strcat("R = ",num2str(round(R(c),2))))
                end
            end

            linkaxes(h(:))

            n = [...
                "X Vergence",...
                "Y Vergence",...
                "T Vergence",...
                "X Version",...
                "Y Version",...
                "T Version"...
                ];

            c=1;
            for i = 1:6:36
                subplot(6,6,i)
                ylabel(n(c))
                c=c+1;
            end


            for i = 31:36
                subplot(6,6,i)
                xlabel(n(i-30))
            end

            sgtitle("Center Fixational Micro Saccades Amplitude (degree)")
        end

        function [out] = Plot_Listings(this)
            figure
            s = this.Session.samplesDataTable;
            plot(s.LeftX, s.LeftT,'o')
            hold
            plot(s.RightX, s.RightT,'o')
            set(gca,'xlim',[-20 20],'ylim',[-20 20])
            xlabel('Horizontal')
            ylabel('Torsion')
        end
    end
end




