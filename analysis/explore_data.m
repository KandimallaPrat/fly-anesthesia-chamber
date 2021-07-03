%% Gather flies
clc; clear variables; close all;

datadir = '/local/anesthesia/data/2021-07-02-11-58-46/';

cd(datadir)

% Load info.txt and find number of flies per well
opts = delimitedTextImportOptions("NumVariables", 7);
opts.DataLines = [1, Inf];
opts.Delimiter = ",";
opts.VariableNames = ["start", "VarName2", "VarName3", "VarName4", "VarName5", "VarName6", "VarName7"];
opts.VariableTypes = ["char", "double", "double", "double", "double", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts = setvaropts(opts, "start", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "start", "EmptyFieldRule", "auto");
opts = setvaropts(opts, ["VarName3", "VarName4", "VarName5", "VarName6", "VarName7"], "TrimNonNumeric", true);
opts = setvaropts(opts, ["VarName3", "VarName4", "VarName5", "VarName6", "VarName7"], "ThousandsSeparator", ",");
info = readtable("info.txt", opts);
info = table2cell(info);
numIdx = cellfun(@(x) ~isnan(str2double(x)), info);
info(numIdx) = cellfun(@(x) {str2double(x)}, info(numIdx));
clear opts

for i = 1:size(info,1)
    if strcmp(info{i,1}, 'n-flies')
        n_flies = vertcat(info{i,2:end})';
    end
end

n_flies

% Motor on times only
t = readNPY('timestamps.npy');
t = t - t(1);
ms = readNPY('motor-status.npy');
ms = readNPY('motor-status.npy');
t(ms == 0) = NaN;
ms(ms == 0) = NaN;

% Get max number of frames
for i = 1:length(n_flies)
    for j = 1:n_flies(i)
        cd([datadir, 'tracking-well-', num2str(i),'/tracking-well-', num2str(i),'_fly', num2str(j-1)]);

        frame = readNPY('frame.npy'); % zero-index
        frame = frame + 1;

        if i == 1
            max_frame = max(frame);
        elseif max(frame) > max_frame
            max_frame = max(frame);
        end
    end
end

% Populate time vector
frames = (1:max_frame)';
tt = NaN(max_frame, 1);
speed = zeros(max_frame, sum(n_flies));
idx_fly = 1;
for i = 1:length(n_flies)
    for j = 1:n_flies(i)
        cd([datadir, 'tracking-well-', num2str(i),'/tracking-well-', num2str(i),'_fly', num2str(j-1)]);

        frame = readNPY('frame.npy'); % zero-index
        frame = frame + 1;

        temp_t = readNPY('time.npy');
        tt(frame) = temp_t;

        sswc = readNPY('SPEED#wcentroid.npy');
        sswc(sswc == Inf) = 0;
        speed(frame, idx_fly) = speed(frame, idx_fly) + sswc;
        
        idx_fly = idx_fly + 1;
    end
end

for i = 1:length(n_flies)
    n_flies(i)
end

return

cd(datadir)
figure(1);
smooth_s = smooth(median(speed,2), 1, 'moving');
box off; hold on;
y_max = max(smooth_s(tt > 60));
h1 = plot(t, ms.*y_max, 'ro', 'linewidth',2);
h2 = plot(tt(tt > 60), smooth_s(tt > 60),'k','linewidth',1);
xlim([tt(1) tt(end)]);
ylim([0 y_max]);
xlabel('time (seconds)');
ylabel('mean velocity (cm/s)');
title('fly session');



%%
clc; clear variables; close all;

% datadir = '/local/anesthesia/data/2021-06-10-17-18-03/';
datadir = '/local/anesthesia/data/2021-06-10-17-18-03/';

n_flies = 30;

cd(datadir);
t = readNPY('timestamps.npy');
t = t - t(1);
ms = readNPY('motor-status.npy');
t(ms == 0) = NaN;
ms(ms == 0) = NaN;

% Get max frame number
for i = 1:n_flies
    cd([datadir, 'tracking/tracking_fly', num2str(i-1)]);
    
    frame = readNPY('frame.npy'); % zero-index
    frame = frame + 1;
    
    if i == 1
        max_frame = max(frame);
    elseif max(frame) > max_frame
        max_frame = max(frame);
    end
end

% Populate time vector
frames = (1:max_frame)';
tt = NaN(max_frame, 1);
speed = zeros(max_frame, 1);
for i = 1:n_flies
    cd([datadir, 'tracking/tracking_fly', num2str(i-1)]);
    
    frame = readNPY('frame.npy'); % zero-index
    frame = frame + 1;
    
    temp_t = readNPY('time.npy');
    tt(frame) = temp_t;
    
    sswc = readNPY('SPEED#wcentroid.npy');
    sswc(sswc == Inf) = 0;
    speed(frame) = speed(frame) + sswc;
end

cd(datadir)
figure(1);
smooth_s = smooth(mean(speed,2), 600, 'moving');
box off; hold on;
h1 = plot(t, ms.*(max(smooth_s)+1), 'r', 'linewidth',2);
h2 = plot(tt, smooth_s,'k','linewidth',1);
h3 = legend([h1,h2],'motors on (n = 6)','smoothed velocity (600s)','Location','southeast');
set(h3,'box','off');
xlim([tt(1) tt(end)]);
ylim([0 max(smooth_s) + 2]);
xlabel('time (seconds)');
ylabel('mean velocity (mm/s)');
title('fly session, (n = 30)');

