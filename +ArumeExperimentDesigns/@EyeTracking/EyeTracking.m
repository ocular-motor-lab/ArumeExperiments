classdef EyeTracking  < ArumeCore.ExperimentDesign
    
    properties
        eyeTracker;
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods (Access=protected)
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeCore.ExperimentDesign(this, importing);
            
            dlg.UseEyeTracker       = { {'0' '{1}'} };
            dlg.EyeTracker = { {'{OpenIris}' 'Fove'} };
            
            if ( exist('importing','var') && importing )
                dlg.DataFiles = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.EventFiles = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.CalibrationFiles = { {['uigetfile(''' fullfile(pwd,'*.cal') ''',''MultiSelect'', ''on'')']} };
            end
        end
        
        function shouldContinue = initBeforeRunning( this )
            
            if ( this.ExperimentOptions.UseEyeTracker )
                this.eyeTracker = ArumeHardware.VOG();
                result = this.eyeTracker.Connect();
                if ( result )
                    this.eyeTracker.SetSessionName(this.Session.name);
                    this.eyeTracker.StartRecording();
                    this.AddTrialStartCallback(@this.TrialStartCallback)
                    this.AddTrialStopCallback(@this.TrialStopCallBack)
                else
                    shouldContinue = 0;
                    this.eyeTracker = [];
                    return;
                end
            end
            
            shouldContinue = 1;
        end
        
        function cleanAfterRunning(this)
            
            if ( this.ExperimentOptions.UseEyeTracker && ~isempty(this.eyeTracker))
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
            if ( isempty(this.eyeTracker))
                return;
            end
            
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
            if ( isempty(this.eyeTracker))
                return;
            end
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
            
            if ( isfield(this.ExperimentOptions,'EyeTracker') )
                eyeTrackerType = this.ExperimentOptions.EyeTracker;
            else
                eyeTrackerType = 'OpenIris';
            end
            
            switch(eyeTrackerType)
                case 'OpenIris'
                    calibrationsForEachTrial = [];
                    
                    % if this session is not a calibration
                    if ( ~strcmp(this.Session.experimentDesign.Name, 'Calibration') )

                        % TODO: FIND A BETTER WAY TO GET ALL THE RELATED
                        % SESSIONS
                        arume = Arume('nogui');
                        calibrationSessions = arume.currentProject.findSessionBySubjectAndExperiment(this.Session.subjectCode, 'Calibration');
                        calibrationTables = {};
                        calibrationCRTables = {};
                        calibrationTimes = NaT(0);
                        calibrationNames = {};
                        for i=1:length(calibrationSessions)
               
                            if ( ~isfield( calibrationSessions(i).analysisResults, 'calibrationTable') || isempty(calibrationSessions(i).analysisResults.calibrationTable))
                                % analyze the calibration sessions just in case
                                % they have not before
                                analysisOptions = arume.getAnalysisOptionsDefault( calibrationSessions(i) );
                                calibrationSessions(i).runAnalysis(analysisOptions);
                            end

                            if ( isfield( calibrationSessions(i).analysisResults, 'calibrationTable') )
                                calibrationTables{i} = calibrationSessions(i).analysisResults.calibrationTable;
                                calibrationCRTables{i} = calibrationSessions(i).analysisResults.calibrationTableCR;
                            else
                                calibrationTables{i} = table();
                                calibrationCRTables{i} = table();
                            end
                            calibrationTimes(i) = datetime(calibrationSessions(i).currentRun.pastTrialTable.DateTimeTrialStart{end});
                            calibrationNames{i} =  calibrationSessions(i).name;
                        end

                        calibrations = table(string(calibrationNames'), calibrationTables', calibrationCRTables', calibrationTimes','VariableNames',{'SessionName','CalibrationTable','CalibrationCRTable','DateTime'});
                        calibrations = sortrows(calibrations,'DateTime');

                        % loop through trials to find the relavant calibration
                        calibrationsForEachTrial = nan(height(this.Session.currentRun.pastTrialTable),1);
                        for i=1:height(this.Session.currentRun.pastTrialTable)
                            trialStartTime = datetime(this.Session.currentRun.pastTrialTable.DateTimeTrialStart(i));

                            pastClosestCalibration = find((trialStartTime - calibrations.DateTime)>0,1, 'last');
                            if ( isempty( pastClosestCalibration))
                                continue;
                            end

                            if (i==1)
                                if ( (trialStartTime-calibrations.DateTime(pastClosestCalibration)) < minutes(5) )
                                    calibrationsForEachTrial(i) = pastClosestCalibration;
                                end
                            else
                                previousTrialCalibration = calibrationsForEachTrial(i-1);
                                % TODO consider the case when you take a
                                % break and forget to do a calibration
                                % before restarting. Right now we will keep
                                % the calibration from the previous trial
                                
                                if( previousTrialCalibration == pastClosestCalibration)
                                    % this is the case for a following trial
                                    % after a calibration
                                    calibrationsForEachTrial(i) = previousTrialCalibration;
                                else
                                    % this is the case for trial following a
                                    % break when one or more calibrations where
                                    % performed
                                    calibrationsForEachTrial(i) = pastClosestCalibration;
                                end
                            end
                        end

                        % if we did not find any calibration for the trials
                        % we behave as if there were no calibrations
                        if ( all(isnan(calibrationsForEachTrial)))
                            calibrationsForEachTrial = [];
                        end
                    end


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
                    




                    if ( isempty(calibrationsForEachTrial) )
                        [samplesDataTable, cleanedData, calibratedData, rawData] = VOGAnalysis.LoadCleanAndResampleData(this.Session.dataPath, dataFiles, calibrationFiles, options);
                    else
                        % Dealing with trials without a calibration. Add an
                        % empty calibration to the table and change the NaN
                        % indices for the index of the empty table
                        calibrations.CalibrationTable{end+1} = table();
                        calibrationsForEachTrial(isnan(calibrationsForEachTrial)) = height(calibrations);
                        
                        calibrationTables = [calibrations(calibrationsForEachTrial,:) this.Session.currentRun.pastTrialTable(:,'FileNumber')];
                        [~,idx] = unique(calibrationTables.SessionName);
                        calibrfationTablesPerFile = calibrationTables(idx,:);
                        [samplesDataTable, cleanedData, calibratedData, rawData] = VOGAnalysis.LoadCleanAndResampleDataArumeMultiCalibration(this.Session.dataPath, dataFiles, calibrationFiles, calibrfationTablesPerFile , options);
                    end

                case 'Fove'
                    
                    samplesDataTable = table();
                    cleanedData = table();
                    calibratedData = table();
                    rawData = table();
                    
                    if ( ~isprop(this.Session.currentRun, 'LinkedFiles' ) || ~isfield(this.Session.currentRun.LinkedFiles,  'foveDataFile') )
                        return;
                    end
                    
                    dataFiles = this.Session.currentRun.LinkedFiles.foveDataFile;
                    if (~iscell(dataFiles) )
                        dataFiles = {dataFiles};
                    end
                   
                    [samplesDataTable, cleanedData, rawData] = VOGAnalysis.LoadCleanAndResampleDataFOVE(this.Session.dataPath, dataFiles, options);
                    
            end
        end
        
        function trialDataTable = PrepareTrialDataTable( this, trialDataTable, options)
            samplesData = this.Session.samplesDataTable;
            
            if ( isfield(this.ExperimentOptions,'EyeTracker') )
                eyeTrackerType = this.ExperimentOptions.EyeTracker;
            else
                eyeTrackerType = 'OpenIris';
            end
            
            if ( ~isempty( samplesData ) )
                
                
                switch(eyeTrackerType)
                    case 'OpenIris'
                        
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
                    case 'Fove'
                        % Find the samples that mark the begining and ends of trials
                        trialDataTable.SampleStartTrial = nan(size(trialDataTable.TrialNumber));
                        trialDataTable.SampleStopTrial = nan(size(trialDataTable.TrialNumber));
                        if ( ~any(strcmp(samplesData.Properties.VariableNames, 'FileNumber')))
                            samplesData.FileNumber = ones(size(samplesData.Time));
                        end
                        for i=1:height(trialDataTable)
                            trialDataTable.SampleStartTrial(i) = find(samplesData.FileNumber' == trialDataTable.FileNumber(i) & samplesData.RawTime'>=trialDataTable.TrialStartTime(i),1,'first');
                            trialDataTable.SampleStopTrial(i) = find(samplesData.FileNumber' == trialDataTable.FileNumber(i) & samplesData.RawTime'<=trialDataTable.TrialEndTime(i),1,'last');
                        end
                        
                        % Build a column for the samples with the trial number
                        samplesData.TrialNumber = nan(size(samplesData.FrameNumber));
                        for i=1:height(trialDataTable)
                            idx = trialDataTable.SampleStartTrial(i):trialDataTable.SampleStopTrial(i);
                            samplesData.TrialNumber(idx) = trialDataTable.TrialNumber(i);

                        end

                        % Add average head position data to the trialtable
                        trialDataTable.HeadYaw = nan(height(trialDataTable),1);
                        trialDataTable.HeadPitch = nan(height(trialDataTable),1);
                        trialDataTable.HeadRoll = nan(height(trialDataTable),1);
                        for i=1:height(trialDataTable)
                            idx = trialDataTable.SampleStartTrial(i):trialDataTable.SampleStopTrial(i);

                            trialDataTable.HeadYaw(i) = mean(samplesData.HeadYaw(idx),1,"omitnan");
                            trialDataTable.HeadPitch(i) = mean(samplesData.HeadPitch(idx),1,"omitnan");
                            trialDataTable.HeadRoll(i) = mean(samplesData.HeadRoll(idx),1,"omitnan");
                        end
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
                    samplesData.(LRdataVars{i}) = mean(samplesData{:,{['Left' LRdataVars{i}],['Right' LRdataVars{i}]}},2,'omitnan');
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
            return
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % CALCULATE AVERAGE EYE MOVEMENT ACROSS TRIALS
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            trialDataTable = this.Session.trialDataTable;
            varsToGroup = trialDataTable.Properties.UserData.EyeTrackingPrepareTrialDataTableVariables;
            
            % IT IS TOO SLOW NOW! 11/23/2021 CANNOT DO ALL THIS WHEN THERE
            % ARE MANY CONDITIONS OR MANY LEVELS
            return;

            % Also calculate average across conditions for each of the
            % values of each condition variables. 
            % Also create a variable that containes all the combinations of
            % all conditions and avarege across those
            ConditionVarsNames = {};
            condition = [];
            for i=1:length(this.Session.experimentDesign.ConditionVars) %TODO CHANGE
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
            
            if ( 0 )
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
                    
                    vmed = nanmedfilt(mean([vleft, vright],2),T,1/2,'omitnan');
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
                if ( width(this.TrialTable) > 5 ) % TODO: a bit ugly! 
                    % experiments that are imported behave a bit different
                    % than experiments that are run original with arume. 
                    ConditionVarsNames = this.TrialTable.Properties.VariableNames(6:end);
                else
                    ConditionVarsNames = this.Session.currentRun.pastTrialTable.Properties.VariableNames(6:end); 
                end
                condition = [];
                for i=1:length(ConditionVarsNames)
                    conditionVarLevels = categories(categorical(this.Session.currentRun.pastTrialTable{:,ConditionVarsNames{i}}));
                    if ( numel(conditionVarLevels)>1)
                        if (isempty(condition) )
                            condition = string(trialDataTable{:,ConditionVarsNames(i)});
                        else
                            condition = strcat(condition,'_', string(trialDataTable{:,ConditionVarsNames(i)}));
                        end
                    end
                end
                
                
                % Build a column for the samples with the trial number
                samplesDataTable.TrialNumber = nan(size(samplesDataTable.FrameNumber));
                for i=1:height(trialDataTable)
                    idx = trialDataTable.SampleStartTrial(i):trialDataTable.SampleStopTrial(i);
                    samplesDataTable.TrialNumber(idx) = trialDataTable.TrialNumber(i);
                end
                
                % add columns to quick and slow phases for trial number and
                % also the values of each condition variable that
                % corresponds with that trial
                [qp, sp] = VOGAnalysis.GetQuickAndSlowPhaseTable(samplesDataTable);
                qpDataVars = qp.Properties.VariableNames;
                spDataVars = sp.Properties.VariableNames;
                
                warning('off','MATLAB:table:RowsAddedNewVars');
                qp.TrialNumber = samplesDataTable.TrialNumber(qp.StartIndex);
                sp.TrialNumber = samplesDataTable.TrialNumber(sp.StartIndex);
                for i=1:numel(ConditionVarsNames)
                    if ( iscategorical(trialDataTable{qp.TrialNumber(~isnan(qp.TrialNumber)),ConditionVarsNames{i}}))
                        qp{~isnan(qp.TrialNumber),ConditionVarsNames{i}} =  categorical(trialDataTable{qp.TrialNumber(~isnan(qp.TrialNumber)),ConditionVarsNames{i}});
                    elseif iscellstr(trialDataTable{qp.TrialNumber(~isnan(qp.TrialNumber)),ConditionVarsNames{i}})
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
                
                
                

                % IT IS TOO SLOW NOW! 11/23/2021 CANNOT DO ALL THIS WHEN THERE
                % ARE MANY CONDITIONS OR MANY LEVELS
                return;

                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % CALCULATE AVERAGE QP AND SP PROPERTIES ACROSS TRIALS
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if ( ~isempty(condition) )
                    varsToGroup = strcat('QP_mean_', qpDataVars(~contains(qpDataVars,'Left') & ~contains(qpDataVars,'Right')));
                    varsToGroup = horzcat({'QP_Rate' 'median_SPVX','median_SPVY','median_SPVT'}, varsToGroup);
                    varsToGroup = intersect(varsToGroup, trialDataTable.Properties.VariableNames);

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
            switch(this.ExperimentOptions.EyeTracker) 
                case 'OpenIris'
                    data = this.Session.rawDataTable;
                    VOGAnalysis.PlotRawTraces(data);
                case 'Fove'
                    data = this.Session.rawDataTable;
                    VOGAnalysis.PlotRawTraces(data,'Fove');
            end
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
                        options.Component = { '{XY}|X|Y|T|All|X and Y' };
                        filterNames = fieldnames(this.FilterTableByConditionVariable('get_filters'));
                        options.DataToInclude = {filterNames};
                        options.Select_Trial_Conditions = this.FilterTableByConditionVariable('get_filters');
                        options.Figures_Axes_Lines_Order = {{...
                            '{Sessions-Conditions-Components}' 'Sessions-Components-Conditions' ...
                            'Conditions-Sessions-Components' 'Conditions-Components-Sessions' ...
                            'Components-Sessions-Conditions'  'Components-Conditions-Sessions'}};
                        return;
                    case 'get_defaults'
                        optionsDlg = VOGAnalysis.PlotMainsequence('get_options');
                        options = StructDlg(optionsDlg,'',[],[],'off');
                        return
                end
            end

            % Pick the variables that corresponds with the options for the
            % components. This can be single or multiple. 
            componentNames = {options.Component};
                switch(options.Component)
                    case 'XY'
                        Xcomponents = {'Amplitude'};
                        Ycomponents = {'PeakSpeed'};
                    case 'X'
                        Xcomponents = {'X_Amplitude'};
                        Ycomponents = {'X_PeakSpeed'};
                    case 'Y'
                        Xcomponents = {'Y_Amplitude'};
                        Ycomponents = {'Y_PeakSpeed'};
                    case 'T'
                        Xcomponents = {'T_Amplitude'};
                        Ycomponents = {'T_PeakSpeed'};
                    case 'All'
                        Xcomponents = {'X_Amplitude' 'Y_Amplitude' 'T_Amplitude'};
                        Ycomponents = {'X_PeakSpeed' 'Y_PeakSpeed' 'T_PeakSpeed'};
                        componentNames  = {'Horizotal', 'Vertical', 'Torsional'};
                    case 'X and Y'
                        Xcomponents = {'X_Amplitude' 'Y_Amplitude'};
                        Ycomponents = {'X_PeakSpeed' 'Y_PeakSpeed'};
                        componentNames  = {'Horizotal', 'Vertical'};
                end

            Xallprops = table();
            for i=1:length(sessions)
                [sessionProps, ~] = this.FilterTableByConditionVariable(sessions(i).analysisResults.QuickPhases, options.Select_Trial_Conditions, Xcomponents, componentNames, options.DataToInclude);
                sessionProps.Session = categorical(cellstr(repmat(sessions(i).shortName,height(sessionProps),1)));
                Xallprops = vertcat(Xallprops, sessionProps);
            end
            
            Yallprops = table();
            for i=1:length(sessions)
                [sessionProps, ~] = this.FilterTableByConditionVariable(sessions(i).analysisResults.QuickPhases, options.Select_Trial_Conditions, Ycomponents, componentNames, options.DataToInclude);
                sessionProps.Session = categorical(cellstr(repmat(sessions(i).shortName,height(sessionProps),1)));
                Yallprops = vertcat(Yallprops, sessionProps);
            end
                        
            
            
%             out = VOGAnalysis.PlotMainsequence(options, xdata, ydata );
%             if (~isempty(legendText) )
%                 legend(out.forLegend, legendText,'box','off');
%             end
% %             title(['Main sequence - ', strrep(filters, '_', ' ')]);

                        
            nplot1 = [1 1 1 2 2 2 2 2 3 2 3 3 3 3 4 4 4 4 4 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5];
            nplot2 = [1 2 3 2 3 3 4 4 3 5 4 4 5 5 4 5 5 5 5 5 5 5 5 5 6 6 6 6 6 6 7 7 7 7 7 7];
            
            
            
            
            
            
            
                        
            COLUMNS = {'Session','Condition', 'Component'};
            switch(options.Figures_Axes_Lines_Order)
                case 'Sessions-Conditions-Components'
                    COLUMNS = {'Session','Condition', 'Component'};
                case 'Sessions-Components-Conditions'
                    COLUMNS = {'Session', 'Component','Condition'};
                case 'Conditions-Sessions-Components'
                    COLUMNS = {'Condition', 'Session', 'Component'};
                case 'Conditions-Components-Sessions'
                    COLUMNS = {'Condition', 'Component', 'Session'};
                case 'Components-Sessions-Conditions'
                    COLUMNS = {'Component', 'Session','Condition'};
                case 'Components-Conditions-Sessions'
                    COLUMNS = {'Component','Condition', 'Session'};
            end

            ELEMENTS = {};
            for i=1:3
                ELEMENTS{i} = unique(Xallprops.(COLUMNS{i}),'stable');
            end
            for i=1:length(ELEMENTS{1})
                figure('name',string(ELEMENTS{1}(i)))
                for j=1:length(ELEMENTS{2})
                    ax = subplot(nplot1(length(ELEMENTS{2})),nplot2(length(ELEMENTS{2})),j,'nextplot','add');
                    xdata = Xallprops(Xallprops.(COLUMNS{1})==ELEMENTS{1}(i) & Xallprops.(COLUMNS{2})==ELEMENTS{2}(j),:);
                    ydata = Yallprops(Yallprops.(COLUMNS{1})==ELEMENTS{1}(i) & Yallprops.(COLUMNS{2})==ELEMENTS{2}(j),:);                    
                    title = char(strcat('Main seq. - ', strrep(string(ELEMENTS{2}(j)), '_', ' ')));
                    out = VOGAnalysis.PlotMainsequence(ax, xdata.Data{1}, ydata.Data{1}, title);
                end
            end
            legend(out.forLegend, strrep(string(ELEMENTS{3}),'_', ' '),'box','off');

        end
          


        function [out, options] = PlotAggregate_VOG_QuickPhase_Distribution(this, sessions, options)
            
            out = [];
            if ( nargin == 1 )
                % if passing no parameters get the default options
                options = this.PlotAggregate_VOG_QuickPhase_Distribution('get_defaults');
            end
            
            if ( ischar(sessions) )
                command = sessions;
                switch( command)
                    case 'get_options'
                        options = VOGAnalysis.PlotHistogram('get_options');
                        options.Feature =  {'{Amplitude}|PeakSpeed|Displacement|Direction'};
                        options.Component = { '{XY}|X|Y|T|All|X and Y' };
                        filterNames = fieldnames(this.FilterTableByConditionVariable('get_filters'));
                        options.DataToInclude = {filterNames};
                        options.Select_Trial_Conditions = this.FilterTableByConditionVariable('get_filters');
                        options.Figures_Axes_Lines_Order = {{...
                            '{Sessions-Conditions-Components}' 'Sessions-Components-Conditions' ...
                            'Conditions-Sessions-Components' 'Conditions-Components-Sessions' ...
                            'Components-Sessions-Conditions'  'Components-Conditions-Sessions'}};
                        return;
                    case 'get_defaults'
                        optionsDlg = VOGAnalysis.PlotAggregate_VOG_QuickPhase_Distribution('get_options');
                        options = StructDlg(optionsDlg,'',[],[],'off');
                        return
                end
            end
            
            % Get the right units for the labels depending on the feature
            % thatis being plotted
            switch(options.Feature)
                case 'Amplitude'
                    units = 'Deg';
                case 'PeakSpeed'
                    units = 'Deg/s';
                case 'Displacement' 
                    units = 'Deg';
                case 'Direction'
                    units = 'Deg';
            end

            % Pick the variables that corresponds with the options for the
            % components. This can be single or multiple. 
            switch(options.Component)
                case 'XY'
                    components = {options.Feature};
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
                    componentNames = {'Horizontal', 'Vertical'};
            end
            
            allprops = table();
            for i=1:length(sessions)
                [sessionProps, ~] = this.FilterTableByConditionVariable(sessions(i).analysisResults.QuickPhases, options.Select_Trial_Conditions, components, componentNames, options.DataToInclude);
                sessionProps.Session = categorical(cellstr(repmat(sessions(i).shortName,height(sessionProps),1)));
                allprops = vertcat(allprops, sessionProps);
            end
                        
            nplot1 = [1 1 1 2 2 2 2 2 3 2 3 3 3 3 4 4 4 4 4 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5];
            nplot2 = [1 2 3 2 3 3 4 4 3 5 4 4 5 5 4 5 5 5 5 5 5 5 5 5 6 6 6 6 6 6 7 7 7 7 7 7];
            

            COLUMNS = {'Session','Condition', 'Component'};
            switch(options.Figures_Axes_Lines_Order)
                case 'Sessions-Conditions-Components'
                    COLUMNS = {'Session','Condition', 'Component'};
                case 'Sessions-Components-Conditions'
                    COLUMNS = {'Session', 'Component','Condition'};
                case 'Conditions-Sessions-Components'
                    COLUMNS = {'Condition', 'Session', 'Component'};
                case 'Conditions-Components-Sessions'
                    COLUMNS = {'Condition', 'Component', 'Session'};
                case 'Components-Sessions-Conditions'
                    COLUMNS = {'Component', 'Session','Condition'};
                case 'Components-Conditions-Sessions'
                    COLUMNS = {'Component','Condition', 'Session'};
            end

            ELEMENTS = {};
            for i=1:3
                ELEMENTS{i} = unique(allprops.(COLUMNS{i}),'stable');
            end
            for i=1:length(ELEMENTS{1})
                figure('name',string(ELEMENTS{1}(i)))
                for j=1:length(ELEMENTS{2})
                    ax = subplot(nplot1(length(ELEMENTS{2})),nplot2(length(ELEMENTS{2})),j);
                    xdata = allprops(allprops.(COLUMNS{1})==ELEMENTS{1}(i) & allprops.(COLUMNS{2})==ELEMENTS{2}(j),:);
                    title = strcat(options.Feature, ' distribution - ', strrep(string(ELEMENTS{2}(j)), '_', ' '));
                    xlab = [options.Feature '(' units ')'];
                    out = VOGAnalysis.PlotHistogram(ax, options, xdata.Data, [], title, xlab );
                end
            end
            legend(out.forLegend, strrep(string(ELEMENTS{3}),'_', ' '),'box','off');

        end
        
        
        function [out, options] = PlotAggregate_VOG_QuickPhase_Polar_Distribution(this, sessions, options)
            
            out = [];
            if ( nargin == 1 )
                % if passing no parameters get the default options
                options = this.PlotAggregate_VOG_QuickPhase_Distribution('get_defaults');
            end
            
            if ( ischar(sessions) )
                command = sessions;
                switch( command)
                    case 'get_options'
                        options = struct();%VOGAnalysis.PlotHistogram('get_options');
                        options.Number_of_bins = 36;
                        options.Feature =  {'{Direction}|NOTIMPLEMENTED'};
                        options.Component = { '{Both eyes combined}|Left eye|Right eye|Left and right eye' };
                        options.Normalize = { '{No}|By area|By max' };
                        options.Average = { {'{0}','1'} };
                        filterNames = fieldnames(this.FilterTableByConditionVariable('get_filters'));
                        options.Trials_to_Include_Filter1 = {filterNames};
                        options.Trials_to_Include_Filter2 = {filterNames};
                        options.Trial_Groups_To_Plot = this.FilterTableByConditionVariable('get_filters');
                        options.Figures_Axes_Lines_Order = {{...
                            '{Sessions-Groups-Components}' 'Sessions-Components-Groups' ...
                            'Groups-Sessions-Components' 'Groups-Components-Sessions' ...
                            'Components-Sessions-Groups'  'Components-Groups-Sessions'}};
                        options.QuickPhase_Filter = {{...
                            '{data.Amplitude > 0}' ...
                            'data.Amplitude <= 1' 'data.Amplitude <= 3' 'data.Amplitude <= 5' 'data.Amplitude < 10' ...
                            'data.Amplitude > 1' 'data.Amplitude > 3' 'data.Amplitude > 5' 'data.Amplitude > 10'
                            }};
                        return;
                    case 'get_defaults'
                        optionsDlg = VOGAnalysis.PlotAggregate_VOG_QuickPhase_Distribution('get_options');
                        options = StructDlg(optionsDlg,'',[],[],'off');
                        return
                end
            end
            
            % Get the right units for the labels depending on the feature
            % thatis being plotted
            switch(options.Feature)
                case 'Direction'
                    units = 'Deg';
            end

            % Pick the variables that corresponds with the options for the
            % components. This can be single or multiple. 
            switch(options.Component)
                case 'Both eyes combined'
                    options.Component = { '{}|||' };
                    components = {options.Feature};
                    componentNames = {'Both eyes'};
                case 'Left eye'
                    components = {['Left_' options.Feature]};
                    componentNames = {'Left eye'};
                case 'Right eye'
                    components = {['Right_' options.Feature]};
                    componentNames = {'Right eye'};
                case 'Left and right eye'
                    components = {['Left_' options.Feature], ['Right_' options.Feature]};
                    componentNames = {'Left eye', 'Right eye'};
            end
            
            allprops = table();
            for i=1:length(sessions)
                [sessionProps, ~] = this.FilterTableByConditionVariable(sessions(i).analysisResults.QuickPhases, options.Trial_Groups_To_Plot, components, componentNames, options.Trials_to_Include_Filter1, options.Trials_to_Include_Filter2, options.QuickPhase_Filter);
                sessionProps.Session = categorical(cellstr(repmat(sessions(i).shortName,height(sessionProps),1)));
                allprops = vertcat(allprops, sessionProps);
            end
                        
            nplot1 = [1 1 1 2 2 2 2 2 3 2 3 3 3 3 4 4 4 4 4 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5];
            nplot2 = [1 2 3 2 3 3 4 4 3 5 4 4 5 5 4 5 5 5 5 5 5 5 5 5 6 6 6 6 6 6 7 7 7 7 7 7];
            

            COLUMNS = {'Session','Condition', 'Component'};
            switch(options.Figures_Axes_Lines_Order)
                case 'Sessions-Groups-Components'
                    COLUMNS = {'Session','Condition', 'Component'};
                case 'Sessions-Components-Groups'
                    COLUMNS = {'Session', 'Component','Condition'};
                case 'Groups-Sessions-Components'
                    COLUMNS = {'Condition', 'Session', 'Component'};
                case 'Groups-Components-Sessions'
                    COLUMNS = {'Condition', 'Component', 'Session'};
                case 'Components-Sessions-Groups'
                    COLUMNS = {'Component', 'Session','Condition'};
                case 'Components-Groups-Sessions'
                    COLUMNS = {'Component','Condition', 'Session'};
            end

            if ( ~options.Average)
                ELEMENTS = {};
                for i=1:3
                    ELEMENTS{i} = unique(allprops.(COLUMNS{i}),'stable');
                end
                hforLegend = [];
                for i=1:length(ELEMENTS{1})
                    figure('name',string(ELEMENTS{1}(i)),'color','w')
                    for j=1:length(ELEMENTS{2})
                        ax1 = subplot(nplot1(length(ELEMENTS{2})),nplot2(length(ELEMENTS{2})),j);
                        ax = polaraxes('Units',ax1.Units,'Position',ax1.Position, 'nextplot','add'); % https://www.mathworks.com/matlabcentral/answers/443441-can-i-plot-multiple-polar-histograms-together
                        delete(ax1);
                        xdata = allprops(allprops.(COLUMNS{1})==ELEMENTS{1}(i) & allprops.(COLUMNS{2})==ELEMENTS{2}(j),:);
                        tit = strcat(options.Feature, ' distribution - ', strrep(string(ELEMENTS{2}(j)), '_', ' '));
                        xlab = [options.Feature '(' units ')'];
                        for k=1:length(xdata.Data)
                            angles = rad2deg(xdata.Data{k});
                            binsize = 360/options.Number_of_bins;

                            binedges = (-180-binsize/2):binsize:(180-binsize/2); % shift the bins to have one bin centered in zero
                            bincenters = (binedges(1:end-1) + binedges(2:end))/2;

                            angles(angles>max(binedges)) = -360+angles(angles>max(binedges)); % so the circular binning works with our bin shift

                            h = histcounts(angles, binedges);
                            switch(options.Normalize)
                                case 'By area'
                                    h = h/sum(h);
                                case 'By max'
                                    h = h/max(h);
                            end

                            radBinsCenter = deg2rad(bincenters);

                            h = polarplot(ax, radBinsCenter([1:end 1]), h([1:end 1]));

                            hforLegend(k) = h;

                        end

                        title(tit);
                    end
                end
                ll = legend(hforLegend, strrep(string(ELEMENTS{3}),'_', ' '),'box','off');
                set(ll,'Location','northeast');
            else
                ELEMENTS = {};
                for i=1:3
                    ELEMENTS{i} = unique(allprops.(COLUMNS{i}),'stable');
                end
                hforLegend = [];
                figure('color','w')
                for i=1:length(ELEMENTS{1})
                    tit = ['Average ' options.Feature ' distribution - ' strrep(char(ELEMENTS{1}(i)), '_', ' ')];
                    ax1 = subplot(nplot1(length(ELEMENTS{1})),nplot2(length(ELEMENTS{1})),i);
                    ax = polaraxes('Units',ax1.Units,'Position',ax1.Position, 'nextplot','add'); % https://www.mathworks.com/matlabcentral/answers/443441-can-i-plot-multiple-polar-histograms-together
                    delete(ax1);
                    for j=1:length(ELEMENTS{2})
                        xdata = allprops(allprops.(COLUMNS{1})==ELEMENTS{1}(i) & allprops.(COLUMNS{2})==ELEMENTS{2}(j),:);
                        allH = [];
                        for k=1:length(xdata.Data)
                            angles = rad2deg(xdata.Data{k});
                            binsize = 360/options.Number_of_bins;

                            binedges = (-180-binsize/2):binsize:(180-binsize/2); % shift the bins to have one bin centered in zero
                            bincenters = (binedges(1:end-1) + binedges(2:end))/2;

                            angles(angles>max(binedges)) = -360+angles(angles>max(binedges)); % so the circular binning works with our bin shift

                            h = histcounts(angles, binedges);
                            switch(options.Normalize)
                                case 'By area'
                                    h = h/sum(h);
                                case 'By max'
                                    h = h/max(h);
                            end

                            radBinsCenter = deg2rad(bincenters);

                            allH = vertcat(allH, h);
                        end

                        havg = mean(allH, 1);
                        h = polarplot(ax, radBinsCenter([1:end 1]), havg([1:end 1]),'linewidth',2);

                        xlab = [options.Feature '(' units ')'];
                        hforLegend(j) = h;
                        title(tit);
                    end
                end
                ll = legend(hforLegend, strrep(string(ELEMENTS{2}),'_', ' '),'box','off');
                set(ll,'Location','northeast');
            end

        end
        
        
        function [out, options] = PlotAggregate(this, sessions, options)
            
        end
    end
    
end



