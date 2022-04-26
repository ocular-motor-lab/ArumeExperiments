classdef VRTOKN < ArumeExperimentDesigns.EyeTracking
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
                fullfile(folder,dir(fullfile(folder, '*fove*')).name)};
            
            trialFiles = { ...
                fullfile(folder,dir(fullfile(folder, '*trial_results*')).name)};
                
            newRun.pastTrialTable = table();
            for i=1:1
                d = readtable(trialFiles{i});
                trialTable = table();
                trialTable.TrialResult = repmat(categorical(cellstr('CORRECT')),height(d),1);
                if ( i==1)
                    trialTable.TrialNumber = d.trial_num;
                else
                    trialTable.TrialNumber = d.trial_num + max(newRun.pastTrialTable.TrialNumber);
                end
                trialTable.FileNumber = i*ones(size(trialTable.TrialNumber));
                

                % ADD experiment specific columns
                responses = {'L' 'R'};
                frames = {'NoFrame' 'Frame'};
                olverlaps = {'NoOverlap' 'Overlap'};

                trialTable.TrialStartTime = d.start_time;
                trialTable.TrialEndTime = d.end_time;
                trialTable.RotationSpeed = d.RotationSpeed;
                trialTable.Frame = categorical(frames(( categorical(d.Frame)=='True')+1)');
                trialTable.InitialFrameTilt = d.Phase;
                trialTable.Overlap = categorical(olverlaps(( categorical(d.Overlap)=='True')+1)');
                trialTable.LineAngle = d.Direction;
                trialTable.Response(~isnan(d.Response)) = categorical(responses(d.Response(~isnan(d.Response))+1)');

                % end ADD experiment specific columns



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

        function [out] = Plot_Raul(this)

            C = get_nice_colors;
            %%
            s = this.Session.samplesDataTable;
            t = this.Session.trialDataTable;
            t(ismissing(t.Response),:) = [];

            angles = t.LineAngle(t.InitialFrameTilt==-30);
            responses = t.Response(t.InitialFrameTilt==-30);
            [SVVLeft, aLeft, pLeft, allAnglesLeft, allResponsesLeft, trialCountsLeft, SVVthLeft, SVVstdLeft] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses, 1);

            angles = t.LineAngle(t.InitialFrameTilt==0);
            responses = t.Response(t.InitialFrameTilt==0);
            [SVVUpright, aUpright, pUpright, allAnglesUpright, allResponsesUpright, trialCountsUpright, SVVthUpright, SVVstdUpright] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses, 1);

            angles = t.LineAngle(t.InitialFrameTilt==30);
            responses = t.Response(t.InitialFrameTilt==30);
            [SVVRight, aRight, pRight, allAnglesRight, allResponsesRight, trialCountsRight, SVVthRight, SVVstdRight] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses, 1);


            figure('position',[400 400 600 400],'color','w','name',this.Session.name)
            ax1 = gca;

            set(ax1,'nextplot','add', 'fontsize',12);
            
            hleg(1) = plot( allAnglesLeft, allResponsesLeft,'o', 'color', C.MEDIUM_BLUE, 'markersize',15,'linewidth',2, 'markerfacecolor', [0.7 0.7 0.7])
            plot(aLeft,pLeft, 'color', C.MEDIUM_BLUE,'linewidth',3);
            line([SVVLeft, SVVLeft], [-10 110], 'color',C.MEDIUM_BLUE,'linewidth',3,'linestyle','-.');
            line([0, 0], [-10 50], 'color',C.MEDIUM_BLUE,'linewidth',2,'linestyle','-.');
            line([0, SVVLeft], [50 50], 'color',C.MEDIUM_BLUE,'linewidth',2,'linestyle','-.');


            hleg(2) = plot( allAnglesUpright, allResponsesUpright,'o', 'color', C.MEDIUM_RED, 'markersize',15,'linewidth',2, 'markerfacecolor', [0.7 0.7 0.7])
            plot(aUpright,pUpright, 'color', C.MEDIUM_RED,'linewidth',3);
            line([SVVUpright, SVVUpright], [-10 110], 'color',C.MEDIUM_RED,'linewidth',3,'linestyle','-.');
            line([0, 0], [-10 50], 'color',C.MEDIUM_RED,'linewidth',2,'linestyle','-.');
            line([0, SVVUpright], [50 50], 'color',C.MEDIUM_RED,'linewidth',2,'linestyle','-.');


            hleg(3) = plot( allAnglesRight, allResponsesRight,'o', 'color', C.MEDIUM_GREEN, 'markersize',15,'linewidth',2, 'markerfacecolor', [0.7 0.7 0.7])
            plot(aRight,pRight, 'color', C.MEDIUM_GREEN,'linewidth',3);
            line([SVVRight, SVVRight], [-10 110], 'color',C.MEDIUM_GREEN,'linewidth',3,'linestyle','-.');
            line([0, 0], [-10 50], 'color',C.MEDIUM_GREEN,'linewidth',2,'linestyle','-.');
            line([0, SVVRight], [50 50], 'color',C.MEDIUM_GREEN,'linewidth',2,'linestyle','-.');
            
            set(gca,'xlim',[-30 +30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'ytick',[0:25:100])
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            xlabel('Angle (deg)', 'fontsize',16);

            legend(hleg,{'Left' 'Upright' 'Right'},'box','off')

        end
    end
end