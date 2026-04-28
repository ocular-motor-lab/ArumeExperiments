classdef A1MotionEllipses < ArumeExperimentDesigns.EyeTracking
    % Motion Ellipses foveal threshold exp.
    %     
    properties
        fixRad = 20;
        fixColor = [255 0 0];


        lots_dots1
        lots_dots2
        lots_dots3


        gazedata
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            %% Options for stimulus
            dlg.Max_Increment_Speed_Percent = { 100 '* (%)' [0.1 100] };
            dlg.Max_Increment_Direction_Angle = { 60 '* (deg)' [0.1 100] };
            dlg.Number_Of_Increments = 9;
            dlg.Stimulus_Type = { {'{both}' 'speed' 'direction'} };

            dlg.Max_RefVelocityComponent = { 2 '* (deg/s)' [0.01 100] };
            dlg.Num_RefVelocitiesPerComponent = 5;


            dlg.Do_Full_Grid = { {'0','{1}'} };
            dlg.Num_Repeats = {8 '* (N)' [1 100] };

            dlg.Dots_Per_Window = 700;
            dlg.Dots_Diameter   = { 1.5 '* (pix)' [0.01 100] };
            dlg.Dots_LifeTime   = { 0.5 '* (sec)' [0.01 100] };
            dlg.Dots_Grey_Level = [0.5];

            dlg.Window_Radius_Deg   = { 0.5 '* (deg)' [0.01 100] };
            dlg.Window_Eccentricity_Deg   = { 0.75 '* (deg)' [0.01 100] };

            dlg.Fixation_Check_WinSize = {1 '* (deg)' [0.01 100]};
            dlg.Fixation_Check_TimeOut = 0.3;

            %% Fixation Configuration
            dlg.Fixation_Type =  { {'none', '{circle}', 'cross'} };
            dlg.Fixation_Size_Deg = 10;  % deg (diameter for circle, arm length for cross)
            dlg.Fixation_Color = [1 1 1] * 255;  % white
            dlg.Fixation_Line_Width = 3;  % for cross only


            dlg.Initial_Fixation_Duration = { 0.9 '* (sec)' [0.01 100] };
            dlg.Initial_Fixation_Buffer_Duration = { 0.5 '* (sec)' [0.01 100] };
            dlg.Motion_Duration = { 1 '* (sec)' [0.01 100] };
            dlg.Min_Motion_Duration_Before_Response = { 0.2 '* (sec)' [0.01 100] };

            dlg.BackgroundBrightness = 0;
            
            %% Eye tracking options

            dlg.UseEyeTracker = 1;
            dlg.EyeTracker = { {'{Eyelink}', 'OpenIris', 'Fove', 'Mouse sim'} };
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult Speed Stimulus'; % which variables to display every trial in the command line separated by spaces

            %% Display options
            % SamsungOLED
            dlg.DisplayOptions.ScreenWidth = { 169.957 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 95.6009 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 125 '* (cm)' [1 3000] };
            dlg.DisplayOptions.SelectedScreen = {1 '' [0 5]};
            dlg.Debug.DebugMode = {0 {1}};

            % colours
            % screen bg colour
            dlg.DisplayOptions.BackgroundColor = 0;
            dlg.DisplayOptions.ForegroundColor = 127;

            %     % case 'ClaraDesk'
            % screen_dims_mm = [596.74, 335.66]; %https://dl.dell.com/manuals/all-products/esuprt_electronics_accessories/esuprt_electronics_accessories_monitors/dell-p2721q-monitor_user's-guide_en-us.pdf
            % distance_from_screen = 0.5; %meters
            
            dlg.HitKeyBeforeTrial = 0;
            dlg.TrialDuration = 50000000; % Very large to prevent skipping forward
            dlg.TrialsBeforeBreak = 500; % big break
            dlg.TrialsBeforeBreakSmall = 25; % small break
            dlg.TrialAbortAction = 'Delay';

            %% Reference Vector Options
            % Global Ref Parameters
            dlg.lb_screen = { 0.5 '* (deg/s)' [0 300] };
            dlg.ub_screen = { 8 '* (deg/s)' [0 300] };
            dlg.num_ref_gridpts =  { 4 '*' [1 3000] };
            dlg.ref_cart_or_polar = { {'{polar}' 'cartesian'} }; 
            dlg.num_ref_spokes = {8 '*' [1 3000] };
            dlg.ref_log_or_lin = { {'{log}' 'lin'} }; 

            % Local Comp Parameters (The relative offsets)
            dlg.comp_lb = { 0 '* (x ref_vec speed)' [0 300] }; 
            dlg.comp_ub = { 0.8 '* (x ref_vec speed)' [0 300] };
            dlg.comp_num_intervals = { 8 '* ' [1 300] };  
            dlg.comp_num_axes = { 8 '* ' [1 300] }; 
            dlg.comp_cart_or_polar = { {'{polar}' 'cartesian'} };  
            dlg.comp_rel_bool = { {'0','{1}'} };

            % Jitter Parameters
            dlg.Do_Jitter = { {'0','{1}'} }; % Boolean toggle
            dlg.Jitter_Multiplier = { 0.05 '* (x comp_vec speed)' [0 300] }; % e.g., 0.05 for 5% jitter

            dlg.Num_Repeats_Per_Combo = {2  '* ' [0 300]}; 

            dlg.EyeTrackerCalibProportion = {[.30,.30],'Calibration Area (width, height)',[0.05,1],1};

            dlg.ClaraDebug = { {'1','{0}'} };
            
        end

        function trialTable = SetUpTrialTable(this)
            %% 1. Parameter Extraction
            % These variables define the "Global" space where our reference stimuli live.
            lb_ref      = this.ExperimentOptions.lb_screen;
            if isempty(lb_ref)
                lb_ref = 0;
            end
            ub_ref      = this.ExperimentOptions.ub_screen;
            num_ref_pts = this.ExperimentOptions.num_ref_gridpts;
            ref_mode    = this.ExperimentOptions.ref_cart_or_polar; 
            ref_log_or_lin = this.ExperimentOptions.ref_log_or_lin;

            % These define the "Local" difference between the reference and the comparison.
            comp_lb        = this.ExperimentOptions.comp_lb; 
            if isempty(comp_lb)
                comp_lb = 0;
            end
            comp_ub        = this.ExperimentOptions.comp_ub; 
            comp_intervals = this.ExperimentOptions.comp_num_intervals;
            comp_axes      = this.ExperimentOptions.comp_num_axes;
            comp_mode      = this.ExperimentOptions.comp_cart_or_polar; 
            comp_rel_bool  = this.ExperimentOptions.comp_rel_bool; % Toggle for relative vs absolute

            % Jitter adds small noise to the comparison to prevent grid-learning.
            do_jitter   = this.ExperimentOptions.Do_Jitter; 
            jitter_mult = this.ExperimentOptions.Jitter_Multiplier; 

            num_repeats = this.ExperimentOptions.Num_Repeats_Per_Combo;

            %% 2. Seed RNG for Pseudo-Randomization
            % Seeding with the subject code ensures that the trial table is unique to the 
            % participant but reproducible if the same session is re-generated.
            rng(keyHash(this.Session.subjectCode)/10^10)

            %% 3. Generate Global Reference Vectors
            % This step creates the set of baseline motion vectors (x_ref).
            if strcmpi(ref_mode, 'cartesian')
                % Create a square grid and mask it to form a circular frame/ring.
                ref_ax = linspace(-ub_ref, ub_ref, num_ref_pts);
                [rvx, rvy] = meshgrid(ref_ax, ref_ax);
                base_refs = [rvx(:), rvy(:)];
                mags = sqrt(sum(base_refs.^2, 2));
                ref_vecs = base_refs(mags >= lb_ref & mags <= ub_ref, :);
            else 
                num_ref_spokes = this.ExperimentOptions.num_ref_spokes;
                % Create spokes of a wheel (Polar).
                angles = linspace(0, 2*pi, num_ref_spokes + 1);
                angles(end) = []; % Remove overlap
                if strcmpi(ref_log_or_lin, 'log')
                    radii = logspace(log10(lb_ref), log10(ub_ref), max(1, num_ref_pts));
                else
                    radii = linspace(lb_ref, ub_ref, max(1, num_ref_pts));
                end
                [A, R] = meshgrid(angles, radii);
                [vx, vy] = pol2cart(A(:), R(:));
                ref_vecs = [vx, vy];
            end

            %% 3.1 Force inclusion of [0,0] Reference
            % Check if a zero-velocity vector already exists (using a small epsilon)
            if ~any(sqrt(sum(ref_vecs.^2, 2)) < 1e-10)
                ref_vecs = [0, 0; ref_vecs];
                num_refs = size(ref_vecs, 1); % Update the count for later steps
            end


            %% 4. Generate Local Comparison Offsets (dx, dy)
            % Here we define the "delta" or the shape of the MOCS-like intervals.
            % If comp_rel_bool is true, these are treated as unit-less scaling factors.
            if strcmpi(comp_mode, 'cartesian')
                comp_ax = linspace(-comp_ub, comp_ub, comp_intervals);
                [cvx, cvy] = meshgrid(comp_ax, comp_ax);
                base_comps = [cvx(:), cvy(:)];
                c_mags = sqrt(sum(base_comps.^2, 2));
                
                % Filter offsets to stay within the local bounds
                valid_idx = c_mags >= comp_lb & c_mags <= comp_ub;
                comp_offsets = base_comps(valid_idx, :);
                comp_offset_multipliers = c_mags(valid_idx);
                
                % Map Cartesian magnitudes to an index (1 = smallest, N = largest)
                [~, ~, comp_offset_radius_idx] = unique(round(c_mags(valid_idx), 4));
            else 
                % Circular spokes centered on the reference point
                comp_angles = linspace(0, 2*pi, comp_axes + 1);
                comp_angles(end) = [];
                comp_radii = linspace(comp_lb, comp_ub, comp_intervals);
                
                % Create a matching grid of indices (1 to comp_intervals)
                radius_indices = 1:comp_intervals;
                [cA, cR] = meshgrid(comp_angles, comp_radii);
                [~, cR_idx] = meshgrid(comp_angles, radius_indices);
                
                
                [cvx, cvy] = pol2cart(cA(:), cR(:));
                comp_offsets = [cvx, cvy];
                comp_offset_radius_idx = cR_idx(:); % Flattened index array
                comp_offset_multipliers = cR(:); % Flattened array
            end
            
            %% 5. Combine and Build the Trial Table
            % This is the cross-product of all references and all local offsets.
            num_refs = size(ref_vecs, 1);
            num_comps = size(comp_offsets, 1);
            trials_per_rep = num_refs * num_comps;
            
            final_ref = cell(trials_per_rep, 1);
            final_comp_base = cell(trials_per_rep, 1);
            
            % Pre-allocate metric tracking arrays
            final_comp_offset = cell(trials_per_rep, 1); % 1x2 vectors need cell arrays
            final_comp_offset_rel = cell(trials_per_rep, 1);
            final_comp_radius = zeros(trials_per_rep, 1); % Scalars can be standard numeric arrays
            final_comp_radius_rel = zeros(trials_per_rep, 1);
            final_comp_axis   = zeros(trials_per_rep, 1); 
            final_comp_rad_idx = zeros(trials_per_rep, 1); % Index array for different levels
            final_comp_mult   = zeros(trials_per_rep, 1);
            
            counter = 1;
            for r = 1:num_refs
                v_ref = ref_vecs(r, :);
                ref_speed = norm(v_ref);
                
                for c = 1:num_comps
                    final_ref{counter} = v_ref;
                    
                    % Determine the actual offset being added
                    if comp_rel_bool
                        % offset_percentage * speed_ref
                        actual_offset = comp_offsets(c, :) .* ref_speed;
                    else
                        % offset_absolute
                        actual_offset = comp_offsets(c, :);
                    end
                    
                    final_comp_base{counter} = v_ref + actual_offset;
                    
                    % Record the metrics
                    final_comp_offset{counter} = actual_offset;
                    final_comp_offset_rel{counter} = comp_offsets(c, :);
                    final_comp_radius(counter) = norm(actual_offset);
                    final_comp_radius_rel(counter) = norm(comp_offsets(c, :));
                    % Calculate angle using atan2, convert to degrees, and wrap 0-360
                    final_comp_axis(counter)   = wrapTo360(rad2deg(atan2(actual_offset(2), actual_offset(1))));
                    
                    % Record the discrete MOCS radius index
                    final_comp_rad_idx(counter) = comp_offset_radius_idx(c); 
                    final_comp_mult(counter) = comp_offset_multipliers(c);
                    
                    counter = counter + 1;
                end
            end
            
            % Use Arume's TrialTableBuilder to handle shuffling and repeats.
            t = ArumeCore.TrialTableBuilder();
            t.AddConditionVariable('RefCompPair', (1:trials_per_rep));
            trialTable = t.GenerateTrialTable('Random', 'Sequential', num_repeats, 'Delay');
            
            % Randomly assign 1, 2, or 3 to each trial
            trialTable.OddballWindow = randi([1, 3], height(trialTable), 1);
            
            % Map the generated IDs back to the actual velocity pairs.
            idx = trialTable.RefCompPair;
            trialTable.ReferenceVelocity = final_ref(idx);
            comp_vels = final_comp_base(idx);
            
            % Map the offset metrics to the trial table
            trialTable.CompOffsetVector = final_comp_offset(idx);
            trialTable.CompOffsetVectorRel = final_comp_offset_rel(idx);
            trialTable.CompOffsetRadius = final_comp_radius(idx); 
            trialTable.CompOffsetRadiusRel = final_comp_radius_rel(idx);
            trialTable.CompOffsetAxis   = final_comp_axis(idx);
            trialTable.CompOffsetRadiusIndex = final_comp_rad_idx(idx);
            trialTable.CompOffsetMultiplier = final_comp_mult(idx);


            % %% 4. Generate Local Comparison Offsets (dx, dy)
            % % Here we define the "delta" or the shape of the MOCS-like intervals.
            % % If comp_rel_bool is true, these are treated as unit-less scaling factors.
            % if strcmpi(comp_mode, 'cartesian')
            %     comp_ax = linspace(-comp_ub, comp_ub, comp_intervals);
            %     [cvx, cvy] = meshgrid(comp_ax, comp_ax);
            %     base_comps = [cvx(:), cvy(:)];
            %     c_mags = sqrt(sum(base_comps.^2, 2));
            %     % Filter offsets to stay within the local bounds
            %     comp_offsets = base_comps(c_mags >= comp_lb & c_mags <= comp_ub, :);
            % else 
            %     % Circular spokes centered on the reference point
            %     comp_angles = linspace(0, 2*pi, comp_axes + 1);
            %     comp_angles(end) = [];
            %     comp_radii = linspace(comp_lb, comp_ub, comp_intervals);
            %     [cA, cR] = meshgrid(comp_angles, comp_radii);
            %     [cvx, cvy] = pol2cart(cA(:), cR(:));
            %     comp_offsets = [cvx, cvy];
            % end
            % 
            % %% 5. Combine and Build the Trial Table
            % % This is the cross-product of all references and all local offsets.
            % num_refs = size(ref_vecs, 1);
            % num_comps = size(comp_offsets, 1);
            % trials_per_rep = num_refs * num_comps;
            % 
            % final_ref = cell(trials_per_rep, 1);
            % final_comp_base = cell(trials_per_rep, 1);
            % 
            % % Pre-allocate metric tracking arrays ---
            % final_comp_offset = cell(trials_per_rep, 1); % 1x2 vectors need cell arrays
            % final_comp_offset_rel = cell(trials_per_rep, 1);
            % final_comp_radius = zeros(trials_per_rep, 1); % Scalars can be standard numeric arrays
            % final_comp_radius_rel = zeros(trials_per_rep, 1);
            % final_comp_axis   = zeros(trials_per_rep, 1); 
            % 
            % counter = 1;
            % for r = 1:num_refs
            %     v_ref = ref_vecs(r, :);
            %     ref_speed = norm(v_ref);
            % 
            %     for c = 1:num_comps
            %         final_ref{counter} = v_ref;
            % 
            %         % Determine the actual offset being added
            %         if comp_rel_bool
            %             % offset_percentage * speed_ref
            %             actual_offset = comp_offsets(c, :) .* ref_speed;
            %         else
            %             % offset_absolute
            %             actual_offset = comp_offsets(c, :);
            %         end
            % 
            %         final_comp_base{counter} = v_ref + actual_offset;
            % 
            %         % --- NEW: Record the metrics ---
            %         final_comp_offset{counter} = actual_offset;
            %         final_comp_offset_rel{counter} = comp_offsets(c, :);
            %         final_comp_radius(counter) = norm(actual_offset);
            %         final_comp_radius_rel(counter) = norm(comp_offsets(c, :));
            %         % Calculate angle using atan2, convert to degrees, and wrap 0-360
            %         final_comp_axis(counter)   = wrapTo360(rad2deg(atan2(actual_offset(2), actual_offset(1))));
            % 
            %         counter = counter + 1;
            %     end
            % end
            % 
            % % Use Arume's TrialTableBuilder to handle shuffling and repeats.
            % t = ArumeCore.TrialTableBuilder();
            % t.AddConditionVariable('RefCompPair', (1:trials_per_rep));
            % trialTable = t.GenerateTrialTable('Random', 'Sequential', num_repeats, 'Delay');
            % 
            % % Randomly assign 1, 2, or 3 to each trial
            % trialTable.OddballWindow = randi([1, 3], height(trialTable), 1);
            % 
            % % Map the generated IDs back to the actual velocity pairs.
            % idx = trialTable.RefCompPair;
            % trialTable.ReferenceVelocity = final_ref(idx);
            % comp_vels = final_comp_base(idx);
            % 
            % % Map the offset metrics to the trial table ---
            % trialTable.CompOffsetVector = final_comp_offset(idx);
            % trialTable.CompOffsetVectorRel = final_comp_offset_rel(idx);
            % trialTable.CompOffsetRadius = final_comp_radius(idx); % unsure if this is actually useful - it's the radius of the comp vector from origin.
            % trialTable.CompOffsetRadiusRel = final_comp_radius_rel(idx);
            % trialTable.CompOffsetAxis   = final_comp_axis(idx);


            %% 6. Apply Pseudo-Random Jitter
            % We apply jitter after expanding the table so every repeat is slightly unique.
            if do_jitter
                for i = 1:height(trialTable)
                    v_base = comp_vels{i};
                    speed = norm(v_base);

                    % Small floor for speed to ensure 0-velocity points can still jitter.
                    if speed == 0, speed = 0.1; end 

                    % The jitter is a random (x,y) shift proportional to the vector's speed.
                    jx = (2*rand() - 1) * jitter_mult * speed;
                    jy = (2*rand() - 1) * jitter_mult * speed;

                    comp_vels{i} = v_base + [jx, jy];
                end
            end

            trialTable.ComparisonVelocity = comp_vels(idx);

            %% 7. Final Window Assignment
            % Initialize all apertures with the reference velocity.
            trialTable.Window1_Velocity = trialTable.ReferenceVelocity;
            trialTable.Window2_Velocity = trialTable.ReferenceVelocity;
            trialTable.Window3_Velocity = trialTable.ReferenceVelocity;

            % The 'Oddball' window is the only one that gets the comparison velocity.
            trialTable.Window1_Velocity(trialTable.OddballWindow == 1) = comp_vels(trialTable.OddballWindow == 1);
            trialTable.Window2_Velocity(trialTable.OddballWindow == 2) = comp_vels(trialTable.OddballWindow == 2);
            trialTable.Window3_Velocity(trialTable.OddballWindow == 3) = comp_vels(trialTable.OddballWindow == 3);

            % Set the physical positions of the three apertures on the display.
            trialTable.Window1_Angle = 125 + 110 * rand(height(trialTable), 1);
            trialTable.Window2_Angle = wrapTo360(trialTable.Window1_Angle - 120);
            trialTable.Window3_Angle = wrapTo360(trialTable.Window1_Angle - 240);

            %% --- Print Experiment Summary ---
            fprintf('\n============================================================\n');
            fprintf('           STIMULUS CONFIGURATION SUMMARY                 \n');
            fprintf('============================================================\n');
            
            % 1. Reference Vector Specs
            if strcmpi(ref_mode, 'cartesian')
                ref_ax_vals = linspace(-ub_ref, ub_ref, num_ref_pts);
                ref_step_str = num2str(ref_ax_vals, '%0.2f ');
                fprintf('REFERENCE VECTORS: [CARTESIAN GRID]\n');
                fprintf('  - Grid Axis Steps:   [%s] deg/s\n', ref_step_str);
                fprintf('  - Frame Bounds:      %0.2f to %0.2f deg/s (Magnitude)\n', lb_ref, ub_ref);
            else
                %ref_radii = linspace(lb_ref, ub_ref, max(1, num_ref_pts));
                fprintf('REFERENCE VECTORS: [POLAR WHEEL]\n');
                fprintf('  - Reference Radii:   [%s] deg/s\n', num2str(radii, '%0.2f '));
                fprintf('  - Number of Spokes:  %d\n', num_ref_spokes);
            end
            fprintf('  - Total Unique Refs: %d\n', num_refs);
            
            fprintf('------------------------------------------------------------\n');
            
            % 2. Comparison Vector Specs
            comp_type_str = 'ABSOLUTE (deg/s)';
            if comp_rel_bool; comp_type_str = 'RELATIVE (%% of ref speed)'; end
            
            if strcmpi(comp_mode, 'cartesian')
                comp_ax_vals = linspace(-comp_ub, comp_ub, comp_intervals);
                fprintf('COMPARISON VECTORS: [CARTESIAN LOCAL GRID]\n');
                fprintf('  - Offset Type:       %s\n', comp_type_str);
                fprintf('  - Grid Axis Steps:   [%s]\n', num2str(comp_ax_vals, '%0.2f '));
                fprintf('  - Local Bounds:      %0.2f to %0.2f (Magnitude)\n', comp_lb, comp_ub);
            else
                %comp_radii = linspace(comp_lb, comp_ub, comp_intervals);
                fprintf('COMPARISON VECTORS: [POLAR LOCAL SPOKES]\n');
                fprintf('  - Offset Type:       %s\n', comp_type_str);
                fprintf('  - Comparison Radii:  [%s]\n', num2str(comp_radii, '%0.2f '));
                fprintf('  - Comparison Axes:   %d\n', comp_axes);
            end
            fprintf('  - Total Unique Comps: %d (per reference)\n', num_comps);
            
            fprintf('------------------------------------------------------------\n');
            
            % 3. Jitter & Session Totals
            if do_jitter
                fprintf('JITTER: [ENABLED]\n');
                fprintf('  - Multiplier:        %0.2f x velocity\n', jitter_mult);
            else
                fprintf('JITTER: [DISABLED]\n');
            end
            
            fprintf('\nSESSION TOTALS:\n');
            fprintf('  - Unique Combos:     %d (Refs * Comps)\n', trials_per_rep);
            fprintf('  - Repetitions:       %d per combo\n', num_repeats);
            fprintf('  - TOTAL TRIALS:      %d\n', height(trialTable));
            fprintf('============================================================\n\n');

        end
        % function trialTable = SetUpTrialTable(this)
        % 
        %     max_degS = this.ExperimentOptions.Max_RefVelocityComponent;
        % 
        %     if ( this.ExperimentOptions.Do_Full_Grid )
        %         % for entire grid of reference vectors:
        %         % grid of reference speeds
        %         [ref_Vx ref_Vy] = meshgrid(-max_degS:1:max_degS);
        %         % zip together
        %         ref_vecs = [ref_Vx(:), ref_Vy(:)];
        % 
        %     else
        % 
        %         %% BUT: I only want 9 of them: In a 3x3 square, but the direction (ie. signage of components) can be varying
        %         % use participant_ID to seed the rng so it gets the same one everytime
        %         rng(keyHash(this.Session.subjectCode)/10^10)
        % 
        %         % axis of the 
        % 
        %         % grid of reference speeds
        %         [ref_Vx ref_Vy] = meshgrid(-max_degS:0);
        %         [xxx yyy] = meshgrid(1:length(-max_degS:0));
        % 
        %         % flip some of the signs to randomize
        %         flip_num_Vx = ceil(numel(ref_Vx)*rand);% random number of them to flip
        %         flip_idx_Vx =  randperm(numel(ref_Vx), flip_num_Vx); % which ones to flip
        %         ref_Vx(flip_idx_Vx) = -ref_Vx(flip_idx_Vx); % flip those SIGNS
        % 
        %         flip_num_Vy = ceil(numel(ref_Vy)*rand);% random number of them to flip
        %         flip_idx_Vy =  randperm(numel(ref_Vy), flip_num_Vy); % which ones to flip
        %         ref_Vy(flip_idx_Vy) = -ref_Vy(flip_idx_Vy); % flip those SIGNS
        % 
        %         % make a datetime
        %         nowo = datetime("now");
        %         % seed the random back to something random to make sure no duplicate trials
        %         rng(second(nowo) + minute(nowo) + hour(nowo));
        % 
        % 
        %         % zip together
        %         ref_vecs = [ref_Vx(:), ref_Vy(:)];
        %     end
        % 
        %     % build the table
        %     t = ArumeCore.TrialTableBuilder();
        % 
        %     %all the reference vectors
        %     celled_ref_vecs = {};
        %     for n = 1:size(ref_vecs, 1)
        %         celled_ref_vecs{n} = ref_vecs(n, :);
        %     end
        %     t.AddConditionVariable('ReferenceVelocity',celled_ref_vecs);
        % 
        %     % the condition table will generate the appropriate
        %     % combinations itself
        %     % t.AddConditionVariable('ReferenceVelocityY',ref_vecs(:, 1)');
        %     % t.AddConditionVariable('ReferenceVelocityX',ref_vecs(:, 2)');
        % 
        %     % comparison vector - how much of an increment on the reference vector?
        %     t.AddConditionVariable('Increment',-100:(200)/(this.ExperimentOptions.Number_Of_Increments - 1):100);
        % 
        %     % what stimulus type?
        %     switch(this.ExperimentOptions.Stimulus_Type)
        %         case 'both'
        %             t.AddConditionVariable('TypeOfIncrement',{'Speed' 'Direction'});
        %         case 'speed'
        %             t.AddConditionVariable('TypeOfIncrement',{'Speed'});
        %         case 'direction'
        %             t.AddConditionVariable('TypeOfIncrement',{'Direction'});
        %     end
        %     t.AddConditionVariable('OddballWindow',[1 2 3]);
        % 
        %     % Example of how to do blocks if neecessary. Just filter the
        %     % condition table to say which trials belong to that block
        %     %
        %     % t.AddBlock(find(t.ConditionTable.TypeOfIncrement=='Direction'), 1);
        %     % t.AddBlock(find(t.ConditionTable.TypeOfIncrement=='Speed'), 1);
        % 
        %     %% Arume trials specs 
        %     trialSequence = 'Random';
        %     blockSequence =  'Sequential';
        %     blockSequenceRepeatitions = this.ExperimentOptions.Num_Repeats;
        %     abortAction = 'Delay';
        %     trialsPerSession = 1000;
        %     trialTable = t.GenerateTrialTable(trialSequence, blockSequence, blockSequenceRepeatitions, abortAction,trialsPerSession);
        % 
        %     % How are the windows positioned (angularly) to each other?
        %     trialTable.Window1_Angle = 125 + 110*rand(height(trialTable),1); % TODO: comment what this means
        %     trialTable.Window2_Angle = wrapTo360(trialTable.Window1_Angle-120);
        %     trialTable.Window3_Angle = wrapTo360(trialTable.Window1_Angle-240);
        % 
        % 
        %     compVelocity = cell(size(trialTable.ReferenceVelocity, 1), 1);
        %     %compVelocity = trialTable.ReferenceVelocity;
        %     %compVelocityXY = [trialTable.ReferenceVelocityX, trialTable.ReferenceVelocityY]; % init to something
        % 
        %     % Find the trials that are direction and the ones that are speed, and then 
        %     directionTrials = t.ConditionTable.TypeOfIncrement=='Direction';
        %     speedTrials = t.ConditionTable.TypeOfIncrement=='Speed';
        % 
        %     directionTrialsInds = find(directionTrials==1);
        %     speedTrialsInds = find(speedTrials==1);
        % 
        %     % only want the increments for the direction trials
        %     angleIncrement = this.ExperimentOptions.Max_Increment_Direction_Angle .* trialTable.Increment(directionTrials)/100;
        % 
        %     for i=1:size(directionTrialsInds, 1)
        %         thisTrialAngle = angleIncrement(i);
        %         rotation_matrix = [ cosd(thisTrialAngle), -sind(thisTrialAngle);
        %             sind(thisTrialAngle), cosd(thisTrialAngle)];
        % 
        %         %compVelocity(directionTrialsInds(i),:) = (rotation_matrix * trialTable.ReferenceVelocity{directionTrialsInds(i),:}')';
        %         compVelocity(directionTrialsInds(i)) = {(rotation_matrix * trialTable.ReferenceVelocity{directionTrialsInds(i),:}')'};
        %     end
        % 
        %     for i = 1:size(speedTrialsInds, 1)
        %         compVelocity(speedTrialsInds(i)) = {trialTable.ReferenceVelocity{speedTrialsInds(i),:} + ...
        %             this.ExperimentOptions.Max_Increment_Speed_Percent/100 .* trialTable.Increment(speedTrialsInds(i))/100 .* trialTable.ReferenceVelocity{speedTrialsInds(i),:}};
        % 
        %     end
        % 
        % 
        %     trialTable.Window1_Velocity = trialTable.ReferenceVelocity;
        %     trialTable.Window2_Velocity = trialTable.ReferenceVelocity;
        %     trialTable.Window3_Velocity = trialTable.ReferenceVelocity;
        % 
        %     trialTable.Window1_Velocity(trialTable.OddballWindow == 1 ) = compVelocity(trialTable.OddballWindow == 1 );
        %     trialTable.Window2_Velocity(trialTable.OddballWindow == 2 ) = compVelocity(trialTable.OddballWindow == 2 );
        %     trialTable.Window3_Velocity(trialTable.OddballWindow == 3 ) = compVelocity(trialTable.OddballWindow == 3 );
        % 
        % 
        % end

        % run initialization before the first trial is run
        % Use this function to initialize things that need to be
        % initialized before running but don't need to be initialized for
        % every single trial
        function shouldContinue = initBeforeRunning( this )

            shouldContinue = 1;
            % 
            % % the range that the comparison stimulus can increment from the reference
            % inc_range_perc = this.ExperimentOptions.Max_Increment_Speed_Percent/100*[-1 1];
            % inc_range_dir = this.ExperimentOptions.Max_Increment_Direction_Angle*[-1 1]; % in degrees
            % % type of stimulus variation:
            % stim_type = this.ExperimentOptions.Stimulus_Type; %{ {'{both}' 'speed' 'direction'} };
            % max_degS = this.ExperimentOptions.Max_RefVelocityComponent;

            this.ExperimentOptions.DisplayOptions.white_col = 255*[1 1 1] * WhiteIndex(this.ExperimentOptions.DisplayOptions.SelectedScreen);
            this.ExperimentOptions.DisplayOptions.black_col = [1 1 1] * BlackIndex(this.ExperimentOptions.DisplayOptions.SelectedScreen);
            this.ExperimentOptions.DisplayOptions.grey_col = this.ExperimentOptions.DisplayOptions.white_col * this.ExperimentOptions.Dots_Grey_Level;
            
            % screen bg colour
            this.ExperimentOptions.DisplayOptions.BackgroundColor = 0;
            this.ExperimentOptions.DisplayOptions.ForegroundColor = 127;

            % HARD CODED FOR THE SAMSUNG OLED

            % Get the refresh rate and screen dimensions (in pixels) of the screen
            this.ExperimentOptions.DisplayOptions.refreshHz = Screen('FrameRate', this.ExperimentOptions.DisplayOptions.SelectedScreen);
            [windowRect] = Screen('Rect', this.ExperimentOptions.DisplayOptions.SelectedScreen);
            this.ExperimentOptions.DisplayOptions.screen_dims_pix = windowRect(3:4);
            this.ExperimentOptions.DisplayOptions.windowRect = windowRect;

            % Calculate window center positions
            this.ExperimentOptions.DisplayOptions.screenCenterX = windowRect(3) / 2;
            this.ExperimentOptions.DisplayOptions.screenCenterY = windowRect(4) / 2;
            
            this.ExperimentOptions.DisplayOptions.screen_dims_mm = 10.*[this.ExperimentOptions.DisplayOptions.ScreenWidth, this.ExperimentOptions.DisplayOptions.ScreenHeight]; %https://www.displayspecifications.com/en/model/cd7a3130
            this.ExperimentOptions.DisplayOptions.distance_from_screen = this.ExperimentOptions.DisplayOptions.ScreenDistance/100; %meters

            this.ExperimentOptions.DisplayOptions.pixels_per_mm = this.ExperimentOptions.DisplayOptions.screen_dims_pix./this.ExperimentOptions.DisplayOptions.screen_dims_mm;
            % mm_per_pixel = screen_dims_mm./screen_dims_pix;
            this.ExperimentOptions.DisplayOptions.mm_per_deg = tan(deg2rad(1)) * this.ExperimentOptions.DisplayOptions.distance_from_screen * 1000;

            this.ExperimentOptions.DisplayOptions.degS_to_pixFrame_convFactor = this.ExperimentOptions.DisplayOptions.mm_per_deg*this.ExperimentOptions.DisplayOptions.pixels_per_mm/this.ExperimentOptions.DisplayOptions.refreshHz;
            this.ExperimentOptions.DisplayOptions.deg_to_pix_convFactor = this.ExperimentOptions.DisplayOptions.mm_per_deg * this.ExperimentOptions.DisplayOptions.pixels_per_mm(1);

            this.ExperimentOptions.Fixation_Check_WinSize_pix = this.ExperimentOptions.Fixation_Check_WinSize*this.ExperimentOptions.DisplayOptions.deg_to_pix_convFactor;


            %% Window config
            % circle window radii (deg) - could be different for each window
            window_radii_deg = this.ExperimentOptions.Window_Radius_Deg*[1 1 1];
            this.ExperimentOptions.window_radii = window_radii_deg .* this.ExperimentOptions.DisplayOptions.deg_to_pix_convFactor;

            % Distance of window centers from fixation point (pixels)
            this.ExperimentOptions.window_eccentricity_deg = this.ExperimentOptions.Window_Eccentricity_Deg*[1 1 1];
            this.ExperimentOptions.window_eccentricity = this.ExperimentOptions.window_eccentricity_deg(1) * this.ExperimentOptions.DisplayOptions.deg_to_pix_convFactor;

            % Assemble together all the rotational positions of the windows
            this.ExperimentOptions.window_angles = [this.TrialTable.Window1_Angle, this.TrialTable.Window2_Angle, this.TrialTable.Window3_Angle];


            % Number of trials
            this.ExperimentOptions.numTrials = size(this.TrialTable, 1);

            % keeps track of trial duration 
            actualDuration = min(this.ExperimentOptions.Motion_Duration, this.ExperimentOptions.TrialDuration);
            
            % store all gaze contingent data
            nrows = ceil(this.Graph.frameRate*actualDuration)*1.5;
            gazedata = table;
            gazedata.ELtime = nan(nrows,1);
            gazedata.PTBtime = nan(nrows,1);
            gazedata.LGazeX = nan(nrows,1);
            gazedata.LGazeY = nan(nrows,1);
            gazedata.RGazeX = nan(nrows,1);
            gazedata.RGazeY = nan(nrows,1);
            this.gazedata = gazedata;

            %% Initialize the lots_dotses

            dots_per_window = this.ExperimentOptions.Dots_Per_Window;  % dots per window
            num_dots    = dots_per_window*3;  % total dots across all 3 windows
            diameter    = this.ExperimentOptions.Dots_Diameter;
            lifetime_S  = this.ExperimentOptions.Dots_LifeTime;

            window_radii = this.ExperimentOptions.window_radii;


            % Boundary margin around the circle to generate dots in:
            % ex. the dots will generate in bord_marg*circle_diameter square space to avoid clumping in one direction
            % for lotsdots1.bordersX/bordersY, etc.
            bord_marg = 3;

            %% THIS MAY NEED TO BE ADDED TO THE EXPERIMENT OPTIONS?
            window_centers = zeros(3, 2);

            init_trial_num = 1;

            for w = 1:3
                angle_rad = deg2rad(this.ExperimentOptions.window_angles(init_trial_num, w));
                window_centers(w, 1) = this.ExperimentOptions.DisplayOptions.screenCenterX + this.ExperimentOptions.window_eccentricity * cos(angle_rad);
                window_centers(w, 2) = this.ExperimentOptions.DisplayOptions.screenCenterY - this.ExperimentOptions.window_eccentricity * sin(angle_rad);  % negative because Y increases downward
            end


            %% Assign the parameters to the different windows
            all_dots_colour = this.ExperimentOptions.DisplayOptions.grey_col;

            % Window 1 dot parameters - this structure keeps the functionality for simultaneous motion
            window1_vec1 = this.ExperimentOptions.DisplayOptions.degS_to_pixFrame_convFactor(1)*this.TrialTable.Window1_Velocity{init_trial_num, :};   % Movement vector for first half of dots
            window1_vec2 = window1_vec1;    % Movement vector for second half of dots
            window1_colour1 = all_dots_colour;
            window1_colour2 = window1_colour1;
            
            % Window 2 dot parameters
            window2_vec1 = this.ExperimentOptions.DisplayOptions.degS_to_pixFrame_convFactor(1)*this.TrialTable.Window2_Velocity{init_trial_num, :};
            window2_vec2 = window2_vec1;
            window2_colour1 = all_dots_colour;
            window2_colour2 = window2_colour1;
            
            % Window 3 dot parameters
            window3_vec1 = this.ExperimentOptions.DisplayOptions.degS_to_pixFrame_convFactor(1)*this.TrialTable.Window3_Velocity{init_trial_num, :};
            window3_vec2 = window3_vec1;  
            window3_colour1 = all_dots_colour;
            window3_colour2 = window3_colour1;



            %% Create LotsDots for Window 1
            speed = 1; % unneed parameter; set to 1
            lifetimes1   = (lifetime_S*ones(dots_per_window, 1));
            ages1        = lifetimes1(1)*rand(dots_per_window, 1);
            diameters1   = (diameter*ones(dots_per_window, 1));
            speeds1      = (speed*ones(dots_per_window,1));
            locations1   = (ones(dots_per_window, 2));
            refreshHzes1 = (this.ExperimentOptions.DisplayOptions.refreshHz*ones(dots_per_window, 1));

            draw_bordersX1 = [window_centers(1, 1) - bord_marg*window_radii(1), window_centers(1, 1) + bord_marg*window_radii(1)];
            draw_bordersY1 = [window_centers(1, 2) - bord_marg*window_radii(1), window_centers(1, 2) + bord_marg*window_radii(1)];

            % Fill locations randomly around window 1's circular area
            for n = 1:dots_per_window

                randX = draw_bordersX1(1) + 2*bord_marg*window_radii(2)*rand(1,1);
                randY = draw_bordersY1(1) + 2*bord_marg*window_radii(2)*rand(1,1);

                locations1(n, :)     = [randX, randY]; % dot locations filled

                world_dimses1(n,:) = this.ExperimentOptions.DisplayOptions.windowRect;
                colours1(n,:) = this.ExperimentOptions.DisplayOptions.black_col;
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
            lots_dots1.centerX = window_centers(1, 1);
            lots_dots1.centerY = window_centers(1, 2);
            lots_dots1.radius = window_radii(1);
            lots_dots1.bordersX = draw_bordersX1; %QQ: change this every trial
            lots_dots1.bordersY = draw_bordersY1;

            %% Create LotsDots for Window 2
            lifetimes2   = (lifetime_S*ones(dots_per_window, 1));
            ages2        = lifetimes2(1)*rand(dots_per_window, 1);
            diameters2   = (diameter*ones(dots_per_window, 1));
            speeds2      = (speed*ones(dots_per_window,1));
            locations2   = (ones(dots_per_window, 2));
            refreshHzes2 = (this.ExperimentOptions.DisplayOptions.refreshHz*ones(dots_per_window, 1));

            draw_bordersX2 = [window_centers(2, 1) - bord_marg*window_radii(2), window_centers(2, 1) + bord_marg*window_radii(2)];
            draw_bordersY2 = [window_centers(2, 2) - bord_marg*window_radii(2), window_centers(2, 2) + bord_marg*window_radii(2)];

            % Fill locations randomly around window 2's circular area
            for n = 1:dots_per_window

                randX = draw_bordersX2(1) + 2*bord_marg*window_radii(2)*rand(1,1);
                randY = draw_bordersY2(1) + 2*bord_marg*window_radii(2)*rand(1,1);

                locations2(n, :)     = [randX, randY]; % dot locations filled

                world_dimses2(n,:) = this.ExperimentOptions.DisplayOptions.windowRect;
                colours2(n,:) = this.ExperimentOptions.DisplayOptions.black_col;
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
            lots_dots2.centerX = window_centers(2, 1);
            lots_dots2.centerY = window_centers(2, 2);
            lots_dots2.radius = window_radii(2);
            lots_dots2.bordersX = draw_bordersX2;
            lots_dots2.bordersY = draw_bordersY2;

            %% Create LotsDots for Window 3
            lifetimes3   = (lifetime_S*ones(dots_per_window, 1));
            ages3        = lifetimes3(1)*rand(dots_per_window, 1);
            diameters3   = (diameter*ones(dots_per_window, 1));
            speeds3      = (speed*ones(dots_per_window,1));
            locations3   = (ones(dots_per_window, 2));
            refreshHzes3 = (this.ExperimentOptions.DisplayOptions.refreshHz*ones(dots_per_window, 1));

            draw_bordersX3 = [window_centers(3, 1) - bord_marg*window_radii(3), window_centers(3, 1) + bord_marg*window_radii(3)];
            draw_bordersY3 = [window_centers(3, 2) - bord_marg*window_radii(3), window_centers(3, 2) + bord_marg*window_radii(3)];

            % Fill locations randomly around window 2's circular area
            for n = 1:dots_per_window

                randX = draw_bordersX3(1) + 2*bord_marg*window_radii(3)*rand(1,1);
                randY = draw_bordersY3(1) + 2*bord_marg*window_radii(3)*rand(1,1);

                locations3(n, :)     = [randX, randY]; % dot locations filled

                world_dimses3(n,:) = this.ExperimentOptions.DisplayOptions.windowRect;
                colours3(n,:) = this.ExperimentOptions.DisplayOptions.black_col;
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
            lots_dots3.centerX = window_centers(3, 1);
            lots_dots3.centerY = window_centers(3, 2);
            lots_dots3.radius = window_radii(3);
            lots_dots3.bordersX = [window_centers(3, 1) - bord_marg*window_radii(3), window_centers(3, 1) + bord_marg*window_radii(3)];
            lots_dots3.bordersY = [window_centers(3, 2) - bord_marg*window_radii(3), window_centers(3, 2) + bord_marg*window_radii(3)];



            this.lots_dots1 = lots_dots1;
            this.lots_dots2 = lots_dots2;
            this.lots_dots3 = lots_dots3;


            % show cursor if ClaraDebug
            if this.ExperimentOptions.ClaraDebug
                ShowCursor;
            end
            ShowCursor; %show it anyway loll


        end
        
        % runPreTrial
        % use this to prepare things before the trial starts 
        % This runs before EACH trial
        function [trialResult, thisTrialData] = runPreTrial(this, thisTrialData )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;

            dots_per_window = this.ExperimentOptions.Dots_Per_Window;  % dots per window
            num_dots    = dots_per_window*3;  % total dots across all 3 windows
            diameter    = this.ExperimentOptions.Dots_Diameter;
            lifetime_S  = this.ExperimentOptions.Dots_LifeTime;

            window_radii = this.ExperimentOptions.window_radii;


            % Boundary margin around the circle to generate dots in:
            % ex. the dots will generate in bord_marg*circle_diameter square space to avoid clumping in one direction
            % for lotsdots1.bordersX/bordersY, etc.
            bord_marg = 3;

            %% THIS MAY NEED TO BE ADDED TO THE EXPERIMENT OPTIONS?
            window_centers = zeros(3, 2);

            % get the window_centers for this trial specifically
            for w = 1:3
                angle_rad = deg2rad(this.ExperimentOptions.window_angles(thisTrialData.TrialNumber, w));
                window_centers(w, 1) = this.ExperimentOptions.DisplayOptions.screenCenterX + this.ExperimentOptions.window_eccentricity * cos(angle_rad);
                window_centers(w, 2) = this.ExperimentOptions.DisplayOptions.screenCenterY - this.ExperimentOptions.window_eccentricity * sin(angle_rad);  % negative because Y increases downward
            end


            %% Assign the parameters to the different windows
            all_dots_colour = this.ExperimentOptions.DisplayOptions.grey_col;

            % Window 1 dot parameters - this structure keeps the functionality for simultaneous motion
            window1_vec1 = this.ExperimentOptions.DisplayOptions.degS_to_pixFrame_convFactor(1)*this.TrialTable.Window1_Velocity{thisTrialData.TrialNumber, :};   % Movement vector for first half of dots
            window1_vec2 = window1_vec1;    % Movement vector for second half of dots
            window1_colour1 = all_dots_colour;
            window1_colour2 = window1_colour1;
            
            % Window 2 dot parameters
            window2_vec1 = this.ExperimentOptions.DisplayOptions.degS_to_pixFrame_convFactor(1)*this.TrialTable.Window2_Velocity{thisTrialData.TrialNumber, :};
            window2_vec2 = window2_vec1;
            window2_colour1 = all_dots_colour;
            window2_colour2 = window2_colour1;
            
            % Window 3 dot parameters
            window3_vec1 = this.ExperimentOptions.DisplayOptions.degS_to_pixFrame_convFactor(1)*this.TrialTable.Window3_Velocity{thisTrialData.TrialNumber, :};
            window3_vec2 = window3_vec1;  
            window3_colour1 = all_dots_colour;
            window3_colour2 = window3_colour1;

            %% set_3windows_positions
            draw_bordersX1 = [window_centers(1, 1) - bord_marg*window_radii(1), window_centers(1, 1) + bord_marg*window_radii(1)];
            draw_bordersY1 = [window_centers(1, 2) - bord_marg*window_radii(1), window_centers(1, 2) + bord_marg*window_radii(1)];
            
            draw_bordersX2 = [window_centers(2, 1) - bord_marg*window_radii(2), window_centers(2, 1) + bord_marg*window_radii(2)];
            draw_bordersY2 = [window_centers(2, 2) - bord_marg*window_radii(2), window_centers(2, 2) + bord_marg*window_radii(2)];

            draw_bordersX3 = [window_centers(3, 1) - bord_marg*window_radii(3), window_centers(3, 1) + bord_marg*window_radii(3)];
            draw_bordersY3 = [window_centers(3, 2) - bord_marg*window_radii(3), window_centers(3, 2) + bord_marg*window_radii(3)];


            % set window boundaries
            this.lots_dots1.centerX = window_centers(1, 1);
            this.lots_dots1.centerY = window_centers(1, 2);
            this.lots_dots1.bordersX = draw_bordersX1;
            this.lots_dots1.bordersY = draw_bordersY1;
            
            this.lots_dots2.centerX = window_centers(2, 1);
            this.lots_dots2.centerY = window_centers(2, 2);
            this.lots_dots2.bordersX = draw_bordersX2;
            this.lots_dots2.bordersY = draw_bordersY2;
            
            this.lots_dots3.centerX = window_centers(3, 1);
            this.lots_dots3.centerY = window_centers(3, 2);
            this.lots_dots3.bordersX = draw_bordersX3;
            this.lots_dots3.bordersY = draw_bordersY3;


            % Update the moveVecs
            this.lots_dots1.moveVec_array = repmat(window1_vec1, size(this.lots_dots1.moveVec_array, 1), 1);
            this.lots_dots2.moveVec_array = repmat(window2_vec1, size(this.lots_dots2.moveVec_array, 1), 1);
            this.lots_dots3.moveVec_array = repmat(window3_vec1, size(this.lots_dots3.moveVec_array, 1), 1);


            % little invisible prelim run to make the dots spots more diffuse
            prelim_run = true;
            prelim_run_time = 0;
            time = 0;
            % Query the frame duration
            ifi = Screen('GetFlipInterval', this.Graph.window);
            
            while prelim_run
            
                % Update stimulus screen
                this.lots_dots1 = this.lots_dots1.move();
       
                this.lots_dots2 = this.lots_dots2.move();
                this.lots_dots3 = this.lots_dots3.move();
            
                % Increment the time
                time = time + ifi;
                %timestamps(end+1) = time;
            
                if time > prelim_run_time
                    prelim_run = false;
                end
            end

            fprintf(['Trial: %0.0f | W_Vec1: [%0.1f, %0.1f]| W_Vec2: [%0.1f, %0.1f]| W_Vec3: [%0.' ...
                '1f, %0.1f]'], ...
                thisTrialData.TrialNumber, ...
                window1_vec1(1), window1_vec1(2), ...
                window2_vec1(1), window2_vec1(2), ...
                window3_vec1(1), window3_vec1(2));


        end
        

        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )

            try

                
                if this.ExperimentOptions.UseEyeTracker
                    nframesctr = 1;

                    [framenumber, eyetrackertime] = this.eyeTracker.RecordEvent( ...
                        sprintf('STIMULUS_ONSET [,trial=%d condition=%d]', ...
                        thisTrialData.TrialNumber, thisTrialData.Condition) );
                
                    % matches the frame number to the eyetracker time at the start of the trial
                    thisTrialData.EyeTrackerFrameNumberStimulusOnset = framenumber;
                    thisTrialData.EyeTrackerTimeStimulusOnset = eyetrackertime;

                end

                %% Fixation Configuration
                fixation_type = this.ExperimentOptions.Fixation_Type;
                fixation_size = this.ExperimentOptions.Fixation_Size_Deg;
                fixation_color = this.ExperimentOptions.Fixation_Color;
                fixation_line_width = this.ExperimentOptions.Fixation_Line_Width;

                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;


                lastFlipTime        = GetSecs;
                secondsRemaining    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;


                %this.ExperimentOptions.Initial_Fixation_Duration = 0.5;
                %this.ExperimentOptions.Motion_Duration = 1;

                % make this a bit shorter
                screenCenterX = this.ExperimentOptions.DisplayOptions.screenCenterX;
                screenCenterY = this.ExperimentOptions.DisplayOptions.screenCenterY;

                % Initialize the eyePos to be recorded and averaged during the trial
                eyePos_FixationPeriod = [0, 0];
                N=1; % counter for how many have been added to the average

                % how much do we want the fixation position calc to cut
                % into the actual trial?
                cut_in = 0.2;


                while secondsRemaining > 0

                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;


                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                       

                    % Add to the average IF using eyetracker and above
                    % the Initial_Fixation_Buffer_Duration time
                    if (this.ExperimentOptions.UseEyeTracker && ...
                            secondsElapsed < this.ExperimentOptions.Initial_Fixation_Duration + cut_in && ...
                            secondsElapsed > this.ExperimentOptions.Initial_Fixation_Buffer_Duration)
                        % Get the eye tracking data to know where the eye is looking at
                        eyeData = this.eyeTracker.GetCurrentData();

                        % add to the average - just using the first one bc ultimately relative
                        eyePos_FixationPeriod(1) = eyeData.gx(1)*(1/N) + eyePos_FixationPeriod(1)*((N-1)/N);
                        eyePos_FixationPeriod(2) = eyeData.gy(1)*(1/N) + eyePos_FixationPeriod(2)*((N-1)/N);
                        fprintf('\n[0.2%f,0.2%f]', eyePos_FixationPeriod(1), eyePos_FixationPeriod(2));

                        % increment counter
                        N=N+1;
                    end


                    % Fixation Period:
                    if (secondsElapsed < this.ExperimentOptions.Initial_Fixation_Duration)
                       
                        % Move the dots without showing them
                        this.lots_dots1.move();
                        this.lots_dots2.move();
                        this.lots_dots3.move();
                        
                        %fprintf('\n[0.2%f]', secondsElapsed);

                    % Stimulus Presentation Period:
                    elseif ( secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration ...
                            && secondsElapsed < this.ExperimentOptions.Initial_Fixation_Duration + this.ExperimentOptions.Motion_Duration)

                        % first move dots
                        % Move the dots in each window
                        this.lots_dots1.move();
                        this.lots_dots2.move();
                        this.lots_dots3.move();


                        % Draw the dots for window 1
                        Screen('DrawDots', graph.window, this.lots_dots1.location_array', this.lots_dots1.diameter_array, (this.lots_dots1.colour_array)', [], 2);

                        % Draw the dots for window 2
                        Screen('DrawDots', graph.window, this.lots_dots2.location_array', this.lots_dots2.diameter_array, (this.lots_dots2.colour_array)', [], 2);

                        % Draw the dots for window 3
                        Screen('DrawDots', graph.window, this.lots_dots3.location_array', this.lots_dots3.diameter_array, (this.lots_dots3.colour_array)', [], 2);
                    
                    % Draw numbers for responses
                    elseif ( secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration ...
                            + this.ExperimentOptions.Motion_Duration)% ...
                           % && secondsElapsed < this.ExperimentOptions.TrialDuration)

                        circleRadius = this.lots_dots1.radius; % adjust if needed
    
                        circleCenters = [
                            this.lots_dots1.centerX, this.lots_dots1.centerY;
                            this.lots_dots2.centerX, this.lots_dots2.centerY;
                            this.lots_dots3.centerX, this.lots_dots3.centerY
                            ];
    
                        Screen('TextSize', graph.window, 40);
    
                        for i = 1:3
    
                            % rect = CenterRectOnPointd([0 0 2*circleRadius 2*circleRadius], ...
                            %                           circleCenters(i,1), ...
                            %                           circleCenters(i,2));
                            %
                            % Screen('FrameOval', window, white_col, rect, 3);
    
                            numberStr = num2str(i);
                            bounds = Screen('TextBounds', graph.window, numberStr);
                            textWidth  = bounds(3);
                            textHeight = bounds(4);
    
                            Screen('DrawText', graph.window, numberStr, ...
                                circleCenters(i,1) - textWidth/2, ...
                                circleCenters(i,2) - textHeight/2, ...
                                this.ExperimentOptions.DisplayOptions.white_col);
                        end
                    
                    end


                    % Draw fixation spot
                    if(1)

                        % TODO: grab experiment options

                        %-- Find the center of the screen
                        [mx, my] = RectCenter(graph.wRect);

                        fixRect = [0 0 10 10];
                        fixRect = CenterRectOnPointd(fixRect, mx, my );
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

                    % only show gaze bounding box if ClaraDebug
                    % if this.ExperimentOptions.ClaraDebug
                    %     fix_bounds_rect = [0 0 2*this.ExperimentOptions.Fixation_Check_WinSize_pix 2*this.ExperimentOptions.Fixation_Check_WinSize_pix];
                    %     fix_bounds_rect = CenterRectOnPointd(fix_bounds_rect, mx, my );
                    %     Screen('FrameRect', graph.window, [255 255 0], fix_bounds_rect, 3);
                    % end



                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------

                    % Get all gaze data
                    PBT_Time = this.Graph.Flip(this, thisTrialData, secondsRemaining);
  
                    % -----------------------------------------------------------------
                    % -- Flip buffers to refresh screen -------------------------------
                    % -----------------------------------------------------------------
                    % Screen('Flip', this.Graph.window)
                    % this.Graph.Flip(this, secondsRemaining);
                    %this.Graph.Flip(this, thisTrialData, secondsRemaining); % only shows all the variables when
                    %in debug mode
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
                                    KbName(keys(i))

                                    switch(KbName(keys(i)))
                                        case {'1' '1!'}
                                            response = 1;
                                        case {'2' '2@'}
                                            response = 2;
                                        case {'3' '3#'}
                                            response = 3;
                                    end
                                end
                            end
                            if ( ~isempty( response) )
                                thisTrialData.Response = response;
                                thisTrialData.ResponseTime = GetSecs;

                                if this.ExperimentOptions.UseEyeTracker
                                    [framenumber, eyetrackertime] = this.eyeTracker.RecordEvent( ...
                                        sprintf('STIMULUS_OFFSET [trial=%d, condition=%d]', ...
                                        thisTrialData.TrialNumber, thisTrialData.Condition) );
                                
                                    thisTrialData.EyeTrackerFrameNumberStimulusOffset = framenumber;
                                    thisTrialData.EyeTrackerTimeStimulusOffset = eyetrackertime;
            
                                    % truncate table to correct sz
                                    this.gazedata = this.gazedata(1:nframesctr-1,:);
                                    thisTrialData.gazedatatbl = {this.gazedata};
                                    
                                    % establish how much time there were between frames
                                    thisTrialData.EmpiricalFPS = (nframesctr-2)/sum(diff(this.gazedata.PTBtime));
            
                                end

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

                    if ( secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration + max(cut_in, this.ExperimentOptions.Min_Motion_Duration_Before_Response))

                        if ( ~isempty(this.eyeTracker) && this.ExperimentOptions.UseEyeTracker)

                            % Get the eye tracking data to know where the eye is looking at
                            eyeData = this.eyeTracker.GetCurrentData();


                            if isfield(eyeData,'gx') && isfield(eyeData,'gy')
                                gazeX = eyeData.gx(2)/2+eyeData.gx(1)/2;
                                gazeY = eyeData.gy(2)/2+eyeData.gy(1)/2;
                            else
                                % assume eyes are closed and out of bounds?
                                gazeX = inf;
                                gazeY = inf;
                            end

                            % only show fixation tracking dot if ClaraDebug
                            if this.ExperimentOptions.ClaraDebug 
                                fixRect = [0 0 10 10];
                                fixRect = CenterRectOnPointd( fixRect, gazeX, gazeY );

                                Screen('FillOval', graph.window,  [255 0 0], fixRect);

                                % also show the initial fixation period average, which is the reference
                                refRect = [0 0 10 10];
                                refRect = CenterRectOnPointd( refRect, eyePos_FixationPeriod(1), eyePos_FixationPeriod(2) );
                                Screen('FillOval', graph.window,  [255 255 0], refRect);

                                fix_bounds_rect = [0 0 2*this.ExperimentOptions.Fixation_Check_WinSize_pix 2*this.ExperimentOptions.Fixation_Check_WinSize_pix];
                                fix_bounds_rect = CenterRectOnPointd(fix_bounds_rect, eyePos_FixationPeriod(1), eyePos_FixationPeriod(2));
                                Screen('FrameRect', graph.window, [255 255 0], fix_bounds_rect, 3);
                            end
                        end

                        % 
                        % this.gazedata.PTBtime(nframesctr) = PBT_Time;
                        % this.gazedata.ELtime(nframesctr) = eyeData.time;
                        % this.gazedata.LGazeX(nframesctr) =
                        % eyeData.gx(1);2
                        % this.gazedata.RGazeX(nframesctr) = eyeData.gx(2);
                        % this.gazedata.LGazeY(nframesctr) = eyeData.gy(1);
                        % this.gazedata.RGazeY(nframesctr) = eyeData.gy(2);
                        % 
                        % nframesctr = nframesctr+1;

                        % Check to make sure that the participant is looking where they're supposed to look
                        % I think the Fixation_Check_WinSize_pix is like the "radius" of the rectangle, so the actual
                        % bounding box is 2x this measurement

                        % only need to do fixation check if during experiment time
                        if secondsElapsed < this.ExperimentOptions.Initial_Fixation_Duration + this.ExperimentOptions.Motion_Duration
                            this.checkFixation(eyePos_FixationPeriod, this.ExperimentOptions.Fixation_Check_WinSize_pix, this.ExperimentOptions.Fixation_Check_TimeOut);
                            % this.checkFixation(fixRect([1 2]), this.ExperimentOptions.Fixation_Check_WinSize_pix, this.ExperimentOptions.Fixation_Check_TimeOut)
                        end



                    end
                    % -----------------------------------------------------------------
                    % --- Check Fixation  -----------------------------------
                    % -----------------------------------------------------------------
                end

                % ============================================================
                % --- Break screen every N trials -----------------------------
                % ============================================================
                TrialsBeforeBreakSmall = this.ExperimentOptions.TrialsBeforeBreakSmall; % e.g., set this in options
                
                if mod(thisTrialData.TrialNumber, TrialsBeforeBreakSmall) == 0
                
                    % Flush any previous key presses
                    KbReleaseWait;
                
                    waitingForKey = true;
                
                    while waitingForKey
                
                        % --- Draw your break text ---
                        Screen('TextSize', graph.window, 40);
                        breakText = 'Break time!\n\nPress SPACE to continue'; % <-- replace later
                        DrawFormattedText(graph.window, breakText, 'center', 'center', ...
                            this.ExperimentOptions.DisplayOptions.white_col);
                
                        % --- Draw fixation (same style as your trial) ---
                        [mx, my] = RectCenter(graph.wRect);
                
                        % central dot
                        fixRect = [0 0 10 10];
                        fixRect = CenterRectOnPointd(fixRect, mx, my);
                        Screen('FillOval', graph.window, this.fixColor, fixRect);
                
                        % optional fixation type
                        if strcmp(fixation_type, 'circle')
                            fixation_rect = [screenCenterX - fixation_size/2, screenCenterY - fixation_size/2, ...
                                             screenCenterX + fixation_size/2, screenCenterY + fixation_size/2];
                            Screen('FillOval', graph.window, fixation_color, fixation_rect);
                
                        elseif strcmp(fixation_type, 'cross')
                            cross_coords = [
                                screenCenterX - fixation_size/2, screenCenterY, screenCenterX + fixation_size/2, screenCenterY;
                                screenCenterX, screenCenterY - fixation_size/2, screenCenterX, screenCenterY + fixation_size/2
                            ];
                            Screen('DrawLines', graph.window, cross_coords', fixation_line_width, fixation_color, [0 0], 2);
                        end
                
                        % --- Flip to screen ---
                        Screen('Flip', graph.window);
                
                        % --- Wait for SPACE ---
                        [keyIsDown, ~, keyCode] = KbCheck;
                        if keyIsDown
                            if any(strcmp(KbName(find(keyCode)), {'space', 'SPACE'}))
                                waitingForKey = false;
                                KbReleaseWait;
                            end
                        end
                    end
                end
            
            catch ex
                rethrow(ex)
            end
            
        end        
    end
    
end

