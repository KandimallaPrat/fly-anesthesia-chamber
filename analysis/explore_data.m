clc; clear variables; close all;

% datadir = '/local/anesthesia/data/2021-06-10-17-18-03/';
datadir = '/local/anesthesia/data/2021-06-10-19-23-34/';

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
smooth_s = smooth(mean(speed,2), 1, 'moving');
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

