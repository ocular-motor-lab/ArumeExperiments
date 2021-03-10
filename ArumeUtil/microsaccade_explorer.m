function varargout = microsaccade_explorer(varargin)
% MICROSACCADE_EXPLORER M-file for microsaccade_explorer.fig
% USAGE:
%
% microsaccade_explorer( x, y, usaccs)
% microsaccade_explorer( x, y, usaccs, righ_x, right_y, right_usaccs)
% microsaccade_explorer( x, y, left_eyeflags)
% microsaccade_explorer( x, y, left_eyeflags, righ_x, right_y,
% right_eyeflags)

%      MICROSACCADE_EXPLORER, by itself, creates a new MICROSACCADE_EXPLORER or raises the existing
%      singleton*.
%
%      H = MICROSACCADE_EXPLORER returns the handle to a new
%      MICROSACCADE_EXPLORER or the handle to
%      the existing singleton*.
%
%      MICROSACCADE_EXPLORER('CALLBACK', hObject, eventData, handles, ...)
%      calls the local
%      function named CALLBACK in MICROSACCADE_EXPLORER.M with the given
%      input arguments.
%
%      MICROSACCADE_EXPLORER('Property', 'Value', ...) creates a new MICROSACCADE_EXPLORER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before microsaccade_explorer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to microsaccade_explorer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help microsaccade_explorer

% Last Modified by GUIDE v2.5 02-Jan-2013 13:21:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @microsaccade_explorer_OpeningFcn, ...
    'gui_OutputFcn',  @microsaccade_explorer_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT





% --- Executes just before microsaccade_explorer is made visible.
function microsaccade_explorer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to microsaccade_explorer (see VARARGIN)

% Choose default command line output for microsaccade_explorer

handles.output = hObject;

handles.data.left.x = varargin{1};
handles.data.left.y = varargin{2};
if ( size(varargin{3}, 2) >= 5)
    handles.data.isInTrial = varargin{3}(:, 1);
    handles.data.left.u = varargin{3}(:, 2);
    handles.data.left.b = varargin{3}(:, 3);
    handles.data.left.s = varargin{3}(:, 4);
    if ( size(varargin{3}, 2) >= 7)
        handles.data.left.ovrsht = varargin{3}(:, 6);
        handles.data.left.monoc = varargin{3}(:, 7);
    end
else
    if ( ~isempty(handles.data.left.x)  )
        handles.data.isInTrial = true(size(handles.data.left.x ));
    end
    if ~isempty(varargin{3})
        handles.data.left.u = varargin{3};
    else
        handles.data.left.u = false(size(handles.data.left.x ));
        set(handles.chkPlotMicrosaccades, 'visible', 'off')
    end
    handles.data.left.s = false(size(handles.data.left.x ));
    handles.data.left.b = false(size(handles.data.left.x ));
    handles.data.left.ovrsht = false(size(handles.data.left.x ));
    handles.data.left.monoc = false(size(handles.data.left.x ));
    set(handles.PlotMonoculars, 'visible', 'off')
    set(handles.PlotOvershoot, 'visible', 'off')
    set(handles.PlotSaccades, 'visible', 'off')
end

if ( length(varargin) >=6 )
    if ~isempty(varargin{4})
        handles.data.right.x = varargin{4};
        handles.data.right.y = varargin{5};
    else
        handles.data.right.x = nan(size(handles.data.left.x ));
        handles.data.right.y = nan(size(handles.data.left.x ));
    end
    if ( ~isempty(handles.data.right.x) )&& (~isfield(handles.data, 'isInTrial') || isempty(handles.data.isInTrial ))
        handles.data.isInTrial = true(size(handles.data.right.x ));
    end
    if ( size(varargin{6}, 2) >= 5 )
        handles.data.right.u = varargin{6}(:, 2);
        handles.data.right.b = varargin{6}(:, 3);
        handles.data.right.s = varargin{6}(:, 4);
        set(handles.chkPlotMicrosaccades, 'visible', 'on')
        set(handles.PlotSaccades, 'visible', 'on')
        if ( size(varargin{6}, 2) >= 7)
            handles.data.right.ovrsht = varargin{6}(:, 6);
            handles.data.right.monoc = varargin{6}(:, 7);
            set(handles.PlotMonoculars, 'visible', 'on')
            set(handles.PlotOvershoot, 'visible', 'on')
            if isempty(handles.data.isInTrial )
                handles.data.isInTrial = varargin{6}(:, 1);
            end
        end
        
    else
        if ~isempty(varargin{6})
            handles.data.right.u = varargin{6};
        else
            handles.data.right.u = handles.data.left.u;
        end
        
        handles.data.right.s = false(size(handles.data.left.x ));
        handles.data.right.b = false(size(handles.data.left.x ));
        handles.data.right.ovrsht = false(size(handles.data.left.x ));
        handles.data.right.monoc = false(size(handles.data.left.x ));
    end
end



if ( length(varargin) >= 8 )
    %this is for optional left drift plots
    if ~isempty(varargin{7});
        handles.data.left.xd = varargin{7};
        handles.data.left.yd = varargin{8};
    else
        set(handles.PlotDrift, 'visible', 'off')
    end
end

if ( length(varargin) >= 10 )
    %this is for optional right drift plots
    if ~isempty(varargin{9});
        handles.data.right.xd = varargin{9};
        handles.data.right.yd = varargin{10};
        set(handles.PlotDrift, 'visible', 'on')
    end
end

if ( length(varargin) >= 12 )
    %this is for optional left envelope
    if ~isempty(varargin{11});
        handles.data.left.xenvup = varargin{11};
        handles.data.left.yenvup = varargin{12};
    else
        set(handles.PlotEnvelope, 'visible', 'off')
    end
end

if ( length(varargin) >= 14 )
    %this is for optional right plots
    if ~isempty(varargin{13});
        handles.data.right.xenvup = varargin{13};
        handles.data.right.yenvup = varargin{14};
    end
end

if ( length(varargin) >= 16 )
    %this is for optional left plots
    if ~isempty(varargin{15});
        handles.data.left.xenvdwn = varargin{15};
        handles.data.left.yenvdwn = varargin{16};
    end
end

if ( length(varargin) >= 18 )
    %this is for optional right plots
    if ~isempty(varargin{17});
        handles.data.right.xenvdwn = varargin{17};
        handles.data.right.yenvdwn = varargin{18};
    end
end

if ( length(varargin) >= 19 )
    %this is for optional right plots
    if ~isempty(varargin{19});
        handles.data.peak_trough_or_cntrl_intvl = varargin{19};
        %         handles.data.tr_intvl = varargin{20};
    else
        set(handles.PlotPeakTroughOrControl, 'visible', 'off')
    end
end

if ( length(varargin) >= 21 )
    %this is for optional right plots
    if ~isempty(varargin{20});
        handles.data.pr = varargin{20};
        handles.data.re = varargin{21};
    else
        set(handles.PlotPress, 'visible', 'off')
        set(handles.PlotRelease, 'visible', 'off')
    end
end

if ( length(varargin) >= 22 )
    %this is for optional right plots
    if ~isempty(varargin{22});
        handles.data.left.drift_speed = varargin{22};
    else
        set(handles.PlotDriftSpeed, 'visible', 'off')
    end
    
    if ~isempty(varargin{23});
        handles.data.right.drift_speed = varargin{23};
    end
    
    
end


