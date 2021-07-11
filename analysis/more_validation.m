clc; clear variables; close all;
% Translational velocity (+) in forward direction, (-) if fly walks
% backwards
% X.npy and Y.npy : head-coordinate, not precise enough for use
% X#wcentroid.npy : center-of-mass coordinate
% time.npy : time in seconds
% timestamp.npy : time in microseconds
% missing.npy : frames when the fly was "missing" probably too close to
% another fly
% frame.npy : videoframe the fly metrics correspond to, bugged, not
% consistent across flies

datadir = '/local/anesthesia/data/';

well_speed = [];

for q = 6
    switch q
        case 1
            sessiondir = '2021-07-02-17-32-54'; % No GA
            trex_conversion_number = 5;
            
            % magic centroid x,y coordinates
            center = [540 300; 285 300; 210 300; 530 240; 270 260; 200 250];
        case 2
            sessiondir = '2021-07-03-12-22-39'; % 7.0%
            trex_conversion_number = 5;
            center = [540 300; 285 300; 210 300; 530 240; 270 260; 200 250];
        case 3
            sessiondir = '2021-07-03-14-18-36'; % 4.0%
            trex_conversion_number = 5;
            center = [540 300; 285 300; 210 300; 530 240; 270 260; 200 250];
        case 4
            sessiondir = '2021-07-03-16-15-54'; % 1.0%
            trex_conversion_number = 5;
            center = [540 300; 285 300; 210 300; 530 240; 270 260; 200 250];
        case 5
            sessiondir = '2021-07-09-15-41-47'; % Motor test 1
            trex_conversion_number = 3.3697;
            center = [180 180; 180 180; 180 180; 180 180; 180 180; 180 180];
        case 6
            sessiondir = '2021-07-10-14-29-28'; % Sevoflurane 0% in air
            trex_conversion_number = 3.3697;
            center = [180 180; 180 180; 180 180; 180 180; 180 180; 180 180];
        case 7
            sessiondir = '2021-07-07-12-39-58'; % Sevoflurane 0% in O2%
            trex_conversion_number = 3.3697;
            center = [180 180; 180 180; 180 180; 180 180; 180 180; 180 180];
        case 8
            sessiondir = '2021-07-08-10-56-08'; % Sevoflurane 2.0% in O2%
            trex_conversion_number = 3.3697;
            center = [180 180; 180 180; 180 180; 180 180; 180 180; 180 180];
        case 9
            sessiondir = '2021-07-08-12-23-52'; % Sevoflurane 5.0% in O2%
            trex_conversion_number = 3.3697;
            center = [180 180; 180 180; 180 180; 180 180; 180 180; 180 180];
        case 10
            sessiondir = '2021-07-08-13-58-04'; % Sevoflurane 6.0% in O2%
            trex_conversion_number = 3.3697;
            center = [180 180; 180 180; 180 180; 180 180; 180 180; 180 180];
        case 11
            sessiondir = '2021-07-07-14-54-04'; % Sevoflurane 7.0% in O2%
            trex_conversion_number = 3.3697;
            center = [180 180; 180 180; 180 180; 180 180; 180 180; 180 180];
        case 12
            sessiondir = '2021-07-08-16-04-45'; % Sevoflurane 8.0% in O2%
            trex_conversion_number = 3.3697;
            center = [180 180; 180 180; 180 180; 180 180; 180 180; 180 180];
    end
    
    disp(['session: ', sessiondir])
    cd([datadir, sessiondir]);

    % -------------------------------------------------------------------------
    % Import fly and well numbers, find indexes
    % -------------------------------------------------------------------------
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
    info = readtable('info.txt', opts);
    info = table2cell(info);
    numIdx = cellfun(@(x) ~isnan(str2double(x)), info);
    info(numIdx) = cellfun(@(x) {str2double(x)}, info(numIdx));
    clear opts

    for i = 1:size(info,1)
        if strcmp(info{i,1}, 'n-flies')
            n_flies = vertcat(info{i,2:end})';
        end
    end

    n_wells = length(n_flies);
    cs = cumsum(n_flies);
    idx_well = [1 cs(1)];
    for i = 1:length(cs)-1
         idx_well = [idx_well; cs(i)+1 cs(i+1)];
    end

    % For when fly metrics are placed into a matrix
    idx_well_fly = zeros(1, sum(n_flies));
    for i = 1:size(idx_well,1)
        idx_well_fly(idx_well(i,1):idx_well(i,2)) = i;
    end

    disp(['total flies: ', num2str(sum(n_flies))])
    disp(['wells: ', num2str(n_wells)])
    disp(['well occupancy: ', num2str(n_flies)])

    % -------------------------------------------------------------------------
    % Important session metrics
    % -------------------------------------------------------------------------
    dose = readNPY('dose.npy');
    exp_dose = round(prctile(dose, 99));
    disp(['experimental dose: ', num2str(exp_dose), '%']);

    o2 = readNPY('oxygen.npy');

    motor = readNPY('motor-status.npy');
    t = readNPY('timestamps.npy'); % seconds
    t = t - t(1);

    % session times: baseline, GA, recovery
    i0 = find(dose > 0.8);

    if isempty(i0)
        st = [0 t(end); NaN NaN; NaN NaN];
    else
        i1 = i0(end);
        i0 = i0(1);

        st = [0 t(i0);
            t(i0) t(i1);
            t(i1) t(end)];
    end

    i0 = find(motor==1);
    if isempty(i0)
        mt = [NaN NaN];
    else
        mt = [t(i0(1)) t(i0(end))]; % TODO: this assumes only one motor activation per session
    end

    disp(['session duration: ', num2str(t(end)), ' (n = ', num2str(size(t,1)),' samples)']);
    disp(' ');

    % -------------------------------------------------------------------------
    % Important video metrics
    % -------------------------------------------------------------------------
    % Get video widths for reconversion from incorrect cm to pixels
    well_pixel_dims = [];
    for w = 1:n_wells
        vr = VideoReader(['video-c-well-', num2str(w),'.mp4']);
        frame_rate = vr.FrameRate; % assume all videos are the same framerate
        well_pixel_dims = [well_pixel_dims; [vr.Width vr.Height]];
    end

    % -------------------------------------------------------------------------
    % Important fly measures
    % -------------------------------------------------------------------------
    % Determine the max number of timestamps
    max_ts = [];
    for w = 1:n_wells
        for f = 0:(n_flies(w)-1)
            cd([datadir, sessiondir, '/tracking-well-', num2str(w), '/tracking-well-', num2str(w),'_fly', num2str(f)]);
            tt = readNPY('time.npy');
            max_ts = [max_ts; max(size(tt,1))];
        end
    end

    unique_ts = unique(max_ts);

    if length(unique_ts) > 1
        disp('flies differ in number of individual timestamps');
        for i = 1:length(unique_ts)
            disp([num2str(unique_ts(i)), ' (n=', num2str(sum(max_ts == unique_ts(i))),')'])
        end
    else
        disp('number of individual timestamps');
        disp([num2str(unique_ts), ' (n=', num2str(sum(max_ts == unique_ts)),')'])
    end

    % Get the longest timestamp and use it as a reference
    for w = 1:n_wells
        for f = 0:(n_flies(w)-1)
            cd([datadir, sessiondir, '/tracking-well-', num2str(w), '/tracking-well-', num2str(w),'_fly', num2str(f)]);
            tt = readNPY('time.npy');
            if length(tt) == max(max_ts) % this assumes the longest ts are consistent across flies
                ref_ts = tt;
            end
        end
    end
    disp(' ');

    % -------------------------------------------------------------------------
    % Outlier and teleportation detection
    % -------------------------------------------------------------------------
    outlier_th = 300; % values that exceed twice the ~radius (150 pixels) 
    tp_th = 30; % exceeds 10 pixels of movement in 1 frame (about 90 mm/s)

    % matrix to hold proccessed coordinates
    x_fly = NaN(size(ref_ts,1), sum(n_flies));
    y_fly = NaN(size(ref_ts,1), sum(n_flies));

    x_fly_outliers = NaN(size(ref_ts,1), sum(n_flies));
    y_fly_outliers = NaN(size(ref_ts,1), sum(n_flies));
    
    speed_fly = NaN(size(ref_ts,1), sum(n_flies));

    n = 1;
    artifacts = [];
    disp('% of tracking estimated to be not available/incorrect');
    for w = 1:n_wells
        for f = 0:(n_flies(w)-1)
            cd([datadir, sessiondir, '/tracking-well-', num2str(w), '/tracking-well-', num2str(w),'_fly', num2str(f)]);

            % load in x,y coordinates
            x = readNPY('X#wcentroid.npy');
            y = readNPY('Y#wcentroid.npy');

            % load in timestamps
            tt = readNPY('time.npy');

            % compare to reference ts
            [~, idx] = intersect(ref_ts, tt);

            % replace missing inf values with nan
            missing = readNPY('missing.npy'); % could use this...
            x(x == Inf) = NaN;
            y(y == Inf) = NaN;

            % convert x,y from (incorrect) cm to pixels
            % magic number 5 is the value fed to trex (well ~300 pixels diameter)
            x = x.*(well_pixel_dims(w,1)/trex_conversion_number);
            y = y.*(well_pixel_dims(w,1)/trex_conversion_number); 
            
            % determine x,y coords that fall outside well
    %         center = [nanmedian(x), nanmedian(y)]; % somewhere near the center of the wel
            d = sqrt(nansum(([x y] - center(w,:)).^2, 2));
