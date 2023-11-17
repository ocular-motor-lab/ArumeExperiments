classdef ObliqueEccentricGazeHolding < ArumeExperimentDesigns.EyeTracking
    % ObliqueEccentricGazeHolding experiment for Arume
    %
    % 10/17/2023 - Start base experiment to present a dot at a far oblique
    % point and then return back to the center.
    %  
    %
    % Coded by Terence Tyson, 10/17/2023
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

            dlg.NumberOfRepetitions = {1 '* (N)' [1 100] };

            %dlg.Do_Blank = { {'0','{1}'} };

            dlg.TargetSize = 0.5;

            dlg.BackgroundBrightness = 0;

            %% CHANGE DEFAULTS values for existing options
 
            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber chargingLocation'; % which variables to display every trial in the command line separated by spaces

            %dlg.DisplayOptions.ScreenWidth    = { 121 '* (cm)' [1 3000] };
            %dlg.DisplayOptions.ScreenHeight   = { 68 '* (cm)' [1 3000] };
            %dlg.DisplayOptions.ScreenDistance = { 60 '* (cm)' [1 3000] };
            dlg.DisplayOptions.SelectedScreen = 1; % This should be the large monitor in the lab

            dlg.HitKeyBeforeTrial         = 1;
            %dlg.TrialsBeforeBreak         = 20;
            dlg.TrialsBeforeBreak         = 400;
            dlg.TrialAbortAction          = 'Repeat';
            %dlg.TrialDurSequence          = [5 35 35 36 36 36.2];
            dlg.TrialDurSequence          = [0 5 5 35 35 36 36 51];
            %dlg.TrialDurSequence          = 1:1:8;
            dlg.TrialDuration             = 51;
            %dlg.TrialDuration             = 8;
            %dlg.RestDuration              = 0;
            %dlg.flickerRate               = [];
            dlg.refreshRate               = 60; % 60 Hz monitor refresh rate

            % additional parameters on the setup
            whichDisplay                    = 'Lab'; % lab or office?

            switch whichDisplay
                case 'Office'
                    dlg.viewingDistance     = 33.4;   % in cm
                    %dlg.horTargetEccentricity  = 28.2843;% in deg
                    %dlg.verTargetEccentricity  = 28.2843;% in deg
                    dlg.horTargetEccentricity  = 5;% in deg
                    dlg.verTargetEccentricity  = 5;% in deg
                    dlg.targetHorDisplace   = 17.9722;% in cm
                    dlg.targetVerDisplace   = 17.9722;% in cm
                    dlg.screenWidth         = 59.5;   % in cm
                    dlg.screenHeight        = 33.5;   % in cm
                    dlg.screenResolutionHor = 3840;   % in pixels
                    dlg.screenResolutionVer = 2160;   % in pixels
                    dlg.lineFixed           = 20;     % in deg
                    dlg.textScreenFontSize  = 34;     % font size
                case 'Lab'
                    dlg.viewingDistance     = 83;     % in cm
                    %dlg.targetEccentricity  = 40;     % in deg
                    dlg.targetEccentricity  = 37;     % in deg
