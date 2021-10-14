function [out out2] = PlotHistogram( varargin )
% plot_histogram( [ax], [S], data, [thebins], [tit], [xlab], [ylab], [totaltime],[groups], [legend], [colors_array] )
%
% plots a histogram
%
% options = plot_histogram( 'get_options' )
% options = plot_histogram( 'get_defaults' )
%
% plot_histogram( ax, ...)
%       plots in the given axis
%
% Parameters:
%   - options: structure with GUI options for the plot
%   - Y_Axis			= { {'{Number}', 'Percentage', 'Rate', 'Percentmax' } };
%   - X_Axis			= { {'{Linear}', 'Log' } };
%   - Use_Lines			= { {'{0}', '1' } };
%   - Manual_Bin_Range	= { {'{0}', '1' } };
%   - Minimum			= {0};
%   - Maximum			= {3};
%   - Number_Of_Bins	= {40};
%   - Fitting           = { {'{None}', 'Normal', 'Rayleigh', 'Ex-gaussian', 'Mix-2-Gaussian', 'Mix-3-Gaussian'} };
%
%   - data: (if its a cell, multiple histograms will be plotted)
%   - groups: if passed, will calculate error of histograms of the
%        groups indicated by this variable
%   - thebins: bins of the histogram
%   - tit: title of the graph
%   - xlab: label of the x axis
%   - ylab: label of the y axis
%   - totaltime: number of miliseconds that correspond to the data, used to
%   for the normalization 'Rate'
%   - groups: grouping variable to calculate average and standar error
%               it must have the same size as data
%
% Output:
%   -out: handles of objects created
%
% Examples:
% plot_histogram( data )
% plot_histogram( data, degbins )
% plot_histogram( S, data, degbins, tit, xlab, ylab, totaltime )
% plot_histogram( ax, S, data, degbins, tit, xlab, ylab, totaltime )
%
if ( nargin == 1 && isstr(varargin{1}))
    command = varargin{1};
    switch (command)
        case 'get_options'
            Histogram_Options.Y_Axis			= { {'{Number}', 'Percentage', 'Rate', 'Percentmax', 'Density'} };
            Histogram_Options.X_Axis			= { {'{Linear}', 'Log', 'Normalize By Max', 'Normalize By Mean' } };
            Histogram_Options.Use_Lines			= { {'{0}', '1' } };
            Histogram_Options.Manual_Bin_Range	= { {'{0}', '1' } };
            Histogram_Options.Minimum			= {0};
            Histogram_Options.Maximum			= {3};
            Histogram_Options.Number_Of_Bins	= {40};
            Histogram_Options.Fitting           = { {'{None}', 'Normal', 'Rayleigh', 'Ex-gaussian', 'Mix-2-Gaussian', 'Mix-3-Gaussian'} };
            Histogram_Options.Font_Size			= {14};
            Histogram_Options.Error_Type        = { {'{None}', 'Lines', 'Shading', 'Bars'} };
            Histogram_Options.Line_Width        = 2;
            Histogram_Options.Restrict_To_X_Range =  { {'{0}', '1' } };
            Histogram_Options.Plot_Mean =  { {'{0}', '1' } };
            Histogram_Options.Use_Inverse_Cumulative_Distribution = { {'{0}', '1' } };
            Histogram_Options.Use_Cumulative_Distribution = { {'{0}', '1' } };
            out = Histogram_Options;
        case 'get_defaults'
            histogram_options = plot_histogram( 'get_options' );
            out = StructDlg(histogram_options,'',[],[],'off');
    end
    return
end


p = check_parameters( varargin{:} );

if (~isfield(p,'ax') )
    % if no axes is given create a new one in a new figure
    figure
    p.ax = axes;
end

S = p.S;
data = p.data;
if ( ~iscell(data) )
    data = {data};
end
degbins = p.thebins;
tit = p.tit;
xlab = p.xlab;
ylab = p.ylab;
totaltime = p.totaltimes;


if isfield(p,'groups') && ( ~isempty(p.groups) )
    groups = p.groups;
    flag_groups = 1;
    if ( ~iscell(groups) )
        groups = {groups};
    end
