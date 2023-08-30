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
        targetColor = [150 150 150];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            %% ADD new options
            %dlg.InitDisparity = { 5 '* (arcmins)' [0 100] };
            %dlg.InitStepSize = { 15 '* (arcmins)' [0 100] };
            dlg.Number_of_Dots = { 3500 '* (deg/s)' [10 10000] };
            dlg.Size_of_Dots = { 4 '* (pix)' [1 100] };
            %dlg.visibleWindow_cm = {16 '* (cm)' [1 100] };
            dlg.stimWindow_deg = {15 '* (deg)' [1 100] };
            dlg.FixationSpotSize = { 0.25 '* (diameter_in_deg)' [0 5] };
            dlg.TimeStimOn = { 0.5 '* (sec)' [0 60] }; 
            dlg.InitFixDuration = { 0.25 '* (sec)' [0 60] };
            dlg.EndFixDuration = { 0.25 '* (sec)' [0 60] };
            
            dlg.NumberOfRepetitions = {15 '* (N)' [1 200] }; 
            dlg.BackgroundBrightness = 0;
            
            %% CHANGE DEFAULTS values for existing options
            
            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult RotateDots DisparityArcMin GuessedCorrectly'; % which variables to display every trial in the command line separated by spaces
            
            dlg.DisplayOptions.ScreenWidth = { 59.5 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 34 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 57.5 '* (cm)' [1 3000] };
            dlg.DisplayOptions.StereoMode = { 4 '* (mode)' [0 9] }; 
            dlg.DisplayOptions.SelectedScreen = { 2 '* (screen)' [0 5] };
            
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
            conditionVars(i).values = [1]; %[0.1:0.1:0.8];
            
            i = i+1;
            conditionVars(i).name   = 'RotateDots';
            conditionVars(i).values = [0 10 45]; %5 10 45];
            
            i = i+1;
            conditionVars(i).name   = 'SignDisparity';
            conditionVars(i).values = [-1 1]; 
            
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Repeat'; % Repeat, Delay, Drop
            trialTableOptions.trialsPerSession = 1000;
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end
        
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            try
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;
                Screen('FillRect', graph.window, 0); % not sure if needed
                ShowCursor();
                
                % Screen and monitor settings
                screenWidth_pix = this.Graph.wRect(3); % screen width of one of the two eyes in pix
                moniterWidth_deg = (atan2d(this.ExperimentOptions.DisplayOptions.ScreenWidth/2, this.ExperimentOptions.DisplayOptions.ScreenDistance)) * 2;
                pixPerDeg = (screenWidth_pix*2) / moniterWidth_deg;
                                
                % Get fixation spot size in pix
                fixSizePix = pixPerDeg * this.ExperimentOptions.FixationSpotSize;
                
                % How big should the dots stimulus be in pix
                dots = zeros(3, this.ExperimentOptions.Number_of_Dots);
                stimWindow_pix = this.ExperimentOptions.stimWindow_deg * pixPerDeg;
                %xmax = stimWindow_pix / 2; % TODO MEASURE HOW BIG THE WINDOW ACTUALLY IS 
                %ymax = xmax;
                
                % Disparity settings:
                thisTrialData.DisparityArcMin = thisTrialData.Disparities * thisTrialData.SignDisparity;
                disparity_deg = thisTrialData.DisparityArcMin/60;
