function [this,thisTrialData] = eyelink_connect(this,thisTrialData)
% now we prepare for looping over the frames for a single trial
sca
nframesctr = 1;
if this.ExperimentOptions.UseEyeTracker
    [framenumber, eyetrackertime] = this.eyeTracker.RecordEvent( ...
        sprintf('STIMULUS_ONSET [,trial=%d condition=%d]', ...
        thisTrialData.TrialNumber, thisTrialData.Condition) );

    % matches the frame number to the eyetracker time at the start of the trial
    thisTrialData.EyeTrackerFrameNumberStimulusOnset = framenumber;
    thisTrialData.EyeTrackerTimeStimulusOnset = eyetrackertime;
end

currtime = GetSecs;

% keeps track of trial duration 
actualDuration = min(thisTrialData.movieDuration,this.ExperimentOptions.TrialDuration);

% store all gaze contingent data
nrows = ceil(this.Graph.frameRate*actualDuration)*1.5;
gazedata = table;
gazedata.ELtime = nan(nrows,1);
gazedata.PTBtime = nan(nrows,1);
gazedata.LGazeX = nan(nrows,1);
gazedata.LGazeY = nan(nrows,1);
gazedata.RGazeX = nan(nrows,1);
gazedata.RGazeY = nan(nrows,1);

%% I think the chunk at line 37-109 are for gaze-contigent stimuli
while (GetSecs-currtime) < actualDuration

    % Get all gaze data
    gazedata.PTBtime(nframesctr) = this.Graph.Flip(this, thisTrialData);
    gazedata.ELtime(nframesctr) = evt.time;
    gazedata.LGazeX(nframesctr) = evt.gx(1);
    gazedata.RGazeX(nframesctr) = evt.gx(2);
    gazedata.LGazeY(nframesctr) = evt.gy(1);
    gazedata.RGazeY(nframesctr) = evt.gy(2);

    nframesctr = nframesctr+1;

end

% % make sure any stray frame textures are indeed closed 
% Screen('Close')

if this.ExperimentOptions.UseEyeTracker
    [framenumber, eyetrackertime] = this.eyeTracker.RecordEvent( ...
        sprintf('STIMULUS_OFFSET [trial=%d, condition=%d]', ...
        thisTrialData.TrialNumber, thisTrialData.Condition) );

    thisTrialData.EyeTrackerFrameNumberStimulusOffset = framenumber;
    thisTrialData.EyeTrackerTimeStimulusOffset = eyetrackertime;
end

% truncate table to correct sz
gazedata = gazedata(1:nframesctr-1,:);
thisTrialData.gazedatatbl = {gazedata};

% establish how much time there were between frames
thisTrialData.EmpiricalFPS = (nframesctr-2)/sum(diff(gazedata.PTBtime));