%             disp(['well ',num2str(w),', fly ',num2str(f),': ', num2str(round(100*(sum(d > outlier_th)/length(d)),1))])

    %         figure(n)
    %         plot(x,y,'k'); box off; hold on;
    %         plot(x(d > outlier_th), y(d > outlier_th), 'r'); % values that exceed twice the ~radius
    %         plot(center(w,1), center(w,2), 'go');

            % Add processed x,y coordinates to matrix, align with correct ts
            x_fly_outliers(idx, n) = x;
            y_fly_outliers(idx, n) = y;

            % remove outliers (out of well)
            x(d > outlier_th) = NaN;
            y(d > outlier_th) = NaN;
            
            % remove potential "teleportations"
            diff_x = [NaN; diff(x)];
            diff_y = [NaN; diff(y)];
            
            idx_tp = (diff_x >= tp_th | diff_y >= tp_th | diff_x <= -tp_th | diff_y <= -tp_th);
            x(idx_tp) = NaN;
            y(idx_tp) = NaN;
            
            % Add processed x,y coordinates to matrix, align with correct ts
            x_fly(idx, n) = x;
            y_fly(idx, n) = y;
            
            % Calculate translational speed (not velocity)
            speed = [NaN; sqrt(diff(x).^2 + diff(y).^2)];
            speed_fly(idx, n) = speed;
            
            artifacts = [artifacts; 
                [100*(nansum(missing)/length(x)), ... % occlusion
                100*(sum(d > outlier_th)/length(x)), ... % out-of-well
                100*(sum(idx_tp)/length(x)), ... % teleporation
                100*(sum(isnan(x))/length(x))]]; % total
            
            disp(['well ',num2str(w),', fly ',num2str(f)])
            disp(['    occlusion: ', num2str(100*(nansum(missing)/length(x)))]);
            disp(['    out-of-well: ', num2str(100*(sum(d > outlier_th)/length(x)))]);
            disp(['    teleportation: ', num2str(100*(sum(idx_tp)/length(x)))]);
            disp(['    total: ', num2str(100*(sum(isnan(x))/length(x)))]);

            n = n + 1;
        end
    end
    disp(' ');
    
    % Flies to ignore for figures
    idx_bad = (sum(artifacts(:,2:3),2) > 1)';
    
