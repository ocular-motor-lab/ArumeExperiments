classdef A1MotionEllipsesQuest < ArumeExperimentDesigns.EyeTracking
    % MIXED: MOCS trials (standard + hard sets, from A1MotionEllipses) and
    % QUEST staircase trials (from A1MotionEllipsesQuest) interleaved in one
    % session. QUEST staircases are saved exactly as in A1MotionEllipsesQuest
    % (<session>_QuestStaircases.mat, <session>_QuestReferences.png).
    % Every change relative to A1MotionEllipsesQuest is marked 'MIXED:';
    % 'QUEST:' comments are carried over from that file.
    % Motion Ellipses foveal threshold exp.
    %
    properties
        fixRad = 20;
        fixColor = [255 0 0];


        lots_dots1
        lots_dots2
        lots_dots3


        gazedata

        % QUEST: one QUEST struct per staircase (created in initBeforeRunning,
        % updated in runTrial after each response)
        questStates

        % QUEST SAVE: condition info per staircase (ref, comparison angle, ...),
        % built in initBeforeRunning and saved with the staircases
        questInfo
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
            % MIXED: 132 so every rep phase (1584 / 3 = 528 trials) is a whole number
            % of blocks (4); see the phase/block check in SetUpTrialTable.
            dlg.TrialsBeforeBreak = 132;
            %200; % big break; also controls how many trials in a row will have the same mickey-mouse orientation
            dlg.TrialsBeforeBreakSmall = 25; % small break
            dlg.TrialAbortAction = 'Delay';


            %% ====================================================================
            %% MIXED: MOCS options (unchanged from A1MotionEllipses)
            %% ====================================================================
           %% Reference Vector Options

           % STANDARD TRIALS -------------------------------------------------------
            % Global Ref Parameters
            dlg.lb_screen = { 0.5 '* (deg/s)' [0 300] };
            dlg.ub_screen = { 1.5 '* (deg/s)' [0 300] };
            dlg.num_ref_gridpts =  { 7 '*' [0 3000] };
            dlg.ref_cart_or_polar = { {'polar' '{cartesian}'} };
            dlg.num_ref_spokes = {8 '*' [1 3000] };
            dlg.ref_log_or_lin = { {'log' '{lin}'} };

            % Local Comp Parameters (The relative offsets)
            dlg.comp_lb = { 0 '* (x ref_vec speed)' [0 300] };
            dlg.comp_ub = { 0.8 '* (x ref_vec speed)' [0 300] };
            dlg.comp_num_intervals = { 6 '* ' [0 300] };
            dlg.comp_num_axes = { 8 '* ' [1 300] };
            dlg.comp_cart_or_polar = { {'polar' '{cartesian}'} };
            dlg.comp_rel_bool = { {'0','{1}'} };

            dlg.nonzero_rand = { 0.25 '* (x ref_vec speed)' [0 300]};
            dlg.low_speed = { 0 '* (x ref_vec speed)' [0 300]};
            dlg.outer_downsample_n = { 2 '* (x ref_vec speed)' [0 300]};

            % HARD TRIALS -------------------------------------------------------
            % Global Ref Parameters
            dlg.lb_screen_hard = { 0.5 '* (deg/s)' [0 300] };%0.5
            dlg.ub_screen_hard = { 1.5 '* (deg/s)' [0 300] };
            dlg.num_ref_gridpts_hard =  { 7 '*' [1 3000] };
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


            dlg.target_base_trials_hard = {200 '* ' [0 20000]};


            % random trials for easiness
            dlg.num_random_trials_hard = 0;%200;
            dlg.rand_comp_lb_hard = 0.05;%0.2

            dlg.rand_comp_ub_hard = 0.5;%0.8

            % MIXED: expected total (MOCS + QUEST); a warning is printed if the
            % options produce a different number. 0 = no check.
            dlg.Expected_Total_Trials = { 1584 '* (N, 0 = no check)' [0 100000] };

            %% ====================================================================
            %% QUEST Staircase Options (QUEST: new section; replaces the MOCS grid
            %% options commented out above)
            %% ====================================================================
            % QUEST: 1 = draw the reference vectors per participant (options below);
            % 0 = use Quest_Ref_Vx/Vy exactly as entered.
            dlg.Quest_Random_Refs = { {'0','{1}'} };
            % QUEST: random references (used when Quest_Random_Refs = 1). The speed range
            % and the direction range are each split into Quest_Ref_Num equal bins; each
            % reference gets one speed bin and one direction bin, paired at random, at a
            % random spot inside each bin (drawn from the participant ID hash).
            % Directions are 0-90 deg; turn on Quest_Random_Ref_Signs to spread them
            % (QUEST: component limits below can narrow the usable speeds and directions)
            % over all four quadrants.
            dlg.Quest_Ref_Num           = { 10 '* (N refs)' [1 100] };
            dlg.Quest_Ref_Speed_Min     = { 0.5 '* (deg/s)' [0 100] };
            dlg.Quest_Ref_Speed_Max     = { 10 '* (deg/s)' [0 100] };
            dlg.Quest_Ref_Speed_Spacing = { {'{Linear}','Log'} }; % equal-width bins in deg/s or in log10(deg/s)
            dlg.Quest_Ref_Dir_Min       = { 0 '* (deg)' [0 90] };
            dlg.Quest_Ref_Dir_Max       = { 90 '* (deg)' [0 90] };
            % QUEST: limits on each component, |Vx| and |Vy| (deg/s). Together with the
            % speed range this keeps refs inside the region you can test, e.g. speed max 10
            % with component max 7 allows [7 7] (speed 9.9) but not [0 10].
            % Directions are only drawn where both components fit at that speed.
            dlg.Quest_Ref_Comp_Min      = { 0.5 '* (deg/s, |Vx| and |Vy|)' [0 100] };
            dlg.Quest_Ref_Comp_Max      = { 7 '* (deg/s, |Vx| and |Vy|)' [0 100] };

            % Reference vectors (deg/s), paired element-wise (used when Quest_Random_Refs = 0):
            %   ref k = [Quest_Ref_Vx(k), Quest_Ref_Vy(k)]
            % A [0 0] ref is randomized per trial using nonzero_rand (as in the original).
            dlg.Quest_Ref_Vx = {[0.25  0.25 -2  -3   0 -2  -1  7]};
            dlg.Quest_Ref_Vy = {[0     1     0   1.5 3 -4  -6  -5 ]};
            % QUEST: 1 = treat Quest_Ref_Vx/Vy as absolute values and draw the sign of
            % every component from the participant ID hash (same subject -> same signs).
            % QUEST QUADRANTS: signs are chosen so the refs are spread as evenly as
            % possible over the 4 quadrants (random among the most even assignments).
            % 0 = use Quest_Ref_Vx/Vy exactly as entered.
            dlg.Quest_Random_Ref_Signs = { {'{1}','0'} }; 


            % QUEST: comparison angles come from one common pool of equi-spaced
            % absolute screen directions (deg). Pool size = (N refs) x Quest_Comp_Angles_Per_Ref,
            % rotated by Quest_Comp_Axis_Offset_Deg. The pool is shuffled with the
            % participant ID hash and dealt out, so each reference gets
            % Quest_Comp_Angles_Per_Ref different angles and every pool angle is used once.
            % Each (reference, angle) combo gets Quest_Reps_Per_Combo separate staircases.
            % dlg.Quest_Comp_Num_Axes        = { 8 '* (N)' [1 360] };  % QUEST: replaced by Quest_Comp_Angles
            % dlg.Quest_Comp_Angles          = {[0 90 180 270] '* deg'}; % QUEST: replaced by the equi-spaced pool below
            % QUEST FRAME: frame the pool angles are defined in.
            %   relative : angle is measured from the reference vector's direction
            %              (0 = along the ref -> speed change, 90 = perpendicular ->
            %              direction change). For [0 0] refs the per-trial randomized
            %              reference direction is used.
            %   absolute : angle is a fixed screen/stimulus-space direction (0 deg = +Vx)
            dlg.Quest_Comp_Axis_Frame      = { {'absolute', '{relative}'} };
            dlg.Quest_Comp_Angles_Per_Ref  = { 1 '* (N)' [1 360] };
            dlg.Quest_Reps_Per_Combo       = { 3 '* (N staircases per ref/angle combo)' [1 100] };
            dlg.Quest_Comp_Axis_Offset_Deg = { 0 '* (deg)' [0 360] };
            dlg.Quest_Trials_Per_Staircase = { 20 '* (N)' [1 1000] };

            % QUEST LINEAR: the experiment works in LINEAR relative offset
            %   intensity = |comp - ref| / |ref|   (x ref speed)
            % Psychtoolbox QUEST works internally in log10 units, so values are
            % converted (questToLog / questFromLog) only when calling Quest* functions.
            % tGuess is given linearly; the prior SD, grain and range are QUEST's
            % internal (log10) quantities and stay in log10 units.
            dlg.Quest_tGuessRel  = { 0.2 '* (rel offset, x ref speed)' [0.0001 10] }; % prior guess: 20% of ref speed
            dlg.Quest_tGuessSd   = { 2 '* (log10 units, QUEST prior SD)' [0.01 10] };  % wide prior
            dlg.Quest_pThreshold = { 0.6667 '* (prop correct)' [0.34 0.99] }; % midway between 3AFC chance (1/3) and 1
            dlg.Quest_beta       = { 3.5 '*' [0.1 20] }; % default 3.5
            dlg.Quest_delta      = { 0.02 '* (lapse rate)' [0 0.5] };
            dlg.Quest_gamma      = { 0.3333 '* (chance, 3AFC oddity)' [0 1] };
            dlg.Quest_grain      = { 0.01 '* (log10 units, QUEST internal)' [0.0001 1] };
            dlg.Quest_range      = { 5 '* (log10 units, QUEST internal)' [0.1 20] };

            % Hard limits on the relative offset actually shown (QUEST suggestions are clamped)
            dlg.Quest_Min_Rel_Offset = { 0.005 '* (x ref_vec speed)' [0.0001 10] };
            dlg.Quest_Max_Rel_Offset = { 1 '* (x ref_vec speed)' [0.0001 10] };

            % Jitter Parameters
            dlg.Do_Jitter = { {'0','{1}'} }; % Boolean toggle (MOCS and QUEST)
            dlg.Jitter_Multiplier = { 0.05 '* (x comp_vec speed)' [0 300] }; % MIXED: MOCS trials (as in A1MotionEllipses)
            dlg.Quest_Jitter_Multiplier = { 0.0 '* (x comp_vec speed)' [0 300] }; % MIXED: QUEST trials (0 = shown offset equals the QUEST intensity)

            dlg.Num_Repeats_Per_Combo = {1  '* ' [0 300]}; % MIXED: MOCS repeats (QUEST trial counts come from the staircases)

            dlg.EyeTrackerCalibProportion = {[.30,.30],'Calibration Area (width, height)',[0.05,1],1};

            dlg.ClaraDebug = { {'1','{0}'} };

        end

        % =====================================================================
        % QUEST: NEW SetUpTrialTable.
        % Replaces the fixed MOCS grid (standard + hard sets) with interleaved
        % QUEST staircases: one staircase per (reference vector x comparison
        % axis), all defined in GetOptionsDialog. The table only fixes WHICH
        % staircase each trial belongs to (plus ref, axis, oddball window and
        % aperture angles). The offset magnitude is chosen adaptively in
        % runPreTrial, and the staircase is updated with the response in runTrial.
        % The original SetUpTrialTable is kept below, fully commented out.
        % =====================================================================
        function trialTable = SetUpTrialTable(this)
        %% 1. Universal Parameter Extraction & Seed RNG
            rand_seed = this.Session.subjectCode;
            rng(keyHash(rand_seed)/10^10)

            % MIXED: MOCS trials are generated first (A1MotionEllipses code, unchanged
            % apart from MOCS-only names), then the QUEST staircase trials; both lists
            % are combined into one table further down. Both use the same seeded rng.

            % (unchanged) nonzero_rand is still used to randomize [0 0] references
            nonzero_rand = 0.05;
            if isprop(this.ExperimentOptions, 'nonzero_rand') || isfield(this.ExperimentOptions, 'nonzero_rand')
                if ~isempty(this.ExperimentOptions.nonzero_rand)
                    nonzero_rand = this.ExperimentOptions.nonzero_rand;
                end
            end

            %% ####################################################################
            %% MIXED: MOCS TRIALS (A1MotionEllipses SET 1-3, unchanged)
            %% ####################################################################
            num_repeats = this.ExperimentOptions.Num_Repeats_Per_Combo;
            do_jitter   = this.ExperimentOptions.Do_Jitter;
            jitter_mult = this.ExperimentOptions.Jitter_Multiplier;
            base_speed  = 0.25;

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

            %% MIXED: collect the MOCS trials (standard then hard) into mocs_* arrays
            mocs_ref            = [std_ref; hard_ref];
            mocs_comp_base      = [std_comp_base; hard_comp_base];
            mocs_comp_offset    = [std_comp_offset; hard_comp_offset];
            mocs_comp_offset_rel = [std_comp_offset_rel; hard_comp_offset_rel];
            mocs_comp_radius    = [std_comp_radius; hard_comp_radius];
            mocs_comp_radius_rel = [std_comp_radius_rel; hard_comp_radius_rel];
            mocs_comp_axis      = [std_comp_axis; hard_comp_axis];
            mocs_comp_rad_idx   = [std_comp_rad_idx; hard_comp_rad_idx];
            mocs_comp_mult      = [std_comp_mult; hard_comp_mult];
            mocs_is_hard        = [zeros(length(std_ref), 1); ones(length(hard_ref), 1)];
            nM = length(mocs_ref);
            n_std_mocs = length(std_ref);
            n_hard_mocs = length(hard_ref);

            % MIXED: MOCS jitter (same formula as A1MotionEllipses, applied per MOCS trial)
            mocs_comp_vel = mocs_comp_base;
            if do_jitter
                for i = 1:nM
                    v_base = mocs_comp_vel{i};
                    speed = norm(v_base);
                    if speed == 0, speed = 0.1; end
                    jx = (2*rand() - 1) * jitter_mult * speed;
                    jy = (2*rand() - 1) * jitter_mult * speed;
                    mocs_comp_vel{i} = v_base + [jx, jy];
                end
            end
            % MIXED: unit vector of each MOCS offset ([NaN NaN] for a zero offset)
            mocs_dir = cell(nM, 1);
            for i = 1:nM
                o = mocs_comp_offset{i};
                if norm(o) > 1e-12, mocs_dir{i} = o / norm(o); else, mocs_dir{i} = [NaN NaN]; end
            end

            % MIXED: MOCS summary printed here, before the QUEST code reuses names
            % such as ref_vecs and num_refs
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



            %% ####################################################################
            %% MIXED: QUEST STAIRCASE TRIALS (A1MotionEllipsesQuest)
            %% ####################################################################
            %% ====================================================================
            %% QUEST: REFERENCE VECTORS AND COMPARISON AXES (from GetOptionsDialog)
            %% ====================================================================
            if this.ExperimentOptions.Quest_Random_Refs
                % QUEST: random reference vectors for this participant.
                % Stratified draw: the speed range and the direction range are each split
                % into num_refs equal bins. randperm gives every reference a different bin
                % (independently for speed and direction, so the pairing is random), and
                % rand puts it at a random spot inside its bin. Speed bins are equal in
                % deg/s ('Linear') or in log10(deg/s) ('Log').
                % Own random stream (seed offset +3; signs use +1, angles +2), so the
                % references depend only on the participant and the other draws are unaffected.
                num_refs = this.ExperimentOptions.Quest_Ref_Num;
                s_min = this.ExperimentOptions.Quest_Ref_Speed_Min;
                s_max = this.ExperimentOptions.Quest_Ref_Speed_Max;
                d_min = this.ExperimentOptions.Quest_Ref_Dir_Min;
                d_max = this.ExperimentOptions.Quest_Ref_Dir_Max;
                c_min = this.ExperimentOptions.Quest_Ref_Comp_Min; % QUEST: per-component limits
                c_max = this.ExperimentOptions.Quest_Ref_Comp_Max;
                use_log = strcmpi(char(this.ExperimentOptions.Quest_Ref_Speed_Spacing), 'Log');
                if s_max < s_min || d_max < d_min || c_max < c_min
                    error('A1MotionEllipsesMixed:RefRange', ...
                        'Quest_Ref_Speed_Max/Dir_Max/Comp_Max must be >= Quest_Ref_Speed_Min/Dir_Min/Comp_Min.');
                end
                if use_log && s_min <= 0
                    error('A1MotionEllipsesMixed:RefRange', ...
                        'Log speed spacing needs Quest_Ref_Speed_Min > 0.');
                end

                ref_stream = RandStream('mt19937ar', 'Seed', ...
                    mod(floor(keyHash(this.Session.subjectCode)/10^10) + 3, 2^32));
                u_speed = (randperm(ref_stream, num_refs) - rand(ref_stream, 1, num_refs)) / num_refs; % one per bin, in (0,1)
                u_dir   = (randperm(ref_stream, num_refs) - rand(ref_stream, 1, num_refs)) / num_refs;

                % QUEST: directions (0-90 deg) that keep both components in [c_min, c_max]
                % at speed s, intersected with [d_min, d_max]:
                %   Vx = s*cos(d):  d >= acosd(c_max/s)  and  d <= acosd(c_min/s)
                %   Vy = s*sin(d):  d >= asind(c_min/s)  and  d <= asind(c_max/s)
                % (ratios above 1 are capped at 1; a speed is usable when dir_lo <= dir_hi)
                dir_lo = @(s) max(max(d_min, acosd(min(c_max ./ s, 1))), asind(min(c_min ./ s, 1)));
                dir_hi = @(s) min(min(d_max, acosd(min(c_min ./ s, 1))), asind(min(c_max ./ s, 1)));

                % QUEST: usable speed range = the speeds in [s_min, s_max] that have at least
                % one valid direction (always one continuous range), found on a fine grid
                if use_log
                    s_grid = logspace(log10(s_min), log10(s_max), 20001);
                else
                    s_grid = linspace(s_min, s_max, 20001);
                end
                usable = s_grid(dir_lo(s_grid) <= dir_hi(s_grid));
                if isempty(usable)
                    error('A1MotionEllipsesMixed:RefRange', ...
                        'No reference vector satisfies the speed, direction and component limits together.');
                end
                s_lo = min(usable);
                s_hi = max(usable);

                % Speeds: one per bin over the usable range (QUEST: was [s_min, s_max])
                if use_log
                    ref_speeds = 10.^(log10(s_lo) + u_speed * (log10(s_hi) - log10(s_lo)));
                else
                    ref_speeds = s_lo + u_speed * (s_hi - s_lo);
                end
                % Directions: one per bin, as a position within the valid directions at
                % that speed (QUEST: was a position within [d_min, d_max])
                d_lo = dir_lo(ref_speeds);
                d_hi = dir_hi(ref_speeds);
                ref_dirs = d_lo + u_dir .* (d_hi - d_lo);
                ref_vecs = [ref_speeds(:) .* cosd(ref_dirs(:)), ref_speeds(:) .* sind(ref_dirs(:))];

                % QUEST: final check that every limit holds (tolerance for rounding only)
                tol = 1e-9;
                ref_speed_chk = sqrt(sum(ref_vecs.^2, 2));
                % (QUEST FIX: speeds are N x 1 and components 2N x 1, so check each separately)
                if any(ref_speed_chk > s_max + tol) || any(ref_speed_chk < s_min - tol) || ...
                        any(ref_vecs(:) > c_max + tol) || any(ref_vecs(:) < c_min - tol)
                    error('A1MotionEllipsesMixed:RefRange', 'A reference vector violates the speed or component limits.');
                end
            else
                % Reference k is [Quest_Ref_Vx(k), Quest_Ref_Vy(k)] in deg/s
                ref_vx = this.ExperimentOptions.Quest_Ref_Vx(:);
                ref_vy = this.ExperimentOptions.Quest_Ref_Vy(:);
                if numel(ref_vx) ~= numel(ref_vy)
                    error('A1MotionEllipsesMixed:RefVectors', ...
                        'Quest_Ref_Vx (%d values) and Quest_Ref_Vy (%d values) must be the same length.', ...
                        numel(ref_vx), numel(ref_vy));
                end
                ref_vecs = [ref_vx, ref_vy];
            end
            num_refs = size(ref_vecs, 1);

            % QUEST: optional random signs. The entered values are used as absolute
            % values and each component's sign is drawn from the participant ID hash.
            % A separate random stream is used, so the signs depend only on the
            % participant and the rest of the random draws below are unaffected.
            if this.ExperimentOptions.Quest_Random_Ref_Signs
                sign_stream = RandStream('mt19937ar', 'Seed', ...
                    mod(floor(keyHash(this.Session.subjectCode)/10^10) + 1, 2^32));
                % QUEST QUADRANTS: balanced instead of independent coin flips
                ref_signs = balancedRefSigns(abs(ref_vecs), sign_stream);
                ref_vecs  = abs(ref_vecs) .* ref_signs;
            end

            % QUEST: common pool of equi-spaced comparison angles (absolute screen
            % angle, deg), one per (reference x angle slot), rotated by
            % Quest_Comp_Axis_Offset_Deg. e.g. 6 refs x 1 angle each -> 6 angles, 60 deg apart.
            angles_per_ref = this.ExperimentOptions.Quest_Comp_Angles_Per_Ref;
            num_reps       = this.ExperimentOptions.Quest_Reps_Per_Combo;
            num_axes       = num_refs * angles_per_ref;   % pool size
            axis_angles = linspace(0, 360, num_axes + 1);
            axis_angles(end) = [];
            axis_angles = wrapTo360(axis_angles + this.ExperimentOptions.Quest_Comp_Axis_Offset_Deg);

            % QUEST: shuffle the pool with the participant ID hash and deal it out:
            % row r of ref_axis_idx = the pool indices assigned to reference r.
            % Uses its own random stream (seed offset +2; the sign stream uses +1),
            % so it is the same for a given participant and does not shift the
            % other random draws.
            angle_stream = RandStream('mt19937ar', 'Seed', ... % QUEST FIX: 1st argument is the generator type
                mod(floor(keyHash(rand_seed)/10^10) + 2, 2^32));
            pool_order   = randperm(angle_stream, num_axes);
            ref_axis_idx = reshape(pool_order, num_refs, angles_per_ref);

            trials_per_sc = this.ExperimentOptions.Quest_Trials_Per_Staircase;

            %% QUEST: one staircase per (reference, assigned angle, repetition)
            [rep_grid, slot_grid, ref_grid] = ndgrid(1:num_reps, 1:angles_per_ref, 1:num_refs);
            sc_ref_idx  = ref_grid(:);
            sc_rep_idx  = rep_grid(:);
            sc_axis_idx = ref_axis_idx(sub2ind(size(ref_axis_idx), sc_ref_idx, slot_grid(:)));
            sc_axis_idx = sc_axis_idx(:);
            num_sc      = numel(sc_ref_idx);

            %% QUEST: expand staircases into trials (Quest_Trials_Per_Staircase each)
            trial_sc       = repelem((1:num_sc)', trials_per_sc, 1);
            total_trials   = numel(trial_sc);
            trial_ref_idx  = sc_ref_idx(trial_sc);
            trial_axis_idx = sc_axis_idx(trial_sc);
            trial_rep_idx  = sc_rep_idx(trial_sc); % QUEST: which repetition of the ref/angle combo
            trial_axis_deg = reshape(axis_angles(trial_axis_idx), [], 1);

            final_ref         = mat2cell(ref_vecs(trial_ref_idx, :), ones(total_trials, 1), 2);
            final_ref_nominal = final_ref; % QUEST: keeps the staircase's ref before zero-ref randomization
            % QUEST FRAME: final_dir (absolute offset direction) is built after the
            % zero-ref randomization below, because in the 'relative' frame it
            % depends on each trial's actual reference direction.
            axis_relative = strcmpi(char(this.ExperimentOptions.Quest_Comp_Axis_Frame), 'relative');

            %% ====================================================================
            %% SET 3 (kept): RANDOMIZE ZERO REFERENCES BY TRIAL
            %% ====================================================================
            % QUEST: same nz_options as the original. Only the reference is replaced
            % here; the comparison is built from it in runPreTrial (so the offset
            % scales with the randomized ref speed, as before).
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
            for i = 1:total_trials
                if norm(final_ref{i}) < 1e-10
                    final_ref{i} = nz_options(randi(8), :);
                end
            end

            %% QUEST FRAME: absolute offset direction for every trial
            % absolute frame: pool angle is the screen/stimulus-space angle.
            % relative frame: pool angle is added to this trial's reference direction.
            trial_abs_deg = trial_axis_deg;
            if axis_relative
                ref_dir_deg   = cellfun(@(v) atan2d(v(2), v(1)), final_ref);
                trial_abs_deg = wrapTo360(ref_dir_deg + trial_axis_deg);
            end
            final_dir = mat2cell([cosd(trial_abs_deg), sind(trial_abs_deg)], ones(total_trials, 1), 2);

            %% ====================================================================
            %% MIXED: COMBINE MOCS AND QUEST TRIALS INTO ONE TABLE
            %% ====================================================================
            % Combined list: entries 1..nM are MOCS trials, nM+1..nM+nQ QUEST trials.
            nQ = total_trials;              % (QUEST code above calls its count total_trials)
            N  = nM + nQ;
            is_quest = [false(nM, 1); true(nQ, 1)];

            % MIXED: rep phases. QUEST trials belong to the phase of their repetition
            % (all rep-1 staircases finish before rep 2 starts, as in the QUEST
            % version). MOCS trials are spread evenly over the phases, separately for
            % standard and hard trials, so every phase has the same mix.
            % One continuous label cycle over [standard; hard] keeps the phase totals
            % equal (to within 1); shuffling within each set keeps it random.
            num_phases = num_reps;
            mocs_phase = zeros(nM, 1);
            ord = [find(mocs_is_hard == 0); find(mocs_is_hard == 1)];
            lab = mod(0:nM - 1, num_phases)' + 1;
            n0  = sum(mocs_is_hard == 0);
            lab(1:n0)       = lab(randperm(n0));
            lab(n0 + 1:end) = lab(n0 + randperm(nM - n0));
            mocs_phase(ord) = lab;
            trial_phase = [mocs_phase; trial_rep_idx];

            % Generate Table - Arume shuffles everything uniformly; rows are then
            % stably re-sorted by phase, so within a phase MOCS and QUEST trials
            % (and all of that phase's staircases) stay randomly interleaved.
            t = ArumeCore.TrialTableBuilder();
            t.AddConditionVariable('RefCompPair', (1:N));
            trialTable = t.GenerateTrialTable('Random', 'Sequential', 1, 'Delay');
            [~, phase_order] = sort(trial_phase(trialTable.RefCompPair)); % sort is stable
            trialTable = trialTable(phase_order, :);

            trialTable.OddballWindow = randi([1, 3], N, 1);

            idx = trialTable.RefCompPair;
            isQ = is_quest(idx);
            iQ  = idx(isQ) - nM;    % index into the QUEST arrays
            iM  = idx(~isQ);        % index into the MOCS arrays
            mix = @(qv, mv) mixColumn(isQ, iQ, iM, qv, mv);

            trialTable.IsQuestTrial = double(isQ);          % MIXED: 1 = QUEST trial, 0 = MOCS trial
            trialTable.IsHardTrial  = mix(zeros(nQ, 1), mocs_is_hard); % MOCS hard set (0 for QUEST)
            trialTable.TrialPhase   = trial_phase(idx);

            % QUEST: staircase bookkeeping (NaN on MOCS rows)
            trialTable.QuestStaircaseID        = mix(trial_sc, nan(nM, 1));
            trialTable.QuestRefIndex           = mix(trial_ref_idx, nan(nM, 1));
            trialTable.QuestAxisIndex          = mix(trial_axis_idx, nan(nM, 1));
            trialTable.QuestRepIndex           = mix(trial_rep_idx, nan(nM, 1));
            trialTable.QuestNominalRefVelocity = mix(final_ref_nominal, mocs_ref);

            trialTable.ReferenceVelocity     = mix(final_ref, mocs_ref);
            trialTable.QuestCompAxisRelative = isQ & axis_relative;               % QUEST FRAME
            trialTable.CompAxisAngleDeg      = mix(trial_axis_deg, nan(nM, 1));   % QUEST FRAME: pool angle in its frame
            trialTable.CompOffsetAxis        = mix(trial_abs_deg, mocs_comp_axis); % absolute angle of the offset
            trialTable.CompOffsetDirection   = mix(final_dir, mocs_dir);          % absolute unit vector of the offset

            % MOCS rows: fixed comparison (as in A1MotionEllipses).
            % QUEST rows: placeholders, filled in per trial by runPreTrial.
            zero_cell = repmat({[0 0]}, nQ, 1);
            nan_q     = nan(nQ, 1);
            trialTable.ComparisonVelocity    = mix(final_ref, mocs_comp_vel);
            trialTable.CompOffsetVector      = mix(zero_cell, mocs_comp_offset);
            trialTable.CompOffsetVectorRel   = mix(zero_cell, mocs_comp_offset_rel);
            trialTable.CompOffsetRadius      = mix(nan_q, mocs_comp_radius);
            trialTable.CompOffsetRadiusRel   = mix(nan_q, mocs_comp_radius_rel);
            trialTable.CompOffsetRadiusIndex = mix(nan_q, mocs_comp_rad_idx);
            trialTable.CompOffsetMultiplier  = mix(nan_q, mocs_comp_mult);
            trialTable.QuestIntensityRel     = nan(N, 1); % QUEST LINEAR: relative offset shown (QUEST rows)
            trialTable.QuestIntensityLog10   = nan(N, 1); % QUEST LINEAR: same in QUEST's log10 units
            trialTable.IsCorrect             = nan(N, 1); % filled in by runTrial (all trials)

            %% Final Window Assignment
            % All windows start at the reference velocity. MOCS: the oddball window
            % gets the fixed (jittered) comparison now. QUEST: the oddball window is
            % overwritten with the adaptive comparison in runPreTrial.
            for w = 1:3
                wv  = trialTable.ReferenceVelocity;
                sel = ~isQ & trialTable.OddballWindow == w;
                wv(sel) = trialTable.ComparisonVelocity(sel);
                trialTable.(sprintf('Window%d_Velocity', w)) = wv;
            end

            %% Set the physical positions of the three apertures (unchanged)
            trials_per_block = this.ExperimentOptions.TrialsBeforeBreak;
            num_blocks = floor(N / trials_per_block) + 1;
            
            angle_set = 125 + linspace(0, 110, num_blocks);
            angle_set = angle_set(randperm(num_blocks));
            
            block_idx = floor((0:(N-1)) / trials_per_block) + 1;
            trialTable.BlockNumber = block_idx';
            trialTable.BlockSequenceNumber = block_idx';
            
            trialTable.Window1_Angle = angle_set(block_idx)';
            trialTable.Window2_Angle = wrapTo360(trialTable.Window1_Angle - 120);
            trialTable.Window3_Angle = wrapTo360(trialTable.Window1_Angle - 240);

            %% --- Print Experiment Summary --- (QUEST: rewritten for staircases)
            fprintf('\n============================================================\n');
            fprintf('           QUEST STAIRCASE CONFIGURATION SUMMARY            \n');
            fprintf('============================================================\n');
            fprintf('REFERENCE VECTORS (deg/s):\n');
            for r = 1:num_refs
                fprintf('  - Ref %2d: [%7.3f, %7.3f]  (speed %6.3f, dir %5.1f deg)\n', r, ref_vecs(r, 1), ref_vecs(r, 2), ...
                    norm(ref_vecs(r, :)), wrapTo360(atan2d(ref_vecs(r, 2), ref_vecs(r, 1)))); % QUEST: + speed/direction
            end
            if this.ExperimentOptions.Quest_Random_Refs % QUEST
                fprintf('  - Drawn from participant ID hash: %.3f-%.3f deg/s (%s spacing), %.1f-%.1f deg\n', ...
                    this.ExperimentOptions.Quest_Ref_Speed_Min, this.ExperimentOptions.Quest_Ref_Speed_Max, ...
                    char(this.ExperimentOptions.Quest_Ref_Speed_Spacing), ...
                    this.ExperimentOptions.Quest_Ref_Dir_Min, this.ExperimentOptions.Quest_Ref_Dir_Max);
                fprintf('  - Component limits: %.3f-%.3f deg/s; usable speed range: %.3f-%.3f deg/s\n', ...
                    c_min, c_max, s_lo, s_hi); % QUEST
            end
            fprintf('  - [0 0] refs randomized per trial to +/-%.3f deg/s\n', nonzero_rand);
            if this.ExperimentOptions.Quest_Random_Ref_Signs % QUEST
                fprintf('  - Signs drawn from participant ID hash (entered values used as |Vx|, |Vy|),\n');
                fprintf('    balanced across quadrants\n'); % QUEST QUADRANTS
            end
            fprintf('  - Quadrant spread Q1..Q4: [%s]  (on-axis refs count 1/2 to each side)\n', ...
                num2str(refQuadrantLoad(ref_vecs), '%g ')); % QUEST QUADRANTS
            fprintf('------------------------------------------------------------\n');
            fprintf('COMPARISON ANGLE POOL: %d  [%s] deg  (%s frame)\n', num_axes, num2str(axis_angles, '%.1f '), ...
                char(this.ExperimentOptions.Quest_Comp_Axis_Frame)); % QUEST FRAME
            for r = 1:num_refs % QUEST: per-reference assignment (from participant ID hash)
                fprintf('  - Ref %2d angles:    [%s] deg\n', r, num2str(axis_angles(ref_axis_idx(r, :)), '%.1f '));
            end
            fprintf('  - Offset Type:       RELATIVE (x ref speed), adaptive magnitude\n');
            fprintf('  - Allowed Range:     %.4f to %.4f (x ref speed)\n', ...
                this.ExperimentOptions.Quest_Min_Rel_Offset, this.ExperimentOptions.Quest_Max_Rel_Offset);
            fprintf('------------------------------------------------------------\n');
            fprintf('QUEST PARAMETERS (intensity = linear rel offset; QUEST runs in log10 internally):\n');
            fprintf('  - tGuess:            %.4f x ref speed (log10 %.3f), prior SD %.3f log10 units\n', ...
                this.ExperimentOptions.Quest_tGuessRel, log10(this.ExperimentOptions.Quest_tGuessRel), ...
                this.ExperimentOptions.Quest_tGuessSd); % QUEST LINEAR
            fprintf('  - pThreshold:        %.4f\n', this.ExperimentOptions.Quest_pThreshold);
            fprintf('  - beta/delta/gamma:  %.2f / %.3f / %.4f\n', this.ExperimentOptions.Quest_beta, ...
                this.ExperimentOptions.Quest_delta, this.ExperimentOptions.Quest_gamma);
            fprintf('------------------------------------------------------------\n');
            fprintf('  - N Staircases:        %d (%d refs x %d angles x %d reps)\n', num_sc, num_refs, angles_per_ref, num_reps); % QUEST
            fprintf('  - Trials / Staircase:  %d\n', trials_per_sc);
            fprintf('  - QUEST N Trials:      %d\n', nQ); % MIXED

            %% MIXED: overall summary
            phase_sizes = accumarray(trial_phase, 1)';
            fprintf('\n============================================================\n');
            fprintf('           MIXED SESSION SUMMARY (MOCS + QUEST)             \n');
            fprintf('============================================================\n');
            fprintf('  - MOCS standard:       %d\n', n_std_mocs);
            fprintf('  - MOCS hard:           %d\n', n_hard_mocs);
            fprintf('  - QUEST:               %d (%d staircases x %d trials)\n', nQ, num_sc, trials_per_sc);
            fprintf('  - Rep phases:          %d, sizes [%s] (MOCS spread evenly over phases)\n', ...
                num_phases, num2str(phase_sizes));
            fprintf('  - Total N Trials:      %d\n', height(trialTable));
            fprintf('============================================================\n\n');
            % QUEST: Arume moves aborted trials to the end of their block, so a phase
            % boundary must also be a block boundary or a delayed trial could cross phases.
            phase_ends = cumsum(phase_sizes);
            if any(mod(phase_ends(1:end-1), trials_per_block) ~= 0)
                warning('A1MotionEllipsesMixed:PhaseBlocks', ...
                    ['Rep phases (sizes %s) do not end on block boundaries (TrialsBeforeBreak = %d). ', ...
                     'An aborted trial near a phase boundary could be delayed into the next phase.'], ...
                    num2str(phase_sizes), trials_per_block);
            end
            expected_total = 0;
            if isprop(this.ExperimentOptions, 'Expected_Total_Trials') || isfield(this.ExperimentOptions, 'Expected_Total_Trials')
                expected_total = this.ExperimentOptions.Expected_Total_Trials;
            end
            if ~isempty(expected_total) && expected_total > 0 && height(trialTable) ~= expected_total
                warning('A1MotionEllipsesMixed:TotalTrials', ...
                    'The options give %d trials (MOCS %d + QUEST %d), not Expected_Total_Trials = %d.', ...
                    height(trialTable), nM, nQ, expected_total);
            end
        end

       
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

            % =================================================================
            % QUEST: create one QUEST staircase per (reference x axis), all with
            % the same prior. If this run is being resumed, replay the responses
            % already collected so every staircase picks up where it left off.
            % =================================================================
            opts = this.ExperimentOptions;
            q0 = QuestCreate(this.questToLog(opts.Quest_tGuessRel), ... % QUEST LINEAR
                opts.Quest_tGuessSd, opts.Quest_pThreshold, ...
                opts.Quest_beta, opts.Quest_delta, opts.Quest_gamma, opts.Quest_grain, opts.Quest_range);
            q0.normalizePdf = 1; % avoids underflow over many trials (recommended in QuestCreate help)
            num_sc = max(this.TrialTable.QuestStaircaseID);
            this.questStates = repmat(q0, num_sc, 1);

            try
                past = this.Session.currentRun.pastTrialTable;
                % QUEST LINEAR: replay in QUEST's log10 units. New tables store
                % QuestIntensityLog10; tables from the previous version stored
                % log10 values in QuestIntensity.
                if ~isempty(past) && all(ismember({'QuestStaircaseID', 'IsCorrect'}, past.Properties.VariableNames))
                    vn = past.Properties.VariableNames;
                    if ismember('QuestIntensityLog10', vn)
                        past_log = past.QuestIntensityLog10;
                    elseif ismember('QuestIntensityRel', vn)
                        past_log = this.questToLog(past.QuestIntensityRel);
                    elseif ismember('QuestIntensity', vn)
                        past_log = past.QuestIntensity; % previous version: already log10
                    else
                        past_log = nan(height(past), 1);
                    end
                    for i = 1:height(past)
                        if ~isnan(past_log(i)) && ~isnan(past.IsCorrect(i))
                            sc = past.QuestStaircaseID(i);
                            this.questStates(sc) = QuestUpdate(this.questStates(sc), past_log(i), past.IsCorrect(i));
                        end
                    end
                end
            catch ex
                warning('A1MotionEllipsesMixed:QuestReplay', ...
                    'Could not replay past trials into QUEST (%s). Staircases start from the prior.', ex.message);
            end

            % =================================================================
            % QUEST SAVE: condition info for each staircase (read from the trial
            % table), saved alongside the QUEST structs by saveQuestStaircases.
            % =================================================================
            tt = this.TrialTable;
            info = struct('StaircaseID', num2cell((1:num_sc)'));
            for k = 1:num_sc
                info(k).NumTrialsPlanned = opts.Quest_Trials_Per_Staircase;
                r = find(tt.QuestStaircaseID == k, 1);
                if isempty(r), continue; end
                v_ref = tt.QuestNominalRefVelocity{r};
                info(k).RefIndex          = tt.QuestRefIndex(r);
                info(k).RefVelocity       = v_ref;                      % nominal ref [vx vy] (deg/s)
                info(k).RefSpeed          = norm(v_ref);
                info(k).RefDirectionDeg   = wrapTo360(atan2d(v_ref(2), v_ref(1)));
                info(k).ZeroRefRandomized = norm(v_ref) < 1e-10;        % [0 0] refs are randomized per trial (nonzero_rand)
                info(k).AxisIndex         = tt.QuestAxisIndex(r);         % index into the angle pool
                info(k).RepIndex          = tt.QuestRepIndex(r);          % QUEST: repetition of this ref/angle combo
                % QUEST FRAME: the staircase is defined by the pool angle in its frame
                frame = char(opts.Quest_Comp_Axis_Frame);
                ax_deg = tt.CompAxisAngleDeg(r);
                info(k).CompAxisFrame     = frame;                        % 'absolute' | 'relative'
                info(k).CompAxisRelative  = strcmpi(frame, 'relative');
                info(k).CompAxisAngleDeg  = ax_deg;                       % pool angle in that frame
                info(k).CompAxisVector    = [cosd(ax_deg), sind(ax_deg)]; % unit vector in that frame
                % Absolute direction of the offset for the NOMINAL ref. Undefined
                % for a [0 0] ref in the relative frame (it changes per trial).
                if info(k).CompAxisRelative
                    if norm(v_ref) < 1e-10
                        abs_deg = NaN;
                    else
                        abs_deg = wrapTo360(atan2d(v_ref(2), v_ref(1)) + ax_deg);
                    end
                else
                    abs_deg = ax_deg;
                end
                info(k).CompAngleDeg      = abs_deg;                        % absolute screen angle of the offset
                info(k).CompDirection     = [cosd(abs_deg), sind(abs_deg)]; % absolute unit vector (NaN if undefined)
            end
            this.questInfo = info;
            

            % QUEST SAVE: write the file once now, so it exists (with the replayed
            % state if this is a resumed session) before the first response
            this.saveQuestStaircases(NaN);

            % QUEST PLOT: picture of the references and comparison axes, saved
            % at the start of the session (before the first trial)
            this.saveQuestReferencePlot();


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



            % MIXED: MOCS trials already have their comparison in the trial table;
            % only QUEST trials choose it here from their staircase.
            if thisTrialData.IsQuestTrial
                % =================================================================
                % QUEST: choose this trial's comparison from its staircase.
                % QUEST LINEAR: intensity = relative offset magnitude (linear,
                % x ref speed), applied along this trial's offset direction and scaled
                % by the reference speed. QUEST's suggestion (log10) is converted to
                % linear, clamped in linear units, and the shown value is kept in both.
                % (QuestQuantile is a posterior quantile, so it is the same point in
                % linear or log units.)
                % =================================================================
                opts = this.ExperimentOptions;
                sc = thisTrialData.QuestStaircaseID;
                rel_mag = this.questFromLog(QuestQuantile(this.questStates(sc)));
                rel_mag = min(max(rel_mag, opts.Quest_Min_Rel_Offset), opts.Quest_Max_Rel_Offset); % clamp (linear)

                v_ref = thisTrialData.ReferenceVelocity{1};
                ref_speed = norm(v_ref);
                if ref_speed < 1e-10, ref_speed = 0.25; end % original base_speed fallback (zero refs are normally already randomized)

                rel_offset    = rel_mag * thisTrialData.CompOffsetDirection{1};
                actual_offset = rel_offset .* ref_speed;
                v_comp        = v_ref + actual_offset;

                % QUEST: jitter moved here from SetUpTrialTable (same formula as the original)
                % MIXED: QUEST trials use Quest_Jitter_Multiplier (MOCS jitter is in SetUpTrialTable)
                if opts.Do_Jitter && opts.Quest_Jitter_Multiplier > 0
                    speed = norm(v_comp);
                    if speed == 0, speed = 0.1; end
                    jx = (2*rand() - 1) * opts.Quest_Jitter_Multiplier * speed;
                    jy = (2*rand() - 1) * opts.Quest_Jitter_Multiplier * speed;
                    v_comp = v_comp + [jx, jy];
                end

                % QUEST: record what was shown, and put the comparison in the oddball window
                thisTrialData.QuestIntensityRel    = rel_mag;                    % QUEST LINEAR
                thisTrialData.QuestIntensityLog10  = this.questToLog(rel_mag);   % value given to QuestUpdate
                thisTrialData.CompOffsetVector     = {actual_offset};
                thisTrialData.CompOffsetVectorRel  = {rel_offset};
                thisTrialData.CompOffsetRadius     = norm(actual_offset);
                thisTrialData.CompOffsetRadiusRel  = rel_mag;
                thisTrialData.CompOffsetMultiplier = rel_mag;
                thisTrialData.ComparisonVelocity   = {v_comp};
                thisTrialData.(sprintf('Window%d_Velocity', thisTrialData.OddballWindow)) = {v_comp};
                % ===================== END QUEST =================================
            end % MIXED: IsQuestTrial
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

                                % QUEST: score this response (MIXED: all trials) and, on QUEST
                                % trials only, update this trial's staircase
                                thisTrialData.IsCorrect = double(response == thisTrialData.OddballWindow);
                                if thisTrialData.IsQuestTrial % MIXED
                                    sc = thisTrialData.QuestStaircaseID;
                                    this.questStates(sc) = QuestUpdate(this.questStates(sc), ... % QUEST LINEAR: log10 for QUEST
                                        this.questToLog(thisTrialData.QuestIntensityRel), thisTrialData.IsCorrect);
                                    this.saveQuestStaircases(thisTrialData.TrialNumber); % QUEST SAVE: keep the staircase file current
                                end

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

        % =====================================================================
        % QUEST SAVE: write every QUEST staircase, with its condition info, to a
        % separate .mat file next to the session data (overwritten each time).
        % Called once in initBeforeRunning and after every QUEST update in runTrial,
        % so the file is always current even if the session is aborted.
        %
        % File contents:
        %   QuestStaircases  struct array, one element per staircase:
        %       StaircaseID, NumTrialsPlanned, RefIndex, RefVelocity, RefSpeed,
        %       RefDirectionDeg, ZeroRefRandomized, AxisIndex, RepIndex,
        %       CompAxisFrame, CompAxisRelative, CompAxisAngleDeg, CompAxisVector,
        %       CompAngleDeg, CompDirection (absolute, for the nominal ref),
        %       NumTrialsDone,
        %       IntensitiesRel   (linear rel offset shown, x ref speed),
        %       IntensitiesLog10 (same, QUEST's internal units), Responses,
        %       ThresholdLog10 (QuestMean), ThresholdSdLog10 (QuestSd),
        %       ThresholdRel (= 10^QuestMean, posterior median-like),
        %       ThresholdRelPostMean / ThresholdRelPostSd (posterior mean / SD
        %       computed in linear units),
        %       ThresholdOffsetSpeed, ThresholdOffsetVector,
        %       Quest (the full Psychtoolbox QUEST struct, log10 internally)
        %   QuestInfo        subject, last trial number, save time, intensity
        %                    definition, and all Quest_* / jitter / nonzero_rand options
        % =====================================================================
        function saveQuestStaircases(this, lastTrialNumber)
            try
                QuestStaircases = this.questInfo;
                for k = 1:numel(this.questStates)
                    q = this.questStates(k);
                    n = q.trialCount;
                    q.intensity = q.intensity(1:n); % drop QUEST's unused preallocated entries
                    q.response  = q.response(1:n);

                    QuestStaircases(k).NumTrialsDone    = n;
                    QuestStaircases(k).IntensitiesRel   = this.questFromLog(q.intensity); % QUEST LINEAR: rel offset shown
                    QuestStaircases(k).IntensitiesLog10 = q.intensity;  % QUEST's internal log10 values
                    QuestStaircases(k).Responses        = q.response;   % 1 = correct, 0 = incorrect
                    QuestStaircases(k).ThresholdLog10   = QuestMean(q);
                    QuestStaircases(k).ThresholdSdLog10 = QuestSd(q);
                    QuestStaircases(k).ThresholdRel     = this.questFromLog(QuestStaircases(k).ThresholdLog10); % x ref speed
                    [QuestStaircases(k).ThresholdRelPostMean, QuestStaircases(k).ThresholdRelPostSd] = ...
                        this.questLinearPosterior(q);  % QUEST LINEAR
                    if QuestStaircases(k).ZeroRefRandomized
                        % ref speed changes trial to trial, so no single deg/s threshold
                        QuestStaircases(k).ThresholdOffsetSpeed  = NaN;
                        QuestStaircases(k).ThresholdOffsetVector = [NaN NaN];
                    else
                        QuestStaircases(k).ThresholdOffsetSpeed  = QuestStaircases(k).ThresholdRel * QuestStaircases(k).RefSpeed; % deg/s
                        QuestStaircases(k).ThresholdOffsetVector = QuestStaircases(k).ThresholdOffsetSpeed * QuestStaircases(k).CompDirection;
                    end
                    QuestStaircases(k).Quest = q;
                end

                QuestInfo = struct();
                QuestInfo.SubjectCode         = this.Session.subjectCode;
                QuestInfo.LastTrialNumber     = lastTrialNumber; % NaN = saved at start of run
                QuestInfo.SavedAt             = datestr(now, 'yyyy-mm-dd HH:MM:SS');
                QuestInfo.IntensityUnits      = 'relative';  % QUEST LINEAR
                QuestInfo.IntensityDefinition = ['|comp - ref| / |ref| along the trial''s offset direction, before jitter ' ...
                    '(IntensitiesRel; IntensitiesLog10 = log10 of it, as used by QUEST)'];
                QuestInfo.CompAxisFrame       = char(this.ExperimentOptions.Quest_Comp_Axis_Frame); % QUEST FRAME
                QuestInfo.ExperimentDesign    = 'A1MotionEllipsesMixed (MOCS + QUEST interleaved)'; % MIXED
                QuestInfo.JitterNote          = 'QUEST trials use Quest_Jitter_Multiplier; Jitter_Multiplier is MOCS only'; % MIXED
                opt_names = fieldnames(this.ExperimentOptions);
                keep = opt_names(startsWith(opt_names, 'Quest_') | ...
                    ismember(opt_names, {'nonzero_rand', 'Do_Jitter', 'Jitter_Multiplier'}));
                for f = 1:numel(keep)
                    QuestInfo.Options.(keep{f}) = this.ExperimentOptions.(keep{f});
                end

                % Same folder as the session data; falls back to the current folder
                % (QUEST PLOT: path logic moved to questFileBase, shared with the PNG)
                fname = [this.questFileBase() '_QuestStaircases.mat'];

                save(fname, 'QuestStaircases', 'QuestInfo', '-v6'); % -v6: uncompressed, fast between trials
                if isnan(lastTrialNumber)
                    fprintf('QUEST staircases will be saved to: %s\n', fname);
                end
            catch ex
                % never stop the experiment because of a save problem
                warning('A1MotionEllipsesMixed:QuestSave', 'Could not save QUEST staircases (%s).', ex.message);
            end
        end

        % =====================================================================
        % QUEST PLOT: folder + file stem shared by the QUEST output files
        % (same folder as the session data; falls back to the current folder)
        % =====================================================================
        function base = questFileBase(this)
            save_dir = '';
            try save_dir = this.Session.dataPath; catch, end
            if isempty(save_dir) || ~exist(save_dir, 'dir')
                save_dir = pwd;
            end
            try sess_name = this.Session.name; catch, sess_name = ''; end
            if isempty(sess_name), sess_name = this.Session.subjectCode; end
            base = fullfile(char(save_dir), char(sess_name));
        end

        % =====================================================================
        % QUEST PLOT: save a PNG of the reference vectors and their comparison
        % axes in 2D velocity space (Vx, Vy). Called once in initBeforeRunning,
        % before the first trial. Drawn in an invisible figure so the stimulus
        % window is not disturbed.
        %   big dot   = reference vector (label: ref index, comparison angle, N reps)
        %   line      = comparison axis, from the reference out to the largest
        %               allowed offset (Quest_Max_Rel_Offset x ref speed)
        %   small dot = QUEST's starting guess on that axis (Quest_tGuessRel x ref speed)
        %   (QUEST FRAME: label angle is in the axis frame, 'rel' or 'abs'; for a
        %    [0 0] ref in the relative frame the axis changes per trial and is not drawn)
        %   grey      = speed max circle and component max box (random refs only)
        % =====================================================================
        function saveQuestReferencePlot(this)
            fig = [];
            try
                info = this.questInfo;
                opts = this.ExperimentOptions;
                nz = 0.05; % same nonzero_rand default as SetUpTrialTable
                try
                    if ~isempty(opts.nonzero_rand), nz = opts.nonzero_rand; end
                catch
                end

                % one entry per (reference, comparison angle) combo; repetitions share it
                combo_keys = [[info.RefIndex]', [info.AxisIndex]'];
                [combos, first_k] = unique(combo_keys, 'rows', 'stable');
                n_c = numel(first_k);

                % geometry of every combo
                P_ref = zeros(n_c, 2); P_end = zeros(n_c, 2); P_guess = zeros(n_c, 2);
                spd = zeros(n_c, 1); labels = cell(n_c, 1);
                for c = 1:n_c
                    k = first_k(c);
                    v_ref = info(k).RefVelocity;
                    u_dir = info(k).CompDirection;
                    if info(k).ZeroRefRandomized
                        ref_speed = nz; % [0 0] refs are replaced by +/-nonzero_rand each trial
                        ref_note = ' (randomized)';
                    else
                        ref_speed = norm(v_ref);
                        ref_note = '';
                    end
                    P_ref(c, :)   = v_ref;
                    P_end(c, :)   = v_ref + opts.Quest_Max_Rel_Offset * ref_speed * u_dir;
                    P_guess(c, :) = v_ref + opts.Quest_tGuessRel * ref_speed * u_dir; % QUEST LINEAR
                    spd(c)        = ref_speed;
                    if info(k).CompAxisRelative, fr = 'rel'; else, fr = 'abs'; end % QUEST FRAME
                    labels{c}     = sprintf('  R%d, %.0f%s %s, x%d%s', info(k).RefIndex, info(k).CompAxisAngleDeg, ...
                        char(176), fr, sum(all(combo_keys == combos(c, :), 2)), ref_note);
                end

                % panel 1: everything; panel 2: zoom on the slower half of the references
                lim_full = max([1; abs(P_ref(:)); abs(P_end(:))]);
                if opts.Quest_Random_Refs
                    lim_full = max([lim_full, opts.Quest_Ref_Speed_Max, opts.Quest_Ref_Comp_Max]);
                end
                slow = spd <= median(spd);
                lim_zoom = max(max([abs(P_ref(slow, :)), abs(P_end(slow, :))])); % (works on older MATLAB too)
                lims = 1.1 * [lim_full, max(lim_zoom, 0.1)];
                panel_titles = {'All references', 'Zoom: slower half of the references'};

                fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1600 800]);
                colors = lines(n_c);
                for p = 1:2
                    ax = axes('Parent', fig, 'Position', [0.05 + 0.5*(p-1), 0.1, 0.42, 0.75]);
                    hold(ax, 'on'); axis(ax, 'equal'); grid(ax, 'on'); box(ax, 'on');
                    lim = lims(p);
                    plot(ax, [-lim lim], [0 0], '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 0.5);
                    plot(ax, [0 0], [-lim lim], '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 0.5);
                    if opts.Quest_Random_Refs % limits used to draw the random references
                        th = linspace(0, 360, 361);
                        s_max = opts.Quest_Ref_Speed_Max;
                        c_max = opts.Quest_Ref_Comp_Max;
                        plot(ax, s_max * cosd(th), s_max * sind(th), ':', 'Color', [0.6 0.6 0.6]);
                        plot(ax, [-c_max c_max c_max -c_max -c_max], [-c_max -c_max c_max c_max -c_max], ...
                            '--', 'Color', [0.6 0.6 0.6]);
                    end
                    for c = 1:n_c
                        plot(ax, [P_ref(c, 1) P_end(c, 1)], [P_ref(c, 2) P_end(c, 2)], '-', ...
                            'Color', colors(c, :), 'LineWidth', 1.5);
                        plot(ax, P_guess(c, 1), P_guess(c, 2), 'o', 'MarkerSize', 4, ...
                            'MarkerFaceColor', colors(c, :), 'MarkerEdgeColor', 'none');
                        plot(ax, P_ref(c, 1), P_ref(c, 2), 'o', 'MarkerSize', 8, ...
                            'MarkerFaceColor', colors(c, :), 'MarkerEdgeColor', 'k');
                        if all(abs(P_ref(c, :)) <= lim) % only label refs inside this panel
                            text(ax, P_ref(c, 1), P_ref(c, 2), labels{c}, 'FontSize', 8, ...
                                'VerticalAlignment', 'bottom', 'Interpreter', 'none', 'Clipping', 'on');
                        end
                    end
                    xlim(ax, [-lim lim]); ylim(ax, [-lim lim]);
                    xlabel(ax, 'V_x (deg/s)'); ylabel(ax, 'V_y (deg/s)');
                    title(ax, panel_titles{p}, 'FontWeight', 'normal');
                end
                annotation(fig, 'textbox', [0 0.9 1 0.08], 'EdgeColor', 'none', ...
                    'HorizontalAlignment', 'center', 'Interpreter', 'none', 'FontSize', 11, 'String', ...
                    {sprintf('%s: %d references, %d staircases', char(this.Session.subjectCode), ...
                    numel(unique(combos(:, 1))), numel(info)), ...
                    sprintf(['big dot = reference (index, comparison angle in %s frame, N reps); ' ...
                    'line = comparison axis to max offset; small dot = QUEST start guess'], ...
                    char(opts.Quest_Comp_Axis_Frame))}); % QUEST FRAME

                fname = [this.questFileBase() '_QuestReferences.png'];
                print(fig, fname, '-dpng', '-r150');
                fprintf('QUEST reference plot saved to: %s\n', fname);
            catch ex
                % never stop the experiment because of a plotting problem
                warning('A1MotionEllipsesMixed:QuestPlot', 'Could not save the QUEST reference plot (%s).', ex.message);
            end
            if ~isempty(fig) && isvalid(fig), close(fig); end
        end
    end

    % =====================================================================
    % QUEST LINEAR: conversion helpers. The experiment works in linear relative
    % offset; Psychtoolbox QUEST works in log10. Every Quest* call goes through
    % these, so the convention lives in one place. (Called as this.questToLog
    % etc., which also works when the class lives in a package.)
    % =====================================================================
    methods (Static)
        function x_log = questToLog(rel)
            % linear relative offset -> QUEST intensity (log10)
            if any(rel(:) <= 0)
                error('A1MotionEllipsesMixed:NonPositiveIntensity', ...
                    'Relative offsets must be > 0 to convert to QUEST''s log10 units.');
            end
            x_log = log10(rel);
        end

        function rel = questFromLog(x_log)
            % QUEST intensity (log10) -> linear relative offset
            rel = 10 .^ x_log;
        end

        function [m, sd] = questLinearPosterior(q)
            % Mean and SD of the threshold posterior in LINEAR relative units.
            % (10^QuestMean is the back-transformed log mean, which sits below
            % the linear posterior mean when the posterior is wide.)
            p = q.pdf(:) / sum(q.pdf(:));
            t = 10 .^ (q.tGuess + q.x(:));   % same conversion as questFromLog
            m  = sum(p .* t);
            sd = sqrt(sum(p .* (t - m).^2));
        end
    end

end

% =========================================================================
% MIXED: build one trial-table column from the QUEST and MOCS arrays
% =========================================================================
function v = mixColumn(isQ, iQ, iM, qvals, mvals)
% isQ: per row, true for QUEST rows; iQ / iM: indices into qvals / mvals for
% the QUEST / MOCS rows (in table order). Works for numeric and cell columns.
if iscell(qvals)
    v = cell(numel(isQ), 1);
else
    v = nan(numel(isQ), 1);
end
v(isQ)  = qvals(iQ);
v(~isQ) = mvals(iM);
end

% =========================================================================
% QUEST QUADRANTS: local helper functions (file-local, callable from methods)
% =========================================================================
function signs = balancedRefSigns(absRefs, stream)
% Component signs for the references so they are spread as evenly as
% possible over the four quadrants.
%   - off-axis ref (both components nonzero): counts 1 toward its quadrant
%   - ref on an axis (one zero component): counts 1/2 toward each of the two
%     quadrants it borders; only the nonzero component's sign matters
%   - [0 0] ref: counts nothing (it is randomized per trial anyway)
% Evenness = sum of squared quadrant loads (lower = more even). Among all
% equally even assignments, one is chosen at random from STREAM (the
% participant's sign stream), so it is reproducible per participant.
% Exhaustive search when the number of combinations is small (8 random refs
% -> 4^8 = 65536), greedy assignment otherwise (optimal for off-axis refs).
tol  = 1e-10;
n    = size(absRefs, 1);
onX  = abs(absRefs(:, 2)) < tol;      % lies on the x-axis (vy = 0)
onY  = abs(absRefs(:, 1)) < tol;      % lies on the y-axis (vx = 0)
opts = cell(n, 1);                    % candidate sign pairs per ref
Lopt = cell(n, 1);                    % quadrant load of each candidate
for i = 1:n
    if onX(i) && onY(i)
        opts{i} = [1 1];
    elseif onX(i)
        opts{i} = [1 1; -1 1];
    elseif onY(i)
        opts{i} = [1 1; 1 -1];
    else
        opts{i} = [1 1; -1 1; -1 -1; 1 -1];
    end
    Lopt{i} = zeros(size(opts{i}, 1), 4);
    for k = 1:size(opts{i}, 1)
        Lopt{i}(k, :) = refQuadrantLoad(opts{i}(k, :) .* absRefs(i, :));
    end
end
nOpt  = cellfun(@(o) size(o, 1), opts);
nComb = prod(nOpt);
pick  = ones(n, 1);

if nComb <= 1e5
    best = inf; nTies = 0;
    choice = ones(n, 1);
    for c = 1:nComb
        r = c - 1;                                   % mixed-radix decode
        L = zeros(1, 4);
        for i = 1:n
            choice(i) = mod(r, nOpt(i)) + 1;
            r = floor(r / nOpt(i));
            L = L + Lopt{i}(choice(i), :);
        end
        cost = sum(L .^ 2);
        if cost < best - 1e-9
            best = cost; nTies = 1; pick = choice;
        elseif abs(cost - best) <= 1e-9
            nTies = nTies + 1;                       % reservoir sampling:
            if rand(stream) < 1 / nTies              % uniform among the ties
                pick = choice;
            end
        end
    end
else
    % Greedy: off-axis refs first (full units), then on-axis refs, each in a
    % random order, always into the least-loaded option (random tie-break).
    ord  = randperm(stream, n);
    axisRef = onX | onY;
    ord  = [ord(~axisRef(ord)), ord(axisRef(ord))];
    L = zeros(1, 4);
    for i = ord
        costs = sum((L + Lopt{i}) .^ 2, 2);
        cand  = find(costs <= min(costs) + 1e-9);
        pick(i) = cand(randi(stream, numel(cand)));
        L = L + Lopt{i}(pick(i), :);
    end
end

signs = zeros(n, 2);
for i = 1:n
    signs(i, :) = opts{i}(pick(i), :);
end
end

function L = refQuadrantLoad(refs)
% Quadrant load (Q1..Q4, counter-clockwise from +x,+y) of signed reference
% vectors: 1 for an off-axis ref, 1/2 to each bordering quadrant for an
% on-axis ref, 0 for [0 0].
tol = 1e-10;
L = zeros(1, 4);
for i = 1:size(refs, 1)
    vx = refs(i, 1); vy = refs(i, 2);
    if abs(vx) < tol && abs(vy) < tol
        continue
    elseif abs(vy) < tol                         % on the x-axis
        if vx > 0, L([1 4]) = L([1 4]) + 0.5; else, L([2 3]) = L([2 3]) + 0.5; end
    elseif abs(vx) < tol                         % on the y-axis
        if vy > 0, L([1 2]) = L([1 2]) + 0.5; else, L([3 4]) = L([3 4]) + 0.5; end
    elseif vx > 0 && vy > 0, L(1) = L(1) + 1;
    elseif vx < 0 && vy > 0, L(2) = L(2) + 1;
    elseif vx < 0 && vy < 0, L(3) = L(3) + 1;
    else,                    L(4) = L(4) + 1;
    end
end
end