else
    flag_groups = 0;
end

% flag_groups = 1;
% groups{1} = ones(1552,1);
% groups{1}(1000:end) = 2;
if ~isfield(p,'colors_array')||isempty(p.colors_array)
    [COLORS colors_array] = CorrGui.get_nice_colors;
else
    colors_array = p.colors_array;
end
%% prepare the bins for the histogram
if ( isempty(degbins) )
    if ( iscell(data) )
        mindata = min(data{1});
        maxdata = max(data{1});
    else
        mindata = min(data);
        maxdata = max(data);
    end
    degbins = mindata:((maxdata-mindata)/10):maxdata;
end

if (S.Manual_Bin_Range)
    binstart = S.Minimum;
    binstop = S.Maximum;
    binstep = (S.Maximum-S.Minimum)/S.Number_Of_Bins;
    degbins = binstart:binstep:binstop;
end



% logarithmic axis
if ( strcmp( S.X_Axis, 'Log' ) )
    if ( degbins(1) == 0 )
        degbins(1) = degbins(2)/20;
    end
    degbins = logspace(log10(degbins(1)),log10(degbins(end)), length(degbins));
end

%% calculate histograms ---------------------------------------------------

% initialize
histos = zeros( length(data), length(degbins));
fits = zeros( length(data), length(degbins));
h = zeros( 1, length(data) ); % fot the handles
hfit = zeros( 1, length(data) ); % fot the handles

if flag_groups
    histos_errs = zeros( length(groups), length(degbins));
end

degbinsOrig = degbins;