%     % -------------------------------------------------------------------------
%     % Video
%     % -------------------------------------------------------------------------
%     cd([datadir, sessiondir]);
%     for w = 1:n_wells
%         if ~isfile(['tracking-video-c-well-', num2str(w),'.avi'])
%             vr = VideoReader(['video-c-well-', num2str(w),'.mp4']);
%             disp(['tracking video-c-well-', num2str(w),'.mp4'])
%             num_frames = floor(vr.Duration*vr.FrameRate);
% 
%             if num_frames ~= length(ref_ts)
%                 error(['error: num_frames: ', num2str(num_frames),', but ref_ts: ', num2str(length(ref_ts))]);
%             end
% 
%             vw = VideoWriter(['tracking-video-c-well-', num2str(w),'.avi']);
%             vw.Quality = 100;
%             vw.FrameRate = frame_rate;
%             open(vw);
% 
%             ds = 30; % downsample rate
%             frame_counter = 0;
%             pad = 10;
%             set(figure(1), 'Position',  [1000, 500, vr.width+pad, vr.height+pad])
%             for i = 1:ds:num_frames
%                 f = read(vr, i);
% 
%                 image(f); hold on; box off;
%                 plot(x_fly_outliers(i, idx_well(w,1):idx_well(w,2)), y_fly_outliers(i, idx_well(w,1):idx_well(w,2)),'ro');
% 
%                 if ref_ts(i) < st(1,2)
%                     text(vr.width/2, 50, 'Baseline', 'Color', 'w')
%                 elseif ref_ts(i) >= st(2,1) && ref_ts(i) <= st(2,2)
%                     text(vr.width/2, 50, ['Sevoflurane ', num2str(exp_dose),'%'], 'Color', 'w')
%                 elseif ref_ts(i) > st(3,1)
%                     text(vr.width/2, 50, 'Recovery', 'Color', 'w')
%                 end
% 
%                 if ref_ts(i) >= mt(1) && ref_ts(i) <= mt(2)
%                     text(vr.width/2, 75, 'Motor On', 'Color', 'r')
%                 end
% 
%                 set(gca,'XTickLabel',[],'YTickLabel',[],'nextplot','replacechildren', ...
%                 'Units','pixels','Position', [5 5 vr.width vr.height]);
% 
%                 write_frame = getframe(gcf);
% 
%                 % Error checking
%                 if size(write_frame.cdata, 1) > (vr.height+pad)
%     %                 disp(['trimming ', num2str(size(write_frame.cdata, 1) - (vr.height+pad)),' px from height']);
%                     write_frame.cdata = write_frame.cdata(1:(vr.height+pad), :, :);
%                 end
% 
%                 if size(write_frame.cdata, 2) > (vr.width+pad)
%     %                 disp(['trimming ', num2str(size(write_frame.cdata, 2) - (vr.width+pad)),' px from width']);
%                     write_frame.cdata = write_frame.cdata(:, 1:(vr.width+pad), :);
%                 end
% 
%                 if size(write_frame.cdata, 1) < (vr.height+pad)
%     %                 disp(['adding ', num2str(size(write_frame.cdata, 1) - (vr.height+pad)),' px from height']);
%                     temp = zeros(vr.height+pad, vr.width+pad, 3);
%                     temp(1:size(write_frame.cdata,1), 1:size(write_frame.cdata,2), :) = write_frame.cdata;
%                     write_frame.cdata = uint8(temp);
%                 end
% 
%                 if size(write_frame.cdata, 2) < (vr.width+pad)
%     %                 disp(['adding ', num2str(size(write_frame.cdata, 2) - (vr.width+pad)),' px from width']);
%                     temp = zeros(vr.height+pad, vr.width+pad, 3);
%                     temp(1:size(write_frame.cdata,1), 1:size(write_frame.cdata,2), :) = write_frame.cdata;
%                     write_frame.cdata = uint8(temp);
%                 end
% 
%                 try
%                     writeVideo(vw, write_frame);
%                 catch
%                     disp(['improper frame ', num2str(i),' (size: ', num2str(size(write_frame.cdata)),')']);
%                     keyboard
%                 end
% 
%                 frame_counter = frame_counter + ds;
% 
%                 if frame_counter > (5*60*frame_rate) % every 5 minutes worth of frames
%                     disp(['processed ', num2str(100*(i/num_frames)), '%'])
%                     frame_counter = 0;
%                 end
%             end
%             close(gcf);
%             close(vw);
%             disp(' ');
%         end
%     end
    
  	% -------------------------------------------------------------------------
    % Conversion
    % -------------------------------------------------------------------------
    % convert from pixels per frame to mm per second
    
    % width of the well in pixels (well is 30 mm)
    width_well = [327 345 322 324 345 318]; % magic numbers from video
    for w = 1:n_wells
        
        % pixels/frame * frames/second * mm/pixel
        speed_fly(:, idx_well(w,1):idx_well(w,2)) = speed_fly(:, idx_well(w,1):idx_well(w,2)).*(frame_rate*(30./width_well(w)));
        
        % pixels * mm/pixel
        x_fly(:, idx_well(w,1):idx_well(w,2)) = x_fly(:, idx_well(w,1):idx_well(w,2)).*(30./width_well(w));
        y_fly(:, idx_well(w,1):idx_well(w,2)) = y_fly(:, idx_well(w,1):idx_well(w,2)).*(30./width_well(w));
    end
    center = center.*(30./width_well)';
    
    
    % -------------------------------------------------------------------------
    % Filter
    % -------------------------------------------------------------------------
    % All frequency values are in Hz.
    Fs = frame_rate;  % Sampling Frequency
    
    % Attenuate everything under 0.1 Hz = 5 to 10 Seconds 
    Fpass = 0.0167;              % Passband Frequency
    Fstop = 0.1;              % Stopband Frequency
    Dpass = 0.0057563991496;  % Passband Ripple
    Dstop = 0.0001;           % Stopband Attenuation
    dens  = 20;               % Density Factor

    % Calculate the order from the parameters using FIRPMORD.
    [N, Fo, Ao, W] = firpmord([Fpass, Fstop]/(Fs/2), [1 0], [Dpass, Dstop]);

    % Calculate the coefficients using the FIRPM function.
    filter_coeff  = firpm(N, Fo, Ao, W, {dens});

    % -------------------------------------------------------------------------
    % Figures
    % -------------------------------------------------------------------------
    % Translational speed or angular speed 1D time-plots per fly or grouped by
    % well, or grouped by session
    
    % Per well
    figure(1);
    for w = 1:n_wells
        % good flies for that well
        idx = intersect(find(~idx_bad), idx_well(w,1):idx_well(w,2));
        
        if isempty(idx)
        else
            plot_speed = nanmean(speed_fly(:,idx),2);
            plot_speed(isnan(plot_speed)) = 0;
            plot_speed = filtfilt(filter_coeff, 1, plot_speed);
            plot_speed(plot_speed < 0) = 0;

            subplot(3, 2, w)
            box off; hold on;
            plot(ref_ts, nanmean(speed_fly(:,idx),2), 'k');
            plot(ref_ts, plot_speed, 'r');
            line(mt, [10 10],'LineWidth',2, 'Color','g')
            plot(mt(1),10,'gs','MarkerFaceColor','g')
            plot(mt(2),10,'gs','MarkerFaceColor','g')
            xlim([300 ref_ts(end)]);
            ylim([0 20]);
            xlabel('Time (s)');
            ylabel('Speed (mm/s)');
            title(['Well ', num2str(w),' (n = ', num2str(length(idx)), ')']);
            
            well_speed = [well_speed; [length(idx) nanmean(nanmean(speed_fly(ref_ts < 2000,idx),2))]];
        end
    end
    
    % All flies
    figure(2)
    subplot(1,2,1);
    plot_speed = nanmean(speed_fly(:,~idx_bad),2);
    plot_speed(isnan(plot_speed)) = 0;
    plot_speed = filtfilt(filter_coeff, 1, plot_speed);
    plot_speed(plot_speed < 0) = 0;
                
    plot(ref_ts, nanmean(speed_fly(:,~idx_bad),2), 'k'); box off; hold on;
    plot(ref_ts, plot_speed, 'r');
    line(mt, [10 10],'LineWidth',2, 'Color','g')
    plot(mt(1),10,'gs','MarkerFaceColor','g')
    plot(mt(2),10,'gs','MarkerFaceColor','g')
    xlim([300 ref_ts(end)]);
    ylim([0 20]);
    xlabel('Time (s)');
    ylabel('Speed (mm/s)');
    title('All flies');
    
    subplot(1,2,2);
    if sum(isnan(st(:))) > 0
        bar([nanmean(nanmean(speed_fly((ref_ts > 300 & ref_ts < mt(1)), ~idx_bad), 2)), ... % Baseline
        nanmean(nanmean(speed_fly(ref_ts > mt(2),~idx_bad), 2))]); % motor to end GA
        box off;
        ylabel('Mean speed (mm/s)');
        set(gca,'XTick',1:2,'XTickLabel',{'Base','Motor'})
    else
        bar([nanmean(nanmean(speed_fly((ref_ts > 300 & ref_ts < st(1,2)), ~idx_bad), 2)), ... % Baseline
        nanmean(nanmean(speed_fly((ref_ts > st(2,1) & ref_ts < mt(1)),~idx_bad), 2)), ... % start GA to motor
        nanmean(nanmean(speed_fly((ref_ts > mt(2) & ref_ts < st(2,2)),~idx_bad), 2)), ... % motor to end GA
        nanmean(nanmean(speed_fly((ref_ts > st(3,1)),~idx_bad), 2))]); % Recovery
        box off;
        ylabel('Mean speed (mm/s)');
        set(gca,'XTick',1:4,'XTickLabel',{'Base','GA','Motor','Recovery'})
    end

    % 2D movement plot showing one fly or multiple flies (by color) for some
    % shorter (5 minutes?) of activity
    figure(3);
    n = 1;
    pad = 20;
    for w = 1:3 % magic number
        idx = intersect(find(~idx_bad), idx_well(w,1):idx_well(w,2));
        
        if isempty(idx)
        else
            % Baseline
            subplot(3,4,n);
            plot(x_fly(ref_ts > st(1,2)-300 & ref_ts < st(1,2),idx), y_fly(ref_ts > st(1,2)-300 & ref_ts < st(1,2),idx)); box off;
            i0 = x_fly(:,idx);
            i0 = nanmean(i0(:));
            xlim([i0-pad i0+pad]);
            i1 = y_fly(:,idx);
            i1 = nanmean(i1(:));
            ylim([i1-pad i1+pad]);
            ylabel(['Well ', num2str(w),' (n = ', num2str(length(idx)), ')']);
            title('Baseline');
            
            % GA (before motor)
            subplot(3,4,n+1);
            plot(x_fly(ref_ts > st(2,2)-600 & ref_ts < st(2,2)-300,idx), y_fly(ref_ts > st(2,2)-600 & ref_ts < st(2,2)-300,idx)); box off;
            i0 = x_fly(:,idx);
            i0 = nanmean(i0(:));
            xlim([i0-pad i0+pad]);
            i1 = y_fly(:,idx);
            i1 = nanmean(i1(:));
            ylim([i1-pad i1+pad]);
            title('Sevoflurane (before motor)');
            
            % GA (after motor)
            subplot(3,4,n+2);
            plot(x_fly(ref_ts > st(2,2)-300 & ref_ts < st(2,2),idx), y_fly(ref_ts > st(2,2)-300 & ref_ts < st(2,2),idx)); box off;
            i0 = x_fly(:,idx);
            i0 = nanmean(i0(:));
            xlim([i0-pad i0+pad]);
            i1 = y_fly(:,idx);
            i1 = nanmean(i1(:));
            ylim([i1-pad i1+pad]);
            title('Sevoflurane (after motor)');
            4
            % Recovery
            subplot(3,4,n+3);
            plot(x_fly(ref_ts > st(3,1)+600 & ref_ts < st(3,1)+900,idx), y_fly(ref_ts > st(3,1)+600 & ref_ts < st(3,1)+900,idx)); box off;
            i0 = x_fly(:,idx);
            i0 = nanmean(i0(:));
            xlim([i0-pad i0+pad]);
            i1 = y_fly(:,idx);
            i1 = nanmean(i1(:));
            ylim([i1-pad i1+pad]);
            title('Recovery');
            
            n = n + 4;
        end
    end
    
    
    figure(4);
    n = 1;
    for w = 4:6 % magic number
        idx = intersect(find(~idx_bad), idx_well(w,1):idx_well(w,2));
        
        if isempty(idx)
        else
            % Baseline
            subplot(3,4,n);
            plot(x_fly(ref_ts > st(1,2)-300 & ref_ts < st(1,2),idx), y_fly(ref_ts > st(1,2)-300 & ref_ts < st(1,2),idx)); box off;
            i0 = x_fly(:,idx);
            i0 = nanmean(i0(:));
            xlim([i0-pad i0+pad]);
            i1 = y_fly(:,idx);
            i1 = nanmean(i1(:));
            ylim([i1-pad i1+pad]);
            ylabel(['Well ', num2str(w),' (n = ', num2str(length(idx)), ')']);
            title('Baseline');
            
            % GA (before motor)
            subplot(3,4,n+1);
            plot(x_fly(ref_ts > st(2,2)-600 & ref_ts < st(2,2)-300,idx), y_fly(ref_ts > st(2,2)-600 & ref_ts < st(2,2)-300,idx)); box off;
            i0 = x_fly(:,idx);
            i0 = nanmean(i0(:));
            xlim([i0-pad i0+pad]);
            i1 = y_fly(:,idx);
            i1 = nanmean(i1(:));
            ylim([i1-pad i1+pad]);
            title('Sevoflurane (before motor)');
            
            % GA (after motor)
            subplot(3,4,n+2);
            plot(x_fly(ref_ts > st(2,2)-300 & ref_ts < st(2,2),idx), y_fly(ref_ts > st(2,2)-300 & ref_ts < st(2,2),idx)); box off;
            i0 = x_fly(:,idx);
            i0 = nanmean(i0(:));
            xlim([i0-pad i0+pad]);
            i1 = y_fly(:,idx);
            i1 = nanmean(i1(:));
            ylim([i1-pad i1+pad]);
            title('Sevoflurane (after motor)');
            
            % Recovery
            subplot(3,4,n+3);
            plot(x_fly(ref_ts > st(3,1)+600 & ref_ts < st(3,1)+900,idx), y_fly(ref_ts > st(3,1)+600 & ref_ts < st(3,1)+900,idx)); box off;
            i0 = x_fly(:,idx);
            i0 = nanmean(i0(:));
            xlim([i0-pad i0+pad]);
            i1 = y_fly(:,idx);
            i1 = nanmean(i1(:));
            ylim([i1-pad i1+pad]);
            title('Recovery');   
            
            n = n + 4;
        end
    end
    
    if q == 1
        figure(5);
        subplot(1,5,1:4);
        plot_speed = nanmean(speed_fly(:,~idx_bad),2);
        plot_speed(isnan(plot_speed)) = 0;
        plot_speed = filtfilt(filter_coeff, 1, plot_speed);
        plot_speed(plot_speed < 0) = 0;

        plot(ref_ts, nanmean(speed_fly(:,~idx_bad),2), 'Color', [0.7 0.7 0.7]); box off; hold on;
        plot(ref_ts, plot_speed, 'Color', [44,123,182]./255, 'Linewidth', 1.5);
        line(mt, [10 10],'LineWidth',2, 'Color','k')
        plot(mt(1),10,'ks','MarkerFaceColor','w')
        plot(mt(2),10,'ks','MarkerFaceColor','w')
