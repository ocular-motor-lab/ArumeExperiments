classdef OptostaticTorsionVergence < ArumeExperimentDesigns.EyeTracking
    % Stereoacuity_Vergence
    %
    %   Experiment will show dots at different simulated depths, eliciting
    %   different vergence eye movements. Different amounts of simulated
    %   OCR are applied, accounting for complicated geometry with
    %   convergence OCR.
    %
    properties
        targetColor = [255 0 0];
        stimTexture = [];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            %% ADD new options
            dlg.IPD = { 63 '* (mm)' [40 80] }; 
            dlg.StimSizeDeg = { 10 '* (diameter_in_deg)' [0 10000] }; 
            dlg.FixationSpotSize = { 0.2 '* (deg)' [0 5] };
            dlg.InitFixDuration = {2 '* (s)' [0 100] };
            dlg.TimeStimOn = { 10 '* (sec)' [0 60] }; 
            dlg.convergenceAmount = { 20 '* (deg)' [0 60] }; %TODO figure out what that actually means bc something is weird. it's the max we can do anyway but need to find out how much ppl actually converge 
            dlg.StimulusContrast0to100 = {90 '* (%)' [0 100] };
            dlg.BackgroundBrightness = 0;
            
            %% CHANGE DEFAULTS values for existing options
            
            dlg.UseEyeTracker = 1;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber Vergence ImTilt Image GuessedCorrectly'; % which variables to display every trial in the command line separated by spaces
            
            dlg.DisplayOptions.ScreenWidth = { 60 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 33.5 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 57 '* (cm)' [1 3000] };
            dlg.DisplayOptions.StereoMode = { 4 '* (mode)' [0 9] }; 
            dlg.DisplayOptions.SelectedScreen = { 1 '* (screen)' [0 5] };
            
            dlg.HitKeyBeforeTrial = 0;
            dlg.TrialDuration = 16;
            dlg.TrialsBeforeBreak = 33; %150
            dlg.TrialsBeforeCalibration = 100000;
            dlg.TrialAbortAction = 'Repeat';
        end
        
        function trialTable = SetUpTrialTable(this)
            
            %-- condition variables ---------------------------------------
            t = ArumeCore.TrialTableBuilder();
            
            t.AddConditionVariable( 'V', ["p" "c"]); % vergence: parallel or converged, repeated 6x
            t.AddConditionVariable( 'ImTilt', [-30 0 30]);
            %t.AddConditionVariable( 'Image', {'01' '02' '03' '04' '05' '06' '07' '08' '09' '10' '11' '12' '13' '14' '15' '16' '17' '18' '19' '20' '21' '22' '23' '24' '25' '26' '27' '28' '29' '30' '31' '32' '33' '34' '35' '36' '37' '38' '39' '40'} ); 
            %t.AddConditionVariable( 'Image', {'01' '02' '03' '06' '08' '09' '10' '15' '16' '17' '20' '25' '29' '30' '31' '32' '33' '35' '36' '40'}) %20 images
            t.AddConditionVariable( 'Image', {'01' '02' '03' '06' '08' '09' '10' '11' '12' '15' '16' '17' '19' '20' '21' '22' '23' '25' '28' '29' '30' '31' '32' '33' '34' '35' '36' '38' '39' '40'}) %30 images
            
            % Add blocks -- the vergence can change every 15 trials now
            ok=unique(t.ConditionTable.Image);
            if length(ok) ~= 30
                disp('there might be an error!!')
            end
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(1:5)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(6:10)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(11:15)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(16:20)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(21:25)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(26:30)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(1:5)) & t.ConditionTable.V=="c"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(6:10)) & t.ConditionTable.V=="c"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(11:15)) & t.ConditionTable.V=="c"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(16:20)) & t.ConditionTable.V=="c"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(21:25)) & t.ConditionTable.V=="c"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(26:30)) & t.ConditionTable.V=="c"),1)
            
            %t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            %t.AddBlock(find(t.ConditionTable.V=="c"), 1);
            %t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            %t.AddBlock(find(t.ConditionTable.V=="c"), 1);

            trialSequence = 'Random';
            blockSequence =  'Random';
            blockSequenceRepeatitions = 1; % same as dlg.NumberOfRepetitions
            abortAction = 'Repeat';
            trialsPerSession = 100000;
            trialTable = t.GenerateTrialTable(trialSequence, blockSequence,blockSequenceRepeatitions, abortAction,trialsPerSession);
        end
        
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            try
                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;
                Screen('FillRect', graph.window, 0); % not sure if needed
                ShowCursor();
                
                % Loading an image
                test = string(thisTrialData.Image);
                imageFile = fullfile(fileparts(mfilename('fullpath')),[test + ".jpeg"]);
                I = imread(imageFile);
                
                % Settings
                monitorWidthPix     = this.Graph.wRect(3); % bc in stereoMode, this is ONE of the two onscreen wRects
                monitorWidthCm      = this.ExperimentOptions.DisplayOptions.ScreenWidth/2; % so need to divide by 2 here
                monitorDistanceCm   = this.ExperimentOptions.DisplayOptions.ScreenDistance;
                stimSizeDeg         = this.ExperimentOptions.StimSizeDeg;

                % Resizing the image to be our desired size in degrees 
                % non linear aproximation
                stimSizeCm  = 2*tand(stimSizeDeg/2)*monitorDistanceCm;
                stimSizePix = (monitorWidthPix/monitorWidthCm)*stimSizeCm;
                Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                Isquare = imresize(Isquare, [stimSizePix stimSizePix], 'bilinear');
                this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
                
                % Get fixation spot size in pix
                moniterWidth_deg = (atan2d(this.ExperimentOptions.DisplayOptions.ScreenWidth/2, this.ExperimentOptions.DisplayOptions.ScreenDistance)) * 2;
                pixPerDeg = (this.Graph.wRect(3)*2) / moniterWidth_deg;
                fixSizePix = pixPerDeg * this.ExperimentOptions.FixationSpotSize;
                
                % Determine fixation dot location depending on vergence 
                x=(180-this.ExperimentOptions.convergenceAmount)/2;
                displacement_degs = 90-x;
                if thisTrialData.V == "p" || thisTrialData.V == "p1" || thisTrialData.V == "p2" || thisTrialData.V == "p3" || thisTrialData.V == "p4" || thisTrialData.V == "p5" || thisTrialData.V == "p6" || thisTrialData.V == "p7" || thisTrialData.V == "p8" || thisTrialData.V == "p9" || thisTrialData.V == "p10"
                    thisTrialData.Vergence = categorical("parallel");
                    fixXPix_LE = this.Graph.wRect(3)/2; % center coord
                    fixYPix_LE = this.Graph.wRect(4)/2; % center coord
                    fixXPix_RE=fixXPix_LE;  % same for the right eye
                    fixYPix_RE=fixYPix_LE;
                    x_top_left_LE = (this.Graph.wRect(3)/2) - (size(Isquare,1))/2;
                    x_top_left_RE = x_top_left_LE;
                    
                elseif thisTrialData.V == "c" || thisTrialData.V == "c1" || thisTrialData.V == "c2" || thisTrialData.V == "c3" || thisTrialData.V == "c4" || thisTrialData.V == "c5" || thisTrialData.V == "c6"|| thisTrialData.V == "c7" || thisTrialData.V == "c8" || thisTrialData.V == "c9" || thisTrialData.V == "c10"
                    thisTrialData.Vergence = categorical("converged");
                    fixXPix_RE = tand(displacement_degs) * this.ExperimentOptions.DisplayOptions.ScreenDistance * (this.Graph.wRect(3)/(this.ExperimentOptions.DisplayOptions.ScreenWidth/2));
                    fixYPix_RE = this.Graph.wRect(4)/2;
                    fixXPix_LE = this.Graph.wRect(3)/2 + (this.Graph.wRect(3)/2-fixXPix_RE);
                    fixYPix_LE = this.Graph.wRect(4)/2;
                    x_top_left_RE = (tand(displacement_degs) * this.ExperimentOptions.DisplayOptions.ScreenDistance * (this.Graph.wRect(3)/(this.ExperimentOptions.DisplayOptions.ScreenWidth/2))) - (size(Isquare,2))/2;
                    x_top_left_LE = fixXPix_LE - (size(Isquare,1)/2);
                end
                y_top_left = (this.Graph.wRect(4)/2) - (size(Isquare,2))/2;
                
                % For the while loop trial start
                lastFlipTime                        = Screen('Flip', graph.window);
                secondsRemaining                    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop         = lastFlipTime;

                %initialize this
                initialFixationDuration = this.ExperimentOptions.InitFixDuration;
                
                while secondsRemaining > 0

                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;

                    if thisTrialData.TrialNumber > 1
                        % If it's a new block
                        if thisTrialData.Vergence ~= this.Session.currentRun.pastTrialTable.Vergence(thisTrialData.TrialNumber-1)
                            initialFixationDuration = 6;
                        end
                    end

                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------


                    % If it's during the time when the stimulus is on, then show the stimulus plus the fixation dot
                    if ( secondsElapsed > initialFixationDuration && secondsElapsed < initialFixationDuration + this.ExperimentOptions.TimeStimOn) % then show dots + fixation dot

                        % Draw left stim:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[x_top_left_LE y_top_left x_top_left_LE+size(Isquare,1) y_top_left+size(Isquare,2)],thisTrialData.ImTilt); % https://yun-weidai.com/post/ptb-draw-image/
                        Screen('DrawDots', this.Graph.window, [fixXPix_LE; fixYPix_LE], fixSizePix, this.targetColor, [], 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);

                        % Draw right stim:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[x_top_left_RE y_top_left x_top_left_RE+size(Isquare,1) y_top_left+size(Isquare,2)],thisTrialData.ImTilt); 
                        Screen('DrawDots', this.Graph.window, [fixXPix_RE; fixYPix_RE], fixSizePix, this.targetColor, [], 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);

                    % Any other time, just show the fixation dot
                    elseif ( secondsElapsed < initialFixationDuration )
                        % Draw left stim:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        %Screen('DrawDots', this.Graph.window, [0; 0], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('DrawDots', this.Graph.window, [fixXPix_LE; fixYPix_LE], fixSizePix, this.targetColor, [], 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);

                        % Draw right stim:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        Screen('DrawDots', this.Graph.window, [fixXPix_RE; fixYPix_RE], fixSizePix, this.targetColor, [], 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);
                    end
                    
                    % Break trial if needed
                    if (secondsElapsed > initialFixationDuration + this.ExperimentOptions.TimeStimOn)
                        break
                    end
                    
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------

                    % FLIP
                    this.Graph.Flip(this, thisTrialData, secondsRemaining);

                    % Break trial when a key is pressed IF the trial is done
                    if secondsElapsed > initialFixationDuration + this.ExperimentOptions.TimeStimOn
                        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                        if ( keyIsDown )
                            break
                        end
                    end
                  
                end

            %trialResult = Enum.trialResult.CORRECT;
                


            catch ex
                rethrow(ex)
            end

        end
        
      
            
             
        
    end

    

    methods
        
        function [out] = Plot_ConstantStim(this)
            %%
            trialTable = this.Session.trialDataTable;
            
            
            trialTable.RespondedFront = ones(size(trialTable,1),1);
            trialTable.RespondedFront(trialTable.Response == 'B') = trialTable.RespondedFront(trialTable.Response == 'B') *0;
            RotateDotsCond = unique(trialTable.RotateDots);
            here=1;
            
                figure
                
                for arotation = 1:length(RotateDotsCond)
                    idxs = find(trialTable.RotateDots == RotateDotsCond(arotation));
                    temp=sortrows(array2table([trialTable.DisparityArcMin(idxs) trialTable.RespondedFront(idxs)],'VariableNames',{'DisparityArcMin','RespondedFront'}));
                    
                    % Fit model
                    modelspec = 'RespondedFront ~ DisparityArcMin';
                    mdl = fitglm(temp(:,{'RespondedFront', 'DisparityArcMin'}), modelspec, 'Distribution', 'binomial');
                    a=[-1:0.01:0, 0.01:0.01:1];
                    p = predict(mdl,a');
                    
                    % Get average response for that disparity
                    temp.meanedResp=zeros(height(temp),1);
                    [uniqueDisparities,~] = unique(temp.DisparityArcMin);
                    for i = 1:length(uniqueDisparities)
                        idxs=find(temp.DisparityArcMin == uniqueDisparities(i));
                        temp.meanedResp(idxs) = mean(temp.RespondedFront(idxs));
                    end
                    
                    % Get the numbers
                    alpha = mdl.Coefficients.Estimate(2);
                    beta=mdl.Coefficients.Estimate(1);
                    p1=0.5;
                    x1 = (log(p1/(1-p1))-beta)/alpha; %PSE % log(p/1-p) = ax+b where we know p and a and b and are trying to get x.
                    p2=.25;
                    x2 = (log(p2/(1-p2))-beta)/alpha;
                    p3=.75;
                    x3 = (log(p3/(1-p3))-beta)/alpha;
                    slope = (p3-p2) / (x3-x2);
                    threshold=(x3-x2)/2;
                  
                    % Plot
                    subplot(1,(length(RotateDotsCond)),arotation)
                    plot(a,p) % plot prediction
                    hold on;
                    plot(temp.DisparityArcMin,temp.meanedResp,'o'); hold on
                    ylim([0 1])
                    xlabel('Disparity (arcmin)')
                    ylabel('Proportion Front')
                    %text(min(xlim)+0.05, max(ylim)-0.1, sprintf('PSE: %.2f', x1), 'Horiz','left', 'Vert','bottom')
                    text(min(xlim)+0.05, max(ylim)-0.1, sprintf('Slope: %.2f', slope), 'Horiz','left', 'Vert','bottom')
                    text(min(xlim)+0.05, max(ylim)-0.15, sprintf('Threshold(arcmin): %.2f', threshold), 'Horiz','left', 'Vert','bottom')
                    title(sprintf('Rotation: %s',string(RotateDotsCond(arotation))))
                    
                    here=here+1;
                end
            



        end
    end
end