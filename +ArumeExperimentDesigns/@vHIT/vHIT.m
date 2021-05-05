classdef vHIT  < ArumeExperimentDesigns.EyeTracking
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods (Access=protected)
        function dlg = GetOptionsDialog( this, importing )
            dlg = [];
            if ( exist('importing','var') && importing )
                dlg.RawDataFile = { {['uigetfile(''' fullfile(pwd,'*.csv') ''',''MultiSelect'', ''off'')']} };
            end
        end
    end
    
    % --------------------------------------------------------------------
    % Analysis methods --------------------------------------------------
    % --------------------------------------------------------------------
    methods ( Access = public )
        %% ImportSession
        function ImportSession( this )
            % add minimum necessary stuff for single trial
            newRun = ArumeCore.ExperimentRun.SetUpNewRun( this );
            vars = newRun.futureTrialTable;
            vars.TrialResult = categorical(cellstr('CORRECT'));
            vars.TrialNumber = 1;
            newRun.AddPastTrialData(vars);
            newRun.futureTrialTable(:,:) = [];
            this.Session.importCurrentRun(newRun);
            
            
            rawFile = this.ExperimentOptions.RawDataFile;
            
            if (exist(rawFile,'file') )
                this.Session.addFile('vogRawDataFile', rawFile);
            end
            
            
            options = [];
            options.Prepare_For_Analysis_And_Plots = 1;
            options.Preclear_Trial_Table = 0;
            options.Preclear_Session_Table = 0;            
            this.Session.prepareForAnalysis(options);
        end
        
        function [samplesDataTable, cleanedData, calibratedData, rawData] = PrepareSamplesDataTable(this, params)
            samplesDataTable = [];
            cleanedData = [];
            calibratedData = [];
            rawData = [];
            
            if ( ~isprop(this.Session.currentRun, 'LinkedFiles' ) || ~isfield(this.Session.currentRun.LinkedFiles,  'vogRawDataFile') )
                return;
            end
            
            % FOR SAI load the file that you added in import using Linkedfiles
            rawFile = this.Session.currentRun.LinkedFiles.vogRawDataFile;
            
            cprintf('blue','ARUME :: PreparingDataTable::Reading data File %s ...\n',rawFile);
            
            rawFilePath = fullfile(this.Session.dataPath, rawFile);
            
            rawData = readtable(rawFilePath);
            samplesDataTable = table();
            samplesDataTable.FrameNumber = (1:height(rawData))';
            samplesDataTable.RawFrameNumber = (1:height(rawData))';
            samplesDataTable.Time = rawData.Time;
            samplesDataTable.LeftX = (rawData.LeftEyeEuY);
            samplesDataTable.LeftY = (rawData.LeftEyeEuX);
            samplesDataTable.LeftT = zeros(size(rawData.LeftEyeEuX));
            samplesDataTable.RightX = (rawData.RightEyeEuY);
            samplesDataTable.RightY = (rawData.RightEyeEuX);
            samplesDataTable.RightT = zeros(size(rawData.LeftEyeEuX));
            samplesDataTable.LeftBadData = zeros(size(rawData.LeftEyeEuX));
            samplesDataTable.RightBadData = zeros(size(rawData.LeftEyeEuX));
            samplesDataTable.LeftL = (rawData.leftEyelid);
            samplesDataTable.RightL = (rawData.RightEyelid);
%             
            samplesDataTable.HeadX = (rawData.HeadEuY);
            samplesDataTable.HeadY = (rawData.HeadEuX);
            samplesDataTable.HeadT = (rawData.HeadEuZ);
            
            samplesDataTable  = VOGAnalysis.ResampleData(samplesDataTable,params);
            samplesDataTable.FileNumber = ones(height(samplesDataTable), 1);
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function [hh,h] = Plot_Example1(this, options)
            a=1;
        end
        
        function [hh,h] = Plot_Example2(this, options)
            a=1;
        end
        
        function [hh,h] = Plot_Example4(this, options)
            hh=[];
            h=[];
            samples = this.Session.samplesDataTable;
            
            % Arrays to store meaningful vertical eye position and velocity
            eyePosComp = [];
            eyeVertVelComp = [];
            
            % Quick phase array to determine marked skew deviations
            skewLabels = samples.QuickPhase;
            
            % Vertical pos and velocity
            vertPosY = samples.RightY;
            vertVelY = samples.RightVelY;
            
            for i = 1:length(skewLabels)
                if skewLabels(i) == 1 && skewLabels(i-1) == 0
                    % check for index out of bounds?
                    eyePosExtract = vertPosY(i-50:i+77);
                    eyeVertVelExtract = vertVelY(i-50:i+77);
                    eyePosComp = [eyePosComp eyePosExtract];
                    eyeVertVelComp = [eyeVertVelComp eyeVertVelExtract];
                end
            end
            
            eyePosComp = eyePosComp';
            eyeVertVelComp = eyeVertVelComp';
            t_compiled = 1:1:128;
            
            %{
            for r = 1:rows
                for c = 1:cols
                    if eyeVertVelComp(r,c) <= -70
                        eyeExtract = eyePosComp(r, c-10:c+50);
                        eyeCompiledPos = [eyeCompiledPos; eyeExtract];
                        break
                    end
                end
            end
            %}
            figure
            plot(t_compiled,eyePosComp,'Color',[0.9100 0.4100 0.1700],'DisplayName','skew');
            
        end
        
        %{
            Plot_vHITSummary
        
            - Plots all labeled head impulses/eye traces within the timeframe of 140ms
            to 608ms 
            - Gains are calculated and plotted. Calculation was done by
            averaging all of the head impulse and eye traces, taking a 60ms slice 
            from where the average head impulse velocity exceeds 50 or
            drops below -50, then dividing the area under the curve of the
            average eye slice and the area under the curve of the average
            head slice.
        %}
        function [hh,h] = Plot_vHITSummary(this,options)
            hh=[];
            h=[];
            hit = this.Session.samplesDataTable;

            close all;
            
            headCompiledPos = [];
            headCompiledNeg = [];
            eyeCompiledPos = [];
            eyeCompiledNeg = [];
            sacCompiledPos = [];
            sacCompiledNeg = [];

            % Create arrays of impulses for head, eye, saccades,
            % quickphases depending on labels hand selected.
            [head, eye, saccade, quickPhase] = createHITArray(hit.HeadImpule,hit.QuickPhase,hit.HeadVelX,hit.RightVelX);
            head = head';
            eye = eye';
            saccade = saccade';
            quickPhase = quickPhase';
            [rows, cols] = size(head);
            
            % For Otosuite Graphs = -140:4:560
            % For EyeSeeCam Graphs = -28:4:300
            
            t_compiled = -28:4:300;
            
            for r = 1:rows
                for c = 1:cols
                    % For Otosuite Graphs = -35, +140
                    % For EyeSeeCam Graphs = -7, +75
                    
                    if head(r,c) >= 50 % -35 -> 152 for 250Hz, -60 -> 312 for 500Hz, 20 -> 87 for catchups only
                        headExtractPos = head(r,c-7:c+75);
                        headCompiledPos = [headCompiledPos; headExtractPos];
                        eyeExtractPos = eye(r,c-7:c+75);
                        eyeCompiledPos = [eyeCompiledPos; eyeExtractPos]; 
                        sacExtractPos = saccade(r,c-7:c+75);
                        sacExtractPos(sacExtractPos==1) = eyeExtractPos(sacExtractPos==1);
                        sacCompiledPos = [sacCompiledPos; sacExtractPos];
                        break
                    elseif head(r,c) <= -50
                        headExtractNeg = head(r,c-7:c+75);
                        headCompiledNeg = [headCompiledNeg; headExtractNeg];
                        eyeExtractNeg = eye(r,c-7:c+75);
                        eyeCompiledNeg = [eyeCompiledNeg; eyeExtractNeg];
                        sacExtractNeg = saccade(r,c-7:c+75);
                        sacExtractNeg(sacExtractNeg==1) = eyeExtractNeg(sacExtractNeg==1);
                        sacCompiledNeg = [sacCompiledNeg; sacExtractNeg];
                        break
                    end
                end
            end

            
            h = figure('position',[0 0 650,175]);

            % ------------------------------ 
            % Gain Calculation
            % ------------------------------
            
            % Get the average lines of head impulses and eye traces
            avgHeadpos = mean(headCompiledPos);
            avgHeadneg = mean(headCompiledNeg);
            avgEyepos = mean(eyeCompiledPos);
            avgEyeneg = mean(eyeCompiledNeg);

            [~, cols] = size(avgHeadpos);
            [~, colsneg] = size(avgHeadneg);
            headImpulsePosStart = 0;
            headImpulseNegStart = 0;

            % Get index of where head impulses start
            for i = 1:cols
                if avgHeadpos(i) >= 50
                    headImpulsePosStart = i;
                    break;
                end
            end

            for i = 1:colsneg
                if avgHeadneg(i) <= -50
                    headImpulseNegStart = i;
                    break;
                end
            end

            % slice head, eye, and time 60ms in the future (15 * 4 frames = 60ms)
            t_area_slice_pos = t_compiled(headImpulsePosStart:headImpulsePosStart+15);
            avgHeadSlicePos = avgHeadpos(headImpulsePosStart:headImpulsePosStart+15);
            avgEyeSlicePos = avgEyepos(headImpulsePosStart:headImpulsePosStart+15);

            t_area_slice_neg = t_compiled(headImpulseNegStart:headImpulseNegStart+15);
            avgHeadSliceNeg = avgHeadneg(headImpulseNegStart:headImpulseNegStart+15);
            avgEyeSliceNeg = avgEyeneg(headImpulseNegStart:headImpulseNegStart+15);
            
            % area under the curve for head/eye in the positive direction
            underCurvePos = trapz(t_area_slice_pos,avgHeadSlicePos);
            underCurveEPos = trapz(t_area_slice_pos,-avgEyeSlicePos);
            
            % area under the curve for head/eye in the negative direction
            underCurveNeg = trapz(t_area_slice_neg,-avgHeadSliceNeg);
            underCurveENeg = trapz(t_area_slice_neg,avgEyeSliceNeg);
            
            % divide to get the gains
            gainCurvePos = underCurveEPos/underCurvePos;
            gainCurveNeg = underCurveENeg/underCurveNeg;

            %% plot
            subplot(121);
            plot(t_compiled,-headCompiledNeg,'Color','b','DisplayName','head');
            hold on;
            %title('Left Direction')
            plot(t_compiled,eyeCompiledNeg,'g','DisplayName','normal eye');
            plot(t_compiled,sacCompiledNeg,'r','DisplayName','abnormal eye');
            plot(t_area_slice_neg,-avgHeadSliceNeg,'m','LineWidth',3,'DisplayName','abnormal eye');
            plot(t_area_slice_neg,avgEyeSliceNeg,'m','LineWidth',3,'DisplayName','abnormal eye');
            %plot(t_compiled,-avgHeadneg,'Color','b','LineWidth',3,'DisplayName','avgHead');
            %plot(t_compiled,avgEyeneg,'Color',[0 0.5 0],'LineWidth',3,'DisplayName','avgEye');
            gainNeg = ['Gains \approx ' num2str(gainCurveNeg)];
            [row, ~] = size(headCompiledNeg);
            text(175,200,"n = "+row,'FontSize',16)
            text(175,150,gainNeg,'FontSize',16)

            %xlim([min(t_compiled) max(t_compiled)]);
            set(gca,'FontSize',10);
            set(gca,'XLim', [min(t_compiled) max(t_compiled)]);
            set(gca,'XTick', (min(t_compiled):140:max(t_compiled)))
            set(gcf, 'Color', 'w');
            ylabel('Head & Eye Velocity','FontSize',10);
            ylim([-100 400]);
            xlabel('Left Lateral (LL) ms', 'FontSize', 10);
            %title('Head & Eye Left Direction');

            subplot(122);
            plot(t_compiled,headCompiledPos,'Color',[0.9100 0.4100 0.1700],'DisplayName','head');
            hold on;
            %title('Right Direction')
            plot(t_compiled,-eyeCompiledPos,'g','DisplayName','eye');
            plot(t_compiled,-sacCompiledPos,'r','DisplayName','abnormal eye');

            plot(t_area_slice_pos,avgHeadSlicePos,'m','LineWidth',3,'DisplayName','abnormal eye');
            plot(t_area_slice_pos,-avgEyeSlicePos,'m','LineWidth',3,'DisplayName','abnormal eye');
            % plot(t_compiled,avgHeadpos,'Color','b','LineWidth',3,'DisplayName','avgHead');
            % plot(t_compiled,-avgEyepos,'Color',[0 0.5 0],'LineWidth',3,'DisplayName','avgEye');
            gainPos = ['Gains \approx ' num2str(gainCurvePos)];
            [row, ~] = size(headCompiledPos);
            text(175,200,"n = "+row,'FontSize',16)
            text(175,150,gainPos,'FontSize',16)
            %xlim([min(t_compiled) max(t_compiled)]);
            set(gca,'FontSize',10);
            set(gca,'XLim', [min(t_compiled) max(t_compiled)]);
            set(gca,'XTick', (min(t_compiled):140:max(t_compiled)))
            ylabel('Head & Eye Velocity', 'FontSize',10);
            ylim([-100 400]);
            xlabel('Right Lateral (RL) ms', 'FontSize', 10);
            %title('Head & Eye Right Direction');
            %{
            subplot(223);

            headNFlat = headCompiledNeg(:);
            eyeNFlat = eyeCompiledNeg(:);

            nansamples = isnan(eyeNFlat);
            headNFlat = headNFlat(~nansamples);
            eyeNFlat = eyeNFlat(~nansamples);

            regN = headNFlat\eyeNFlat;
            lineN = regN * headNFlat;

            title(['Gains = ' num2str(-regN)])
            xlabel('Head Velocity')
            ylabel('Eye Velocity')
            hold on
            scatter(headNFlat,eyeNFlat)
            plot(headNFlat,lineN,'Color','k','LineWidth',4)

            subplot(224);
            headPFlat = headCompiledPos(:);
            eyePFlat = eyeCompiledPos(:);

            nansamples = isnan(eyePFlat);
            headPFlat = headPFlat(~nansamples);
            eyePFlat = eyePFlat(~nansamples);

            regP = headPFlat\eyePFlat;
            lineP = regP * headPFlat;

            title(['Gains = ' num2str(-regP)])
            xlabel('Head Velocity')
            ylabel('Eye Velocity')
            hold on
            scatter(headPFlat,eyePFlat)
            plot(headPFlat,lineP,'Color','k','LineWidth',4)
            %}
        end
    end
    
end

function appendToCSV(saccade, eye, head)
    % Catchup index 20-87
    csvFile = csvread('../../../Data/iPhone/Patients/labeledPatientData.csv');
    
    [rows, cols] = size(eye);
    
    
    catchup_count = 0;
    for row = 1:rows
        singleEyeTrace = eye(row,1:250);
        singleHeadTrace = head(row,1:250);
        saccadeValue = saccade(row);
        newEyeTrace = [];
        
        startCol = 1;
        i = 1;

        while i < length(singleEyeTrace)
            if singleHeadTrace(i) >= 80
                newi = i;
                while newi < length(singleHeadTrace)
                    if singleHeadTrace(newi) <= 0
                        startCol = newi;
                        break;
                    else
                        newi = newi + 1;
                    end
                end
                break;
            elseif singleHeadTrace(i) <= -80
                newi = i;
                while newi < length(singleHeadTrace)
                    if singleHeadTrace(newi) >= 0
                        startCol = newi;
                        break;
                    else
                        newi = newi + 1;
                    end
                end
                break;
            else
                i = i+1;
            end 
        end
        
        for col = startCol:(startCol+67)
            newEyeTrace = [newEyeTrace singleEyeTrace(col)];
        end
        if saccadeValue == 1
            newEyeTrace = [newEyeTrace 1];
            catchup_count = catchup_count + 1;
        else
            newEyeTrace = [newEyeTrace 0];
        end
        
        %newEyeTrace(1:numel(newEyeTrace)-1) = -newEyeTrace(1:numel(newEyeTrace)-1);
        
        
        
        if (min(singleEyeTrace) < -150)
            newEyeTrace(1:numel(newEyeTrace)-1) = -newEyeTrace(1:numel(newEyeTrace)-1);
            csvFile = [csvFile; newEyeTrace];
            %csvwrite('../../../Data/iPhone/Patients/labeledPatientData.csv',newEyeTrace);
        else
            csvFile = [csvFile; newEyeTrace]; 
            %csvwrite('../../../Data/iPhone/Patients/labeledPatientData.csv',newEyeTrace);
        end
        
    end
    
    disp(catchup_count);
    csvwrite('../../../Data/iPhone/Patients/labeledPatientData.csv',csvFile);
    
end