if ( length(varargin) >= 25 ) && ~isempty(varargin{24})
    %this is for optional right plots
    handles.data.spike_on = varargin{25};
else
    set(handles.plotSpikes, 'visible', 'off')
end




handles = createaxes( handles );
handles.maxSpan = 30;
set(handles.sldSpan, 'value', 1/handles.maxSpan);
if ( ~isempty(handles.data.left.x) )
    set(handles.sldScroll, 'sliderstep', [ 200/length(handles.data.left.x) 1000/length(handles.data.left.x)  ])
else
    set(handles.sldScroll, 'sliderstep', [ 200/length(handles.data.right.x) 1000/length(handles.data.right.x)  ])
end
set(handles.radbutSamplerate1000, 'value', 1)
set(handles.radbutVrange2, 'value', 1)
set(handles.sldSpan, 'Interruptible', 'off')
set(handles.sldScroll, 'Interruptible', 'off')
set(handles.sldScroll, 'busyaction', 'cancel')



if ( length(varargin) >= 24 )
    if ~isempty(varargin{24});
        samplerate = varargin{24};
        set(handles.radbutSamplerate1000, 'value', 0)
        set(handles.radbutSamplerate1000, 'visible', 'off');
        set(handles.radbutSamplerate500, 'value', 0)
        set(handles.radbutSamplerate500, 'visible', 'off')
        set(handles.radbutSamplerate250, 'value', 0)
        set(handles.radbutSamplerate250, 'visible', 'off')
        set(handles.radbutSamplerate2000, 'value', 0)
        set(handles.radbutSamplerate2000, 'visible', 'off')
        
        set(handles.(['radbutSamplerate' sprintf('%0.0f', samplerate)]), 'visible', 'on')
        set(handles.(['radbutSamplerate' sprintf('%0.0f', samplerate)]), 'value', 1)
    end
end

if ~isempty(handles.data.left.x)
    set(handles.PlotLeft, 'value', 1 );
else
    set(handles.PlotLeft, 'value', 0 );
    
end
if isfield(handles.data, 'right') && ~isempty(handles.data.right.x)
    set(handles.PlotRight, 'value', 1 );
else
    set(handles.PlotRight, 'value', 0);
end
set(handles.PlotRaw, 'value', 1 );


handles = mainplot( handles);

handles.output = handles.fig.mainfig;

% handles.colors = CorrGui.get_nice_colors;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes microsaccade_explorer wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = microsaccade_explorer_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function handles = createaxes( handles )


handles.fig.mainfig = figure('color', 'white', 'Renderer', 'painters', 'position', [500 100 1000 400]);
handles.fig.axx = axes('position', [.05 .55 .7 .44], 'box', 'off', 'Drawmode', 'fast', 'fontsize', 16);
handles.fig.axy = axes('position', [.05 .06 .7 .44], 'box', 'off', 'Drawmode', 'fast', 'fontsize', 16);
xlabel(handles.fig.axy, 'Time (ms)', 'fontsize', 20);
ylabel(handles.fig.axx, 'Horizontal Position (degrees visual angle)', 'fontsize', 20);
xlabel(handles.fig.axx, 'Time (ms)', 'fontsize', 20);
ylabel(handles.fig.axy, 'Vertical Position (degrees visual angle)', 'fontsize', 20);
handles.fig.axxy = axes('position', [.8 .55 .23 .44], 'Drawmode', 'fast', 'fontsize', 8);
handles.fig.axxyv = axes('position', [.8 .06 .19 .44], 'Drawmode', 'fast', 'fontsize', 8);

ManAxMode(handles.fig.axx)
ManAxMode(handles.fig.axy)


set(handles.fig.axx, 'ButtonDownFcn', @press)

function press(hObject, eventdata, handles)

% point = get(hObject, 'CurrentPoint');
%
% set(findobj(hObject, 'Type', 'text'), 'position', [point(1, 1), point(1, 2) 0], 'string', 'hi', 'visible', 'on');

% ManAxMode(handles.fig.axx);
% ManAxMode(handles.fig.axy);

function handles = mainplot( handles )

if ( ~ishandle(handles.fig.mainfig) )
    handles = createaxes( handles );
end

colors = CorrGui.get_nice_colors;
left_data_color = [.5 .5 .5];
right_data_color = [0 0 0 ];
% left_data_color = [.1 .1 .1];
% right_data_color = [.4 0 .4];
usacc_color = colors.DARK_GREEN;
usacc_height = 2;
usacc_linewidth = 2;

blink_color = [0 0 0];
% blink_color = [.5 .5 .5];
blink_height = .7;
blink_linewidth = 1;

monoc_color = [.2 .3 .9];
monoc_height = 1.5;

saccade_color = colors.MEDIUM_BROWN;
saccade_height = 2.5;
sacc_linewidth = 2;

overshoot_color = colors.MEDIUM_PINK;
overshoot_height = 1.5;

drift_color = [.2 .9 .2];
drift_linewidth = 3;

envlp_color = colors.DARK_KHAKI;

pk_color = colors.ROYAL_PURPLE;
pk_height = 1.5;
pk_linewidth = 4;

pr_color = colors.MEDIUM_BLUE;
pr_height = .5;
pr_linewidth = 1.5;

re_color = colors.MEDIUM_RED;
re_height = 1;
re_linewidth = 1.5;


drift_speed_color = colors.DARK_GREEN;
drift_speed_linewidth =2;

spike_color = [0 0 0];
spike_on_height = 1;

