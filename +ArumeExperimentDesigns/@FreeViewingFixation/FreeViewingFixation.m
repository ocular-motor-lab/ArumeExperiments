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
                         
            dlg.TargetSize = 0.5;
            
            dlg.BackgroundBrightness = 0;
            
            dlg.StimulusContrast0to100 = {100 '* (%)' [0 100] };
            dlg.ImTilt = {30 '* (deg)' [0 90] };
            
            dlg.Initial_Fixation_Duration = {2 '* (s)' [1 100] };
            
            dlg.TrialDuration = {12 '* (s)' [1 100] };
            dlg.HitKeyBeforeTrial = { {'0' '{1}'} };
        end
        
        % Set up the trial table when a new session is created
        function trialTable = SetUpTrialTable( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Image';
            conditionVars(i).values = {'Im1' 'Im2' 'Im3' 'Im4' 'Im5' 'Im6' 'Im7' 'Im8' 'Im9' 'Im10' 'Im11' 'Im12' 'Im13' 'Im14' 'Im15' 'Im16' 'Im17' 'Im18' 'Im19' 'Im20' 'Im21' 'Im22' 'Im23' 'Im24'};
            
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
            test = string(thisTrialData.Image)
            imageFile = fullfile(fileparts(mfilename('fullpath')),[test + ".jpeg"]);
            I = imread(imageFile);
            
            Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
            Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
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
                    hScreen('FillOval', graph.window,  this.targetColor, fixRect);
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
        end
          
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )

        function [outt] = Plot_Stephanie(this)
            tt = this.Session.trialDataTable;
            ss = this.Session.samplesDataTable;
            rr = this.Session.analysisResults;

            figure
            polarhistogram(r.QuickPhases.Direction,36)
        end

        function [out] = Plot_Torsion_by_image(this)
            %%
            t = this.Session.trialDataTable;
            s = this.Session.samplesDataTable;
            
            conditions ={};
            conditions{1,1} = 'IllusoryTiltLeft';
            conditions{1,2} = 'IlusoryTiltRight';
            
            conditions{2,1} = 'NonIlusoryTiltRight';
            conditions{2,2} = 'NonIllusoryTiltLeft';
            
            conditions{3,1} = 'RealSmallTiltLeft'; 
            conditions{3,2} = 'RealSmallTiltRight'; 
            
            conditions{4,1} = 'RealLargeTiltLeft';
            conditions{4,2} = 'RealLargeTiltRight';
            
            % adding the non-illusory stimuli to the plot methods
            

            
            trialTorsion = nan(4,2,10,1000);
            
            for i=1:size(conditions,1)
                for j=1:2
                    trials = t(t.Image==conditions{i,j},:);
                    for itrial = 1:height(trials)
                        trialIdx = trials.SampleStartTrial(itrial):trials.SampleStopTrial(itrial);
                        torsionLeft = s.LeftT(trialIdx);
                        torsionRight = s.RightT(trialIdx);
                        
                        torsion = nanmedfilt(mean([torsionLeft, torsionRight],2,'omitnan'),100,1/2);
                        torsion = torsion - mean(torsion(1:1000),'omitnan');
                    
                        if ( length(torsion)>10000)
                            torsion = torsion(1:10000);
                        end
                        trialTorsion(i,j,itrial,1:length(torsion)) = torsion;
                    end
                end
            end
            
            %%
            time = 0:0.002:20;
            time = time(1:end-1);
            figure

            
            
            subplot(2,4,1);
            plot(time, squeeze(trialTorsion(1,1,:,:))','b');
            hold
            plot(time, squeeze(trialTorsion(1,2,:,:))','r');
            title('Illusory tilt')
            
            subplot(2,4,2);
            plot(time, squeeze(trialTorsion(2,1,:,:))','b');
            hold
            plot(time, squeeze(trialTorsion(2,2,:,:))','r');
            title('NonIllusory tilt small')
            
            subplot(2,4,3);
            plot(time, squeeze(trialTorsion(3,1,:,:))','b');
            hold
            plot(time, squeeze(trialTorsion(3,2,:,:))','r');
            title('Real tilt small')
               
            subplot(2,4,4);
            plot(time, squeeze(trialTorsion(4,1,:,:))','b');
            hold
            plot(time, squeeze(trialTorsion(4,2,:,:))','r');
            title('Real tilt large')
           
            subplot(2,4,5);
            plot(time, mean(squeeze(trialTorsion(1,1,:,:)),'omitnan'),'b');
            hold
            plot(time, mean(squeeze(trialTorsion(1,2,:,:)),'omitnan'),'r');
            title('Illusory tilt (avg.)')
            
            subplot(2,4,6);
            plot(time, mean(squeeze(trialTorsion(2,1,:,:)),'omitnan'),'b');
            hold
            plot(time, mean(squeeze(trialTorsion(2,2,:,:)),'omitnan'),'r');
            title('NonIllusory tilt (avg.)')
            
            subplot(2,4,7);
            plot(time, mean(squeeze(trialTorsion(3,1,:,:)),'omitnan'),'b');
            hold
            plot(time, mean(squeeze(trialTorsion(3,2,:,:)),'omitnan'),'r');
            title('Real tilt small (avg.)')
            
            subplot(2,4,8);
            plot(time, mean(squeeze(trialTorsion(4,1,:,:)),'omitnan'),'b');
            hold
            plot(time, mean(squeeze(trialTorsion(4,2,:,:)),'omitnan'),'r');
            title('Real tilt large (avg.)')
            
            
            set(get(gcf,'children'),'ylim',[-1 1])
            
            ylabel('Torsion (deg)');
            xlabel('Time (s)');
            legend({'left tilt','right tilt'});
        end
    end
end