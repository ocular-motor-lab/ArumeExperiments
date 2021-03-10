classdef EyeTracking  < ArumeCore.ExperimentDesign
    
    properties
        eyeTracker
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods (Access=protected)
        function dlg = GetOptionsDialog( this, importing )
            dlg.UseEyeTracker = { {'0' '{1}'} };
            dlg.Debug = { {'{0}','1'} };
            
            dlg.ScreenWidth = { 40 '* (cm)' [1 3000] };
            dlg.ScreenHeight = { 30 '* (cm)' [1 3000] };
            dlg.ScreenDistance = { 135 '* (cm)' [1 3000] };
            
            if ( exist('importing','var') && importing )
                dlg.DataFiles = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.EventFiles = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.CalibrationFiles = { {['uigetfile(''' fullfile(pwd,'*.cal') ''',''MultiSelect'', ''on'')']} };
            end
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            % This is necessary for basic imported sessions of eye movement
            % recordings
            
            i = i+1;
            conditionVars(i).name   = 'Recording';
            conditionVars(i).values = 1;
        end
        
        function shouldContinue = initBeforeRunning( this )
            
            if ( this.ExperimentOptions.UseEyeTracker )
                this.eyeTracker = ArumeHardware.VOG();
                this.eyeTracker.Connect();
                this.eyeTracker.SetSessionName(this.Session.name);
                this.eyeTracker.StartRecording();
                this.AddTrialStartCallback(@this.TrialStartCallback)
                this.AddTrialStopCallback(@this.TrialStopCallBack)
            end
            
            shouldContinue = 1;
        end
        
        function cleanAfterRunning(this)
            
            if ( this.ExperimentOptions.UseEyeTracker )
                this.eyeTracker.StopRecording();
        
                disp('Downloading eye tracking files...');
                files = this.eyeTracker.DownloadFile();
                
                if (~isempty( files) )
                    disp(files{1});
                    disp(files{2});
                    if (length(files) > 2 )
                        disp(files{3});
                    end
                    disp('Finished downloading');
                    
                    this.Session.addFile('vogDataFile', files{1});
                    this.Session.addFile('vogCalibrationFile', files{2});
                    if (length(files) > 2 )
                        this.Session.addFile('vogEventsFile', files{3});
                    end
                else
                    disp('No eye tracking files downloaded!');
                end
            end
        end
        
        function variables = TrialStartCallback(this, variables)
            if ( ~this.eyeTracker.IsRecording )
                ME = MException('ArumeHardware.VOG:NotRecording', 'The eye tracker is not recording.');
                throw(ME);
            end
                
            variables.EyeTrackerFrameNumberTrialStart = this.eyeTracker.RecordEvent(sprintf('TRIAL_START %d %d', variables.TrialNumber, variables.Condition) );
            if ( ~isempty( this.Session.currentRun.LinkedFiles) )
                if ( ischar(this.Session.currentRun.LinkedFiles.vogDataFile) )
                    variables.FileNumber = 2;
                else
                    variables.FileNumber = length(this.Session.currentRun.LinkedFiles.vogDataFile)+1;
                end
            else
                variables.FileNumber = 1;
            end
        end
         
        function variables = TrialStopCallBack(this, variables)
            if ( ~this.eyeTracker.IsRecording )
                ME = MException('ArumeHardware.VOG:NotRecording', 'The eye tracker is not recording.');
                throw(ME);
            end
            variables.EyeTrackerFrameNumberTrialStop = this.eyeTracker.RecordEvent(sprintf('TRIAL_STOP %d %d', variables.TrialNumber, variables.Condition) );
        end
            
    end
        
    % --------------------------------------------------------------------
    % Analysis methods --------------------------------------------------
    % --------------------------------------------------------------------
    methods ( Access = public )
        %% ImportSession
        function ImportSession( this )
            newRun = ArumeCore.ExperimentRun.SetUpNewRun( this );
            vars = newRun.futureTrialTable;
            vars.TrialResult = categorical(cellstr('CORRECT'));
            vars.TrialNumber = 1;
            vars.FileNumber = 1;
            newRun.AddPastTrialData(vars);
            newRun.futureTrialTable(:,:) = [];
            this.Session.importCurrentRun(newRun);
            
            
            dataFiles = this.ExperimentOptions.DataFiles;
            eventFiles = this.ExperimentOptions.EventFiles;
            calibrationFiles = this.ExperimentOptions.CalibrationFiles;
            if ( ~iscell(dataFiles) )
                dataFiles = {dataFiles};
            end
            if ( ~iscell(eventFiles) )
                eventFiles = {eventFiles};
            end
            if ( ~iscell(calibrationFiles) )
                calibrationFiles = {calibrationFiles};
            end
            
            for i=1:length(dataFiles)
                if (exist(dataFiles{i},'file') )
                    this.Session.addFile('vogDataFile', dataFiles{i});
                end
            end
            for i=1:length(eventFiles)
                if (exist(eventFiles{i},'file') )
                    this.Session.addFile('vogEventsFile', eventFiles{i});
                end
            end
            for i=1:length(calibrationFiles)
                if (exist(calibrationFiles{i},'file') )
                    this.Session.addFile('vogCalibrationFile', calibrationFiles{i});
                end
            end
        end
        
        function optionsDlg = GetAnalysisOptionsDialog(this)
            optionsDlg = VOGAnalysis.GetParameterOptions();
        end
        
        function [samplesDataTable, cleanedData, calibratedData, rawData] = PrepareSamplesDataTable(this, options)
            samplesDataTable = table();
            cleanedData = table();
            calibratedData = table();
            rawData = table();
            
            if ( ~isprop(this.Session.currentRun, 'LinkedFiles' ) || ~isfield(this.Session.currentRun.LinkedFiles,  'vogDataFile') )
                return;
            end
            
            dataFiles = this.Session.currentRun.LinkedFiles.vogDataFile;
            calibrationFiles = this.Session.currentRun.LinkedFiles.vogCalibrationFile;
                        
            if (~iscell(dataFiles) )
                dataFiles = {dataFiles};
            end
            
            if (~iscell(calibrationFiles) )
                calibrationFiles = {calibrationFiles};
            end
            
            if (length(calibrationFiles) == 1)
                calibrationFiles = repmat(calibrationFiles,size(dataFiles));
            elseif length(calibrationFiles) ~= length(dataFiles)
                error('ERROR preparing sample data set: The session should have the same number of calibration files as data files or 1 calibration file');
            end
            
            [samplesDataTable, cleanedData, calibratedData, rawData] = VOGAnalysis.LoadCleanAndResampleData(this.Session.dataPath, dataFiles, calibrationFiles, options);
            
            a = Arume;
            cal = a.currentProject.findSession(this.Session.subjectCode,'Cal');
            if ( ~isempty(cal))
                % RECALIBRATE DATA WITH BEHAVIORAL CALIBRATION FROM ANOTHER
                % SESSION
                
                reCalibratedData   = VOGAnalysis.CalibrateData(samplesDataTable, cal.analysisResults.calibrationTable);

                disp('RECALIBRATING DATA');
                cal.analysisResults.calibrationTable
                samplesDataTable = reCalibratedData;
            end
        end
        
        function trialDataTable = PrepareTrialDataTable( this, trialDataTable, options)
            samplesData = this.Session.samplesDataTable;
            
            if ( ~isempty( samplesData ) )
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % DEAL WITH OLD FILES THAT HAVE SOME MISSING FIELDS
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % Old versions did not have a file number column. This code
                % recovers one from the events file.
                if ( ~any(strcmp(trialDataTable.Properties.VariableNames,'FileNumber')) )
                    % Find the file number that corresponds with each trial.
                    if ( isfield(this.Session.currentRun.LinkedFiles, 'vogEventsFile'))
                        ev = VOGAnalysis.ReadEventFiles(this.Session.dataPath, this.Session.currentRun.LinkedFiles.vogEventsFile);
                        trialDataTable.FileNumber = ev.FileNumber(this.Session.currentRun.pastTrialTable.TrialResult=='CORRECT');
                    else
                        % if there are no event files assume all the data
                        % comes from one single file
                        trialDataTable.FileNumber = ones(size(trialDataTable.TrialNumber));
                    end
                end

                % Old versions did not have a timestamp from the eye
                % tracker to line up trials precisely. This reads the old
                % event file to try to line them up.
                if ( ~any(strcmp(trialDataTable.Properties.VariableNames,'EyeTrackerFrameNumberTrialStart')) )
                    if ( height(trialDataTable) == 1 )
                        trialDataTable.EyeTrackerFrameNumberTrialStart = samplesData.RawFrameNumber(1);
                        trialDataTable.EyeTrackerFrameNumberTrialStop = samplesData.RawFrameNumber(end);
                    else
                        events = readtable(fullfile(this.Session.folder, this.Session.currentRun.LinkedFiles.vogEventsFile),'Delimiter',' ');
                        % get frame number from event table
                        % get trial duration from trialDataTable
                        % calculate frame number off of those two things
                        events = events(this.Session.currentRun.pastTrialTable.TrialResult=='CORRECT',:);
                        trialDataTable.EyeTrackerFrameNumberTrialStart = events.Var2 - samplesData.LeftCameraRawFrameNumber(1)+1;
                        if ( min(trialDataTable.EyeTrackerFrameNumberTrialStart) < 0 )
                            % crappy fix for files recorded around july-aug
                            % 2018. The data files and the event files have
                            % different frame numbers so they cannot be
                            % lined up exactly.
                            daysForFirstTrialStart = datenum(events.Var1{1},'yyyy-mm-dd-HH:MM:SS');
                            a = regexp(this.Session.currentRun.LinkedFiles.vogEventsFile,'.+PostProc\-(?<date>.+)\-events\.txt', 'names');
                            daysForFileOpening = datenum(a.date,'yyyymmmdd-HHMMSS');
                            secondsFromFileOpeningToFirstTrial = (daysForFirstTrialStart-daysForFileOpening)*24*60*60;
                            frameNumberFirstTrialStart = min( secondsFromFileOpeningToFirstTrial*100,  max(samplesData.FrameNumber) - (trialDataTable.TimeTrialStop(end)-trialDataTable.TimeTrialStart(1))*100);
                            trialDataTable.EyeTrackerFrameNumberTrialStart = (trialDataTable.TimeTrialStart-trialDataTable.TimeTrialStart(1))*100 + frameNumberFirstTrialStart;
                        end
                        trialDataTable.EyeTrackerFrameNumberTrialStop = (trialDataTable.TimeTrialStop - trialDataTable.TimeTrialStart)*100 + trialDataTable.EyeTrackerFrameNumberTrialStart;    
                    end
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % END OF DEALING WITH OLD FILES
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % LINE UP TRIALS AND SAMPLES DATA
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % Find the samples that mark the begining and ends of trials
                trialDataTable.SampleStartTrial = nan(size(trialDataTable.TrialNumber));
                trialDataTable.SampleStopTrial = nan(size(trialDataTable.TrialNumber));
                if ( ~any(strcmp(samplesData.Properties.VariableNames, 'FileNumber')))
                    samplesData.FileNumber = ones(size(samplesData.Time));
                end
                for i=1:height(trialDataTable)
                    trialDataTable.SampleStartTrial(i) = find(samplesData.FileNumber' == trialDataTable.FileNumber(i) & samplesData.RawFrameNumber'>=trialDataTable.EyeTrackerFrameNumberTrialStart(i),1,'first');
                    trialDataTable.SampleStopTrial(i) = find(samplesData.FileNumber' == trialDataTable.FileNumber(i) & samplesData.RawFrameNumber'<=trialDataTable.EyeTrackerFrameNumberTrialStop(i),1,'last');
                end
                
                % Build a column for the samples with the trial number
                samplesData.TrialNumber = nan(size(samplesData.FrameNumber));
                for i=1:height(trialDataTable)
                    idx = trialDataTable.SampleStartTrial(i):trialDataTable.SampleStopTrial(i);
                    samplesData.TrialNumber(idx) = trialDataTable.TrialNumber(i);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % CALCULATE AVERAGE EYE MOVEMENT STATS FOR EACH TRIAL
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                LRdataVars = {'X' 'Y' 'T'};
                for i=1:length(LRdataVars)
                    if ( ~any(strcmp(samplesData.Properties.VariableNames,['Left' LRdataVars{i}])) )
                        samplesData.(['Left' LRdataVars{i}]) = nan(size(samplesData.(['Right' LRdataVars{i}])));
                    end
                    if ( ~any(strcmp(samplesData.Properties.VariableNames,['Right' LRdataVars{i}])) )
                        samplesData.(['Right' LRdataVars{i}]) = nan(size(samplesData.(['Left' LRdataVars{i}])));
                    end
                    
                    % average both eyes
                    samplesData.(LRdataVars{i}) = nanmean(samplesData{:,{['Left' LRdataVars{i}],['Right' LRdataVars{i}]}},2);
                end
                
                dataVars = { 'X' 'Y' 'T' 'LeftX' 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
                
                if ( any(strcmp(samplesData.Properties.VariableNames,'LeftBadData')) && any(strcmp(samplesData.Properties.VariableNames,'RightBadData')) )
                    samplesData.GoodData = ~samplesData.LeftBadData & ~samplesData.RightBadData;
                elseif ( any(strcmp(samplesData.Properties.VariableNames,'LeftBadData')) )
                    samplesData.GoodData = ~samplesData.LeftBadData ;
                elseif ( any(strcmp(samplesData.Properties.VariableNames,'RightBadData')) )
                    samplesData.GoodData =  ~samplesData.RightBadData;
                end
                isInTrial = ~isnan(samplesData.TrialNumber);
                
                stats = grpstats(...
                    samplesData(isInTrial,:), ...     % Selected rows of data
                    'TrialNumber', ...                  % GROUP VARIABLE
                    {'median' 'mean' 'std'}, ...        % Stats to calculate
                    'DataVars', dataVars );             % Vars to do stats on
                leftRightBadData = intersect({'LeftBadData', 'RightBadData'},samplesData.Properties.VariableNames);
                stats2 = grpstats(...
                    samplesData(isInTrial,:), ...     % Selected rows of data
                    'TrialNumber', ...                  % GROUP VARIABLE
                    {'sum'}, ...             % Vars to do stats on
                    'DataVars', {'GoodData', leftRightBadData{:}});	% Vars to do stats on
                stats2.Properties.VariableNames{'GroupCount'} = 'count_GoodSamples';
                
                samplerate = samplesData.Properties.UserData.sampleRate;
                varsBeforeJoin = trialDataTable.Properties.VariableNames;
                trialDataTable = outerjoin(trialDataTable, stats,'Keys','TrialNumber','MergeKeys',true, 'LeftVariables', setdiff(trialDataTable.Properties.VariableNames, stats.Properties.VariableNames) );
                trialDataTable = outerjoin(trialDataTable, stats2,'Keys','TrialNumber','MergeKeys',true, 'LeftVariables', setdiff(trialDataTable.Properties.VariableNames, stats2.Properties.VariableNames) );
                
                trialDataTable.TotalGoodSec = trialDataTable.sum_GoodData/samplerate;
                trialDataTable.TotalSec = trialDataTable.count_GoodSamples/samplerate;
                
                % keep a list of the variables added so it is easier to do
                % states across trials
                trialDataTable.Properties.UserData.EyeTrackingPrepareTrialDataTableVariables = setdiff(trialDataTable.Properties.VariableNames, varsBeforeJoin);
            end
        end
        
        function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable, options)
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % CALCULATE AVERAGE EYE MOVEMENT ACROSS TRIALS
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            trialDataTable = this.Session.trialDataTable;
            varsToGroup = trialDataTable.Properties.UserData.EyeTrackingPrepareTrialDataTableVariables;
            
            % Also calculate average across conditions for each of the
            % values of each condition variables. 
            % Also create a variable that containes all the combinations of
            % all conditions and avarege across those
            ConditionVarsNames = {};
            condition = [];
            for i=1:length(this.Session.experimentDesign.ConditionVars)
                if ( numel(this.Session.experimentDesign.ConditionVars(i).values)>1)
                    ConditionVarsNames{end+1} = this.Session.experimentDesign.ConditionVars(i).name;
                    if (isempty(condition) )
                        condition = string(trialDataTable{:,ConditionVarsNames(i)});
                    else
                        condition = strcat(condition,'_', string(trialDataTable{:,ConditionVarsNames(i)}));
                    end
                end
            end
            if ( ~isempty(ConditionVarsNames))
                trialDataTable.Condition = condition;
                ConditionVarsNames = horzcat({'Condition'}, ConditionVarsNames);
                for i=1:length(ConditionVarsNames)
                    st = grpstats(trialDataTable, ...     % Selected rows of data
                        ConditionVarsNames{i}, ...                  % GROUP VARIABLE
                        {'mean' 'std'}, ...        % Stats to calculate
                        'DataVars', varsToGroup);             % Vars to do stats on
                    b = unstack(st,setdiff(st.Properties.VariableNames, ConditionVarsNames{i}),ConditionVarsNames{i});
                    b.Properties.RowNames = {};
                    sessionDataTable(:,intersect(b.Properties.VariableNames, sessionDataTable.Properties.VariableNames)) = [];
                    sessionDataTable = horzcat(sessionDataTable, b);
                end
            end
        end

        function [analysisResults, samplesDataTable, trialDataTable, sessionDataTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable, sessionDataTable, options)
            
            updateTrialsAndSessionTables = false;
            
            if ( isfield(options,'Detect_Quik_and_Slow_Phases') && options.Detect_Quik_and_Slow_Phases )
                samplesDataTable = VOGAnalysis.DetectQuickPhases(samplesDataTable, options);
                samplesDataTable = VOGAnalysis.DetectSlowPhases(samplesDataTable, options);
                updateTrialsAndSessionTables = true;
            end
            
            if ( isfield(options,'Mark_Data') && options.Mark_Data )
                samplesDataTable = VOGDataExplorer.MarkData(samplesDataTable);
                updateTrialsAndSessionTables = true;
            end
            
            if ( 1 )
                T = samplesDataTable.Properties.UserData.sampleRate;
                analysisResults.SPV.Time = samplesDataTable.Time(1:T:(end-T/2));
                fields = {'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
                
                t = samplesDataTable.Time;
                                
                %
                % calculate binocular spv
                %
                LRdataVars = {'X' 'Y' 'T'};
                for j =1:length(LRdataVars)
                    
                    [vleft, xleft] = VOGAnalysis.GetSPV_SimpleQP(t, samplesDataTable.(['Left' LRdataVars{j}]), samplesDataTable.QuickPhase );
                    [vright, xright] = VOGAnalysis.GetSPV_SimpleQP(t, samplesDataTable.(['Right' LRdataVars{j}]), samplesDataTable.QuickPhase );
                    
                    vmed = nanmedfilt(nanmean([vleft, vright],2),T,1/2);
                    samplesDataTable.(['SPV' LRdataVars{j}]) = vmed;
                end
                
                
                % Build a column for the samples with the trial number
                samplesDataTable.TrialNumber = nan(size(samplesDataTable.FrameNumber));
                for i=1:height(trialDataTable)
                    idx = trialDataTable.SampleStartTrial(i):trialDataTable.SampleStopTrial(i);
                    samplesDataTable.TrialNumber(idx) = trialDataTable.TrialNumber(i);
                end
                
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % CALCULATE AVERAGE SAMPLE PROPERTIES ACROSS TRIALS
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                
                dataVars = { 'SPVX' 'SPVY' 'SPVT'};
                isInTrial = ~isnan(samplesDataTable.TrialNumber);
                
                stats = grpstats(...
                    samplesDataTable(isInTrial,:), ...     % Selected rows of data
                    'TrialNumber', ...                  % GROUP VARIABLE
                    {'median' 'mean' 'std'}, ...        % Stats to calculate
                    'DataVars', dataVars );             % Vars to do stats on
                
                trialDataTable = outerjoin(trialDataTable, stats,'Keys','TrialNumber','MergeKeys',true, 'LeftVariables', setdiff(trialDataTable.Properties.VariableNames, stats.Properties.VariableNames) );
            end
            
            if (updateTrialsAndSessionTables)
                ConditionVarsNames = {};
                condition = [];
                for i=1:length(this.Session.experimentDesign.ConditionVars)
                    if ( numel(this.Session.experimentDesign.ConditionVars(i).values)>1)
                        ConditionVarsNames{end+1} = this.Session.experimentDesign.ConditionVars(i).name;
                        if (isempty(condition) )
                            condition = string(trialDataTable{:,ConditionVarsNames(i)});
                        else
                            condition = strcat(condition,'_', string(trialDataTable{:,ConditionVarsNames(i)}));
                        end
                    end
                end
                
                [qp, sp] = VOGAnalysis.GetQuickAndSlowPhaseTable(samplesDataTable);
                
                % Build a column for the samples with the trial number
                samplesDataTable.TrialNumber = nan(size(samplesDataTable.FrameNumber));
                for i=1:height(trialDataTable)
                    idx = trialDataTable.SampleStartTrial(i):trialDataTable.SampleStopTrial(i);
                    samplesDataTable.TrialNumber(idx) = trialDataTable.TrialNumber(i);
                end
                
                % add columns to quick and slow phases for trial number and
                % also the values of each condition variable that
                % corresponds with that trial
                qpDataVars = qp.Properties.VariableNames;
                spDataVars = sp.Properties.VariableNames;
                
                warning('off','MATLAB:table:RowsAddedNewVars');
                qp.TrialNumber = samplesDataTable.TrialNumber(qp.StartIndex);
                sp.TrialNumber = samplesDataTable.TrialNumber(sp.StartIndex);
                for i=1:numel(ConditionVarsNames)
                    if ( iscategorical(trialDataTable{qp.TrialNumber(~isnan(qp.TrialNumber)),ConditionVarsNames{i}}))
                        qp{~isnan(qp.TrialNumber),ConditionVarsNames{i}} =  categorical(trialDataTable{qp.TrialNumber(~isnan(qp.TrialNumber)),ConditionVarsNames{i}});
                    else
                        qp{:,ConditionVarsNames{i}} = nan(height(qp),1);
                        qp{~isnan(qp.TrialNumber),ConditionVarsNames{i}} =  trialDataTable{qp.TrialNumber(~isnan(qp.TrialNumber)),ConditionVarsNames{i}};
                    end
                    sp{~isnan(sp.TrialNumber),ConditionVarsNames{i}} =  categorical(trialDataTable{sp.TrialNumber(~isnan(sp.TrialNumber)),ConditionVarsNames{i}});
                end
                warning('on','MATLAB:table:RowsAddedNewVars');
                
                analysisResults.QuickPhases = qp;
                analysisResults.SlowPhases = sp;
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % CALCULATE AVERAGE QP AND SP PROPERTIES FOR EACH TRIAL
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Add average properties of QP and SP to the trial table
                goodQP = qp(~isnan(qp.TrialNumber),:);
                stats = grpstats(goodQP, ...     % Selected rows of data
                    'TrialNumber', ...                  % GROUP VARIABLE
                    {'median' 'mean' 'std'}, ...        % Stats to calculate
                    'DataVars', qpDataVars);             % Vars to do stats on
                stats.Properties.VariableNames(2:end) = strcat('QP_', stats.Properties.VariableNames(2:end));
                trialDataTable = outerjoin(trialDataTable, stats,'Keys','TrialNumber','MergeKeys',true, 'LeftVariables', setdiff(trialDataTable.Properties.VariableNames, stats.Properties.VariableNames) );
                
                goodSP = sp(~isnan(sp.TrialNumber),:);
                stats = grpstats(goodSP, ...     % Selected rows of data
                    'TrialNumber', ...                  % GROUP VARIABLE
                    {'median' 'mean' 'std'}, ...        % Stats to calculate
                    'DataVars', spDataVars);             % Vars to do stats on
                stats.Properties.VariableNames(2:end) = strcat('SP_', stats.Properties.VariableNames(2:end));
                trialDataTable = outerjoin(trialDataTable, stats,'Keys','TrialNumber','MergeKeys',true, 'LeftVariables', setdiff(trialDataTable.Properties.VariableNames, stats.Properties.VariableNames) );
                
                trialDataTable.QP_Rate = trialDataTable.QP_GroupCount ./ trialDataTable.TotalGoodSec;
                
                
                
                
                
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % CALCULATE AVERAGE QP AND SP PROPERTIES ACROSS TRIALS
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if ( ~isempty(condition) )
                    varsToGroup = strcat('QP_mean_', qpDataVars(~contains(qpDataVars,'Left') & ~contains(qpDataVars,'Right')));
                    varsToGroup = horzcat({'QP_Rate' 'median_SPVX','median_SPVY','median_SPVT'}, varsToGroup);
                
                    trialDataTable.Condition = condition; % combination of condition variables
                    ConditionVarsNames = horzcat({'Condition'}, ConditionVarsNames);
                    for i=1:length(ConditionVarsNames)
                        stats = grpstats(trialDataTable, ...     % Selected rows of data
                            ConditionVarsNames{i}, ...                  % GROUP VARIABLE
                            {'mean' 'std'}, ...        % Stats to calculate
                            'DataVars', varsToGroup);             % Vars to do stats on
                        conditionStats = unstack(stats,setdiff(stats.Properties.VariableNames, ConditionVarsNames{i}),ConditionVarsNames{i});
                        conditionStats.Properties.RowNames = {};
                        sessionDataTable(:,intersect(conditionStats.Properties.VariableNames, sessionDataTable.Properties.VariableNames)) = [];
                        sessionDataTable = horzcat(sessionDataTable, conditionStats);
                    end
                end
                
                cprintf('blue','++ EyeTracking :: Done with eye tracking analsyis\n');
            end
        end
                
        function markData(this, options)
            options.Prepare_For_Analysis_And_Plots = 0;
            options.Preclear_Samples_Table = 0;
            options.Preclear_Trial_Table = 0;
            options.Preclear_Session_Table = 0;
            options.Mark_Data = 1;
            
            this.Session.runAnalysis(options);
        end
    end
            
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function Plot_VOG_RawData(this)
            data = this.Session.rawDataTable;
            
            VOGAnalysis.PlotRawTraces(data);
        end
        
        function Plot_VOG_Data_Explorer(this)
            VOGDataExplorer.Open(this.Session.samplesDataTable);
        end
            
        function [out, options] = Plot_VOG_Traces(this, options)
            
            out = [];
            if ( nargin == 1 )
                [~, options] = this. Plot_VOG_Traces('get_defaults');
            end
            
            if ( ischar(options) )
                command = options;
                switch( command)
                    case 'get_options'
                        options = VOGAnalysis.PlotTraces('get_options');
                        options.Show_Trials = { {'0','{1}'} };
                        return;
                    case 'get_defaults'
                        optionsDlg = VOGAnalysis.PlotTraces('get_options');
                        options = StructDlg(optionsDlg,'',[],[],'off');
                        return
                end
            end
            
            % Start plot
            
            data = this.Session.samplesDataTable;
            
            h = VOGAnalysis.PlotTraces(data, options);
            
            % Add vertical lines for trial begin and end
            if ( options.Show_Trials )
                for i=1:length(h)
                    axes(h(i));
                    yl = get(h(i),'ylim');
                    
                    trialStarts = nan(size(data.Time));
                    trialStarts(this.Session.trialDataTable.SampleStartTrial-1) = yl(1);
                    trialStarts(this.Session.trialDataTable.SampleStartTrial) = yl(2);
                    
                    trialStops = nan(size(data.Time));
                    trialStops(this.Session.trialDataTable.SampleStopTrial-1) = yl(1);
                    trialStops(this.Session.trialDataTable.SampleStopTrial) = yl(2);
                    
                    plot(data.Time, trialStarts,'color',[0.8 0.8 0.8]);
                    plot(data.Time, trialStops,'--','color',[0.8 0.8 0.8]);
                end
            end
        end
        
        function Plot_VOG_DebugCleaning(this)
            
            rawdata = this.Session.rawDataTable;
            data = this.Session.samplesDataTable;
            
            VOGAnalysis.PlotCleanAndResampledData(rawdata,data);
        end
        
        function Plot_VOG_SaccadeTraces(this)
            data = this.Session.samplesDataTable;
            VOGAnalysis.PlotQuickPhaseDebug(data)
        end
                
        function [out, options] = PlotAggregate_VOG_QuickPhase_MainSequence(this, sessions, options)
            
            out = [];
            if ( nargin == 1 )
                options = this.Plot_VOG_MainSequence('get_defaults');
            end
            
            if ( ischar(sessions) )
                command = sessions;
                switch( command)
                    case 'get_options'
                        options = VOGAnalysis.PlotMainsequence('get_options');
                        options.Component = { {'{XY}','X', 'Y','T', 'All', 'X and Y'} };
                        options.Select_Trial_Conditions = this.FilterTableByConditionVariable('get_filters');
                        return;
                    case 'get_defaults'
                        optionsDlg = VOGAnalysis.PlotMainsequence('get_options');
                        options = StructDlg(optionsDlg,'',[],[],'off');
                        return
                end
            end
            
            QPs = table();
            for session=sessions
                QPs = vertcat(session.analysisResults.QuickPhases);
            end
            
            [props, ~, filters] = this.FilterTableByConditionVariable(QPs, options.Select_Trial_Conditions);
            
            xdata = {};
            ydata = {};
            legendText = {};
            for i=1:height(props)
                switch(options.Component)
                    case 'XY'
                        xdata{i} = props.Data{i}.Amplitude;
                        ydata{i} = props.Data{i}.PeakSpeed;
                    case 'X'
                        xdata{i} = props.Data{i}.X_Amplitude;
                        ydata{i} = props.Data{i}.X_PeakSpeed;
                    case 'Y'
                        xdata{i} = props.Data{i}.Y_Amplitude;
                        ydata{i} = props.Data{i}.Y_PeakSpeed;
                    case 'T'
                        xdata{i} = props.Data{i}.T_Amplitude;
                        ydata{i} = props.Data{i}.T_PeakSpeed;
                    case 'All'
                        xdata{i} = {props.Data{i}.X_Amplitude, props.Data{i}.Y_Amplitude, props.Data{i}.T_Amplitude};
                        ydata{i} = {props.Data{i}.X_PeakSpeed, props.Data{i}.Y_PeakSpeed, props.Data{i}.T_PeakSpeed};
                        legendText{i}  = {'Horizotal', 'Vertical', 'Torsional'};
                    case 'X and Y'
                        xdata{i} = {props.Data{i}.X_Amplitude, props.Data{i}.Y_Amplitude};
                        ydata{i} = {props.Data{i}.X_PeakSpeed, props.Data{i}.Y_PeakSpeed};
                        legendText{i}  = {'Horizotal', 'Vertical'};
                end
            end
            
            out = VOGAnalysis.PlotMainsequence(options, xdata{1}, ydata{1} );
            if (~isempty(legendText) )
                legend(out.forLegend, legendText{1},'box','off');
            end
            title(['Main sequence - ', strrep(filters{1}, '_', ' ')]);
        end
          
        function [out, options] = PlotAggregate_VOG_QuickPhase_Distribution(this, sessions, options)
            
            out = [];
            if ( nargin == 1 )
                options = this.Plot_VOG_QuickPhase_Distribution('get_defaults');
            end
            
            if ( ischar(sessions) )
                command = sessions;
                switch( command)
                    case 'get_options'
                        options = VOGAnalysis.PlotHistogram('get_options');
                        options.Feature =  {'{Amplitude}|PeakSpeed|Displacement'};
                        options.Component = { '{X}|Y|T|All|X and Y' };
                        options.Select_Trial_Conditions = this.FilterTableByConditionVariable('get_filters');
                        options.Figures_Axes_Lines_Order = {{...
                            '{Sessions-Conditions-Components}' 'Sessions-Components-Conditions' ...
                            'Conditions-Sessions-Components' 'Conditions-Components-Sessions' ...
                            'Components-Sessions-Conditions'  'Components-Conditions-Sessions'}};
                        return;
                    case 'get_defaults'
                        optionsDlg = VOGAnalysis.PlotHistogram('get_options');
                        options = StructDlg(optionsDlg,'',[],[],'off');
                        return
                end
            end
            
            switch(options.Component)
                case 'XY'
                    components = options.Feature;
                    componentNames = {'Polar'};
                case 'X'
                    components = {['X_' options.Feature]};
                    componentNames = {'Horizontal'};
                case 'Y'
                    components = {['Y' options.Feature]};
                    componentNames = {'Vertical'};
                case 'T'
                    components = {['T' options.Feature]};
                    componentNames = {'Torsion'};
                case 'All'
                    components = {['X_' options.Feature], ['Y_' options.Feature], ['T_' options.Feature]};
                    componentNames = {'Horizontal', 'Vertical', 'Torsion'};
                case 'X and Y'
                    components = {['X_' options.Feature], ['Y_' options.Feature]};
                    componentNames = {'Horizontal'};
            end
            
            allprops = table();
            for i=1:length(sessions)
                [sessionProps, ~] = this.FilterTableByConditionVariable(sessions(i).analysisResults.QuickPhases, options.Select_Trial_Conditions, components, componentNames);
                sessionProps.Session = categorical(cellstr(repmat(sessions(i).shortName,height(sessionProps),1)));
                allprops = vertcat(allprops, sessionProps);
            end
                        
            nplot1 = [1 1 1 2 2 2 2 2 3 2 3 3 3 3 4 4 4 4 4 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5];
            nplot2 = [1 2 3 2 3 3 4 4 3 5 4 4 5 5 4 5 5 5 5 5 5 5 5 5 6 6 6 6 6 6 7 7 7 7 7 7];
                        
            COLUMNS = {'Session','Condition', 'Component'};
            ELEMENTS = {};
            for i=1:3
                ELEMENTS{i} = unique(allprops.(COLUMNS{i}));
            end
            for i=1:length(ELEMENTS{1})
                figure
                for j=1:length(ELEMENTS{2})
                    ax = subplot(nplot1(length(ELEMENTS{2})),nplot2(length(ELEMENTS{2})),j);
                    xdata = allprops(allprops.(COLUMNS{1})==ELEMENTS{1}(i) & allprops.(COLUMNS{2})==ELEMENTS{2}(j),:);
                    out = VOGAnalysis.PlotHistogram(ax, options, xdata.Data );
                end
            end
            if (~isempty(legendText) )
                legend(out.forLegend, string(ELEMENTS{3}),'box','off');
            end
            filters = cellstr(filters);
            title([options.Feature ' distribution - ', strrep(filters{1}, '_', ' ')]);
        end
        
        function [out, options] = PlotAggregate(this, sessions, options)
            
        end
    end
    
end