%         line([3900 3900],[0 20],'LineStyle','--','Color','k','LineWidth',1.5);
%         line([4800 4800],[0 20],'LineStyle','--','Color','k','LineWidth',1.5);
        xlim([300 ref_ts(end)]);
        ylim([0 16]);
        xlabel('Time (s)');
        ylabel(['Speed (mm/s, n = ', num2str(sum(~idx_bad)), ')']);
        set(gca,'YTick',0:2:20,'XTick',0:600:10000);
        
        subplot(1,5,5);
        bar([nanmean(nanmean(speed_fly((ref_ts > 300 & ref_ts < mt(1)), ~idx_bad), 2)), ... % Baseline
        nanmean(nanmean(speed_fly(ref_ts > mt(2),~idx_bad), 2))],'FaceColor','k'); % motor to end GA
        box off;
        ylabel('Mean speed (mm/s)');
        set(gca,'XTick',1:2,'XTickLabel',{'Base','Motor'})
        
        cd('/home/jdk20/Documents/ppc-fly-anesthesia');
        w = 9;
        h = 3;
        set(figure(5),'PaperPosition',[0 0 w*1.19 h*1.19]);
        print(figure(5),'-dpng','no_anesthesia.png');
%         close all;
    end
    
    if q == 2
        figure(5);
        subplot(1,5,1:4);
        plot_speed = nanmean(speed_fly(:,~idx_bad),2);
        plot_speed(isnan(plot_speed)) = 0;
        plot_speed = filtfilt(filter_coeff, 1, plot_speed);
        plot_speed(plot_speed < 0) = 0;

        plot(ref_ts, nanmean(speed_fly(:,~idx_bad),2), 'Color', [0.7 0.7 0.7]); box off; hold on;
        plot(ref_ts, plot_speed, 'Color', [44,123,182]./255, 'Linewidth', 1.5);
        line(mt, [10 10],'LineWidth',2, 'Color','k')
        plot(mt(1),10,'ks','MarkerFaceColor','w')
        plot(mt(2),10,'ks','MarkerFaceColor','w')
        line([3900 3900],[0 20],'LineStyle','--','Color','k','LineWidth',1.5);
        line([4800 4800],[0 20],'LineStyle','--','Color','k','LineWidth',1.5);
        xlim([300 ref_ts(end)]);
        ylim([0 16]);
        xlabel('Time (s)');
        ylabel(['Speed (mm/s, n = ', num2str(sum(~idx_bad)), ')']);
        set(gca,'YTick',0:2:20,'XTick',0:600:10000);
        
        subplot(1,5,5);
        bar([nanmean(nanmean(speed_fly((ref_ts > 300 & ref_ts < st(1,2)), ~idx_bad), 2)), ... % Baseline
        nanmean(nanmean(speed_fly((ref_ts > st(2,1) & ref_ts < mt(1)),~idx_bad), 2)), ... % start GA to motor
        nanmean(nanmean(speed_fly((ref_ts > mt(2) & ref_ts < st(2,2)),~idx_bad), 2)), ... % motor to end GA
        nanmean(nanmean(speed_fly((ref_ts > st(3,1)),~idx_bad), 2))],'FaceColor','k'); % Recovery
        box off;
        ylabel('Mean speed (mm/s)');
        set(gca,'XTick',1:4,'XTickLabel',{'Base','GA','Motor','Rec'})
        
        cd('/home/jdk20/Documents/ppc-fly-anesthesia');
        w = 9;
        h = 3;
        set(figure(5),'PaperPosition',[0 0 w*1.19 h*1.19]);
        print(figure(5),'-dpng','anesthesia_7.png');