%                 shiftNeeded_cm = viewingDist * tand(disparity_deg); % SR unclear why i was going back to cm?
%                 shiftNeeded_pix = ((screenWidth*2) / moniterWidth_cm) * shiftNeeded_cm;
                disparityNeeded_pix = pixPerDeg*disparity_deg;
                dots(1, :) = stimWindow_pix*rand(1, this.ExperimentOptions.Number_of_Dots) - (stimWindow_pix/2); % SR x coords
                dots(2, :) = stimWindow_pix*rand(1, this.ExperimentOptions.Number_of_Dots) - (stimWindow_pix/2); % SR y coords
                
                % Make the dot stimulus circular :D 
                distFromCenter = sqrt((dots(1,:)).^2 + (dots(2,:)).^2);
                while isempty(distFromCenter(distFromCenter>stimWindow_pix/2 | distFromCenter<fixSizePix)) == 0 % while there are dots that are outside of the desired circle
                    idxs=find(distFromCenter>stimWindow_pix/2 | distFromCenter<fixSizePix);
                    dots(1, idxs) = stimWindow_pix*rand(1, length(idxs)) - (stimWindow_pix/2); % resample those dots
                    dots(2, idxs) = stimWindow_pix*rand(1, length(idxs)) - (stimWindow_pix/2); 
                    distFromCenter = sqrt((dots(1,:)).^2 + (dots(2,:)).^2);
                end
                dots(3, :) = (ones(size(dots,2),1)')*disparityNeeded_pix; % how much the dots will shift by in pixels
                
                % % Don't shift all the dots, only shift the ones further
                % % than 2 degs out 
                % % Update, don't love the way this looks
                % idxs = find(distFromCenter<pixPerDeg*2); 
                % dots(3, idxs) = dots(3, idxs) * 0;
                 
                % Right and left shifted dots % SR DOES IT MATTER PLUS LEFT/RIGHT OR MINUS?
                leftStimDots = [dots(1,:)+(dots(3,:)/2); dots(2,:)]; %dots(1:2, :) + [dots(3, :)/2; zeros(1, numDots)]; 
                rightStimDots = [dots(1,:)-(dots(3,:)/2); dots(2,:)]; 
                
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
                    
                    
                    % If it's during the time when the stimulus (dots) is on, then snow the stimulus plus the fixation dot
                    if ( secondsElapsed > this.ExperimentOptions.InitFixDuration && secondsElapsed < this.ExperimentOptions.TimeStimOn ) % then show dots + fixation dot
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
                    
                    % If it's either: 1) the initial fixation time, or 2) the post-trial ending fixation time, then just show the fixation dot
                    if ( secondsElapsed < this.ExperimentOptions.InitFixDuration || secondsElapsed < this.ExperimentOptions.TimeStimOn + this.ExperimentOptions.EndFixDuration) 
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
           if isempty(this.Session.currentRun.pastTrialTable) | isempty(find(this.Session.currentRun.pastTrialTable.DisparityArcMin == thisTrialData.DisparityArcMin & this.Session.currentRun.pastTrialTable.RotateDots == thisTrialData.RotateDots)) % if this is the first trial of the whole experiment or if this staircase has never occured before
               thisTrialData.IsReversal = 0;
           elseif thisTrialData.GuessedCorrectly == this.Session.currentRun.pastTrialTable.GuessedCorrectly(find(this.Session.currentRun.pastTrialTable.DisparityArcMin == thisTrialData.DisparityArcMin & this.Session.currentRun.pastTrialTable.RotateDots == thisTrialData.RotateDots,1,'last'))
               thisTrialData.IsReversal = 0;
           elseif thisTrialData.GuessedCorrectly ~= this.Session.currentRun.pastTrialTable.GuessedCorrectly(find(this.Session.currentRun.pastTrialTable.DisparityArcMin == thisTrialData.DisparityArcMin & this.Session.currentRun.pastTrialTable.RotateDots == thisTrialData.RotateDots,1,'last'))
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

    methods

        function [out] = Plot_ConstantStim(this)
            %%
            t = this.Session.trialDataTable;

            
% Plotting the psychometric function
RotateDotsCond = [0,10,45];
SignDispCond = [1 -1];
whichone = 1; figure(1);

% lets start with just one condition
for asign = 1:length(SignDispCond)
    for arotation = 1:length(RotateDotsCond)
        idxs = find(t.RotateDots == RotateDotsCond(arotation) & t.SignDisparity == SignDispCond(asign));
        temp=array2table([t.DisparityArcMin(idxs) t.GuessedCorrectly(idxs)],'VariableNames',{'DisparityArcMin','GuessedCorrectly'});
        temp_sorted = sortrows(temp);
        
        % Define the ranges for alpha and beta that you want to search over
        aRange = linspace(-2,2,height(temp)); %"threshold" parameter range, alpha
        bRange = linspace(-10,30,height(temp)); %"slope" parameter range, beta
        LLE = zeros(length(bRange),length(aRange));
        loglikelihood_trials = [];
        
        % For all combinations of alpha and beta, get the log likelihoods
        % for each trial describing how likely it is for that data point to
        % exist based on the tested alpha + beta
        for bi = 1:length(bRange)
            for ai = 1:length(aRange)
                for atrial = 1:height(temp)
                    switch (true)
                        case SignDispCond(asign) == 1
                            if temp.GuessedCorrectly(atrial) == 1
                                loglikelihood_trials(atrial) = log( 0.5./(1+exp(-bRange(bi).*(temp.DisparityArcMin(atrial)-aRange(ai))))+0.5); % logistic equation: 1./(1 + exp(-b.*(x-a)))
                                
                            elseif temp.GuessedCorrectly(atrial) == 0
                                loglikelihood_trials(atrial) = log( 1- (0.5./(1+exp(-bRange(bi).*(temp.DisparityArcMin(atrial)-aRange(ai)))) +0.5) );
                                
                            end
                        case SignDispCond(asign) == -1
                            if temp.GuessedCorrectly(atrial) == 1
                                loglikelihood_trials(atrial) = log( 0.5./(1+exp(bRange(bi).*(temp.DisparityArcMin(atrial)-aRange(ai))))+0.5); % logistic equation: 1./(1 + exp(-b.*(x-a)))
                                
                            elseif temp.GuessedCorrectly(atrial) == 0
                                loglikelihood_trials(atrial) = log( 1- (0.5./(1+exp(bRange(bi).*(temp.DisparityArcMin(atrial)-aRange(ai)))) +0.5) );
                                
                            end
                    end
                end
                % Sum the log likelihoods for all the trials and put it
                % into a matrix for an alpha/beta combination
                LLE(bi,ai) = sum(loglikelihood_trials);
                
            end
            %plot(LLE(bi,:)); pause;
        end
        
        % Get the maximum likelihood of the alpha and beta parameters
        [themax,theidx]=max(LLE(:));
        [maybeX,maybeY] = meshgrid(1:height(temp),1:height(temp));
        if maybeX(theidx) == 1 | maybeX(theidx) == 100 | maybeY(theidx) == 1 | maybeY(theidx) == 100
            disp('search range isnt big enough!')
            break
        end
        the_a_parameter = aRange(maybeX(theidx));
        the_b_parameter = bRange(maybeY(theidx));
        
        % What is the 80% threshold from our staircase
        p=0.8; %from arume staircase
        what_is_the_threshold = (log(1-p / p-0.5)) ./ -the_b_parameter + the_a_parameter; 
        
        % How do you want to group the raw data for visualization?
        grouping_method = 2; %1 or 2
        
        % Preparing visualization
        temp_sorted = sortrows(temp);
        if grouping_method == 1
            % Group the raw data so that each chunk has the same number of data points
            sizeOfChunk = 10;
            thechunk = 1:sizeOfChunk;
            for achunk = 1:100/sizeOfChunk
                themeans(achunk) = mean(temp_sorted.DisparityArcMin(thechunk));
                theresponses(achunk) = mean(temp_sorted.GuessedCorrectly(thechunk));
                thechunk = thechunk + sizeOfChunk;
            end
            
        elseif grouping_method == 2
            % Group the raw data in steps of 0.1
            temp_sorted.roundedDisparities = round(temp_sorted.DisparityArcMin*10)/10;
            maybe = find(diff(temp_sorted.roundedDisparities));
            starting = 1;
            temp_sorted.meanedResp=zeros(height(temp_sorted),1)
            for i = 1:length(maybe)
                ending = maybe(i);
                temp_sorted.meanedResp(starting:ending) = mean(temp_sorted.GuessedCorrectly(starting:ending));
                forplotting(i)=length(starting:ending);
                starting = ending+1;
                if starting > maybe(end) % if it's the last chunk
                    temp_sorted.meanedResp(starting:end) = mean(temp_sorted.GuessedCorrectly(starting:end));
                    forplotting(i+1) = length(starting:100);
                end
            end
        end
        
        % Visualize!
        subplot(2,4,whichone)
        if SignDispCond(asign) == -1
            x = -3:.01:0;
            plot(x, 0.5./(1 + exp(the_b_parameter.*(x-the_a_parameter)))+0.5,'linewidth',2); hold on
        else
            x = 0:.01:3;
            plot(x, 0.5./(1 + exp(-the_b_parameter.*(x-the_a_parameter)))+0.5,'linewidth',2); hold on
        end
        
        if grouping_method == 1
            plot(themeans, theresponses,'o','markersize',7,'color','k','linewidth',1)
        elseif grouping_method == 2
            [disparities,idx] = unique(temp_sorted.roundedDisparities);
            meanedResponses = temp_sorted.meanedResp(idx);
            for i = 1:length(disparities)
                plot(disparities(i),meanedResponses(i),'o','markersize',(forplotting(i)+10)/2,'color','k','linewidth',1)
            end
        end
        ylim([0 1])
        xlabel('Disparity (arcmin)')
        ylabel('Proportion Correct')
        title(sprintf('Rotation: %s',string(RotateDotsCond(arotation))))
        text(min(xlim)+0.05, min(ylim)+0.13, sprintf('Threshold param: %.2f', what_is_the_threshold), 'Horiz','left', 'Vert','bottom')
        text(min(xlim)+0.05, min(ylim)+0.08, sprintf('Alpha param: %.2f', the_a_parameter), 'Horiz','left', 'Vert','bottom')
        text(min(xlim)+0.05, min(ylim)+0.03, sprintf('Beta param: %.2f', the_b_parameter), 'Horiz','left', 'Vert','bottom')

        whichone = whichone + 1;
        
    end
end



        end
    end
end