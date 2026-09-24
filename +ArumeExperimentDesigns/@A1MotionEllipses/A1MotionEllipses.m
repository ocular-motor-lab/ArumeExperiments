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
            % dlg.Max_Increment_Speed_Percent = { 100 '* (%)' [0.1 100] };
            % dlg.Max_Increment_Direction_Angle = { 60 '* (deg)' [0.1 100] };
            % dlg.Number_Of_Increments = 9;
            % dlg.Stimulus_Type = { {'{both}' 'speed' 'direction'} };

            %dlg.Max_RefVelocityComponent = { 2 '* (deg/s)' [0.01 100] };
            %dlg.Num_RefVelocitiesPerComponent = 5;


            %dlg.Do_Full_Grid = { {'0','{1}'} };
            %dlg.Num_Repeats = {8 '* (N)' [1 100] };

            dlg.Dots_Per_Window = 700;
            dlg.Dots_Diameter   = { 1.5 '* (pix)' [0.01 100] };
            dlg.Dots_LifeTime   = { 0.5 '* (sec)' [0.01 100] };
            dlg.Dots_Grey_Level = [0.5];

            dlg.Window_Radius_Deg   = { 0.5 '* (deg)' [0.01 100] };
            dlg.Window_Eccentricity_Deg   = { 0.75 '* (deg)' [0.01 100] };

            dlg.Fixation_Check_WinSize = {1.25 '* (deg)' [0.01 100]};
            dlg.Fixation_Check_TimeOut = 0.5;

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
            dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult OddballWindow ReferenceVelocity CompOffsetVector'; % which variables to display every trial in the command line separated by spaces

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
            dlg.TrialsBeforeBreak = 200; % big break; also controls how many trials in a row will have the same mickey-mouse orientation
            dlg.TrialsBeforeBreakSmall = 25; % small break
            dlg.TrialAbortAction = 'Delay';


           %% Reference Vector Options
            % Global Ref Parameters
            dlg.lb_screen = { 0.5 '* (deg/s)' [0 300] };
            dlg.ub_screen = { 8 '* (deg/s)' [0 300] };
            dlg.num_ref_gridpts =  { 11 '*' [1 3000] };
            dlg.ref_cart_or_polar = { {'polar' '{cartesian}'} };
            dlg.num_ref_spokes = {8 '*' [1 3000] };
            dlg.ref_log_or_lin = { {'log' '{lin}'} };

            % Local Comp Parameters (The relative offsets)
            dlg.comp_lb = { 0 '* (x ref_vec speed)' [0 300] };
            dlg.comp_ub = { 1 '* (x ref_vec speed)' [0 300] };
            dlg.comp_num_intervals = { 8 '* ' [1 300] };
            dlg.comp_num_axes = { 8 '* ' [1 300] };
            dlg.comp_cart_or_polar = { {'polar' '{cartesian}'} };
            dlg.comp_rel_bool = { {'0',['{ ' ...
                '' ...
                '' ...
                '                                1}']} };

            dlg.nonzero_rand = { 0.25 '* (x ref_vec speed)' [0 300]};
            dlg.low_speed = { 3.1 '* (x ref_vec speed)' [0 300]};
            dlg.outer_downsample_n = { 2 '* (x ref_vec speed)' [0 300]};


            % Global Ref Parameters
            dlg.lb_screen_hard = { 0.5 '* (deg/s)' [0 300] };
            dlg.ub_screen_hard = { 8 '* (deg/s)' [0 300] };
            dlg.num_ref_gridpts_hard =  { 11 '*' [1 3000] };
            dlg.ref_cart_or_polar_hard = { {'polar' '{cartesian}'} };
            dlg.num_ref_spokes_hard = {8 '*' [1 3000] };
            dlg.ref_log_or_lin_hard = { {'log' '{lin}'} };

            % Local Comp Parameters (The relative offsets)
            dlg.comp_lb_hard = { 0 '* (x ref_vec speed)' [0 300] };
            dlg.comp_ub_hard = { 0.12 '* (x ref_vec speed)' [0 300] };
            dlg.comp_num_intervals_hard = { 5 '* ' [1 300] };
            dlg.comp_num_axes_hard = { 3 '* ' [1 300] };
            dlg.comp_cart_or_polar_hard = { {'polar' '{cartesian}'} };
            dlg.comp_rel_bool_hard = { {'0','{1}'} };
            dlg.spec_comp_intervals_hard = {[-0.10, -0.05, 0, 0.075, 0.10]};
            dlg.target_base_trials_hard = {1400 '* ' [1 20000]};


            % random trials for easiness
            dlg.num_random_trials_hard = 0;%200;
            dlg.rand_comp_lb_hard = 0.2;
            dlg.rand_comp_ub_hard = 0.8;

            % Jitter Parameters
            dlg.Do_Jitter = { {'0','{1}'} }; % Boolean toggle
            dlg.Jitter_Multiplier = { 0.05 '* (x comp_vec speed)' [0 300] }; % e.g., 0.05 for 5% jitter

            dlg.Num_Repeats_Per_Combo = {1  '* ' [0 300]};

            dlg.EyeTrackerCalibProportion = {[.30,.30],'Calibration Area (width, height)',[0.05,1],1};

            dlg.ClaraDebug = { {'1','{0}'} };

        end

        function trialTable = SetUpTrialTable(this)
        %% 1. Universal Parameter Extraction & Seed RNG
            rng(keyHash(this.Session.subjectCode)/10^10)
            
            num_repeats = this.ExperimentOptions.Num_Repeats_Per_Combo;
            do_jitter   = this.ExperimentOptions.Do_Jitter;
            jitter_mult = this.ExperimentOptions.Jitter_Multiplier;
            base_speed  = 0.25;

            nonzero_rand = 0.05;
            if isprop(this.ExperimentOptions, 'nonzero_rand') || isfield(this.ExperimentOptions, 'nonzero_rand')
                if ~isempty(this.ExperimentOptions.nonzero_rand)
                    nonzero_rand = this.ExperimentOptions.nonzero_rand;
                end
            end

            low_speed = 0.1;
            if isprop(this.ExperimentOptions, 'low_speed') || isfield(this.ExperimentOptions, 'low_speed')
                if ~isempty(this.ExperimentOptions.low_speed)
                    low_speed = this.ExperimentOptions.low_speed;
                end
            end

            % Downsampling factor for extra low-speed trial components (default 2 -> half)
            outer_downsample_n = 2;
            if isprop(this.ExperimentOptions, 'outer_downsample_n') || isfield(this.ExperimentOptions, 'outer_downsample_n')
                if ~isempty(this.ExperimentOptions.outer_downsample_n)
                    outer_downsample_n = this.ExperimentOptions.outer_downsample_n; 
                end
            end             
           
            %% ====================================================================
            %% SET 1: STANDARD TRIALS
            %% ====================================================================
            lb_ref      = this.ExperimentOptions.lb_screen;
            if isempty(lb_ref), lb_ref = 0; end
            ub_ref      = this.ExperimentOptions.ub_screen;
            num_ref_pts = this.ExperimentOptions.num_ref_gridpts;
            ref_mode    = this.ExperimentOptions.ref_cart_or_polar;
            ref_log_or_lin = this.ExperimentOptions.ref_log_or_lin;
            
            comp_lb        = this.ExperimentOptions.comp_lb;
            if isempty(comp_lb), comp_lb = 0; end
            comp_ub        = this.ExperimentOptions.comp_ub;
            comp_intervals = this.ExperimentOptions.comp_num_intervals;
            comp_axes      = this.ExperimentOptions.comp_num_axes;
            comp_mode      = this.ExperimentOptions.comp_cart_or_polar;
            comp_rel_bool  = this.ExperimentOptions.comp_rel_bool; 
            
            % Generate Global Reference Vectors (Standard)
            if strcmpi(ref_mode, 'cartesian')
                ref_ax = linspace(-ub_ref, ub_ref, num_ref_pts);
                [rvx, rvy] = meshgrid(ref_ax, ref_ax);
                ref_vecs = [rvx(:), rvy(:)];
            else
                num_ref_spokes = this.ExperimentOptions.num_ref_spokes;
                angles = linspace(0, 2*pi, num_ref_spokes + 1);
                angles(end) = []; 
                if strcmpi(ref_log_or_lin, 'log')
                    radii = logspace(log10(lb_ref), log10(ub_ref), max(1, num_ref_pts));
                else
                    radii = linspace(lb_ref, ub_ref, max(1, num_ref_pts));
                end
                [A, R] = meshgrid(angles, radii);
                [vx, vy] = pol2cart(A(:), R(:));
                ref_vecs = [vx, vy];
            end
            
            if ~any(sqrt(sum(ref_vecs.^2, 2)) < 1e-10)
                ref_vecs = [0, 0; ref_vecs];
            end
            num_refs = size(ref_vecs, 1);
            
            % Generate Default Local Comparison Offsets (Standard)
            if strcmpi(comp_mode, 'cartesian')
                comp_ax = linspace(-comp_ub, comp_ub, comp_intervals);
                [cvx, cvy] = meshgrid(comp_ax, comp_ax);
                base_comps = [cvx(:), cvy(:)];
                c_mags = sqrt(sum(base_comps.^2, 2));
                
                valid_idx = c_mags >= comp_lb & c_mags <= comp_ub;
                std_comp_offsets_def = base_comps(valid_idx, :);
                std_comp_offset_multipliers_def = c_mags(valid_idx);
                [~, ~, std_comp_offset_radius_idx_def] = unique(round(c_mags(valid_idx), 4));
            else
                comp_angles = linspace(0, 2*pi, comp_axes + 1);
                comp_angles(end) = [];
                comp_radii = linspace(comp_lb, comp_ub, comp_intervals);
                
                radius_indices = 1:comp_intervals;
                [cA, cR] = meshgrid(comp_angles, comp_radii);
                [~, cR_idx] = meshgrid(comp_angles, radius_indices);
                [cvx, cvy] = pol2cart(cA(:), cR(:));
                std_comp_offsets_def = [cvx, cvy];
                std_comp_offset_radius_idx_def = cR_idx(:);
                std_comp_offset_multipliers_def = cR(:);
            end
            
            % Combine and Build Standard Base Trial Arrays
            std_ref = {};
            std_comp_base = {};
            std_comp_offset = {};
            std_comp_offset_rel = {};
            std_comp_radius = [];
            std_comp_radius_rel = [];
            std_comp_axis   = [];
            std_comp_rad_idx = [];
            std_comp_mult   = [];
            std_is_zero_ref = [];

            % --- PRECOMPUTE BALANCED & RANDOMIZED OFFSETS ---
            start_offsets = zeros(num_refs, 1);
            
            % Identify which reference vectors meet the qualifying criteria
            qualifying_mask = false(num_refs, 1);
            if comp_rel_bool && strcmpi(comp_mode, 'cartesian')
                for r = 1:num_refs
                    sp = norm(ref_vecs(r, :));
                    if (sp < low_speed) && (sp >= 1e-10)
                        qualifying_mask(r) = true;
                    end
                end
            end
            
            num_qual = sum(qualifying_mask);
            
            if num_qual > 0
                % Create an evenly balanced pool of offsets [1, 2, ..., N, 1, 2, ..., N]
                offset_pool = mod(0:num_qual-1, outer_downsample_n) + 1;
                
                % Shuffle the pool randomly
                offset_pool = offset_pool(randperm(num_qual));
                
                % Assign to the qualifying refs
                start_offsets(qualifying_mask) = offset_pool;
            end
            
            for r = 1:num_refs
                v_ref = ref_vecs(r, :);
                ref_speed = norm(v_ref);
                is_zero = (ref_speed < 1e-10);
                
                % Standard condition: low speed refs (EXCLUDING 0) with relative comp get an extra grid axis step
                if comp_rel_bool && (ref_speed < low_speed) && ~is_zero
                    if strcmpi(comp_mode, 'cartesian')
                        % comp_ax_base = linspace(-comp_ub, comp_ub, comp_intervals);
                        % step_sz = comp_ax_base(2) - comp_ax_base(1);
                        % 
                        % if rand() > 0.5
                        %     comp_ax_ext = [comp_ax_base, comp_ax_base(end) + step_sz];
                        % else
                        %     comp_ax_ext = [comp_ax_base(1) - step_sz, comp_ax_base];
                        % end
                        % 
                        % [cvx, cvy] = meshgrid(comp_ax_ext, comp_ax_ext);
                        % base_comps_r = [cvx(:), cvy(:)];
                        % c_mags_r = sqrt(sum(base_comps_r.^2, 2));
                        % 
                        % max_ub = max(abs(comp_ax_ext));
                        % valid_idx_r = c_mags_r >= comp_lb & c_mags_r <= (max_ub + 1e-5);
                        % comp_offsets_r = base_comps_r(valid_idx_r, :);
                        % comp_offset_multipliers_r = c_mags_r(valid_idx_r);
                        % [~, ~, comp_offset_radius_idx_r] = unique(round(c_mags_r(valid_idx_r), 4));
                        comp_ax_base = linspace(-comp_ub, comp_ub, comp_intervals);
                        step_sz = comp_ax_base(2) - comp_ax_base(1);
                        
                        % Add both lower and upper extra steps
                        comp_ax_ext = [comp_ax_base(1) - step_sz, comp_ax_base, comp_ax_base(end) + step_sz];
                        
                        [cvx, cvy] = meshgrid(comp_ax_ext, comp_ax_ext);
                        base_comps_r = [cvx(:), cvy(:)];
                        c_mags_r = sqrt(sum(base_comps_r.^2, 2));
                        
                        % FIX: Expand outer boundary safely to capture the 2D radius of the new ring
                        outer_radius_limit = comp_ub + (step_sz * 1.00001); 
                        
                        % Isolate the strict original circle and the new outer ring (annulus)
                        is_inner = c_mags_r >= comp_lb & c_mags_r <= (comp_ub + 1e-5);
                        is_outer = c_mags_r > (comp_ub + 1e-5) & c_mags_r <= outer_radius_limit;
                        
                        inner_idx = find(is_inner);
                        outer_idx = find(is_outer);
                        
                        if ~isempty(outer_idx)
                            start_offset = start_offsets(r);
                            %outer_kept = outer_idx(start_offset : outer_downsample_n : end);

                            % snake draft
                            % 1. Define the full range of potential indices you care about
                            idx_range = start_offset : length(outer_idx);
                            
                            % 2. Create a 0-based step counter (0, 1, 2, 3...)
                            steps = 0 : length(idx_range) - 1;
                            
                            % 3. Create a logical mask: floor(steps / n) groups them into chunks of n
                            % mod(..., 2) == 0 keeps the even chunks (keep), and drops the odd chunks (skip)
                            keep_mask = mod(floor(steps / outer_downsample_n), 2) == 0;
                            
                            % 4. Apply the mask to index your array
                            outer_kept = outer_idx(idx_range(keep_mask));
                        else
                            outer_kept = [];
                        end
                        
                        final_idx = [inner_idx; outer_kept];
                        
                        comp_offsets_r = base_comps_r(final_idx, :);
                        comp_offset_multipliers_r = c_mags_r(final_idx);
                        [~, ~, comp_offset_radius_idx_r] = unique(round(c_mags_r(final_idx), 4));
                    else
                        comp_angles = linspace(0, 2*pi, comp_axes + 1);
                        comp_angles(end) = [];
                        comp_radii_base = linspace(comp_lb, comp_ub, comp_intervals);
                        step_sz = comp_radii_base(2) - comp_radii_base(1);
                        
                        if rand() > 0.5
                            comp_radii_ext = [comp_radii_base, comp_radii_base(end) + step_sz];
                        else
                            comp_radii_ext = [max(0, comp_radii_base(1) - step_sz), comp_radii_base];
                        end
                        
                        radius_indices_r = 1:length(comp_radii_ext);
                        [cA, cR] = meshgrid(comp_angles, comp_radii_ext);
                        [~, cR_idx] = meshgrid(comp_angles, radius_indices_r);
                        [cvx, cvy] = pol2cart(cA(:), cR(:));
                        comp_offsets_r = [cvx, cvy];
                        comp_offset_radius_idx_r = cR_idx(:);
                        comp_offset_multipliers_r = cR(:);
                    end
                else
                    comp_offsets_r = std_comp_offsets_def;
                    comp_offset_multipliers_r = std_comp_offset_multipliers_def;
                    comp_offset_radius_idx_r = std_comp_offset_radius_idx_def;
                end
                
                num_comps_r = size(comp_offsets_r, 1);
                for c = 1:num_comps_r
                    std_ref{end+1, 1} = v_ref;
                    std_is_zero_ref(end+1, 1) = is_zero;
                    
                    if comp_rel_bool
                        actual_offset = comp_offsets_r(c, :) .* ref_speed;
                        if ref_speed == 0, actual_offset = comp_offsets_r(c, :) .* base_speed; end
                    else
                        actual_offset = comp_offsets_r(c, :);
                    end
                    
                    std_comp_base{end+1, 1}       = v_ref + actual_offset;
                    std_comp_offset{end+1, 1}     = actual_offset;
                    std_comp_offset_rel{end+1, 1} = comp_offsets_r(c, :);
                    std_comp_radius(end+1, 1)     = norm(actual_offset);
                    std_comp_radius_rel(end+1, 1) = norm(comp_offsets_r(c, :));
                    std_comp_axis(end+1, 1)       = wrapTo360(rad2deg(atan2(actual_offset(2), actual_offset(1))));
                    std_comp_rad_idx(end+1, 1)    = comp_offset_radius_idx_r(c);
                    std_comp_mult(end+1, 1)       = comp_offset_multipliers_r(c);
                end
            end
            
            % Repeat Standard set manually for concatenation
            std_ref = repmat(std_ref, num_repeats, 1);
            std_is_zero_ref = repmat(std_is_zero_ref, num_repeats, 1);
            std_comp_base = repmat(std_comp_base, num_repeats, 1);
            std_comp_offset = repmat(std_comp_offset, num_repeats, 1);
            std_comp_offset_rel = repmat(std_comp_offset_rel, num_repeats, 1);
            std_comp_radius = repmat(std_comp_radius, num_repeats, 1);
            std_comp_radius_rel = repmat(std_comp_radius_rel, num_repeats, 1);
            std_comp_axis = repmat(std_comp_axis, num_repeats, 1);
            std_comp_rad_idx = repmat(std_comp_rad_idx, num_repeats, 1);
            std_comp_mult = repmat(std_comp_mult, num_repeats, 1);

            %% ====================================================================
            %% SET 2: HARD TRIALS (Using _hard suffix parameters)
            %% ====================================================================
            lb_ref_h      = this.ExperimentOptions.lb_screen_hard;
            if isempty(lb_ref_h), lb_ref_h = 0; end
            ub_ref_h      = this.ExperimentOptions.ub_screen_hard;
            num_ref_pts_h = this.ExperimentOptions.num_ref_gridpts_hard;
            ref_mode_h    = this.ExperimentOptions.ref_cart_or_polar_hard;
            ref_log_or_lin_h = this.ExperimentOptions.ref_log_or_lin_hard;
            
            comp_lb_h        = this.ExperimentOptions.comp_lb_hard;
            if isempty(comp_lb_h), comp_lb_h = 0; end
            comp_ub_h        = this.ExperimentOptions.comp_ub_hard;
            comp_intervals_h = this.ExperimentOptions.comp_num_intervals_hard;
            comp_axes_h      = this.ExperimentOptions.comp_num_axes_hard;
            comp_mode_h      = this.ExperimentOptions.comp_cart_or_polar_hard;
            comp_rel_bool_h  = this.ExperimentOptions.comp_rel_bool_hard; 
            
            custom_comp_intervals_h = [];
            if isprop(this.ExperimentOptions, 'spec_comp_intervals_hard') || isfield(this.ExperimentOptions, 'spec_comp_intervals_hard')
                custom_comp_intervals_h = this.ExperimentOptions.spec_comp_intervals_hard;
            end
            
            target_base_trials_h = [];
            if isprop(this.ExperimentOptions, 'target_base_trials_hard') || isfield(this.ExperimentOptions, 'target_base_trials_hard')
                target_base_trials_h = this.ExperimentOptions.target_base_trials_hard;
            end
            
            num_random_trials_h = 0;
            if isprop(this.ExperimentOptions, 'num_random_trials_hard') || isfield(this.ExperimentOptions, 'num_random_trials_hard')
                num_random_trials_h = this.ExperimentOptions.num_random_trials_hard;
                if isempty(num_random_trials_h), num_random_trials_h = 0; end
            end
            
            rand_comp_lb_h = comp_lb_h;
            if isprop(this.ExperimentOptions, 'rand_comp_lb_hard') || isfield(this.ExperimentOptions, 'rand_comp_lb_hard')
                if ~isempty(this.ExperimentOptions.rand_comp_lb_hard), rand_comp_lb_h = this.ExperimentOptions.rand_comp_lb_hard; end
            end
            
            rand_comp_ub_h = comp_ub_h; 
            if isprop(this.ExperimentOptions, 'rand_comp_ub_hard') || isfield(this.ExperimentOptions, 'rand_comp_ub_hard')
                if ~isempty(this.ExperimentOptions.rand_comp_ub_hard), rand_comp_ub_h = this.ExperimentOptions.rand_comp_ub_hard; end
            end

            % Generate Global Reference Vectors (Hard)
            if strcmpi(ref_mode_h, 'cartesian')
                ref_ax_h = linspace(-ub_ref_h, ub_ref_h, num_ref_pts_h);
                [rvx, rvy] = meshgrid(ref_ax_h, ref_ax_h);
                ref_vecs_h = [rvx(:), rvy(:)];
            else
                num_ref_spokes_h = this.ExperimentOptions.num_ref_spokes_hard;
                angles = linspace(0, 2*pi, num_ref_spokes_h + 1);
                angles(end) = []; 
                if strcmpi(ref_log_or_lin_h, 'log')
                    radii = logspace(log10(lb_ref_h), log10(ub_ref_h), max(1, num_ref_pts_h));
                else
                    radii = linspace(lb_ref_h, ub_ref_h, max(1, num_ref_pts_h));
                end
                [A, R] = meshgrid(angles, radii);
                [vx, vy] = pol2cart(A(:), R(:));
                ref_vecs_h = [vx, vy];
            end
            
            if ~any(sqrt(sum(ref_vecs_h.^2, 2)) < 1e-10)
                ref_vecs_h = [0, 0; ref_vecs_h];
            end
            num_refs_h = size(ref_vecs_h, 1);

            % Generate Local Comparison Offsets (Hard)
            if strcmpi(comp_mode_h, 'cartesian')
                if ~isempty(custom_comp_intervals_h)
                    comp_ax_h = custom_comp_intervals_h;
                else
                    comp_ax_h = linspace(-comp_ub_h, comp_ub_h, comp_intervals_h);
                end
                [cvx, cvy] = meshgrid(comp_ax_h, comp_ax_h);
                base_comps_h = [cvx(:), cvy(:)];
                c_mags_h = sqrt(sum(base_comps_h.^2, 2));
                
                valid_idx = c_mags_h >= comp_lb_h & c_mags_h <= comp_ub_h;
                comp_offsets_h = base_comps_h(valid_idx, :);
                comp_offset_multipliers_h = c_mags_h(valid_idx);
                [~, ~, comp_offset_radius_idx_h] = unique(round(c_mags_h(valid_idx), 4));
            else
                comp_angles_h = linspace(0, 2*pi, comp_axes_h + 1);
                comp_angles_h(end) = [];
                
                if ~isempty(custom_comp_intervals_h)
                    comp_radii_h = custom_comp_intervals_h;
                    actual_intervals_h = length(custom_comp_intervals_h);
                else
                    comp_radii_h = linspace(comp_lb_h, comp_ub_h, comp_intervals_h);
                    actual_intervals_h = comp_intervals_h;
                end
                
                radius_indices_h = 1:actual_intervals_h;
                [cA, cR] = meshgrid(comp_angles_h, comp_radii_h);
                [~, cR_idx] = meshgrid(comp_angles_h, radius_indices_h);
                [cvx, cvy] = pol2cart(cA(:), cR(:));
                comp_offsets_h = [cvx, cvy];
                comp_offset_radius_idx_h = cR_idx(:);
                comp_offset_multipliers_h = cR(:);
            end

            % Combine and Build Hard Trial Arrays
            num_comps_h = size(comp_offsets_h, 1);
            trials_per_rep_h = num_refs_h * num_comps_h;
            
            hard_ref = cell(trials_per_rep_h, 1);
            hard_is_zero_ref = zeros(trials_per_rep_h, 1);
            hard_comp_base = cell(trials_per_rep_h, 1);
            hard_comp_offset = cell(trials_per_rep_h, 1); 
            hard_comp_offset_rel = cell(trials_per_rep_h, 1);
            hard_comp_radius = zeros(trials_per_rep_h, 1); 
            hard_comp_radius_rel = zeros(trials_per_rep_h, 1);
            hard_comp_axis   = zeros(trials_per_rep_h, 1);
            hard_comp_rad_idx = zeros(trials_per_rep_h, 1); 
            hard_comp_mult   = zeros(trials_per_rep_h, 1);
            
            counter = 1;
            for r = 1:num_refs_h
                v_ref = ref_vecs_h(r, :);
                ref_speed = norm(v_ref);
                is_zero = (ref_speed < 1e-10);
                
                for c = 1:num_comps_h
                    hard_ref{counter} = v_ref;
                    hard_is_zero_ref(counter) = is_zero;
                    
                    if comp_rel_bool_h
                        actual_offset = comp_offsets_h(c, :) .* ref_speed;
                        if ref_speed == 0, actual_offset = comp_offsets_h(c, :) .* base_speed; end
                    else
                        actual_offset = comp_offsets_h(c, :);
                    end
                    hard_comp_base{counter} = v_ref + actual_offset;
                    hard_comp_offset{counter} = actual_offset;
                    hard_comp_offset_rel{counter} = comp_offsets_h(c, :);
                    hard_comp_radius(counter) = norm(actual_offset);
                    hard_comp_radius_rel(counter) = norm(comp_offsets_h(c, :));
                    hard_comp_axis(counter)   = wrapTo360(rad2deg(atan2(actual_offset(2), actual_offset(1))));
                    hard_comp_rad_idx(counter) = comp_offset_radius_idx_h(c);
                    hard_comp_mult(counter) = comp_offset_multipliers_h(c);
                    counter = counter + 1;
                end
            end
            
            % Repeat and Downsample arrays manually
            hard_ref = repmat(hard_ref, num_repeats, 1);
            hard_is_zero_ref = repmat(hard_is_zero_ref, num_repeats, 1);
            hard_comp_base = repmat(hard_comp_base, num_repeats, 1);
            hard_comp_offset = repmat(hard_comp_offset, num_repeats, 1);
            hard_comp_offset_rel = repmat(hard_comp_offset_rel, num_repeats, 1);
            hard_comp_radius = repmat(hard_comp_radius, num_repeats, 1);
            hard_comp_radius_rel = repmat(hard_comp_radius_rel, num_repeats, 1);
            hard_comp_axis = repmat(hard_comp_axis, num_repeats, 1);
            hard_comp_rad_idx = repmat(hard_comp_rad_idx, num_repeats, 1);
            hard_comp_mult = repmat(hard_comp_mult, num_repeats, 1);
        
            base_generated_h = length(hard_ref);
            
            % % Randomly cull base variables if target exists
            % if ~isempty(target_base_trials_h) && target_base_trials_h < base_generated_h
            %     keep_idx = randperm(base_generated_h, target_base_trials_h);
            % 
            %     hard_ref = hard_ref(keep_idx);
            %     hard_is_zero_ref = hard_is_zero_ref(keep_idx);
            %     hard_comp_base = hard_comp_base(keep_idx);
            %     hard_comp_offset = hard_comp_offset(keep_idx);
            %     hard_comp_offset_rel = hard_comp_offset_rel(keep_idx);
            %     hard_comp_radius = hard_comp_radius(keep_idx);
            %     hard_comp_radius_rel = hard_comp_radius_rel(keep_idx);
            %     hard_comp_axis = hard_comp_axis(keep_idx);
            %     hard_comp_rad_idx = hard_comp_rad_idx(keep_idx);
            %     hard_comp_mult = hard_comp_mult(keep_idx);
            %     base_kept_h = target_base_trials_h;

            % Randomly cull base variables if target exists, evenly distributed by reference vector
            if ~isempty(target_base_trials_h) && target_base_trials_h < base_generated_h
                
                % Convert cell array to matrix to group by unique reference vectors
                ref_mat = cell2mat(hard_ref);
                
                % Find unique reference vectors (rounding to 4 decimals to avoid floating point issues)
                [~, ~, ref_group_idx] = unique(round(ref_mat, 4), 'rows');
                num_groups = max(ref_group_idx);
                
                % Calculate how many trials to keep per unique reference vector
                trials_per_group = floor(target_base_trials_h / num_groups);
                remainder = mod(target_base_trials_h, num_groups);
                
                % Randomly decide which groups get the +1 remainder trials
                groups_with_extra = randperm(num_groups, remainder);
                
                keep_idx = [];
                
                for g = 1:num_groups
                    % Find all trial indices belonging to this specific reference vector
                    idx_for_group = find(ref_group_idx == g);
                    
                    % Determine the target number to keep for this group
                    num_to_keep_g = trials_per_group;
                    if ismember(g, groups_with_extra)
                        num_to_keep_g = num_to_keep_g + 1;
                    end
                    
                    % Fail-safe: don't try to keep more trials than actually exist in the group
                    num_to_keep_g = min(num_to_keep_g, length(idx_for_group));
                    
                    % Randomly select the specific trials to keep for this reference vector
                    rand_subset = randperm(length(idx_for_group), num_to_keep_g);
                    keep_idx = [keep_idx; idx_for_group(rand_subset)];
                end
                
                % Sort the indices to maintain the original relative generation order
                keep_idx = sort(keep_idx);
                
                % Apply the final curated indices
                hard_ref = hard_ref(keep_idx);
                hard_is_zero_ref = hard_is_zero_ref(keep_idx);
                hard_comp_base = hard_comp_base(keep_idx);
                hard_comp_offset = hard_comp_offset(keep_idx);
                hard_comp_offset_rel = hard_comp_offset_rel(keep_idx);
                hard_comp_radius = hard_comp_radius(keep_idx);
                hard_comp_radius_rel = hard_comp_radius_rel(keep_idx);
                hard_comp_axis = hard_comp_axis(keep_idx);
                hard_comp_rad_idx = hard_comp_rad_idx(keep_idx);
                hard_comp_mult = hard_comp_mult(keep_idx);
                
                base_kept_h = length(keep_idx); % Ensures accuracy if the min() fail-safe triggered
            else

                base_kept_h = base_generated_h;
            end
            
            % Inject Random Trial Arrays
            if num_random_trials_h > 0
                rand_ref_idx = randi([1, num_refs_h], num_random_trials_h, 1);
                m_ref_rand = ref_vecs_h(rand_ref_idx, :);
                
                rand_r = rand_comp_lb_h + (rand_comp_ub_h - rand_comp_lb_h) * rand(num_random_trials_h, 1);
                rand_theta = 2 * pi * rand(num_random_trials_h, 1);
                [dx, dy] = pol2cart(rand_theta, rand_r);
                actual_rand_offsets = [dx, dy];
                
                if comp_rel_bool_h
                    ref_speeds_rand = sqrt(sum(m_ref_rand.^2, 2));
                    ref_speeds_rand(ref_speeds_rand == 0) = base_speed;
                    actual_rand_offsets_scaled = actual_rand_offsets .* ref_speeds_rand;
                else
                    actual_rand_offsets_scaled = actual_rand_offsets;
                end
                m_comp_rand = m_ref_rand + actual_rand_offsets_scaled;
                
                rand_ref_cell = mat2cell(m_ref_rand, ones(num_random_trials_h,1), 2);
                rand_is_zero_ref = (sqrt(sum(m_ref_rand.^2, 2)) < 1e-10);
                rand_comp_base_cell = mat2cell(m_comp_rand, ones(num_random_trials_h,1), 2);
                rand_comp_offset_cell = mat2cell(actual_rand_offsets_scaled, ones(num_random_trials_h,1), 2);
                rand_comp_offset_rel_cell = mat2cell(actual_rand_offsets, ones(num_random_trials_h,1), 2);
                
                rand_comp_radius = sqrt(sum(actual_rand_offsets_scaled.^2, 2));
                rand_comp_radius_rel = rand_r;
                rand_comp_axis = wrapTo360(rad2deg(atan2(actual_rand_offsets_scaled(:,2), actual_rand_offsets_scaled(:,1))));
                rand_comp_rad_idx = zeros(num_random_trials_h, 1); 
                rand_comp_mult = rand_r;
                
                hard_ref = [hard_ref; rand_ref_cell];
                hard_is_zero_ref = [hard_is_zero_ref; rand_is_zero_ref];
                hard_comp_base = [hard_comp_base; rand_comp_base_cell];
                hard_comp_offset = [hard_comp_offset; rand_comp_offset_cell];
                hard_comp_offset_rel = [hard_comp_offset_rel; rand_comp_offset_rel_cell];
                hard_comp_radius = [hard_comp_radius; rand_comp_radius];
                hard_comp_radius_rel = [hard_comp_radius_rel; rand_comp_radius_rel];
                hard_comp_axis = [hard_comp_axis; rand_comp_axis];
                hard_comp_rad_idx = [hard_comp_rad_idx; rand_comp_rad_idx];
                hard_comp_mult = [hard_comp_mult; rand_comp_mult];
            end

            %% ====================================================================
            %% SET 3: RANDOMIZE ZERO REFERENCES BY TRIAL
            %% ====================================================================
            nz = nonzero_rand;
            nz_options = [
                -nz,   0;
                 nz,   0;
                  0, -nz;
                  0,  nz;
                -nz, -nz;
                -nz,  nz;
                 nz, -nz;
                 nz,  nz
            ];

            % Standard trials zero-reference replacement
            for i = 1:length(std_ref)
                if std_is_zero_ref(i)
                    v_rand = nz_options(randi(8), :);
                    std_ref{i} = v_rand;
                    v_rand_speed = norm(v_rand);
                    
                    rel_offset = std_comp_offset_rel{i};
                    if comp_rel_bool
                        actual_offset = rel_offset .* v_rand_speed;
                    else
                        actual_offset = rel_offset;
                    end
                    
                    std_comp_base{i}       = v_rand + actual_offset;
                    std_comp_offset{i}     = actual_offset;
                    std_comp_radius(i)     = norm(actual_offset);
                    std_comp_axis(i)       = wrapTo360(rad2deg(atan2(actual_offset(2), actual_offset(1))));
                end
            end

            % Hard trials zero-reference replacement
            for i = 1:length(hard_ref)
                if hard_is_zero_ref(i)
                    v_rand = nz_options(randi(8), :);
                    hard_ref{i} = v_rand;
                    v_rand_speed = norm(v_rand);
                    
                    rel_offset = hard_comp_offset_rel{i};
                    if comp_rel_bool_h
                        actual_offset = rel_offset .* v_rand_speed;
                    else
                        actual_offset = rel_offset;
                    end
                    
                    hard_comp_base{i}       = v_rand + actual_offset;
                    hard_comp_offset{i}     = actual_offset;
                    hard_comp_radius(i)     = norm(actual_offset);
                    hard_comp_axis(i)       = wrapTo360(rad2deg(atan2(actual_offset(2), actual_offset(1))));
                end
            end

            %% ====================================================================
            %% SET 4: COMBINE STANDARD AND HARD SETS & GENERATE TABLE
            %% ====================================================================
            final_ref = [std_ref; hard_ref];
            final_comp_base = [std_comp_base; hard_comp_base];
            final_comp_offset = [std_comp_offset; hard_comp_offset];
            final_comp_offset_rel = [std_comp_offset_rel; hard_comp_offset_rel];
            final_comp_radius = [std_comp_radius; hard_comp_radius];
            final_comp_radius_rel = [std_comp_radius_rel; hard_comp_radius_rel];
            final_comp_axis = [std_comp_axis; hard_comp_axis];
            final_comp_rad_idx = [std_comp_rad_idx; hard_comp_rad_idx];
            final_comp_mult = [std_comp_mult; hard_comp_mult];
            
            % Boolean vector indicating if the trial is from the hard condition
            is_hard_trial = [zeros(length(std_ref), 1); ones(length(hard_ref), 1)];

            total_trials = length(final_ref);
            
            t = ArumeCore.TrialTableBuilder();
            t.AddConditionVariable('RefCompPair', (1:total_trials));
            
            % Generate Table - Arume will shuffle everything uniformly
            trialTable = t.GenerateTrialTable('Random', 'Sequential', 1, 'Delay');
            trialTable.OddballWindow = randi([1, 3], total_trials, 1);
            
            idx = trialTable.RefCompPair;
            
            trialTable.ReferenceVelocity = final_ref(idx);
            trialTable.ComparisonVelocity = final_comp_base(idx);
            trialTable.CompOffsetVector = final_comp_offset(idx);
            trialTable.CompOffsetVectorRel = final_comp_offset_rel(idx);
            trialTable.CompOffsetRadius = final_comp_radius(idx);
            trialTable.CompOffsetRadiusRel = final_comp_radius_rel(idx);
            trialTable.CompOffsetAxis   = final_comp_axis(idx);
            trialTable.CompOffsetRadiusIndex = final_comp_rad_idx(idx);
            trialTable.CompOffsetMultiplier = final_comp_mult(idx);
            trialTable.IsHardTrial = is_hard_trial(idx);
        
            %% Apply Pseudo-Random Jitter
            comp_vels = trialTable.ComparisonVelocity;
            if do_jitter
                for i = 1:height(trialTable)
                    v_base = comp_vels{i};
                    speed = norm(v_base);
                    if speed == 0, speed = 0.1; end
                    
                    jx = (2*rand() - 1) * jitter_mult * speed;
                    jy = (2*rand() - 1) * jitter_mult * speed;
                    comp_vels{i} = v_base + [jx, jy];
                end
            end
            trialTable.ComparisonVelocity = comp_vels; 
            
            %% Final Window Assignment
            trialTable.Window1_Velocity = trialTable.ReferenceVelocity;
            trialTable.Window2_Velocity = trialTable.ReferenceVelocity;
            trialTable.Window3_Velocity = trialTable.ReferenceVelocity;
            
            trialTable.Window1_Velocity(trialTable.OddballWindow == 1) = comp_vels(trialTable.OddballWindow == 1);
            trialTable.Window2_Velocity(trialTable.OddballWindow == 2) = comp_vels(trialTable.OddballWindow == 2);
            trialTable.Window3_Velocity(trialTable.OddballWindow == 3) = comp_vels(trialTable.OddballWindow == 3);
            
            %% Set the physical positions of the three apertures
            trials_per_block = this.ExperimentOptions.TrialsBeforeBreak;
            num_blocks = floor(total_trials / trials_per_block) + 1;
            
            angle_set = 125 + linspace(0, 110, num_blocks);
            angle_set = angle_set(randperm(num_blocks));
            
            block_idx = floor((0:(total_trials-1)) / trials_per_block) + 1;
            trialTable.BlockNumber = block_idx';
            trialTable.BlockSequenceNumber = block_idx';
            
            trialTable.Window1_Angle = angle_set(block_idx)';
            trialTable.Window2_Angle = wrapTo360(trialTable.Window1_Angle - 120);
            trialTable.Window3_Angle = wrapTo360(trialTable.Window1_Angle - 240);
            
            %% --- Print Experiment Summary ---

            fprintf('\n============================================================\n');
            fprintf('           STANDARD STIMULUS CONFIGURATION SUMMARY                 \n');
            fprintf('============================================================\n');
            if strcmpi(ref_mode, 'cartesian')
                fprintf('REFERENCE VECTORS: [CARTESIAN GRID]\n');
                fprintf('  - Grid Axis Steps:   [%s] deg/s\n', num2str(ref_ax, '%.4f '));
                fprintf('  - Frame Bounds:      %.4f to %.4f deg/s (Magnitude)\n', lb_ref, ub_ref);
            else
                fprintf('REFERENCE VECTORS: [POLAR WHEEL]\n');
                fprintf('  - Reference Radii:   [%s] deg/s\n', num2str(radii, '%.4f '));
                fprintf('  - Number of Spokes:  %d\n', num_ref_spokes);
            end
            fprintf('  - Total Unique Refs: %d\n', num_refs);
            fprintf('------------------------------------------------------------\n');
            if comp_rel_bool
                comp_type_str = 'RELATIVE (%% of ref speed)';
            else
                comp_type_str = 'ABSOLUTE (deg/s)';
            end

            if strcmpi(comp_mode, 'cartesian')
                fprintf('COMPARISON VECTORS: [CARTESIAN LOCAL GRID]\n');
                fprintf('  - Offset Type:       %s\n', comp_type_str);
                fprintf('  - Grid Axis Steps:   [%s]\n', num2str(comp_ax, '%.2f '));
                if exist('comp_ax_ext', 'var')
                    fprintf('  - Grid Axis Steps for Refs w/ Speeds Lower than %s: %s\n',  num2str(low_speed, '%.2f '), num2str(comp_ax_ext, '%.2f '));
                end
                fprintf('  - Local Bounds:      %.2f to %.2f (Magnitude)\n', comp_lb, comp_ub);
            else
                fprintf('COMPARISON VECTORS: [POLAR LOCAL SPOKES]\n');
                fprintf('  - Offset Type:       %s\n', comp_type_str);
                fprintf('  - Comparison Radii:  [%s]\n', num2str(comp_radii, '%.2f '));
                fprintf('  - Comparison Axes:   %d\n', comp_axes);
            end
            fprintf('  - Total Unique Comps: %d (per reference)\n', num_comps_r);

            fprintf('\n============================================================\n');
            fprintf('          HARD STIMULUS CONFIGURATION SUMMARY                 \n');
            fprintf('============================================================\n');
            if strcmpi(ref_mode, 'cartesian')
                fprintf('REFERENCE VECTORS: [CARTESIAN GRID]\n');
                fprintf('  - Grid Axis Steps:   [%s] deg/s\n', num2str(ref_ax_h, '%.4f '));
                fprintf('  - Frame Bounds:      %.4f to %.4f deg/s (Magnitude)\n', lb_ref_h, ub_ref_h);
            else
                fprintf('REFERENCE VECTORS: [POLAR WHEEL]\n');
                fprintf('  - Reference Radii:   [%s] deg/s\n', num2str(radii, '%.4f '));
                fprintf('  - Number of Spokes:  %d\n', num_ref_spokes);
            end
            fprintf('  - Total Unique Refs: %d\n', num_refs_h);
            fprintf('------------------------------------------------------------\n');

            if comp_rel_bool
                comp_type_str = 'RELATIVE (%% of ref speed)';
            else
                comp_type_str = 'ABSOLUTE (deg/s)';
            end

            if strcmpi(comp_mode, 'cartesian')
                fprintf('COMPARISON VECTORS: [CARTESIAN LOCAL GRID]\n');
                fprintf('  - Offset Type:       %s\n', comp_type_str);
                fprintf('  - Grid Axis Steps:   [%s]\n', num2str(comp_ax_h, '%.4f '));
                fprintf('  - Local Bounds:      %.4f to %.4f (Magnitude)\n', comp_lb_h, comp_ub_h);
            else
                fprintf('COMPARISON VECTORS: [POLAR LOCAL SPOKES]\n');
                fprintf('  - Offset Type:       %s\n', comp_type_str);
                fprintf('  - Comparison Radii:  [%s]\n', num2str(comp_radii, '%.4f '));
                fprintf('  - Comparison Axes:   %d\n', comp_axes);
            end
            fprintf('  - Total Unique Comps: %d (per reference)\n', num_comps_h);

            if ~isempty(target_base_trials_h) && target_base_trials_h < base_generated_h
                fprintf('  - Culled Base Trials:  %d (randomly kept)\n', base_kept_h);
            end
            if num_random_trials_h > 0
                fprintf('------------------------------------------------------------\n');
                fprintf('  - EXTRA INJECTIONS:    %d Random Offset Trials\n', num_random_trials_h);
                fprintf('  - Random Offset Range: %.4f to %.4f\n', rand_comp_lb_h, rand_comp_ub_h);
            end


            fprintf('\n============================================================\n');
            fprintf('           STIMULUS CONFIGURATION SUMMARY (MIXED)         \n');
            fprintf('============================================================\n');
            fprintf('  - Standard N Trials:   %d\n', length(std_ref));
            fprintf('  - Hard N Trials:       %d\n', length(hard_ref));
            fprintf('------------------------------------------------------------\n');
            fprintf('  - Total N Trials:      %d\n', height(trialTable));
            fprintf('============================================================\n\n');
        end


        % function trialTable = SetUpTrialTable(this)
        %     %% 1. Parameter Extraction
        %     lb_ref      = this.ExperimentOptions.lb_screen;
        %     if isempty(lb_ref), lb_ref = 0; end
        %     ub_ref      = this.ExperimentOptions.ub_screen;
        %     num_ref_pts = this.ExperimentOptions.num_ref_gridpts;
        %     ref_mode    = this.ExperimentOptions.ref_cart_or_polar;
        %     ref_log_or_lin = this.ExperimentOptions.ref_log_or_lin;
        % 
        %     comp_lb        = this.ExperimentOptions.comp_lb;
        %     if isempty(comp_lb), comp_lb = 0; end
        %     comp_ub        = this.ExperimentOptions.comp_ub;
        %     comp_intervals = this.ExperimentOptions.comp_num_intervals;
        %     comp_axes      = this.ExperimentOptions.comp_num_axes;
        %     comp_mode      = this.ExperimentOptions.comp_cart_or_polar;
        %     comp_rel_bool  = this.ExperimentOptions.comp_rel_bool; 
        % 
        %     % --- Optional Arrays and Injectors ---
        %     custom_comp_intervals = [];
        %     if isprop(this.ExperimentOptions, 'comp_intervals_list') || isfield(this.ExperimentOptions, 'comp_intervals_list')
        %         custom_comp_intervals = this.ExperimentOptions.comp_intervals_list;
        %     end
        % 
        %     % --- Base Trial Target Downsampler ---
        %     target_base_trials = [];
        %     if isprop(this.ExperimentOptions, 'target_base_trials') || isfield(this.ExperimentOptions, 'target_base_trials')
        %         target_base_trials = this.ExperimentOptions.target_base_trials;
        %     end
        % 
        %     num_random_trials = 0;
        %     if isprop(this.ExperimentOptions, 'num_random_trials') || isfield(this.ExperimentOptions, 'num_random_trials')
        %         num_random_trials = this.ExperimentOptions.num_random_trials;
        %         if isempty(num_random_trials), num_random_trials = 0; end
        %     end
        % 
        %     rand_comp_lb = comp_lb;
        %     if isprop(this.ExperimentOptions, 'rand_comp_lb') || isfield(this.ExperimentOptions, 'rand_comp_lb')
        %         if ~isempty(this.ExperimentOptions.rand_comp_lb), rand_comp_lb = this.ExperimentOptions.rand_comp_lb; end
        %     end
        % 
        %     rand_comp_ub = comp_ub; 
        %     if isprop(this.ExperimentOptions, 'rand_comp_ub') || isfield(this.ExperimentOptions, 'rand_comp_ub')
        %         if ~isempty(this.ExperimentOptions.rand_comp_ub), rand_comp_ub = this.ExperimentOptions.rand_comp_ub; end
        %     end
        % 
        %     do_jitter   = this.ExperimentOptions.Do_Jitter;
        %     jitter_mult = this.ExperimentOptions.Jitter_Multiplier;
        %     num_repeats = this.ExperimentOptions.Num_Repeats_Per_Combo;
        % 
        %     %% 2. Seed RNG 
        %     rng(keyHash(this.Session.subjectCode)/10^10)
        % 
        %     %% 3. Generate Global Reference Vectors
        %     if strcmpi(ref_mode, 'cartesian')
        %         ref_ax = linspace(-ub_ref, ub_ref, num_ref_pts);
        %         [rvx, rvy] = meshgrid(ref_ax, ref_ax);
        %         base_refs = [rvx(:), rvy(:)];
        %         ref_vecs = base_refs;
        %     else
        %         num_ref_spokes = this.ExperimentOptions.num_ref_spokes;
        %         angles = linspace(0, 2*pi, num_ref_spokes + 1);
        %         angles(end) = []; 
        %         if strcmpi(ref_log_or_lin, 'log')
        %             radii = logspace(log10(lb_ref), log10(ub_ref), max(1, num_ref_pts));
        %         else
        %             radii = linspace(lb_ref, ub_ref, max(1, num_ref_pts));
        %         end
        %         [A, R] = meshgrid(angles, radii);
        %         [vx, vy] = pol2cart(A(:), R(:));
        %         ref_vecs = [vx, vy];
        %     end
        % 
        %     if ~any(sqrt(sum(ref_vecs.^2, 2)) < 1e-10)
        %         ref_vecs = [0, 0; ref_vecs];
        %     end
        %     num_refs = size(ref_vecs, 1);
        % 
        %     %% 4. Generate Local Comparison Offsets (dx, dy)
        %     if strcmpi(comp_mode, 'cartesian')
        %         if ~isempty(custom_comp_intervals)
        %             comp_ax = custom_comp_intervals;
        %         else
        %             comp_ax = linspace(-comp_ub, comp_ub, comp_intervals);
        %         end
        %         [cvx, cvy] = meshgrid(comp_ax, comp_ax);
        %         base_comps = [cvx(:), cvy(:)];
        %         c_mags = sqrt(sum(base_comps.^2, 2));
        % 
        %         valid_idx = c_mags >= comp_lb & c_mags <= comp_ub;
        %         comp_offsets = base_comps(valid_idx, :);
        %         comp_offset_multipliers = c_mags(valid_idx);
        %         [~, ~, comp_offset_radius_idx] = unique(round(c_mags(valid_idx), 4));
        %     else
        %         comp_angles = linspace(0, 2*pi, comp_axes + 1);
        %         comp_angles(end) = [];
        % 
        %         if ~isempty(custom_comp_intervals)
        %             comp_radii = custom_comp_intervals;
        %             actual_intervals = length(custom_comp_intervals);
        %         else
        %             comp_radii = linspace(comp_lb, comp_ub, comp_intervals);
        %             actual_intervals = comp_intervals;
        %         end
        % 
        %         radius_indices = 1:actual_intervals;
        %         [cA, cR] = meshgrid(comp_angles, comp_radii);
        %         [~, cR_idx] = meshgrid(comp_angles, radius_indices);
        %         [cvx, cvy] = pol2cart(cA(:), cR(:));
        %         comp_offsets = [cvx, cvy];
        %         comp_offset_radius_idx = cR_idx(:);
        %         comp_offset_multipliers = cR(:);
        %     end
        % 
        %     %% 5. Combine and Build the Base Trial Arrays
        %     num_comps = size(comp_offsets, 1);
        %     trials_per_rep = num_refs * num_comps;
        % 
        %     final_ref = cell(trials_per_rep, 1);
        %     final_comp_base = cell(trials_per_rep, 1);
        %     final_comp_offset = cell(trials_per_rep, 1); 
        %     final_comp_offset_rel = cell(trials_per_rep, 1);
        %     final_comp_radius = zeros(trials_per_rep, 1); 
        %     final_comp_radius_rel = zeros(trials_per_rep, 1);
        %     final_comp_axis   = zeros(trials_per_rep, 1);
        %     final_comp_rad_idx = zeros(trials_per_rep, 1); 
        %     final_comp_mult   = zeros(trials_per_rep, 1);
        % 
        %     counter = 1;
        %     base_speed = 0.25;
        %     for r = 1:num_refs
        %         v_ref = ref_vecs(r, :);
        %         ref_speed = norm(v_ref);
        %         for c = 1:num_comps
        %             final_ref{counter} = v_ref;
        %             if comp_rel_bool
        %                 actual_offset = comp_offsets(c, :) .* ref_speed;
        %                 if ref_speed == 0
        %                     actual_offset = comp_offsets(c, :) .* base_speed;
        %                 end
        %             else
        %                 actual_offset = comp_offsets(c, :);
        %             end
        %             final_comp_base{counter} = v_ref + actual_offset;
        % 
        %             final_comp_offset{counter} = actual_offset;
        %             final_comp_offset_rel{counter} = comp_offsets(c, :);
        %             final_comp_radius(counter) = norm(actual_offset);
        %             final_comp_radius_rel(counter) = norm(comp_offsets(c, :));
        %             final_comp_axis(counter)   = wrapTo360(rad2deg(atan2(actual_offset(2), actual_offset(1))));
        %             final_comp_rad_idx(counter) = comp_offset_radius_idx(c);
        %             final_comp_mult(counter) = comp_offset_multipliers(c);
        %             counter = counter + 1;
        %         end
        %     end
        % 
        %     %% 5.1 Repeat and Downsample arrays manually
        %     % Duplicate variables to account for num_repeats directly
        %     final_ref = repmat(final_ref, num_repeats, 1);
        %     final_comp_base = repmat(final_comp_base, num_repeats, 1);
        %     final_comp_offset = repmat(final_comp_offset, num_repeats, 1);
        %     final_comp_offset_rel = repmat(final_comp_offset_rel, num_repeats, 1);
        %     final_comp_radius = repmat(final_comp_radius, num_repeats, 1);
        %     final_comp_radius_rel = repmat(final_comp_radius_rel, num_repeats, 1);
        %     final_comp_axis = repmat(final_comp_axis, num_repeats, 1);
        %     final_comp_rad_idx = repmat(final_comp_rad_idx, num_repeats, 1);
        %     final_comp_mult = repmat(final_comp_mult, num_repeats, 1);
        % 
        %     base_generated = length(final_ref);
        % 
        %     % Randomly cull base variables if target exists
        %     if ~isempty(target_base_trials) && target_base_trials < base_generated
        %         keep_idx = randperm(base_generated, target_base_trials);
        % 
        %         final_ref = final_ref(keep_idx);
        %         final_comp_base = final_comp_base(keep_idx);
        %         final_comp_offset = final_comp_offset(keep_idx);
        %         final_comp_offset_rel = final_comp_offset_rel(keep_idx);
        %         final_comp_radius = final_comp_radius(keep_idx);
        %         final_comp_radius_rel = final_comp_radius_rel(keep_idx);
        %         final_comp_axis = final_comp_axis(keep_idx);
        %         final_comp_rad_idx = final_comp_rad_idx(keep_idx);
        %         final_comp_mult = final_comp_mult(keep_idx);
        % 
        %         base_kept = target_base_trials;
        %     else
        %         base_kept = base_generated;
        %     end
        % 
        %     %% 5.2 Inject Random Trial Arrays
        %     if num_random_trials > 0
        %         rand_ref_idx = randi([1, num_refs], num_random_trials, 1);
        %         m_ref_rand = ref_vecs(rand_ref_idx, :);
        % 
        %         rand_r = rand_comp_lb + (rand_comp_ub - rand_comp_lb) * rand(num_random_trials, 1);
        %         rand_theta = 2 * pi * rand(num_random_trials, 1);
        %         [dx, dy] = pol2cart(rand_theta, rand_r);
        %         actual_rand_offsets = [dx, dy];
        % 
        %         if comp_rel_bool
        %             ref_speeds_rand = sqrt(sum(m_ref_rand.^2, 2));
        %             ref_speeds_rand(ref_speeds_rand == 0) = base_speed;
        %             actual_rand_offsets_scaled = actual_rand_offsets .* ref_speeds_rand;
        %         else
        %             actual_rand_offsets_scaled = actual_rand_offsets;
        %         end
        %         m_comp_rand = m_ref_rand + actual_rand_offsets_scaled;
        % 
        %         % Convert to matching cell arrays and vectors
        %         rand_ref_cell = mat2cell(m_ref_rand, ones(num_random_trials,1), 2);
        %         rand_comp_base_cell = mat2cell(m_comp_rand, ones(num_random_trials,1), 2);
        %         rand_comp_offset_cell = mat2cell(actual_rand_offsets_scaled, ones(num_random_trials,1), 2);
        %         rand_comp_offset_rel_cell = mat2cell(actual_rand_offsets, ones(num_random_trials,1), 2);
        % 
        %         rand_comp_radius = sqrt(sum(actual_rand_offsets_scaled.^2, 2));
        %         rand_comp_radius_rel = rand_r;
        %         rand_comp_axis = wrapTo360(rad2deg(atan2(actual_rand_offsets_scaled(:,2), actual_rand_offsets_scaled(:,1))));
        %         rand_comp_rad_idx = zeros(num_random_trials, 1); 
        %         rand_comp_mult = rand_r;
        % 
        %         % Vertically concatenate directly to the downsampled base arrays
        %         final_ref = [final_ref; rand_ref_cell];
        %         final_comp_base = [final_comp_base; rand_comp_base_cell];
        %         final_comp_offset = [final_comp_offset; rand_comp_offset_cell];
        %         final_comp_offset_rel = [final_comp_offset_rel; rand_comp_offset_rel_cell];
        %         final_comp_radius = [final_comp_radius; rand_comp_radius];
        %         final_comp_radius_rel = [final_comp_radius_rel; rand_comp_radius_rel];
        %         final_comp_axis = [final_comp_axis; rand_comp_axis];
        %         final_comp_rad_idx = [final_comp_rad_idx; rand_comp_rad_idx];
        %         final_comp_mult = [final_comp_mult; rand_comp_mult];
        %     end
        % 
        %     %% 5.3 Generate Arume Table ONCE
        %     total_trials = length(final_ref);
        % 
        %     t = ArumeCore.TrialTableBuilder();
        %     t.AddConditionVariable('RefCompPair', (1:total_trials));
        % 
        %     % Because we handled num_repeats manually, tell Arume to do exactly 1 sequence
        %     trialTable = t.GenerateTrialTable('Random', 'Sequential', 1, 'Delay');
        % 
        %     trialTable.OddballWindow = randi([1, 3], total_trials, 1);
        % 
        %     % The variable idx is a shuffled index of (1 to total_trials)
        %     idx = trialTable.RefCompPair;
        % 
        %     trialTable.ReferenceVelocity = final_ref(idx);
        %     trialTable.ComparisonVelocity = final_comp_base(idx);
        %     trialTable.CompOffsetVector = final_comp_offset(idx);
        %     trialTable.CompOffsetVectorRel = final_comp_offset_rel(idx);
        %     trialTable.CompOffsetRadius = final_comp_radius(idx);
        %     trialTable.CompOffsetRadiusRel = final_comp_radius_rel(idx);
        %     trialTable.CompOffsetAxis   = final_comp_axis(idx);
        %     trialTable.CompOffsetRadiusIndex = final_comp_rad_idx(idx);
        %     trialTable.CompOffsetMultiplier = final_comp_mult(idx);
        % 
        %     %% 6. Apply Pseudo-Random Jitter
        %     comp_vels = trialTable.ComparisonVelocity;
        %     if do_jitter
        %         for i = 1:height(trialTable)
        %             v_base = comp_vels{i};
        %             speed = norm(v_base);
        %             if speed == 0, speed = 0.1; end
        % 
        %             jx = (2*rand() - 1) * jitter_mult * speed;
        %             jy = (2*rand() - 1) * jitter_mult * speed;
        %             comp_vels{i} = v_base + [jx, jy];
        %         end
        %     end
        %     trialTable.ComparisonVelocity = comp_vels; 
        % 
        %     %% 7. Final Window Assignment
        %     trialTable.Window1_Velocity = trialTable.ReferenceVelocity;
        %     trialTable.Window2_Velocity = trialTable.ReferenceVelocity;
        %     trialTable.Window3_Velocity = trialTable.ReferenceVelocity;
        % 
        %     trialTable.Window1_Velocity(trialTable.OddballWindow == 1) = comp_vels(trialTable.OddballWindow == 1);
        %     trialTable.Window2_Velocity(trialTable.OddballWindow == 2) = comp_vels(trialTable.OddballWindow == 2);
        %     trialTable.Window3_Velocity(trialTable.OddballWindow == 3) = comp_vels(trialTable.OddballWindow == 3);
        % 
        %     %% 8. Set the physical positions of the three apertures
        %     trials_per_block = this.ExperimentOptions.TrialsBeforeBreak;
        %     num_blocks = floor(total_trials / trials_per_block) + 1;
        % 
        %     angle_set = 125 + linspace(0, 110, num_blocks);
        %     angle_set = angle_set(randperm(num_blocks));
        % 
        %     block_idx = floor((0:(total_trials-1)) / trials_per_block) + 1;
        %     trialTable.BlockNumber = block_idx';
        %     trialTable.BlockSequenceNumber = block_idx';
        % 
        %     trialTable.Window1_Angle = angle_set(block_idx)';
        %     trialTable.Window2_Angle = wrapTo360(trialTable.Window1_Angle - 120);
        %     trialTable.Window3_Angle = wrapTo360(trialTable.Window1_Angle - 240);
        % 
        % 
        %     %% --- Print Experiment Summary ---
        %     fprintf('\n============================================================\n');
        %     fprintf('           STIMULUS CONFIGURATION SUMMARY                 \n');
        %     fprintf('============================================================\n');
        %     if strcmpi(ref_mode, 'cartesian')
        %         fprintf('REFERENCE VECTORS: [CARTESIAN GRID]\n');
        %         fprintf('  - Grid Axis Steps:   [%s] deg/s\n', num2str(ref_ax, '%.4f '));
        %         fprintf('  - Frame Bounds:      %.4f to %.4f deg/s (Magnitude)\n', lb_ref, ub_ref);
        %     else
        %         fprintf('REFERENCE VECTORS: [POLAR WHEEL]\n');
        %         fprintf('  - Reference Radii:   [%s] deg/s\n', num2str(radii, '%.4f '));
        %         fprintf('  - Number of Spokes:  %d\n', num_ref_spokes);
        %     end
        %     fprintf('  - Total Unique Refs: %d\n', num_refs);
        %     fprintf('------------------------------------------------------------\n');
        % 
        %     if comp_rel_bool
        %         comp_type_str = 'RELATIVE (%% of ref speed)';
        %     else
        %         comp_type_str = 'ABSOLUTE (deg/s)';
        %     end
        % 
        %     if strcmpi(comp_mode, 'cartesian')
        %         fprintf('COMPARISON VECTORS: [CARTESIAN LOCAL GRID]\n');
        %         fprintf('  - Offset Type:       %s\n', comp_type_str);
        %         fprintf('  - Grid Axis Steps:   [%s]\n', num2str(comp_ax, '%.4f '));
        %         fprintf('  - Local Bounds:      %.4f to %.4f (Magnitude)\n', comp_lb, comp_ub);
        %     else
        %         fprintf('COMPARISON VECTORS: [POLAR LOCAL SPOKES]\n');
        %         fprintf('  - Offset Type:       %s\n', comp_type_str);
        %         fprintf('  - Comparison Radii:  [%s]\n', num2str(comp_radii, '%.4f '));
        %         fprintf('  - Comparison Axes:   %d\n', comp_axes);
        %     end
        %     fprintf('  - Total Unique Comps: %d (per reference)\n', num_comps);
        % 
        %     if ~isempty(target_base_trials) && target_base_trials < base_generated
        %         fprintf('  - Culled Base Trials:  %d (randomly kept)\n', base_kept);
        %     end
        %     if num_random_trials > 0
        %         fprintf('------------------------------------------------------------\n');
        %         fprintf('  - EXTRA INJECTIONS:    %d Random Offset Trials\n', num_random_trials);
        %         fprintf('  - Random Offset Range: %.4f to %.4f\n', rand_comp_lb, rand_comp_ub);
        %     end
        % 
        % 
        %     fprintf('------------------------------------------------------------\n');
        %     fprintf('  - Repetitions / Combo: %d\n', num_repeats);
        %     fprintf('  - Total N Trials:      %d\n', height(trialTable));
        %     fprintf('============================================================\n\n');
        % end

        % 
        % function trialTable = SetUpTrialTable(this)
        % 
        %     %% 1. Parameter Extraction
        %     % These variables define the "Global" space where our reference stimuli live.
        %     lb_ref      = this.ExperimentOptions.lb_screen;
        %     if isempty(lb_ref)
        %         lb_ref = 0;
        %     end
        %     ub_ref      = this.ExperimentOptions.ub_screen;
        %     num_ref_pts = this.ExperimentOptions.num_ref_gridpts;
        %     ref_mode    = this.ExperimentOptions.ref_cart_or_polar;
        %     ref_log_or_lin = this.ExperimentOptions.ref_log_or_lin;
        %     % These define the "Local" difference between the reference and the comparison.
        %     comp_lb        = this.ExperimentOptions.comp_lb;
        %     if isempty(comp_lb)
        %         comp_lb = 0;
        %     end
        %     comp_ub        = this.ExperimentOptions.comp_ub;
        %     comp_intervals = this.ExperimentOptions.comp_num_intervals;
        %     comp_axes      = this.ExperimentOptions.comp_num_axes;
        %     comp_mode      = this.ExperimentOptions.comp_cart_or_polar;
        %     comp_rel_bool  = this.ExperimentOptions.comp_rel_bool; % Toggle for relative vs absolute
        %     % Jitter adds small noise to the comparison to prevent grid-learning.
        %     do_jitter   = this.ExperimentOptions.Do_Jitter;
        %     jitter_mult = this.ExperimentOptions.Jitter_Multiplier;
        %     num_repeats = this.ExperimentOptions.Num_Repeats_Per_Combo;
        % 
        %     %% 2. Seed RNG for Pseudo-Randomization
        %     % Seeding with the subject code ensures that the trial table is unique to the
        %     % participant but reproducible if the same session is re-generated.
        %     rng(keyHash(this.Session.subjectCode)/10^10)
        % 
        %     %% 3. Generate Global Reference Vectors
        %     % This step creates the set of baseline motion vectors (x_ref).
        %     if strcmpi(ref_mode, 'cartesian')
        %         % Create a square grid and mask it to form a circular frame/ring.
        %         ref_ax = linspace(-ub_ref, ub_ref, num_ref_pts);
        %         [rvx, rvy] = meshgrid(ref_ax, ref_ax);
        %         base_refs = [rvx(:), rvy(:)];
        % 
        %         % MODIFIED TO MATCH PYTHON: use full grid instead of masking by magnitude
        %         % mags = sqrt(sum(base_refs.^2, 2));
        %         % ref_vecs = base_refs(mags >= lb_ref & mags <= ub_ref, :);
        %         ref_vecs = base_refs;
        %     else
        %         num_ref_spokes = this.ExperimentOptions.num_ref_spokes;
        %         % Create spokes of a wheel (Polar).
        %         angles = linspace(0, 2*pi, num_ref_spokes + 1);
        %         angles(end) = []; % Remove overlap
        %         if strcmpi(ref_log_or_lin, 'log')
        %             radii = logspace(log10(lb_ref), log10(ub_ref), max(1, num_ref_pts));
        %         else
        %             radii = linspace(lb_ref, ub_ref, max(1, num_ref_pts));
        %         end
        %         [A, R] = meshgrid(angles, radii);
        %         [vx, vy] = pol2cart(A(:), R(:));
        %         ref_vecs = [vx, vy];
        %     end
        % 
        %     %% 3.1 Force inclusion of [0,0] Reference
        %     % Check if a zero-velocity vector already exists (using a small epsilon)
        %     if ~any(sqrt(sum(ref_vecs.^2, 2)) < 1e-10)
        %         ref_vecs = [0, 0; ref_vecs];
        %         num_refs = size(ref_vecs, 1); % Update the count for later steps
        %     end
        % 
        %     %% 4. Generate Local Comparison Offsets (dx, dy)
        %     % Here we define the "delta" or the shape of the MOCS-like intervals.
        %     % If comp_rel_bool is true, these are treated as unit-less scaling factors.
        %     if strcmpi(comp_mode, 'cartesian')
        %         comp_ax = linspace(-comp_ub, comp_ub, comp_intervals);
        %         [cvx, cvy] = meshgrid(comp_ax, comp_ax);
        %         base_comps = [cvx(:), cvy(:)];
        %         c_mags = sqrt(sum(base_comps.^2, 2));
        %         % Filter offsets to stay within the local bounds
        %         valid_idx = c_mags >= comp_lb & c_mags <= comp_ub;
        %         comp_offsets = base_comps(valid_idx, :);
        %         comp_offset_multipliers = c_mags(valid_idx);
        %         % Map Cartesian magnitudes to an index (1 = smallest, N = largest)
        %         [~, ~, comp_offset_radius_idx] = unique(round(c_mags(valid_idx), 4));
        %     else
        %         % Circular spokes centered on the reference point
        %         comp_angles = linspace(0, 2*pi, comp_axes + 1);
        %         comp_angles(end) = [];
        %         comp_radii = linspace(comp_lb, comp_ub, comp_intervals);
        %         % Create a matching grid of indices (1 to comp_intervals)
        %         radius_indices = 1:comp_intervals;
        %         [cA, cR] = meshgrid(comp_angles, comp_radii);
        %         [~, cR_idx] = meshgrid(comp_angles, radius_indices);
        %         [cvx, cvy] = pol2cart(cA(:), cR(:));
        %         comp_offsets = [cvx, cvy];
        %         comp_offset_radius_idx = cR_idx(:); % Flattened index array
        %         comp_offset_multipliers = cR(:); % Flattened array
        %     end
        % 
        %     %% 5. Combine and Build the Trial Table
        %     % This is the cross-product of all references and all local offsets.
        %     num_refs = size(ref_vecs, 1);
        %     num_comps = size(comp_offsets, 1);
        %     trials_per_rep = num_refs * num_comps;
        %     final_ref = cell(trials_per_rep, 1);
        %     final_comp_base = cell(trials_per_rep, 1);
        % 
        %     % Pre-allocate metric tracking arrays
        %     final_comp_offset = cell(trials_per_rep, 1); % 1x2 vectors need cell arrays
        %     final_comp_offset_rel = cell(trials_per_rep, 1);
        %     final_comp_radius = zeros(trials_per_rep, 1); % Scalars can be standard numeric arrays
        %     final_comp_radius_rel = zeros(trials_per_rep, 1);
        %     final_comp_axis   = zeros(trials_per_rep, 1);
        %     final_comp_rad_idx = zeros(trials_per_rep, 1); % Index array for different levels
        %     final_comp_mult   = zeros(trials_per_rep, 1);
        % 
        %     counter = 1;
        %     % if 0,0
        %     base_speed = 0.25;
        %     for r = 1:num_refs
        %         v_ref = ref_vecs(r, :);
        %         ref_speed = norm(v_ref);
        %         for c = 1:num_comps
        %             final_ref{counter} = v_ref;
        %             % Determine the actual offset being added
        %             if comp_rel_bool
        %                 % offset_percentage * speed_ref
        %                 actual_offset = comp_offsets(c, :) .* ref_speed;
        %                 if ref_speed == 0
        %                     actual_offset = comp_offsets(c, :) .* base_speed;
        %                     % MODIFIED TO MATCH PYTHON: removed stray 2;
        %                 end
        %             else
        %                 % offset_absolute
        %                 actual_offset = comp_offsets(c, :);
        %             end
        %             final_comp_base{counter} = v_ref + actual_offset;
        % 
        %             % Record the metrics
        %             final_comp_offset{counter} = actual_offset;
        %             final_comp_offset_rel{counter} = comp_offsets(c, :);
        %             final_comp_radius(counter) = norm(actual_offset);
        %             final_comp_radius_rel(counter) = norm(comp_offsets(c, :));
        % 
        %             % Calculate angle using atan2, convert to degrees, and wrap 0-360
        %             final_comp_axis(counter)   = wrapTo360(rad2deg(atan2(actual_offset(2), actual_offset(1))));
        % 
        %             % Record the discrete MOCS radius index
        %             final_comp_rad_idx(counter) = comp_offset_radius_idx(c);
        %             final_comp_mult(counter) = comp_offset_multipliers(c);
        %             counter = counter + 1;
        %         end
        %     end
        % 
        %     % Use Arume's TrialTableBuilder to handle shuffling and repeats.
        %     t = ArumeCore.TrialTableBuilder();
        %     t.AddConditionVariable('RefCompPair', (1:trials_per_rep));
        %     trialTable = t.GenerateTrialTable('Random', 'Sequential', num_repeats, 'Delay');
        % 
        %     % Randomly assign 1, 2, or 3 to each trial
        %     trialTable.OddballWindow = randi([1, 3], height(trialTable), 1);
        % 
        %     % Map the generated IDs back to the actual velocity pairs.
        %     idx = trialTable.RefCompPair;
        %     trialTable.ReferenceVelocity = final_ref(idx);
        %     comp_vels = final_comp_base(idx);
        % 
        %     % Map the offset metrics to the trial table
        %     trialTable.CompOffsetVector = final_comp_offset(idx);
        %     trialTable.CompOffsetVectorRel = final_comp_offset_rel(idx);
        %     trialTable.CompOffsetRadius = final_comp_radius(idx);
        %     trialTable.CompOffsetRadiusRel = final_comp_radius_rel(idx);
        %     trialTable.CompOffsetAxis   = final_comp_axis(idx);
        %     trialTable.CompOffsetRadiusIndex = final_comp_rad_idx(idx);
        %     trialTable.CompOffsetMultiplier = final_comp_mult(idx);
        % 
        %     %% 6. Apply Pseudo-Random Jitter
        %     % We apply jitter after expanding the table so every repeat is slightly unique.
        %     if do_jitter
        %         for i = 1:height(trialTable)
        %             v_base = comp_vels{i};
        %             speed = norm(v_base);
        %             % Small floor for speed to ensure 0-velocity points can still jitter.
        %             if speed == 0, speed = 0.1; end
        %             % The jitter is a random (x,y) shift proportional to the vector's speed.
        %             jx = (2*rand() - 1) * jitter_mult * speed;
        %             jy = (2*rand() - 1) * jitter_mult * speed;
        %             comp_vels{i} = v_base + [jx, jy];
        %         end
        %     end
        % 
        %     % MODIFIED TO MATCH PYTHON: removed the "(idx)" at the end.
        %     % comp_vels was already indexed at line 147, indexing it again shuffles it wrongly.
        %     trialTable.ComparisonVelocity = comp_vels;
        % 
        %     %% 7. Final Window Assignment
        %     % Initialize all apertures with the reference velocity.
        %     trialTable.Window1_Velocity = trialTable.ReferenceVelocity;
        %     trialTable.Window2_Velocity = trialTable.ReferenceVelocity;
        %     trialTable.Window3_Velocity = trialTable.ReferenceVelocity;
        % 
        %     % The 'Oddball' window is the only one that gets the comparison velocity.
        %     trialTable.Window1_Velocity(trialTable.OddballWindow == 1) = comp_vels(trialTable.OddballWindow == 1);
        %     trialTable.Window2_Velocity(trialTable.OddballWindow == 2) = comp_vels(trialTable.OddballWindow == 2);
        %     trialTable.Window3_Velocity(trialTable.OddballWindow == 3) = comp_vels(trialTable.OddballWindow == 3);
        % 
        %     %% 8.
        %     %  Set the physical positions of the three apertures on the display.
        %     % trialTable.Window1_Angle = 125 + 110 * rand(height(trialTable), 1);
        %     % trialTable.Window2_Angle = wrapTo360(trialTable.Window1_Angle - 120);
        %     % trialTable.Window3_Angle = wrapTo360(trialTable.Window1_Angle - 240);
        % 
        %     % Determine the number of unique rotation blocks
        %     total_trials = height(trialTable);
        %     trials_per_block = this.ExperimentOptions.TrialsBeforeBreak;
        %     num_blocks = floor(total_trials / trials_per_block) + 1;
        % 
        %     % Generate evenly spaced offsets across 0 to 110, add the 125 base, and shuffle
        %     angle_set = 125 + linspace(0, 110, num_blocks);
        %     angle_set = angle_set(randperm(num_blocks));
        % 
        %     % Map each trial sequentially to its corresponding block index
        %     block_idx = floor((0:(total_trials-1)) / trials_per_block) + 1;
        % 
        %     % Change the blocknumber and session columns manually to match
        %     trialTable.BlockNumber = block_idx';
        %     trialTable.BlockSequenceNumber = block_idx';
        % 
        % 
        %     % Assign the angles
        %     trialTable.Window1_Angle = angle_set(block_idx)';
        %     trialTable.Window2_Angle = wrapTo360(trialTable.Window1_Angle - 120);
        %     trialTable.Window3_Angle = wrapTo360(trialTable.Window1_Angle - 240);
        % 
        % 
        %     %% --- Print Experiment Summary ---
        %     % MODIFIED TO MATCH PYTHON: Formatted exactly like the python version
        %     fprintf('\n============================================================\n');
        %     fprintf('           STIMULUS CONFIGURATION SUMMARY                 \n');
        %     fprintf('============================================================\n');
        % 
        %     if strcmpi(ref_mode, 'cartesian')
        %         fprintf('REFERENCE VECTORS: [CARTESIAN GRID]\n');
        %         fprintf('  - Grid Axis Steps:   [%s] deg/s\n', num2str(ref_ax, '%.2f '));
        %         fprintf('  - Frame Bounds:      %.2f to %.2f deg/s (Magnitude)\n', lb_ref, ub_ref);
        %     else
        %         fprintf('REFERENCE VECTORS: [POLAR WHEEL]\n');
        %         fprintf('  - Reference Radii:   [%s] deg/s\n', num2str(radii, '%.2f '));
        %         fprintf('  - Number of Spokes:  %d\n', num_ref_spokes);
        %     end
        % 
        %     fprintf('  - Total Unique Refs: %d\n', num_refs);
        %     fprintf('------------------------------------------------------------\n');
        % 
        %     if comp_rel_bool
        %         comp_type_str = 'RELATIVE (%% of ref speed)';
        %     else
        %         comp_type_str = 'ABSOLUTE (deg/s)';
        %     end
        % 
        %     if strcmpi(comp_mode, 'cartesian')
        %         fprintf('COMPARISON VECTORS: [CARTESIAN LOCAL GRID]\n');
        %         fprintf('  - Offset Type:       %s\n', comp_type_str);
        %         fprintf('  - Grid Axis Steps:   [%s]\n', num2str(comp_ax, '%.2f '));
        %         fprintf('  - Local Bounds:      %.2f to %.2f (Magnitude)\n', comp_lb, comp_ub);
        %     else
        %         fprintf('COMPARISON VECTORS: [POLAR LOCAL SPOKES]\n');
        %         fprintf('  - Offset Type:       %s\n', comp_type_str);
        %         fprintf('  - Comparison Radii:  [%s]\n', num2str(comp_radii, '%.2f '));
        %         fprintf('  - Comparison Axes:   %d\n', comp_axes);
        %     end
        % 
        %     fprintf('  - Total Unique Comps: %d (per reference)\n', num_comps);
        %     fprintf('------------------------------------------------------------\n');
        %     fprintf('  - Repetitions / Combo: %d\n', num_repeats);
        %     fprintf('  - Total N Trials:      %d\n', height(trialTable));
        %     fprintf('============================================================\n\n');
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
        function [trialResult, thisTrialData] = runPreTrial(this, thisTrialData)
            %thisTrialData
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
            % for w = 1:3
            %     angle_rad = deg2rad(this.ExperimentOptions.window_angles(thisTrialData.TrialNumber, w));
            %     window_centers(w, 1) = this.ExperimentOptions.DisplayOptions.screenCenterX + this.ExperimentOptions.window_eccentricity * cos(angle_rad);
            %     window_centers(w, 2) = this.ExperimentOptions.DisplayOptions.screenCenterY - this.ExperimentOptions.window_eccentricity * sin(angle_rad);  % negative because Y increases downward
            % end

            % get the window_centers for this trial specifically
            angle_rad1 = deg2rad(thisTrialData.Window1_Angle);
            window_centers(1, 1) = this.ExperimentOptions.DisplayOptions.screenCenterX + this.ExperimentOptions.window_eccentricity * cos(angle_rad1);
            window_centers(1, 2) = this.ExperimentOptions.DisplayOptions.screenCenterY - this.ExperimentOptions.window_eccentricity * sin(angle_rad1);  % negative because Y increases downward
            
            angle_rad2 = deg2rad(thisTrialData.Window2_Angle);
            window_centers(2, 1) = this.ExperimentOptions.DisplayOptions.screenCenterX + this.ExperimentOptions.window_eccentricity * cos(angle_rad2);
            window_centers(2, 2) = this.ExperimentOptions.DisplayOptions.screenCenterY - this.ExperimentOptions.window_eccentricity * sin(angle_rad2);  % negative because Y increases downward

            angle_rad3 = deg2rad(thisTrialData.Window3_Angle);
            window_centers(3, 1) = this.ExperimentOptions.DisplayOptions.screenCenterX + this.ExperimentOptions.window_eccentricity * cos(angle_rad3);
            window_centers(3, 2) = this.ExperimentOptions.DisplayOptions.screenCenterY - this.ExperimentOptions.window_eccentricity * sin(angle_rad3);  % negative because Y increases downward



            %% Assign the parameters to the different windows
            all_dots_colour = this.ExperimentOptions.DisplayOptions.grey_col;

            % Window 1 dot parameters - this structure keeps the functionality for simultaneous motion
            % QQ: Change all to thisTrialData, which is just the current
            % row
            window1_vec1 = thisTrialData.Window1_Velocity{1}*this.ExperimentOptions.DisplayOptions.degS_to_pixFrame_convFactor(1);   % Movement vector for first half of dots
            window1_vec2 = window1_vec1;    % Movement vector for second half of dots
            window1_colour1 = all_dots_colour;
            window1_colour2 = window1_colour1;

            % Window 2 dot parameters
            window2_vec1 = thisTrialData.Window2_Velocity{1}*this.ExperimentOptions.DisplayOptions.degS_to_pixFrame_convFactor(1);  %this.ExperimentOptions.DisplayOptions.degS_to_pixFrame_convFactor(1)*this.TrialTable.Window2_Velocity{thisTrialData.TrialNumber, :};
            window2_vec2 = window2_vec1;
            window2_colour1 = all_dots_colour;
            window2_colour2 = window2_colour1;

            % Window 3 dot parameters
            window3_vec1 = thisTrialData.Window3_Velocity{1}*this.ExperimentOptions.DisplayOptions.degS_to_pixFrame_convFactor(1);
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


        end


        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )

            try

                % CHeck the this.Session.currentRun.pastTrialTable last
                % row; if last one soft-abrted, make a pause screen
                % spacebar next 

                %% Fixation Configuration
                fixation_type = this.ExperimentOptions.Fixation_Type;
                fixation_size = this.ExperimentOptions.Fixation_Size_Deg;
                fixation_color = this.ExperimentOptions.Fixation_Color;
                fixation_line_width = this.ExperimentOptions.Fixation_Line_Width;

                screenCenterX = this.ExperimentOptions.DisplayOptions.screenCenterX;
                screenCenterY = this.ExperimentOptions.DisplayOptions.screenCenterY;

                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;



                if (~isempty(this.Session.currentRun.pastTrialTable) && this.Session.currentRun.pastTrialTable(end, :).TrialResult == 'SOFTABORT')

                    % Flush any previous key presses
                    KbReleaseWait;

                    waitingForKey = true;

                    while waitingForKey

                        % --- Draw your break text ---
                        Screen('TextSize', graph.window, 40);
                        breakText = ['Make sure you are fixating on the dot for the entire trial!\n\nPress space to continue']; % <-- replace later
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



                if this.ExperimentOptions.UseEyeTracker
                    nframesctr = 1;

                    [framenumber, eyetrackertime] = this.eyeTracker.RecordEvent( ...
                        sprintf('STIMULUS_ONSET [,trial=%d condition=%d]', ...
                        thisTrialData.TrialNumber, thisTrialData.Condition) );

                    % matches the frame number to the eyetracker time at the start of the trial
                    thisTrialData.EyeTrackerFrameNumberStimulusOnset = framenumber;
                    thisTrialData.EyeTrackerTimeStimulusOnset = eyetrackertime;

                end

                

                lastFlipTime        = GetSecs;
                secondsRemaining    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;


                %this.ExperimentOptions.Initial_Fixation_Duration = 0.5;
                %this.ExperimentOptions.Motion_Duration = 1;


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
                        %fprintf('\n[0.2%f,0.2%f]', eyePos_FixationPeriod(1), eyePos_FixationPeriod(2));

                        % increment counter
                        N=N+1;

                        % initial fixation colour
                        fixation_color = [0.25 0.5 0.75]*255;
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

                        fixation_color = this.ExperimentOptions.Fixation_Color;

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
                            % Flush any previous key presses
                            %2KbReleaseWait;

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

                                fprintf(['\n\nTrial: %0.0f | %s | W_Vec1: [%0.1f, %0.1f]| W_Vec2: [%0.1f, %0.1f]| W_Vec3: [%0.' ...
                                    '1f, %0.1f] | Oddball: %0.0f | Reponse: %0.0f \n'], ...
                                    thisTrialData.TrialNumber, ...
                                    thisTrialData.TrialResult, ...
                                    thisTrialData.Window1_Velocity{1}(1), thisTrialData.Window1_Velocity{1}(2), ...
                                    thisTrialData.Window2_Velocity{1}(1), thisTrialData.Window2_Velocity{1}(2), ...
                                    thisTrialData.Window3_Velocity{1}(1), thisTrialData.Window3_Velocity{1}(2), ...
                                    thisTrialData.OddballWindow, ...
                                    thisTrialData.Response);


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

                    if ( secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration + max(cut_in, this.ExperimentOptions.Min_Motion_Duration_Before_Response) && ...
                            secondsElapsed < this.ExperimentOptions.Initial_Fixation_Duration +       ...
                            this.ExperimentOptions.Motion_Duration)

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

                            %% ADJUST WINSIZE_PIX HERE:
                            % % default = 1deg QQ
                            new_size_deg = 1.25;







                            
                            
                            %       
                            %this.ExperimentOptions.Fixation_Check_WinSize_pix = new_size_deg*this.ExperimentOptions.DisplayOptions.deg_to_pix_convFactor;
                            % % % % default = 0.5
                            % this.ExperimentOptions.Fixation_Check_TimeOut = 0.5;

                            this.checkFixation(eyePos_FixationPeriod, this.ExperimentOptions.Fixation_Check_WinSize_pix, this.ExperimentOptions.Fixation_Check_TimeOut);

                            %
                            % boolo = this.checkFixationClara(eyePos_FixationPeriod, this.ExperimentOptions.Fixation_Check_WinSize_pix, this.ExperimentOptions.Fixation_Check_TimeOut);
                            % if boolo

                            %     print('trial aborted from checkFixation')
                            % end
                            %
                            % this.checkFixation(fixRect([1 2]), this.ExperimentOptions.Fixation_Check_WinSize_pix, this.ExperimentOptions.Fixation_Check_TimeOut)
                        end



                    end
                    % -----------------------------------------------------------------
                    % --- Check Fixation  -----------------------------------
                    % -----------------------------------------------------------------
                end

                % ============================================================
                % --- Break screen every TrialsBeforeBreakSmall trials -----------------------------
                % ============================================================
                TrialsBeforeBreakSmall = this.ExperimentOptions.TrialsBeforeBreakSmall; % e.g., set this in options

                if mod(thisTrialData.TrialNumber, TrialsBeforeBreakSmall) == 0

                    % Flush any previous key presses
                    KbReleaseWait;

                    waitingForKey = true;

                    while waitingForKey

                        % --- Draw your break text ---
                        Screen('TextSize', graph.window, 40);
                        breakText = ['Blink blink! \n\nPress space to continue']; % <-- replace later
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

