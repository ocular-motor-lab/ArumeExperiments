classdef OpticFlow_DualTask < ArumeExperimentDesigns.EyeTracking

    % OpticFlow_DualTaskexperiment for Arume 

    properties
        camera
        uicomponents
        audio
        shapes
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);

            %% ADD new options
            dlg.ObserverID = {'test'};
            dlg.TaskType = {{'Visual Search','Heading','Both','All interleaved'}};
            dlg.UniformityOptions = {{'Only Uniform' '{Only non-uniform}' 'both'}};
            dlg.NumDots = {2000, 'Number of dots',[1000,100000]};
            dlg.DotSz = {12, 'dot size (pixels)',[1,100]}; % px - preferable odd
            dlg.HFOV = {66.35, 'horizontal FoV (degrees)',[1,10000]}; % based on view distance of 1.3000 meters
            dlg.FCP = {60, 'far clipping plane',[1,1000]}; % in meters
            dlg.ObserverHeight = {1.23, 'Observer Height',[0.1,10]}; % Center of the screen in meters
            dlg.DotSizeCue = {{'0','{1}'}, 'Size Cue?'};

            % condition parameters
            % dlg.useeyelink = { {'{0}','1'}, 'Use Eyelink'};
            dlg.HeadingChanges = {[-15, -12.5, -10, -7.5, -5, -2.5, 2.5, 5, 7.5, 10, 12.5, 15], 'Heading Deltas (degrees)',[-100,100]}; % in meters per second walking = 1.31, jogging = 3.25, running = 5.76, driving = 13.41
            dlg.HeadingChangeDuration = {2, 'Heading change duration',[0,10]};
            dlg.Smoothing = {{'Gaussian','Linear','None'}};
            dlg.WalkSpeed = {3.25, 'Locomotion Speed (m/sec)',[0,100]}; % in meters per second walking = 1.31, jogging = 3.25, running = 5.76, driving = 13.41
            dlg.DotLifetime = {8, 'Dot Lifetime (secs)',[0,20]}; % in secs
            dlg.NumberTrials = {20, 'Number of Trials Per Condition',[1,10000]};
            dlg.AuditoryFeedback = {{'0','{1}'}, 'Auditory Feedback?'};

            %% CHANGE DEFAULTS values for existing options

            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult Speed Stimulus'; % which variables to display every trial in the command line separated by spaces

            dlg.DisplayOptions.ScreenWidth = { 121 '* (cm)' [1 3000]};
            dlg.DisplayOptions.ScreenHeight = { 68 '* (cm)' [1 3000]};
            dlg.DisplayOptions.ScreenDistance = { 60 '* (cm)' [1 3000]};
            
            dlg.HitKeyBeforeTrial = 0;
            dlg.TrialDuration = {8, 'Trial duration',[1,100]}; % in secs
            dlg.TrialsBeforeBreak = 500; %             dlg.numberblocks = {5, 'Number of Blocks', [1,1000]};
            dlg.TrialAbortAction = 'Repeat';
        end
        
        function trialTable = SetUpTrialTable(this)
            
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Density';
            switch(this.ExperimentOptions.UniformityOptions)
                case 'Only Uniform'
                    conditionVars(i).values = {'Uniform'};
                case 'Only non-uniform'
                    conditionVars(i).values = {'NonUniform'};
                case 'both'
                    conditionVars(i).values = {'Uniform' 'NonUniform'};
            end

            i = i+1;
            conditionVars(i).name   = 'Task';
            switch ( this.ExperimentOptions.TaskType ) 
                case 'Visual Search'
                    conditionVars(i).values = {'Visual Search'};
                case 'Heading'
                    conditionVars(i).values = {'Heading'};
                case 'Both'
                    conditionVars(i).values = {'Both'};
                case 'All interleaved'
                    conditionVars(i).values = {'Visual Search' 'Heading' 'Both'};
            end

            i = i+1;
            conditionVars(i).name = 'WalkingSpeed';
            conditionVars(i).values =  this.ExperimentOptions.WalkSpeed;

            i = i+1;
            conditionVars(i).name = 'HeadingChange';
            conditionVars(i).values =  this.ExperimentOptions.HeadingChanges;


            % remember - we only really want the heading-change condition
            % to be the IV here. We do not care that there are n trials per
            % searchtarget condition, and/or task order condition. 
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Delay';
            trialTableOptions.trialsPerSession = 1000;
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberTrials;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);

            this.ExperimentOptions.nTrialsTotal = height(trialTable);

            % set up delta-onset time
            mintonset = 1; % heading change cannot happen immediately
            mintoffset = 1; % and the trial cannot end immediately after heading change is completed
            trange = this.ExperimentOptions.TrialDuration-this.ExperimentOptions.HeadingChangeDuration-mintoffset-mintonset;
            trialTable.HeadingChangeOnsetTime = rand(height(trialTable),1).*trange + mintonset;

            % set up target type
            targetTypes = categorical({'red squares' 'red circles' 'green squares' 'green circles'});
            trialTable.SearchTarget = targetTypes(randi(length(targetTypes),this.ExperimentOptions.nTrialsTotal,1))';

            % set up target present/absent. Arume hates logicals so use doubles
            trialTable.TargetPresent = double(rand(this.ExperimentOptions.nTrialsTotal,1)>.5);

            % set up target present/absent
            responseOrder = categorical({'HeadingFirst' 'SearchFirst'});
            trialTable.ResponseOrder = responseOrder(randi(length(responseOrder),this.ExperimentOptions.nTrialsTotal,1))';

            % and trial number
            trialTable.Trial = (1:this.ExperimentOptions.nTrialsTotal)';

            % and block derivative (block change)
            trialTable.BlockChange = double([diff(trialTable.BlockNumber);0]);


        end
        
        % run initialization before the first trial is run
        % Use this function to initialize things that need to be
        % initialized before running but don't need to be initialized for
        % every single trial
        function shouldContinue = initBeforeRunning( this )

            % create camera object with rendering properties
            this = setUpDotAppearanceAndCameraProjectionMatrix(this);

            % UI screen coordinates and shapes
            this = setUpUIVariables(this);

            % give feedback in the form of a sound effect?
            if this.ExperimentOptions.AuditoryFeedback
                this = getAudioFeedbackFiles(this);
            end
            shouldContinue = 1;
        end
        
        % runPreTrial
        % use this to prepare things before the trial starts
        function [trialResult, thisTrialData] = runPreTrial(this, thisTrialData )

            % initialize the camera to the starting position every trial
            this.camera.pos = [0, this.ExperimentOptions.ObserverHeight, 0, 0];

            % precompute the x-z position for every frame in the trial
            this = createLocomotionTrajectory(this,thisTrialData);

            % create array of randomly positioned distractor locations
            this = initializeShapePlacement(this,thisTrialData);

            % create a smaller array of targets
            this = initializeTargetShapes(this,thisTrialData);

            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
        end
        
        

        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )

            try

                Enum = ArumeCore.ExperimentDesign.getEnum();
                % graph = this.Graph; %% object of class ArumeCore.Display with all the psychtoolbox initialization, window handle, and a few more things FLIP
                trialResult = Enum.trialResult.CORRECT;

                lastFlipTime        = GetSecs;
                % secondsRemaining    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;

                [this,thisTrialData,exitedEarly] = presentStimulus(this,thisTrialData);
                % if exitedEarly; break; end

                % request response from observer
                switch thisTrialData.Task
                    case 'Visual Search'
                        [this, thisTrialData, exitedEarly]  = getVisualSearchResponse(this, thisTrialData);
            
                    case 'Heading'
                        [this, thisTrialData,  exitedEarly]  = getHeadingResponse(this, thisTrialData);
            
                    case 'Both'
                        % randomly choose which one goes first though. 
                        switch thisTrialData.ResponseOrder
                            case 'HeadingFirst'
                                [this, thisTrialData, exitedEarly]  = getVisualSearchResponse(this, thisTrialData);
                                if ~exitedEarly
                                    [this, thisTrialData, exitedEarly]  = getHeadingResponse(this, thisTrialData);
                                end
                            case 'SearchFirst'
                                [this, thisTrialData, exitedEarly]  = getHeadingResponse(this, thisTrialData);
                                if ~exitedEarly
                                    [this, thisTrialData, exitedEarly]  = getVisualSearchResponse(this, thisTrialData); %#ok<*ASGLU>
                                end
                        end
                end

            catch exq
                
                rethrow(ex)
            end
            
        end        


        % runPostTrial
        function [trialResult, thisTrialData] = runPostTrial(this, thisTrialData)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;

            exitedEarly = endOfTrialSequence(this,thisTrialData);
        end
        
        % run cleaning up after the session is completed or interrupted
        function cleanAfterRunning(this)
        end
        
    end
    
end