%                     dlg.horTargetEccentricity  = 28.2843;% in deg
%                     dlg.verTargetEccentricity  = 28.2843;% in deg
                    dlg.horTargetEccentricity  = dlg.targetEccentricity*cos(45*pi/180);% in deg
                    dlg.verTargetEccentricity  = dlg.targetEccentricity*sin(45*pi/180);% in deg
                    %dlg.horTargetEccentricity  = 5;% in deg
                    %dlg.verTargetEccentricity  = 5;% in deg
                    %dlg.targetHorDisplace   = 44.6616;% in cm
                    %dlg.targetVerDisplace   = 44.6616;% in cm
                    dlg.targetHorDisplace   = dlg.viewingDistance*tan(dlg.horTargetEccentricity*(pi/180));% in cm
                    dlg.targetVerDisplace   = dlg.viewingDistance*tan(dlg.verTargetEccentricity*(pi/180));% in cm
                    dlg.targetHorDisplace_pureHorizontal = dlg.viewingDistance*tan(dlg.targetEccentricity*(pi/180));% in cm

                    %dlg.targetHorDisplace   = 69.6453;% in cm
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

                  % experimental variable 1: charging location (4 locations: [...] )
            i = i + 1;
            conditionVars(i).name   = 'chargingLocation';
            conditionVars(i).values = {'Q1','Q2','Q3','Q4','Hleft','Hright'};
            %conditionVars(i).values = {'Q1','Q2'};
            % - 4 oblique charging locations at 37 deg, one for each quadrant
                % - 32 trials, 8 trials per quadrant
                % - 51 seconds per trial; ~1 minute per trial
                % - ~32 minutes
            % - 2 horizontal charging locations 
                % - 16 trials, 8 trials per side
                % - 51 seconds per trial; ~1 minute per trial
                % - ~ 16 minutes
            % 48 trials total; ~1 hour including breaks
            

            % % experimental variable 2: rebound location (0 deg)
            % i = i + 1;
            % conditionVars(i).name   = 'reboundLocation';
            % conditionVars(i).values = [];

            % trial table options
            trialTableOptions                   = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence     = 'Random';
            trialTableOptions.trialAbortAction  = 'Delay';
            trialTableOptions.trialsPerSession  = 1000;
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);

            % organize this table to get the sequencing correct
            % trialTable

            % add coordinates of the target charging coordinates
            trialTable.chargingTargetX = ones(height(trialTable),1);
            trialTable.chargingTargetY = ones(height(trialTable),1);
           

%             % add eccentric gaze holding duration column            
%             trialTable.gazeHoldingDuration = ones(height(trialTable),1);
% %            uniqueDist                     = unique(trialTable.lineDistance); % unique distances          
% 
%             % add a column for the side that the distance was adjusted
%             trialTable.distanceAdjSide     = zeros(height(trialTable),1);

        end
  


        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            try
                Enum  = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;

                lastFlipTime        = GetSecs;
                secondsRemaining    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;

                % initialize flicker stim start time
                timeStamps     = nan(this.ExperimentOptions.refreshRate*...
                    this.ExperimentOptions.TrialDuration,1);
                timeInd        = 1;
               
                % initialize experimentalState for finite state machine
                % implementation
                experimentalState = 1;
                targetFlashState  = 1;

                while secondsRemaining > 0
                    secondsNow          = GetSecs;
                    secondsElapsed      = secondsNow - thisTrialData.TimeStartLoop;
                   % if ~unlimitedTime
                    secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;
                    timeStamps(timeInd) = secondsNow;
                    if timeInd > 1
                        secondsperIteration = secondsperIteration + (secondsNow - timeStamps(timeInd-1));
                        %waitTime4Button     = waitTime4Button - (secondsNow - timeStamps(timeInd-1));
                    else
                        secondsperIteration = 0;
                    end
                    timeInd             = timeInd + 1;
                    %end
