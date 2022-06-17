classdef SVVVergence < ArumeExperimentDesigns.EyeTracking
    %Illusory tilt Summary of this class goes here
    %   Detailed explanation goes here

    properties
    end
    
    properties(Constant)
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeCore.ExperimentDesign(this, importing);
            
            dlg.UseEyeTracker       = { {'0' '{1}'} };
            dlg.EyeTracker          = { {'OpenIris' '{Fove}'} };
            
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
                fullfile(folder,dir(fullfile(folder, '*L_fove*')).name),...
                fullfile(folder,dir(fullfile(folder, '*Up_fove*')).name),...
                fullfile(folder,dir(fullfile(folder, '*R_fove*')).name)};
            
            trialFiles = { ...
                fullfile(folder,dir(fullfile(folder, '*L_trial_results*')).name),...
                fullfile(folder,dir(fullfile(folder, '*Up_trial_results*')).name),...
                fullfile(folder,dir(fullfile(folder, '*R_trial_results*')).name)};
            
            headTilts = categorical({'Left', 'Upright', 'Right'}');
                
            responses = {'L' 'R'};
            vergences = {'Near' 'Far'};
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
                trialTable.TrialEndTime = d.end_time;
                trialTable.HeadTilt = categorical(headTilts(i*ones(size(trialTable.TrialNumber))));
                trialTable.LineAngle = d.Direction;
                trialTable.VergenceDistance = d.Vergence;
%                 trialTable.Vergence = categorical(vergences(d.VergenceDistance == -1.5));
                trialTable.Response(~isnan(d.Response)) = categorical(responses(d.Response(~isnan(d.Response))+1)');
                
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
            
            %             options = StructDlg(this.Session.experimentDesign.GetAnalysisOptionsDialog,'',[],[],'off');
            %             options.Prepare_For_Analysis_And_Plots  =1;
            %             this.Session.prepareForAnalysis(options);
             
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )

        function [out] = Plot_Josie(this)

            %%
            s = this.Session.samplesDataTable;
            figure
            
            subplot(4,3,[1 2],'nextplot','add');
            plot(s.Time, s.LeftX)
            plot(s.Time, s.RightX)
            ylabel('Horizontal (deg)')
            subplot(4,3,3+[1 2],'nextplot','add');
            plot(s.Time, s.LeftY)
            plot(s.Time, s.RightY)
            ylabel('Vertical (deg)')
            subplot(4,3,6+[1 2],'nextplot','add');
            plot(s.Time, s.LeftT)
            plot(s.Time, s.RightT)
            ylabel('Torsion (deg)')
            legend({'Left eye' 'Right eye'})
            subplot(4,3,9+[1 2],'nextplot','add');
            plot(s.Time, s.HeadRoll)
            plot(s.Time, s.HeadPitch)
            ylabel('Head (deg)')
            xlabel('Time (s)')
            legend({'Roll' 'Pitch'})

            t = this.Session.trialDataTable;
            t.HeadVergence = categorical(strcat(string(t.HeadTilt), string(t.VergenceDistance)));
            g = grpstats(t,'HeadVergence',{'mean' 'sem'}, 'datavars','median_T');
            subplot(4,3,[3 6 9 12])
            errorbar(g.HeadVergence, g.mean_median_T, g.sem_median_T,'linestyle','none')
            ylabel('Torsion (deg)')

        end
    end
end