classdef Stereoacuity_Vergence < ArumeExperimentDesigns.EyeTracking
    % Stereoacuity_Vergence
    %
    %   Experiment will show dots at different simulated depths, eliciting
    %   different vergence eye movements. Different amounts of simulated
    %   OCR are applied, accounting for complicated geometry with
    %   convergence OCR.
    %
    properties
        targetColor = [150 150 150];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            %% ADD new options
            dlg.IPD = { 61 '* (mm)' [40 80] }; 
            dlg.Practice = { 0 '* (1 or 0)' [0 1] }; 
            dlg.Number_of_Dots = { 750 '* (num)' [10 10000] }; %750
            dlg.FixationSpotSize = { 0.25 '* (diameter_in_deg)' [0 5] };
            dlg.TimeStimOn = { 0.3 '* (sec)' [0 60] }; %0.3
            dlg.InitFixDuration = { 1 '* (sec)' [0 60] };
            dlg.BackgroundBrightness = 0;
            
            %% CHANGE DEFAULTS values for existing options
            
            dlg.UseEyeTracker = 1; % this will automatically get set to 0 if you're doing practice
            dlg.Debug.DisplayVariableSelection = 'TrialNumber Vergence RotateDots DisparityArcMin GuessedCorrectly'; % which variables to display every trial in the command line separated by spaces
            
            dlg.DisplayOptions.ScreenWidth = { 60 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 33.5 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 57 '* (cm)' [1 3000] };
            dlg.DisplayOptions.StereoMode = { 4 '* (mode)' [0 9] }; 
            dlg.DisplayOptions.SelectedScreen = { 1 '* (screen)' [0 5] };
            
            dlg.HitKeyBeforeTrial = 0;
            dlg.TrialDuration = 90;
            dlg.TrialsBeforeBreak = 150; %150
            dlg.TrialsBeforeCalibration = 100000;
            dlg.TrialAbortAction = 'Repeat';
        end
        
        function trialTable = SetUpTrialTable(this)
            
            %-- condition variables ---------------------------------------
            t = ArumeCore.TrialTableBuilder();
            
            t.AddConditionVariable( 'V', ["p" "c"]); 
            if this.ExperimentOptions.Practice == 0
                t.AddConditionVariable( 'RotateDots', [-30 -10 -5 0 0 5 10 30]);
            elseif this.ExperimentOptions.Practice == 1
                t.AddConditionVariable( 'RotateDots', [0]);
                this.ExperimentOptions.UseEyeTracker = 0; % no need for eye tracking w/ practice!
            end
            %t.AddConditionVariable( 'Disparities', [-1.6 -1.2 -0.8 -0.4 0.4 0.8 1.2 1.6 ]); % arcmins
            t.AddConditionVariable( 'Disparities', [-1.2 -0.9 -0.6 -0.3 0.3 0.6 0.9 1.2 ]); % arcmins

            % Add three blocks. One with all the upright trials, one with the rest,
            % and another one with upright trials. Running only one repeatition of
            % each upright trial and 3 repeatitions of the other trials,
            t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c"), 1);

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
                Screen('FillRect', graph.window, 0.5); % not sure if needed
                ShowCursor();
                
                % Prepare some settings to get the dots
                SizeCm = [this.ExperimentOptions.DisplayOptions.ScreenWidth/2 this.ExperimentOptions.DisplayOptions.ScreenHeight]; % FOR ONE OF THE TWO STEREO SCREENS
                ResPix = this.Graph.wRect(3:4); % automatically one of the two screens 
                ScreenDistance = this.ExperimentOptions.DisplayOptions.ScreenDistance;
                ScreenSlant = 0;
                IPDMm = this.ExperimentOptions.IPD;
                FixationSpot = [];
                FixationSpot.X = 0;
                FixationSpot.Y = 0;
                TorsionVergence = 0;
                PlaneTilt = 0;
                PlaneSlant = 0;
                numDots = this.ExperimentOptions.Number_of_Dots;
                if thisTrialData.V == "p" 
                    FixationSpot.Z = 200; % fixation spot distance in cm
                    sizeStimCm = 13; %13
                    thisTrialData.Vergence = categorical("parallel");
                elseif thisTrialData.V == "c"
                    FixationSpot.Z = 30; % fixation spot distance in cm
                    sizeStimCm = 2; %2
                    thisTrialData.Vergence = categorical("converged");
                end
                minsizeStimCm = sizeStimCm/4;
                
                % Calculate the simulated stimulus distance based on the
                % desired rough disparity
                disparities_rad = deg2rad(thisTrialData.Disparities/60);
                z0 = FixationSpot.Z / 100; % meters
                ipd = this.ExperimentOptions.IPD / 1000; % meters
                StimulusDistance = 1 / ((1/z0) - (disparities_rad/ipd));
                
                % Add to trial table
                thisTrialData.SimFixationDist =  FixationSpot.Z; % cm
                thisTrialData.SimStimulusDist =  StimulusDistance*100; %cm
                thisTrialData.DisparityArcMin = -thisTrialData.Disparities;
                
                % Make world points
                worldPoints = table();
                worldPoints.X = rand(numDots,1)*sizeStimCm - (sizeStimCm/2);
                worldPoints.Y = rand(numDots,1)*sizeStimCm - (sizeStimCm/2);
                worldPoints.Z = zeros(numDots, 1);
                
                % Resample points that outsie of the radius
                worldPoints.EucDist=sqrt(worldPoints.X.^2+worldPoints.Y.^2);
                while sum(worldPoints.EucDist>sizeStimCm/2) > 0 || sum(worldPoints.EucDist<minsizeStimCm/2) > 0
                    idxs=find(worldPoints.EucDist>sizeStimCm/2 | worldPoints.EucDist<minsizeStimCm/2);
                    worldPoints.X(idxs) = rand(length(idxs),1)*sizeStimCm - (sizeStimCm/2);
                    worldPoints.Y(idxs) = rand(length(idxs),1)*sizeStimCm - (sizeStimCm/2);
                    worldPoints.Z(idxs) = zeros(length(idxs), 1);
                    worldPoints.EucDist=sqrt(worldPoints.X.^2+worldPoints.Y.^2);
                end
                worldPoints = removevars(worldPoints, 'EucDist');
                
                % Rotate by slant and tilt
                R = Geometry3D.Quat2RotMat(Geometry3D.AxisAngle2Quat([cosd(PlaneTilt) sind(PlaneTilt) 0],deg2rad(PlaneSlant)));
                worldPoints{:,:} = (R*worldPoints{:,:}')';
                % Displace by distance
                worldPoints.Z = worldPoints.Z + thisTrialData.SimStimulusDist;

                % Add the fixation spot point to the world points 
                worldPoints=vertcat(worldPoints,array2table([0 0 FixationSpot.Z],'VariableNames',{'X','Y','Z'}));
                % end make world points
                
                % Convert points to in eye points and then to on screen points
                leftEyeScreen = Geometry3D.MakeScreen(SizeCm, ResPix, ScreenDistance, ScreenSlant);
                rightEyeScreen = Geometry3D.MakeScreen(SizeCm, ResPix, ScreenDistance, ScreenSlant);
                eyes = Geometry3D.MakeEyes(IPDMm/10, FixationSpot, thisTrialData.RotateDots, TorsionVergence);
                eyePoints = Geometry3D.Points3DToEyes(worldPoints, eyes);
                screenPoints = Geometry3D.PointsEyesToScreen(eyes, eyePoints, leftEyeScreen, rightEyeScreen);
                
                % Make the screen points work for our screen where (0,0)
                % is the center of the screen
                screenPoints.RX=screenPoints.RX-rightEyeScreen.middleX;
                screenPoints.RY=screenPoints.RY-rightEyeScreen.middleY;
                screenPoints.LX=screenPoints.LX-leftEyeScreen.middleX;
                screenPoints.LY=screenPoints.LY-leftEyeScreen.middleY;

                % figure
                % plot(screenPoints.RX,screenPoints.RY,'o','Color','r'); hold on
                % plot(screenPoints.LX,screenPoints.LY,'o','Color','b');
                % 
                % figure
                % plot(eyePoints.RH,eyePoints.RV,'o','Color','r'); hold on
                % plot(eyePoints.LH,eyePoints.LV,'o','Color','b'); 

                % Get fixation spot size in pix
                moniterWidth_deg = (atan2d(this.ExperimentOptions.DisplayOptions.ScreenWidth/2, this.ExperimentOptions.DisplayOptions.ScreenDistance)) * 2;
                pixPerDeg = (this.Graph.wRect(3)*2) / moniterWidth_deg;
                fixSizePix = pixPerDeg * this.ExperimentOptions.FixationSpotSize;
                
                % What the response should be
                if thisTrialData.DisparityArcMin > 0
                    thisTrialData.CorrectResponse = 'F';
                elseif thisTrialData.DisparityArcMin < 0
                    thisTrialData.CorrectResponse = 'B';
                end
                
                % For the while loop trial start
                lastFlipTime                        = Screen('Flip', graph.window);
                secondsRemaining                    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop         = lastFlipTime;

                %initialize this
                response = []; 
                sizeOfDots=1; % in pix
                displayGridAndWait = 0;
                initialWaiting = 0;
                if thisTrialData.TrialNumber > 1
                    % If it's a new block or if it's right after a break
                    if (thisTrialData.Vergence ~= this.Session.currentRun.pastTrialTable.Vergence(thisTrialData.TrialNumber-1) || mod(thisTrialData.TrialNumber-1, this.ExperimentOptions.TrialsBeforeBreak) == 0)
                        displayGridAndWait = 1;
                    end
                end
                    

                % If you press space accidentaly instead of responding F/B
                % then the stimulus will just show itself again
                % If you press F/B instead of space (following the grid
                % display), then it will skip to the next trial. This is
                % not ideal so the epxerimenter needs to watch for this.
                while secondsRemaining > 0

                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;

                    if displayGridAndWait == 0
                        
                        % If it's during the time when the stimulus (dots) is on, then show the stimulus plus the fixation dot
                        if ( secondsElapsed > this.ExperimentOptions.InitFixDuration+initialWaiting && secondsElapsed < this.ExperimentOptions.InitFixDuration+initialWaiting + this.ExperimentOptions.TimeStimOn) % then show dots + fixation dot
                            
                            % Draw left stim:
                            Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                            Screen('DrawDots', this.Graph.window, [screenPoints.LX(1:end-1)'; screenPoints.LY(1:end-1)'],sizeOfDots, [], this.Graph.wRect(3:4)/2, 1); % the 1 at the end means dot type where 1 2 or 3 is circular
                            Screen('DrawDots', this.Graph.window, [screenPoints.LX(end); screenPoints.LY(end)], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                            Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);
                            
                            % Draw right stim:
                            Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                            Screen('DrawDots', this.Graph.window, [screenPoints.RX(1:end-1)'; screenPoints.RY(1:end-1)'], sizeOfDots, [], this.Graph.wRect(3:4)/2, 1);
                            Screen('DrawDots', this.Graph.window, [screenPoints.RX(end); screenPoints.RY(end)], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                            Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);
                            
                        end
                        
                    elseif displayGridAndWait == 1
                        % Draw left stim:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.LX(end)-200, this.Graph.wRect(4)/2, this.Graph.wRect(3)/2+screenPoints.LX(end)+200, this.Graph.wRect(4)/2, 3); % main horizontal line
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.LX(end), this.Graph.wRect(4)/2+screenPoints.LY(end)-200, this.Graph.wRect(3)/2+screenPoints.LX(end), this.Graph.wRect(4)/2+screenPoints.LY(end)+200, 3); % main vert line
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.LX(end)-200, this.Graph.wRect(4)/2+100, this.Graph.wRect(3)/2+screenPoints.LX(end)+200, this.Graph.wRect(4)/2+100, 3); 
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.LX(end)-200, this.Graph.wRect(4)/2-100, this.Graph.wRect(3)/2+screenPoints.LX(end)+200, this.Graph.wRect(4)/2-100, 3); 
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.LX(end)+100, this.Graph.wRect(4)/2+screenPoints.LY(end)-200, this.Graph.wRect(3)/2+screenPoints.LX(end)+100, this.Graph.wRect(4)/2+screenPoints.LY(end)+200, 3);
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.LX(end)-100, this.Graph.wRect(4)/2+screenPoints.LY(end)-200, this.Graph.wRect(3)/2+screenPoints.LX(end)-100, this.Graph.wRect(4)/2+screenPoints.LY(end)+200, 3);
                        Screen('TextSize', this.Graph.window, 70);
                        DrawFormattedText(this.Graph.window, 'QTQ', this.Graph.wRect(3)/2+screenPoints.LX(end)-100,this.Graph.wRect(4)/2+screenPoints.LY(end),[150 150 150]);

                        % Draw right stim:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.RX(end)-200, this.Graph.wRect(4)/2, this.Graph.wRect(3)/2+screenPoints.RX(end)+200, this.Graph.wRect(4)/2, 3); % main horizontal line
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.RX(end), this.Graph.wRect(4)/2+screenPoints.RY(end)-200, this.Graph.wRect(3)/2+screenPoints.RX(end), this.Graph.wRect(4)/2+screenPoints.RY(end)+200, 3); % main vert line
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.RX(end)-200, this.Graph.wRect(4)/2+100, this.Graph.wRect(3)/2+screenPoints.RX(end)+200, this.Graph.wRect(4)/2+100, 5); 
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.RX(end)-200, this.Graph.wRect(4)/2-100, this.Graph.wRect(3)/2+screenPoints.RX(end)+200, this.Graph.wRect(4)/2-100, 3); 
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.RX(end)+100, this.Graph.wRect(4)/2+screenPoints.RY(end)-200, this.Graph.wRect(3)/2+screenPoints.RX(end)+100, this.Graph.wRect(4)/2+screenPoints.RY(end)+200, 3);
                        Screen('DrawLine', this.Graph.window, [150 150 150], this.Graph.wRect(3)/2+screenPoints.RX(end)-100, this.Graph.wRect(4)/2+screenPoints.RY(end)-200, this.Graph.wRect(3)/2+screenPoints.RX(end)-100, this.Graph.wRect(4)/2+screenPoints.RY(end)+200, 3);
                        Screen('TextSize', this.Graph.window, 70);
                        DrawFormattedText(this.Graph.window, 'QTQ', this.Graph.wRect(3)/2+screenPoints.RX(end)-100,this.Graph.wRect(4)/2+screenPoints.RY(end),[150 150 150]);
                    end


                    % Any other time, just show the fixation dot
                    % Draw left stim:
                    Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                    Screen('DrawDots', this.Graph.window, [screenPoints.LX(end); screenPoints.LY(end)], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                    Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);

                    % Draw right stim:
                    Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                    Screen('DrawDots', this.Graph.window, [screenPoints.RX(end); screenPoints.RY(end)], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                    Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);
                    

                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------

                    % FLIP
                    this.Graph.Flip(this, thisTrialData, secondsRemaining);


                    % -----------------------------------------------------------------
                    % --- Collecting responses  ---------------------------------------
                    % -----------------------------------------------------------------

                    % Only collect responses after the stim has been displayed
                    if secondsElapsed > this.ExperimentOptions.InitFixDuration+initialWaiting
                        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                        if ( keyIsDown )
                            keys = find(keyCode);
                            for i=1:length(keys)
                                KbName(keys(i));
                                switch(KbName(keys(i)))
                                    case 'RightArrow'
                                        response = 'F';
                                    case 'LeftArrow'
                                        response = 'B';
                                    case 'DownArrow'
                                        response = 'F';
                                    case 'UpArrow'
                                        response = 'B';
                                    case 'space'
                                        initialWaiting = GetSecs - thisTrialData.TimeStartLoop;
                                        displayGridAndWait = 0;
                                end
                            end
                            if ( ~isempty(response) ) % if there is a response, break this trial and start the next
                                thisTrialData.Response = response;
                                thisTrialData.ResponseTime = GetSecs;
                                thisTrialData.GridWaitTime = initialWaiting;
                                break;
                            end
                        end
                    end
                end

                if ( isempty(response) )
                    thisTrialData.Response = 'N';
                    thisTrialData.ResponseTime = GetSecs;
                    thisTrialData.GridWaitTime = initialWaiting;
                    trialResult = Enum.trialResult.ABORT;
                else
                    trialResult = Enum.trialResult.CORRECT;
                end


            catch ex
                rethrow(ex)
            end

        end
        
       function [trialResult, thisTrialData] = runPostTrial( this, thisTrialData )
           % Record if the subject guessed correctly or not 
           if thisTrialData.Response == thisTrialData.CorrectResponse
               thisTrialData.GuessedCorrectly = 1;
           elseif thisTrialData.Response ~= thisTrialData.CorrectResponse
               thisTrialData.GuessedCorrectly = 0;
           end
           
           % Move this forward
           trialResult = thisTrialData.TrialResult;
       end
            
             
        
    end

    

    methods
        
        function [thresholdTable] = Plot_StereoVergencePsychometric(this)
            %%
            trialTable = this.Session.trialDataTable;
            trialTable.RespondedFront = ones(size(trialTable,1),1);
            trialTable.RespondedFront(trialTable.Response == 'B') = trialTable.RespondedFront(trialTable.Response == 'B') *0;
            
            RotateDotsCond = unique(abs(trialTable.RotateDots));
            EyePosCond=unique(trialTable.Vergence);
            thresholdTable = table();
            here=1;
            
            for arotation = 1:length(RotateDotsCond)
            
                
                %figure('Position',1.0e+03 * [0.3243  1.0297 1.2357  0.3083]);
                
                for aneyepos = 1:length(EyePosCond)
                    idxs = find((trialTable.RotateDots == RotateDotsCond(arotation) & trialTable.Vergence == EyePosCond(aneyepos))  | ((trialTable.RotateDots == -RotateDotsCond(arotation) & trialTable.Vergence == EyePosCond(aneyepos))));
                    temp=sortrows(array2table([trialTable.DisparityArcMin(idxs) trialTable.RespondedFront(idxs)],'VariableNames',{'DisparityArcMin','RespondedFront'}));
                    
                    % Fit model
                    modelspec = 'RespondedFront ~ DisparityArcMin';
                    mdl = fitglm(temp(:,{'RespondedFront', 'DisparityArcMin'}), modelspec, 'Distribution', 'binomial');
                    a=[-2:0.01:0, 0.01:0.01:2];
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
                    
                    % Add them to a table
                    thresholdTable.Vergence(here,:) = EyePosCond(aneyepos);
                    thresholdTable.Condition(here) = abs(RotateDotsCond(arotation));
                    thresholdTable.Slope(here) = slope;
                    thresholdTable.Threshold(here) = threshold;
                    thresholdTable.CoeffIntercept(here) = mdl.Coefficients.Estimate(1);
                    thresholdTable.CoeffDispar(here) = mdl.Coefficients.Estimate(2);
                    thresholdTable.Temp(here)={(table2cell(temp))};
                    
                    % Add baseline to threshold table if the zero condition was added
                    if ~isempty(thresholdTable.Threshold( find(thresholdTable.Vergence == EyePosCond(aneyepos) & thresholdTable.Condition == 0)))
                        thresholdTable.baseline(here) = thresholdTable.Threshold( find(thresholdTable.Vergence == EyePosCond(aneyepos) & thresholdTable.Condition == 0));
                    end
                    
                    % Plot
                    subplot(1,length(RotateDotsCond),arotation)
                    if EyePosCond(aneyepos) == "parallel"
                        par=plot(a,p,'Color',[8, 143, 143]/255,'LineWidth',1.5); hold on % plot prediction, blue
                        plot(temp.DisparityArcMin,temp.meanedResp,'o','Color',[8, 143, 143]/255);
                    elseif EyePosCond(aneyepos) == "converged"
                        con=plot(a,p,'Color',[255 121 0]/255,'LineWidth',1.5); hold on  % plot prediction, yellow-orange
                        plot(temp.DisparityArcMin,temp.meanedResp,'o','Color',[255 121 0]/255);
                    end
                    ylim([0 1])
                    xlabel('Disparity (arcmin)')
                    ylabel('Proportion Front')
                    if EyePosCond(aneyepos) == "parallel"
                        text(min(xlim)+0.05, max(ylim)-0.1, sprintf('P Threshold(arcmin): %.2f', threshold), 'Horiz','left', 'Vert','bottom')
                    elseif EyePosCond(aneyepos) == "converged"
                        text(min(xlim)+0.05, max(ylim)-0.15, sprintf('C Threshold(arcmin): %.2f', threshold), 'Horiz','left', 'Vert','bottom')
                    end
                    title([sprintf('   Rotation: %s',string(abs(RotateDotsCond(arotation))))])
                    % only make the legend once the data are all there
                    if aneyepos == 2
                        legend([ con par ],{'Converged','Parallel'},'location','southeast')
                    end
                    
                    here=here+1;
                end
                
            end


        end
    end
end