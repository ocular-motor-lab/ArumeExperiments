classdef ReboundNystagmus_PeripheralProcessing_v2 < ArumeExperimentDesigns.EyeTracking
    % ReboundNystagmus_PeripheralProcessing experiment for Arume
    %
    % 11/13/2022 - Added a break screen and rest state variable
    %
    % Coded by Terence Tyson, 11/1/2022
    properties
        fixRad   = 20;
        fixColor = [255 0 0];
    end

    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);

            %% ADD new options
            %dlg.Max_Speed        = { 30 '* (deg/s)' [0 100] };
            %dlg.Number_of_Speeds = {3 '* (N)' [1 100] };

            %dlg.Number_of_Dots = { 2000 '* (deg/s)' [10 10000] };
            %dlg.Max_Radius     = { 40 '* (deg)' [1 100] };
            %dlg.Min_Radius     = { 1 '* (deg)' [0 100] };

            %dlg.Min_Dot_Diam        = {0.1  '* (deg)' [0.01 100] };
            %dlg.Max_Dot_Diam        = {0.4  '* (deg)' [0.01 100] };
            %dlg.Number_of_Dot_Sizes = {5 '* (N)' [1 100] };

            dlg.NumberOfRepetitions = {8 '* (N)' [1 100] };

            dlg.Do_Blank = { {'0','{1}'} };

            dlg.TargetSize = 0.5;

            dlg.BackgroundBrightness = 0;

            %% CHANGE DEFAULTS values for existing options

            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult controlORexperimental lineDistance  Response'; % which variables to display every trial in the command line separated by spaces

            dlg.DisplayOptions.ScreenWidth    = { 121 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight   = { 68 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 60 '* (cm)' [1 3000] };

            dlg.HitKeyBeforeTrial         = 1;
            dlg.TrialsBeforeBreak         = 20;
            dlg.TrialAbortAction          = 'Repeat';
            dlg.TrialDurSequence          = [5 35 35 36 36 36.2];
            dlg.TrialDurSequence_Control  = [0 5 5 5.2];
            dlg.TrialDuration             = 50;
            dlg.RestDuration              = 0;
            dlg.flickerRate               = [];
            dlg.refreshRate               = 60; % 60 Hz monitor refresh rate
            %dlg.LeftORRight_Gaze  = 'L';


            % additional parameters on the setup
            whichDisplay                    = 'Lab'; % lab or office?

            switch whichDisplay
                case 'Office'
                    dlg.viewingDistance     = 33.4;   % in cm
                    dlg.targetEccentricity  = 40;     % in deg
                    dlg.targetHorDisplace   = 28;     % in cm
                    dlg.screenWidth         = 59.5;   % in cm
                    dlg.screenHeight        = 33.5;   % in cm
                    dlg.screenResolutionHor = 3840;   % in pixels
                    dlg.screenResolutionVer = 2160;   % in pixels
                    dlg.lineFixed           = 20;     % in deg
                    dlg.textScreenFontSize  = 34;     % font size
                case 'Lab'
                    dlg.viewingDistance     = 83;     % in cm
                    dlg.targetEccentricity  = 40;     % in deg
                    dlg.targetHorDisplace   = 69.6453;% in cm
                    dlg.screenWidth         = 144.78; % in cm
                    dlg.screenHeight        = 82.55;  % in cm
                    dlg.screenResolutionHor = 3840;   % in pixels
                    dlg.screenResolutionVer = 2160;   % in pixels
                    dlg.lineFixed           = 20;     % in deg
                    dlg.textScreenFontSize  = 34;     % font size
             end


            dlg.debugFlag           = NaN;
        end

        function trialTable = SetUpTrialTable(this)

            %-- condition variables ---------------------------------------
            i = 0;

            % experimental variable 1: line distance (10 conditions)
            i = i+1;
            conditionVars(i).name   = 'lineDistance';
            %conditionVars(i).values = {'17.5','18','18.5','19','19.5',...
            %    '20.5','21','21.5','22','22.5'};
%             conditionVars(i).values = {'18.5','19','19.25','19.50','19.75',...
%                 '20.25','20.5','20.75','21','21.25'};
             conditionVars(i).values = {'19','19.2','19.4','19.6','19.8',...
                 '20','20.2','20.4','20.6','20.8','21'}; % Terence
%            conditionVars(i).values = {'15','16','17','18','19',...
%                '20','21','22','23','24','25'}; % Dennis

            % experimental variable 2: control vs experimental (2
            % conditions)
            i = i + 1;
            conditionVars(i).name   = 'controlORexperimental';
            conditionVars(i).values = {'control','experimental'};
            %conditionVars(i).values = {'control'};

            % trial table options
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Delay';
            trialTableOptions.trialsPerSession = 1000;
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);

        end


        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            try
                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;

                lastFlipTime        = GetSecs;
                secondsRemaining    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;

                % initialize flicker stim start time
                timeStamps     = nan(this.ExperimentOptions.refreshRate*...
                    this.ExperimentOptions.TrialDuration,1);
                timeInd        = 1;
                
                % trial level flags
                waitTime4Button = 0;
                unlimitedTime   = 0; % for 2AFC response
                restState       = 0; % rest state
                beepState       = 1;
                expState        = 1;

                while secondsRemaining > 0
                    secondsNow          = GetSecs;
                    secondsElapsed      = secondsNow - thisTrialData.TimeStartLoop;
                    if ~unlimitedTime
                        secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;
                        timeStamps(timeInd) = secondsNow;
                        if timeInd > 1
                            secondsperIteration = secondsperIteration + (secondsNow - timeStamps(timeInd-1));
                            waitTime4Button     = waitTime4Button - (secondsNow - timeStamps(timeInd-1));
                        else
                            secondsperIteration = 0;
                        end
                        timeInd             = timeInd + 1;
                    end

                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------


                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);

                    fixRect = [0 0 10 10];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    %fixRect =  [440   190   450   300];
                    %fixRect =  [500   290   510   300]';

                    % 
                    bisectionFlag    = 0;
                    bisectionFlag2   = 0;
                    eccentricFixFlag = 0;
                    
                    switch thisTrialData.controlORexperimental
                        case 'experimental'
                            % Step 1: Eccentric Gaze Holding (40 deg)
                            if secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(1) && ...
                                    secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(2)
                                % initial beep to indicate state change
                                if beepState == 1
                                    Beeper(500,0.4,0.15);
                                    beepState = 2;
                                end
                                % calculate the fixation eccentricity in pixels
                                eccentricFix_Pixels = this.ExperimentOptions.targetEccentricity*(this.ExperimentOptions.targetHorDisplace/...
                                    this.ExperimentOptions.targetEccentricity)*...
                                    (this.ExperimentOptions.screenResolutionHor/this.ExperimentOptions.screenWidth);

                                % check if debugger mode off or on
                                switch this.ExperimentOptions.Debug.DebugMode
                                    case 0 % debugger mode off
                                        fixRect = [fixRect(1)+eccentricFix_Pixels ...
                                            fixRect(2) ...
                                            fixRect(3)+eccentricFix_Pixels ...
                                            fixRect(4)]';
                                    otherwise
                                        % Scaled to the debugger mode window (scaling factor
                                        % in denominator (i.e., 7.322)
                                        fixRect= [fixRect(1)+round(436.5/7.322) fixRect(2) ...
                                            fixRect(3)+round(436.5/7.322) fixRect(4)]';
                                end
                                eccentricFixFlag = 1;
                                expState         = 2;
                                % Step 3: 1 sec interval to move gaze position from
                                % eccentric target back to central target
                            elseif secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(3) && ...
                                    secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(4)
                                eccentricFixFlag = 0;
                                % state change beep
                                if beepState == 2
                                    Beeper(500,0.4,0.15);
                                    beepState = 3;
                                end
                                expState = 3;
                                % Step 4: Primary Position, bisection task
                            elseif secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(5) && ...
                                    secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(6)
                                % state change beep (more salient beep)
                                if beepState == 3
                                    Beeper(1000,0.4,0.15);
                                    beepState = 4;
                                end
                                % create bisection stimulus
                                [fixRect,bisectionFlag] = biSection_Stimulus(fixRect,...
                                    thisTrialData.lineDistance(end),...
                                    this.ExperimentOptions);
                                expState = 5;
                                % Step 5: Primary position, question
                            elseif secondsRemaining < this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(6)
                                % state change beep
                                if beepState == 4
                                    Beeper(500,0.4,0.15);
                                    beepState = 5;
                                end
                                bisectionFlag2 = 1;
                                % display text indefinitely
                            end
                        case 'control'
                            % Step 1: 5 sec gaze in primary position
                            if secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Control(1) && ...
                                    secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Control(2)
                                eccentricFixFlag = 0;
                            % Step 2: Primary Position, bisection task
                            elseif secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Control(3) && ...
                                    secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Control(4)
                                % state change beep
                                if beepState == 1
                                    Beeper(1000,0.4,0.15);
                                    beepState = 2;
                                end
                                
                                % create bisection stimulus
                                [fixRect,bisectionFlag] = biSection_Stimulus(fixRect,...
                                    thisTrialData.lineDistance(end),...
                                    this.ExperimentOptions);
                            % Step 3: Primary position, question
                            elseif secondsRemaining < this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Control(4)
                                % state change beep
                                if beepState == 2
                                    Beeper(500,0.4,0.15);
                                    beepState = 3;
                                end
                                bisectionFlag2 = 1;
                                % display text indefinitely
                            end
                    end

                    % Only draw for 16.7 ms, then off for 983.3 ms
                    if expState == 3
                        Screen('FillOval', graph.window,  this.fixColor, fixRect);
                        secondsperIteration = -0.500;
                        expState = 4;
                    elseif expState == 4
                        if secondsperIteration <= 0.5 && secondsperIteration >= 0
                            1;
                        else
                            Screen('FillOval', graph.window,  this.fixColor, fixRect);
                        end
                    elseif ~bisectionFlag && secondsperIteration <= 0.0167 && secondsperIteration >= 0 && ~bisectionFlag2
                        % Draw fixation position in primary position
                        Screen('FillOval', graph.window,  this.fixColor, fixRect);
                    elseif ~bisectionFlag && ~eccentricFixFlag && ~bisectionFlag2
                        % Only reset secondsperIteration when it is longer
                        % than 16.7 ms or else it would repeatedly reset the
                        % countdown to -983.3 ms.
                        if secondsperIteration >= 0.0167 && expState < 3
                            secondsperIteration = -0.98330;
                        % step 3
                        elseif secondsperIteration >= 0.0167 && expState == 3 
                            secondsperIteration = 0;
                        end
                    elseif bisectionFlag2
                        Screen('TextSize', graph.window, 36);
                        Screen('TextFont', graph.window, 'Courier');
%                         DrawFormattedText(graph.window, ...
%                             strcat('Which line was closer to the middle line?',...
%                             '\n','Left line (left arrow key)',...
%                             '\n','OR',...
%                             '\n','Right line (right arrow key)'),...
%                             'center', 'center', this.fixColor);
                        unlimitedTime = 1;
                    else
                        % Draw bisection stimulus
                        Screen('FillRect', graph.window,  this.fixColor, fixRect);
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
                    %if bisectionFlag || bisectionFlag2
                    if bisectionFlag2
                        % time between iterations of KbCheck loop
                        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                        response = '';
                        if ( keyIsDown ) && waitTime4Button <= 0
                            keys = find(keyCode);
                            for i=1:length(keys)
                                KbName(keys(i));
                                switch(KbName(keys(i)))
                                    case 'RightArrow'
                                        response = 'R';
                                        % if right key then, have kbcheck
                                        % wait for a full second before
                                        % another check.
                                        waitTime4Button = 1;
                                    case 'LeftArrow'
                                        response = 'L';
                                        waitTime4Button = 1;
                                end
                            end

                        end
                        if ( ~isempty( response) )
                            thisTrialData.Response = response;
                            thisTrialData.ResponseTime = GetSecs;

                            % Subject rests for the remainder of the trial
                            while secondsRemaining > 0
                                switch thisTrialData.controlORexperimental
                                    case 'experimental'
                                        this.ExperimentOptions.RestDuration = 10;
                                    case 'control'
                                        this.ExperimentOptions.RestDuration = 0;
                                end
                                if ~restState
                                    TimeStartLoop_Rest = GetSecs;
                                    restState          = 1;
                                end
                                secondsNow        = GetSecs;
                                secondsElapsed    = secondsNow - TimeStartLoop_Rest;
                                secondsRemaining  = this.ExperimentOptions.RestDuration - secondsElapsed;
%                                 Screen('TextSize', graph.window, 36);
%                                 Screen('TextFont', graph.window, 'Courier');
%                                 DrawFormattedText(graph.window, ...
%                                     strcat('BREAK (close your eyes)',...
%                                     '\n\n','10 seconds'),...
%                                     'center', 'center', this.fixColor);
                                this.Graph.Flip(this, thisTrialData, secondsRemaining);
                            end

                            break
                        end
%                             thisTrialData.Response = '';
%                             thisTrialData.ResponseTime = nan;

                    end
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------
                end
            catch ex
                rethrow(ex)
            end

            % -------------------------------------------------------------
            % --- NESTED HELPER FUNCTIONS ---------------------------------
            % -------------------------------------------------------------
            function [fixRect,bisectionFlag] = biSection_Stimulus(fixRect,...
                    lineDistance,ExperimentOptions)
                % pixel 2 degree
                fixRect_Temp  = fixRect;
                fixRect_Temp2 = fixRect;

                % calculate eccentricity in pixels
                lineDistance = double(string(lineDistance))*(ExperimentOptions.targetHorDisplace/...
                    ExperimentOptions.targetEccentricity)*...
                    (ExperimentOptions.screenResolutionHor/ExperimentOptions.screenWidth);
                lineFixed      = ExperimentOptions.lineFixed*(ExperimentOptions.targetHorDisplace/...
                    ExperimentOptions.targetEccentricity)*...
                    (ExperimentOptions.screenResolutionHor/ExperimentOptions.screenWidth);

                % middle line
                fixRect_Temp  = fixRect;
                fixRect       = [fixRect_Temp(1) ;fixRect_Temp(2)-50 ;fixRect_Temp(3) ;fixRect_Temp(4)+50];

                % left line (varied)
                switch ExperimentOptions.Debug.DebugMode
                    case 0   % debugger mode off
                        fixRect       = [fixRect [fixRect_Temp(1)-lineDistance;...
                            fixRect_Temp(2)-50; ...
                            fixRect_Temp(3)-lineDistance ;...
                            fixRect_Temp(4)+50]];
                    otherwise % debugger mode
                        fixRect       = [fixRect [fixRect_Temp(1)-lineDistance;...
                            fixRect_Temp(2)-50; ...
                            fixRect_Temp(3)-lineDistance;...
                            fixRect_Temp(4)+50]];
                end

                % right line (fixed)
                fixRect       = [fixRect [fixRect_Temp(1)+lineFixed; fixRect_Temp(2)-50; ...
                    fixRect_Temp(3)+lineFixed; fixRect_Temp(4)+50]];
                % change bisection flag to be true
                bisectionFlag = 1;
            end
        end
    end
end