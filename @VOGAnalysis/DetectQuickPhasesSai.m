function [data, info] = DetectQuickPhasesSai(data, params)

info = [];

if ( ischar(data) )
    command = data;
    switch( command)
        case 'get_options'
            optionsDlg = [];
            
            optionsDlg.Components = {{'H','{HV}','HVT'}};
            optionsDlg.lmbda = 5;               % Engbert and Kliegl parameter
            optionsDlg.F = 2;                   % Factor for Microsaccade Rate
            optionsDlg.MinSacIntDuration = 0.03;% 30ms of min Sac Interval
            optionsDlg.windw = 0.3;             % Window of 300ms for detecting start and end of saccades  -----> parameter to change for ROC
            optionsDlg.n = 1;                   % Number of seconds to search in for the microsacs according to obtained rate, R2
            optionsDlg.nwindw = 0.005;          % Window of 5ms for removing garbage/ noisy part of signal  -----> parameter to change for ROC
            
            data = optionsDlg;
            return;
        case 'get_defaults'
            optionsDlg = VOGAnalysis.DetectQuickPhasesSai('get_options');
            defaultOptions = StructDlg(optionsDlg,'',[],[],'off');
            data = defaultOptions;
            return;
    end
end

if ( ~exist('params','var') )
    params = VOGAnalysis.DetectQuickPhasesSai('get_defaults');
end

params.Fs = data.Properties.UserData.sampleRate;

eyes = data.Properties.UserData.Eyes;
eyesignals = {'X','Y'};

% Head Velocity Correction

HeadVelThresh = 10; % Threshold of Head vel
padding = 0.1; % 100 ms

hinds = find(data.HeadVel>=HeadVelThresh);
T = data.Properties.UserData.sampleRate;
for k = 1:numel(eyes)
    for p = 1:numel(eyesignals)
        for q = 1:numel(hinds)
            data.([eyes{k} eyesignals{p}])(max(1,hinds(q)-T*padding): min(height(data),hinds(q)+T*padding),1) = nan;
        end
    end
end

