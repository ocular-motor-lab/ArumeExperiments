classdef FixationTargets_BEAST < ArumeExperimentDesigns.EyeTracking
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here

    properties
        fixRad = 20;
        fixColor = [255 0 0];
        targetPositions =[];
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
            dlg.Experiment_Type = { {'Center dot' '2 dots - Horizontal' '{2 dots - Vertical}' '4 dots - Square'} };
            dlg.Calibration_Distance_H = { 20 '* (deg)' [1 3000] };
            dlg.Calibration_Distance_V = { 15 '* (deg)' [1 3000] };

            dlg.BackgroundBrightness = 0;
        end


        function trialTable = SetUpTrialTable(this)
            h = this.ExperimentOptions.Calibration_Distance_H;
            v = this.ExperimentOptions.Calibration_Distance_V;

            switch(this.ExperimentOptions.Experiment_Type)
                case 'Center dot'
                    this.targetPositions = {[0,0]};
                case '2 dots - Horizontal'
                    this.targetPositions = {[h,0],[-h,0]};
                case '2 dots - Vertical'
                    this.targetPositions = {[0,v],[0,-v]};
                case '4 dots - Square'
                    this.targetPositions = {[h,0],[-h,0],[0,v],[0,-v]};   
            end

            targets = 1:length(this.targetPositions);

            %-- condition variables ---------------------------------------
            i= 0;

            i = i+1;
            conditionVars(i).name   = 'TargetPosition';
            conditionVars(i).values = targets;


            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Sequential';
            trialTableOptions.trialAbortAction = 'Drop';
            trialTableOptions.trialsPerSession = (length(targets))*this.ExperimentOptions.NumberRepetitions;

            trialTableOptions.blockSequence       = 'Sequential';	% Sequential, Random, Random with repetition, ...numberOfTimesRepeatBlockSequence = 1;
            trialTableOptions.blocksToRun         = 1;
            trialTableOptions.blocks                = struct( 'fromCondition', 1, 'toCondition', length(targets), 'trialsToRun', length(targets));
            %trialTableOptions.blocks(2)             = struct( 'fromCondition', 2, 'toCondition', length(targets), 'trialsToRun', length(targets)-1 );
            %trialTableOptions.blocks(3)             = struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1 );
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberRepetitions;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end

        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )

            try

                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;


                lastFlipTime        = GetSecs;
                secondsRemaining    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;

                if ( ~isempty(this.eyeTracker) )
                    thisTrialData.EyeTrackerFrameStartLoop = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_LOOP %d %d %d', thisTrialData.TrialNumber, thisTrialData.Condition, thisTrialData.TargetPosition) );
                end

                while secondsRemaining > 0

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
                        targetHPix = this.Graph.pxWidth/this.ExperimentOptions.DisplayOptions.ScreenWidth * this.ExperimentOptions.DisplayOptions.ScreenDistance * tand(this.targetPositions{thisTrialData.TargetPosition}(1));
                        targetYPix = this.Graph.pxWidth/this.ExperimentOptions.DisplayOptions.ScreenWidth * this.ExperimentOptions.DisplayOptions.ScreenDistance * tand(this.targetPositions{thisTrialData.TargetPosition}(2));
                        fixRect = [0 0 targetPix/2 targetPix/2];
                        fixRect = CenterRectOnPointd( fixRect, mx+targetHPix/2, my+targetYPix/2 );
                        Screen('FillOval', graph.window, this.fixColor, fixRect);

                        fixRect2 = CenterRectOnPointd( fixRect./2, mx+targetHPix/2, my+targetYPix/2 );
                        Screen('FillOval', graph.window, [250,250,250], fixRect2);

                        Screen('DrawingFinished', graph.window); % Tell PTB that no further drawing commands will follow before Screen('Flip')
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

            targetPositions_ = cell2mat(this.targetPositions');

            calibrationPointsX = targetPositions_(trialDataTable.TargetPosition,1);
            calibrationPointsY = targetPositions_(trialDataTable.TargetPosition,2);

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


    end
end




