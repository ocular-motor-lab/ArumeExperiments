classdef SaccadeDirectionsHeadTilt < ArumeExperimentDesigns.EyeTracking
    %Illusory tilt Summary of this class goes here
    %   Detailed explanation goes here

    properties
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeCore.ExperimentDesign(this, importing);
            
            dlg.UseEyeTracker       = { {'0' '{1}'} };
            dlg.EyeTracker          = { {'OpenIris' '{Fove}'} };
            dlg.HeadTilt            = 0;
            
            if ( exist('importing','var') && importing )
                dlg.Folder = { {['uigetdir(''' pwd ''')']} };
            end
        end
    end
    
    methods ( Access = public )
        %% ImportSession
        function ImportSession( this )
            newRun = ArumeCore.ExperimentRun.SetUpNewRun( this );
            
            folder = this.ExperimentOptions.Folder;
            dataFiles = { ...
                fullfile(folder, 'TiltLeft',dir(fullfile(folder, 'TiltLeft','fove*')).name),...
                fullfile(folder, 'HeadUpright',dir(fullfile(folder, 'HeadUpright','fove*')).name),...
                fullfile(folder, 'TiltRight',dir(fullfile(folder, 'TiltRight','fove*')).name)};
            
            trialFiles = { ...
                fullfile(folder, 'TiltLeft',dir(fullfile(folder, 'TiltLeft','trial*')).name),...
                fullfile(folder, 'HeadUpright',dir(fullfile(folder, 'HeadUpright','trial*')).name),...
                fullfile(folder, 'TiltRight',dir(fullfile(folder, 'TiltRight','trial*')).name)};
            
            headTilts = categorical({'Left', 'Upright', 'Right'}');
                
            newRun.pastTrialTable = table();
            for i=1:3
                d = readtable(trialFiles{i});
                trialTable = table();
                trialTable.TrialResult = repmat(categorical(cellstr('CORRECT')),height(d),1);
                if ( i==1)
                    trialTable.TrialNumber = d.trial_num;
                else
                    trialTable.TrialNumber = d.trial_num + max(newRun.pastTrialTable.TrialNumber);
                end
                trialTable.FileNumber = i*ones(size(trialTable.TrialNumber));
                
                trialTable.TrialStartTime = d.start_time;
                trialTable.TrialEndTime = d.start_time;
                trialTable.HeadTilt = headTilts(i*ones(size(trialTable.TrialNumber)));
                trialTable.ImageType = categorical(d.ImageType);
                trialTable.ImageTilt = d.TiltType;
                trialTable.ImageNumber = d.ImageNumber;
                trialTable.StimName = d.StimName;
                
                newRun.pastTrialTable = vertcat(newRun.pastTrialTable, trialTable);
            end
            newRun.futureTrialTable = trialTable([],:);
            this.Session.importCurrentRun(newRun);
            
            if ( ~iscell(dataFiles) )
                dataFiles = {dataFiles};
            end
            if ( ~iscell(trialFiles) )
                trialFiles = {trialFiles};
            end
            
            for i=1:length(dataFiles)
                if (exist(dataFiles{i},'file') )
                    this.Session.addFile('foveDataFile', dataFiles{i});
                end
            end
            for i=1:length(trialFiles)
                if (exist(trialFiles{i},'file') )
                    this.Session.addFile('foveTrialFile', trialFiles{i});
                end
            end
            
            options = StructDlg(this.Session.experimentDesign.GetAnalysisOptionsDialog,'',[],[],'off');
            options.Prepare_For_Analysis_And_Plots  =1;
            
%             this.Session.prepareForAnalysis(options);
            
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )

    end
end