
%% after_run_plot 
% Make a quick plot of which ones were correct:

% get unique stim types

all_stim_types_uncell = vertcat(expParams.all_stim_types{:});
stim_types = unique(all_stim_types_uncell);

this_inds = [];

% gets logical arrays of which entries are of each stimulus type (direction or speed)
for n = 1:length(stim_types)

    this_inds(n, :) = strcmp(all_stim_types_uncell, stim_types(n)); 

end

%% direction========================================================================================
% get the ones related to either
dir_inds = logical(this_inds(1,:));

respMatrix_dir      = respMatrix(dir_inds, :);
%MOCS_incs_dir       = MOCS_incs_dir;
all_move_vecs_dir   = expParams.all_move_vecs(dir_inds, :, :);
odd_one_ind_dir     = expParams.odd_one_ind(dir_inds, :); % also shuffled the same way to make sure the order is correct
all_ref_vecs_dir    = expParams.all_ref_vecs(dir_inds, :, :);
all_inc_vecs_dir    = expParams.all_inc_vecs(dir_inds, :, :);
all_incs_dir        = expParams.all_incs(dir_inds, :, :);
all_inc_inds_dir    = expParams.all_inc_inds(dir_inds, :);
all_ref_inds_dir    = expParams.all_ref_inds(dir_inds, :);
all_stim_types_dir  = expParams.all_stim_types(dir_inds);


%tack on the stimLevels per trial so they move together
respMatrix_dir(:, 4) = all_inc_inds_dir;
ref_inds = unique(all_ref_inds_dir);

% get monitors:
monitors = get(0, 'MonitorPositions');

fig = figure('Position', monitors(2,:)); %hold on;
subplot(1,2,1)
ax = gca;

ax.XTick = 1:length(ref_inds);

for n = 1:length(ref_inds)

    this_ref_respMatrix = respMatrix_dir(all_ref_inds_dir == ref_inds(n), :);

    this_corrects = this_ref_respMatrix(:, 3);
    this_incs = this_ref_respMatrix(:, 4);

    dot_colours = ones(size(this_corrects,  1), 3);
    dot_colours(:, 1) = dot_colours(:, 1).*(1-this_corrects); % reds for wrongs
    dot_colours(:, 2) = dot_colours(:, 2).*(this_corrects); % greens for rights
    dot_colours(:, 3) = dot_colours(:, 3).*0; % no blue
    
    scatter(repmat(n, length(this_corrects), 1), ...
        expParams.MOCS_incs_dir(this_incs), ...
        50,...
        dot_colours, ...
        'filled'); hold on;

        ax.XTickLabel{n} = sprintf('[%0.1f, %0.1f]', abs(expParams.ref_vecs(n, 1)), abs(expParams.ref_vecs(n, 2)));

        % repmat(abs(expParams.ref_vecs(n, 1)), length(this_corrects), 1), ...
        % repmat(abs(expParams.ref_vecs(n, 2)), length(this_corrects), 1), ...

end
yline(0, '--')
xlabel("Reference Vectors");
ylabel("Direction Angle change from reference vector");
title("Direction Trials");

axis square


%% speed============================================================================================
spe_inds = logical(this_inds(2,:));

respMatrix_spe      = respMatrix(spe_inds, :);
%MOCS_incs_spe       = MOCS_incs_spe;
all_move_vecs_spe   = expParams.all_move_vecs(spe_inds, :, :);
odd_one_ind_spe     = expParams.odd_one_ind(spe_inds, :); % also shuffled the same way to make sure the order is correct
all_ref_vecs_spe    = expParams.all_ref_vecs(spe_inds, :, :);
all_inc_vecs_spe    = expParams.all_inc_vecs(spe_inds, :, :);
all_incs_spe        = expParams.all_incs(spe_inds, :, :);
all_inc_inds_spe    = expParams.all_inc_inds(spe_inds, :);
all_ref_inds_spe    = expParams.all_ref_inds(spe_inds, :);
all_stim_types_spe  = expParams.all_stim_types(spe_inds);

%tack on the stimLevels per trial so they move together
nTrials = length(all_inc_inds_spe);

respMatrix_spe(:, 4) = all_inc_inds_spe;
ref_inds = unique(all_ref_inds_spe);

%figure; %hold on;
subplot(1,2,2)
ax = gca;
ax.XTick = 1:length(ref_inds);

for n = 1:length(ref_inds)

    this_ref_respMatrix = respMatrix_spe(all_ref_inds_spe == ref_inds(n), :);

    this_corrects = this_ref_respMatrix(:, 3);
    this_incs = this_ref_respMatrix(:, 4);

    dot_colours = ones(size(this_corrects,  1), 3);
    dot_colours(:, 1) = dot_colours(:, 1).*(1-this_corrects); % reds for wrongs
    dot_colours(:, 2) = dot_colours(:, 2).*(this_corrects); % greens for rights
    dot_colours(:, 3) = dot_colours(:, 3).*0; % no blue
    
    scatter(repmat(n, length(this_corrects), 1), ...
        expParams.MOCS_incs_spe(this_incs), ...
        50,...
        dot_colours, ...
        'filled'); hold on;

        ax.XTickLabel{n} = sprintf('[%0.1f, %0.1f]', abs(expParams.ref_vecs(n, 1)), abs(expParams.ref_vecs(n, 2)));

        % repmat(abs(expParams.ref_vecs(n, 1)), length(this_corrects), 1), ...
        % repmat(abs(expParams.ref_vecs(n, 2)), length(this_corrects), 1), ...

end
yline(0, '--')
xlabel("Reference Vectors");
ylabel("Percent change from reference vector");
title("Speed Trials");

axis square

saveas(fig, sprintf('./results/after_run_plots/%s_oddball_%s_%0.0fx%0.0frefvecs_%0.0ftrials_%s_%s.png', participant_ID, stim_type, sqrt(size(ref_vecs, 1)), sqrt(size(ref_vecs, 1)), numTrials, trials_type, string(datetime('now', 'Format', 'MM-dd_HH-mm'))));
