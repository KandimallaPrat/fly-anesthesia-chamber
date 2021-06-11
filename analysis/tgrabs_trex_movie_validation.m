clc; clear variables; close all;

datadir = '/local/anesthesia/data/2021-06-10-19-23-34/';

n_flies = 30;

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
X = NaN(max_frame, n_flies);
Y = NaN(max_frame, n_flies);

for i = 1:n_flies
    cd([datadir, 'tracking/tracking_fly', num2str(i-1)]);
    
    % Frames (per animal)
    frame = readNPY('frame.npy');
    frame = frame + 1;
    
    % Center of mass
%     temp_X_w = readNPY('X#wcentroid.npy');
%     temp_Y_w = readNPY('Y#wcentroid.npy');
    
    % Head
    temp_X = readNPY('X.npy');
    temp_Y = readNPY('Y.npy');
        
    temp_X(temp_X == Inf) = NaN;
    temp_Y(temp_Y == Inf) = NaN;
%     temp_X_w(m) = NaN;
%     temp_Y_w(m) = NaN;
    
    X(frame, i) = temp_X;
    Y(frame, i) = temp_Y;
end

for i = 1:n_flies
    figure(i)
    plot(X(:,i),Y(:,i),'k.'); box off;
    xlim([0 15]);
    ylim([0 8.5]);
end












