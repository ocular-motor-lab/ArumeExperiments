classdef OptostaticTorsionVergence < ArumeExperimentDesigns.EyeTracking
    % Stereoacuity_Vergence
    %
    %   Experiment will show dots at different simulated depths, eliciting
    %   different vergence eye movements. Different amounts of simulated
    %   OCR are applied, accounting for complicated geometry with
    %   convergence OCR.
    %
    properties
        targetColor = [255 0 0];
        stimTexture = [];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
            
            %% ADD new options
            dlg.StimSizeDeg = { 10 '* (diameter_in_deg)' [0 10000] }; 
            dlg.FixationSpotSize = { 0.2 '* (deg)' [0 5] };
            dlg.InitFixDuration = {2 '* (s)' [0 100] };
            dlg.TimeStimOn = { 10 '* (sec)' [0 60] }; 
            dlg.convergenceAmount = { 10 '* (deg)' [0 60] }; 
            dlg.StimulusContrast0to100 = {90 '* (%)' [0 100] };
            dlg.BackgroundBrightness = 0;
            
            %% CHANGE DEFAULTS values for existing options
            
            dlg.UseEyeTracker = 1;
            dlg.Debug.DisplayVariableSelection = 'TrialNumber Vergence ImTilt Image GuessedCorrectly'; % which variables to display every trial in the command line separated by spaces
            
            dlg.DisplayOptions.ScreenWidth = { 60 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenHeight = { 33.5 '* (cm)' [1 3000] };
            dlg.DisplayOptions.ScreenDistance = { 57 '* (cm)' [1 3000] };
            dlg.DisplayOptions.StereoMode = { 4 '* (mode)' [0 9] }; 
            dlg.DisplayOptions.SelectedScreen = { 1 '* (screen)' [0 5] };
            
            dlg.HitKeyBeforeTrial = 0;
            dlg.TrialDuration = 16;
            dlg.TrialsBeforeBreak = 33; %150
            dlg.TrialsBeforeCalibration = 100000;
            dlg.TrialAbortAction = 'Repeat';
        end
        
        function trialTable = SetUpTrialTable(this)
            
            %-- condition variables ---------------------------------------
            t = ArumeCore.TrialTableBuilder();
            
            t.AddConditionVariable( 'V', ["p" "c"]); % vergence: parallel or converged, repeated 6x
            t.AddConditionVariable( 'ImTilt', [-30 0 30]);
            %t.AddConditionVariable( 'Image', {'01' '02' '03' '04' '05' '06' '07' '08' '09' '10' '11' '12' '13' '14' '15' '16' '17' '18' '19' '20' '21' '22' '23' '24' '25' '26' '27' '28' '29' '30' '31' '32' '33' '34' '35' '36' '37' '38' '39' '40'} ); 
            %t.AddConditionVariable( 'Image', {'01' '02' '03' '06' '08' '09' '10' '15' '16' '17' '20' '25' '29' '30' '31' '32' '33' '35' '36' '40'}) %20 images
            t.AddConditionVariable( 'Image', {'01' '02' '03' '06' '08' '09' '10' '11' '12' '15' '16' '17' '19' '20' '21' '22' '23' '25' '28' '29' '30' '31' '32' '33' '34' '35' '36' '38' '39' '40'}) %30 images
            
            % Add blocks -- the vergence can change every 15 trials now
            ok=unique(t.ConditionTable.Image);
            if length(ok) ~= 30
                disp('there might be an error!!')
            end
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(1:5)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(6:10)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(11:15)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(16:20)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(21:25)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(26:30)) & t.ConditionTable.V=="p"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(1:5)) & t.ConditionTable.V=="c"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(6:10)) & t.ConditionTable.V=="c"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(11:15)) & t.ConditionTable.V=="c"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(16:20)) & t.ConditionTable.V=="c"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(21:25)) & t.ConditionTable.V=="c"),1)
            t.AddBlock(find(ismember(t.ConditionTable.Image,ok(26:30)) & t.ConditionTable.V=="c"),1)
            
            %t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            %t.AddBlock(find(t.ConditionTable.V=="c"), 1);
            %t.AddBlock(find(t.ConditionTable.V=="p"), 1);
            %t.AddBlock(find(t.ConditionTable.V=="c"), 1);

            trialSequence = 'Random';
            blockSequence =  'Random';
            blockSequenceRepeatitions = 1; % same as dlg.NumberOfRepetitions
            abortAction = 'Repeat';
            trialsPerSession = 100000;
            trialTable = t.GenerateTrialTable(trialSequence, blockSequence,blockSequenceRepeatitions, abortAction,trialsPerSession);
        end
        
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            try
                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;
                Screen('FillRect', graph.window, 0); % not sure if needed
                ShowCursor();
                
                % Loading an image
                test = string(thisTrialData.Image);
                imageFile = fullfile(fileparts(mfilename('fullpath')),[test + ".jpeg"]);
                I = imread(imageFile);
                
                % Settings
                monitorWidthPix     = this.Graph.wRect(3); % bc in stereoMode, this is ONE of the two onscreen wRects
                monitorWidthCm      = this.ExperimentOptions.DisplayOptions.ScreenWidth/2; % so need to divide by 2 here
                monitorDistanceCm   = this.ExperimentOptions.DisplayOptions.ScreenDistance;
                stimSizeDeg         = this.ExperimentOptions.StimSizeDeg;

                % Resizing the image to be our desired size in degrees 
                % non linear aproximation
                stimSizeCm  = 2*tand(stimSizeDeg/2)*monitorDistanceCm;
                stimSizePix = (monitorWidthPix/monitorWidthCm)*stimSizeCm;
                Isquare = uint8(double(I(:,(size(I,2) - size(I,1))/2+(1:(size(I,1))),:,:))*this.ExperimentOptions.StimulusContrast0to100/100);
                Isquare = imresize(Isquare, [stimSizePix stimSizePix], 'bilinear');
                this.stimTexture = Screen('MakeTexture', this.Graph.window, Isquare);
                
                % Get fixation spot size in pix
                moniterWidth_deg = (atan2d(this.ExperimentOptions.DisplayOptions.ScreenWidth/2, this.ExperimentOptions.DisplayOptions.ScreenDistance)) * 2;
                pixPerDeg = (this.Graph.wRect(3)*2) / moniterWidth_deg;
                fixSizePix = pixPerDeg * this.ExperimentOptions.FixationSpotSize;
                
                % Determine fixation dot location depending on vergence 
                if thisTrialData.V == "p" || thisTrialData.V == "p1" || thisTrialData.V == "p2" || thisTrialData.V == "p3" || thisTrialData.V == "p4" || thisTrialData.V == "p5" || thisTrialData.V == "p6" || thisTrialData.V == "p7" || thisTrialData.V == "p8" || thisTrialData.V == "p9" || thisTrialData.V == "p10"
                    thisTrialData.Vergence = categorical("parallel");
                    fixXPix_LE = this.Graph.wRect(3)/2; % center coord
                    fixYPix_LE = this.Graph.wRect(4)/2; % center coord
                    fixXPix_RE=fixXPix_LE;  % same for the right eye
                    fixYPix_RE=fixYPix_LE;
                    x_top_left_LE = (this.Graph.wRect(3)/2) - (size(Isquare,1))/2;
                    x_top_left_RE = x_top_left_LE;
                    
                elseif thisTrialData.V == "c" || thisTrialData.V == "c1" || thisTrialData.V == "c2" || thisTrialData.V == "c3" || thisTrialData.V == "c4" || thisTrialData.V == "c5" || thisTrialData.V == "c6"|| thisTrialData.V == "c7" || thisTrialData.V == "c8" || thisTrialData.V == "c9" || thisTrialData.V == "c10"
                    thisTrialData.Vergence = categorical("converged");
                    % this line is based on tan(x) = opp/adj where we have a desired x (convergence/2) and we want to know opp. once you get opp (the displacement on the screen in cm), you need to convert that to pix. lastly, the screen coordinates have zero on the far left of the screen so you need to add the middle back to get 0 to be at the "origin"
                    fixXPix_RE = -(tand(this.ExperimentOptions.convergenceAmount/2) * this.ExperimentOptions.DisplayOptions.ScreenDistance * (this.Graph.wRect(3)/(this.ExperimentOptions.DisplayOptions.ScreenWidth/2))) + this.Graph.wRect(3)/2;
                    fixYPix_RE = this.Graph.wRect(4)/2;
                    fixXPix_LE = this.Graph.wRect(3)/2 + (this.Graph.wRect(3)/2-fixXPix_RE);
                    fixYPix_LE = this.Graph.wRect(4)/2;
                    x_top_left_RE = fixXPix_RE- (size(Isquare,1)/2);
                    x_top_left_LE = fixXPix_LE - (size(Isquare,1)/2);
                end
                y_top_left = (this.Graph.wRect(4)/2) - (size(Isquare,2))/2;
                
                % For the while loop trial start
                lastFlipTime                        = Screen('Flip', graph.window);
                secondsRemaining                    = this.ExperimentOptions.TrialDuration;
                thisTrialData.TimeStartLoop         = lastFlipTime;

                %initialize this
                initialFixationDuration = this.ExperimentOptions.InitFixDuration;
                
                while secondsRemaining > 0

                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = this.ExperimentOptions.TrialDuration - secondsElapsed;

                    if thisTrialData.TrialNumber > 1
                        % If it's a new block
                        if thisTrialData.Vergence ~= this.Session.currentRun.pastTrialTable.Vergence(thisTrialData.TrialNumber-1)
                            initialFixationDuration = 6;
                        end
                    end

                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------


                    % If it's during the time when the stimulus is on, then show the stimulus plus the fixation dot
                    if ( secondsElapsed > initialFixationDuration && secondsElapsed < initialFixationDuration + this.ExperimentOptions.TimeStimOn) % then show dots + fixation dot

                        % Draw left stim:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[x_top_left_LE y_top_left x_top_left_LE+size(Isquare,1) y_top_left+size(Isquare,2)],thisTrialData.ImTilt); % https://yun-weidai.com/post/ptb-draw-image/
                        %Screen('DrawDots', this.Graph.window, [fixXPix_LE; fixYPix_LE], fixSizePix, this.targetColor, [], 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);

                        % Draw right stim:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        Screen('DrawTexture', this.Graph.window, this.stimTexture, [],[x_top_left_RE y_top_left x_top_left_RE+size(Isquare,1) y_top_left+size(Isquare,2)],thisTrialData.ImTilt); 
                        %Screen('DrawDots', this.Graph.window, [fixXPix_RE; fixYPix_RE], fixSizePix, this.targetColor, [], 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);

                    % Any other time, just show the fixation dot
                    elseif ( secondsElapsed < initialFixationDuration )
                        % Draw left stim:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 0);
                        Screen('DrawDots', this.Graph.window, [fixXPix_LE; fixYPix_LE], fixSizePix, this.targetColor, [], 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [1 0 0], [], 5);

                        % Draw right stim:
                        Screen('SelectStereoDrawBuffer', this.Graph.window, 1);
                        Screen('DrawDots', this.Graph.window, [fixXPix_RE; fixYPix_RE], fixSizePix, this.targetColor, [], 1); % fixation spot
                        Screen('FrameRect', this.Graph.window, [0 1 0], [], 5);
                    end
                    
                    % Break trial if needed
                    if (secondsElapsed > initialFixationDuration + this.ExperimentOptions.TimeStimOn)
                        break
                    end
                    
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------

                    % FLIP
                    this.Graph.Flip(this, thisTrialData, secondsRemaining);

                    % Break trial when a key is pressed IF the trial is done
                    if secondsElapsed > initialFixationDuration + this.ExperimentOptions.TimeStimOn
                        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                        if ( keyIsDown )
                            break
                        end
                    end
                  
                end

            %trialResult = Enum.trialResult.CORRECT;
                


            catch ex
                rethrow(ex)
            end

        end
        
      
            
             
        
    end

    

    methods
        
        function [out] = Plot_OptoVergence(this)
            %%
            trialDataTable = this.Session.trialDataTable;
            
            % converged Positions
            x_converged = trialDataTable.mean_T(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "converged") % -30 tilt
            y_converged = trialDataTable.mean_T(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "converged")  % 0 tilt
            z_converged = trialDataTable.mean_T(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "converged") % 30 tilt
            
            % Parallel Positions
            x_parallel = trialDataTable.mean_T(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "parallel")
            y_parallel = trialDataTable.mean_T(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "parallel")
            z_parallel = trialDataTable.mean_T(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "parallel")
            
            % boxplots
            group1 = [ones(size(x_converged)); 3 * ones(size(y_converged)); 5 * ones(size(z_converged)); 1.5 * ones(size(x_parallel)); 3.5 * ones(size(y_parallel)); 5.5 * ones(size(z_parallel))]
            figure
            boxplot([x_converged; x_parallel; y_converged; y_parallel; z_converged; z_parallel ], group1, 'Positions', group1, 'Whisker', inf, 'Colors',[0 0 0]); hold on
            plot(ones(size(x_converged)), x_converged,'o','Color',[0 0 1])
            plot(ones(size(y_converged))*3, y_converged,'o','Color',[0 0 1]) %problem with color
            plot(ones(size(z_converged))*5, z_converged,'o','Color',[0 0 1])
            plot(ones(size(x_parallel))*1.5, x_parallel,'o','Color',[1 0 0])
            plot(ones(size(y_parallel))*3.5, y_parallel,'o','Color',[1 0 0]) %problem with color
            plot(ones(size(z_parallel))*5.5, z_parallel,'o','Color',[1 0 0])
            ylim([-2 1.5])
            xlabel('Image Tilt at Eye Vergence')
            ylabel('Optostatic Torsion')
            title('OST during Converged and Distance Viewing')
            set(gca,'XTickLabel',{'Converged -30°','Parallel -30°','Converged 0°','Parallel 0°',' Converged 30°','Parallel 30°'})
            
           %%
           %Left Eye Torsion
            x_leftconverged = trialDataTable.mean_LeftT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "converged")
            y_leftconverged = trialDataTable.mean_LeftT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "converged")
            z_leftconverged = trialDataTable.mean_LeftT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "converged")
            
            % Parallel Positions
            x_leftparallel = trialDataTable.mean_LeftT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "parallel")
            y_leftparallel = trialDataTable.mean_LeftT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "parallel")
            z_leftparallel = trialDataTable.mean_LeftT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "parallel")
            
            %converged boxplots
            group2 = [ones(size(x_leftconverged)); 3 * ones(size(y_leftconverged)); 5 * ones(size(z_leftconverged)); 1.5 * ones(size(x_leftparallel)); 3.5 * ones(size(y_leftparallel)); 5.5 * ones(size(z_leftparallel))]
            figure
            boxplot([x_leftconverged; x_leftparallel; y_leftconverged; y_leftparallel; z_leftconverged; z_leftparallel ], group2, 'Positions', group2, 'Whisker', inf, 'Colors',[0 0 0]); hold on
            plot(ones(size(x_leftconverged)), x_leftconverged,'o','Color',[0 0 1])
            plot(ones(size(y_leftconverged))*3, y_leftconverged,'o','Color',[0 0 1])
            plot(ones(size(z_leftconverged))*5, z_leftconverged,'o','Color',[0 0 1])
            plot(ones(size(x_leftparallel))*1.5, x_leftparallel,'o','Color',[1 0 0])
            plot(ones(size(y_leftparallel))*3.5, y_leftparallel,'o','Color',[1 0 0])
            plot(ones(size(z_leftparallel))*5.5, z_leftparallel,'o','Color',[1 0 0])
            ylim([-2 1.5])
            xlabel('Image Tilt at Eye Vergence')
            ylabel('Optostatic Torsion')
            title('Left Eye OST during Converged and Distance Viewing')
            set(gca,'XTickLabel',{'Converged -30°','Parallel -30°','Converged 0°','Parallel 0°',' Converged 30°','Parallel 30°'})

           
            %%
            %Right Eye Torsion
            x_rightconverged = trialDataTable.mean_RightT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "converged")
            y_rightconverged = trialDataTable.mean_RightT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "converged")
            z_rightconverged = trialDataTable.mean_RightT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "converged")
            
            % Parallel Positions
            x_rightparallel = trialDataTable.mean_RightT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "parallel")
            y_rightparallel = trialDataTable.mean_RightT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "parallel")
            z_rightparallel = trialDataTable.mean_RightT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "parallel")
            
            %converged boxplots
            group2 = [ones(size(x_rightconverged)); 3 * ones(size(y_rightconverged)); 5 * ones(size(z_rightconverged)); 1.5 * ones(size(x_rightparallel)); 3.5 * ones(size(y_rightparallel)); 5.5 * ones(size(z_rightparallel))]
            figure
            boxplot([x_rightconverged; x_rightparallel; y_rightconverged; y_rightparallel; z_rightconverged; z_rightparallel ], group2, 'Positions', group2, 'Whisker', inf, 'Colors',[0 0 0]); hold on
            plot(ones(size(x_rightconverged)), x_rightconverged,'o','Color',[0 0 1])
            plot(ones(size(y_rightconverged))*3, y_rightconverged,'o','Color',[0 0 1])
            plot(ones(size(z_rightconverged))*5, z_rightconverged,'o','Color',[0 0 1])
            plot(ones(size(x_rightparallel))*1.5, x_rightparallel,'o','Color',[1 0 0])
            plot(ones(size(y_rightparallel))*3.5, y_rightparallel,'o','Color',[1 0 0])
            plot(ones(size(z_rightparallel))*5.5, z_rightparallel,'o','Color',[1 0 0])
            ylim([-2 1.5])
            xlabel('Image Tilt at Eye Vergence')
            ylabel('Optostatic Torsion')
            title('Right Eye OST during Converged and Distance Viewing')
            set(gca,'XTickLabel',{'Converged -30°','Parallel -30°','Converged 0°','Parallel 0°',' Converged 30°','Parallel 30°'})
        end


       function [out] = Plot_OptoVergence_BarGraph(this)
            %% 
            
            %converged
            trialDataTable = this.Session.trialDataTable;

            negthirtytilt_mean_converged =  mean(trialDataTable.mean_T(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "converged")) 
            zerotilt_mean_converged = mean(trialDataTable.mean_T(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "converged"))
            posthirtytilt_mean_converged = mean(trialDataTable.mean_T(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "converged"))
            diff_xy_converged = negthirtytilt_mean_converged - zerotilt_mean_converged
            diff_zy_converged = posthirtytilt_mean_converged - zerotilt_mean_converged

            %parallel 
            negthirtytilt_mean_parallel = mean(trialDataTable.mean_T(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "parallel"))
            zerotilt_mean_parallel = mean(trialDataTable.mean_T(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "parallel"))
            posthirtytilt_mean_parallel = mean(trialDataTable.mean_T(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "parallel"))
            diff_xy_parallel =  negthirtytilt_mean_parallel - zerotilt_mean_parallel
            diff_zy_parallel =  posthirtytilt_mean_parallel - zerotilt_mean_parallel

            figure
            subplot(1,2,1)
            b1 = bar(1,diff_xy_converged); hold on
            b2 = bar(2,diff_zy_converged); 
            xticks(1:2)
            xticklabels({'-30','30'})
            ylim([-0.5 0.5])
            xlabel('Image Tilt during Converged Viewing')
            ylabel('Optostatic Torsion')
            legend([b1 b2],'-30° tilt converged','30° tilt converged')
            title('OST during Converged Viewing')
            
            subplot(1,2,2)
            b3 = bar(1,diff_xy_parallel); hold on 
            b4 = bar(2,diff_zy_parallel); 
            ylim([-0.5 0.5])
            xlabel('Image Tilt during Parallel Viewing')
            ylabel('Optostatic Torsion')
            legend([b3 b4],'-30° tilt parallel','30° tilt parallel')
            title('OST during Distance Viewing')
            
            %% bar plot for left eye

            negthirtytilt_leftmean_converged =  mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "converged")) 
            zerotilt_leftmean_converged = mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "converged"))
            posthirtytilt_leftmean_converged = mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "converged"))
            leftdiff_xy_converged = negthirtytilt_leftmean_converged - zerotilt_leftmean_converged
            leftdiff_zy_converged = posthirtytilt_leftmean_converged - zerotilt_leftmean_converged

            %parallel 
            negthirtytilt_leftmean_parallel = mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "parallel"))
            zerotilt_leftmean_parallel = mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "parallel"))
            posthirtytilt_leftmean_parallel = mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "parallel"))
            leftdiff_xy_parallel =  negthirtytilt_leftmean_parallel - zerotilt_leftmean_parallel
            leftdiff_zy_parallel =  posthirtytilt_leftmean_parallel - zerotilt_leftmean_parallel

            figure
            subplot(1,2,1)
            b1 = bar(1,leftdiff_xy_converged); hold on
            b2 = bar(2,leftdiff_zy_converged); 
            xticks(1:2)
            xticklabels({'-30','30'})
            ylim([-0.5 0.5])
            xlabel('Image Tilt during Converged Viewing')
            ylabel('Optostatic Torsion')
            legend([b1 b2],'-30° tilt converged','30° tilt converged')
            title('Left eye OST during Converged Viewing')
            
            subplot(1,2,2)
            b3 = bar(1,leftdiff_xy_parallel); hold on 
            b4 = bar(2,leftdiff_zy_parallel); 
            ylim([-0.5 0.5])
            xlabel('Image Tilt during Parallel Viewing')
            ylabel('Optostatic Torsion')
            legend([b3 b4],'-30° tilt parallel','30° tilt parallel')
            title('Left eye OST during Distance Viewing')
            
            %% bar plot for right eye

            negthirtytilt_rightmean_converged =  mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "converged")) 
            zerotilt_rightmean_converged = mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "converged"))
            posthirtytilt_rightmean_converged = mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "converged"))
            rightdiff_xy_converged = negthirtytilt_rightmean_converged - zerotilt_rightmean_converged
            rightdiff_zy_converged = posthirtytilt_rightmean_converged - zerotilt_rightmean_converged

            %parallel 
            negthirtytilt_rightmean_parallel = mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "parallel"))
            zerotilt_rightmean_parallel = mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "parallel"))
            posthirtytilt_rightmean_parallel = mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "parallel"))
            rightdiff_xy_parallel =  negthirtytilt_rightmean_parallel - zerotilt_rightmean_parallel
            rightdiff_zy_parallel =  posthirtytilt_rightmean_parallel - zerotilt_rightmean_parallel

            figure
            subplot(1,2,1)
            b1 = bar(1,rightdiff_xy_converged); hold on
            b2 = bar(2,rightdiff_zy_converged); 
            xticks(1:2)
            xticklabels({'-30','30'})
            ylim([-0.5 0.5])
            xlabel('Image Tilt during Converged Viewing')
            ylabel('Optostatic Torsion')
            legend([b1 b2],'-30° tilt converged','30° tilt converged')
            title('Right eye OST during Converged Viewing')
            
            subplot(1,2,2)
            b3 = bar(1,rightdiff_xy_parallel); hold on 
            b4 = bar(2,rightdiff_zy_parallel); 
            ylim([-0.5 0.5])
            xlabel('Image Tilt during Parallel Viewing')
            ylabel('Optostatic Torsion')
            legend([b3 b4],'-30° tilt parallel','30° tilt parallel')
            title('Right eye OST during Distance Viewing')
            
            
   
       
            
       end

        function [analysisResults, samplesDataTable, trialDataTable, sessionTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable, sessionTable, options)

  %converged
            %trialDataTable = this.Session.trialDataTable;

            %both eyes converged
            sessionTable.negthirtytilt_mean_converged =  mean(trialDataTable.mean_T(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "converged")) ;
            sessionTable.zerotilt_mean_converged = mean(trialDataTable.mean_T(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "converged"));
            sessionTable.posthirtytilt_mean_converged = mean(trialDataTable.mean_T(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "converged"));

            %both eyes parallel 
            sessionTable.negthirtytilt_mean_parallel = mean(trialDataTable.mean_T(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "parallel"));
            sessionTable.zerotilt_mean_parallel = mean(trialDataTable.mean_T(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "parallel"));
            sessionTable.posthirtytilt_mean_parallel = mean(trialDataTable.mean_T(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "parallel"));

            %left eyes converged
            sessionTable.negthirtytilt_leftmean_converged =  mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "converged")) ;
            sessionTable.zerotilt_leftmean_converged = mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "converged"));
            sessionTable.posthirtytilt_leftmean_converged = mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "converged"));

            %left eye parallel 
            sessionTable.negthirtytilt_leftmean_parallel = mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "parallel"));
            sessionTable.zerotilt_leftmean_parallel = mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "parallel"));
            sessionTable.posthirtytilt_leftmean_parallel = mean(trialDataTable.mean_LeftT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "parallel"));

            %right eyes converged
            sessionTable.negthirtytilt_rightmean_converged =  mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "converged")); 
            sessionTable.zerotilt_rightmean_converged = mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "converged"));
            sessionTable.posthirtytilt_rightmean_converged = mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "converged"));

            %right eye parallel 
            sessionTable.negthirtytilt_rightmean_parallel = mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==-30 & trialDataTable.Vergence== "parallel"));
            sessionTable.zerotilt_rightmean_parallel = mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==0 & trialDataTable.Vergence== "parallel"));
            sessionTable.posthirtytilt_rightmean_parallel = mean(trialDataTable.mean_RightT(trialDataTable.ImTilt ==30 & trialDataTable.Vergence== "parallel"));

           

            
            
            
        end

    end
end