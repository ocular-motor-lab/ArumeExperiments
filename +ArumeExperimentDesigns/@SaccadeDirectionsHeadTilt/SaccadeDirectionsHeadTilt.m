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
                trialTable.TrialEndTime = d.end_time;
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
            
            %             options = StructDlg(this.Session.experimentDesign.GetAnalysisOptionsDialog,'',[],[],'off');
            %             options.Prepare_For_Analysis_And_Plots  =1;
            %             this.Session.prepareForAnalysis(options);
             
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )

        function [out] = Plot_Stephanie(this)
            tt = this.Session.trialDataTable;
            ss = this.Session.samplesDataTable;
            rr = this.Session.analysisResults;

            binsize = 10;
            binedges = [0:binsize:360]/180*pi;
            bincenters = [-binsize/2:binsize:360]/180*pi;

            AnalysisResults_QuickPhases= rr.QuickPhases;

            f = figure;
            h1 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == -30 & AnalysisResults_QuickPhases.Task == "Fixation" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test1 = h1.Values
            h2 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == 0 & AnalysisResults_QuickPhases.Task == "Fixation" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test2 = h2.Values
            h3 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == 30 & AnalysisResults_QuickPhases.Task == "Fixation" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test3 = h3.Values
            h4 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == -30 & AnalysisResults_QuickPhases.Task == "FreeView" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test4 = h4.Values
            h5 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == 0 & AnalysisResults_QuickPhases.Task == "FreeView" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test5 = h5.Values
            h6 = polarhistogram(AnalysisResults_QuickPhases.Left_Direction(find(AnalysisResults_QuickPhases.ImTilt == 30 & AnalysisResults_QuickPhases.Task == "FreeView" & AnalysisResults_QuickPhases.TrialNumber > 0)),bincenters,'Normalization','probability')
            test6 = h6.Values

            close(f);

            figure
            subplot(2,3,1)
            polarplot(binedges,[test1 test1(1)],'LineWidth',2, 'Color', 'black')
            title('-30 Images')
            subplot(2,3,2)
            polarplot(binedges,[test2 test2(1)],'LineWidth',2, 'Color', 'black')
            title('0 Images')
            subplot(2,3,3)
            polarplot(binedges,[test3 test3(1)],'LineWidth',2, 'Color', 'black')
            title('30 Images')
            subplot(2,3,4)
            polarplot(binedges,[test4 test4(1)],'LineWidth',2, 'Color', 'black')
            subplot(2,3,5)
            polarplot(binedges,[test5 test5(1)],'LineWidth',2, 'Color', 'black')
            subplot(2,3,6)
            polarplot(binedges,[test6 test6(1)],'LineWidth',2, 'Color', 'black')
        end
    end
end