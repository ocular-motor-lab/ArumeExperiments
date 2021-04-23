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
                
                dlg.DisplayOptions.ForegroundColor      = 0;
                dlg.DisplayOptions.BackgroundColor      = 128;
                dlg.DisplayOptions.ScreenWidth          = { 40 '* (cm)' [1 3000] };
                dlg.DisplayOptions.ScreenHeight         = { 30 '* (cm)' [1 3000] };
                dlg.DisplayOptions.ScreenDistance       = { 135 '* (cm)' [1 3000] };
                
                dlg.HitKeyBeforeTrial = 0;
                dlg.TrialDuration = 10;
                dlg.TrialsBeforeBreak = 1000;
            end
        end
        
        % Set up the trial table when a new session is created
        function trialTable = SetUpTrialTable( this )
            trialTable = table();
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
        
        function [dataTable, idx, selectedFilters] = FilterTableByConditionVariable(this, dataTable, Select_Conditions, columns, columnNames)
            
            if (ischar(dataTable) )
                switch(dataTable)
                    case 'get_filters'
                        Select_Conditions = struct();
                        Select_Conditions.All = { {'0', '{1}'}};
                        for i=1:length(this.Session.experimentDesign.ConditionVars)
                            name = this.Session.experimentDesign.ConditionVars(i).name;
                            values = categorical(this.Session.experimentDesign.ConditionVars(i).values);
                            for j=1:numel(values)
                                Select_Conditions.(strcat(name, '_', string(values(j)))) = { {'{0}', '1'}};
                            end
                        end
                        dataTable = Select_Conditions;
                        return;
                end
            end
            
            dataTable.All = ones(height(dataTable),1);
            
            Select_ConditionsFilters = struct();
            Select_ConditionsFilters.All.VarName = 'All';
            Select_ConditionsFilters.All.VarValue = 1;
            for i=1:length(this.Session.experimentDesign.ConditionVars)
                name = this.Session.experimentDesign.ConditionVars(i).name;
                if ( iscell(this.Session.experimentDesign.ConditionVars(i).values) )
                    values = categorical(this.Session.experimentDesign.ConditionVars(i).values);
                else
                    values = this.Session.experimentDesign.ConditionVars(i).values;
                end
                for j=1:numel(values)
                    Select_ConditionsFilters.(strcat(name, '_', string(values(j)))).VarName = name;
                    Select_ConditionsFilters.(strcat(name, '_', string(values(j)))).VarValue = values(j);
                end
            end
            
            selectedFilters = {};
            
            filters = fieldnames(Select_Conditions);
            for i=1:length(filters)
                if ( Select_Conditions.(filters{i}) )
                    selectedFilters{end+1} = filters{i};
                end
            end
            
            sessionDataTable = dataTable;
            dataTable = table();
            idx = table();
            for i=1:length(selectedFilters)
                idxf = find(sessionDataTable.(Select_ConditionsFilters.(selectedFilters{i}).VarName) == Select_ConditionsFilters.(selectedFilters{i}).VarValue);
                dataTable{i, {'Data' 'Condition' 'Idx'}} = {sessionDataTable(idxf,:), selectedFilters{i}, idxf};
            end
            
            
            
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
                            
                            shouldContinue = this.initBeforeRunning();
                            
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
                            dlgResult = this.Graph.DlgHitKey( 'Break: hit a key to continue',[],[] );
                            %             this.Graph.DlgTimer( 'Break');
                            %             dlgResult = this.Graph.DlgYesNo( 'Finish break and continue?');
                            % problems with breaks i am going to skip the timer
                            if ( ~dlgResult )
                                state = IDLE;
                            else
                                trialsSinceBreak = 0;
                                state = RUNNING;
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
                                        
                                        this.PlaySound(thisTrialData.TrialResult);
                                        
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
                            
                            % -- Display trial Table for last 20 trials
                            data = this.Session.currentRun.pastTrialTable;
                            varSelection = intersect(strsplit(this.ExperimentOptions.Debug.DisplayVariableSelection,' '),data.Properties.VariableNames,'stable');
                            if ( ~this.ExperimentOptions.Debug.DebugMode )
                                disp(data(max(1,end-20):end,varSelection));
                            else
                                disp(data);
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
    end % methods (Access=private)
    
    
    methods ( Static = true )
        
        function options = GetDefaultExperimentOptions(experiment)
            experiment = ArumeCore.ExperimentDesign.Create(experiment);
            optionsDlg = experiment.GetExperimentOptionsDialog( );
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

