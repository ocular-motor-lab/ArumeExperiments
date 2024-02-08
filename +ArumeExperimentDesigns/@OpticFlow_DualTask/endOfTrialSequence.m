function exitedEarly = endOfTrialSequence(this,thisTrialData)

    exitedEarly = false;

    % just exit if end of experiment
    if thisTrialData.Trial ~= this.ExperimentOptions.nTrialsTotal
        
        % end of block = break
        if thisTrialData.BlockChange

            pcomplete = thisTrialData.BlockNumber/this.ExperimentOptions.numberblocks;
            msg = sprintf('Completed: %i%%\nTake a break, then press any key to continue...', round(pcomplete*100));

            noresp = true;

            while noresp

                DrawFormattedText(this.Graph.window,msg,'center','center',[255,255,255])
                this.Graph.Flip(this, thisTrialData);

                % enter accepts the user's response
                [keyIsDown, ~, keyCode, ~] = KbCheck();
                if keyIsDown
                    keys = find(keyCode);
                    for i=1:length(keys)
                        KbName(keys(i));
            
                        switch(KbName(keys(i)))
                            case 'ESCAPE'
                                exitedEarly = true;
                                noresp = false;
                            otherwise 
                                % just start next block
                                noresp = false;
                        end
                    end
                end
            end
        end
    end
end