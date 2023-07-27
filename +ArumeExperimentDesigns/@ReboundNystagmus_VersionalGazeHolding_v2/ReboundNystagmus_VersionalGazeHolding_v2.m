classdef ReboundNystagmus_VersionalGazeHolding_v2 < ArumeExperimentDesigns.EyeTracking
    % ReboundNystagmus_VersionalGazeHolding_v2 experiment for Arume
    %
    % ---------------------------------------------------------------------
    % Updates
    % ---------------------------------------------------------------------
    % 11/28/2022 (v2) - Modify to run a passive viewing task and to
    % simplify to a finite-state machine code design. This will be for the
    % vergence task.
    %
    % 12/12/2022 (v2) - Incorporate the finite state machine architecture.

    % Before running:
    %  1) Connect the Arduino board to the computer.
    %  2) Upload the Arduino firmware titled
    % "lightOn_11282022_v2.ino", found in C:\Users\opt-omlab\Desktop\TerenceProjects\Arduino\Sketches\lightOn_11282022

    %
    % Coded by Terence Tyson, 11/28/2022
    % ---------------------------------------------------------------------
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
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult experimentalCondition'; % which variables to display every trial in the command line separated by spaces

%             dlg.DisplayOptions.ScreenWidth    = { 121 '* (cm)' [1 3000] };
%             dlg.DisplayOptions.ScreenHeight   = { 68 '* (cm)' [1 3000] };
%             dlg.DisplayOptions.ScreenDistance = { 60 '* (cm)' [1 3000] };

            dlg.HitKeyBeforeTrial         = 1;
            dlg.TrialsBeforeBreak         = 20;
            dlg.TrialAbortAction          = 'Repeat';
            dlg.SerialPortOpenPauseDur    = 2;
            dlg.TrialDurSequence          = [5 35 35 45 45] + dlg.SerialPortOpenPauseDur;
            dlg.TrialDurSequence_Control  = [0 5 5 5.2];
            dlg.TrialDurSequence_Vergence = [5 35 35 55 55 65 65] + dlg.SerialPortOpenPauseDur;
            dlg.TrialDuration             = 65;
            dlg.RestDuration              = 0;
            dlg.flickerRate               = [];
            dlg.refreshRate               = 60; % 60 Hz monitor refresh rate
            dlg.beepDuration              = 0.4; % 400 ms
            %dlg.LeftORRight_Gaze  = 'L';


            % additional parameters on the setup
            whichDisplay                    = 'Lab'; % lab or office?

            switch whichDisplay
                case 'Office'
                    dlg.viewingDistance     = 33.4;   % in cm
                    dlg.targetEccentricity  = 40;     % in deg
                    %dlg.targetHorDisplace   = 28;     % in cm
                    dlg.targetHorDisplace   = ...
                        dlg.viewingDistance*tan(dlg.targetEccentricity*(pi/180)); % in cm
                    dlg.screenWidth         = 59.5;   % in cm
                    dlg.screenHeight        = 33.5;   % in cm
                    dlg.screenResolutionHor = 3840;   % in pixels
                    dlg.screenResolutionVer = 2160;   % in pixels
                    dlg.lineFixed           = 20;     % in deg
                    dlg.textScreenFontSize  = 34;     % font size
                case 'Lab'
                    dlg.viewingDistance     = 83;     % in cm
                    dlg.targetEccentricity  = 40;     % in deg
                    %dlg.targetHorDisplace   = 69.6453;% in cm
                    dlg.targetHorDisplace   = ...
                        dlg.viewingDistance*tan(dlg.targetEccentricity*(pi/180)); % in cm
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

            % experimental conditions (5 conditions)
            i = i + 1;
            conditionVars(i).name   = 'experimentalCondition';
            %conditionVars(i).values = {'leftFar','rightFar','vergence'};
            %conditionVars(i).values = {'vergence'};
            %conditionVars(i).values = {'vergence','vergenceLeft','vergenceRight'};
            %conditionVars(i).values = {'vergence','leftFar','rightFar'};
            conditionVars(i).values = {'vergence'};

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

                % initialize experimentalState for finite state machine
                    % implementation
                experimentalState = 1;
                targetFlashState  = 1;
                deviceState       = 1;

                % initialize arduino device
                deviceSpecs.Port     = 'COM3'; % COM4 on desktop
                deviceSpecs.Rate     = 9600;
                deviceSpecs.DataBits = 8;
                deviceSpecs.StopBits = 1;                                                                      
                device = serial(deviceSpecs.Port,'BaudRate',deviceSpecs.Rate,...
                    'DataBits',deviceSpecs.DataBits,'StopBits',deviceSpecs.StopBits);   
                fopen(device);
                pause(this.ExperimentOptions.SerialPortOpenPauseDur);

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

                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------

                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);
                    fixRect = [0 0 10 10];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    
                    % Finite-state machine implementation % --------------

                    % TWO FINITE-STATE MACHINES ARE IMPLEMENTED IN
                    % CONJUCTION:
                    %
                    % 1) Trial sequence finite-state machine 
                    % 2) Target finite-state machine

                    % TRIAL SEQUENCE FINITE-STATE MACHINE % ---------------
                    switch thisTrialData.experimentalCondition
                        %case 'rightFar'
                        % Eccentric gaze at far distance 
                        case {'rightFar','leftFar'}
                            switch experimentalState

                                % State 1: Trial start
                                case 1
                                    Beeper(500,0.4,0.4); % start trial beep
                                    experimentalState = 2;

                                % State 2: Fixation at central position (0 deg) 
                                % Ocular Property: 
                                % Disconjugate, secondary listing position
                                case 2
                                    if secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(1) && ...
                                            secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(2)
                                        experimentalState = 3;
                                        targetFlashState  = 2; % Continuous target
                                        Beeper(500,0.4,this.ExperimentOptions.beepDuration); % initial beep to indicate state change
                                    end
                                
                                % State 3: Eccentric gaze holding (40 deg)
                                % Ocular Property: 
                                % Conjugate, secondary listing position
                                case 3
                                    % calculate the fixation eccentricity in pixels
                                    eccentricFix_Pixels = this.ExperimentOptions.targetEccentricity*(this.ExperimentOptions.targetHorDisplace/...
                                        this.ExperimentOptions.targetEccentricity)*...
                                        (this.ExperimentOptions.screenResolutionHor/this.ExperimentOptions.screenWidth);
                                    
                                    switch thisTrialData.experimentalCondition
                                        % Rightward gaze-holding trial
                                        case 'rightFar'
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
                                        % Leftward gaze-holding trial
                                        case 'leftFar'
                                            % check if debugger mode off or on
                                            switch this.ExperimentOptions.Debug.DebugMode
                                                case 0 % debugger mode off
                                                    fixRect = [fixRect(1)-eccentricFix_Pixels ...
                                                        fixRect(2) ...
                                                        fixRect(3)-eccentricFix_Pixels ...
                                                        fixRect(4)]';
                                                otherwise
                                                    % Scaled to the debugger mode window (scaling factor
                                                    % in denominator (i.e., 7.322)
                                                    fixRect= [fixRect(1)+round(436.5/7.322) fixRect(2) ...
                                                        fixRect(3)+round(436.5/7.322) fixRect(4)]';
                                            end    
                                    end


                                    if secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(3) && ...
                                        secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(4)
                                        experimentalState = 4;
                                        targetFlashState  = 1; % Return to flashing target state
                                        Beeper(500,0.4,this.ExperimentOptions.beepDuration);
                                    end
                                  
                                % State 4: Fixation at central position (0 deg) 
                                % 10 seconds
                                % Ocular Property: 
                                % Disconjugate, secondary listing position
                                case 4
                                    if secondsRemaining < this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence(5)
                                        experimentalState = 5;
                                    end

                                % State 5: End trial
                                % REST (eyes closed)
                                case 5
%                                     response = 'NA';
%                                     thisTrialData.Response = response;
%                                     thisTrialData.ResponseTime = GetSecs;
                                    break                  
                            end
                        % Vergence task    
                        %case 'vergence'
                        case {'vergence','vergenceLeft','vergenceRight'}
                            switch experimentalState
                                % State 1: Trial start
                                case 1
                                    Beeper(500,0.4,this.ExperimentOptions.beepDuration); % start trial beep
                                    experimentalState = 2;
                                
                                % State 2: Fixation at central position (0
                                % deg)
                                % Far target (monitor)
                                case 2
                                    if secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Vergence(1) && ...
                                            secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Vergence(2)
                                        experimentalState = 3;
                                        targetFlashState  = 3; % Blank monitor
                                        Beeper(500,0.4,this.ExperimentOptions.beepDuration); % initial beep to indicate state change
                                    end
                                % State 3: Fixation at central position (0 deg) 
                                % Near Target (LED)
                                case 3
                                    % The three vergence conditions
                                    switch thisTrialData.experimentalCondition
                                        case 'vergence'
                                            % Central LED
                                            [deviceState] = controlLED('ON',device,deviceState);        
                                        case 'vergenceLeft'
                                            % Left LED
                                            [deviceState] = controlLED('ON_VERGENCE_LEFT',device,deviceState);       
                                        case 'vergenceRight'
                                            % Right LED
                                            [deviceState] = controlLED('ON_VERGENCE_RIGHT',device,deviceState);
                                    end
                                    if secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Vergence(3) && ...
                                                    secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Vergence(4)
                                        experimentalState = 4;
                                        targetFlashState  = 1; % Flashing target
                                        Beeper(500,0.4,this.ExperimentOptions.beepDuration); % initial beep to indicate state change
                                    end
                                % State 4: Fixation at central position (0
                                % deg)
                                % Far Target (monitor)
                                case 4
                                    % Turn LED off
                                    [deviceState] = controlLED('OFF',device,deviceState);
                                    if secondsRemaining <= this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Vergence(5) && ...
                                            secondsRemaining > this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Vergence(6)
                                        experimentalState = 5;
                                        targetFlashState = 3; % Blank screen
                                        Beeper(500,0.4,this.ExperimentOptions.beepDuration);
                                    end
                                % State 5: Rest period
                                % REST (eyes closed)
                                % DURATION: 
                                case 5
                                    if secondsRemaining < this.ExperimentOptions.TrialDuration-this.ExperimentOptions.TrialDurSequence_Vergence(7)
                                        experimentalState = 6;
                                        Beeper(500,0.4,this.ExperimentOptions.beepDuration);
                                    end
                                % State 6: End trial
                                % DURATION: 
                                case 6
%                                     response                   = 'NA';
%                                     thisTrialData.Response     = response;
%                                     thisTrialData.ResponseTime = GetSecs;
                                    break 
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
                            end
                            if secondsperIteration > 0.0167 %&& expState < 3
                                secondsperIteration = -0.98330;
                            end
                        case 2 % Target State 2: Continuous
                            % Draw fixation position in eccentric position
                            % (40 deg, listing secondary position, conjugate)
                            Screen('FillOval', graph.window,  this.fixColor, fixRect);
                        case 3 % Target State 3: LED at central position
                            % Blank screen
                            1;
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

                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------
                end

                % ---------------------------------------------------------
                % Close all serial ports ----------------------------------
                % ---------------------------------------------------------
                newPorts = instrfind;
                fclose(newPorts);               

            catch ex
                rethrow(ex)            
            end

            % -------------------------------------------------------------
            % --- NESTED HELPER FUNCTIONS ---------------------------------
            % -------------------------------------------------------------
            function [deviceState] = controlLED(controlState,device,deviceState)
                switch controlState
                    case 'ON'
                        if deviceState == 1
                            % test comms between matlab and arduino
                            fwrite(device,'1');                    
                            deviceState = 2;
                        end
                    case 'ON_VERGENCE_LEFT'
                        if deviceState == 1
                            fwrite(device,'2');                    
                            deviceState = 2;
                        end
                    case 'ON_VERGENCE_RIGHT'
                        if deviceState == 1
                            fwrite(device,'3');                    
                            deviceState = 2;
                        end
                    case 'OFF' % should happen
                        if deviceState == 2                
                            % send bit message to turn off LED
                            fwrite(device,'4'); 
                            % make sure to close port after test
                            fclose(device);
                            deviceState = 3;
                        end
                end
            end
        end
    end
end