%INITIATE LINE HANDLES
if ~isfield(handles, 'lines')
    
    % lines for the horizontal component plot for left
    axes(handles.fig.axx);%%%%%%%%%%% HORIZONTAL AXES
    
    %microsaccades (if we have left, the use left)
    if ~isempty( handles.data.left.u)
        handles.lines.left.xu   = line([0 1], [0 1], 'color', usacc_color, 'linewidth', usacc_linewidth);
        set(get(get(handles.lines.left.xu , 'Annotation'), 'LegendInformation'), ...
            'IconDisplayStyle', 'off');
    else %if no left data, then use the right data
        
        handles.lines.right.xu   = line([0 1], [0 1], 'color', usacc_color, 'linewidth', usacc_linewidth);
        set(get(get(handles.lines.right.xu , 'Annotation'), 'LegendInformation'), ...
            'IconDisplayStyle', 'off');
    end
    
    %left horizontal in trial
    if ~isempty( handles.data.left.x)
        handles.lines.left.x    = line([0 1], [0 1], 'color', left_data_color);
        
        %left horizontal not in trial
        handles.lines.left.xx   = line([0 1], [0 1], 'linestyle', ':', 'color', left_data_color);
        set(get(get(handles.lines.left.xx , 'Annotation'), 'LegendInformation'), ...
            'IconDisplayStyle', 'off');
    end
    
    %saccades
    if  ~isempty( handles.data.left.s)%(if we have left, the use left)
        handles.lines.left.xs   = line([0 1], [0 1], 'color', saccade_color, 'linewidth', sacc_linewidth);
        set(get(get( handles.lines.left.xs  , 'Annotation'), 'LegendInformation'), ...
            'IconDisplayStyle', 'off');
    else %if no left data, then use the right data
        handles.lines.right.xs   = line([0 1], [0 1], 'color', saccade_color, 'linewidth', sacc_linewidth);
        set(get(get( handles.lines.right.xs  , 'Annotation'), 'LegendInformation'), ...
            'IconDisplayStyle', 'off');
    end
    
    %blinks
    if  ~isempty( handles.data.left.b)
        handles.lines.left.xb   = line([0 1], [0 1], 'color', blink_color, 'linewidth', blink_linewidth);
        set(get(get( handles.lines.left.xb , 'Annotation'), 'LegendInformation'), ...
            'IconDisplayStyle', 'off');
    else
        handles.lines.right.xb   = line([0 1], [0 1], 'color', blink_color, 'linewidth', blink_linewidth);
        set(get(get( handles.lines.right.xb , 'Annotation'), 'LegendInformation'), ...
            'IconDisplayStyle', 'off');
    end
    
    %overshoots
    if  ~isempty( handles.data.left.ovrsht)
        handles.lines.left.xos   = line([0 1], [0 1], 'color', overshoot_color);
        set(get(get( handles.lines.left.xos , 'Annotation'), 'LegendInformation'), ...
            'IconDisplayStyle', 'off');
    end
    
    if  isfield(handles.data,'right') && ~isempty( handles.data.right.ovrsht)
        handles.lines.right.xos   = line([0 1], [0 1], 'color', overshoot_color);
        set(get(get( handles.lines.right.xos , 'Annotation'), 'LegendInformation'), ...
            'IconDisplayStyle', 'off');
    end
    
    
    %%%Put LEFT MONOCULARS in the horizontal component
    if  ~isempty( handles.data.left.monoc)
        handles.lines.left.xmon  = line([0 1], [0 1], 'color', monoc_color);
        set(get(get( handles.lines.left.xmon , 'Annotation'), 'LegendInformation'), ...
            'IconDisplayStyle', 'off');
    end
    
    
    
    if isfield(handles.data.left, 'xd')
        %drift
        handles.lines.left.xd   = line([0 1], [0 1], 'linestyle', '-', 'color', drift_color, 'linewidth', drift_linewidth);
        
    end
    if isfield(handles.data.left, 'drift_speed')
        %drift
        handles.lines.left.drift_speed   = line([0 1], [0 1], 'linestyle', '-', 'color', drift_speed_color, 'linewidth', drift_speed_linewidth);
        
    end
    if isfield(handles.data.left, 'xenvup')
        %envelope
        handles.lines.left.xenvup   = line([0 1], [0 1], 'linestyle', '-', 'color', envlp_color);
    end
    if isfield(handles.data.left, 'xenvdwn')
        %envelope
        handles.lines.left.xenvdwn   = line([0 1], [0 1], 'linestyle', '-', 'color', envlp_color);
    end
    
    
    % lines for the horizontal component right in trial
    if isfield( handles.data,'right') && ~isempty( handles.data.right.x)
        handles.lines.right.x    = line([0 1], [0 1], 'color', right_data_color);
        
        % lines for the horizontal component right out of trial
        handles.lines.right.xx   = line([0 1], [0 1], 'linestyle', ':', 'color', right_data_color);
        set(get(get(handles.lines.right.xx   , 'Annotation'), 'LegendInformation'), ...
            'IconDisplayStyle', 'off');
    end
    
    
    if isfield( handles.data,'right') && isfield(handles.data.right, 'xd')
        %drift
        handles.lines.right.xd   = line([0 1], [0 1], 'linestyle', '-', 'color', drift_color, 'linewidth', drift_linewidth);
    end
    
    if isfield( handles.data,'right') && isfield(handles.data.right, 'xenvup')
        %envelope
        handles.lines.right.xenvup   = line([0 1], [0 1], 'linestyle', '-', 'color', envlp_color);
    end
    if isfield( handles.data,'right') && isfield(handles.data.right, 'xenvdwn')
        %envelope
        handles.lines.right.xenvdwn   = line([0 1], [0 1], 'linestyle', '-', 'color', envlp_color);
    end
    
    %presses releases and peak/trough interval
    if isfield(handles.data, 'peak_trough_or_cntrl_intvl')
        handles.lines.peak_trough_or_cntrl_intvl   = line([0 1], [0 1], 'linestyle', '-', 'color', pk_color, 'linewidth', pk_linewidth);
    end
    
    if isfield(handles.data, 'pr')
        handles.lines.pr   = line([0 1], [0 1], 'linestyle', ':', 'color', pr_color, 'linewidth', pr_linewidth);
    end
    
    if isfield(handles.data, 're')
        handles.lines.re   = line([0 1], [0 1], 'linestyle', ':', 'color', re_color, 'linewidth', re_linewidth);
    end
    %%%%%%%%%%% END HORIZONTAL AXES
    
    handles.text.horu = text(1, 1, ' ', 'visible', 'off');
    
    % lines for the vertical component plot for left
    axes(handles.fig.axy); %%%%%%%%%%% VERTICAL AXES
    if ~isempty( handles.data.left.u)
        handles.lines.left.yu = line([0 1], [0 1], 'color', usacc_color);
    else
        handles.lines.right.yu = line([0 1], [0 1], 'color', usacc_color);
    end
    
    if ~isempty( handles.data.left.x)
        %this is the part thats in trial
        handles.lines.left.y = line([0 1], [0 1], 'color', left_data_color);
        
        %this is for the part thats not in trial
        handles.lines.left.yy = line([0 1], [0 1], 'linestyle', ':', 'color', left_data_color);
    end
    
    if isfield(handles.data.left, 'yd')
        handles.lines.left.yd   = line([0 1], [0 1], 'linestyle', '-', 'color', drift_color, 'linewidth', drift_linewidth);
    end
    if isfield(handles.data.left, 'yenvup')
        handles.lines.left.yenvup   = line([0 1], [0 1], 'linestyle', '-', 'color', envlp_color);
    end
    if isfield(handles.data.left, 'yenvdwn')
        handles.lines.left.yenvdwn   = line([0 1], [0 1], 'linestyle', '-', 'color', envlp_color);
    end
    if isfield( handles.data,'right') && isfield(handles.data.right, 'drift_speed')
        %drift
        handles.lines.right.drift_speed   = line([0 1], [0 1], 'linestyle', '-', 'color', drift_speed_color, 'linewidth', drift_speed_linewidth);
        
    end
    
    % lines for the vertical component plot for right
    if isfield( handles.data,'right') && ~isempty( handles.data.right.x)
        
        %this is the part thats in trial
        handles.lines.right.y = line([0 1], [0 1], 'color', right_data_color);
        
        %this is for the part thats not in trial
        handles.lines.right.yy = line([0 1], [0 1], 'linestyle', ':', 'color', right_data_color);
    end
    
    %%%Put RIGHT MONOCULARS in the vertical component
    if isfield( handles.data,'right') && ~isempty( handles.data.right.monoc)
        handles.lines.right.ymon  = line([0 1], [0 1], 'color', monoc_color);
    end
    
    if isfield( handles.data,'right') && isfield(handles.data.right, 'yd')
        handles.lines.right.yd   = line([0 1], [0 1], 'linestyle', '-', 'color', drift_color, 'linewidth', drift_linewidth);
    end
    if isfield( handles.data,'right') && isfield(handles.data.right, 'yenvup')
        handles.lines.right.yenvup   = line([0 1], [0 1], 'linestyle', '-', 'color', envlp_color);
    end
    if isfield( handles.data,'right') && isfield(handles.data.right, 'yenvdwn')
        handles.lines.right.yenvdwn   = line([0 1], [0 1], 'linestyle', '-', 'color', envlp_color);
    end
    
     if isfield(handles.data, 'spike_on')
        handles.lines.spike_on   = line([0 1], [0 1], 'linestyle', '-', 'color', spike_color);
    end
    
    
    
    %%%%%%%%%%% END VERTICAL AXES
    
    
    % lines for the x-y position plot
    axes(handles.fig.axxy);
    if ~isempty( handles.data.left.x)
        handles.lines.left.xy = line([0 1], [0 1], 'color', left_data_color);
        handles.lines.left.xyu = line([0 1], [0 1], 'color', [.8 0 0], 'linewidth', 2);
    end
    if isfield( handles.data,'right') && ~isempty( handles.data.right.x)
        handles.lines.right.xy = line([0 1], [0 1], 'color', right_data_color);
        handles.lines.right.xyu = line([0 1], [0 1], 'color', [.8 0 0], 'linewidth', 2);
    end
    
    % lines for the x-y velocity plot
    axes(handles.fig.axxyv);
    if ~isempty( handles.data.left.x)
        handles.lines.left.xyv = line([0 1], [0 1], 'color', left_data_color);
        handles.lines.left.xyvu = line([0 1], [0 1], 'color', [.8 0 0], 'linewidth', 2);
    end
    if isfield( handles.data,'right') && ~isempty( handles.data.right.x)
        handles.lines.right.xyv = line([0 1], [0 1], 'color', right_data_color);
        handles.lines.right.xyvu = line([0 1], [0 1], 'color', [.8 0 0], 'linewidth', 2);
    end
