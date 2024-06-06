classdef Stereoacuity_Vergence < ArumeExperimentDesigns.EyeTracking
    % DEMO experiment for Arume
    %
    %   1. Copy paste the folder @Demo within +ArumeExperimentDesigns.
    %   2. Rename the folder with the name of the new experiment but keep that @ at the begining!
    %   3. Rename also the file inside to match the name of the folder (without the @ this time).
    %   4. Then change the name of the class inside the folder.
    %
    properties
        stimTextureLeft = [];
        stimTextureRight = [];
        targetColor = [150 150 150];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            %% ADD new options
            dlg.IPD = { 63 '* (mm)' [40 80] }; 
            dlg.Number_of_Dots = { 500 '* (num)' [10 10000] }; %750
            dlg.Size_of_Dots = { 1 '* (pix)' [1 100] };
            dlg.FixationSpotSize = { 0.25 '* (diameter_in_deg)' [0 5] };
            dlg.TimeStimOn = { 0.3 '* (sec)' [0 60] }; 
            dlg.InitFixDuration = { 1 '* (sec)' [0 60] };
            
            dlg.NumberOfRepetitions = {1 '* (N)' [1 200] }; 
            dlg.BackgroundBrightness = 0;
            
            %% CHANGE DEFAULTS values for existing options
            
            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber Vergence RotateDots DisparityArcMin GuessedCorrectly'; % which variables to display every trial in the command line separated by spaces
            
            dlg.DisplayOptions.ScreenWidth = { 60 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 33.5 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 57 '* (cm)' [1 3000] };
            dlg.DisplayOptions.StereoMode = { 4 '* (mode)' [0 9] }; 
            dlg.DisplayOptions.SelectedScreen = { 1 '* (screen)' [0 5] };
            
            dlg.HitKeyBeforeTrial = 0;
            dlg.TrialDuration = 90;
            dlg.TrialsBeforeBreak = 100000; %150
            dlg.TrialAbortAction = 'Repeat';
        end
        
        function trialTable = SetUpTrialTable(this)
            
            %-- condition variables ---------------------------------------
            t = ArumeCore.TrialTableBuilder();
            
            t.AddConditionVariable( 'V', ["p1" "c1" "p2" "c2" "p3" "c3" "p4" "c4" "p5" "c5" "p6" "c6"]); % vergence: parallel or converged, repeated 6x
            t.AddConditionVariable( 'RotateDots', [-30 -10 -5 0 5 10 30]);
            %t.AddConditionVariable( 'RotateDots', [0]);
            %t.AddConditionVariable( 'Disparities', [-2 -1.6 -1.2 -0.8 -0.4 0.4 0.8 1.2 1.6 2]); % arcmins
            t.AddConditionVariable( 'Disparities', [-1.2 -0.8 -0.4 0.4 0.8 1.2]); % arcmins

            % Add three blocks. One with all the upright trials, one with the rest,
            % and another one with upright trials. Running only one repeatition of
            % each upright trial and 3 repeatitions of the other trials,
            t.AddBlock(find(t.ConditionTable.V=="p1"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c1"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p2"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c2"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p3"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c3"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p4"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c4"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p5"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c5"), 1);
            t.AddBlock(find(t.ConditionTable.V=="p6"), 1);
            t.AddBlock(find(t.ConditionTable.V=="c6"), 1);
            trialSequence = 'Random';
            blockSequence =  'Random';
            blockSequenceRepeatitions = this.ExperimentOptions.NumberOfRepetitions; % same as dlg.NumberOfRepetitions
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
                if thisTrialData.V == "p1" || thisTrialData.V == "p2" || thisTrialData.V == "p3" || thisTrialData.V == "p4" || thisTrialData.V == "p5" || thisTrialData.V == "p6"
                    FixationSpot.Z = 200; % fixation spot distance in cm
                    sizeStimCm = 13;
                    thisTrialData.Vergence = categorical("parallel");
                elseif thisTrialData.V == "c1" || thisTrialData.V == "c2" || thisTrialData.V == "c3" || thisTrialData.V == "c4" || thisTrialData.V == "c5" || thisTrialData.V == "c6"
                    FixationSpot.Z = 30; % fixation spot distance in cm
                    sizeStimCm = 2;
                    thisTrialData.Vergence = categorical("converged");
                end
                minsizeStimCm = sizeStimCm/4;
                
                % Calculate the stimulus simulated distance based on the
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
                
                response = []; %initialize this
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                    % If it's during the time when the stimulus (dots) is on, then show the stimulus plus the fixation dot
                    if ( secondsElapsed > this.ExperimentOptions.InitFixDuration && secondsElapsed < this.ExperimentOptions.InitFixDuration + this.ExperimentOptions.TimeStimOn) % then show dots + fixation dot
                        % Select left-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        
                        % Draw left stim:
                        Screen('DrawDots', this.Graph.window, [screenPoints.LX(1:end-1)'; screenPoints.LY(1:end-1)'], this.ExperimentOptions.Size_of_Dots, [], this.Graph.wRect(3:4)/2, 1); % the 1 at the end means dot type where 1 2 or 3 is circular
                        Screen('DrawDots', this.Graph.window, [screenPoints.LX(end); screenPoints.LY(end)], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);
                        
                        % Select right-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        
                        % Draw right stim:
                        Screen('DrawDots', this.Graph.window, [screenPoints.RX(1:end-1)'; screenPoints.RY(1:end-1)'], this.ExperimentOptions.Size_of_Dots, [], this.Graph.wRect(3:4)/2, 1);
                        Screen('DrawDots', this.Graph.window, [screenPoints.RX(end); screenPoints.RY(end)], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);
                        
                    end
                    
                    % If it's the initial fixation time, or if it's after the stimulus time has expired, then just show the fixation dot
                    if ( secondsElapsed <= this.ExperimentOptions.InitFixDuration ||  secondsElapsed > this.ExperimentOptions.InitFixDuration + this.ExperimentOptions.TimeStimOn) 
                        % Select left-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        
                        % Draw left stim:
                        Screen('DrawDots', this.Graph.window, [screenPoints.LX(end); screenPoints.LY(end)], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);
                        
                        % Select right-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        
                        % Draw right stim:
                        Screen('DrawDots', this.Graph.window, [screenPoints.RX(end); screenPoints.RY(end)], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);
                        
                    end
                                        
                    
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------
                    
                    % -----------------------------------------------------------------
                    % -- Flip buffers to refresh screen -------------------------------
                    % -----------------------------------------------------------------
                    this.Graph.Flip(this, thisTrialData, secondsRemaining);
                    % -----------------------------------------------------------------
                    
                    
                    % -----------------------------------------------------------------
                    % --- Collecting responses  ---------------------------------------
                    % -----------------------------------------------------------------
                    
                    % Only collect responses after the stim has been displayed
                    if secondsElapsed > this.ExperimentOptions.InitFixDuration
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
                                end
                            end
                            if ( ~isempty(response) ) % if there is a response, break this trial and start the next
                                thisTrialData.Response = response;
                                thisTrialData.ResponseTime = GetSecs;
                                break;
                            end
                        end
                    end
                end
                
                if ( isempty(response) )
                    thisTrialData.Response = 'N';
                    thisTrialData.ResponseTime = GetSecs;
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