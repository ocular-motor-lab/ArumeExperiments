%%
try
    exp = ArumeCore.ExperimentDesign();
    opt = exp.GetDefaultExperimentOptions('ExperimentDesign');
    exp.init('TEST',opt);
    
    
    graph = ArumeCore.Display( );
    graph.Init( exp );
    
    stop = 0;
    while ~stop
        
            % -----------------------------------------------------------------
            % --- Drawing of stimulus -----------------------------------------
            % -----------------------------------------------------------------
            
            %-- Find the center of the screen
            [mx, my] = RectCenter(graph.wRect);
            
            angle = 0;
            position =  'Up'; %Up or Down
            type = 'Radius'; % Radius or Diameter
            lineLength = 300; % pix
            
            targetColor = [255 0 0];
            fromH = mx;
            fromV = my;
            toH = mx + lineLength*sin(angle/180*pi);
            toV = my - lineLength*cos(angle/180*pi);
            Screen('DrawLine', graph.window, targetColor, fromH, fromV, toH, toV, 4);
            
            fixColor = [255 0 0];
            fixRect = [0 0 10 10];
            fixRect = CenterRectOnPointd( fixRect, mx, my );
            Screen('FillOval', graph.window,  fixColor, fixRect);
            
            Screen('Flip', graph.window);
            % -----------------------------------------------------------------
            % --- END Drawing of stimulus -------------------------------------
            % -----------------------------------------------------------------
            
            %-- Check for keyboard press
            [keyIsDown,secs,keyCode] = KbCheck;
            if keyCode(KbName('ESCAPE'))
                stop =1;
            end
    end
    
    graph.Clear();
    graph = [];
catch err
     disp(err.getReport);
end
clear screen