for i=1:length(data)
    
    
    if ~flag_groups
        if ( ~isempty( data{i} ) )
            
            if S.Restrict_To_X_Range
                idx = data{i} >= S.Minimum &  data{i} <= S.Maximum;
                data{i} =  data{i}(idx);
            end
            
            meanOfData(i) = mean(data{i},'omitnan');
            stdOfData(i) = std(data{i},'omitnan');;
            
            % calculate histogram
            if ( strcmp( S.X_Axis, 'Normalize By Max' ) )
                if i == 1 %can only change the bins once to plot histograms on the same axes
                    degbins = (degbinsOrig-min(data{i}))/max(data{i});
                    degbins = [0, degbins(degbins>0)];
                    histos = zeros( length(data), length(degbins));
                    fits = zeros( length(data), length(degbins));
                end
                data{i} = (data{i}-min(data{i}))/max(data{i});
            end
            
            % calculate histogram
            if ( strcmp( S.X_Axis, 'Normalize By Mean' ) )
                if i == 1
                    degbins = (degbinsOrig-min(data{i}))/meanOfData(i);
                    degbins = [0, degbins(degbins>0)];
                    histos = zeros( length(data), length(degbins));
                    fits = zeros( length(data), length(degbins));
                end
                data{i} = (data{i}-min(data{i}))/meanOfData(i);
            end
            
            histos(i,:)	= histc( data{i}, degbins);
            
            
            if S.Use_Inverse_Cumulative_Distribution
                histos(i,:) = 1-cumsum( histos(i,:))/sum( histos(i,:));
                histos(i,:) = 100*[1, histos(i,1:end-1)];
            end
            
            if S.Use_Cumulative_Distribution
                histos(i,:) = cumsum( histos(i,:))/sum( histos(i,:));
                histos(i,:) = 100*[0, histos(i,1:end-1)];
            end
            
            
            %cant normalize if we do cumulative distribution
            if ~S.Use_Inverse_Cumulative_Distribution && ~S.Use_Cumulative_Distribution
                % normalize histogram
                switch( S.Y_Axis )
                    case 'Percentage'
                        histos(i,:) = histos(i,:) / sum(histos(i,:)) *100;
                    case 'Rate'
                        histos(i,:) = histos(i,:) / totaltime(i) *1000;
                    case 'Percentmax'
                        histos(i,:) = histos(i,:) / max(histos(i,:))*100;
                    case 'Density'
                        density = ksdensity(log(data{i}), log(degbins));
                        histos(i,:) = density/sum(density)*sum(histos(i,:));
                    otherwise
                        histos(i,:) = histos(i,:);
                end
            end
        end
        
        % fit data
        if ~strcmp( S.Fitting , 'None')
            [fitParams, fitParamsInt, fithistogram] = fitdata( data{i}, S.Fitting, degbins );
            fits(i,:) = fithistogram/sum(fithistogram)*sum(histos(i,:));
        end
        
    else
        if ( ~isempty( groups{i} ) )
            num_groups = length(unique(groups{i}));
            group_histos = {};
            groupMeans = [];
            groupMedians = [];
            groupStds = [];
            groupList = floor(unique(groups{i}))';
            if size(groupList, 2) == 1
                groupList = groupList';
            end
            for jgroup = groupList
                data_idx{jgroup} = find(groups{i} == jgroup);
                
                currData = data{i}(data_idx{jgroup});
                groupMeans(jgroup) = mean(currData,'omitnan');
                groupMedians(jgroup) = median(currData,'omitnan');
                groupModes(jgroup) = mode(currData);
                groupStds(jgroup) = std(currData,'omitnan');
                
                
                % calculate histogram
                if ( strcmp( S.X_Axis, 'Normalize By Max' ) )
                    if i == 1 && jgroup == 1
                        degbins = (degbinsOrig-min(currData))/max(currData);
                        degbins = [0, degbins(degbins>0)];
                        histos = zeros( length(data), length(degbins));
                        fits = zeros( length(data), length(degbins));
                        histos_errs = zeros( length(groups), length(degbins));
                    end
                    currData = (currData-min(currData))/max(currData);
                end
                
                % calculate histogram
                if ( strcmp( S.X_Axis, 'Normalize By Mean' ) )
                    if i == 1 && jgroup == 1
                        degbins = (degbinsOrig-min(currData))/groupMeans(jgroup);
                        degbins = [0, degbins(degbins>0)];
                        histos = zeros( length(data), length(degbins));
                        fits = zeros( length(data), length(degbins));
                        histos_errs = zeros( length(groups), length(degbins));
                    end
                    currData = (currData-min(currData))/groupMeans(jgroup);
                end
                
                group_histos{jgroup}	= histc( currData , degbins);
                
                
                if S.Use_Inverse_Cumulative_Distribution
                    group_histos{jgroup} = 1-cumsum(group_histos{jgroup})/sum(group_histos{jgroup});
                    group_histos{jgroup} = 100*[1;group_histos{jgroup}(1:end-1)];
                end
                
                if S.Use_Cumulative_Distribution
                    group_histos{jgroup} = cumsum( group_histos{jgroup})/sum( group_histos{jgroup});
                    group_histos{jgroup} = 100*[0; group_histos{jgroup}(1:end-1)];
                end
                
                
                % fit data
                if ~strcmp( S.Fitting , 'None')
                    [fitParams, fitParamsInt, fithistogram] = fitdata( currData, S.Fitting, degbins );
                    group_fits{jgroup} = fithistogram;
                end
                
                %cant normalize if we do cumulative distribution
                if ~S.Use_Inverse_Cumulative_Distribution && ~S.Use_Cumulative_Distribution
                    switch( S.Y_Axis )
                        case 'Percentage'
                            group_histos{jgroup} = group_histos{jgroup}/ sum(group_histos{jgroup}) *100;
                        case 'Rate'
                            disp('Need To Fix Code To Plot Rate Histogram')
                            %group_histos{jgroup} = group_histos{jgroup} / totaltime(i) *1000; %%%%%THIS IS NOT RIGHT MUST FIX
                        case 'Percentmax'
                            group_histos{jgroup} = group_histos{jgroup} / max(group_histos{jgroup})*100;
                        case 'Density'
                            density = ksdensity(log(currData), log(degbins));
                            group_histos{jgroup} = density/sum(density)*sum(group_histos{jgroup});
                    end
                end
            end
            histos(i,:) = mean(cat(3, group_histos{:}),3);
            histos_errs(i,:) = std(cat(3, group_histos{:}),0,3)/sqrt(num_groups);
            if ~strcmp( S.Fitting , 'None')
                fits(i,:) =  mean(cat(3, group_fits{:}),3);
            end
            
            meanOfData(i) = mean(groupMeans,'omitnan');
            stdOfData(i) = nan(groupStds,'omitnan');
            
            out.groupMeans(i, :) = groupMeans;
            out.groupStds(i, :) = groupStds;
            out.groupMedians(i, :) = groupMedians;
            out.groupModes(i, :) = groupModes;
            
            
        end
    end
