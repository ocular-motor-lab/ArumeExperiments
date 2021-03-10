
function out = PlotMainsequence( varargin )
% out = plot_mainsequence( [axis], [options], xdata, ydata, [tit], [xlab], [ylab] )
%
% plots the mainsequence
%
% options = plot_mainsequence( 'get_options' )
%
% plot_mainsequence( ax, ...)
%       plots in the given axis
%
% Parameters:
%   - options: structure with GUI options for the plot
%       - Type_Of_Points	= { {'.','{o}', 'Colormap' } };
%       - Axes				= { {'Linear', 'Log' } };
%       - Minimum_X			= {0};
%       - Maximum_X			= {3};
%       - Minimum_Y			= {0};
%       - Maximum_Y			= {200};
%       - Number_of_Colormap_Bins = {200};
%
%   - xdata: x coordinates of points (if its a cell, multiple main
%   sequences will be plotted)
%   - ydata: y coordinates of points (if its a cell, multiple main
%   sequences will be plotted)
%   - xlimit: limits of the x axis
%   - ylimit: limits of the y axis
%   - tit: title of the graph
%   - xlab: label of the x axis
%   - ylab: label of the y axis
%
% Output:
%   -out: handles of objects created
%
% Examples:
%   plot_mainsequence( xdata, ydata )
%   plot_mainsequence( xdata, ydata, xlimit, ylimit )
%   plot_mainsequence( xdata, ydata, xlimit, ylimit, tit, xlab, ylab)
%   plot_mainsequence( {xdata1, xdata2, xdata3}, {ydata1,ydata2,ydata3}, xlimit, ylimit, tit, xlab, ylab)
%   options = plot_mainsequence( 'get_options' )
%   plot_mainsequence( ax, ...)
%


%% check for single parameter command
if ( nargin == 1 )
    command = varargin{1};
    switch (command)
        case 'get_options'
            out = get_mainsequence_options();
        case 'get_defaults'
            mainsequence_options = get_mainsequence_options();
            out = StructDlg(mainsequence_options,'',[],[],'off');
    end
    return
end


%%  check parameters

p = check_parameters( varargin{:} );

S = p.S;
xdata   = p.xdata;
ydata   = p.ydata;
xlim    = [S.Minimum_X S.Maximum_X];
ylim    = [S.Minimum_Y S.Maximum_Y];
tit     = p.tit;
xlab    = p.xlab;
ylab    = p.ylab;

% if no axes is given create a new one in a new figure
if (~isfield(p,'ax') )
    figure('color','w');
    p.ax = axes;
    set(p.ax,'NextPlot','Add');
end

if ( strcmp( S.Axes, 'Log') )
    % if the axes are log, 0 is not a valid limit
    if ( xlim(1) == 0 )
        xlim(1) = 0.01;
    end
    if ( ylim(1) == 0 )
        ylim(1) = 3;
    end
end

colors_array = repmat(get(gca,'colororder'),10,1);


h = zeros(1,size(xdata,2)); % for the handles

