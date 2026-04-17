classdef A1MotionEllipses < ArumeExperimentDesigns.EyeTracking
    % Motion Ellipses foveal threshold exp.
    %     
    properties
        fixRad = 20;
        fixColor = [255 0 0];

        lots_dots1
        lots_dots2
        lots_dots3
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            %% ADD new options
            dlg.Max_Increment_Speed_Percent = { 100 '* (%)' [0.1 100] };
            dlg.Max_Increment_Direction_Angle = { 60 '* (deg)' [0.1 100] };
            dlg.Number_Of_Increments = 9;
            dlg.Stimulus_Type = { {'{both}' 'speed' 'direction'} };

            dlg.Max_RefVelocityComponent = { 2 '* (deg/s)' [0.01 100] };
            dlg.Num_RefVelocitiesPerComponent = 5;

            dlg.Do_Full_Grid = { {'{0}','1'} };
            dlg.Num_Repeats = {8 '* (N)' [1 100] };

            dlg.Dots_Per_Window = 700;
            dlg.Dots_Diameter   = { 1.5 '* (pix)' [0.01 100] };
            dlg.Dots_LifeTime   = { 0.5 '* (sec)' [0.01 100] };
            dlg.Dots_Grey_Level = [0.5];

            dlg.Window_Radius_Deg   = { 0.5 '* (deg)' [0.01 100] };
            dlg.Window_Eccentricity_Deg   = { 0.75 '* (deg)' [0.01 100] };

            dlg.Fixation_Check_WinSize = 1;
            dlg.Fixation_Check_TimeOut = 0.3;

            %% Fixation Configuration
            dlg.Fixation_Type =  { {'none', '{circle}', 'cross'} };
            dlg.Fixation_Size_Deg = 10;  % deg (diameter for circle, arm length for cross)
            dlg.Fixation_Color = [1 1 1] * 255;  % white
            dlg.Fixation_Line_Width = 3;  % for cross only


            dlg.Initial_Fixation_Duration = 0.5;
            dlg.Motion_Duration = 1;
            dlg.Min_Motion_Duration_Before_Response = 0.2;

            dlg.BackgroundBrightness = 0;
            
            %% CHANGE DEFAULTS values for existing options

            dlg.UseEyeTracker = 0;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult Speed Stimulus'; % which variables to display every trial in the command line separated by spaces

            % SamsungOLED
            dlg.DisplayOptions.ScreenWidth = { 169.957 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 95.6009 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 125 '* (cm)' [1 3000] };

            %     % case 'ClaraDesk'
            % screen_dims_mm = [596.74, 335.66]; %https://dl.dell.com/manuals/all-products/esuprt_electronics_accessories/esuprt_electronics_accessories_monitors/dell-p2721q-monitor_user's-guide_en-us.pdf
            % distance_from_screen = 0.5; %meters
            
            dlg.HitKeyBeforeTrial = 0;
            dlg.TrialDuration = 5;
            dlg.TrialsBeforeBreak = 15;
            dlg.TrialAbortAction = 'Repeat';

        end
        
        function trialTable = SetUpTrialTable(this)

            max_degS = this.ExperimentOptions.Max_RefVelocityComponent;
            
            if ( this.ExperimentOptions.Do_Full_Grid )
                % for entire grid of reference vectors:
                % grid of reference speeds
                [ref_Vx ref_Vy] = meshgrid(-max_degS:1:max_degS);
                % zip together
                ref_vecs = [ref_Vx(:), ref_Vy(:)];

            else

                %% BUT: I only want 9 of them: In a 3x3 square, but the direction (ie. signage of components) can be varying
                % use participant_ID to seed the rng so it gets the same one everytime
                rng(keyHash(this.Session.subjectCode)/10^10)

                % axis of the 

                % grid of reference speeds
                [ref_Vx ref_Vy] = meshgrid(-max_degS:0);
                [xxx yyy] = meshgrid(1:length(-max_degS:0));

                % flip some of the signs to randomize
                flip_num_Vx = ceil(numel(ref_Vx)*rand);% random number of them to flip
                flip_idx_Vx =  randperm(numel(ref_Vx), flip_num_Vx); % which ones to flip
                ref_Vx(flip_idx_Vx) = -ref_Vx(flip_idx_Vx); % flip those SIGNS

                flip_num_Vy = ceil(numel(ref_Vy)*rand);% random number of them to flip
                flip_idx_Vy =  randperm(numel(ref_Vy), flip_num_Vy); % which ones to flip
                ref_Vy(flip_idx_Vy) = -ref_Vy(flip_idx_Vy); % flip those SIGNS

                % make a datetime
                nowo = datetime("now");
                % seed the random back to something random to make sure no duplicate trials
                rng(second(nowo) + minute(nowo) + hour(nowo));


                % zip together
                ref_vecs = [ref_Vx(:), ref_Vy(:)];
            end

            % build the table
            t = ArumeCore.TrialTableBuilder();

            %all the reference vectors
            celled_ref_vecs = {};
            for n = 1:size(ref_vecs, 1)
                celled_ref_vecs{n} = ref_vecs(n, :);
            end
            t.AddConditionVariable('ReferenceVelocity',celled_ref_vecs);

            % the condition table will generate the appropriate
            % combinations itself
            % t.AddConditionVariable('ReferenceVelocityY',ref_vecs(:, 1)');
            % t.AddConditionVariable('ReferenceVelocityX',ref_vecs(:, 2)');

            


            % comparison vector - how much of an increment on the reference vector?
            t.AddConditionVariable('Increment',-100:(200)/(this.ExperimentOptions.Number_Of_Increments - 1):100);

            % what stimulus type?
            switch(this.ExperimentOptions.Stimulus_Type)
                case 'both'
                    t.AddConditionVariable('TypeOfIncrement',{'Speed' 'Direction'});
                case 'speed'
                    t.AddConditionVariable('TypeOfIncrement',{'Speed'});
                case 'direction'
                    t.AddConditionVariable('TypeOfIncrement',{'Direction'});
            end
            t.AddConditionVariable('OddballWindow',[1 2 3]);

            % Example of how to do blocks if neecessary. Just filter the
            % condition table to say which trials belong to that block
            %
            % t.AddBlock(find(t.ConditionTable.TypeOfIncrement=='Direction'), 1);
            % t.AddBlock(find(t.ConditionTable.TypeOfIncrement=='Speed'), 1);

            trialSequence = 'Random';
            blockSequence =  'Sequential';
            blockSequenceRepeatitions = this.ExperimentOptions.Num_Repeats;
            abortAction = 'Delay';
            trialsPerSession = 100;
            trialTable = t.GenerateTrialTable(trialSequence, blockSequence, blockSequenceRepeatitions, abortAction,trialsPerSession);


            trialTable.Window1_Angle = 125 + 110*rand(height(trialTable),1); % TODO: comment what this means
            trialTable.Window2_Angle = wrapTo360(trialTable.Window1_Angle-120);
            trialTable.Window3_Angle = wrapTo360(trialTable.Window1_Angle-240);

            compVelocity = cell(size(trialTable.ReferenceVelocity, 1), 1);
            %compVelocity = trialTable.ReferenceVelocity;
            %compVelocityXY = [trialTable.ReferenceVelocityX, trialTable.ReferenceVelocityY]; % init to something
            directionTrials = t.ConditionTable.TypeOfIncrement=='Direction';
            speedTrials = t.ConditionTable.TypeOfIncrement=='Speed';

            directionTrialsInds = find(directionTrials==1);
            speedTrialsInds = find(speedTrials==1);
            
            % only want the increments for the direction trials
            angleIncrement = this.ExperimentOptions.Max_Increment_Direction_Angle .* trialTable.Increment(directionTrials)/100;

            for i=1:size(directionTrialsInds, 1)
                thisTrialAngle = angleIncrement(i);
                rotation_matrix = [ cosd(thisTrialAngle), -sind(thisTrialAngle);
                    sind(thisTrialAngle), cosd(thisTrialAngle)];

                %compVelocity(directionTrialsInds(i),:) = (rotation_matrix * trialTable.ReferenceVelocity{directionTrialsInds(i),:}')';
                compVelocity(directionTrialsInds(i)) = {(rotation_matrix * trialTable.ReferenceVelocity{directionTrialsInds(i),:}')'};
            end

            for i = 1:size(speedTrialsInds, 1)
                compVelocity(speedTrialsInds(i)) = {trialTable.ReferenceVelocity{speedTrialsInds(i),:} + ...
                    this.ExperimentOptions.Max_Increment_Speed_Percent/100 .* trialTable.Increment(speedTrialsInds(i))/100 .* trialTable.ReferenceVelocity{speedTrialsInds(i),:}};

            end
            

            trialTable.Window1_Velocity = trialTable.ReferenceVelocity;
            trialTable.Window2_Velocity = trialTable.ReferenceVelocity;
            trialTable.Window3_Velocity = trialTable.ReferenceVelocity;
            
            trialTable.Window1_Velocity(trialTable.OddballWindow == 1 ) = compVelocity(trialTable.OddballWindow == 1 );
            trialTable.Window2_Velocity(trialTable.OddballWindow == 2 ) = compVelocity(trialTable.OddballWindow == 2 );
            trialTable.Window3_Velocity(trialTable.OddballWindow == 3 ) = compVelocity(trialTable.OddballWindow == 3 );


        end
        
        % runPreTrial
        % use this to prepare things before the trial starts
        function [trialResult, thisTrialData] = runPreTrial(this, thisTrialData )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;



            % the range that the comparison stimulus can increment from the reference
            inc_range_perc = this.ExperimentOptions.Max_Increment_Speed_Percent/100*[-1 1];
            inc_range_dir = this.ExperimentOptions.Max_Increment_Direction_Angle*[-1 1]; % in degrees
            % type of stimulus variation:
            stim_type = this.ExperimentOptions.Stimulus_Type; %{ {'{both}' 'speed' 'direction'} };
            max_degS = this.ExperimentOptions.Max_RefVelocityComponent;

            white_col = 255*[1 1 1] * WhiteIndex(screenNumber);
            black_col = [1 1 1] * BlackIndex(screenNumber);
            grey_col = white_col * this.ExperimentOptions.Dots_Grey_Level;
            all_dots_colour = grey_col;

            dots_per_window = this.ExperimentOptions.Dots_Per_Window;  % dots per window
            num_dots    = dots_per_window*3;  % total dots across all 3 windows
            diameter    = this.ExperimentOptions.Dots_Diameter;
            lifetime_S  = this.ExperimentOptions.Dots_LifeTime;


            degS_to_pixFrame_convFactor = mm_per_deg*pixels_per_mm/refreshHz;
            deg_to_pix_convFactor = mm_per_deg * pixels_per_mm(1);




            %% Window config
            % circle window radii (deg) - could be different for each window
            window_radii_deg = this.ExperimentOptions.Window_Radius_Deg*[1 1 1];
            window_radii = window_radii_deg .* deg_to_pix_convFactor;

            % Distance of window centers from fixation point (pixels)
            window_eccentricity_deg = this.ExperimentOptions.Window_Eccentricity_Deg*[1 1 1];
            window_eccentricity = window_eccentricity_deg * deg_to_pix_convFactor;


            window_angles = [thisTrialData.Window1_Angle thisTrialData.Window2_Angle  thisTrialData.Window3_Angle ];


            % Boundary margin around the circle to generate dots in:
            % ex. the dots will generate in bord_marg*circle_diameter square space to avoid clumping in one direction
            % for lotsdots1.bordersX/bordersY, etc.
            bord_marg = 3;

            window_centers = zeros(numTrials, 3, 2);

            for n = 1:numTrials
                for w = 1:3
                    angle_rad = deg2rad(window_angles(n, w));
                    window_centers(n, w, 1) = screenCenterX + window_eccentricity * cos(angle_rad);
                    window_centers(n, w, 2) = screenCenterY - window_eccentricity * sin(angle_rad);  % negative because Y increases downward
                end
            end

            %% Create LotsDots for Window 1
            lifetimes1   = (lifetime_S*ones(dots_per_window, 1));
            ages1        = lifetimes1(1)*rand(dots_per_window, 1);
            diameters1   = (diameter*ones(dots_per_window, 1));
            speeds1      = (speed*ones(dots_per_window,1));
            locations1   = (ones(dots_per_window, 2));
            refreshHzes1 = (refreshHz*ones(dots_per_window, 1));

            draw_bordersX1 = [window_centers(1, 1, 1) - bord_marg*window_radii(1), window_centers(1, 1, 1) + bord_marg*window_radii(1)];
            draw_bordersY1 = [window_centers(1, 1, 2) - bord_marg*window_radii(1), window_centers(1, 1, 2) + bord_marg*window_radii(1)];

            % Fill locations randomly around window 1's circular area
            for n = 1:dots_per_window

                randX = draw_bordersX1(1) + 2*bord_marg*window_radii(2)*rand(1,1);
                randY = draw_bordersY1(1) + 2*bord_marg*window_radii(2)*rand(1,1);

                locations1(n, :)     = [randX, randY]; % dot locations filled

                world_dimses1(n,:) = windowRect;
                colours1(n,:) = black_col;
            end

            % Assign equal numbers of dots to each movement type
            ID_array1 = [ones(floor(dots_per_window/2),1); zeros(floor(dots_per_window/2), 1)];

            % Make the moveVec array based off of the ID_array
            moveVecs1 = zeros(dots_per_window, 2);
            idx0_1 = ID_array1 == 0;
            idx1_1 = ID_array1 == 1;
            moveVecs1(idx0_1, :) = repmat(window1_vec1, sum(idx0_1), 1);
            moveVecs1(idx1_1, :) = repmat(window1_vec2, sum(idx1_1), 1);

            % Make the ON_colour array
            ON_colours1 = ones(dots_per_window, 3);
            ON_colours1(idx0_1, :) = repmat(window1_colour1, sum(idx0_1), 1);
            ON_colours1(idx1_1, :) = repmat(window1_colour2, sum(idx1_1), 1);
            ON_colours1 = uint8(ON_colours1);

            % Create LotsDots object for window 1
            lots_dots1 = LotsDots(lifetimes1, ages1, diameters1, colours1, locations1, speeds1, ...
                world_dimses1, refreshHzes1, moveVecs1, ID_array1, ON_colours1);

            % Set window 1 boundaries
            lots_dots1.centerX = window_centers(1, 1, 1);
            lots_dots1.centerY = window_centers(1, 1, 2);
            lots_dots1.radius = window_radii(1);
            lots_dots1.bordersX = draw_bordersX1; %QQ: change this every trial
            lots_dots1.bordersY = draw_bordersY1;

            %% Create LotsDots for Window 2
            lifetimes2   = (lifetime_S*ones(dots_per_window, 1));
            ages2        = lifetimes2(1)*rand(dots_per_window, 1);
            diameters2   = (diameter*ones(dots_per_window, 1));
            speeds2      = (speed*ones(dots_per_window,1));
            locations2   = (ones(dots_per_window, 2));
            refreshHzes2 = (refreshHz*ones(dots_per_window, 1));

            draw_bordersX2 = [window_centers(1, 2, 1) - bord_marg*window_radii(2), window_centers(1, 2, 1) + bord_marg*window_radii(2)];
            draw_bordersY2 = [window_centers(1, 2, 2) - bord_marg*window_radii(2), window_centers(1, 2, 2) + bord_marg*window_radii(2)];

            % Fill locations randomly around window 2's circular area
            for n = 1:dots_per_window

                randX = draw_bordersX2(1) + 2*bord_marg*window_radii(2)*rand(1,1);
                randY = draw_bordersY2(1) + 2*bord_marg*window_radii(2)*rand(1,1);

                locations2(n, :)     = [randX, randY]; % dot locations filled

                world_dimses2(n,:) = windowRect;
                colours2(n,:) = black_col;
            end

            % Assign equal numbers of dots to each movement type
            ID_array2 = [ones(floor(dots_per_window/2),1); zeros(floor(dots_per_window/2), 1)];

            % Make the moveVec array
            moveVecs2 = zeros(dots_per_window, 2);
            idx0_2 = ID_array2 == 0;
            idx1_2 = ID_array2 == 1;
            moveVecs2(idx0_2, :) = repmat(window2_vec1, sum(idx0_2), 1);
            moveVecs2(idx1_2, :) = repmat(window2_vec2, sum(idx1_2), 1);

            % Make the ON_colour array
            ON_colours2 = ones(dots_per_window, 3);
            ON_colours2(idx0_2, :) = repmat(window2_colour1, sum(idx0_2), 1);
            ON_colours2(idx1_2, :) = repmat(window2_colour2, sum(idx1_2), 1);
            ON_colours2 = uint8(ON_colours2);

            % Create LotsDots object for window 2
            lots_dots2 = LotsDots(lifetimes2, ages2, diameters2, colours2, locations2, speeds2, ...
                world_dimses2, refreshHzes2, moveVecs2, ID_array2, ON_colours2);

            % Set window 2 boundaries
            lots_dots2.centerX = window_centers(1, 2, 1);
            lots_dots2.centerY = window_centers(1, 2, 2);
            lots_dots2.radius = window_radii(2);
            lots_dots2.bordersX = draw_bordersX2;
            lots_dots2.bordersY = draw_bordersY2;

            %% Create LotsDots for Window 3
            lifetimes3   = (lifetime_S*ones(dots_per_window, 1));
            ages3        = lifetimes3(1)*rand(dots_per_window, 1);
            diameters3   = (diameter*ones(dots_per_window, 1));
            speeds3      = (speed*ones(dots_per_window,1));
            locations3   = (ones(dots_per_window, 2));
            refreshHzes3 = (refreshHz*ones(dots_per_window, 1));

            draw_bordersX3 = [window_centers(1, 3, 1) - bord_marg*window_radii(3), window_centers(1, 3, 1) + bord_marg*window_radii(3)];
            draw_bordersY3 = [window_centers(1, 3, 2) - bord_marg*window_radii(3), window_centers(1, 3, 2) + bord_marg*window_radii(3)];

            % Fill locations randomly around window 2's circular area
            for n = 1:dots_per_window

                randX = draw_bordersX3(1) + 2*bord_marg*window_radii(3)*rand(1,1);
                randY = draw_bordersY3(1) + 2*bord_marg*window_radii(3)*rand(1,1);

                locations3(n, :)     = [randX, randY]; % dot locations filled

                world_dimses3(n,:) = windowRect;
                colours3(n,:) = black_col;
            end

            % Assign equal numbers of dots to each movement type
            ID_array3 = [ones(floor(dots_per_window/2),1); zeros(floor(dots_per_window/2), 1)];

            % Make the moveVec array
            moveVecs3 = zeros(dots_per_window, 2);
            idx0_3 = ID_array3 == 0;
            idx1_3 = ID_array3 == 1;
            moveVecs3(idx0_3, :) = repmat(window3_vec1, sum(idx0_3), 1);
            moveVecs3(idx1_3, :) = repmat(window3_vec2, sum(idx1_3), 1);

            % Make the ON_colour array
            ON_colours3 = ones(dots_per_window, 3);
            ON_colours3(idx0_3, :) = repmat(window3_colour1, sum(idx0_3), 1);
            ON_colours3(idx1_3, :) = repmat(window3_colour2, sum(idx1_3), 1);
            ON_colours3 = uint8(ON_colours3);

            % Create LotsDots object for window 3
            lots_dots3 = LotsDots(lifetimes3, ages3, diameters3, colours3, locations3, speeds3, ...
                world_dimses3, refreshHzes3, moveVecs3, ID_array3, ON_colours3);

            % Set window 3 boundaries
            lots_dots3.centerX = window_centers(1, 3, 1);
            lots_dots3.centerY = window_centers(1, 3, 2);
            lots_dots3.radius = window_radii(3);
            lots_dots3.bordersX = [window_centers(1, 3, 1) - bord_marg*window_radii(3), window_centers(1, 3, 1) + bord_marg*window_radii(3)];
            lots_dots3.bordersY = [window_centers(1, 3, 2) - bord_marg*window_radii(3), window_centers(1, 3, 2) + bord_marg*window_radii(3)];



            this.lots_dots1 = lots_dots1;
            this.lots_dots2 = lots_dots2;
            this.lots_dots3 = lots_dots3;

        end
        

        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )

            try
                %% Fixation Configuration
                fixation_type = dlg.Fixation_Type;
                fixation_size = dlg.Fixation_Size_Deg;
                fixation_color = dlg.Fixation_Color;
                fixation_line_width = dlg.Fixation_Line_Width;



                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;


                lastFlipTime        = GetSecs;
                secondsRemaining    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;


                dlg.Initial_Fixation_Duration = 1;
                dlg.Motion_Duration = 1;



                while secondsRemaining > 0

                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;


                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------

                    % Draw fixation spot
                    if(1)

                        % TODO: grab experiment options

                        %-- Find the center of the screen
                        [mx, my] = RectCenter(graph.wRect);

                        fixRect = [0 0 10 10];
                        fixRect = CenterRectOnPointd( fixRect, mx, my );
                        Screen('FillOval', graph.window,  this.fixColor, fixRect);

                        if strcmp(fixation_type, 'circle')
                            fixation_rect = [screenCenterX - fixation_size/2, screenCenterY - fixation_size/2, ...
                                screenCenterX + fixation_size/2, screenCenterY + fixation_size/2];
                            Screen('FillOval', graph.window, fixation_color, fixation_rect);
                        elseif strcmp(fixation_type, 'cross')
                            % Horizontal and vertical lines for cross
                            cross_coords = [
                                screenCenterX - fixation_size/2, screenCenterY, screenCenterX + fixation_size/2, screenCenterY;  % horizontal
                                screenCenterX, screenCenterY - fixation_size/2, screenCenterX, screenCenterY + fixation_size/2   % vertical
                                ];
                            Screen('DrawLines', graph.window, cross_coords', fixation_line_width, fixation_color, [0 0], 2);
                        end
                    end

                    % Draw dots
                    if ( secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration ...
                            && secondsElapsed < this.ExperimentOptions.Initial_Fixation_Duration + this.ExperimentOptions.MotionDuration)

                        % first move dots
                        % Move the dots in each window
                        this.lots_dots1.move();
                        this.lots_dots2.move();
                        this.lots_dots3.move();


                        % Draw the dots for window 1
                        Screen('DrawDots', graph.window, this.lots_dots1.location_array', this.lots_dots1.diameter_array, (this.lots_dots1.colour_array./255)', [], 2);

                        % Draw the dots for window 2
                        Screen('DrawDots', graph.window, this.lots_dots2.location_array', this.lots_dots2.diameter_array, (this.lots_dots2.colour_array./255)', [], 2);

                        % Draw the dots for window 3
                        Screen('DrawDots', graph.window, this.lots_dots3.location_array', this.lots_dots3.diameter_array, (this.lots_dots3.colour_array./255)', [], 2);
                    end

                    % Draw numbers for responses

                    circleRadius = lots_dots1.radius; % adjust if needed

                    circleCenters = [
                        lots_dots1.centerX, lots_dots1.centerY;
                        lots_dots2.centerX, lots_dots2.centerY;
                        lots_dots3.centerX, lots_dots3.centerY
                        ];

                    Screen('TextSize', window, 40);

                    for i = 1:3

                        % rect = CenterRectOnPointd([0 0 2*circleRadius 2*circleRadius], ...
                        %                           circleCenters(i,1), ...
                        %                           circleCenters(i,2));
                        %
                        % Screen('FrameOval', window, white_col, rect, 3);

                        numberStr = num2str(i);
                        bounds = Screen('TextBounds', window, numberStr);
                        textWidth  = bounds(3);
                        textHeight = bounds(4);

                        Screen('DrawText', window, numberStr, ...
                            circleCenters(i,1) - textWidth/2, ...
                            circleCenters(i,2) - textHeight/2, ...
                            white_col);
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

                    if ( secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration + this.ExperimentOptions.Min_Motion_Duration_Before_Response)

                        if ( secondsElapsed > 0.2)
                            response = [];
                            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                            if ( keyIsDown )
                                keys = find(keyCode);
                                for i=1:length(keys)
                                    KbName(keys(i));
                                    switch(KbName(keys(i)))
                                        case [KbName('1') KbName('1!')]
                                            response = 1;
                                        case [KbName('2') KbName('2@')]
                                            response = 2;
                                        case [KbName('3') KbName('3#')]
                                            response = 3;
                                    end
                                end
                            end
                            if ( ~isempty( response) )
                                thisTrialData.Response = response;
                                thisTrialData.ResponseTime = GetSecs;

                                break;
                            end
                        end
                    end
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------



                    % -----------------------------------------------------------------
                    % --- Check Fixation  ---------------------------------------
                    % -----------------------------------------------------------------

                    if ( secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration + this.ExperimentOptions.Min_Motion_Duration_Before_Response)

                        this.checkFixation(this, fixRect(1:2), this.ExperimentOptions.Fixation_Check_WinSize*[1 1], this.ExperimentOptions.Fixation_Check_TimeOut);
                    end
                    % -----------------------------------------------------------------
                    % --- Check Fixation  -----------------------------------
                    % -----------------------------------------------------------------
                end
            catch ex
                rethrow(ex)
            end
            
        end        
    end
    
end