temp = table();
for j = 1:numel(eyes)
       
    for k = 1:numel(eyesignals)
        data.(['QuickPhase' eyesignals{k}])  = false(size(data.([eyes{j} eyesignals{k}])));
        data.(['RemoveData' eyesignals{k}])  = false(size(data.([eyes{j} eyesignals{k}])));
        
        temp.(eyesignals{k}) = data.([eyes{j} eyesignals{k}]);  
        temp.(eyesignals{k}) = sgolayfilt( temp.(eyesignals{k}), 2, 11);
        temp.(['v' eyesignals{k}]) =  smooth_vel(temp.(eyesignals{k}),params.Fs);
        
        % Small periods of good data are shortened after smoothing; hence
        % removing them
        nans = zeros(height(temp),1);
        nans(isnan(temp.(['v' eyesignals{k}]))) = 1;
        nans = imclose(nans,ones(10));        
        temp.(['v' eyesignals{k}])(nans==1) = nan;
        
        data.(eyesignals{k}) = temp.(eyesignals{k});
        data.(['v' eyesignals{k}]) =  temp.(['v' eyesignals{k}]);
        
        temp.(['acc' eyesignals{k}]) =  [0;diff(temp.(['v' eyesignals{k}])).*params.Fs];
        temp.(['sac_inds' eyesignals{k} ]) = false(size(data.([eyes{j} eyesignals{k}])));
        
        peaks.(eyes{j}).(eyesignals{k}) = table();
        peaks.(eyes{j}).(eyesignals{k}) = detect_Peaks(temp,eyesignals{k},params);
    end
    
    if height(peaks.(eyes{j}).(eyesignals{k}))<8
        continue;
    end
    
    allPeaks = peaks;
    [peaks.(eyes{j}),xtra] = select_Peaks(peaks.(eyes{j}),temp,params);
    peaks.(eyes{j}) = detect_Period(peaks.(eyes{j}),temp,params);
    peaks.(eyes{j}) = recalibrate_Period(peaks.(eyes{j}),temp,params);
    
    for k = 1:numel(eyesignals)
        
        if height(peaks.(eyes{j}).(eyesignals{k}))<8
            continue;
        end
        
        
        for i = 1:height(peaks.(eyes{j}).(eyesignals{k}))
            temp.(['sac_inds' eyesignals{k}])(peaks.(eyes{j}).(eyesignals{k}).start(i): peaks.(eyes{j}).(eyesignals{k}).stop(i)) = 1;
        end
        
        peaks.(eyes{j}) = feature_Extraction(peaks.(eyes{j}),temp,params,eyesignals(k));
        
        features = table();
        features.promCalc = peaks.(eyes{j}).(eyesignals{k}).promCalc;
        features.meddiff_vel= log(abs(peaks.(eyes{j}).(eyesignals{k}).meddiff_vel));
        features.stddiff_acc= log(abs(peaks.(eyes{j}).(eyesignals{k}).stddiff_acc));
        features.wv = log(abs(peaks.(eyes{j}).(eyesignals{k}).wv));
        features = table2array(features);
        n_clusters  = 2;
        % cluster.features = [normalize(abs(features), 0,1)];
        clusters.features       = features;
        clusters.distance_type  = 'cosine';
        clusters.dm = squareform(pdist(clusters.features,clusters.distance_type));
        %     clusters.dm             = squareform(1-abs(pdist(clusters.features, clusters.distance_type)-1));
        
        % CHANGED SAMPLERATE IN CHOOSE_DC FUNCTION TO 500HZ INSTEAD OF 1000HZ
        [clusters.dc, clusters.kd_sorted] = choose_dc(clusters.dm, round(xtra.(['R2' eyesignals{k}])) ,params.Fs);
        fprintf('  Dc = %f\n', clusters.dc)
        
        % clustering
        clusters.rho        = get_rho(clusters.dc, clusters.dm,'gaussian'); % can be 'gaussian' or step
        clusters.delta      = get_delta(clusters.rho, clusters.dm);
        clusters.gamma      = get_gamma(clusters.rho.rho, clusters.delta.delta);
        [clusters.labels, clusters.centers, clusters.cindex] = get_clusters(n_clusters, clusters.features, clusters.rho, clusters.delta, clusters.gamma);
        
        % determine noise
        clusters = separate_noise(clusters);                                % determine noise points (they have label 0)
        
        % Separating the wanted cluster
        peaks.(eyes{j}).(eyesignals{k}).labels = clusters.labels;
        if sum(abs(peaks.(eyes{j}).(eyesignals{k}).promCalc(peaks.(eyes{j}).(eyesignals{k}).labels==2))>=xtra.(['r' eyesignals{k}])) > ...
                sum(abs(peaks.(eyes{j}).(eyesignals{k}).promCalc(peaks.(eyes{j}).(eyesignals{k}).labels==1))>=xtra.(['r' eyesignals{k}]))
            peaks.(eyes{j}).(eyesignals{k}).labels(peaks.(eyes{j}).(eyesignals{k}).labels~=2)= 0;
        else
            peaks.(eyes{j}).(eyesignals{k}).labels(peaks.(eyes{j}).(eyesignals{k}).labels==2)= 0;
        end
        
        for i = 1:height(peaks.(eyes{j}).(eyesignals{k}))
            if peaks.(eyes{j}).(eyesignals{k}).labels(i)~=0
                data.(['QuickPhase' eyesignals{k}])(peaks.(eyes{j}).(eyesignals{k}).start(i):peaks.(eyes{j}).(eyesignals{k}).stop(i)) = true;
            elseif peaks.(eyes{j}).(eyesignals{k}).labels(i)==0 && peaks.(eyes{j}).(eyesignals{k}).prom(i)>=xtra.(['r' eyesignals{k}])
                data.(['RemoveData' eyesignals{k}])(peaks.(eyes{j}).(eyesignals{k}).start(i):peaks.(eyes{j}).(eyesignals{k}).stop(i)) = true;
            end
        end
        
        % Removing Baddata
        [~,inds] = setdiff(allPeaks.(eyes{j}).(eyesignals{k}).loc, peaks.(eyes{j}).(eyesignals{k}).loc);
        allPeaks.(eyes{j}).(eyesignals{k}) = allPeaks.(eyes{j}).(eyesignals{k})(inds,:);
        inds = find(allPeaks.(eyes{j}).(eyesignals{k}).prom>=xtra.(['r' eyesignals{k}]));
        for i = 1:numel(inds)
            data.(['RemoveData' eyesignals{k}])(allPeaks.(eyes{j}).(eyesignals{k}).border_start(inds(i)):allPeaks.(eyes{j}).(eyesignals{k}).border_stop(inds(i))) = true;
        end
        
        v = [0;diff(temp.(eyesignals{k})).*params.Fs];
        
        inds = find(abs(v)>=xtra.(['r' eyesignals{k}]));
        for i = 1:numel(inds)
            data.(['RemoveData' eyesignals{k}])(inds(i):inds(i)) = true;
        end
        
        v(data.(['RemoveData' eyesignals{k}])==1) = nan;
        v(data.(['QuickPhase' eyesignals{k}])==1) = nan;
        
        [~,loc,~,~] = findpeaks( abs(v)+1,'Annotate','extents','WidthReference','halfheight');
        findpeaks( abs(v)+1,'Annotate','extents','WidthReference','halfheight');
        Ax = gca; Kids = Ax.Children;
        starts = (unique(Kids(2).XData(~isnan(Kids(2).XData))))';
        stops = (unique(Kids(1).XData(~isnan(Kids(1).XData))))'; close
        chk = [ v(loc)-v(starts), v(loc)-v(stops) ];
        [~,inds] = nanmax(abs(chk),[],2); prom = [];
        for i = 1:length(inds)
            prom(i) = chk(i,inds(i))' ;
        end
        inds = find(prom>=xtra.(['r' eyesignals{k}]));
        for i = 1:numel(inds)
            data.(['RemoveData' eyesignals{k}])(starts(inds(i)):stops(inds(i))) = true;
        end
        
    end
    peaks.(eyes{j}).xtra = xtra;
    
end
info = peaks;
end

function v = smooth_vel(x,Fs)
% Another kind of velocity calculation
N = length(x(:,1));
v = zeros(N,1);
v(3:N-2,:)	= Fs/6 * [x(5:end,:) + x(4:end-1,:) - x(2:end-3,:) - x(1:end-4,:)];
v(2,:)		= Fs/2 * [x(3,:) - x(1,:)];
v(N-1,:)	= Fs/2 * [x(end,:) - x(end-2,:)];
v(9:end-8,:)	= Fs/24 * [x(17:end,:) + x(13:end-4,:) - x(5:end-12,:) - x(1:end-16,:)];
end