%                     if ~unlimitedTime
%                         secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;
%                         timeStamps(timeInd) = secondsNow;
%                         if timeInd > 1
%                             secondsperIteration = secondsperIteration + (secondsNow - timeStamps(timeInd-1));
%                             %waitTime4Button     = waitTime4Button - (secondsNow - timeStamps(timeInd-1));
%                         else
%                             secondsperIteration = 0;
%                         end
%                         timeInd             = timeInd + 1;
%                     end

                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------


                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);

                    fixRect = [0 0 10 10];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    %fixRect =  [440   190   450   300];
                    %fixRect =  [500   290   510   300]';
                    
                    switch experimentalState
                        % State 1: Trial start, central fixation (0 deg),
                        % flashing target, 5 seconds
                        case 1
                            if secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(1) && ...
                            secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(2)
                                Beeper(500,0.4,0.15); % start trial beep
                                experimentalState = 2;
                                targetFlashState  = 1; % target flashing
                            end
                        % State 2: Eccentric Gaze Holding (40 deg),
                        % continuous target, 30 seconds
                        case 2
                            % if gaze holding is long (30 seconds)
                            if secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(3) && ...
                            secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(4) %&& ...
                            %thisTrialData.gazeHoldingDuration == 30
                                experimentalState = 3;
                                targetFlashState  = 2; % target continuous
                                Beeper(500,0.4,0.15);  % initial beep to indicate state change
                            end
                        % State 3: Keep target on for 500 ms before
                        % flashing           
                        case 3 
                            if secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(5) && ...
                            secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(6)
                                experimentalState = 4;
                                targetFlashState  = 3;
                                Beeper(500,0.4,0.15);
                            end

                        % State 4: flashing target for 14.5 seconds
                        case 4
                            if secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(7) && ...
                            secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(8)
                                %Beeper(1000,0.4,0.15);
                                experimentalState = 5;
                                targetFlashState  = 1;
                                %targetFlashState  = 3; % Bisection stimulus
                                %GetSecs
                            end                        
                    end

                    % TARGET FINITE-STATE MACHINE % -----------------------
                    % Only draw for 16.7 ms, then off for 983.3 ms
                    switch targetFlashState
                        case 1 % Target State 1: Flashing
                            if secondsperIteration <= 0.0167 && secondsperIteration >= 0
                                % Draw fixation position at central position
                                % (0 deg, listing secondary position, disconjugate)
                                Screen('FillOval', graph.window,  this.fixColor, fixRect);
                            elseif mod(secondsperIteration,0.0167) < (0.0167)*(0.75) && ...
                                    secondsperIteration >= 0 && ...
                                    secondsperIteration <= 0.0167*2
                                % If secondsperIteration is delayed by half
                                % a frame or less, then reset the counter
                                % by subtracting off the delay
                                secondsperIteration = secondsperIteration - ...
                                    mod(secondsperIteration,0.0167);
                                Screen('FillOval', graph.window,  this.fixColor, fixRect);
                            end
                            if secondsperIteration > 0.0167 %&& expState < 3
                                secondsperIteration = -0.98330;
                            end
                        case 2 % Target State 2: Continuous
                            % Draw fixation position in eccentric position
                            % (40 deg, listing secondary position, conjugate)
                            % calculate the fixation eccentricity in pixels
                
                            % compute the x-y screen coordinates of the
                            % target location for charging
                            [eccentricFix_Pixels] = targetLocationCalculation(thisTrialData,this.ExperimentOptions);

                            % eccentricFix_Pixels = this.ExperimentOptions.targetEccentricity*(this.ExperimentOptions.targetHorDisplace/...
                            %     this.ExperimentOptions.targetEccentricity)*...
                            %     (this.ExperimentOptions.screenResolutionHor/this.ExperimentOptions.screenWidth);
                            % check if debugger mode off or on
                            switch this.ExperimentOptions.Debug.DebugMode
                                case 0 % debugger mode off
%                                     fixRect = [fixRect(1)+eccentricFix_Pixels ...
%                                         fixRect(2) ...
%                                         fixRect(3)+eccentricFix_Pixels ...
%                                         fixRect(4)]';
                                    fixRect = [fixRect(1)+eccentricFix_Pixels(1) ...
                                        fixRect(2)+eccentricFix_Pixels(2) ...
                                        fixRect(3)+eccentricFix_Pixels(1) ...
                                        fixRect(4)+eccentricFix_Pixels(2)]';