%         close all;

        w = 5;
        idx = intersect(find(~idx_bad), idx_well(w,1):idx_well(w,2));
        
        figure(6);
        % Baseline
        subplot(1,4,1);
        plot(x_fly(ref_ts > st(1,2)-300 & ref_ts < st(1,2),idx), y_fly(ref_ts > st(1,2)-300 & ref_ts < st(1,2),idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        ylabel(['Well ', num2str(w),' (n = ', num2str(length(idx)), ')']);
        title('Base');

        % GA (before motor)
        subplot(1,4,2);
        plot(x_fly(ref_ts > st(2,2)-600 & ref_ts < st(2,2)-300,idx), y_fly(ref_ts > st(2,2)-600 & ref_ts < st(2,2)-300,idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        title('GA (before motor)');

        % GA (after motor)
        subplot(1,4,3);
        plot(x_fly(ref_ts > st(2,2)-300 & ref_ts < st(2,2),idx), y_fly(ref_ts > st(2,2)-300 & ref_ts < st(2,2),idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        title('GA (after motor)');

        % Recovery
        subplot(1,4,4);
        plot(x_fly(ref_ts > st(3,1)+600 & ref_ts < st(3,1)+900,idx), y_fly(ref_ts > st(3,1)+600 & ref_ts < st(3,1)+900,idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        title('Recovery');
        
        w = 12;
        h = 3;
        set(figure(6),'PaperPosition',[0 0 w*1.19 h*1.19]);
        print(figure(6),'-dpng','anesthesia_7_chamber.png');
        
    end
    
    if q == 3
        figure(5);
        subplot(1,5,1:4);
        plot_speed = nanmean(speed_fly(:,~idx_bad),2);
        plot_speed(isnan(plot_speed)) = 0;
        plot_speed = filtfilt(filter_coeff, 1, plot_speed);
        plot_speed(plot_speed < 0) = 0;

        plot(ref_ts, nanmean(speed_fly(:,~idx_bad),2), 'Color', [0.7 0.7 0.7]); box off; hold on;
        plot(ref_ts, plot_speed, 'Color', [44,123,182]./255, 'Linewidth', 1.5);
        line(mt, [10 10],'LineWidth',2, 'Color','k')
        plot(mt(1),10,'ks','MarkerFaceColor','w')
        plot(mt(2),10,'ks','MarkerFaceColor','w')
        line([3900 3900],[0 20],'LineStyle','--','Color','k','LineWidth',1.5);
        line([4800 4800],[0 20],'LineStyle','--','Color','k','LineWidth',1.5);
        xlim([300 ref_ts(end)]);
        ylim([0 16]);
        xlabel('Time (s)');
        ylabel(['Speed (mm/s, n = ', num2str(sum(~idx_bad)), ')']);
        set(gca,'YTick',0:2:20,'XTick',0:600:10000);
        
        subplot(1,5,5);
        bar([nanmean(nanmean(speed_fly((ref_ts > 300 & ref_ts < st(1,2)), ~idx_bad), 2)), ... % Baseline
        nanmean(nanmean(speed_fly((ref_ts > st(2,1) & ref_ts < mt(1)),~idx_bad), 2)), ... % start GA to motor
        nanmean(nanmean(speed_fly((ref_ts > mt(2) & ref_ts < st(2,2)),~idx_bad), 2)), ... % motor to end GA
        nanmean(nanmean(speed_fly((ref_ts > st(3,1)),~idx_bad), 2))],'FaceColor','k'); % Recovery
        box off;
        ylabel('Mean speed (mm/s)');
        set(gca,'XTick',1:4,'XTickLabel',{'Base','GA','Motor','Rec'})
        
        cd('/home/jdk20/Documents/ppc-fly-anesthesia');
        w = 9;
        h = 3;
        set(figure(5),'PaperPosition',[0 0 w*1.19 h*1.19]);
        print(figure(5),'-dpng','anesthesia_4.png');
%         close all;

        w = 5;
        idx = intersect(find(~idx_bad), idx_well(w,1):idx_well(w,2));
        
        figure(6);
        % Baseline
        subplot(1,4,1);
        plot(x_fly(ref_ts > st(1,2)-300 & ref_ts < st(1,2),idx), y_fly(ref_ts > st(1,2)-300 & ref_ts < st(1,2),idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        ylabel(['Well ', num2str(w),' (n = ', num2str(length(idx)), ')']);
        title('Base');

        % GA (before motor)
        subplot(1,4,2);
        plot(x_fly(ref_ts > st(2,2)-600 & ref_ts < st(2,2)-300,idx), y_fly(ref_ts > st(2,2)-600 & ref_ts < st(2,2)-300,idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        title('GA (before motor)');

        % GA (after motor)
        subplot(1,4,3);
        plot(x_fly(ref_ts > st(2,2)-300 & ref_ts < st(2,2),idx), y_fly(ref_ts > st(2,2)-300 & ref_ts < st(2,2),idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        title('GA (after motor)');

        % Recovery
        subplot(1,4,4);
        plot(x_fly(ref_ts > st(3,1)+600 & ref_ts < st(3,1)+900,idx), y_fly(ref_ts > st(3,1)+600 & ref_ts < st(3,1)+900,idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        title('Recovery');
        
        w = 12;
        h = 3;
        set(figure(6),'PaperPosition',[0 0 w*1.19 h*1.19]);
        print(figure(6),'-dpng','anesthesia_4_chamber.png');
    end
    
    if q == 4
        figure(5);
        subplot(1,5,1:4);
        plot_speed = nanmean(speed_fly(:,~idx_bad),2);
        plot_speed(isnan(plot_speed)) = 0;
        plot_speed = filtfilt(filter_coeff, 1, plot_speed);
        plot_speed(plot_speed < 0) = 0;

        plot(ref_ts, nanmean(speed_fly(:,~idx_bad),2), 'Color', [0.7 0.7 0.7]); box off; hold on;
        plot(ref_ts, plot_speed, 'Color', [44,123,182]./255, 'Linewidth', 1.5);
        line(mt, [10 10],'LineWidth',2, 'Color','k')
        plot(mt(1),10,'ks','MarkerFaceColor','w')
        plot(mt(2),10,'ks','MarkerFaceColor','w')
        line([3900 3900],[0 20],'LineStyle','--','Color','k','LineWidth',1.5);
        line([4800 4800],[0 20],'LineStyle','--','Color','k','LineWidth',1.5);
        xlim([300 ref_ts(end)]);
        ylim([0 16]);
        xlabel('Time (s)');
        ylabel(['Speed (mm/s, n = ', num2str(sum(~idx_bad)), ')']);
        set(gca,'YTick',0:2:20,'XTick',0:600:10000);
        
        subplot(1,5,5);
        bar([nanmean(nanmean(speed_fly((ref_ts > 300 & ref_ts < st(1,2)), ~idx_bad), 2)), ... % Baseline
        nanmean(nanmean(speed_fly((ref_ts > st(2,1) & ref_ts < mt(1)),~idx_bad), 2)), ... % start GA to motor
        nanmean(nanmean(speed_fly((ref_ts > mt(2) & ref_ts < st(2,2)),~idx_bad), 2)), ... % motor to end GA
        nanmean(nanmean(speed_fly((ref_ts > st(3,1)),~idx_bad), 2))],'FaceColor','k'); % Recovery
        box off;
        ylabel('Mean speed (mm/s)');
        set(gca,'XTick',1:4,'XTickLabel',{'Base','GA','Motor','Rec'})
        
        cd('/home/jdk20/Documents/ppc-fly-anesthesia');
        w = 9;
        h = 3;
        set(figure(5),'PaperPosition',[0 0 w*1.19 h*1.19]);
        print(figure(5),'-dpng','anesthesia_1.png');
%         close all;

         w = 5;
        idx = intersect(find(~idx_bad), idx_well(w,1):idx_well(w,2));
        
        figure(6);
        % Baseline
        subplot(1,4,1);
        plot(x_fly(ref_ts > st(1,2)-300 & ref_ts < st(1,2),idx), y_fly(ref_ts > st(1,2)-300 & ref_ts < st(1,2),idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        ylabel(['Well ', num2str(w),' (n = ', num2str(length(idx)), ')']);
        title('Base');

        % GA (before motor)
        subplot(1,4,2);
        plot(x_fly(ref_ts > st(2,2)-600 & ref_ts < st(2,2)-300,idx), y_fly(ref_ts > st(2,2)-600 & ref_ts < st(2,2)-300,idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        title('GA (before motor)');

        % GA (after motor)
        subplot(1,4,3);
        plot(x_fly(ref_ts > st(2,2)-300 & ref_ts < st(2,2),idx), y_fly(ref_ts > st(2,2)-300 & ref_ts < st(2,2),idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        title('GA (after motor)');

        % Recovery
        subplot(1,4,4);
        plot(x_fly(ref_ts > st(3,1)+600 & ref_ts < st(3,1)+900,idx), y_fly(ref_ts > st(3,1)+600 & ref_ts < st(3,1)+900,idx)); box off;
        i0 = x_fly(:,idx);
        i0 = nanmean(i0(:));
        xlim([i0-pad i0+pad]);
        i1 = y_fly(:,idx);
        i1 = nanmean(i1(:));
        ylim([i1-pad i1+pad]);
        title('Recovery');
        
        w = 12;
        h = 3;
        set(figure(6),'PaperPosition',[0 0 w*1.19 h*1.19]);
        print(figure(6),'-dpng','anesthesia_1_chamber.png');
    end
    
    
    % 2D heatmap by well for some timepoints

    % Scatter plot of individual mean fly speed for baseline vs GA

    % Dose-response curve across sessions for movement during GA
    
end















