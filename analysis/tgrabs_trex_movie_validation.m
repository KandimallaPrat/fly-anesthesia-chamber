clc; clear variables; close all;

% datadir = '/local/anesthesia/data/2021-06-10-19-23-34/';
datadir = '/local/anesthesia/data/2021-06-10-17-18-03/';

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
X_w = NaN(max_frame, n_flies);
Y_w = NaN(max_frame, n_flies);
VX = NaN(max_frame, n_flies);
VY = NaN(max_frame, n_flies);
for i = 1:n_flies
    cd([datadir, 'tracking/tracking_fly', num2str(i-1)]);
    
    % Frames (per animal)
    frame = readNPY('frame.npy');
    frame = frame + 1;
    
    % Center of mass
    temp_X_w = readNPY('X#wcentroid.npy');
    temp_Y_w = readNPY('Y#wcentroid.npy');
    
    % Head
    temp_X = readNPY('X.npy');
    temp_Y = readNPY('Y.npy');
    
    % Velocity
    temp_VX = readNPY('VX.npy');
    temp_VY = readNPY('VY.npy');
        
    temp_X(temp_X == Inf) = NaN;
    temp_Y(temp_Y == Inf) = NaN;
    temp_X_w(temp_X_w == Inf) = NaN;
    temp_Y_w(temp_Y_w == Inf) = NaN;
    temp_VX(temp_VX == Inf) = NaN;
    temp_VY(temp_VY == Inf) = NaN;
    
    X(frame, i) = temp_X;
    Y(frame, i) = temp_Y;
    
    X_w(frame, i) = temp_X_w;
    Y_w(frame, i) = temp_Y_w;
    
    VX(frame, i) = temp_VX;
    VY(frame, i) = temp_VY;
end

% Convert from cm to pixels (1280 pixels = 15 cm)
pix_per_cm = 1280/15;
X_w = pix_per_cm.*X_w;
Y_w = pix_per_cm.*Y_w;
X = pix_per_cm.*X;
Y = pix_per_cm.*Y;
VX = pix_per_cm.*VX;
VY = pix_per_cm.*VY;

plot(VX(:,4), VY(:,4),'k.')

return

% for i = 1:n_flies
%     figure(i)
%     plot(X_w(:,i),Y_w(:,i),'k.'); box off; hold on;
%     plot(X(:,i),Y(:,i),'r.');
%     xlim([0 1280]);
%     ylim([0 720]);
% end

cd(datadir)
tic
ct = 0;
vr = VideoReader([datadir, 'video-c.mp4']);
vr.CurrentTime = ct;

vw = VideoWriter('tracking_validation_by_well.avi');
vw.Quality = 100;
vw.FrameRate = 60/2;
open(vw);

set(gcf,'units','pixels','Position',[250 250 1280/2 720/2],'color','k')

% Y < 350
% Well 1 1,1: X < 380
% Well 2 1,2: X >= 380 and X <= 780
% Well 3 1,3: X > 780

% Y >= 350
% Well 4 2,1: X < 380
% Well 5 2,2: X >= 380 and X <= 780
% Well 6 2,3: X > 780

% Find Well ID for fly ID (5-6 minutes location)
well_id = zeros(1, n_flies);
well_color = {'b','g','r','c','m','y'};
idx = (5*60*60):(6*60*60);
for i = 1:n_flies
    if nanmedian(Y(idx,i)) < 350 % Well 1,n
        if nanmedian(X(idx,i)) < 380
            well_id(i) = 1;
        elseif nanmedian(X(idx,i)) >= 380 && nanmedian(X(idx,i)) <= 780
            well_id(i) = 2;
        elseif nanmedian(X(idx,i)) > 780
            well_id(i) = 3;
        end
    elseif nanmedian(Y(idx,i)) >= 350 % Well 2,n
        if nanmedian(X(idx,i)) < 380
            well_id(i) = 4;
        elseif nanmedian(X(idx,i)) >= 380 && nanmedian(X(idx,i)) <= 780
            well_id(i) = 5;
        elseif nanmedian(X(idx,i)) > 780
            well_id(i) = 6;
        end
    end
end

% return

for i = 1:354000
    f = readFrame(vr);
    
    if mod(i,2) == 0
        image(f); hold on; box off;
        for j = 1:6
            plot(X_w(60*ct+i,well_id == j),Y_w(60*ct+i,well_id == j),'o','Color',well_color{j});
            plot(X(60*ct+i,well_id == j),Y(60*ct+i,well_id == j),'.','Color',well_color{j});
        end
        set(gca,'XTickLabel',[],'YTickLabel',[],'nextplot','replacechildren', ...
            'Units','pixels','Position', [5/2 5/2 1280/2 720/2])
        
        write_frame = getframe(gcf);
        try
            writeVideo(vw,write_frame);
        catch
            disp(['improper frame ', num2str(i),' (size: ', num2str(size(write_frame.cdata)),')']);
        end
    end
end

close(gcf);
close(vw);
toc






