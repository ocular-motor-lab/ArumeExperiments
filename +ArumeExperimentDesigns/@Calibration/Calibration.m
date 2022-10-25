classdef Calibration < ArumeExperimentDesigns.EyeTracking
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
                
            dlg.DisplayOptions.ScreenWidth = { 144 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 80 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 90 '* (cm)' [1 3000] };
                      
            dlg.TrialDuration =  { 3 '* (s)' [1 100] };
            
            dlg.TargetSize = 0.5;
            dlg.Calibration_Distance_H = { 20 '* (deg)' [1 3000] };
            dlg.Calibration_Distance_V = { 20 '* (deg)' [1 3000] };
            
            dlg.BackgroundBrightness = 0;
        end


        function trialTable = SetUpTrialTable(this)
            

            targets = 1:9;

            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'TargetPosition';
            conditionVars(i).values = targets;
            
            
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Delay';
            trialTableOptions.trialsPerSession = (length(targets)+1)*1;

            trialTableOptions.blockSequence       = 'Sequential';	% Sequential, Random, Random with repetition, ...numberOfTimesRepeatBlockSequence = 1;
            trialTableOptions.blocksToRun         = 3;
            trialTableOptions.blocks                = struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1 );
            trialTableOptions.blocks(2)             = struct( 'fromCondition', 2, 'toCondition', length(targets), 'trialsToRun', length(targets)-1 );
            trialTableOptions.blocks(3)             = struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1 );
            trialTableOptions.numberOfTimesRepeatBlockSequence = 21;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end

        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            h = this.ExperimentOptions.Calibration_Distance_H;
            v = this.ExperimentOptions.Calibration_Distance_V;
            targetPositions = {[0,0],[h,0],[-h,0],[0,v],[0,-v],[h,v],[h,-v],[-h,v],[-h,-v]};

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
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    %-- Draw fixation spot
                    [mx, my] = RectCenter(this.Graph.wRect)
                   % this.Graph.pxWidth
                   % targetHPix
                    targetPix = this.Graph.pxWidth/this.ExperimentOptions.DisplayOptions.ScreenWidth * this.ExperimentOptions.DisplayOptions.ScreenDistance * tand(this.ExperimentOptions.TargetSize);
                    targetHPix = this.Graph.pxWidth/this.ExperimentOptions.DisplayOptions.ScreenWidth * this.ExperimentOptions.DisplayOptions.ScreenDistance * tand(targetPositions{thisTrialData.TargetPosition}(1));
                    targetYPix = this.Graph.pxWidth/this.ExperimentOptions.DisplayOptions.ScreenWidth * this.ExperimentOptions.DisplayOptions.ScreenDistance * tand(targetPositions{thisTrialData.TargetPosition}(2));
                    fixRect = [0 0 targetPix/2 targetPix/2];
                    fixRect = CenterRectOnPointd( fixRect, mx+targetHPix/2, my+targetYPix/2 );
                    Screen('FillOval', graph.window, this.fixColor, fixRect);
                    
                    Screen('DrawingFinished', graph.window); % Tell PTB that no further drawing commands will follow before Screen('Flip')
                    
                    
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


            h = this.ExperimentOptions.Calibration_Distance_H/2;
            v = -this.ExperimentOptions.Calibration_Distance_V/2;
            targetPositions = {[0,0],[h,0],[-h,0],[0,v],[0,-v],[h,v],[h,-v],[-h,v],[-h,-v]};
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

        function [out] = Plot_CalibrationDebug(this)


            analysisResults = this.Session.analysisResults;
            samplesDataTable = this.Session.samplesDataTable;
            trialDataTable = this.Session.trialDataTable;
            sessionDataTable = this.Session.sessionDataTable;



            h = this.ExperimentOptions.Calibration_Distance_H/2;
            v = -this.ExperimentOptions.Calibration_Distance_V/2;
            targetPositions = {[0,0],[h,0],[-h,0],[0,v],[0,-v],[h,v],[h,-v],[-h,v],[-h,-v]};
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
             

            samplesDataTable.LeftX = samplesDataTable.LeftX_UNCALIBRATED;
            samplesDataTable.LeftY = samplesDataTable.LeftY_UNCALIBRATED;
            samplesDataTable.RightX = samplesDataTable.RightX_UNCALIBRATED;
            samplesDataTable.RightY = samplesDataTable.RightY_UNCALIBRATED;
            

             calibratedCalibrationData   = VOGAnalysis.CalibrateDataCR(samplesDataTable, analysisResults.calibrationTableCR);
             PlotCalibrationCR(analysisResults.calibrationTableCR, samplesDataTable, calibratedCalibrationData, targetPosition)
             title('CR calibration')
                          
             calibratedCalibrationData   = VOGAnalysis.CalibrateData(samplesDataTable, analysisResults.calibrationTable);
             PlotCalibration(analysisResults.calibrationTable, samplesDataTable, calibratedCalibrationData, targetPosition)
             title('pupil calibration')
        end
    end