end

set(handles.text.horu, 'visible', 'off');
%%
samplerate = get_current_samplerate(handles);


if get(handles.radbutVrange1, 'value')
    vrange = 1;
elseif get(handles.radbutVrange2, 'value')
    vrange = 2;
elseif get(handles.radbutVrange5, 'value')
    vrange = 5;
elseif get(handles.radbutVrange10, 'value')
    vrange = 10;
elseif get(handles.radbutVrange025, 'value')
    vrange = .25;
elseif get(handles.radbutVrange05, 'value')
    vrange = .5;
elseif get(handles.radbutVrange075, 'value')
    vrange = .75;
elseif get(handles.radbutVrange20, 'value')
    vrange = 20;
end

%%
span    = floor(get(handles.sldSpan, 'value')*handles.maxSpan*samplerate);
if ~isempty(handles.data.left.x)
    scroll  = max(floor(get(handles.sldScroll, 'value') * length(handles.data.left.x)), 1);
else
    scroll  = max(floor(get(handles.sldScroll, 'value') * length(handles.data.right.x)), 1);
end

set(handles.txtGoTo, 'string', num2str(scroll/samplerate));
idx = (0:span)+scroll;
plot_idx = 1000/samplerate*(idx-idx(1));

if (~isempty(handles.data.left.x ) )
    set(handles.PlotLeft, 'value', 1);
    if isfield( handles.data,'right') && isempty(handles.data.right.x)
        set(handles.PlotRight, 'value', 0);
    end
    meanx = nanmean(handles.data.left.x(idx));
    meany = nanmean(handles.data.left.y(idx));
else
    set(handles.PlotLeft, 'value', 0);
    set(handles.PlotRight, 'value', 1);
    meanx = nanmean(handles.data.right.x(idx));
    meany = nanmean(handles.data.right.y(idx));
end



%presses releases and peak/trough interval
if isfield(handles.data, 'peak_trough_or_cntrl_intvl')
    if ( get(handles.PlotPeakTroughOrControl, 'value') )
        set(handles.lines.peak_trough_or_cntrl_intvl, 'visible', 'on');
        set(handles.lines.peak_trough_or_cntrl_intvl, 'xdata', plot_idx, 'ydata', handles.data.peak_trough_or_cntrl_intvl(idx)*pk_height -1.8 + meanx);
    else
        set(handles.lines.peak_trough_or_cntrl_intvl, 'visible', 'off');
    end
end

if isfield(handles.data, 'pr')
    if ( get(handles.PlotPress, 'value') )
        set(handles.lines.pr, 'visible', 'on');
        set(handles.lines.pr, 'xdata', plot_idx, 'ydata', handles.data.pr(idx)*pr_height -1.8 + meanx);
    else
        set(handles.lines.pr, 'visible', 'off');
    end
end


if isfield(handles.data, 're')
    if ( get(handles.PlotRelease, 'value') )
        set(handles.lines.re, 'visible', 'on');
        set(handles.lines.re, 'xdata', plot_idx, 'ydata', handles.data.re(idx)*re_height -1.8 + meanx);
    else
        set(handles.lines.re, 'visible', 'off');
    end
end

