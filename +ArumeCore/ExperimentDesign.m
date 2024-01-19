classdef ExperimentDesign < handle
    %EXPERIMENTDESIGN Base class for all experiment designs (paradigms).
    % All experiment designs must inherit from this class and must override
    % some of the methods.
    %
    % A experiment design contains the main trail flow but also a lot of
    % options regarding configuration of the experiment, randomization,
    % etc.
    
    properties( SetAccess = protected)
        Session = [];       % The session that is currently running this experiment design
        ExperimentOptions   = [];  % Options of this specific experiment design
        TrialTable          = [];
        
        Graph               = [];   % Display handle (usually psychtoolbox).
        
        TrialStartCallbacks  % callback functions to be called before a trial starts
        TrialStopCallbacks   % callback functions to be called after a trial ends
        
        Name

        eyeTracker;
    end
        
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % THESE ARE THE METHODS THAT SHOULD BE IMPLEMENTED BY NEW EXPERIMENT
    % DESIGNS
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access=protected)
        
        % Gets the options that be set in the UI when creating a new
        % session of this experiment (in structdlg format)
        % Some common options will be added
        function dlg = GetOptionsDialog( this, importing )
            dlg = [];
            
            if ( ~importing)
                dlg.Debug.DebugMode = { {'{0}','1'} };
                dlg.Debug.DisplayVariableSelection = 'TrialNumber TrialResult'; % which variables to display every trial in the command line separated by spaces
            end

            dlg.DisplayOptions.ForegroundColor      = 0;
            dlg.DisplayOptions.BackgroundColor      = 128;
            dlg.DisplayOptions.ScreenWidth          = { 142.8 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight         = { 80 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance       = { 85 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ShowTrialTable       = { {'0','{1}'} };
            dlg.DisplayOptions.PlaySound            = { {'0','{1}'} };
            dlg.DisplayOptions.StereoMode           = { 0 '* (mode)' [0 9] }; % SR added, 0 should be the default
            dlg.DisplayOptions.SelectedScreen       = { 2 '* (screen)' [0 5] }; % SR added, screen 2 should perhaps be the default

            dlg.HitKeyBeforeTrial = 0;
            dlg.TrialDuration = 10;
            dlg.TrialsBeforeBreak = 1000;

            dlg.UseEyeTracker   = { {'0' '{1}'} };
            dlg.EyeTracker      = { {'{OpenIris}' 'Fove'} };

            if ( exist('importing','var') && importing )
                dlg.DataFiles = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.EventFiles = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.CalibrationFiles = { {['uigetfile(''' fullfile(pwd,'*.cal') ''',''MultiSelect'', ''on'')']} };
            end
        end
        
        % Set up the trial table when a new session is created
        function trialTable = SetUpTrialTable( this )
            trialTable = table();
            trialTable.Condition = 1;
            trialTable.BlockNumber = 1;
            trialTable.BlockSequenceNumber = 1;
            trialTable.BlockSequenceRepeat = 1;
            trialTable.Session = 1;
        end
        
        % run initialization before the first trial is run
        % Use this function to initialize things that need to be
        % initialized before running but don't need to be initialized for
        % every single trial
        function shouldContinue = initBeforeRunning( this )
            shouldContinue = 1;
        end
        
        % runPreTrial
        % use this to prepare things before the trial starts
        function [trialResult, thisTrialData] = runPreTrial(this, thisTrialData )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
        end
        
        % runTrial
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
        end
        
        % runPostTrial
        function [trialResult, thisTrialData] = runPostTrial(this, thisTrialData)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
        end
        
        % run cleaning up after the session is completed or interrupted
        function cleanAfterRunning(this)
        end
        
    end
        
    % --------------------------------------------------------------------
    % Analysis methods --------------------------------------------------
    % --------------------------------------------------------------------
    
    methods ( Access = public )
        
        function optionsDlg = GetAnalysisOptionsDialog(this)
            optionsDlg = [];
        end
        
        function [samplesDataTable, rawData] = PrepareSamplesDataTable(this, options)
            samplesDataTable= [];
            rawData = [];
        end
        
        function trialDataTable = PrepareTrialDataTable( this, trialDataTable, options)
        end
        
        function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable, options)
        end

        function [analysisResults, samplesDataTable, trialDataTable, sessionTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable, sessionTable, options)
        end
        
        function ImportSession( this )
        end
    end

    methods(Access=public,Sealed=true)

        function  [samplesDataTable, trialDataTable, sessionTable] = prepareTablesForAnalysis( this, options)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            if ( isempty(  this.currentRun ) )
                return;
            end
            
            %% 0) Create the basic trial data table (without custom experiment stuff)
            if ( options.Prepare_For_Analysis_And_Plots )
                
                trials = this.Session.currentRun.pastTrialTable;
                
                % remove errors and aborts for analysis
                if (~isempty(trials))
                    % Trial attempt is just a continuos unique number for
                    % each past trial.
                    trials.TrialAttempt = (1:height(trials))';
                    
                    % just in case for old data. TrialResult used to be
                    % numeric. Now it is categorical but the categories
                    % match the old numbers+1;
                    if ( ~iscategorical(trials.TrialResult) )
                        trials.TrialResult = Enum.trialResult.PossibleResults(trials.TrialResult+1);
                    end
                    % in old files TrialNumber counted all trials not just
                    % correct trials. So we fix it for code down the line
                    % it could also be missing
                    if ( ~any(strcmp(trials.Properties.VariableNames,'TrialNumber')) || ...
                            sum(trials.TrialResult == Enum.trialResult.CORRECT) < max(trials.TrialNumber) )
                        % rebuild trial number as a counter of past correct
                        % trials plus one
                        trials.TrialNumber = cumsum([1;trials.TrialResult(1:end-1) == Enum.trialResult.CORRECT]);
                    end
                    
                    % keep only correct trials from now on
                    % TODO: rething this. Depending on how the experiment
                    % is programmed it may be interesting to look at the
                    % aborts.
                    trials(trials.TrialResult ~= Enum.trialResult.CORRECT ,:) = [];
                    
                    % merge the columns in trials with the ones already
                    % present in the trialDataTable.
                    % It is only necessary to rerun this stage zero if
                    % this.trialDataTable is not empty because there may be
                    % changes on the code. Otherwise we could change it to
                    % get here only if trialDataTable is empty.
                    if ( ~isempty(this.Session.trialDataTable) )
                        rightVariables = setdiff(this.Session.trialDataTable.Properties.VariableNames, trials.Properties.VariableNames);
                        trials =  outerjoin(trials, this.Session.trialDataTable, 'Keys', 'TrialNumber', 'MergeKeys',true, 'RightVariables', rightVariables );
                    end
                end
                
                trialDataTable = trials;
                
                %% 1) Prepare the sample data table
                if ( isempty(this.Session.samplesDataTable) )
                    % In most cases this will just be from EyeTracking
                    % experiment but there could be others that have a
                    % different way to load sample data.
                    try
                        [samples, cleanedData, calibratedData, rawData] = this.PrepareSamplesDataTable(options);
                        samplesDataTable = samples;
                        % TODO: I don't like this here. It should be moved
                        % to session. But may have memory problems at some
                        % point
                        this.Session.WriteVariableIfNotEmpty(rawData,'rawDataTable');
                        this.Session.WriteVariableIfNotEmpty(cleanedData,'cleanedData');
                        this.Session.WriteVariableIfNotEmpty(calibratedData,'calibratedData');
                    catch ex
                        getReport(ex)
                        cprintf('red', sprintf('++ VOGAnalysis :: ERROR PREPARING SAMPLES. WE WILL TRY TO CONTINUE.\n'));
                    end
                end
                cprintf('blue', '++ ARUME::Done with samplesDataTable.\n');
                
                %% 2) Prepare the trial data table
                trials = this.PrepareTrialDataTable(trials, options);
                trialDataTable = trials;
                cprintf('blue', '++ ARUME::Done with trialDataTable.\n');
                
                %% 3) Prepare session data table
                newSessionDataTable = this.Session.GetBasicSessionDataTable();
                newSessionDataTable = this.PrepareSessionDataTable(newSessionDataTable, options);
                newSessionDataTable.LastAnalysisDateTime = datestr(now);
                
                options = FlattenStructure(options); % eliminate strcuts with the struct so it can be made into a row of a table
                opts = fieldnames(options);
                s = this.GetExperimentOptionsDialog(1);
                for i=1:length(opts)
                    if ( isempty(options.(opts{i})))
                        newSessionDataTable.(['AnalysisOption_' opts{i}]) = {''};
                    elseif ( ~ischar( options.(opts{i})) && numel(options.(opts{i})) <= 1)
                        newSessionDataTable.(['AnalysisOption_' opts{i}]) = options.(opts{i});
                    elseif (isfield( s, opts{i}) && iscell(s.(opts{i})) && iscell(s.(opts{i}){1}) && length(s.(opts{i}){1}) >1)
                        newSessionDataTable.(['AnalysisOption_' opts{i}]) = categorical(cellstr(options.(opts{i})));
                    elseif (~ischar(options.(opts{i})) && numel(options.(opts{i})) > 1 )
                        newSessionDataTable.(['AnalysisOption_' opts{i}]) = {options.(opts{i})};
                    else
                        newSessionDataTable.(['AnalysisOption_' opts{i}]) = string(options.(opts{i}));
                    end
                end
                
                sessionTable = newSessionDataTable;
            end
        end
        
        function [analysisResults, samplesDataTable, trialDataTable, sessionTable] = RunExperimentAnalysis(this, options)
            [samplesDataTable, trialDataTable, sessionTable]  = this.prepareTablesForAnalysis(options);
            analysisResults  = struct();
            [analysisResults, samplesDataTable, trialDataTable, sessionTable]  = this.RunDataAnalyses(analysisResults, samplesDataTable, trialDataTable, sessionTable, options);
        end
    end
    
    methods(Access=public,Sealed=true)
        
        function this = ExperimentDesign()
            className = class(this);
            this.Name = className(find(className=='.',1, 'last')+1:end);
        end
    end
    
    methods(Access=protected,Sealed=true)
        
        function AddTrialStartCallback(this, fun)
            if ( isempty(this.TrialStartCallbacks) )
                this.TrialStartCallbacks = {fun};
            else
                this.TrialStartCallbacks{end+1} = fun;
            end
        end
        
        function AddTrialStopCallback(this, fun)
            if ( isempty(this.TrialStopCallbacks) )
                this.TrialStopCallbacks = {fun};
            else
                this.TrialStopCallbacks{end+1} = fun;
            end
        end
        
    end
    
    methods (Access = public)
        function trialTable = GetTrialTable(this)
            trialTable = this.TrialTable;
        end
        
        function trialTableOptions = GetDefaultTrialTableOptions(this)
            % Trial sequence and blocking
            trialTableOptions = [];
            trialTableOptions.trialSequence       = 'Sequential';	% Sequential, Random, Random with repetition, ...
            trialTableOptions.trialAbortAction    = 'Repeat';     % Repeat, Delay, Drop
            trialTableOptions.trialsPerSession    = 1;
            trialTableOptions.trialsBeforeBreak   = 1;
            
            trialTableOptions.blockSequence       = 'Sequential';	% Sequential, Random, Random with repetition, ...numberOfTimesRepeatBlockSequence = 1;
            trialTableOptions.blocksToRun         = 1;
            trialTableOptions.blocks              = [];
            trialTableOptions.numberOfTimesRepeatBlockSequence = 1;
        end
            
        function trialTable = GetTrialTableFromConditions(this, conditionVars, trialTableOptions)
            
            % Create the matrix with all the possible combinations of
            % condition variables. Each combination is a condition
            % total number of conditions is the product of the number of
            % values of each condition variable
            nConditions = 1;
            for iVar = 1:length(conditionVars)
                nConditions = nConditions * length(conditionVars(iVar).values);
            end
            
            conditionMatrix = [];
            
            %-- recursion to create the condition matrix
            % for each variable, we repeat the previous matrix as many
            % times as values the current variable has and in each
            % repetition we add a new column with one of the values of the
            % current variable
            % example: var1 = {a b} var2 = {e f g}
            % step 1: matrix = [ a ;
            %                    b ];
            % step 2: matrix = [ a e ;
            %                    b e ;
            %                    a f ;
            %                    b f ;
            %                    a g ;
            %                    b g ];
            for iVar = 1:length(conditionVars)
                nValues(iVar) = length(conditionVars(iVar).values);
                conditionMatrix = [ repmat(conditionMatrix,nValues(iVar),1)  ceil((1:prod(nValues))/prod(nValues(1:end-1)))' ];
            end
            
            % if the blocks are empty add one that includes all the
            % conditions
            if ( isempty( trialTableOptions.blocks) )
                trialTableOptions.blocks = struct( 'fromCondition', 1, 'toCondition', size(conditionMatrix,1), 'trialsToRun', size(conditionMatrix,1)  );
                trialTableOptions.blocksToRun = 1;
            end
        
        
            blockSeqWithRepeats = [];
            for iRepeatBlockSequence = 1:trialTableOptions.numberOfTimesRepeatBlockSequence
        
                % generate the sequence of blocks, a total of
                % parameters.blocksToRun blocks will be run
                nBlocks = length(trialTableOptions.blocks);
                blockSeq = [];
                switch(trialTableOptions.blockSequence)
                    case 'Sequential'
                        blockSeq = mod( (1:trialTableOptions.blocksToRun)-1,  nBlocks ) + 1;
                    case 'Random'
                        [~, theBlocks] = sort( rand(1,trialTableOptions.blocksToRun) ); % get a random shuffle of 1 ... blocks to run
                        blockSeq = mod( theBlocks-1,  nBlocks ) + 1; % limit the random sequence to 1 ... nBlocks
                    case 'Random with repetition'
                        blockSeq = ceil( rand(1,trialTableOptions.blocksToRun) * nBlocks ); % just get random block numbers
                    case 'Manual'
                        blockSeq = [];
                        
                        while length(blockSeq) ~= trialTableOptions.blocksToRun
                            S.Block_Sequence = [1:trialTableOptions.blocksToRun];
                            S = StructDlg( S, ['Block Sequence'], [],  CorrGui.get_default_dlg_pos() );
                            blockSeq =  S.Block_Sequence;
                        end
                        %                     if length(parameters.manualBlockSequence) == parameters.blocksToRun;
                        %                         %                         blockSequence = parameters.manualBlockSequence;
                        %
                        %                     else
                        %                         disp(['Error with the manual block sequence. Please fix.']);
                        %                     end
                end
                blockSeq = [blockSeq;ones(size(blockSeq))*iRepeatBlockSequence];
                blockSeqWithRepeats = [blockSeqWithRepeats blockSeq];
            end
            blockSeq = blockSeqWithRepeats;
            
            futureConditions = [];
            for iblock=1:size(blockSeq,2)
                i = blockSeq(1,iblock);
                possibleConditions = trialTableOptions.blocks(i).fromCondition : trialTableOptions.blocks(i).toCondition; % the possible conditions to select from in this block
                nConditions = length(possibleConditions);
                nTrials = trialTableOptions.blocks(i).trialsToRun;
                
                switch( trialTableOptions.trialSequence )
                    case 'Sequential'
                        trialSeq = possibleConditions( mod( (1:nTrials)-1,  nConditions ) + 1 );
                    case 'Random'
                        [~, conditions] = sort( rand(1,nTrials) ); % get a random shuffle of 1 ... nTrials
                        conditionIndexes = mod( conditions-1,  nConditions ) + 1; % limit the random sequence to 1 ... nConditions
                        trialSeq = possibleConditions( conditionIndexes ); % limit the random sequence to fromCondition ... toCondition for this block
                    case 'Random with repetition' 
                        trialSeq = possibleConditions( ceil( rand(1,nTrials) * nConditions ) ); % nTrialss numbers between 1 and nConditions
                end
                futureConditions = cat(1,futureConditions, [trialSeq' ones(size(trialSeq'))*iblock  ones(size(trialSeq'))*i ones(size(trialSeq'))*blockSeq(2,iblock)] );
            end
            
            newTrialTable = table();
            newTrialTable.Condition = futureConditions(:,1);
            newTrialTable.BlockNumber = futureConditions(:,2);
            newTrialTable.BlockSequenceNumber = futureConditions(:,3);
            newTrialTable.BlockSequenceRepeat = futureConditions(:,4);
            newTrialTable.Session = ceil((1:height(newTrialTable))/min(height(newTrialTable), trialTableOptions.trialsPerSession))';
            
            variableTable = table();
            for i=1:height(newTrialTable)
                variables = [];
                for iVar=1:length(conditionVars)
                    varName = conditionVars(iVar).name;
                    varValues = conditionVars(iVar).values;
                    if iscell( varValues )
                        variables.(varName) = categorical(varValues(conditionMatrix(newTrialTable.Condition(i),iVar)));
                    else
                        variables.(varName) = varValues(conditionMatrix(newTrialTable.Condition(i),iVar));
                    end
                end
            
                variableTable = cat(1,variableTable,struct2table(variables,'AsArray',true));
            end
            
            trialTable = [newTrialTable variableTable];
            
            trialTable.Properties.UserData.conditionVars = conditionVars;
            trialTable.Properties.UserData.trialTableOptions = trialTableOptions;
        end
        
        function options = GetDefaultOptions(this)
            options = StructDlg(this.GetAnalysisOptionsDialog(),'',[],[],'off');
        end
        
        function UpdateExperimentOptions(this, newOptions)
            this.ExperimentOptions = newOptions;
        end
        
        function [dataTable, idx, selectedFilters] = FilterTableByConditionVariable(this, dataTable, Select_Conditions, columns, columnNames, DataToIncludeFilter1, DataToIncludeFilter2, datafilter)
            
            % if there are no filters just get everything
            if ( ~exist('DataToIncludeFilter1','var') )
                DataToIncludeFilter1 = 'All';
            end
            if ( ~exist('DataToIncludeFilter2','var') )
                DataToIncludeFilter2 = 'All';
            end

            % TODO: not great right now. But get all the columns from the
            % trial table that have condition variables. 
            if(size(this.Session.experimentDesign.TrialTable,2)>6) % if not imported
                ConditionVars = this.Session.experimentDesign.TrialTable.Properties.VariableNames(6:end);
            else % if imported (TODO: not very good)
                ConditionVars = this.Session.currentRun.pastTrialTable.Properties.VariableNames(6:end);
            end

            % get all the possible values of the condition variables. But
            % only if they have less than 10 possible values. Otherwise it
            % gets too cumbersome
            if (ischar(dataTable) )
                switch(dataTable)
                    case 'get_filters'
                        Select_Conditions = struct();
                        Select_Conditions.All = { {'0', '{1}'}};
                        for i=1:length(ConditionVars)
                            name = ConditionVars{i};
                            if ( isnumeric(this.Session.currentRun.pastTrialTable{:,ConditionVars{i}}))
                                values = unique(this.Session.currentRun.pastTrialTable{:,ConditionVars{i}});
                            else
                                values = categories(categorical(this.Session.currentRun.pastTrialTable{:,ConditionVars{i}}));
                            end
                            if ( numel(values) < 10 )
                                for j=1:numel(values)
                                    if (~ismissing(values(j)))
                                        Select_Conditions.(strcat(name, '_', genvarname(string(values(j))))) = { {'{0}', '1'}};
                                    end
                                end
                            end
                        end
                        dataTable = Select_Conditions;
                        return;
                end
            end
            
            % Add the All condition variable column to allow that filter to
            % work like all others and not need special code later
            dataTable.All = ones(height(dataTable),1);
            
            % Get the actual variable name and the value of that variable
            % for the group filter
            Select_ConditionsFilters = struct();
            Select_ConditionsFilters.All.VarName = 'All';
            Select_ConditionsFilters.All.VarValue = 1;
            for i=1:length(ConditionVars)
                name = ConditionVars{i};
                if ( isnumeric(this.Session.currentRun.pastTrialTable{:,ConditionVars{i}}))
                    values = unique(this.Session.currentRun.pastTrialTable{:,ConditionVars{i}});
                else
                    values = categories(categorical(this.Session.currentRun.pastTrialTable{:,ConditionVars{i}}));
                end
                if ( numel(values) < 10 )
                    for j=1:numel(values)
                        if (~ismissing(values(j)))
                            Select_ConditionsFilters.(strcat(name, '_', genvarname(string(values(j))))).VarName = name;
                            Select_ConditionsFilters.(strcat(name, '_', genvarname(string(values(j))))).VarValue = values(j);
                        end
                    end
                end
            end

            % Get the actual variable name and the value of that variable
            % for the data to include filters
            switch(DataToIncludeFilter1)
                case 'All'
                    DataToIncludeName1 = 'All';
                    DataToIncludeValue1 = 1;
                otherwise
                    DataToIncludeNameValue1 = strsplit(DataToIncludeFilter1,'_');
                    DataToIncludeName1 = DataToIncludeNameValue1{1};
                    DataToIncludeValue1 = DataToIncludeNameValue1{2};
            end
            switch(DataToIncludeFilter2)
                case 'All'
                    DataToIncludeName2 = 'All';
                    DataToIncludeValue2 = 1;
                otherwise
                    DataToIncludeNameValue2 = strsplit(DataToIncludeFilter2,'_');
                    DataToIncludeName2 = DataToIncludeNameValue2{1};
                    DataToIncludeValue2 = DataToIncludeNameValue2{2};
            end
            
            % find which filters have been selected
            selectedFilters = {};
            
            filters = fieldnames(Select_Conditions);
            for i=1:length(filters)
                if ( Select_Conditions.(filters{i}) )
                    selectedFilters{end+1} = filters{i};
                end
            end
            
            % create a table with one row per filter and in each row the
            % filter name and the filtered table
            sessionDataTable = dataTable;
            dataTable = table();
            idx = table();
            for i=1:length(selectedFilters)
                idxf = sessionDataTable.(Select_ConditionsFilters.(selectedFilters{i}).VarName) == Select_ConditionsFilters.(selectedFilters{i}).VarValue;
                idxf = idxf & sessionDataTable.(DataToIncludeName1) == DataToIncludeValue1 & sessionDataTable.(DataToIncludeName2) == DataToIncludeValue2;
                dataTable{i, {'Data' 'Condition' 'Idx'}} = {sessionDataTable(idxf,:), selectedFilters{i}, find(idxf)};
            end
            
            % get the specific components we want and if more than one
            % replicate the rows as many time as needed but with the data
            % from the particular component
            if ( exist('columns','var'))
                dataTableTemp = table();
                for j=1:height(dataTable)
                    props = dataTable(j,:);
                    
                    props = repmat(props, numel(columns), 1);
                    props.Component = columnNames';
                    for iComp=1:numel(columns)
                        props{iComp,'Data'} = {props.Data{iComp}.(columns{iComp})};
                    end
                    dataTableTemp = vertcat(dataTableTemp, props);
                end
                dataTable = dataTableTemp;
                
                
                dataTable.Component = categorical(cellstr(dataTable.Component));
            end

            % apply data filters. For each row get only the elements of the
            % table that meet a particular condition
            if ( exist('datafilter','var'))
                for j=1:height(dataTable)
                    data = sessionDataTable(dataTable.Idx{j},:);
                    rowsToKeep = eval(datafilter);
                    dataTable.Data{j}  = dataTable.Data{j}(rowsToKeep,:);
                    dataTable.Idx{j}  = dataTable.Idx{j}(rowsToKeep,:);
                end
            end

            dataTable.Condition = categorical(cellstr(dataTable.Condition));
        end
    end
    
    % --------------------------------------------------------------------
    %% PUBLIC and sealed METHODS ------------------------------------------
    % --------------------------------------------------------------------
    % to be called from gui or command line
    % --------------------------------------------------------------------
    methods(Sealed = true)
        
        %
        % Options to set at runtime, this options will appear as a dialog
        % when creating a new session. If one experiment inherits from another
        % one it is a good idea to first call GetExperimentDesignOptions from
        % the parent class to get the options and then add new ones.
        %
        % This options may also appear when importing a session and it is
        % possible that the parameters that want to be displaied in that
        % case are different
        function dlg = GetExperimentOptionsDialog( this, importing )
            if ( ~exist( 'importing', 'var') )
                importing = 0;
            end
            dlg = this.GetOptionsDialog(importing);
        end
        
        function init(this, session, options, importing)
            this.Session = session;
            if ( ~exist( 'importing', 'var') )
                importing = 0;
            end
            
            %-- Check if all the options are there, if not add the default
            % values. This is important to mantain past compatibility if
            % options are added in the future.
            % TODO deal with nested structures
            optionsDlg = this.GetOptionsDialog(importing);
            if ( ~isempty( optionsDlg ) && (isempty(options) || ~isempty(setdiff(fieldnames(optionsDlg), fieldnames(options)))) )
                
                defaultOptions = StructDlg(optionsDlg,'',[],[],'off');
                
                fields = fieldnames(defaultOptions);
                for i=1:length(fields)
                    if ( ~isfield(options, fields{i}))
                        options.(fields{i}) = defaultOptions.(fields{i});
                    end
                end
            end
            
            this.ExperimentOptions = options;
            
            newTrialTable = this.SetUpTrialTable();
            
            % Check trialTable
            
            this.TrialTable = newTrialTable;
        end
        
        
        function run(this)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            % --------------------------------------------------------------------
            %% -- EXPERIMENT LOOP -------------------------------------------------
            % --------------------------------------------------------------------
            
            % possible states of the loop
            INITIALIZNG_HARDWARE = 0;
            INITIALIZNG_EXPERIMENT = 1;
            IDLE = 2;
            RUNNING = 3;
            FINILIZING_EXPERIMENT = 4;
            SESSIONFINISHED = 5;
            BREAK = 6;
            FINALIZING_HARDWARE = 7;
            
            state = INITIALIZNG_HARDWARE;
            
            trialsSinceBreak = 0;
            
            while(1)
                try
                    switch( state )
                        case INITIALIZNG_HARDWARE
                            
                            this.Graph = ArumeCore.Display( );
                            this.Graph.Init( this );
                            
                            state = INITIALIZNG_EXPERIMENT;
                            
                        case INITIALIZNG_EXPERIMENT
                            
                            this.TrialStartCallbacks = [];
                            this.TrialStopCallbacks = [];
                            
                            shouldContinue = this.EyeTrackingInit();
                            if ( shouldContinue)
                                shouldContinue = this.initBeforeRunning();
                            end

                            if ( shouldContinue )
                                state = RUNNING;
                            else
                                state = FINILIZING_EXPERIMENT;
                            end
                            
                        case IDLE
                            result = this.Graph.DlgSelect( ...
                                'Choose an option:', ...
                                { 'n' 'q'}, ...
                                { 'Next trial'  'Quit'} , [],[]);
                            
                            switch( result )
                                case 'n'
                                    state = RUNNING;
                                case {'q' 0}
                                    dlgResult = this.Graph.DlgYesNo( 'Are you sure you want to exit?',[],[],20,20);
                                    if( dlgResult )
                                        state = FINILIZING_EXPERIMENT;
                                    end
                            end
                            
                        case BREAK

                            result = this.Graph.DlgSelect( ...
                                'Break: Want to continue?:', ...
                                { 'c' 'q'}, ...
                                { 'Continue to next trial'  'Quit'} , [],[]);
                            
                            switch( result )
                                case 'c'
                                    trialsSinceBreak=0; %SR addition 9/22/2023
                                    state = RUNNING;
                                case {'q' 0}
                                    dlgResult = this.Graph.DlgYesNo( 'Are you sure you want to exit?',[],[],20,20);
                                    if( dlgResult )
                                        state = FINILIZING_EXPERIMENT;
                                    end
                            end
                            
                        case RUNNING
                            % force to hit a key to continue if the
                            % previous trial was an abort or if the
                            % experiment is set to ask for hit key before
                            % every trial
                            if ( (~isempty(this.Session.currentRun.pastTrialTable) && this.Session.currentRun.pastTrialTable.TrialResult(end) == Enum.trialResult.ABORT) ...
                                    || this.ExperimentOptions.HitKeyBeforeTrial )
                                dlgResult = this.Graph.DlgHitKey( 'Hit a key to continue',[],[]);
                                if ( ~dlgResult )
                                    state = IDLE;
                                    continue;
                                end
                            end
                            
                            try
                                commandwindow;
                                
                                nCorrectTrials = 0;
                                if ( any(strcmp(this.Session.currentRun.pastTrialTable.Properties.VariableNames,'TrialResult')))
                                    nCorrectTrials = sum(this.Session.currentRun.pastTrialTable.TrialResult == 'CORRECT');
                                end
                                
                                %-- find which condition to run and the variable values for that condition
                                thisTrialData = table();
                                thisTrialData.TrialNumber  = nCorrectTrials+1;
                                thisTrialData.DateTimeTrialStart = string(datestr(now));
                                thisTrialData = [thisTrialData this.Session.currentRun.futureTrialTable(1,:)];
                                
                                fprintf('\nARUME :: TRIAL %d START (%d TOTAL) ...\n', nCorrectTrials+1, height(this.Session.currentRun.originalFutureTrialTable));
                                
                                %------------------------------------------------------------
                                % -- PRE TRIAL ----------------------------------------------
                                %------------------------------------------------------------
                                thisTrialData.TimePreTrialStart = GetSecs;
                                
                                [trialResult, thisTrialData] = this.runPreTrial( thisTrialData );
                                thisTrialData.TrialResult = trialResult;
                                thisTrialData.TimePreTrialStop = GetSecs;
                                
                                if ( trialResult == Enum.trialResult.CORRECT )
                                    
                                    %------------------------------------------------------------
                                    % -- TRIAL --------------------------------------------------
                                    %------------------------------------------------------------
                                    thisTrialData.TimeTrialStart = GetSecs;
                                    for i=1:length(this.TrialStartCallbacks)
                                        thisTrialData = feval(this.TrialStartCallbacks{i}, thisTrialData);
                                    end
                                    
                                    if ( ~isempty(this.Graph) )
                                        this.Graph.ResetFlipTimes();
                                    end
                                    [trialResult, thisTrialData] = this.runTrial( thisTrialData );
                                    thisTrialData.TrialResult = trialResult;
                                    if ( ~isempty(this.Graph) )
                                        thisTrialData.NumFlips = this.Graph.NumFlips;
                                        thisTrialData.NumSlowFlips = this.Graph.NumSlowFlips;
                                        thisTrialData.NumSuperSlowFlips = this.Graph.NumSuperSlowFlips;
                                    end
                                    
                                    thisTrialData.TimeTrialStop = GetSecs;
                                    for i=1:length(this.TrialStopCallbacks)
                                        thisTrialData = feval(this.TrialStopCallbacks{i}, thisTrialData);
                                    end
                                    
                                    if ( trialResult == Enum.trialResult.CORRECT )
                                        
                                        %------------------------------------------------------------
                                        % -- POST TRIAL ---------------------------------------------
                                        %------------------------------------------------------------
                                        
                                        if ( this.ExperimentOptions.DisplayOptions.PlaySound)
                                            this.PlaySound(thisTrialData.TrialResult);
                                        end
                                        
                                        thisTrialData.TimePostTrialStart = GetSecs;
                                        
                                        [trialResult, thisTrialData] = this.runPostTrial( thisTrialData );
                                        thisTrialData.TrialResult = trialResult;
                                        
                                        thisTrialData.TimePostTrialStop = GetSecs;
                                    end
                                end
                                
                            
                            catch err
                                if ( streq(err.identifier, 'PSYCORTEX:USERQUIT' ) )
                                    thisTrialData.TrialResult = Enum.trialResult.QUIT;
                                else
                                    thisTrialData.TrialResult = Enum.trialResult.ERROR;
                                    thisTrialData.ErrorMessage = string(err.message);
                                    % display error
                                    
                                    beep
                                    cprintf('red', '\n')
                                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                                    cprintf('red', '!!!!!!!!!!!!! ARUME ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                                    disp(err.getReport);
                                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                                    cprintf('red', '!!!!!!!!!!!!! END ARUME ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                                    cprintf('red', '\n')
                                end
                            end
                            
                            
                            % -- Update past trial table
                            this.Session.currentRun.AddPastTrialData(thisTrialData);
                            
                            if ( this.ExperimentOptions.DisplayOptions.ShowTrialTable)
                                % -- Display trial Table for last 20 trials
                                data = this.Session.currentRun.pastTrialTable;
                                varSelection = intersect(strsplit(this.ExperimentOptions.Debug.DisplayVariableSelection,' '),data.Properties.VariableNames,'stable');
                                if ( ~this.ExperimentOptions.Debug.DebugMode )
                                    disp(data(max(1,end-20):end,varSelection));
                                else
                                    disp(data);
                                end
                            end
                            
                            
                            if ( thisTrialData.TrialResult == Enum.trialResult.CORRECT )
                                %-- remove the condition that has just run from the future conditions list
                                this.Session.currentRun.futureTrialTable(1,:) = [];
                                
                                %-- save to disk temporary data
                                %//TODO this.SaveTempData();
                                
                                trialsSinceBreak = trialsSinceBreak + 1;
                            else
                                %-- what to do in case of abort
                                switch(this.TrialTable.Properties.UserData.trialTableOptions.trialAbortAction)
                                    case 'Repeat'
                                        % do nothing
                                    case 'Delay'
                                        % randomly get one of the future conditions in the current block
                                        % and switch it with the next
                                        currentblock = this.Session.currentRun.futureTrialTable.BlockNumber(1);
                                        currentblockSeqNumber = this.Session.currentRun.futureTrialTable.BlockSequenceNumber(1);
                                        futureConditionsInCurrentBlock = this.Session.currentRun.futureTrialTable(this.Session.currentRun.futureTrialTable.BlockNumber==currentblock & this.Session.currentRun.futureTrialTable.BlockSequenceNumber==currentblockSeqNumber,:);
                                        
                                        newPosition = ceil(rand(1)*(height(futureConditionsInCurrentBlock)-1))+1;
                                        c = futureConditionsInCurrentBlock(1,:);
                                        futureConditionsInCurrentBlock(1,:) = futureConditionsInCurrentBlock(newPosition,:);
                                        futureConditionsInCurrentBlock(newPosition,:) = c;
                                        this.Session.currentRun.futureTrialTable(this.Session.currentRun.futureTrialTable.BlockNumber==currentblock & this.Session.currentRun.futureTrialTable.BlockSequenceNumber==currentblockSeqNumber,:) = futureConditionsInCurrentBlock;
                                    case 'Drop'
                                        %-- remove the condition that has just run from the future conditions list
                                        this.Session.currentRun.futureTrialTable(1,:) = [];
                                end
                            end
                            
                            %-- handle errors
                            switch ( thisTrialData.TrialResult )
                                case Enum.trialResult.ERROR
                                    state = IDLE;
                                    continue;
                                case Enum.trialResult.QUIT
                                    state = IDLE;
                                    continue;
                            end
                            
                            % -- Experiment or session finished ?
                            if ( trialsSinceBreak >= this.ExperimentOptions.TrialsBeforeBreak )
                                state = BREAK;
                            end
                            if ( ~isempty(this.Session.currentRun.futureTrialTable) && ~isempty(this.Session.currentRun.pastTrialTable) )
                                if ( this.Session.currentRun.pastTrialTable.Session(end) ~= this.Session.currentRun.futureTrialTable.Session(1) )
                                    state = SESSIONFINISHED;
                                end
                            end
                            if ( isempty(this.Session.currentRun.futureTrialTable) )
                                state = FINILIZING_EXPERIMENT;
                            end
                            
                        case SESSIONFINISHED
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', 'Session part finished! closing down and saving data ...\n');
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', '---------------------------------------------------------\n')
                            state = FINILIZING_EXPERIMENT;
                            
                        case FINILIZING_EXPERIMENT
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', 'Session finished! closing down and saving data ...\n');
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', '---------------------------------------------------------\n')
                            
                            this.cleanAfterRunning();
                            this.EyeTrackingStop();
                            
                            state = FINALIZING_HARDWARE;
                            
                        case FINALIZING_HARDWARE
                            
                            this.Graph.Clear();
                            
                            this.Graph = [];
                            disp('ARUME:: Done closing display and connections!');
                            break; % finish loop
                            
                    end
                catch lastError
                    beep
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!! ARUME ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    disp(lastError.getReport);
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!! END ARUME ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    
                    if ( state == FINILIZING_EXPERIMENT )
                        state = FINALIZING_HARDWARE;
                    elseif ( state == FINALIZING_HARDWARE )
                        break;
                    else
                        state = FINILIZING_EXPERIMENT;
                    end
                end
            end
            % --------------------------------------------------------------------
            %% -------------------- END EXPERIMENT LOOP ---------------------------
            % --------------------------------------------------------------------
        end
        
        function abortExperiment(this)
            throw(MException('PSYCORTEX:USERQUIT', ''));
        end
    end
        
    % --------------------------------------------------------------------
    %% Private methods ----------------------------------------------------
    % --------------------------------------------------------------------
    % to be called only by this class
    % --------------------------------------------------------------------
    methods (Access=private)
        
        function PlaySound(this,trialResult)
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            %% make a sound for the end of the trial
            fs = 8000;
            T = 0.1; % 2 seconds duration
            t = 0:(1/fs):T;
            if ( trialResult == Enum.trialResult.CORRECT )
                f = 500;
            else
                f = 250;
            end
            y = sin(2*pi*f*t);
            sound(y, fs);
        end
    end

    % --------------------------------------------------------------------
    %% Eye tracking methods ----------------------------------------------
    % --------------------------------------------------------------------
    % to be called only by this class
    % --------------------------------------------------------------------
    methods (Access=private)

        function shouldContinue = EyeTrackingInit(this)

            if ( this.ExperimentOptions.UseEyeTracker )
                this.eyeTracker = ArumeHardware.VOG();
                result = this.eyeTracker.Connect();
                if ( result )
                    this.eyeTracker.SetSessionName(this.Session.name);
                    this.eyeTracker.StartRecording();
                    this.AddTrialStartCallback(@this.EyeTrackingTrialStartCallback)
                    this.AddTrialStopCallback(@this.EyeTrackingTrialStopCallBack)
                else
                    shouldContinue = 0;
                    this.eyeTracker = [];
                    return;
                end
            end
            
            shouldContinue = 1;
        end


        function EyeTrackingStop(this)
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

        function variables = EyeTrackingTrialStartCallback(this, variables)
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
         
        function variables = EyeTrackingTrialStopCallBack(this, variables)
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
    
    
    methods ( Static = true )
        
        function options = GetDefaultExperimentOptions(experiment, importing)
            if ( ~exist('importing','var') )
                importing = 0;
            end
            experiment = ArumeCore.ExperimentDesign.Create(experiment);
            optionsDlg = experiment.GetExperimentOptionsDialog( importing);
            options = StructDlg(optionsDlg,'',[],[],'off');
        end
            
        function experimentList = GetExperimentList()
            experimentList = {};
            
            % It is important to not navigate the expPackage object in the
            % loop. It is vry slow. Keep the objects in their own variables
            % and used them like that.
            classList = meta.package.fromName('ArumeExperimentDesigns').ClassList;
            for i=1:length(classList)
                c = classList(i);
                if (~c.Abstract)
                    experimentList{end+1} = strrep( c.Name, 'ArumeExperimentDesigns.','');
                end
            end
        end
        
        function experiment = Create(experimentName)
            
            if ( exist( ['ArumeExperimentDesigns.' experimentName],  'class') )
                % Create the experiment design object
                experiment = ArumeExperimentDesigns.(experimentName)();
            else
                % Create the experiment design object
                experiment = ArumeCore.ExperimentDesign();
            end
        end
        
        function Enum = getEnum()
            % -- possible trial results
            Enum.trialResult.CORRECT = categorical(cellstr('CORRECT')); % Trial finished correctly
            Enum.trialResult.ABORT = categorical(cellstr('ABORT'));   % Trial not finished, wrong key pressed, subject did not fixate, etc
            Enum.trialResult.ERROR = categorical(cellstr('ERROR'));   % Error during the trial
            Enum.trialResult.QUIT = categorical(cellstr('QUIT'));    % Escape was pressed during the trial
            Enum.trialResult.SOFTABORT = categorical(cellstr('SOFTABORT')); % Like an abort but does not go to hitkey to continue
            Enum.trialResult.PossibleResults = [...
                Enum.trialResult.CORRECT ...
                Enum.trialResult.ABORT ...
                Enum.trialResult.ERROR ...
                Enum.trialResult.QUIT ...
                Enum.trialResult.SOFTABORT]';
                
            
            % -- useful key codes
            try
                
                KbName('UnifyKeyNames');
                Enum.keys.SPACE     = KbName('space');
                Enum.keys.ESCAPE    = KbName('ESCAPE');
                Enum.keys.RETURN    = KbName('return');
                % Enum.keys.BACKSPACE = KbName('backspace');
                %
                %             Enum.keys.TAB       = KbName('tab');
                %             Enum.keys.SHIFT     = KbName('shift');
                %             Enum.keys.CONTROL   = KbName('control');
                %             Enum.keys.ALT       = KbName('alt');
                %             Enum.keys.END       = KbName('end');
                %             Enum.keys.HOME      = KbName('home');
                
                Enum.keys.LEFT      = KbName('LeftArrow');
                Enum.keys.UP        = KbName('UpArrow');
                Enum.keys.RIGHT     = KbName('RightArrow');
                Enum.keys.DOWN      = KbName('DownArrow');
            catch
            end
            
        end
        
    end
end

