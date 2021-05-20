classdef IllusoryTiltPerception < ArumeExperimentDesigns.SVV2AFC
    %Illusotry tilt Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        texControl = [];
        texLeft = [];
        texRight = [];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.SVV2AFC(this, importing);
            
            dlg.StimulusContrast0to100 = 20;
            dlg.TestWithoutTilt = { {'{0}','1'} };
            
            %% override defaults
            dlg.fixationDuration = { 500 '* (ms)' [1 3000] };
            dlg.targetDuration = { 100 '* (ms)' [100 30000] };
            dlg.Target_On_Until_Response = { {'0','{1}'} }; 
            dlg.responseDuration = { 1500 '* (ms)' [100 3000] };
        end
        
        
        % Set up the trial table when a new session is created
        function trialTable = SetUpTrialTable( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Angle';
            conditionVars(i).values = -10:2:10;
            
            i = i+1;
            conditionVars(i).name   = 'Position';
            conditionVars(i).values = {'Up'};
            
            i = i+1;
            conditionVars(i).name   = 'Image';
            conditionVars(i).values = {'Left' 'Right'};
            
            trialTableOptions = this.GetDefaultTrialTableOptions();
            trialTableOptions.trialSequence = 'Random';
            trialTableOptions.trialAbortAction = 'Delay';
            trialTableOptions.trialsPerSession = 100;
            trialTableOptions.numberOfTimesRepeatBlockSequence = 5;
            trialTable = this.GetTrialTableFromConditions(conditionVars, trialTableOptions);
        end
        
        function [trialResult, thisTrialData] = runPreTrial( this, thisTrialData )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
            if ( isempty(this.Session.currentRun.pastTrialTable) && this.ExperimentOptions.HeadAngle ~= 0 )
                [trialResult, thisTrialData] = this.TiltBiteBar(this.ExperimentOptions.HeadAngle, thisTrialData);
            end
            
            
            I = imread(fullfile(fileparts(mfilename('fullpath')),'TiltWithBlur.tiff'));
            Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
            
            Isquare = imresize(Isquare, [this.Graph.wRect(4) this.Graph.wRect(4)], 'bilinear');

            this.texRight = Screen('MakeTexture', this.Graph.window, Isquare);
            this.texLeft = Screen('MakeTexture', this.Graph.window, Isquare(end:-1:1,:,:));
                    
        end
            
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            graph = this.Graph;
            
            trialDuration = this.ExperimentOptions.TrialDuration;
            
            %-- add here the trial code
            Screen('FillRect', graph.window, 0);
            
            % SEND TO PARALEL PORT TRIAL NUMBER
            %write a value to the default LPT1 printer output port (at 0x378)
            %nCorrect = sum(this.Session.currentRun.pastConditions(:,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT );
            %outp(hex2dec('378'),rem(nCorrect,100)*2);
            
            lastFlipTime                        = Screen('Flip', graph.window);
            secondsRemaining                    = trialDuration;
            thisTrialData.TimeStartLoop         = lastFlipTime;
            if ( ~isempty(this.eyeTracker) )
                thisTrialData.EyeTrackerFrameStartLoop = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_LOOP %d %d', thisTrialData.TrialNumber, thisTrialData.Condition) );
            end
            while secondsRemaining > 0
                
                secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                secondsRemaining    = trialDuration - secondsElapsed;
                
                % -----------------------------------------------------------------
                % --- Drawing of stimulus -----------------------------------------
                % -----------------------------------------------------------------
                
                %-- Find the center of the screen
                [mx, my] = RectCenter(graph.wRect);
                
                
                t1 = this.ExperimentOptions.fixationDuration/1000;
                t2 = this.ExperimentOptions.fixationDuration/1000 +this.ExperimentOptions.targetDuration/1000;
                
                if ( secondsElapsed > t1 && (this.ExperimentOptions.Target_On_Until_Response || secondsElapsed < t2) )
                    %-- Draw target
                    
                    switch(thisTrialData.Image)
                        case 'Left'
                            tex = this.texLeft;
                        case 'Right'
                            tex = this.texRight;
                        case 'Control'
                            tex = this.texControl;
                    end
                    
                    if ( this.ExperimentOptions.TestWithoutTilt)
                        Screen('DrawTexture', this.Graph.window, tex);        
                    else
                        Screen('DrawTexture', this.Graph.window, tex, [],[],thisTrialData.Angle);        
                    end
        
        
                    % SEND TO PARALEL PORT TRIAL NUMBER
                    %write a value to the default LPT1 printer output port (at 0x378)
                    %outp(hex2dec('378'),7);
                end
                
                fixRect = [0 0 10 10];
                fixRect = CenterRectOnPointd( fixRect, mx, my );
                Screen('FillOval', graph.window,  this.targetColor, fixRect);
                
                this.Graph.Flip(this, thisTrialData, secondsRemaining);
                % -----------------------------------------------------------------
                % --- END Drawing of stimulus -------------------------------------
                % -----------------------------------------------------------------
                
                
                % -----------------------------------------------------------------
                % --- Collecting responses  ---------------------------------------
                % -----------------------------------------------------------------
                
                if ( secondsElapsed > max(t1,0.200)  )
                    reverse = thisTrialData.Position == 'Down';
                    response = this.CollectLeftRightResponse(reverse);
                    if ( ~isempty( response) )
                        thisTrialData.Response = response;
                        thisTrialData.ResponseTime = GetSecs;
                        thisTrialData.ReactionTime = thisTrialData.ResponseTime - thisTrialData.TimeStartLoop - t1;
                        
                        % SEND TO PARALEL PORT TRIAL NUMBER
                        %write a value to the default LPT1 printer output port (at 0x378)
                        %outp(hex2dec('378'),9);
                        
                        break;
                    end
                end
                
                % -----------------------------------------------------------------
                % --- END Collecting responses  -----------------------------------
                % -----------------------------------------------------------------
                
            end
            
            if ( isempty(response) )
                trialResult = Enum.trialResult.ABORT;
            else
                trialResult = Enum.trialResult.CORRECT;
            end
        end
          
    end
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        function [out] = Plot_Sigmoids_by_Tilt(this)
            %%
            d = this.Session.currentRun.pastTrialTable(:,{'Image','Angle','Response'});
            d(ismissing(d.Response),:)=[];
            figure
            subplot(1,2,1);
            ArumeExperimentDesigns.SVV2AFC.PlotSigmoid(d.Angle(d.Image=='Left'), d.Response(d.Image=='Left'));
            xlabel('Angle (deg)');
            ylabel('Percent response right');
            title('Left tilt');
            set(gca,'xlim',[-30 30])
            subplot(1,2,2);
            ArumeExperimentDesigns.SVV2AFC.PlotSigmoid(d.Angle(d.Image=='Right'), d.Response(d.Image=='Right'));
            xlabel('Angle (deg)');
            ylabel('Percent response right');
            title('Right tilt');
            set(gca,'xlim',[-30 30])
        end
    end
    
    methods(Static=true)
        function [] = DrawStimIllusoryTilt()
            %%
            %% Drawing illusory tilt stimuli based on cafe wall illusion
            %%
            %% - This script draws a tunnel with illusory tilted walls based on the cafe wall illusion
            %% - the stimulus is drawing using patches in a matlab axis from -1 to +1.
            %%
            %%
            % -- begin set parameters
            
            h = [0 0]; % horizon point
            L = 10; % length of the corridor
            N1 = 16; % number of tiles per row
            N2 = 20; % number of rows
            
            bw = [0 0 0 ; 1 1 1]; % colors of the tiles
            
            shift = 0.5;
            
            hl = 0.02; % grey line thickness
            colorl = 0.6*[1 1 1]; % grey line color
            
            CENTER_SQUARE = 0; % 1 for center blurry square 0 for circle
            
            % -- end set parameters
            
            % height of the figure should be enough to fit the pattern diagonally
            
            figure('color','k','visible','off');
            axis equal
            set(gca,'xlim',[-1 1]*1.1,'ylim',[-1 1]*1.1,'visible','off')
            set(gca,'innerposition',[0 0 1 1]);
            set(gcf,'position',[20 20 1000 1000])
            
            for side = 1:4
                for j=1:N2
                    for i=0:N1+1
                        
                        w = 2/N1; % width of the tiles
                        h = L/N2; % height of the tiles
                        
                        color = bw(mod(i+1,2)+1,:); % color of the current tile
                        
                        rowshift = mod(shift*2/N1*(j-1),2); % shift of the current row.
                        
                        
                        cornerx = -1 + 2/N1*(i-1) + rowshift; % position of the current tile
                        cornery = L/N2*(j-1);
                        
                        % cycle the tiles if the shift move them outside
                        if ( cornerx > 1 )
                            cornerx = cornerx -2*(N1+2)/N1;
                        end
                        
                        if ( cornerx+w*2 < -1 )
                            cornerx = cornerx +2*(N1+2)/N1;
                        end
                        
                        % if the tile is just outside don't draw it.
                        if ( (cornerx+w <= -1 ) || (cornerx >= 1) )
                            continue;
                        end
                        
                        % corners of the tile without perspective
                        corners = [
                            cornerx         cornery;
                            cornerx + w     cornery;
                            cornerx + w     cornery + h;
                            cornerx         cornery + h;
                            cornerx         cornery];
                        
                        corners(1,1) = max(corners(1,1), -1);
                        corners(2,1) = min(corners(2,1), 1);
                        corners(3,1) = min(corners(3,1), 1);
                        corners(4,1) = max(corners(4,1), -1);
                        corners(5,1) = max(corners(5,1), -1);
                        
                        % corners of the tile with perspective distorsion
                        switch(side)
                            case 1
                                corners(:,1) = corners(:,1) ./ (1+corners(:,2));
                                corners(:,2) = -1 ./(1+ corners(:,2));
                            case 2
                                corners = [-1 ./(1+ corners(:,2))  -corners(:,1) ./ (1+corners(:,2))];
                            case 3
                                corners(:,1) = - corners(:,1) ./ (1+corners(:,2));
                                corners(:,2) =  1 ./(1+ corners(:,2));
                            case 4
                                corners = [1 ./(1+ corners(:,2))  corners(:,1) ./ (1+corners(:,2))];
                        end
                        
                        % draw the tile
                        patch(corners(:,1), corners(:,2),zeros(size(corners(:,2))), 'facecolor',color,'edgecolor','none');
                    end
                    
                    % Draw the grey squares
                    
                    if ( j==1)
                        continue; % do not do a square for the first row of tiles
                    end
                    
                    corners = [
                        -1          L/N2*(j-1);
                        1           L/N2*(j-1);
                        1           L/N2*(j-1) + hl;
                        -1          L/N2*(j-1) + hl;
                        -1          L/N2*(j-1)];
                    
                    corners(1,1) = max(corners(1,1), -1);
                    corners(2,1) = min(corners(2,1), 1);
                    corners(3,1) = min(corners(3,1), 1);
                    corners(4,1) = max(corners(4,1), -1);
                    corners(5,1) = max(corners(5,1), -1);
                    
                    
                    switch(side)
                        case 1
                            corners(:,1) = corners(:,1) ./ (1+corners(:,2));
                            corners(:,2) = -1 ./(1+ corners(:,2));
                        case 2
                            corners = [-1 ./(1+ corners(:,2))  -corners(:,1) ./ (1+corners(:,2))];
                        case 3
                            corners(:,1) = - corners(:,1) ./ (1+corners(:,2));
                            corners(:,2) =  1 ./(1+ corners(:,2));
                        case 4
                            corners = [1 ./(1+ corners(:,2))  corners(:,1) ./ (1+corners(:,2))];
                    end
                    
                    patch(corners(:,1), corners(:,2),zeros(size(corners(:,2))), 'facecolor',colorl,'edgecolor','none');
                    
                    
                    
                    % draw diagonal lines
                    
                    corners = [
                        -1          0;
                        -1           L;
                        -1+hl           L;
                        -1+hl          0;
                        -1          0];
                    
                    corners(1,1) = max(corners(1,1), -1);
                    corners(2,1) = min(corners(2,1), 1);
                    corners(3,1) = min(corners(3,1), 1);
                    corners(4,1) = max(corners(4,1), -1);
                    corners(5,1) = max(corners(5,1), -1);
                    
                    
                    switch(side)
                        case 1
                            corners(:,1) = corners(:,1) ./ (1+corners(:,2));
                            corners(:,2) = -1 ./(1+ corners(:,2));
                        case 2
                            corners = [-1 ./(1+ corners(:,2))  -corners(:,1) ./ (1+corners(:,2))];
                        case 3
                            corners(:,1) = - corners(:,1) ./ (1+corners(:,2));
                            corners(:,2) =  1 ./(1+ corners(:,2));
                        case 4
                            corners = [1 ./(1+ corners(:,2))  corners(:,1) ./ (1+corners(:,2))];
                    end
                    
                    patch(corners(:,1), corners(:,2),zeros(size(corners(:,2))), 'facecolor',colorl,'edgecolor','none');
                    
                    % draw diagonal lines
                    
                    corners = [
                        1          0;
                        1           L;
                        1-hl           L;
                        1-hl          0;
                        1          0];
                    
                    corners(1,1) = max(corners(1,1), -1);
                    corners(2,1) = min(corners(2,1), 1);
                    corners(3,1) = min(corners(3,1), 1);
                    corners(4,1) = max(corners(4,1), -1);
                    corners(5,1) = max(corners(5,1), -1);
                    
                    
                    switch(side)
                        case 1
                            corners(:,1) = corners(:,1) ./ (1+corners(:,2));
                            corners(:,2) = -1 ./(1+ corners(:,2));
                        case 2
                            corners = [-1 ./(1+ corners(:,2))  -corners(:,1) ./ (1+corners(:,2))];
                        case 3
                            corners(:,1) = - corners(:,1) ./ (1+corners(:,2));
                            corners(:,2) =  1 ./(1+ corners(:,2));
                        case 4
                            corners = [1 ./(1+ corners(:,2))  corners(:,1) ./ (1+corners(:,2))];
                    end
                    
                    patch(corners(:,1), corners(:,2),zeros(size(corners(:,2))), 'facecolor',colorl,'edgecolor','none');
                end
            end
            
            %%
            tempfile = 'temp.png';
            source_fig = gcf;
            set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 10])
            set(source_fig,'InvertHardcopy','off');
            print(source_fig,['-r',num2str(216)], '-dpng', tempfile);
            illusionimage = imread(tempfile);
            %%
            %%
            [xmesh, ymesh] = meshgrid(-2160/2:2160/2-1, -2160/2:2160/2-1);
            
            R1 = 200;
            R2 = 2160/2/1.1-350;
            S1 = 20;
            S2 = 20;
            
            rs = sqrt(max(xmesh.^2,ymesh.^2));
            r = sqrt(xmesh.^2 +ymesh.^2);
            
            
            mask = zeros(size(xmesh));
            % mask(r<R1 | r>R2) = 1;
            if ( CENTER_SQUARE )
                mask = 1./(1 + exp(-(rs-R1)/S1)) + 1./(1 + exp((r-R2)/S2))-1;
            else
                mask = 1./(1 + exp(-(r-R1)/S1)) + 1./(1 + exp((r-R2)/S2))-1;
            end
            
            
            if ( 1 )
                figure
                imshow(uint8(double(illusionimage).*mask))
            end
            
            imwrite(uint8(double(illusionimage).*mask), 'TiltWithBlur.tiff');
            
        end
    end
end