%% do the plot
switch (S.Type_Of_Points)
    
    case { '.' 'o' 'x' }
        % scatter points plot
        if ( ~iscell( xdata) )
            xdata = {xdata}; ydata = {ydata};
        end
        out.ax = p.ax;
        out.hfit = zeros(1,size(xdata,2));
        out.hdots = zeros(1,size(xdata,2));
        out.htext = zeros(1,size(xdata,2));
        
        for row = 1:size(xdata,2)
            
            if ( isempty(xdata{row}))
                continue;
            end
            
            if S.Restrict_Fit_To_X_Range
                idx = xdata{row} >= xlim(1) &  xdata{row} <= xlim(end);
                xdata{row} = xdata{row}(idx);
                ydata{row} = ydata{row}(idx);
            end
            
            if S.Log_Transform_Data_For_Fit
                xdata{row} = log(xdata{row});
                ydata{row} = log(ydata{row});
            end
            
            % Do the linear fit and get the parameters
            [beta, stats] = robustfit( xdata{row} , ydata{row} );
            fitIntercept = beta(1);
            fitSlope = beta(2);
            
            % Plot the scatter and the fit
            xfit = xlim(1):( xlim(end)-xlim(1))/200':xlim(end);
            if S.Log_Transform_Data_For_Fit
                xdata{row} = exp(xdata{row});
                ydata{row} = exp(ydata{row});
                yfit = exp(fitIntercept)*(xfit).^(fitSlope);
            else
                yfit = fitIntercept+fitSlope*xfit;
            end
            
            hdots = plot( p.ax, xdata{row}, ydata{row}, S.Type_Of_Points, 'Color', colors_array(row,:) );
            if (S.Show_Fit)
                hfit = plot( p.ax, xfit, yfit, '-', 'LineWidth',S.Fit_Line_Width, 'Color', colors_array(row,:) );
            end
            h(row) = hdots;
            
            set(hdots,'MarkerSize', S.Marker_Size);
            set(hdots,'LineWidth', S.Marker_Line_Width);
            
            out.hfit(row) = hfit;
            out.hdots(row) = hdots;
            out.slopes(row) = beta(2);
            out.intercepts(row) = beta(1);
        end
        
        if (S.Show_Fit)
            out.forLegend = out.hfit;
        else
            out.forLegend = out.hdots;
        end
    case 'Colormap'
        % colormap plot
        if ( iscell( xdata) )
            xdata = xdata{1}; ydata = ydata{1};
            disp('PLOT MAINSEQ COLOR: Only one main sequence can be plotted in the same axes');
        end
        
        % calculate bins
        if ( strcmp( S.Axes, 'Linear') )
            vXEdge = linspace( xlim(1), xlim(end), S.Number_of_Colormap_Bins );
            vYEdge = linspace( ylim(1), ylim(end), S.Number_of_Colormap_Bins );
        else
            vXEdge = logspace( log10(xlim(1)), log10(xlim(end)), S.Number_of_Colormap_Bins);
            vYEdge = logspace( log10(ylim(1)), log10(ylim(end)), S.Number_of_Colormap_Bins);
        end
        % get the 2D histogram
        hist_data = hist2d([ydata xdata],vYEdge,vXEdge);
        
        % normalize the histogram
        m = sum(sum(hist_data));
        m = max(max(hist_data));
        % hist_data = hist_data/ m;
        hist_data = hist_data/ totaltime;
        % 				mHist2d_jig(end,end) = .03;
        % 				mHist2d_jig(1,1) = 0.00001;
        nXBins = length(vXEdge);
        nYBins = length(vYEdge);
        vXLabel = 0.5*(vXEdge(1:(nXBins-1))+vXEdge(2:nXBins));
        vYLabel = 0.5*(vYEdge(1:(nYBins-1))+vYEdge(2:nYBins));
        
        % plot
        pcolor( p.ax,  vXLabel, vYLabel,(log10(hist_data)));
        
        % set the color limits
        set(p.ax,'clim',[ -7 -6]) % LOG10 COLORMAP
        %  set(gca,'clim',[ 0 2e-6]) % Linear COLORMAP
        
        % % format colorbar
        % c = colorbar;
        % tick = get(c, 'ytick');
        % set(c, 'ytick', log10([0.0001 0.001 0.01 0.1]))
        % set(c,'yticklabel', [0.0001 0.001 0.01 0.1]*100);
        shading(p.ax, 'flat')
        
        h = [];
end

if ( ~exist('out','var') || isempty( out ) )
    out = h;
end

%% format axes
switch (S.Axes)
    case {'Log'}
        set(p.ax,'XScale','log','YScale','log')
end

set(p.ax,'xlim',xlim, 'ylim', ylim);
if ~isfield(S,'Font_Size')
    S.Font_Size = 12;
end
set(p.ax,'FontName', 'Arial', 'FontSize',S.Font_Size-2);
set(p.ax, 'TickDir','out')

if ( S.Show_title)
    title(p.ax,tit, 'FontSize',S.Font_Size);
end
xlabel(p.ax,xlab, 'FontSize',S.Font_Size);
ylabel(p.ax,ylab, 'FontSize',S.Font_Size);
box off;
end



function Main_Sequence_Options = get_mainsequence_options()

Main_Sequence_Options.Type_Of_Points	= { {'.','{o}', 'x', 'Colormap' } };
Main_Sequence_Options.Axes				= { {'Linear', 'Log' } };
Main_Sequence_Options.Minimum_X			= {0};
Main_Sequence_Options.Maximum_X			= {3};
Main_Sequence_Options.Minimum_Y			= {0};
Main_Sequence_Options.Maximum_Y			= {200};
Main_Sequence_Options.Number_of_Colormap_Bins = {200};
Main_Sequence_Options.Show_title        = { {'0','{1}'} };
Main_Sequence_Options.Font_Size         = {14};
Main_Sequence_Options.Marker_Size       = {2};
Main_Sequence_Options.Marker_Line_Width	= {2};
Main_Sequence_Options.Show_Fit          = { {'0','{1}'} };
Main_Sequence_Options.Fit_Line_Width   	= {2};
Main_Sequence_Options.Restrict_Fit_To_X_Range    = {{'{0}' '1'}};
Main_Sequence_Options.Log_Transform_Data_For_Fit    = {{'{0}' '1'}};

end




function p = check_parameters( varargin )

S = StructDlg(get_mainsequence_options(),'',[],[],'off');

if ( nargin >=2)
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
    p.addRequired('xdata', @(x)(isnumeric(x)&& length(x)>1)||iscell(x));
    p.addRequired('ydata', @(x)(isnumeric(x)&& length(x)>1)||iscell(x));
    p.addOptional('tit', 'Main sequence', @(x)(isstr(x)||iscell(x)));
    p.addOptional('xlab', 'Amplitude (deg)', @isstr);
    p.addOptional('ylab', 'Velocity (deg/s)', @isstr);
    
    
    p.StructExpand = true;
    p.parse(varargin{:});
    
    
    p = p.Results;
    if ( ~isfield( p, 'S') )
        p.S = S;
    end
else
    throw('at least two parameter are necessary');
end
end