if isfield(handles.data, 'spike_on')
    if ( get(handles.plotSpikes, 'value') )
        set(handles.lines.spike_on, 'visible', 'on');
        set(handles.lines.spike_on, 'xdata', plot_idx, 'ydata', handles.data.spike_on(idx)*spike_on_height -1.8 + meanx);
    else
        set(handles.lines.spike_on, 'visible', 'off');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%LEFT PLOTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ( get(handles.PlotLeft, 'value') ) && ~isempty(handles.data.left)
    
    % microsaccades
    if ( get(handles.chkPlotMicrosaccades, 'value') )
        set(handles.lines.left.xu, 'visible', 'on');
        set(handles.lines.left.yu, 'visible', 'on');
        set(handles.lines.left.xu, 'xdata', plot_idx, 'ydata', handles.data.left.u(idx)*usacc_height -1.8 + meanx);
        set(handles.lines.left.yu, 'xdata', plot_idx, 'ydata', handles.data.left.u(idx)*usacc_height -1.8 + meany);
    else
        set(handles.lines.left.xu, 'visible', 'off');
        set(handles.lines.left.yu, 'visible', 'off');
    end
    
    % saccades
    if ( get(handles.PlotSaccades, 'value') )
        set(handles.lines.left.xs, 'visible', 'on');
        set(handles.lines.left.xs, 'xdata', plot_idx, 'ydata', handles.data.left.s(idx)*saccade_height -1.8 + meanx);
    else
        set(handles.lines.left.xs, 'visible', 'off');
    end
    
    % blinks
    if ( get(handles.PlotBlinks, 'value') )
        set(handles.lines.left.xb, 'visible', 'on');
        set(handles.lines.left.xb, 'xdata', plot_idx, 'ydata', handles.data.left.b(idx)*blink_height -1.8 + meanx);
    else
        set(handles.lines.left.xb, 'visible', 'off');
    end
    
    % overshoots
    if ( get(handles.PlotOvershoot, 'value') )
        set(handles.lines.left.xos, 'visible', 'on');
        set(handles.lines.left.xos, 'xdata', plot_idx, 'ydata', handles.data.left.ovrsht(idx)*overshoot_height -1.8 + meanx);
    else
        set(handles.lines.left.xos, 'visible', 'off');
    end
    
    % monoculars (left monoculars in the horizontal and right monoculars in the
    % vertical)
    if ( get(handles.PlotMonoculars, 'value') )
        set(handles.lines.left.xmon, 'visible', 'on');
        set(handles.lines.left.xmon, 'xdata', plot_idx, 'ydata', handles.data.left.monoc(idx)*monoc_height -1.8 + meanx);
    else
        set(handles.lines.left.xmon, 'visible', 'off');
    end
    
    
    % Left Drift and envelope
    if isfield(handles.data.left, 'xd')
        if ( get(handles.PlotDrift, 'value') )
            set(handles.lines.left.xd, 'visible', 'on');
            set(handles.lines.left.yd, 'visible', 'on');
            set(handles.lines.left.xd, 'xdata', plot_idx, 'ydata', handles.data.left.xd(idx));
            set(handles.lines.left.yd, 'xdata', plot_idx, 'ydata', handles.data.left.yd(idx));
        else
            set(handles.lines.left.xd, 'visible', 'off');
            set(handles.lines.left.yd, 'visible', 'off');
        end
    end
    if isfield(handles.data.left, 'drift_speed')
        if ( get(handles.PlotDriftSpeed, 'value') )
            set(handles.lines.left.drift_speed, 'visible', 'on');
            set(handles.lines.left.drift_speed, 'xdata', plot_idx, 'ydata', handles.data.left.drift_speed(idx));
        else
            set(handles.lines.left.drift_speed, 'visible', 'off');
        end
    end
    if isfield(handles.data.left, 'xenvup')
        if ( get(handles.PlotEnvelope, 'value') )
            set(handles.lines.left.xenvup, 'visible', 'on');
            set(handles.lines.left.xenvup, 'xdata', plot_idx, 'ydata', handles.data.left.xenvup(idx));
        else
            set(handles.lines.left.xenvup, 'visible', 'off');
        end
    end
    if isfield(handles.data.left, 'xenvdwn')
        if ( get(handles.PlotEnvelope, 'value') )
            set(handles.lines.left.xenvdwn, 'visible', 'on');
            set(handles.lines.left.xenvdwn, 'xdata', plot_idx, 'ydata', handles.data.left.xenvdwn(idx));
        else
            set(handles.lines.left.xenvdwn, 'visible', 'off');
        end
    end
    if isfield(handles.data.left, 'yenvup')
        if ( get(handles.PlotEnvelope, 'value') )
            set(handles.lines.left.yenvup, 'visible', 'on');
            set(handles.lines.left.yenvup, 'xdata', plot_idx, 'ydata', handles.data.left.yenvup(idx));
        else
            set(handles.lines.left.yenvup, 'visible', 'off');
        end
    end
    if isfield(handles.data.left, 'yenvdwn')
        if ( get(handles.PlotEnvelope, 'value') )
            set(handles.lines.left.yenvdwn, 'visible', 'on');
            set(handles.lines.left.yenvdwn, 'xdata', plot_idx, 'ydata', handles.data.left.yenvdwn(idx));
        else
            set(handles.lines.left.yenvdwn, 'visible', 'off');
        end
    end
    
    
    if ( get(handles.PlotRaw, 'value') )
        
        set(handles.lines.left.y, 'visible', 'on');
        set(handles.lines.left.yy, 'visible', 'on');
        set(handles.lines.left.x, 'visible', 'on');
        set(handles.lines.left.xx, 'visible', 'on');
        
        
        
        xinTrial = handles.data.left.x(idx);
        xoutTrial = handles.data.left.x(idx);
        
        xinTrial(~handles.data.isInTrial(idx)) = NaN;
        xoutTrial(handles.data.isInTrial(idx)) = NaN;
        
        set(handles.lines.left.x, 'xdata', plot_idx, 'ydata', xinTrial);
        set(handles.lines.left.xx, 'xdata', plot_idx, 'ydata', xoutTrial);
        
        
        yinTrial = handles.data.left.y(idx);
        youtTrial = handles.data.left.y(idx);
        
        yinTrial(~handles.data.isInTrial(idx)) = NaN;
        youtTrial(handles.data.isInTrial(idx)) = NaN;
        
        set(handles.lines.left.y, 'xdata', plot_idx, 'ydata', yinTrial);
        set(handles.lines.left.yy, 'xdata', plot_idx, 'ydata', youtTrial);
        
    else
        set(handles.lines.left.y, 'visible', 'off');
        set(handles.lines.left.yy, 'visible', 'off');
        set(handles.lines.left.x, 'visible', 'off');
        set(handles.lines.left.xx, 'visible', 'off');
        
    end
    
else
    if isfield(handles.lines, 'left')
        change_visiblity(handles.lines.left, 'off')
    end
    