end

%% plot histograms --------------------------------------------------------
set(p.ax,'nextplot','add');
set(p.ax, 'xlim', [degbins(1) degbins(end)]);
out.ax = p.ax;
if ( ~S.Use_Lines ) % plot using bars
    
    h	= bar(p.ax, degbins, histos', 'histc');
    out.hbar = h;
    
    % plot_error
    if flag_groups &&  ~strcmp(S.Error_Type, 'None')
        degbins = degbins+.5*(degbins(2)-degbins(1));
        degbins = repmat(degbins,size(histos,1),1);
        out.herr = errorbar(p.ax, degbins' ,  histos', histos_errs', 'linestyle','none'); %we will only use one error type for bar plots
    end
    for i=1:length(data)
        set(h(i), 'facecolor', colors_array(i,:));
        set(h(i), 'edgecolor', [0 0 0]);
    end
    
    if ( ~strcmp(S.Fitting, 'None') )
        out.hfit = zeros(1,length(data));
        for i=1:length(data)
            % plto fits
            hfit = plot(p.ax, degbins, fits(i,:)','--');
            set(hfit, 'color', colors_array(i,:),'linewidth',1);
            out.hfit(i) = hfit;
        end
    end
    
    out.forLegend = out.hbar;
else % plot using lines
    
% %     degbins2 = degbins+.5*(degbins(2)-degbins(1)); % When using lines, the indices should be in the middle of the bin
    
    for i=1:length(data)
        
        % plot fits
        if ( ~strcmp(S.Fitting, 'None') )
            hfit(i) = plot(p.ax, degbins, fits(i,:)','--');
            set(hfit(i), 'color', colors_array(i,:), 'linewidth', 1);
            out.forLegend = hfit;
        end
        
        % plot histograms without error
        if ~flag_groups || strcmp(S.Error_Type, 'None')
            
            h(i) = plot(p.ax, degbins, histos(i,:)');
            set(h(i), 'color', colors_array(min(i,length(colors_array(:, 1))) ,:),'linewidth',S.Line_Width);
            out.forLegend = h;
        else
            % plot histograms with error
            switch S.Error_Type
                case 'Lines'
                    
                    h(i) = plot(p.ax, degbins, histos(i,:)', 'LineWidth', S.Line_Width, 'Color', colors_array(i,:) );
                    
                    errplus = histos(i,:)' + histos_errs(i,:)';
                    errminus = histos(i,:)' - histos_errs(i,:)';
                    herrplus(i) = plot(p.ax, degbins, errplus, '-', 'LineWidth', 1, 'Color', colors_array(i,:) );
                    herrminus(i)= plot(p.ax, degbins, errminus, '-', 'LineWidth', 1, 'Color', colors_array(i,:) );
                    out.forLegend = h;
                    
                case 'Shading'
                    
                    h(i) = plot(p.ax, degbins, histos(i,:)','LineWidth', S.Line_Width, 'Color', colors_array(i,:));
                    
                    % plot shadows
                    errplus = histos(i,:)' + histos_errs(i,:)';
                    errminus = histos(i,:)' - histos_errs(i,:)';
                    xind_double = [degbins   degbins(end:-1:1)];
                    err =	[errplus;   errminus(end:-1:1)];
                    err = err';
                    axes(p.ax);
                    if ( ~isfield (S, 'UseTransparency') )
                        S.UseTransparency = 1;
                    end
                    
                    if ( S.UseTransparency )
                        hpatch(i) = patch( xind_double, err, '-', 'FaceColor', colors_array(i,:), 'LineStyle', 'none','FaceAlpha','flat','FaceVertexAlphaData',0.3,'AlphaDataMapping','none');
                    else
                        hpatch(i) = patch( xind_double, err, '-', 'FaceColor', colors_array(i,:), 'LineStyle', 'none');
                    end
                    
                    out.forLegend = h;
                case 'Bars'
                    h(i) = errorbar(p.ax, degbins,  histos(i,:)', histos_errs(i,:)','linewidth', S.Line_Width , 'color', colors_array(i,:));
            end
        end
        
        if S.Plot_Mean
            meanSrings{i} =  ['Mean: ' num2str(meanOfData(i),2) ' \pm ' num2str(stdOfData(i),2)];
        end
        
    end
    
    currYlim = get(p.ax, 'ylim');
    currXlim = get(p.ax, 'xlim');
    if S.Plot_Mean
        text(currXlim(end)*.7, currYlim(end)*.8, meanSrings, 'fontsize', S.Font_Size  )
    end
    
    % output all the handles
    out.data = data;
    out.hline = h;
    if ( exist('hfit', 'var') )
        out.hfit = hfit;
    end
    if ( exist('herrplus', 'var') )
        out.herrplus = herrplus;
        out.herrplus = herrminus;
    end
    if ( exist('hpatch', 'var') )
        out.hpatch = hpatch;
    end
end
if ( ~exist('out','var') || isempty( out) )
    out = h;
    out2 = hfit;
end
%% format plot ------------------------------------------------------------
if ~isfield(S,'Font_Size')
    S.Font_Size = 12;
end
set(p.ax, 'FontSize', S.Font_Size-2);
if ( ~isempty( tit ) )
    title( p.ax, tit, 'fontsize', S.Font_Size);
end
xlabel(p.ax, xlab, 'fontsize', S.Font_Size);

switch( S.Y_Axis )
    case 'Number'
        ylab = ['Number of ' ylab];
    case 'Distribution'
        ylab = ['Probability of ' ylab];
    case 'Percentage'
        ylab = ['Percent of ' ylab];
    case 'Rate'
        ylab = [ylab ' per sec'];
    case 'Density'
        ylab = ['Density'];
end
ylabel(p.ax, ylab, 'fontsize', S.Font_Size);

if ( strcmp( S.X_Axis, 'Log' ) )
    set(p.ax,'XScale','log')
end
set(p.ax, 'TickDir','out')





if isfield(p,'leg') && ~isempty(p.leg)
    out.legHandle = legend(h,p.leg);
end


function p = check_parameters( varargin )


histogram_options = plot_histogram( 'get_options' );
S = StructDlg(histogram_options,'',[],[],'off');

if ( nargin >=1)
    p = inputParser;   % Create an instance of the class.
    
    if ( ishandle( varargin{1} ) )
        p.addRequired('ax', @ishandle);
        if ( isstruct( varargin{2} ) )
            p.addRequired('S', @isstruct);
        end
    end
    if ( isstruct( varargin{1} ) )
        p.addRequired('S', @isstruct);
    end
    p.addRequired('data', @(x)(isnumeric(x)&& length(x)>0)||iscell(x));
    p.addOptional('thebins', [], @(x)(isnumeric(x)));
    p.addOptional('tit', 'Main sequence', @isstr);
    p.addOptional('xlab', '', @(x)(isstr(x)||iscell(x)));
    p.addOptional('ylab', 'Number',  @(x)(isstr(x)||iscell(x)));
    p.addOptional('totaltimes', NaN, @(x)(isempty(x) || (isnumeric(x) && (size(x,2)==1)||size(x,1)==1)));
    p.addOptional('groups', [], @(x)(isnumeric(x)&& length(x)>1)||iscell(x)||isempty(x));
    p.addOptional('leg', [], @(x)(isstr(x)||iscell(x)||isempty(x)));
    p.addOptional('colors_array', '', @(x)(isnumeric(x) && any(size(x) == 3)));

    
    p.StructExpand = true;
    p.parse(varargin{:});
    
    
    p = p.Results;
    if ( ~isfield( p, 'S') )
        p.S = S;
    end
else
    throw('at least one parameter are necessary');
end