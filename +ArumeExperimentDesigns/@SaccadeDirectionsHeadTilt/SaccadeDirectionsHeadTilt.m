classdef SaccadeDirectionsHeadTilt < ArumeExperimentDesigns.EyeTracking
    %Illusory tilt Summary of this class goes here
    %   Detailed explanation goes here

    properties
    end
    
    properties(Constant)
        BaselineIdx = cell2table(...
            {...
            'SaccadeDirectionsHeadTilt__0101__A' , 7888, 10786, 191309,192600, 339263, 343211,'R';  %1 %0 means 0 good eyes, 1 means good red eye, 2 means good blue eye, 3 means good both eyes (for torsion data across head tilt sessions)
            'SaccadeDirectionsHeadTilt__0122__A' , 6251, 8751, 152430, 153000, 293106, 294215,'L'; %2
            'SaccadeDirectionsHeadTilt__0123__A' , 4404, 5787, 145200, 146200, 284291, 286656,'L'; %2
            'SaccadeDirectionsHeadTilt__0124__A' , 6432, 8443, 154536, 155622, 297994, 299446, 'B'; %3
            'SaccadeDirectionsHeadTilt__0125__A' , 4669, 6557, 166575, 167980, 315852, 322374, 'N'; % ? % neither eye is great but doesn't seem bad enough to throw the whole thing away?? mayyyybe the blue is slightly better?
            'SaccadeDirectionsHeadTilt__0126__A' , 4415, 5079, 145155, 147008, 288761, 289641, 'N'; % 0
            'SaccadeDirectionsHeadTilt__0127__A' , 7325, 8221, 155925, 156991, 309665, 312200, 'R'; % 1
            'SaccadeDirectionsHeadTilt__0128__A' , 6011, 6925, 145218, 145888, 288985, 290878, 'B'; % 3
            'SaccadeDirectionsHeadTilt__0129__A' , 6372, 7376, 152548, 153282, 298402, 299853, 'B'; %3
            'SaccadeDirectionsHeadTilt__0166__A' , 4747, 8357, 152043, 153043, 295794, 296700, 'N'; % 0
            'SaccadeDirectionsHeadTilt__0167__A' , 6370, 7600, 155753, 156396, 304600, 307100, 'B'; %3
            'SaccadeDirectionsHeadTilt__0169__A' , 3771, 5040, 157217, 158287, 315332, 316380, 'B'; %3
            'SaccadeDirectionsHeadTilt__0172__A' , 6881, 8194, 153800, 155079, 293920, 297560, 'B'; %3
            'SaccadeDirectionsHeadTilt__0173__A' , 5869, 6990, 148038, 149200, 290533, 291590, 'B'; %3
            },...
            'VariableNames', {'SessionName','LeftStart','LeftEnd','UpStart','UpEnd','RightStart','RightEnd','WhichEye'});
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
        
        function [samplesDataTable, cleanedData, calibratedData, rawData] = PrepareSamplesDataTable(this, options)
            
            
            [samplesDataTable, cleanedData, calibratedData, rawData] = PrepareSamplesDataTable@ArumeExperimentDesigns.EyeTracking(this, options);
            
            % This was added in efforts to normalize some of the torsion
            % data. It was occuring that the mean of head upright for a
            % subject was 2 (for example), which is just not correct given
            % what we know about torsion. This was happening for all head
            % tilts. One way to correct for this is to get the mean torsion
            % between an interval: in this case, after the calibration and
            % before the act of head tilting. If we get the mean of that
            % interval and then subtract it off we should be normalizing a
            % bit. 
            sessname = this.Session.name;
            
            baselines = ArumeExperimentDesigns.SaccadeDirectionsHeadTilt.BaselineIdx;
            baselines.Properties.RowNames = baselines.SessionName;
            baselines.WhichEye = categorical(baselines.WhichEye);
            
            switch(baselines{sessname,'WhichEye'})
                case 'L'
                    samplesDataTable.RightT = nan(size(samplesDataTable.RightT));
                case 'R'
                    samplesDataTable.LeftT = nan(size(samplesDataTable.LeftT));
                case 'N'
                    samplesDataTable.RightT = nan(size(samplesDataTable.RightT));
                    samplesDataTable.LeftT = nan(size(samplesDataTable.LeftT));
            end
            
            % Adjust baselines
            baselineIdxL = baselines{sessname,'LeftStart'}:baselines{sessname,'LeftEnd'};
            baselineIdxU = baselines{sessname,'UpStart'}:baselines{sessname,'UpEnd'};
            baselineIdxR = baselines{sessname,'RightStart'}:baselines{sessname,'RightEnd'};
            
            dataIdxL = baselines{sessname,'LeftStart'}:baselines{sessname,'UpStart'};
            dataIdxU = baselines{sessname,'UpStart'}:baselines{sessname,'RightStart'};
            dataIdxR = baselines{sessname,'RightStart'}:height(samplesDataTable);
            
            samplesDataTable.UncorrectedLeftT = samplesDataTable.LeftT;
            samplesDataTable.UncorrectedRightT = samplesDataTable.RightT;
            samplesDataTable.LeftT(dataIdxL) = samplesDataTable.LeftT(dataIdxL) - median(samplesDataTable.LeftT(baselineIdxL),'omitnan');
            samplesDataTable.RightT(dataIdxL) = samplesDataTable.RightT(dataIdxL) - median(samplesDataTable.RightT(baselineIdxL),'omitnan');
            
            samplesDataTable.LeftT(dataIdxU) = samplesDataTable.LeftT(dataIdxU) - median(samplesDataTable.LeftT(baselineIdxU),'omitnan');
            samplesDataTable.RightT(dataIdxU) = samplesDataTable.RightT(dataIdxU) - median(samplesDataTable.RightT(baselineIdxU),'omitnan');
            
            samplesDataTable.LeftT(dataIdxR) = samplesDataTable.LeftT(dataIdxR) - median(samplesDataTable.LeftT(baselineIdxR),'omitnan');
            samplesDataTable.RightT(dataIdxR) = samplesDataTable.RightT(dataIdxR) - median(samplesDataTable.RightT(baselineIdxR),'omitnan');
            
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