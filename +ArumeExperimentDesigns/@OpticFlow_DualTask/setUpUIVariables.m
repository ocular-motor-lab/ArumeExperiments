function exptparams = setUpUIVariables(exptparams)

    % fixation rect stuff
    hfixwidth = 3;
    hfixlen = 40;
    fix1 = [exptparams.wwidth/2-hfixwidth;
        exptparams.wheight/2-hfixlen;
        exptparams.wwidth/2+hfixwidth;
        exptparams.wheight/2+hfixlen];
    fix2 =  [exptparams.wwidth/2-hfixlen;
        exptparams.wheight/2-hfixwidth;
        exptparams.wwidth/2+hfixlen;
        exptparams.wheight/2+hfixwidth];
    exptparams.fixrects = [fix1,fix2];
    
    % initialize the anchor point for the response line
    exptparams.resplinex1 = exptparams.wwidth/2;
    exptparams.respliney1 =exptparams. wheight/2;
    exptparams.linelen = exptparams.wheight/8;
    exptparams.anginc = .01;
    
    % angle ticks
    rulerlineangs = linspace(0,pi,5);
    rulerlinex1 = exptparams.resplinex1+cos(rulerlineangs)*exptparams.linelen*.9;
    rulerlinex2 = exptparams.resplinex1+cos(rulerlineangs)*exptparams.linelen*1;
    rulerliney1 = exptparams.respliney1-sin(rulerlineangs)*exptparams.linelen*.9;
    rulerliney2 = exptparams.respliney1-sin(rulerlineangs)*exptparams.linelen*1;
    exptparams.rulerlinexy = [reshape([rulerlinex1;rulerlinex2],1,[]);...
        reshape([rulerliney1;rulerliney2],1,[])];
    
    % outside semi-circle
    outsidelineangs = linspace(0,pi,100);
    outsidelinex = exptparams.resplinex1+cos(outsidelineangs)*exptparams.linelen;
    outsidelinex = [outsidelinex(1),repelem(outsidelinex(2:end),2),outsidelinex(1)];
    
    outsideliney = exptparams.respliney1-sin(outsidelineangs)*exptparams.linelen;
    outsideliney = [outsideliney(1),repelem(outsideliney(2:end),2),outsideliney(1)];
    
    exptparams.outsidelinexy = [outsidelinex;outsideliney];
    
    % location for degree text box response
    exptparams.texty = exptparams.wheight/2+exptparams.wheight/20;

    % text box response for visual search bounting task
    % exptparams.visualsearchtexty1 = exptparams.wheight/2-exptparams.wheight/20;
    % exptparams.visualsearchtexty2 = exptparams.wheight/2-exptparams.wheight/20;

end