classdef MVS < ArumeExperimentDesigns.EyeTracking
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
         function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            if ( exist('importing','var') && importing )
                dlg.DataFiles = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.EventFiles = '';
                dlg.CalibrationFiles = { {['uigetfile(''' fullfile(pwd,'*.cal') ''',''MultiSelect'', ''on'')']} };


                dlg.Experiment              = 'SimpleMVS';
                dlg.Duration                =  {{'{5min}' '20min' '60min' }};
                dlg.ControlSession          = '';
                dlg.Condition               = 'Something';
                dlg.PositionStartTrunk      = 'Supine';
                dlg.PositionEndTrunk        = 'Supine';
                dlg.PositionEndHeadYawAngle     = { 0 '* (deg)' [-90 90] };
                dlg.PositionEndHeadPitchAngle   = { 0 '* (deg)' [-90 90] }; 
                dlg.PositionEndHeadRollAngle    = { 0 '* (deg)' [-90 90] }; 
                dlg.Start_Baseline       = { 0 '* (sec)' [0 Inf] };
                dlg.Start_EnterMagnet    = { 120 '* (sec)' [0 Inf] };
                dlg.Finish_EnterMagnet   = { 140 '* (sec)' [0 Inf] };
                dlg.Start_ExitMagnet     = { 420 '* (sec)' [0 Inf] };
                dlg.Finish_ExitMagnet    = { 440 '* (sec)' [0 Inf] };
                dlg.Finish               = { 600 '* (sec)' [0 Inf] };
            end
         end
    end


    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        %% ImportSession
        function ImportSession( this )

            ImportSession@ArumeExperimentDesigns.EyeTracking(this);

            opt = this.GetAnalysisOptionsDialog();
            options = StructDlg(opt,'',[],[],'off');
            options.Prepare_For_Analysis_And_Plots = 1;
            this.Session.runAnalysis(options);
        end
        
        function [analysisResults, samplesDataTable, trialDataTable, sessionTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable,sessionTable, options)
            
            [analysisResults, samplesDataTable, trialDataTable, sessionTable] = RunDataAnalyses@ArumeExperimentDesigns.EyeTracking(this, analysisResults, samplesDataTable, trialDataTable,sessionTable, options);
            
            if ( 1 )
                analysisResults.SPV = table();
                
                T = samplesDataTable.Properties.UserData.sampleRate;
                analysisResults.SPV.Time = samplesDataTable.Time(1:T:(end-T/2));
                fields = {'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
                
                t = samplesDataTable.Time;
                
                %
                % calculate monocular spv
                %
                for j =1:length(fields)
                    
                    [vmed, xmed] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(fields{j}));
                    
                    analysisResults.SPV.(fields{j}) = vmed((T/2+1):T:end);
                    analysisResults.SPV.([fields{j} 'Pos']) = xmed((T/2+1):T:end);
                end
                
                %
                % calculate binocular spv
                %
                LRdataVars = {'X' 'Y' 'T'};
                for j =1:length(LRdataVars)
                    
                    [vleft, xleft] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(['Left' LRdataVars{j}]));
                    [vright, xright] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(['Right' LRdataVars{j}]));
                    
                    vmed = nanmedfilt(nanmean([vleft, vright],2),T,1/2);
                    xmed = nanmedfilt(nanmean([xleft, xright],2),T,1/2);
                    
                    analysisResults.SPV.(LRdataVars{j}) = vmed((T/2+1):T:end);
                    analysisResults.SPV.([LRdataVars{j} 'Pos']) = xmed((T/2+1):T:end);
                end
                
                %
                % Realign SPV
                %
                % Get the SPV realigned for easier averaging across
                % recordings. Necessary because not all of them have
                % exactly the same time for entering and exiting the
                % magnet.  
                %
                analysisResults.SPVRealigned = ArumeExperimentDesigns.MVS.RealignSPV(...
                    analysisResults.SPV, ...
                    this.ExperimentOptions.Duration, ...
                    this.ExperimentOptions.Start_EnterMagnet/60, ...
                    this.ExperimentOptions.Start_ExitMagnet/60);
                
                %
                % Nnormalize data acording to the peak of the control
                %
                
                arume = Arume('nogui');
                controlSession = arume.currentProject.findSession(this.Session.subjectCode, this.Session.experimentDesign.ExperimentOptions.ControlSession);
                
                % process the control just in case. 
                % Redundant but necessary for two reasons. 
                % 1) in case the control session is listed after the current session 
                % 2) in case the options have changed and we want to use the
                % control with the updated settings.
                if ( controlSession ~= this.Session) % TODO review this: a bit of a mess now. 
                    opt = arume.getAnalysisOptionsDefault(controlSession);
                    opt.SPV = 1;
                    opt.SPV_Periods = 0;
                    controlSession.runAnalysis(opt);
                    controlSession.save();
                    spvControl = controlSession.analysisResults.SPVRealigned;
                else
                    spvControl = analysisResults.SPVRealigned;
                end
                
                analysisResults.SPVNormalized = ArumeExperimentDesigns.MVS.NormalizeSPV( analysisResults.SPVRealigned, spvControl, [1 300] );
            end
            
            if ( 1 )
                
                %
                % Get the SPV at different timepoints
                %
                switch(categorical(sessionTable.Option_Duration))
                    case '5min'
                        timeExitMagnet = 7; % min
                        durationAfterEffect = 3; % min
                        
                        lightsON = 3; % min
                        lightsOFF = 6.7; % min
                        
                        startHeadMoving = 3; % min
                        stopHeadMoving = 6.7; % min
                        
                    case '20min'
                        timeExitMagnet = 22; % min
                        durationAfterEffect = 7; % min
                        
                        lightsON = 3; % min
                        lightsOFF = 21.5; % min
                        
                        startHeadMoving = 3; % min
                        stopHeadMoving = 21.5; % min
                        
                    case '60min'
                        timeExitMagnet = 62; % min
                        durationAfterEffect = 7; % min
                         
                        lightsON = 3; % min
                        lightsOFF = 61.5; % min
                        
                        startHeadMoving = 3; % min
                        stopHeadMoving = 61.5; % min
                        
                end
                
                periods.Baseline        = 2 + [-1.5     -0.2];
                periods.MainEffect      = 2 + [ 0.2   1.5];
                periods.AfterEffect     = timeExitMagnet + [ 0.2    durationAfterEffect];
                periods.BeforeExit      = timeExitMagnet + [-0.1    0.1];

%                 % add periods for light conditions
%                 periods.DuringLightsON      = [lightsON lightsOFF];
%                 periods.AfterLightsON       = lightsON   + [0.3 1.3];
%                 periods.BeforeLightsOFF     = lightsOFF  + [-1.3 -0.3];
%                 
%                 % add periods for head moving conditions
%                 periods.AfterStartHeadMoving	= startHeadMoving   + [0.3 1.3];
%                 periods.BeforeStopHeadMoving	= stopHeadMoving  + [-1.3 -0.3];
                
                fields = {'X' 'Y' 'T' 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
                periodNames = fieldnames(periods);
                analysisResults.periods = periods;
                
                for k = 1:length(periodNames) 
                    periodName = periodNames{k};
                    periodMin = periods.(periodName);
                    sessionTable.([periodName 'StartMin']) = periodMin(1);
                    sessionTable.([periodName 'StopMin']) = periodMin(2);
                    idx = sessionTable.([periodName 'StartMin'])*60:sessionTable.([periodName 'StopMin'])*60;
                    
                    for j =1:length(fields)
                        sessionTable.(['SPV_' fields{j} '_' periodName]) = nan;
                        sessionTable.(['SPVNorm_' fields{j} '_' periodName]) = nan;
                        sessionTable.(['SPV_' fields{j} '_' periodName '_Peak']) = nan;
                        sessionTable.(['SPV_' fields{j} '_' periodName '_PeakTime']) = nan;
                        sessionTable.(['SPVNorm_' fields{j} '_' periodName '_Peak']) = nan;
                        sessionTable.(['SPVNorm_' fields{j} '_' periodName '_PeakTime']) = nan;
                        
                        x = analysisResults.SPVRealigned.(fields{j});
                        t = analysisResults.SPVRealigned.Time;
                        xNorm = analysisResults.SPVNormalized.(fields{j});
                        
                        if ( ~isnan(sessionTable.([periodName 'StartMin'])))
                            xidx = idx(~isnan(x(idx)));
                            xnormidx = idx(~isnan(xNorm(idx)));
                            % important! measure area under the curve to be
                            % more fair into how samples are weighted in
                            % the case of nans
                            if ( length(xidx)>10 )
                                sessionTable.(['SPV_' fields{j} '_' periodName]) = trapz(t(xidx),x(xidx))/(t(xidx(end))-t(xidx(1)));
                            end
                            if ( length(xnormidx)>10)
                                sessionTable.(['SPVNorm_' fields{j} '_' periodName]) = trapz(t(xnormidx),xNorm(xnormidx))/(t(xnormidx(end))-t(xnormidx(1)));
                            end
                            
                            % find absolute value peak within period
                            [~,maxIdx] = max(abs(x(idx)));
                            sessionTable.(['SPV_' fields{j} '_' periodName '_Peak']) = x(idx(maxIdx));
                            sessionTable.(['SPV_' fields{j} '_' periodName '_PeakTime']) = t(idx(maxIdx));
                            sessionTable.(['SPVNorm_' fields{j} '_' periodName '_Peak']) = xNorm(idx(maxIdx));
                            sessionTable.(['SPVNorm_' fields{j} '_' periodName '_PeakTime']) = t(idx(maxIdx));
                            
                            sessionTable.(['SPVTimeConstant_' fields{j} '_' periodName]) = nan;
                            sessionTable.(['SPVTimeConstantA_' fields{j} '_' periodName]) = nan;
                            
                            fitIdx = idx(maxIdx):idx(end);
                            fitIdx = fitIdx(~isnan(x(fitIdx)));
                            if ( length(fitIdx) > 10 )
                                tfit = t(fitIdx)-t(fitIdx(1));
                                xfit = x(fitIdx);
                                warning('off','curvefit:fit:invalidStartPoint') 
                                f = fit(tfit,xfit,'exp1');
                                warning('on','curvefit:fit:invalidStartPoint')
                                sessionTable.(['SPVTimeConstant_' fields{j} '_' periodName]) = -1/f.b;
                                sessionTable.(['SPVTimeConstantA_' fields{j} '_' periodName]) = f.a;
                            end
                        end 
                    end
                end
            end
            
            if (0 & options.MVS_Fixation_Position )
                idx = samplesDataTable.Time>(sessionTable.Option_Events.LightsOn*60) & samplesDataTable.Time<(sessionTable.Option_Events.LightsOff*60);
                
                fields = {'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
                
                for j =1:length(fields)
                    x = samplesDataTable.(fields{j});
                    x = x(idx);
                    xzero = x - nanmedian(x);
                    sessionTable.(['DuringFixation_PositionSTD_' fields{j}]) = nanstd(x);
                    sessionTable.(['DuringFixation_PositionWithin1Deg_' fields{j}]) = mean(abs(xzero)<1)*100;
                    sessionTable.(['DuringFixation_PositionWithin2Deg_' fields{j}]) = mean(abs(xzero)<2)*100;
                    sessionTable.(['DuringFixation_PositionWithin3Deg_' fields{j}]) = mean(abs(xzero)<2)*100;
                end
                
                xl = samplesDataTable.LeftX(idx)    - nanmedfilt(samplesDataTable.LeftX(idx), 500*60*5, 0.5);
                xr = samplesDataTable.RightX(idx)   - nanmedfilt(samplesDataTable.RightX(idx), 500*60*5, 0.5);
                yl = samplesDataTable.LeftY(idx)    - nanmedfilt(samplesDataTable.LeftY(idx), 500*60*5, 0.5);
                yr = samplesDataTable.RightY(idx)   - nanmedfilt(samplesDataTable.RightY(idx), 500*60*5, 0.5);
                
                leftIsInside = abs(xl)<1 & abs(yl)<1;
                rightIsInside = abs(xr)<1 & abs(yr)<1;
                leftIsGood = ~isnan(xl) & ~isnan(yl);
                rightIsGood = ~isnan(xr) & ~isnan(yr);
                
                sessionTable.DuringFixation_PositionWithin1Deg_Left     = sum(leftIsInside)/sum(leftIsGood)*100;
                sessionTable.DuringFixation_PositionWithin1Deg_Right    = sum(rightIsInside)/sum(rightIsGood)*100;
                sessionTable.DuringFixation_PositionWithin1Deg = sum( (leftIsInside & rightIsInside) | (leftIsInside & ~rightIsGood) | (rightIsInside & ~leftIsGood)) / sum(leftIsGood | rightIsGood)*100;
                
                leftIsInside = abs(xl)<2 & abs(yl)<2;
                rightIsInside = abs(xr)<2 & abs(yr)<2;
                leftIsGood = ~isnan(xl) & ~isnan(yl);
                rightIsGood = ~isnan(xr) & ~isnan(yr);
                
                sessionTable.DuringFixation_PositionWithin2Deg_Left = sum(leftIsInside)/sum(leftIsGood)*100;
                sessionTable.DuringFixation_PositionWithin2Deg_Right = sum(rightIsInside)/sum(rightIsGood)*100;
                sessionTable.DuringFixation_PositionWithin2Deg =  sum( (leftIsInside & rightIsInside) | (leftIsInside & ~rightIsGood) | (rightIsInside & ~leftIsGood)) / sum(leftIsGood | rightIsGood)*100;
                
                
                leftIsInside = abs(xl)<1;
                rightIsInside = abs(xr)<1;
                leftIsGood = ~isnan(xl);
                rightIsGood = ~isnan(xr);
                
                sessionTable.DuringFixation_PositionWithin1Deg_LeftX     = sum(leftIsInside)/sum(leftIsGood)*100;
                sessionTable.DuringFixation_PositionWithin1Deg_RightX    = sum(rightIsInside)/sum(rightIsGood)*100;
                sessionTable.DuringFixation_PositionWithin1Deg_X = sum( (leftIsInside & rightIsInside) | (leftIsInside & ~rightIsGood) | (rightIsInside & ~leftIsGood)) / sum(leftIsGood | rightIsGood)*100;
                
                leftIsInside = abs(xl)<2;
                rightIsInside = abs(xr)<2;
                leftIsGood = ~isnan(xl);
                rightIsGood = ~isnan(xr);
                
                sessionTable.DuringFixation_PositionWithin2Deg_LeftX = sum(leftIsInside)/sum(leftIsGood)*100;
                sessionTable.DuringFixation_PositionWithin2Deg_RightX = sum(rightIsInside)/sum(rightIsGood)*100;
                sessionTable.DuringFixation_PositionWithin2Deg_X =  sum( (leftIsInside & rightIsInside) | (leftIsInside & ~rightIsGood) | (rightIsInside & ~leftIsGood)) / sum(leftIsGood | rightIsGood)*100;
                
                sessionTable.DuringFixation_DisparitySTD_X = nanstd(xl-xr);
                sessionTable.DuringFixation_DisparitySTD_Y = nanstd(yl-yr);
            end
            
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function Plot_MVS_VposExit(this)
            
            t = this.Session.samplesDataTable.Time;
            ly = this.Session.samplesDataTable.LeftY;
            ry = this.Session.samplesDataTable.RightY;
            y = nanmean([ry ly],2);
            
            tExit = this.Session.experimentDesign.ExperimentOptions.Events.ExitMagnet;
            
            figure('name', [this.Session.subjectCode '  ' this.Session.sessionCode]);
            plot(t(1:end-1)/60,sgolayfilt(diff(y),1,5));
            set(gca,'xlim',tExit +[-1 +1],'ylim',[-0.2 0.2]);
        end
        
        function Plot_MVS_SPV_Trace(this)
            if ( ~isfield(this.Session.analysisResults, 'SPV' ) )
                error( 'Need to run analysis SPV before ploting SPV');
            end
            
            t = this.Session.analysisResults.SPV.Time;
            vxl = this.Session.analysisResults.SPV.LeftX;
            vxr = this.Session.analysisResults.SPV.RightX;
            vyl = this.Session.analysisResults.SPV.LeftY;
            vyr = this.Session.analysisResults.SPV.RightY;
            vtl = this.Session.analysisResults.SPV.LeftT;
            vtr = this.Session.analysisResults.SPV.RightT;
            
            %%
            figure('name', [this.Session.subjectCode '  ' this.Session.sessionCode]);
            subplot(3,1,1,'nextplot','add')
            grid
            plot(t,vxl,'o')
            plot(t,vxr,'o')
            ylabel('Horizontal (deg/s)')
            events = [this.Session.experimentDesign.ExperimentOptions.Start_Baseline  ...
                this.Session.experimentDesign.ExperimentOptions.Start_EnterMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Finish_EnterMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Start_ExitMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Finish_ExitMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Finish ];
            for i=1:length(events)
                line([1 1]*events(i), get(gca,'ylim'),'linestyle','--','color',0.7*[1 1 1]);
            end
            
            
            subplot(3,1,2,'nextplot','add')
            grid
            set(gca,'ylim',[-20 20])
            plot(t,vyl,'o')
            plot(t,vyr,'o')
            ylabel('Vertical (deg/s)')
            
            events = [this.Session.experimentDesign.ExperimentOptions.Start_Baseline  ...
                this.Session.experimentDesign.ExperimentOptions.Start_EnterMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Finish_EnterMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Start_ExitMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Finish_ExitMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Finish ];
            for i=1:length(events)
                line([1 1]*events(i), get(gca,'ylim'),'linestyle','--','color',0.7*[1 1 1]);
            end
            
            
            subplot(3,1,3,'nextplot','add')
            set(gca,'ylim',[-20 20])
            hleg(1) = plot(t,vtl,'o');
            hleg(2) = plot(t,vtr,'o');
            ylabel('Torsional (deg/s)')
            grid
            set(gca,'ylim',[-20 20])
            xlabel('Time (s)');
            linkaxes(get(gcf,'children'))
            
            legend(hleg,{'Left eye'  'Right eye'})
        end
        
        function Plot_MVS_Magnetometer(this)
   %%
             t = this.Session.samplesDataTable.Time;
             
            figure('name', [this.Session.subjectCode '  ' this.Session.sessionCode]);
            
            hleg = plot(t, this.Session.samplesDataTable{:,{'HeadMagX', 'HeadMagY', 'HeadMagZ'}},'.');
            title('Magnetometer');

            events = [this.Session.experimentDesign.ExperimentOptions.Start_Baseline  ...
                this.Session.experimentDesign.ExperimentOptions.Start_EnterMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Finish_EnterMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Start_ExitMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Finish_ExitMagnet  ...
                this.Session.experimentDesign.ExperimentOptions.Finish ];
            for i=1:length(events)
                line([1 1]*events(i), get(gca,'ylim'),'linestyle','--','color',0.7*[1 1 1]);
            end
            
            legend(hleg, {'X' 'Y' 'Z'})
        end
        
        
        function Plot_MVS_SPVH_Trace(this)
            CLRS = get(groot,'defaultAxesColorOrder');
            
            if ( ~isfield(this.Session.analysisResults, 'SPV' ) )
                error( ['Need to run analysis SPV before ploting SPV. Session: ' this.Session.name]);
            end
            
            t = this.Session.analysisResults.SPV.Time/60;
            v = this.Session.analysisResults.SPV.X;
            tr = this.Session.analysisResults.SPVRealigned.Time/60;
            vr = this.Session.analysisResults.SPVRealigned.X;
            
            
            %%
            figure('name', [this.Session.subjectCode '  ' this.Session.sessionCode]);
            grid
            plot(t,v,'color',CLRS(2,:))
            hold
            plot(tr,vr,'o','color',CLRS(1,:))
            set(gca,'nextplot','add');
            % make the y axis symmetrical around 0 and a multiple of 10
            set(gca,'ylim',[-1 1]*10*ceil(max(abs(get(gca,'ylim')))/10));
            ylabel('Horizontal (deg/s)')
            xlabel('Time (min)');
            
            if ( isfield(this.Session.analysisResults, 'periods') ...
                    && isstruct(this.Session.analysisResults.periods) )
                events = struct2array(this.Session.analysisResults.periods);
                for i=1:length(events)
                    line([1 1]*events(i), get(gca,'ylim'),'linestyle','--','color',0.7*[1 1 1]);
                end
                
                periods = {'Baseline', 'MainEffect', 'BeforeExit', 'AfterEffect','AfterLightsON' 'BeforeLightsOFF' 'AfterStartHeadMoving' 'BeforeStopHeadMoving'};
                
                for i=1:length(periods)
                    time = this.Session.sessionDataTable.([periods{i} 'StartMin'])*60:this.Session.sessionDataTable.([periods{i} 'StopMin'])*60;
                    value = ones(size(time))*this.Session.sessionDataTable.(['SPV_' 'X' '_' periods{i}]);
                    plot(time/60,value,'o','color','r','linewidth',1);
                    
                   
                    plot(this.Session.sessionDataTable.(['SPV_' 'X' '_' periods{i} '_PeakTime'])/60,this.Session.sessionDataTable.(['SPV_' 'X' '_' periods{i} '_Peak']),'^','color','r','linewidth',2);
                end
            end
            
            
        end
        
        function PlotAggregate_MVS_SPV(this, sessions)
            
            CLRS = get(groot,'defaultAxesColorOrder');
            figure
            arume = Arume('nogui');
            s = arume.currentProject.GetDataTable(sessions);
            s.SessionObj = sessions';
            s.IsControl = s.Option_ControlSession == s.SessionCode;
            s = sortrows(s,'SessionCode');
            %%
            subjects = unique(s.Subject);
            for i=1:length(subjects)
                subplot(length(subjects),1, i,'nextplot','add');
                ss = s(s.Subject == subjects(i),:);
                for j=1:height(ss)
                    t = ss.SessionObj(j).analysisResults.SPVRealigned.Time/60;
                    vxl = ss.SessionObj(j).analysisResults.SPVRealigned.LeftX;
                    vxr = ss.SessionObj(j).analysisResults.SPVRealigned.RightX;
                    spv = nanmean([vxl vxr],2);
                    if (ss.Option_Experiment=='HeadMoving' )
                        spv(t>180 & t<405) = nan;
                    end
                    if ( ss.IsControl(j))
                        color = CLRS(1,:);
                    else
                        color = CLRS(2,:);
                    end
                    plot(t,spv,'.','markersize',10,'color',color);
                end
                line(get(gca,'xlim'),[0 0],'color',[0.5 0.5 0.5],'linestyle','-.')
                legend(strrep(string(ss.SessionCode),'_',' '));
                title(string(subjects(i)));
                xlabel('Time (s)');
                ylabel('SPV (deg/s)');
            end
        end
        
        function PlotAggregate_MVS_SPV_Normalized(this, sessions)
            
            CLRS = get(groot,'defaultAxesColorOrder');
            
            figure
            arume = Arume('nogui');
            s = arume.currentProject.GetDataTable(sessions);
            s.SessionObj = sessions';
            s.IsControl = s.Option_ControlSession == s.SessionCode;
            s = sortrows(s,'SessionCode');
            %%
            subjects = unique(s.Subject);
            for i=1:length(subjects)
                subplot(length(subjects),1, i,'nextplot','add');
                ss = s(s.Subject == subjects(i),:);
                for j=1:height(ss)
                    t = ss.SessionObj(j).analysisResults.SPVNormalized.Time/60;
                    vxl = ss.SessionObj(j).analysisResults.SPVNormalized.LeftX;
                    vxr = ss.SessionObj(j).analysisResults.SPVNormalized.RightX;
                    spv = nanmean([vxl vxr],2);
                    if (ss.Option_Experiment=='HeadMoving' )
                        spv(t>180 & t<405) = nan;
                    end
                    if ( ss.IsControl(j))
                        color = CLRS(1,:);
                    else
                        color = CLRS(2,:);
                    end
                    plot(t,spv,'.','markersize',10,'color',color);
                end
                line(get(gca,'xlim'),[0 0],'color',[0.5 0.5 0.5],'linestyle','-.')
                legend(strrep(string(ss.SessionCode),'_',' '));
                title(string(subjects(i)));
                xlabel('Time (s)');
                ylabel('SPV (deg/s)');
            end
        end
        
    end
    
    methods(Static =true)
        
        function [newSPV] = RealignSPV( spvTable, durationExpeirmentMin, timeEnterMagnetMin, timeExitMagnetMin)
            
            switch(categorical(string(durationExpeirmentMin)))
                case '5min'
                    durationInsideMagnet = 5;
                    durationUntilEnd = 11;
                case '20min'
                    durationInsideMagnet = 20;
                    durationUntilEnd = 37;
                case '60min'
                    durationInsideMagnet = 60;
                    durationUntilEnd = 82;
            end
            
            newSPV = table();
            newSPV.Time = (0:1:durationUntilEnd*60)';
            
            fields = setdiff(spvTable.Properties.VariableNames,{'Time'},'stable');
            for i=1:length(fields)
                spvRealigned = nan(size(newSPV.Time));
                spv = spvTable.(fields{i});
                if ( sum(~isnan(spv))> 3 )
                    spv = interp1(find(~isnan(spv)),spv(~isnan(spv)),1:1:length(spv));
                    
                    actualTimeEnter = round(timeEnterMagnetMin*60);
                    actualTimeExit = round(timeExitMagnetMin*60);
                    
                    expectedTimeEnter = 2*60;
                    expectedTimeExit = (durationInsideMagnet+2)*60;
                    
                    % From entering the magnet minus 2 min to duration until exist
                    % minus one minute
                    idxOriginPeriod1 = actualTimeEnter + ((-2*60)+1:((durationInsideMagnet-2)*60));
                    idxDestinPreiod1 = expectedTimeEnter + ((-2*60)+1:((durationInsideMagnet-2)*60));
                    remidx = find(idxOriginPeriod1<1 | idxOriginPeriod1>length(spv));
                    idxOriginPeriod1(remidx) = [];
                    idxDestinPreiod1(remidx) = [];
                    spvRealigned(idxDestinPreiod1) = spv(idxOriginPeriod1);
                    
                    idxOriginPeriod2 = actualTimeExit + ((-3*60)+1:((durationUntilEnd-durationInsideMagnet-2)*60));
                    idxDestinPreiod2 = expectedTimeExit + ((-3*60)+1:((durationUntilEnd-durationInsideMagnet-2)*60));
                    remidx = find(idxOriginPeriod2<1 | idxOriginPeriod2>length(spv));
                    idxOriginPeriod2(remidx) = [];
                    idxDestinPreiod2(remidx) = [];
                    spvRealigned(idxDestinPreiod2) = spv(idxOriginPeriod2);
                    
                    if(0)
                        figure
                        subplot(1,2,1)
                        plot(spvTable.Time, spv);
                        subplot(1,2,2)
                        plot(spvRealigned);
                    end
                end
                
                newSPV.(fields{i}) = spvRealigned;
            end
        end
        
        function newSPV = NormalizeSPV( spvTable, spvControlTable, peakInterval )
            
            newSPV = spvTable;
            
            fields = setdiff(spvTable.Properties.VariableNames,{'Time'},'stable');
            for i=1:length(fields)
                spvField = spvControlTable.(fields{i});
                peak = max(abs(spvField(peakInterval(1):peakInterval(2))));
                newSPV.(fields{i}) = spvTable.(fields{i}) / peak;
            end
        end
    end
    
end

