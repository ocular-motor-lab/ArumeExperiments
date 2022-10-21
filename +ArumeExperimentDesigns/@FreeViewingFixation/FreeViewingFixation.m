classdef FreeViewingFixation < ArumeExperimentDesigns.EyeTracking
    %Illusory tilt Summary of this class goes here
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
            
            dlg.NumberOfRepetitions = {1 '* (N)' [1 100] };
                         
            dlg.TargetSize = {0.5 '* (deg)' [0.1 10]};
            
            dlg.BackgroundBrightness = 0;
            
            dlg.StimulusContrast0to100 = {60 '* (%)' [0 100] };
            dlg.StimSizeDeg = {20 '* (deg)' [1 100] };
            dlg.ImTilt = {30 '* (deg)' [0 90] };
            
            dlg.Initial_Fixation_Duration = {2 '* (s)' [1 100] };
            
            dlg.TrialDuration = {12 '* (s)' [1 100] };
            dlg.HitKeyBeforeTrial = { {'0' '{1}'} };
            dlg.TrialsBeforeBreak = 40;

            % Change the defaults for the screen parameters
            dlg.DisplayOptions.ScreenWidth = { 144 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 80 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 90 '* (cm)' [1 3000] };
            
        end
        
        % Set up the trial table when a new session is created
        function trialTable = SetUpTrialTable( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Image';
            %conditionVars(i).values = {'Im01' 'Im02' 'Im03' 'Im04' 'Im05'
            %'Im06' 'Im07' 'Im08' 'Im09' 'Im10' 'Im11' 'Im12' 'Im13' 'Im14'
            %'Im15' 'Im16' 'Im17' 'Im18' 'Im19' 'Im20' 'Im21' 'Im22'
            %'Im23'}; % pilot study
            conditionVars(i).values = {'01' '02' '03' '04' '05' '06' '07' '08' '09' '10' '11' '12' '13' '14' '15' '16' '17' '18' '19' '20' '21' '22' '23' '24' '25' '26' '27' '28' '29' '30' '31' '32' '33' '34' '35' '36' '37' '38' '39' '40'};
            
            i = i+1;
            conditionVars(i).name   = 'ImTilt';
            conditionVars(i).values = [-1 0 1] * this.ExperimentOptions.ImTilt;
            
            i = i+1;
            conditionVars(i).name   = 'Task';
            conditionVars(i).values = {'FreeView' 'Fixation'};
            
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
            
            % JORGE AT THE MEETING
            %experimentFolder = fileparts(mfilename('fullpath'));
            %imageFile = fullfile(experimentFolder,[thisTrialData.Image '.jpg']);
            % END JORGE
            test = string(thisTrialData.Image);
            imageFile = fullfile(fileparts(mfilename('fullpath')),[test + ".jpeg"]);
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
            %stimSizePix = stimSizeCm/monitorWidthCm*monitorWidthPix;
            stimSizePix = (monitorWidthPix/monitorWidthCm)*stimSizeCm

            Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
            Isquare = imresize(Isquare, [stimSizePix stimSizePix], 'bilinear');
            this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
            
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
                fixRect = [0 0 10 10];
                fixRect = CenterRectOnPointd( fixRect, mx, my );

                if ( secondsElapsed <= this.ExperimentOptions.Initial_Fixation_Duration )
                    %-- Draw target
                    % These commands are for the fixation dot
                    Screen('FillOval', graph.window,  this.targetColor, fixRect);
                end

                if ( secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration )
                    Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],thisTrialData.ImTilt);

                    switch (thisTrialData.Task)
                        case 'Fixation'
                            Screen('FillOval', graph.window,  this.targetColor, fixRect);
                        case 'FreeView'
                    end
                end
                        
                this.Graph.Flip(this, thisTrialData, secondsRemaining);
                % -----------------------------------------------------------------
                % --- END Drawing of stimulus -------------------------------------
                % -----------------------------------------------------------------
                
                
            end
            
            trialResult = Enum.trialResult.CORRECT;


            % After every 40 trials, quit (in order to do calibration)
            if mod(thisTrialData.TrialNumber, 2) == 0
                sca;
            end

        end
          
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )

        function [out] = Plot_Stephanie(this)
            tt = this.Session.trialDataTable;
            ss = this.Session.samplesDataTable;
            rr = this.Session.analysisResults;

            binsize = 10;
            binedges = [0:binsize:360]/180*pi;
            bincenters = [-binsize/2:binsize:360]/180*pi;

            AnalysisResults_QuickPhases= rr.QuickPhases;

            f = figure;
            h1 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == -30 & AnalysisResults_QuickPhases.Task == "Fixation" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test1 = h1.Values
            h2 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == 0 & AnalysisResults_QuickPhases.Task == "Fixation" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test2 = h2.Values
            h3 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == 30 & AnalysisResults_QuickPhases.Task == "Fixation" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test3 = h3.Values
            h4 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == -30 & AnalysisResults_QuickPhases.Task == "FreeView" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test4 = h4.Values
            h5 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == 0 & AnalysisResults_QuickPhases.Task == "FreeView" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test5 = h5.Values
            h6 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == 30 & AnalysisResults_QuickPhases.Task == "FreeView" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test6 = h6.Values

            close(f);

            figure
            subplot(2,3,1)
            polarplot(binedges,[test1 test1(1)],'LineWidth',2, 'Color', 'black')
            title('-30 Images')
            subplot(2,3,2)
            polarplot(binedges,[test2 test2(1)],'LineWidth',2, 'Color', 'black')
            title('0 Images')
            subplot(2,3,3)
            polarplot(binedges,[test3 test3(1)],'LineWidth',2, 'Color', 'black')
            title('30 Images')
            subplot(2,3,4)
            polarplot(binedges,[test4 test4(1)],'LineWidth',2, 'Color', 'black')
            subplot(2,3,5)
            polarplot(binedges,[test5 test5(1)],'LineWidth',2, 'Color', 'black')
            subplot(2,3,6)
            polarplot(binedges,[test6 test6(1)],'LineWidth',2, 'Color', 'black')
        end

        function [out] = Plot_XY(this)
            tt = this.Session.trialDataTable;
            ss = this.Session.samplesDataTable;
            rr = this.Session.analysisResults;

            figure

            h = [];
            for i=1:2
                for j=1:3
                    h(i,j) = subplot(2,3,j+(i-1)*3,'nextplot','add');
                    set(gca,'xlim',[-30 30])
                    set(gca,'ylim',[-25 25])
                end
            end

            for i=1:height(tt)
                idx = tt.SampleStartTrial(i):tt.SampleStopTrial(i);
                ssTrial = ss(idx,:);

                switch(tt.Task(i))
                    case 'Fixation'
                        row = 1;
                    case 'FreeView'
                        row = 2;
                end
                switch(tt.ImTilt(i))
                    case -30
                        col = 1;
                    case 0
                        col = 2;
                    case 30
                        col = 3;
                end


                plot(h(row,col), ssTrial.RightX-median(ssTrial.RightX(1:500)), ssTrial.RightY-median(ssTrial.RightY(1:500)),'.');
            end
        end
    end
end