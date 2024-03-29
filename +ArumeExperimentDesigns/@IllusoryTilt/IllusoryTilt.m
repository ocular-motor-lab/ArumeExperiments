classdef IllusoryTilt < ArumeExperimentDesigns.EyeTracking
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
            
            dlg.NumberOfRepetitions = {8 '* (N)' [1 100] };
                         
            dlg.TargetSize = 0.5;
            
            dlg.BackgroundBrightness = 0;
            
            dlg.StimulusContrast0to100 = {10 '* (%)' [0 100] };
            dlg.SmallTilt = {4 '* (deg)' [0 90] };
            dlg.LargeTilt = {30 '* (deg)' [0 90] };
            
            dlg.Initial_Fixation_Duration = {5 '* (s)' [1 100] };
            
            dlg.TrialDuration = {20 '* (s)' [1 100] };
            dlg.HitKeyBeforeTrial = { {'0' '{1}'} };
        end
        
        % Set up the trial table when a new session is created
        function trialTable = SetUpTrialTable( this )
            %-- condition variables ---------------------------------------
            i= 0;
                                    
            i = i+1;
            conditionVars(i).name   = 'Image';
            %adding the non-illusory patterned image to line 40 condition variables  
            conditionVars(i).values = {'IlusoryTiltRight' 'IllusoryTiltLeft' 'RealSmallTiltLeft' 'RealSmallTiltRight' 'RealLargeTiltLeft' 'RealLargeTiltRight' 'NonIlusoryTiltRight' 'NonIllusoryTiltLeft'};
          
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Delay';
            trialTableOptions.trialsPerSession = 100;
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end
        
        
        function [trialResult, thisTrialData] = runPreTrial( this, thisTrialData )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
            
            switch(thisTrialData.Image)
                case 'IlusoryTiltRight'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'TiltWithBlur.tiff'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
                    
                case 'IllusoryTiltLeft'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'TiltWithBlur.tiff'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare(end:-1:1,:,:));
                case 'RealSmallTiltLeft'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'NaturalImage.jpg'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
                case 'RealSmallTiltRight'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'NaturalImage.jpg'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
                case 'RealLargeTiltLeft'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'NaturalImage.jpg'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
                case 'RealLargeTiltRight'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'NaturalImage.jpg'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
                case 'NonIlusoryTiltRight'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'NonTilt.tiff'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare(end:-1:1,:,:));
                    
                case 'NonIllusoryTiltLeft'
                    I = imread(fullfile(fileparts(mfilename('fullpath')),'NonTilt.tiff'));
                    Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                    Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');
                    
                    this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
            end
            
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
                                
                if ( secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration )
                    switch(thisTrialData.Image)
                        case 'IlusoryTiltRight'
                            Screen('DrawTexture', this.Graph.window, this.stimTexture);
                        case 'IllusoryTiltLeft'
                            Screen('DrawTexture', this.Graph.window, this.stimTexture);
                        case 'RealSmallTiltLeft'
                            Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],-this.ExperimentOptions.SmallTilt);
                        case 'RealSmallTiltRight'
                            Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],this.ExperimentOptions.SmallTilt);
                        case 'RealLargeTiltLeft'
                            Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],-this.ExperimentOptions.LargeTilt);
                        case 'RealLargeTiltRight'
                            Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],this.ExperimentOptions.LargeTilt);
                        case 'NonIlusoryTiltRight'
                            Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],-this.ExperimentOptions.SmallTilt);
                        case 'NonIllusoryTiltLeft'
                            Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[],this.ExperimentOptions.SmallTilt);
                    end
                end
                
                %-- Draw target
                
                
                fixRect = [0 0 10 10];
                fixRect = CenterRectOnPointd( fixRect, mx, my );
                Screen('FillOval', graph.window,  this.targetColor, fixRect);
                
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