%                                     fixRect = [fixRect(1)+eccentricFix_Pixels(1) ...
%                                         fixRect(2) ...
%                                         fixRect(3)+eccentricFix_Pixels(1) ...
%                                         fixRect(4)]';
                                otherwise
                                    % Scaled to the debugger mode window (scaling factor
                                    % in denominator (i.e., 7.322)
                                    fixRect= [fixRect(1)+round(436.5/7.322) fixRect(2) ...
                                        fixRect(3)+round(436.5/7.322) fixRect(4)]';
                            end  
                            Screen('FillOval', graph.window,  this.fixColor, fixRect);                       
                        case 3 % Target State 3: First part of half-second target state
                            Screen('FillOval', graph.window,  this.fixColor, fixRect);
                            secondsperIteration = -0.500; 
                            targetFlashState    = 1;
%                         case 4 % Target State 4: Second part of half-second target state
%                             if secondsperIteration <= 0.5 && secondsperIteration >= 0
%                                 1;
%                             else
%                                 Screen('FillOval', graph.window,  this.fixColor, fixRect);
%                             end
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

               end
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------
            
            catch ex
                rethrow(ex)
            end

            % -------------------------------------------------------------
            % --- NESTED HELPER FUNCTIONS ---------------------------------
            % -------------------------------------------------------------

            function [targetLocation_Pixels] = targetLocationCalculation(thisTrialData,ExperimentOptions)
                % calculate the target location  
                
                switch thisTrialData.chargingLocation
                    % y axis is flipped in screen coordinates
                    % (x-axis from left to right: - to +)
                    % (y-axis from bottom to top: + to -)
                    case 'Q1'
                        %XYtargetLocation = [28.2843 28.2843];
                        XYtargetLocation = [28.2843 -28.2843];
                    case 'Q2'
                        %XYtargetLocation = [-28.2843 28.2843];
                        XYtargetLocation = [-28.2843 -28.2843];
                    case 'Q3'
                        %XYtargetLocation = [-28.2843 -28.2843];
                        XYtargetLocation = [-28.2843 28.2843];
                    case 'Q4'
                        %XYtargetLocation = [28.2843 -28.2843];
                        XYtargetLocation = [28.2843 28.2843];
                    case 'Hleft'
                        XYtargetLocation = [-37 0];
                    case 'Hright'
                        XYtargetLocation = [37 0];
                end
                % horizontal and vertical coordinates (in pixels) of the target for horizontal trials (H=x and V=0)       
                if contains(string(thisTrialData.chargingLocation),'Hright') || ...
                        contains(string(thisTrialData.chargingLocation), 'Hleft')
                    verTargetLocation_Pixels = 0;
                    horTargetLocation_Pixels = XYtargetLocation(1)*(ExperimentOptions.targetHorDisplace_pureHorizontal/...
                                abs(XYtargetLocation(1)))*...
                                (ExperimentOptions.screenResolutionHor/ExperimentOptions.screenWidth); 
                % horizontal and vertical coordinates (in pixels) of the target for oblique trials (H=x and V=y)      
                else
                    verTargetLocation_Pixels = XYtargetLocation(2)*(ExperimentOptions.targetVerDisplace/...
                                    abs(XYtargetLocation(2)))*...
                                    (ExperimentOptions.screenResolutionVer/ExperimentOptions.screenHeight);
                    horTargetLocation_Pixels = XYtargetLocation(1)*(ExperimentOptions.targetHorDisplace/...
                                abs(XYtargetLocation(1)))*...
                                (ExperimentOptions.screenResolutionHor/ExperimentOptions.screenWidth);   
                end
                targetLocation_Pixels = [horTargetLocation_Pixels verTargetLocation_Pixels];

%                 dlg.targetEccentricity  = 28.2843;% in deg
%                     dlg.targetHorDisplace   = 17.9722;% in cm
%                     dlg.targetVerDisplace   = 17.9722;% in cm
%                     dlg.screenWidth         = 59.5;   % in cm
%                     dlg.screenHeight        = 33.5;   % in cm
%                     dlg.screenResolutionHor = 3840;   % in pixels
%                     dlg.screenResolutionVer = 2160;   % in pixels
            end
        end
    end
end