%%
load('C:\Users\jorge\Downloads\ArumeSession.mat');
d = sessionData.currentRun.pastTrialTable(:,{'Image','Angle','Response'});
d(ismissing(d.Response),:)=[];
figure
subplot(1,2,1);
ArumeExperimentDesigns.SVV2AFC.PlotSigmoid(d.Angle(d.Image=='Left'), d.Response(d.Image=='Left'));
xlabel('Angle (deg)');
ylabel('Percent response right');
title('Left tilt');
subplot(1,2,2);
ArumeExperimentDesigns.SVV2AFC.PlotSigmoid(d.Angle(d.Image=='Right'), d.Response(d.Image=='Right'));
xlabel('Angle (deg)');
ylabel('Percent response right');
title('Right tilt');