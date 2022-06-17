
%%
try
    
    
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'VisualDebugLevel', 0);
    
    SelectedScreen = 1;
    
    [window, wRect] = Screen('OpenWindow', SelectedScreen, 0, [], [], [], 0, 10);
    
    stop = 0;
    while ~stop
        
        % -----------------------------------------------------------------
        % --- Drawing of stimulus -----------------------------------------
        % -----------------------------------------------------------------
        
        %-- Find the center of the screen
        [mx, my] = RectCenter(wRect);
        
        angle = 0;
        position =  'Up'; %Up or Down
        type = 'Radius'; % Radius or Diameter
        lineLength = 300; % pix
        
        targetColor = [255 0 0];
        fromH = mx;
        fromV = my;
        toH = mx + lineLength*sin(angle/180*pi);
        toV = my - lineLength*cos(angle/180*pi);
        Screen('DrawLine', window, targetColor, fromH, fromV, toH, toV, 4);

        Screen('DrawLine', window, targetColor, mx, 0, mx, wRect(4), 1);
        Screen('DrawLine', window, targetColor, 0, my, wRect(3), my, 1);
        
        fixColor = [255 0 0];
        fixRect = [0 0 10 10];
        fixRect = CenterRectOnPointd( fixRect, mx, my );
        Screen('FillOval', window,  fixColor, fixRect);
        
        Screen('Flip', window);
        % -----------------------------------------------------------------
        % --- END Drawing of stimulus -------------------------------------
        % -----------------------------------------------------------------
        
        %-- Check for keyboard press
        [keyIsDown,secs,keyCode] = KbCheck;
        if keyCode(KbName('esc')) % keyCode(KbName('ESCAPE'))
            stop =1;
        end
    end
    
    Clear();
    graph = [];
catch err
    disp(err.getReport);
end
clear screen