end
%%%%%%%%%%%%%%%%%%%%%%%% END LEFT PLOTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%% RIGHT PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ( get(handles.PlotRight, 'value') )
    
    %if no left data, then use right data for microsaccades, saccades and
    %blinks
    % saccades
    if isempty(handles.data.left.x)
        
        %microsaccades
        if ( get(handles.chkPlotMicrosaccades, 'value') )
            set(handles.lines.right.xu, 'visible', 'on');
            set(handles.lines.right.yu, 'visible', 'on');
            set(handles.lines.right.xu, 'xdata', plot_idx, 'ydata', handles.data.right.u(idx)*usacc_height -1.8 + meanx);
            set(handles.lines.right.yu, 'xdata', plot_idx, 'ydata', handles.data.right.u(idx)*usacc_height -1.8 + meany);
        else
            set(handles.lines.right.xu, 'visible', 'off');
            set(handles.lines.right.yu, 'visible', 'off');
        end
        
        %saccades
        if ( get(handles.PlotSaccades, 'value') )
            set(handles.lines.right.xs, 'visible', 'on');
            set(handles.lines.right.xs, 'xdata', plot_idx, 'ydata', handles.data.right.s(idx)*saccade_height -1.8 + meanx);
        else
            set(handles.lines.right.xs, 'visible', 'off');
        end
        
        % blinks
        if ( get(handles.PlotBlinks, 'value') )
            set(handles.lines.right.xb, 'visible', 'on');
            set(handles.lines.right.xb, 'xdata', plot_idx, 'ydata', handles.data.right.b(idx)*blink_height -1.8 + meanx);
        else
            set(handles.lines.right.xb, 'visible', 'off');
        end
        
        % overshoots
        if ( get(handles.PlotOvershoot, 'value') )
            set(handles.lines.right.xos, 'visible', 'on');
            set(handles.lines.right.xos, 'xdata', plot_idx, 'ydata', handles.data.right.ovrsht(idx)*overshoot_height -1.8 + meanx);
        else
            set(handles.lines.right.xos, 'visible', 'off');
        end
        
    end
    
    
    % Right Drift and envelope
    if isfield(handles.data.right, 'xd')
        if ( get(handles.PlotDrift, 'value') )
            set(handles.lines.right.xd, 'visible', 'on');
            set(handles.lines.right.yd, 'visible', 'on');
            set(handles.lines.right.xd, 'xdata', plot_idx, 'ydata', handles.data.right.xd(idx));
            set(handles.lines.right.yd, 'xdata', plot_idx, 'ydata', handles.data.right.yd(idx));
        else
            set(handles.lines.right.xd, 'visible', 'off');
            set(handles.lines.right.yd, 'visible', 'off');
        end
    end
    if isfield(handles.data.right, 'drift_speed')
        if ( get(handles.PlotDriftSpeed, 'value') )
            set(handles.lines.right.drift_speed , 'visible', 'on');
            set(handles.lines.right.drift_speed, 'xdata', plot_idx, 'ydata', handles.data.right.drift_speed(idx));
        else
            set(handles.lines.right.drift_speed, 'visible', 'off');
        end
    end
    if isfield(handles.data.right, 'xenvup')
        if ( get(handles.PlotEnvelope, 'value') )
            set(handles.lines.right.xenvup, 'visible', 'on');
            set(handles.lines.right.xenvup, 'xdata', plot_idx, 'ydata', handles.data.right.xenvup(idx));
        else
            set(handles.lines.right.xenvup, 'visible', 'off');
        end
    end
    if isfield(handles.data.right, 'xenvdwn')
        if ( get(handles.PlotEnvelope, 'value') )
            set(handles.lines.right.xenvdwn, 'visible', 'on');
            set(handles.lines.right.xenvdwn, 'xdata', plot_idx, 'ydata', handles.data.right.xenvdwn(idx));
        else
            set(handles.lines.right.xenvdwn, 'visible', 'off');
        end
    end
    if isfield(handles.data.right, 'yenvup')
        if ( get(handles.PlotEnvelope, 'value') )
            set(handles.lines.right.yenvup, 'visible', 'on');
            set(handles.lines.right.yenvup, 'xdata', plot_idx, 'ydata', handles.data.right.yenvup(idx));
        else
            set(handles.lines.right.yenvup, 'visible', 'off');
        end
    end
    if isfield(handles.data.right, 'yenvdwn')
        if ( get(handles.PlotEnvelope, 'value') )
            set(handles.lines.right.yenvdwn, 'visible', 'on');
            set(handles.lines.right.yenvdwn, 'xdata', plot_idx, 'ydata', handles.data.right.yenvdwn(idx));
        else
            set(handles.lines.right.yenvdwn, 'visible', 'off');
        end
    end
    % monoculars (left monoculars in the horizontal and right monoculars in the
    % vertical)
    if ( get(handles.PlotMonoculars, 'value') )
        set(handles.lines.right.ymon, 'visible', 'on');
        set(handles.lines.right.ymon, 'xdata', plot_idx, 'ydata', handles.data.right.monoc(idx)*monoc_height -1.8 + mean(handles.data.right.y(idx)));
    else
        set(handles.lines.right.ymon, 'visible', 'off');
    end
    
    if ( get(handles.PlotRaw, 'value') )
        
        
        %Horizontal raw
        if ( isfield( handles.data, 'right'))
            
            set(handles.lines.right.y, 'visible', 'on');
            set(handles.lines.right.yy, 'visible', 'on');
            set(handles.lines.right.x, 'visible', 'on');
            set(handles.lines.right.xx, 'visible', 'on');
            
            xinTrial = handles.data.right.x(idx);
            xoutTrial = handles.data.right.x(idx);
            xinTrial(~handles.data.isInTrial(idx)) = NaN;
            xoutTrial(handles.data.isInTrial(idx)) = NaN;
            set(handles.lines.right.x, 'xdata', plot_idx, 'ydata', xinTrial);
            set(handles.lines.right.xx, 'xdata', plot_idx, 'ydata', xoutTrial);
            
            
            
            %Vertical Raw
            yinTrial = handles.data.right.y(idx);
            youtTrial = handles.data.right.y(idx);
            yinTrial(~handles.data.isInTrial(idx)) = NaN;
            youtTrial(handles.data.isInTrial(idx)) = NaN;
            set(handles.lines.right.y, 'xdata', plot_idx, 'ydata', yinTrial);
            set(handles.lines.right.yy, 'xdata', plot_idx, 'ydata', youtTrial);
        end
        
    else
        if ( isfield( handles.data, 'right'))
            set(handles.lines.right.y, 'visible', 'off');
            set(handles.lines.right.yy, 'visible', 'off');
            set(handles.lines.right.x, 'visible', 'off');
            set(handles.lines.right.xx, 'visible', 'off');
            
        end
        
    end
else
    if ( isfield( handles.data, 'right'))
        change_visiblity(handles.lines.right, 'off')
    end
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END RIGHT PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%


% set limits

%  horizontal raw
ylim = [-vrange vrange] + meanx;
set(handles.fig.axx, 'xlim', 1000/samplerate*([idx(1) idx(end)]-idx(1)), 'ylim', ylim);


% vertical raw
ylim = [-vrange vrange] + meany;
set(handles.fig.axy, 'xlim', 1000/samplerate*([idx(1) idx(end)]-idx(1)), 'ylim', ylim);





%% x-y plot
if ( isfield( handles.data, 'left') && ~isempty( handles.data.left.x ) )
    xlim = [-vrange vrange] + Means(handles.data.left.x((0:span)+scroll));
    ylim = [-vrange vrange] + Means(handles.data.left.y((0:span)+scroll));
    set(handles.fig.axxy, 'xlim', xlim, 'ylim', ylim);
    
    
    x = medfilt1(handles.data.left.x((0:1000)+scroll), 3);
    y = medfilt1(handles.data.left.y((0:1000)+scroll), 3);
    set(handles.lines.left.xy, 'xdata', x, 'ydata', y);
    x(~handles.data.left.u((0:1000)+scroll)) = NaN;
    y(~handles.data.left.u((0:1000)+scroll)) = NaN;
    set(handles.lines.left.xyu, 'xdata',  x, 'ydata', y );
end

% right eye
if ( isfield( handles.data, 'right') && ~isempty( handles.data.right.x ) && ~sum(isnan(handles.data.right.x)) )
    xlim = [-vrange vrange] + Means(handles.data.right.x((0:span)+scroll));
    ylim = [-vrange vrange] + Means(handles.data.right.y((0:span)+scroll));
    set(handles.fig.axxy, 'xlim', xlim, 'ylim', ylim);
    x = medfilt1(handles.data.right.x((0:1000)+scroll), 3);
    y = medfilt1(handles.data.right.y((0:1000)+scroll), 3);
    set(handles.lines.right.xy, 'xdata', x, 'ydata', y);
    x(~handles.data.right.u((0:1000)+scroll)) = NaN;
    y(~handles.data.right.u((0:1000)+scroll)) = NaN;
    set(handles.lines.right.xyu, 'xdata',  x, 'ydata', y );
end

%% x-y velocity plot

set(handles.fig.axxyv, 'xlim', [-100 100], 'ylim', [-100 100]);


if ( isfield( handles.data, 'left') && ~isempty( handles.data.left.x ) )
    v = engbert_vecvel([handles.data.left.x((0:1000)+scroll) handles.data.left.y((0:1000)+scroll)], 1000, 2);
    x = v(:, 1);
    y = v(:, 2);
    set(handles.lines.left.xyv, 'xdata', x, 'ydata', y);
    x(~handles.data.left.u((0:1000)+scroll)) = NaN;
    y(~handles.data.left.u((0:1000)+scroll)) = NaN;
    set(handles.lines.left.xyvu, 'xdata',  x, 'ydata', y );
end
% right eye
if ( isfield( handles.data, 'right'))
    
    v = engbert_vecvel([handles.data.right.x((0:1000)+scroll) handles.data.right.y((0:1000)+scroll)], 1000, 2);
    x = v(:, 1);
    y = v(:, 2);
    set(handles.lines.right.xyv, 'xdata', x, 'ydata', y);
    x(~handles.data.right.u((0:1000)+scroll)) = NaN;
    y(~handles.data.right.u((0:1000)+scroll)) = NaN;
    set(handles.lines.right.xyvu, 'xdata',  x, 'ydata', y );
end


drawnow

function handles = oneplot(handles, ax, xl, xxl, x, ul, u, isInTrial)


