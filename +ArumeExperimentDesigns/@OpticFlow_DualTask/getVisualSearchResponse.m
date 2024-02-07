function [this, thisTrialData, exitedEarly]  = getVisualSearchResponse(this, thisTrialData)

    exitedEarly = false;
    noresp = true;
    startt = GetSecs;
    resp = nan;

    while noresp
    
        % we flip the heading so that the labels are more intuitive
        msg = sprintf( 'Were there any %s?',thisTrialData.SearchTarget);
        DrawFormattedText(this.Graph.window, msg, 'center', 'center', [255,255,255])
        this.Graph.Flip(this, thisTrialData)
    
        % enter accepts the user's response
        [keyIsDown, ~, keyCode, ~] = KbCheck();
        if keyIsDown
            keys = find(keyCode);
            for i=1:length(keys)
                KbName(keys(i));
    
                switch(KbName(keys(i)))
                    case 'y'
                        resp = true;
                        noresp = false;
    
                    case 'n'
                        resp = false;
                        noresp = false;

                    case 'ESCAPE'
                        exitedEarly = true;
                        noresp = false;
                end
            end
        end
    
    end

    thisTrialData.SearchResp = resp;
    thisTrialData.ResponseTime = GetSecs - startt;

    if this.ExperimentOptions.AuditoryFeedback

        if thisTrialData.SearchResp == thisTrialData.TargetPresent
            PsychPortAudio('Start', this.audio.pahandlecorrect, 1, 0, 1);
        else
            PsychPortAudio('Start', this.audio.pahandleincorrect, 1, 0, 1);
        end

    end

end