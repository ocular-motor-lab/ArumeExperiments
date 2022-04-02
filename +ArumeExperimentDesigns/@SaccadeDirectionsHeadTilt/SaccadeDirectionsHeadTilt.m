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
            baselineIdxU = [];
            baselineIdxL = [];
            baselineIdxR = [];
            switch(this.Session.name)
                case 'SaccadeDirectionsHeadTilt__0101__A' % refine these, they are guesstamites
                    baselineIdxR = 4000:5000;
                    baselineIdxL = 16000:161000;
                    baselineIdxU = 320000:321000;
                    
                    dataIdxU = 100:1300;
                    dataIdxL = 123123123:123123123;
                    dataIdxR = 123123123:123123123;
                    
                case 'SaccadeDirectionsHeadTilt__0122__A'
                    baselineIdxL = 6251:8751;
                    baselineIdxU = 152536:155051;
                    baselineIdxR = 293040:294298;

                    dataIdxL = 6251:152536;                    
                    dataIdxU = 152536:293040;
                    dataIdxR = 293040:427070;
                
                case 'SaccadeDirectionsHeadTilt__0123__A' % head tilt right torsion data isn't that good
                    baselineIdxL = 4404:5787;
                    baselineIdxU = 144656:147172;
                    baselineIdxR = 284252:286752;

                    dataIdxL = 4404:144656;                    
                    dataIdxU = 144656:284252;
                    dataIdxR = 284252:421321;
                    
                case 'SaccadeDirectionsHeadTilt__0124__A'
                    baselineIdxL = 6432:9100;
                    baselineIdxU = 167036:168122;
                    baselineIdxR = 322994:324446;

                    dataIdxL = 6432:167036;                    
                    dataIdxU = 167036:322994;
                    dataIdxR = 322994:445060;
                
                case 'SaccadeDirectionsHeadTilt__0125__A' %not great torsion for head right but even 2 other head tilts were eh
                    baselineIdxL = 4669:6557;
                    baselineIdxU = 179075:180480;
                    baselineIdxR = 340852:348480;

                    dataIdxL = 4669:179075;                    
                    dataIdxU = 179075:340852;
                    dataIdxR = 340852:466613;
                
                case 'SaccadeDirectionsHeadTilt__0126__A' % torsion does NOT look good for any head tilts
                    baselineIdxL = 4415:5339;
                    baselineIdxU = 157655:159508;
                    baselineIdxR = 313761:314641;

                    dataIdxL = 4415:157655;                    
                    dataIdxU = 157655:313761;
                    dataIdxR = 313761:426922;
                    
                case 'SaccadeDirectionsHeadTilt__0127__A' 
                    baselineIdxL = 7325:8221;
                    baselineIdxU = 168425:169491;
                    baselineIdxR = 334665:336917;
                    
                    dataIdxL = 7325:168425;
                    dataIdxU = 168425:334665;
                    dataIdxR = 334665:451495;
                case 'SaccadeDirectionsHeadTilt__0128__A'
                    baselineIdxL = 6011:6200;
                    baselineIdxU = 157718:158488;
                    baselineIdxR = 313985:316500;
                    
                    dataIdxL = 6011:157718;
                    dataIdxU = 157718:313985;
                    dataIdxR = 313985:434062;
                    
                case 'SaccadeDirectionsHeadTilt__0129__A'
                    baselineIdxL = 6372:7376;
                    baselineIdxU = 165048:165782;
                    baselineIdxR = 323402:324853;
                    
                    dataIdxL = 6372:165048;
                    dataIdxU = 165048:323402;
                    dataIdxR = 323402:450745;
                
                case 'SaccadeDirectionsHeadTilt__0166__A' % torsion for head left and head upright look bad
                    baselineIdxL = 4747:5747;
                    baselineIdxU = 164543:165543;
                    baselineIdxR = 320794:321701;
                    
                    dataIdxL = 4747:164543;
                    dataIdxU = 164543:320794;
                    dataIdxR = 320794:438394;
                
                case 'SaccadeDirectionsHeadTilt__0167__A'
                    baselineIdxL = 6370:7353;
                    baselineIdxU = 168253:168896;
                    baselineIdxR = 329589:332200;
                    
                    dataIdxL = 6370:168253;
                    dataIdxU = 168253:329589;
                    dataIdxR = 329589:446844;
                    
                case 'SaccadeDirectionsHeadTilt__0169__A'
                    baselineIdxL = 3771:5040;
                    baselineIdxU = 169717:170787;
                    baselineIdxR = 340328:34113;
                    
                    dataIdxL = 3771:169717;
                    dataIdxU = 169717:340328;
                    dataIdxR = 340328:451456;
                    
                case 'SaccadeDirectionsHeadTilt__0172__A'
                    baselineIdxL = 6881:8194;
                    baselineIdxU = 166300:167579;
                    baselineIdxR = 318920:320131;
                    
                    dataIdxL = 6881:166300;
                    dataIdxU = 166300:318920;
                    dataIdxR = 318920:429925;
                    
                case 'SaccadeDirectionsHeadTilt__0173__A'
                    baselineIdxL = 5869:7212;
                    baselineIdxU = 160538:161700;
                    baselineIdxR = 315533:316773;
                    
                    dataIdxL = 5869:160538;
                    dataIdxU = 160538:315533;
                    dataIdxR = 315533:425381;
            end
            samplesDataTable.LeftT(dataIdxL) = samplesDataTable.LeftT(dataIdxL) - mean(samplesDataTable.LeftT(baselineIdxL),'omitnan');
            samplesDataTable.RightT(dataIdxL) = samplesDataTable.RightT(dataIdxL) - mean(samplesDataTable.RightT(baselineIdxL),'omitnan');
            
            samplesDataTable.LeftT(dataIdxU) = samplesDataTable.LeftT(dataIdxU) - mean(samplesDataTable.LeftT(baselineIdxU),'omitnan');
            samplesDataTable.RightT(dataIdxU) = samplesDataTable.RightT(dataIdxU) - mean(samplesDataTable.RightT(baselineIdxU),'omitnan');
            
            samplesDataTable.LeftT(dataIdxR) = samplesDataTable.LeftT(dataIdxR) - mean(samplesDataTable.LeftT(baselineIdxR),'omitnan');
            samplesDataTable.RightT(dataIdxR) = samplesDataTable.RightT(dataIdxR) - mean(samplesDataTable.RightT(baselineIdxR),'omitnan');
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