set(handles.fig.axxyv, 'xlim', [-100 100], 'ylim', [-100 100]);


set(ul, 'xdata', (0:span)+scroll, 'ydata', u((0:span)+scroll)*3.6 -1.8 + Means(x((0:span)+scroll)));


if ( exist('isInTrial'))
    
    [b, a] = butter(10, 100/1000);
    
    
    xinTrial = x((0:span)+scroll);
    xoutTrial = x((0:span)+scroll);
    isIn = isInTrial((0:span)+scroll);
    xinTrial(~isIn) = NaN;
    xoutTrial(isIn) = NaN;
    set(xl, 'xdata', (0:span)+scroll, 'ydata', xinTrial);
    set(xxl, 'xdata', (0:span)+scroll, 'ydata', xoutTrial);
    
    xu = medfilt1(handles.data.lx((0:1000)+scroll), 3);
    yu = medfilt1(handles.data.ly((0:1000)+scroll), 3);
    set(handles.fig.xyline, 'xdata', xu, 'ydata', yu);
    uu = u((0:1000)+scroll);
    xu(~uu) = NaN;
    yu(~uu) = NaN;
    set(handles.fig.xyuline, 'xdata',  xu, 'ydata', yu );
    
    xu = medfilt1(handles.data.rx((0:1000)+scroll), 3);
    yu = medfilt1(handles.data.ry((0:1000)+scroll), 3);
    set(handles.fig.xyrline, 'xdata', xu, 'ydata', yu );
    uu = u((0:1000)+scroll);
    xu(~uu) = NaN;
    yu(~uu) = NaN;
    set(handles.fig.xyruline, 'xdata',  xu, 'ydata', yu );
    
    
    v = engbert_vecvel([handles.data.lx((0:1000)+scroll) handles.data.ly((0:1000)+scroll)], 1000, 2);
    xu = v(:, 1);
    yu = v(:, 2);
    set(handles.fig.xyvline, 'xdata', xu, 'ydata', yu);
    uu = u((0:1000)+scroll);
    xu(~uu) = NaN;
    yu(~uu) = NaN;
    set(handles.fig.xyvuline, 'xdata',  xu, 'ydata', yu );
    
    v = engbert_vecvel([handles.data.rx((0:1000)+scroll) handles.data.ry((0:1000)+scroll)], 1000, 2);
    xu = v(:, 1);
    yu = v(:, 2);
    set(handles.fig.xyvrline, 'xdata', xu, 'ydata', yu );
    uu = u((0:1000)+scroll);
    xu(~uu) = NaN;
    yu(~uu) = NaN;
    set(handles.fig.xyvruline, 'xdata',  xu, 'ydata', yu );
else
    set(xl, 'xdata', (0:span)+scroll, 'ydata', x((0:span)+scroll));
end

% u = handles.data.lu((0:span)+scroll);
% ustart = find(diff([0;u])>0);
% ustop = find(diff([u;0])<0);
% axes(ax)
% for i=1:length(ustart)
%     text(ustart(i), yl(2), 'hi')
% end


% --- Executes on slider movement.
function sldSpan_Callback(hObject, eventdata, handles)
% hObject    handle to sldSpan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject, 'Value') returns position of slider
%        get(hObject, 'Min') and get(hObject, 'Max') to determine range of slider
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function sldSpan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldSpan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', [.9 .9 .9]);
end


% --- Executes on slider movement.
function sldScroll_Callback(hObject, eventdata, handles)
% hObject    handle to sldScroll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject, 'Value') returns position of slider
%        get(hObject, 'Min') and get(hObject, 'Max') to determine range of slider
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function sldScroll_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldScroll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', [.9 .9 .9]);
end


% --- Executes on button press in butSpan1.
function butSpan1_Callback(hObject, eventdata, handles)
% hObject    handle to butSpan1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.sldSpan, 'value', 1/handles.maxSpan);
handles = mainplot( handles );

handles = change_slider_step(handles, 1);


% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in butSpan2.
function butSpan2_Callback(hObject, eventdata, handles)
% hObject    handle to butSpan2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.sldSpan, 'value', 2/handles.maxSpan);
handles = mainplot( handles );

handles = change_slider_step(handles, 2);

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in butSpan5.
function butSpan5_Callback(hObject, eventdata, handles)
% hObject    handle to butSpan5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.sldSpan, 'value', 5/handles.maxSpan);
handles = mainplot( handles );

handles = change_slider_step(handles,  5);

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in butSpan10.
function butSpan10_Callback(hObject, eventdata, handles)
% hObject    handle to butSpan10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.sldSpan, 'value', 10/handles.maxSpan);
handles = mainplot( handles );

