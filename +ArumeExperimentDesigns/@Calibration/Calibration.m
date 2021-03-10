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
             
            dlg.ScreenWidth = { 121 '* (cm)' [1 3000] };
            dlg.ScreenHeight = { 68 '* (cm)' [1 3000] };
            dlg.ScreenDistance = { 60 '* (cm)' [1 3000] };
                      
            dlg.Trial_Duration =  { 30 '* (s)' [1 100] };
            
            dlg.TargetSize = 0.5;
            
            dlg.BackgroundBrightness = 0;
        end
        
        function initExperimentDesign( this  )
            this.DisplayVariableSelection = {'TrialNumber' 'TrialResult' 'Speed' 'Stimulus'};
        
            this.HitKeyBeforeTrial = 1;
            this.BackgroundColor = this.ExperimentOptions.BackgroundBrightness;
            
            this.trialDuration = this.ExperimentOptions.Trial_Duration; %seconds
            
            this.trialsBeforeBreak = 15;
                
            % default parameters of any experiment
            this.trialAbortAction = 'Delay';     % Repeat, Delay, Drop
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, ...
            
            this.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            this.trialsPerSession = this.NumberOfConditions;
            this.numberOfTimesRepeatBlockSequence  = 1;
            this.blocksToRun = 1;
            this.blocks = struct( 'fromCondition', 1, 'toCondition', this.NumberOfConditions, 'trialsToRun', this.NumberOfConditions  );
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Position';
            conditionVars(i).values = 0;
        end
        
    end
    
    methods ( Access = public )
         function [analysisResults, samplesDataTable, trialDataTable, sessionDataTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable, sessionDataTable, options)
             
             [analysisResults, samplesDataTable, trialDataTable, sessionDataTable]  = RunDataAnalyses@ArumeExperimentDesigns.EyeTracking(this, analysisResults, samplesDataTable, trialDataTable, sessionDataTable, options);
             x = atand(30/60);
             y = atand(17/60);
             calibrationPointsX = [0, -x , x, 0 , 0 ];
             calibrationPointsY = [0, 0 , 0, y , -y ];
             
             f = samplesDataTable.Fixations;
             fstart = find(diff([f;0])>0);
             fstops = find(diff([0;f])<0);
             
             t = nan(size(f,1),2);
             
             for i=1:length(fstart)
                 t(fstart(i):fstops(i),1) = calibrationPointsX(i);
                 t(fstart(i):fstops(i),2) = calibrationPointsY(i);
             end
             %
             %                           rawCalibrationData = table();
             %                           rawCalibrationData.LeftX = samplesDataTable.LeftRawX;
             %                           rawCalibrationData.LeftY = samplesDataTable.LeftRawY;
             %                           rawCalibrationData.RightX = samplesDataTable.RightRawX;
             %                           rawCalibrationData.RightY = samplesDataTable.RightRawY;
             %
             %
             targetPosition = table();
             targetPosition.x = t(:,1);
             targetPosition.y = t(:,2);
             targetPosition.LeftX = t(:,1);
             targetPosition.LeftY = t(:,2);
             targetPosition.RightX = t(:,1);
             targetPosition.RightY = t(:,2);
             
             analysisResults.calibrationTable = VOGAnalysis.CalculateCalibration(samplesDataTable, targetPosition);
             
             calibratedCalibrationData   = VOGAnalysis.CalibrateData(samplesDataTable, analysisResults.calibrationTable);
             
             PlotCalibration(analysisResults.calibrationTable, samplesDataTable, calibratedCalibrationData, targetPosition)
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
            plot(rawCalibrationData.LeftX,rawCalibrationData.LeftY,'.');
            plot(rawCalibrationData.RightX,rawCalibrationData.RightY,'.');
            
            subplot(4,3,3,'nextplot','add')
            title('Eye positions in time');
            plot(t,rawCalibrationData.LeftX);
            plot(t,rawCalibrationData.RightX);
            plot(t,rawCalibrationData.LeftY);
            plot(t,rawCalibrationData.RightY);
            plot(t,targetPosition.x);
            plot(t,targetPosition.y);
            
            x = [-30 30];
            y = [-17 17];
            subplot(4,3,4,'nextplot','add')
            title('Horizontal target vs eye pos. (deg)');
            h1 = plot(targetPosition.x+randn(size(t))/5,rawCalibrationData.LeftX,'.');
            h2 = plot(targetPosition.x+randn(size(t))/5,rawCalibrationData.RightX,'.');
            line(x,calibrationCoefficients.OffsetX('LeftEye')+calibrationCoefficients.GainX('LeftEye')*x,'color',get(h1,'color'));
            line(x,calibrationCoefficients.OffsetX('RightEye')+calibrationCoefficients.GainX('RightEye')*x,'color',get(h2,'color'));
            
            subplot(4,3,5,'nextplot','add')
            title('Vertical target vs eye pos. (deg)');
            h1 = plot(targetPosition.y+randn(size(t))/5,rawCalibrationData.LeftY,'.');
            h2 = plot(targetPosition.y+randn(size(t))/5,rawCalibrationData.RightY,'.');
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