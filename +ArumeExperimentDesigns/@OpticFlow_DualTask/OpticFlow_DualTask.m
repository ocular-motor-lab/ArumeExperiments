classdef OpticFlow_DualTask < ArumeExperimentDesigns.EyeTracking
    % OpticFlow_DualTaskexperiment for Arume 
    %
    %     
    properties
        exptparams

            cam_pos
            deltax
            deltaz
            dots
            valididxs
            xWorldFlatten
            zWorldFlatten
            fctr
            dotsorcircles
            targetornot
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);

            %% ADD new options
            dlg.observerid = {'test'};
            dlg.Tasktype = {{'Visual Search','Heading','Both','All interleaved'}};
            dlg.UniformityOptions = {{'Only Uniform' 'Only non-uniform' 'both'}};
            dlg.num_dots = {2000, 'Number of dots',[1000,100000]};
            dlg.dotsz = {12, 'dot size (pixels)',[1,100]}; % px - preferable odd
            dlg.hfov = {66.35, 'horizontal FoV (degrees)',[1,10000]}; % based on view distance of 1.3000 meters
            dlg.fcp = {60, 'far clipping plane',[1,1000]}; % in meters
            dlg.observerheight = {1.23, 'Observer Height',[0.1,10]}; % Center of the screen in meters
            dlg.dotsizecue = {{'0','{1}'}, 'Size Cue?'};

            % condition parameters
            dlg.useeyelink = { {'{0}','1'}, 'Use Eyelink'};
            dlg.headingchanges = {[-15, -12.5, -10, -7.5, -5, -2.5, 2.5, 5, 7.5, 10, 12.5, 15], 'Heading Deltas (degrees)',[-100,100]}; % in meters per second walking = 1.31, jogging = 3.25, running = 5.76, driving = 13.41
            dlg.headingchangeDuration = {2, 'Heading change duration',[0,10]};
            dlg.Smoothing = {{'Gaussian','Linear','None'}};
            dlg.walkspeed = {3.25, 'Locomotion Speed (m/sec)',[0,100]}; % in meters per second walking = 1.31, jogging = 3.25, running = 5.76, driving = 13.41
            dlg.dotlifetime = {8, 'Dot Lifetime (secs)',[0,20]}; % in secs
            dlg.numbertrials = {20, 'Number of Trials Per Condition',[1,10000]};
            dlg.auditoryfeedback = {{'0','{1}'}, 'Auditory Feedback?'};



            %% CHANGE DEFAULTS values for existing options

            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult Speed Stimulus'; % which variables to display every trial in the command line separated by spaces

            dlg.DisplayOptions.ScreenWidth = { 121 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 68 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 60 '* (cm)' [1 3000] };
            
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
            switch ( this.ExperimentOptions.Tasktype ) 
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
            conditionVars(i).values =  this.ExperimentOptions.walkspeed;

            i = i+1;
            conditionVars(i).name = 'HeadingChange';
            conditionVars(i).values =  this.ExperimentOptions.headingchanges;

            i = i+1;
            conditionVars(i).name = 'SearchTarget';
            conditionVars(i).values =  {'red squares' 'red circles' 'green squares' 'green circles'};

            i = i+1;
            conditionVars(i).name = 'TargetPresent';
            conditionVars(i).values =  [0 1];

            i = i+1;
            conditionVars(i).name = 'ResponseOrder';
            conditionVars(i).values =  {'HeadingFirst' 'SearchFirst'};

            
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Delay';
            trialTableOptions.trialsPerSession = 1000;
            trialTableOptions.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.numbertrials;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);


            mintonset = 1; % heading change cannot happen immediately
            mintoffset = 1; % and the trial cannot end immediately after heading change is completed
            trange = this.ExperimentOptions.TrialDuration-this.ExperimentOptions.headingchangeDuration-mintoffset-mintonset;
            trialTable.headingchangeonsettime = rand(height(trialTable),1).*trange + mintonset;

        end
        
        % run initialization before the first trial is run
        % Use this function to initialize things that need to be
        % initialized before running but don't need to be initialized for
        % every single trial
        function shouldContinue = initBeforeRunning( this )


            this.exptparams = setUpDotAppearanceAndCameraProjectionMatrix(this.exptparams);
            this.exptparams = setUpUIVariables(this.exptparams);

            % give feedback in the form of a sound effect?
            if this.exptparams.auditoryfeedback
                this.exptparams = getAudioFeedbackFiles(this.exptparams);
            end


            shouldContinue = 1;
        end

        %% EXTERNAL FILES FOR CLASS FUNCTIONS
        exptparams = setUpUIVariables(exptparams);
        exptparams = setUpDotAppearanceAndCameraProjectionMatrix(exptparams);
        [deltax,deltaz] = createLocomotionTrajectory(thisTrialData,exptparams);
        [exptparams,dots,valididxs,xWorldFlatten,zWorldFlatten] = initializeDotPlacement(thisTrialData, exptparams, cam_pos);
        [dots,fctr,dotsorcircles,targetornot] = initializeTargetDots(dots, deltax, deltaz, exptparams, cam_pos, thisTrialData);

        %%

        
        % runPreTrial
        % use this to prepare things before the trial starts
        function [trialResult, thisTrialData] = runPreTrial(this, thisTrialData )

            % initialize the camera to the starting position every trial
            this.cam_pos = [0, this.exptparams.observerheight, 0, 0];

            % precompute the x-z position for every frame in the trial
            [this.deltax,this.deltaz] = createLocomotionTrajectory(thisTrialData,this.exptparams);

            % create array of randomly positioned distractor locations
            [this.exptparams,this.dots,this.valididxs,this.xWorldFlatten,this.zWorldFlatten] = initializeDotPlacement(thisTrialData, this.exptparams, this.cam_pos);

            % create a smaller array of targets
            [this.dots,this.fctr,this.dotsorcircles,this.targetornot] = initializeTargetDots(this.dots, this.deltax, this.deltaz, this.exptparams, this.cam_pos, thisTrialData);

            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
        end
        
        

        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )

            try


                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;


                lastFlipTime        = GetSecs;
                secondsRemaining    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;


                while secondsRemaining > 0

                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;


                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------


                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);

                    fixRect = [0 0 10 10];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    Screen('FillOval', graph.window,  this.fixColor, fixRect);


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
                                    response = 'R';
                                case 'LeftArrow'
                                    response = 'L';
                            end
                        end
                    end
                    if ( ~isempty( response) )
                        thisTrialData.Response = response;
                        thisTrialData.ResponseTime = GetSecs;

                        break;
                    end
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------


                end
            catch ex
                rethrow(ex)
            end
            
        end        


        % runPostTrial
        function [trialResult, thisTrialData] = runPostTrial(this, thisTrialData)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
        end
        
        % run cleaning up after the session is completed or interrupted
        function cleanAfterRunning(this)
        end
        
    end
    
end