classdef Stereoacuity_MethodOfConstantStimuli < ArumeExperimentDesigns.EyeTracking
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
        targetColor = [255 0 0];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            %% ADD new options
            dlg.InitDisparity = { 5 '* (arcmins)' [0 100] };
            dlg.InitStepSize = { 15 '* (arcmins)' [0 100] };
            dlg.Number_of_Dots = { 3000 '* (deg/s)' [10 10000] };
            dlg.Size_of_Dots = { 4 '* (pix)' [1 100] };
            dlg.visibleWindow_cm = {16 '* (cm)' [1 100] };
            dlg.FixationSpotSize = { 0.4 '* (diameter_in_deg)' [0 5] };
            dlg.TimeStimOn = { 0.5 '* (sec)' [0 60] }; 
            
            dlg.NumberOfRepetitions = {10 '* (N)' [1 200] }; % 100 bc 100 * 2 (sign disparities) = 200 total trials (100 for front, 100 for back)
            dlg.BackgroundBrightness = 0;
            
            %% CHANGE DEFAULTS values for existing options
            
            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult RotateDots DisparityArcMin GuessedCorrectly'; % which variables to display every trial in the command line separated by spaces
            
            dlg.DisplayOptions.ScreenWidth = { 59.5 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 34 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 54 '* (cm)' [1 3000] };
            dlg.DisplayOptions.StereoMode = { 4 '* (mode)' [0 9] }; 
            dlg.DisplayOptions.SelectedScreen = { 1 '* (screen)' [0 5] };
            
            dlg.HitKeyBeforeTrial = 1;
            dlg.TrialDuration = 90;
            dlg.TrialsBeforeBreak = 1200;
            dlg.TrialAbortAction = 'Repeat';
        end
        
        function trialTable = SetUpTrialTable(this)
            
            %-- condition variables ---------------------------------------
            i= 0;
             
            i = i+1;
            conditionVars(i).name   = 'Disparities';
            conditionVars(i).values = [-1:0.1:1] 
            
            i = i+1;
            conditionVars(i).name   = 'RotateDots';
            conditionVars(i).values = [0]; %5 10 45];
            
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Repeat'; % Repeat, Delay, Drop
            trialTableOptions.trialsPerSession = 1000;
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end
        
        
%         function [trialResult, thisTrialData] = runPreTrial( this, thisTrialData )
%             Enum = ArumeCore.ExperimentDesign.getEnum();
%             trialResult = Enum.trialResult.CORRECT;
%             
%             % Calculate the disparity, depending on whether or not the staircase exists
%             
%             if isempty(this.Session.currentRun.pastTrialTable) || isempty(find(this.Session.currentRun.pastTrialTable.SignDisparity == thisTrialData.SignDisparity & this.Session.currentRun.pastTrialTable.RotateDots == thisTrialData.RotateDots)) % if this is the first trial of the whole experiment or if this staircase has never occured before
%                  thisTrialData.DisparityArcMinLogAbs = log(this.ExperimentOptions.InitDisparity); % first disparity of this staircase will be the initial disparity
% 
%             else
%                 thisTrialsStaircaseTrials = find(this.Session.currentRun.pastTrialTable.SignDisparity == thisTrialData.SignDisparity & this.Session.currentRun.pastTrialTable.RotateDots == thisTrialData.RotateDots);
%                 numReversals = sum(this.Session.currentRun.pastTrialTable.IsReversal(thisTrialsStaircaseTrials));
%                 
%                 % What the disparity will be on this trial, given the response on the last trial
%                 lastAbsoluteTrialDisparity = this.Session.currentRun.pastTrialTable.DisparityArcMinLogAbs(thisTrialsStaircaseTrials(end)); % this should already be in log units, so don't need to change anything here
%                 lastTrialGuessedCorrectly = this.Session.currentRun.pastTrialTable.GuessedCorrectly(thisTrialsStaircaseTrials(end));
%                 absoluteDisparityArcMin = lastAbsoluteTrialDisparity - (log(this.ExperimentOptions.InitStepSize)) / (numReversals+1) * (lastTrialGuessedCorrectly - 0.8); % from Faes 2007, https://link.springer.com/article/10.3758/BF03193747
%                 thisTrialData.DisparityArcMinLogAbs = absoluteDisparityArcMin;
%                 
% %                 % probably don't need this now that we're doing log?
% %                 if exp(thisTrialData.DisparityArcMinLog) > 0 & thisTrialData.SignDisparity == -1 % if you went below/above zero when you weren't supposed to
% %                     thisTrialData.DisparityArcMinLog = 0.001 *  thisTrialData.SignDisparity;
% %                 elseif exp(thisTrialData.DisparityArcMinLog) < 0 & thisTrialData.SignDisparity == 1 % if you went below/above zero when you weren't supposed to
% %                     thisTrialData.DisparityArcMinLog = 0.001 *  thisTrialData.SignDisparity;
% %                 end
%             end
%             
%             thisTrialData.DisparityArcMinLog =  thisTrialData.DisparityArcMinLogAbs * thisTrialData.SignDisparity;
%             thisTrialData.DisparityArcMin = exp(thisTrialData.DisparityArcMinLogAbs) * thisTrialData.SignDisparity;
%             
%         end
        
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            try
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;
                
                Screen('FillRect', graph.window, 0); % not sure if needed
                
                % Screen width and height of one of the two eye displays in pixels
                screenWidth = this.Graph.wRect(3);
                screenHeight = this.Graph.wRect(4);
                
                % Settings
                moniterWidth_cm =  this.ExperimentOptions.DisplayOptions.ScreenWidth;
                viewingDist = this.ExperimentOptions.DisplayOptions.ScreenDistance;
                moniterWidth_deg = (atan2d(moniterWidth_cm/2, viewingDist)) * 2;
                pixPerDeg = (screenWidth*2) / moniterWidth_deg;
                
                % Stimulus settings:
                numDots = this.ExperimentOptions.Number_of_Dots;
                dots = zeros(3, numDots);
                
                % How big should the window (entire dots stimulus) be in pix?
                visibleWindow_cm = this.ExperimentOptions.visibleWindow_cm; % in cm, this is how much of the screen you can see w one eye at a viewingDist of 20 (from haploscope calcs!)
                visibleWindow_pix = ((screenWidth*2) / moniterWidth_cm) * visibleWindow_cm;
                xmax = visibleWindow_pix / 2;
                ymax = xmax;
                
                % Disparity settings:
                if thisTrialData.Disparities == 0 % handle what happens when disparity is zero
                    if rand < 0.5
                        thisTrialData.Disparities = 0.001 * -1
                    else
                        thisTrialData.Disparities = 0.001 * 1
                    end
                end
                disparity_deg = thisTrialData.Disparities/60;
                shiftNeeded_cm = viewingDist * tand(disparity_deg);
                shiftNeeded_pix = ((screenWidth*2) / moniterWidth_cm) * shiftNeeded_cm;
                %shiftNeeded_pix = pixPerDeg * shiftNeeded_deg;
                dots(1, :) = 2*(xmax)*rand(1, numDots) - xmax; % SR x coords
                dots(2, :) = 2*(ymax)*rand(1, numDots) - ymax; % SR y coords
                
                % Get fixation spot size in pix
                fixSizePix = pixPerDeg * this.ExperimentOptions.FixationSpotSize;
                
                % Make the window (entire dot stimulus) circular :D 
                distFromCenter = sqrt((dots(1,:)).^2 + (dots(2,:)).^2);
                while isempty(distFromCenter(distFromCenter>ymax | distFromCenter<fixSizePix)) == 0 % while there are dots that are outside of the desired circle
                    idxs=find(distFromCenter>ymax | distFromCenter<fixSizePix);
                    dots(1, idxs) = 2*(xmax)*rand(1, length(idxs)) - xmax; % resample those dots
                    dots(2, idxs) = 2*(ymax)*rand(1, length(idxs)) - ymax; 
                    distFromCenter = sqrt((dots(1,:)).^2 + (dots(2,:)).^2);
                end
                dots(3, :) = (ones(size(dots,2),1)')*shiftNeeded_pix; % how much the dots will shift by in pixels
                
%                 % Stim Prep for shifting only the center dots of the stimulus (not the
%                 % whole thing). The inside center dots shifting is a square, not circle. 
%                 vec_x = dots(1, :);
%                 vec_y = dots(2, :);
%                 vec_x(vec_x < -xmax/2) = 0;
%                 vec_x(vec_x > xmax/2) = 0;
%                 vec_y(vec_y < -ymax/2) = 0;
%                 vec_y(vec_y > ymax/2) = 0;
%                 idx_x = find(vec_x==0);
%                 idx_y = find(vec_y==0);
%                 dots(3,idx_x) = 0;
%                 dots(3,idx_y) = 0;
%                 
                % Right and left shifted dots
                leftStimDots = dots(1:2, :) + [dots(3, :)/2; zeros(1, numDots)]; % zeros here bc no shift in vertical dots 
                rightStimDots = dots(1:2, :) - [dots(3, :)/2; zeros(1, numDots)];
                
                % Rotating the dots if needed
                leftDistFromCenter = sqrt((leftStimDots(1,:)).^2 + (leftStimDots(2,:)).^2); %where leftStimDots(1,:) is the x coord and leftStimDots(2,:) is the y coord
                leftThetaDeg = atan2d(leftStimDots(2,:),leftStimDots(1,:));
                leftPolarPtX = cosd(leftThetaDeg + thisTrialData.RotateDots) .* leftDistFromCenter;
                leftPolarPtY = sind(leftThetaDeg + thisTrialData.RotateDots) .* leftDistFromCenter;
                rightDistFromCenter = sqrt((rightStimDots(1,:)).^2 + (rightStimDots(2,:)).^2); %where leftStimDots(1,:) is the x coord and leftStimDots(2,:) is the y coord
                rightThetaDeg = atan2d(rightStimDots(2,:),rightStimDots(1,:));
                rightPolarPtX = cosd(rightThetaDeg + thisTrialData.RotateDots) .* rightDistFromCenter;
                rightPolarPtY = sind(rightThetaDeg + thisTrialData.RotateDots) .* rightDistFromCenter;
                % rotated dots
                leftStimDots = [leftPolarPtX;leftPolarPtY];
                rightStimDots = [rightPolarPtX;rightPolarPtY];
                
                % What the response should be
                if thisTrialData.Disparities > 0
                    thisTrialData.CorrectResponse = 'F';
                elseif thisTrialData.Disparities < 0
                    thisTrialData.CorrectResponse = 'B';
%                 elseif thisTrialData.DisparityArcMin == 0
%                     thisTrialData.DisparityArcMin
%                     disp('Crashed here')
%                     thisTrialData.DisparityArcMin
                end
                
                % For the while loop trial start
                trialDuration = this.ExperimentOptions.TrialDuration;
                lastFlipTime                        = Screen('Flip', graph.window);
                secondsRemaining                    = trialDuration;
                thisTrialData.TimeStartLoop         = lastFlipTime;
                
                response = []; %initialize this
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = trialDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                    if ( secondsElapsed <= this.ExperimentOptions.TimeStimOn ) % then show dots + fixation dot
                        % Select left-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        
                        % Draw left stim:
                        Screen('DrawDots', this.Graph.window, leftStimDots, this.ExperimentOptions.Size_of_Dots, [], this.Graph.wRect(3:4)/2, 1); % the 1 at the end means dot type where 1 2 or 3 is circular
                        Screen('DrawDots', this.Graph.window, [0;0], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);
                        
                        % Select right-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        
                        % Draw right stim:
                        Screen('DrawDots', this.Graph.window, rightStimDots, this.ExperimentOptions.Size_of_Dots, [], this.Graph.wRect(3:4)/2, 1);
                        Screen('DrawDots', this.Graph.window, [0;0], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);
                        
                    end
                    
                    if ( secondsElapsed > this.ExperimentOptions.TimeStimOn ) % then show only fixation dot
                        % Select left-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        
                        % Draw left stim:
                        Screen('DrawDots', this.Graph.window, [0;0], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);
                        
                        % Select right-eye image buffer for drawing:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        
                        % Draw right stim:
                        Screen('DrawDots', this.Graph.window, [0;0], fixSizePix, this.targetColor, this.Graph.wRect(3:4)/2, 1); % fixation spot
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
                            end
                        end
                        if ( ~isempty(response) ) % if there is a response, break this trial and start the next
                            thisTrialData.Response = response;
                            thisTrialData.ResponseTime = GetSecs;
                            break;
                        end
                    end
                end
                
                if ( isempty(response) )
                    thisTrialData.Response = 'NoResponse';
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
           
           % Record if the trial was a reversal
           if isempty(this.Session.currentRun.pastTrialTable) | isempty(find(this.Session.currentRun.pastTrialTable.Disparities == thisTrialData.Disparities & this.Session.currentRun.pastTrialTable.RotateDots == thisTrialData.RotateDots)) % if this is the first trial of the whole experiment or if this staircase has never occured before
               thisTrialData.IsReversal = 0;
           elseif thisTrialData.GuessedCorrectly == this.Session.currentRun.pastTrialTable.GuessedCorrectly(find(this.Session.currentRun.pastTrialTable.Disparities == thisTrialData.Disparities & this.Session.currentRun.pastTrialTable.RotateDots == thisTrialData.RotateDots,1,'last'))
               thisTrialData.IsReversal = 0;
           elseif thisTrialData.GuessedCorrectly ~= this.Session.currentRun.pastTrialTable.GuessedCorrectly(find(this.Session.currentRun.pastTrialTable.Disparities == thisTrialData.Disparities & this.Session.currentRun.pastTrialTable.RotateDots == thisTrialData.RotateDots,1,'last'))
               thisTrialData.IsReversal = 1;
           end
           
           % Move this forward
           trialResult = thisTrialData.TrialResult;
           
       end
            
       

                    
        
    end

    methods

        function [out] = Plot_Staircase(this)
            %%
            t = this.Session.trialDataTable;

            figure
            subplot(2,2,[1 2])
            plot(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 0),'-o','Color','k'); hold on
            plot(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 0),'-o','Color','k')
            plot(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 5),'-o','Color','b')
            plot(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 5),'-o','Color','b')
            plot(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 10),'-o','Color','r')
            plot(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 10),'-o','Color','r')  
            plot(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 45),'-o','Color','m')
            plot(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 45),'-o','Color','m')
            legend('0','0','5','5','10','10','45','45')
            xlabel('Trials')
            ylabel('Disparity Arcmins')
            subplot(2,2,3)
            bar(1,mean(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 0 & t.IsReversal == 1)),'FaceColor','k'); hold on
            bar(1.1,mean(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 0 & t.IsReversal == 1)),'FaceColor','k')
            bar(2,mean(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 5 & t.IsReversal == 1)),'FaceColor','b')
            bar(2.1,mean(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 5 & t.IsReversal == 1)),'FaceColor','b')
            bar(3,mean(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 10 & t.IsReversal == 1)),'FaceColor','r')
            bar(3.1,mean(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 10 & t.IsReversal == 1)),'FaceColor','r')
            bar(4,mean(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 45 & t.IsReversal == 1)),'FaceColor','m')
            bar(4.1,mean(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 45 & t.IsReversal == 1)),'FaceColor','m')
            xticks(1:3)
            xticklabels({'0','5','10','45'})  
            ylim([-1 1])
            ylabel('Threshold, avg of reversals')
            subplot(2,2,4)
            bar(1,mean(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 0 & t.BlockNumber > 90)),'FaceColor','k'); hold on
            bar(1.1,mean(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 0 & t.BlockNumber > 90)),'FaceColor','k')
            bar(2,mean(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 5 & t.BlockNumber > 90)),'FaceColor','b')
            bar(2.1,mean(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 5 & t.BlockNumber > 90)),'FaceColor','b')
            bar(3,mean(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 10 & t.BlockNumber > 90)),'FaceColor','r')
            bar(3.1,mean(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 10 & t.BlockNumber > 90)),'FaceColor','r')
            bar(4,mean(t.DisparityArcMin(t.SignDisparity == 1 & t.RotateDots == 45 & t.BlockNumber > 90)),'FaceColor','m')
            bar(4.1,mean(t.DisparityArcMin(t.SignDisparity == -1 & t.RotateDots == 45 & t.BlockNumber > 90)),'FaceColor','m')
            xticks(1:4)
            xticklabels({'0','5','10','45'})  
            ylim([-1 1])
            ylabel('Threshold, avg of last 10 trials')

        end
    end
end