end


        function PlotCalibration(calibrationCoefficients, rawCalibrationData, calibratedCalibrationData, targetPosition)
            
%             rawCalibrationData.LeftX = rawCalibrationData.LeftX - rawCalibrationData .LeftCR1X;
%             rawCalibrationData.LeftY = rawCalibrationData.LeftY - rawCalibrationData.LeftCR1Y;
%             rawCalibrationData.RightX = rawCalibrationData.RightX - rawCalibrationData.RightCR1X;
%             rawCalibrationData.RightY = rawCalibrationData.RightY - rawCalibrationData.RightCR1Y;
            
            
            figure
            t = calibratedCalibrationData.Time;
            
            subplot(4,3,1,'nextplot','add')
            title('Targets X/Y (deg)');
            plot(targetPosition.x,targetPosition.y,'.')
            
            subplot(4,3,2,'nextplot','add')
            title('Eye positions X/Y (pixels)');
            plot(rawCalibrationData.LeftX_UNCALIBRATED,rawCalibrationData.LeftY_UNCALIBRATED,'.');
            plot(rawCalibrationData.RightX_UNCALIBRATED,rawCalibrationData.RightY_UNCALIBRATED,'.');
            
            subplot(4,3,3,'nextplot','add')
            title('Eye positions in time');
            plot(t,rawCalibrationData.LeftX_UNCALIBRATED);
            plot(t,rawCalibrationData.RightX_UNCALIBRATED);
            plot(t,rawCalibrationData.LeftY_UNCALIBRATED);
            plot(t,rawCalibrationData.RightY_UNCALIBRATED);
            plot(t,targetPosition.x);
            plot(t,targetPosition.y);
            
            x = [-30 30];
            y = [-22 22];
            subplot(4,3,4,'nextplot','add')
            title('Horizontal target vs eye pos. (deg)');
            h1 = plot(targetPosition.x+randn(size(t))/5,rawCalibrationData.LeftX_UNCALIBRATED,'.');
            h2 = plot(targetPosition.x+randn(size(t))/5,rawCalibrationData.RightX_UNCALIBRATED,'.');
            line(x,calibrationCoefficients.OffsetX('LeftEye')+calibrationCoefficients.GainX('LeftEye')*x,'color',get(h1,'color'));
            line(x,calibrationCoefficients.OffsetX('RightEye')+calibrationCoefficients.GainX('RightEye')*x,'color',get(h2,'color'));
            
            subplot(4,3,5,'nextplot','add')
            title('Vertical target vs eye pos. (deg)');
            h1 = plot(targetPosition.y+randn(size(t))/5,rawCalibrationData.LeftY_UNCALIBRATED,'.');
            h2 = plot(targetPosition.y+randn(size(t))/5,rawCalibrationData.RightY_UNCALIBRATED,'.');
            line(y,calibrationCoefficients.OffsetY('LeftEye')+calibrationCoefficients.GainY('LeftEye')*y,'color',get(h1,'color'));
            line(y,calibrationCoefficients.OffsetY('RightEye')+calibrationCoefficients.GainY('RightEye')*y,'color',get(h2,'color'));
            
            subplot(4,3,6,'nextplot','add')
            title('Targets and eye positions X/Y (deg)');
            plot(calibratedCalibrationData.LeftX(~isnan(targetPosition.x)),calibratedCalibrationData.LeftY(~isnan(targetPosition.x)),'.','markersize',1)
            plot(calibratedCalibrationData.RightX(~isnan(targetPosition.x)),calibratedCalibrationData.RightY(~isnan(targetPosition.x)),'.','markersize',1)
            plot(targetPosition.x,targetPosition.y,'.','markersize',20,'color','k')
            set(gca,'xlim',x,'ylim',y);
            
            subplot(4,3,[7:9],'nextplot','add')
            plot(t,calibratedCalibrationData.LeftX);
            plot(t,calibratedCalibrationData.RightX);
            plot(t,targetPosition.x,'color','k','linewidth',3)
            set(gca,'ylim',x);
            ylabel('Horizontal (deg)');
            
            subplot(4,3,[10:12],'nextplot','add')
            plot(t,calibratedCalibrationData.LeftY);
            plot(t,calibratedCalibrationData.RightY);
            plot(t,targetPosition.y,'color','k','linewidth',3)
            set(gca,'ylim',y);
            ylabel('Vertical (deg)');
        end

          function PlotCalibrationCR(calibrationCoefficients, rawCalibrationData, calibratedCalibrationData, targetPosition)
            
             lx = rawCalibrationData.LeftX_UNCALIBRATED - rawCalibrationData.LeftCR1X;
             ly = rawCalibrationData.LeftY_UNCALIBRATED - rawCalibrationData.LeftCR1Y;
             rx = rawCalibrationData.RightX_UNCALIBRATED - rawCalibrationData.RightCR1X;
             ry = rawCalibrationData.RightY_UNCALIBRATED - rawCalibrationData.RightCR1Y;
            
            
            figure
            t = calibratedCalibrationData.Time;
            
            subplot(4,3,1,'nextplot','add')
            title('Targets X/Y (deg)');
            plot(targetPosition.x,targetPosition.y,'.')
            
            subplot(4,3,2,'nextplot','add')
            title('Eye positions X/Y (pixels)');
            plot(lx,ly,'.');
            plot(rx,ry,'.');
            
            subplot(4,3,3,'nextplot','add')
            title('Eye positions in time');
            plot(t,lx);
            plot(t,rx);
            plot(t,ly);
            plot(t,ry);
            plot(t,targetPosition.x);
            plot(t,targetPosition.y);
            
            x = [-30 30];
            y = [-22 22];
            subplot(4,3,4,'nextplot','add')
            title('Horizontal target vs eye pos. (deg)');
            h1 = plot(targetPosition.x+randn(size(t))/5,lx,'.');
            h2 = plot(targetPosition.x+randn(size(t))/5,rx,'.');
            line(x,calibrationCoefficients.OffsetX('LeftEye')+calibrationCoefficients.GainX('LeftEye')*x,'color',get(h1,'color'));
            line(x,calibrationCoefficients.OffsetX('RightEye')+calibrationCoefficients.GainX('RightEye')*x,'color',get(h2,'color'));
            
            subplot(4,3,5,'nextplot','add')
            title('Vertical target vs eye pos. (deg)');
            h1 = plot(targetPosition.y+randn(size(t))/5,ly,'.');
            h2 = plot(targetPosition.y+randn(size(t))/5,ry,'.');
            line(y,calibrationCoefficients.OffsetY('LeftEye')+calibrationCoefficients.GainY('LeftEye')*y,'color',get(h1,'color'));
            line(y,calibrationCoefficients.OffsetY('RightEye')+calibrationCoefficients.GainY('RightEye')*y,'color',get(h2,'color'));
            
            subplot(4,3,6,'nextplot','add')
            title('Targets and eye positions X/Y (deg)');
            plot(calibratedCalibrationData.LeftX(~isnan(targetPosition.x)),calibratedCalibrationData.LeftY(~isnan(targetPosition.x)),'.','markersize',1)
            plot(calibratedCalibrationData.RightX(~isnan(targetPosition.x)),calibratedCalibrationData.RightY(~isnan(targetPosition.x)),'.','markersize',1)
            plot(targetPosition.x,targetPosition.y,'.','markersize',20,'color','k')
            set(gca,'xlim',x,'ylim',y);
            
            subplot(4,3,[7:9],'nextplot','add')
            plot(t,calibratedCalibrationData.LeftX);
            plot(t,calibratedCalibrationData.RightX);
            plot(t,targetPosition.x,'color','k','linewidth',3)
            set(gca,'ylim',x);
            ylabel('Horizontal (deg)');
            
            subplot(4,3,[10:12],'nextplot','add')
            plot(t,calibratedCalibrationData.LeftY);
            plot(t,calibratedCalibrationData.RightY);
            plot(t,targetPosition.y,'color','k','linewidth',3)
            set(gca,'ylim',y);
            ylabel('Vertical (deg)');
        end