handles = change_slider_step(handles, 10);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in butPrevUsac.
function butPrevUsac_Callback(hObject, eventdata, handles)
% hObject    handle to butPrevUsac (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in butNextUsac.
function butNextUsac_Callback(hObject, eventdata, handles)
% hObject    handle to butNextUsac (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% This function sets most axes mode properties to manual
function ManAxMode(h)
% Do not set CameraViewAngleMode, DataAspectRatioMode,
% and PlotBoxAspectRatioMode to aviod exposing a bug
pn = {'ALimMode', ...
    'CLimMode', ...
    'TickDirMode', 'XLimMode', ...
    'YLimMode', 'ZLimMode', ...
    'ZTickMode', ...
    'ZTickLabelMode'};
for k = 1:length(pn)
    pv(k) = {'manual'};
end
set(h, pn, pv)
pn = {'ALimMode', ...
    'CameraPositionMode', 'CameraTargetMode', ...
    'CameraUpVectorMode', 'CLimMode', ...
    'TickDirMode', 'XLimMode', ...
    'YLimMode', 'ZLimMode', ...
    'XTickMode', 'YTickMode', ...
    'ZTickMode', 'XTickLabelMode', ...
    'YTickLabelMode', 'ZTickLabelMode'};



function txtGoTo_Callback(hObject, eventdata, handles)
% hObject    handle to txtGoTo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject, 'String') returns contents of txtGoTo as text
%        str2double(get(hObject, 'String')) returns contents of txtGoTo as a double
strGoTo = get(handles.txtGoTo, 'string');

intGoTo = (str2double(strGoTo));

samplerate = get_current_samplerate(handles);

if ( ~isempty(intGoTo) )
    intGoTo = round(intGoTo*samplerate);
    if ( intGoTo > 0 && intGoTo < length(handles.data.left.x) )
        set(handles.sldScroll, 'value', intGoTo/length(handles.data.left.x));
        handles = mainplot( handles );
        
        % Update handles structure
        guidata(hObject, handles);
    end
end

% --- Executes during object creation, after setting all properties.
function txtGoTo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtGoTo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


% --- Executes on button press in butGoTo.
function butGoTo_Callback(hObject, eventdata, handles)
% hObject    handle to butGoTo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

strGoTo = get(handles.txtGoTo, 'string');

intGoTo = (str2double(strGoTo));

samplerate = get_current_samplerate(handles);

if ( ~isempty(intGoTo) )
    intGoTo = round(intGoTo*samplerate);
    if ( intGoTo > 0 && intGoTo < length(handles.data.left.x) )
        set(handles.sldScroll, 'value', intGoTo/length(handles.data.left.x));
        handles = mainplot( handles );
        
        % Update handles structure
        guidata(hObject, handles);
    end
end



% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radiobutton1


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radiobutton2


% --- Executes on button press in radiobutton3.
function radiobutton3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radiobutton3


% --- Executes on button press in radiobutton4.
function radiobutton4_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radiobutton4


% --- Executes on button press in butSpan30.
function butSpan30_Callback(hObject, eventdata, handles)
% hObject    handle to butSpan30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



set(handles.sldSpan, 'value', 30/handles.maxSpan);
handles = mainplot( handles );

handles = change_slider_step(handles, 30);

% Update handles structure
guidata(hObject, handles);


function handles = change_slider_step(handles,  span)

samplerate = get_current_samplerate(handles);

if ( ~isempty(handles.data.left.x) )
    set(handles.sldScroll, 'sliderstep', [ span*samplerate/10/length(handles.data.left.x) span*samplerate/length(handles.data.left.x)  ]);
else
    set(handles.sldScroll, 'sliderstep', [ span*samplerate/10/length(handles.data.right.x) span*samplerate/length(handles.data.right.x)  ]);
end


% --- Executes on button press in chkPlotMicrosaccades.
function chkPlotMicrosaccades_Callback(hObject, eventdata, handles)
% hObject    handle to chkPlotMicrosaccades (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of chkPlotMicrosaccades
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in radbutVrange1.
function radbutVrange1_Callback(hObject, eventdata, handles)
% hObject    handle to radbutVrange1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radbutVrange1
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in radbutVrange2.
function radbutVrange2_Callback(hObject, eventdata, handles)
% hObject    handle to radbutVrange2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radbutVrange2
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in radbutVrange5.
function radbutVrange5_Callback(hObject, eventdata, handles)
% hObject    handle to radbutVrange5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radbutVrange5
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in radbutVrange10.
function radbutVrange10_Callback(hObject, eventdata, handles)
% hObject    handle to radbutVrange10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radbutVrange10
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in radbutSamplerate250.
function radbutSamplerate250_Callback(hObject, eventdata, handles)
% hObject    handle to radbutSamplerate250 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radbutSamplerate250
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in radbutSamplerate500.
function radbutSamplerate500_Callback(hObject, eventdata, handles)
% hObject    handle to radbutSamplerate500 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radbutSamplerate500
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in radbutSamplerate1000.
function radbutSamplerate1000_Callback(hObject, eventdata, handles)
% hObject    handle to radbutSamplerate1000 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radbutSamplerate1000
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in radbutSamplerate2000.
function radbutSamplerate2000_Callback(hObject, eventdata, handles)
% hObject    handle to radbutSamplerate2000 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of radbutSamplerate2000

handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in radbutVrange05.
function radbutVrange05_Callback(hObject, eventdata, handles)
% hObject    handle to radbutVrange05 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%  Hint: get(hObject, 'Value') returns toggle state of radbutVrange5
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in radbutVrange075.
function radbutVrange075_Callback(hObject, eventdata, handles)
% hObject    handle to radbutVrange075 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%  Hint: get(hObject, 'Value') returns toggle state of radbutVrange5
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in radbutVrange025.
function radbutVrange025_Callback(hObject, eventdata, handles)
% hObject    handle to radbutVrange025 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);

% Hint: get(hObject, 'Value') returns toggle state of radbutVrange025

% --- Executes on button press in radbutVrange20.
function radbutVrange20_Callback(hObject, eventdata, handles)
% hObject    handle to radbutVrange20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in PlotPeakTroughOrControl.
function PlotPeakTroughOrControl_Callback(hObject, eventdata, handles)
% hObject    handle to PlotPeakTroughOrControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject, 'Value') returns toggle state of PlotPeakTroughOrControl




% --- Executes on button press in PlotPress.
function PlotPress_Callback(hObject, eventdata, handles)
% hObject    handle to PlotPress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject, 'Value') returns toggle state of PlotPress




% --- Executes on button press in PlotMonoculars.
function PlotMonoculars_Callback(hObject, eventdata, handles)
% hObject    handle to PlotMonoculars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject, 'Value') returns toggle state of PlotMonoculars


% --- Executes on button press in PlotSaccades.
function PlotSaccades_Callback(hObject, eventdata, handles)
% hObject    handle to PlotSaccades (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject, 'Value') returns toggle state of PlotSaccades


% --- Executes on button press in PlotBlinks.
function PlotBlinks_Callback(hObject, eventdata, handles)
% hObject    handle to PlotBlinks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject, 'Value') returns toggle state of PlotBlinks


% --- Executes on button press in PlotDrift.
function PlotDrift_Callback(hObject, eventdata, handles)
% hObject    handle to PlotDrift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject, 'Value') returns toggle state of PlotDrift


% --- Executes on button press in PlotEnvelope.
function PlotEnvelope_Callback(hObject, eventdata, handles)
% hObject    handle to PlotEnvelope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject, 'Value') returns toggle state of PlotEnvelope


% --- Executes on button press in PlotOvershoot.
function PlotOvershoot_Callback(hObject, eventdata, handles)
% hObject    handle to PlotOvershoot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject, 'Value') returns toggle state of PlotOvershoot


% --- Executes on button press in PlotRaw.
function PlotRaw_Callback(hObject, eventdata, handles)
% hObject    handle to PlotRaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject, 'Value') returns toggle state of PlotRaw


% --- Executes on button press in PlotLeft.
function PlotLeft_Callback(hObject, eventdata, handles)
% hObject    handle to PlotLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: gehandles = mainplot( handles );

% Update handles structure



% --- Executes on button press in PlotRight.
function PlotRight_Callback(hObject, eventdata, handles)
% hObject    handle to PlotRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject, 'Value') returns toggle state of PlotRight


% --- Executes on button press in PlotRelease.
function PlotRelease_Callback(hObject, eventdata, handles)
% hObject    handle to PlotRelease (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject, 'Value') returns toggle state of PlotRelease
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);



function   change_visiblity(input, on_or_off)

fieldnames = fields(input);

for i = 1:length(fieldnames)
    set(input.(fieldnames{i}), 'visible', on_or_off);
    
end


% --- Executes on button press in PlotDriftSpeed.
function PlotDriftSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to PlotDriftSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject, 'Value') returns toggle state of PlotRelease
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);

function samplerate = get_current_samplerate(handles)
if get(handles.radbutSamplerate250, 'value')
    samplerate = 250;
elseif get(handles.radbutSamplerate221, 'value')
    samplerate = 221;
elseif get(handles.radbutSamplerate500, 'value')
    samplerate = 500;
elseif get(handles.radbutSamplerate1000, 'value')
    samplerate = 1000;
elseif get(handles.radbutSamplerate2000, 'value')
    samplerate = 2000;
end
% Hint: get(hObject, 'Value') returns toggle state of PlotDriftSpeed


% --- Executes on button press in plotSpikes.
function plotSpikes_Callback(hObject, eventdata, handles)
% hObject    handle to plotSpikes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject, 'Value') returns toggle state of chkPlotMicrosaccades
handles = mainplot( handles );

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of plotSpikes


% --- Executes on button press in butSpan3.
function butSpan3_Callback(hObject, eventdata, handles)
% hObject    handle to butSpan3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.sldSpan, 'value', 3/handles.maxSpan);
handles = mainplot( handles );

handles = change_slider_step(handles, 3);

% Update handles structure
guidata(hObject, handles);










