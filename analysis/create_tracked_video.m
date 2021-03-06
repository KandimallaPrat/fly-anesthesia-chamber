function create_tracked_video(sessiondir)
    datadir = '/local/anesthesia/data/';
    
    trex_conversion_number = 3.3697;
    center = [180 180; 180 180; 180 180; 180 180; 180 180; 180 180];     

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
            d = sqrt(nansum(([x y] - center(w,:)).^2, 2));

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
    
    % -------------------------------------------------------------------------
    % Video
    % -------------------------------------------------------------------------
    cd([datadir, sessiondir]);
    for w = 1:n_wells
        if ~isfile(['tracking-video-c-well-', num2str(w),'.avi'])
            vr = VideoReader(['video-c-well-', num2str(w),'.mp4']);
            disp(['tracking video-c-well-', num2str(w),'.mp4'])
            num_frames = floor(vr.Duration*vr.FrameRate);

            if num_frames ~= length(ref_ts)
                error(['error: num_frames: ', num2str(num_frames),', but ref_ts: ', num2str(length(ref_ts))]);
            end

            vw = VideoWriter(['tracking-video-c-well-', num2str(w),'.avi']);
            vw.Quality = 100;
            vw.FrameRate = frame_rate;
            open(vw);

            ds = 30; % downsample rate
            frame_counter = 0;
            pad = 10;
            set(figure(1), 'Position',  [1000, 500, vr.width+pad, vr.height+pad])
            for i = 1:ds:num_frames
                f = read(vr, i);

                image(f); hold on; box off;
                plot(x_fly_outliers(i, idx_well(w,1):idx_well(w,2)), y_fly_outliers(i, idx_well(w,1):idx_well(w,2)),'ro');

                if ref_ts(i) < st(1,2)
                    text(vr.width/2, 50, 'Baseline', 'Color', 'w')
                elseif ref_ts(i) >= st(2,1) && ref_ts(i) <= st(2,2)
                    text(vr.width/2, 50, ['Sevoflurane ', num2str(exp_dose),'%'], 'Color', 'w')
                elseif ref_ts(i) > st(3,1)
                    text(vr.width/2, 50, 'Recovery', 'Color', 'w')
                end

                if ref_ts(i) >= mt(1) && ref_ts(i) <= mt(2)
                    text(vr.width/2, 75, 'Motor On', 'Color', 'r')
                end

                set(gca,'XTickLabel',[],'YTickLabel',[],'nextplot','replacechildren', ...
                'Units','pixels','Position', [5 5 vr.width vr.height]);

                write_frame = getframe(gcf);

                % Error checking
                if size(write_frame.cdata, 1) > (vr.height+pad)
                    write_frame.cdata = write_frame.cdata(1:(vr.height+pad), :, :);
                end

                if size(write_frame.cdata, 2) > (vr.width+pad)
                    write_frame.cdata = write_frame.cdata(:, 1:(vr.width+pad), :);
                end

                if size(write_frame.cdata, 1) < (vr.height+pad)
                    temp = zeros(vr.height+pad, vr.width+pad, 3);
                    temp(1:size(write_frame.cdata,1), 1:size(write_frame.cdata,2), :) = write_frame.cdata;
                    write_frame.cdata = uint8(temp);
                end

                if size(write_frame.cdata, 2) < (vr.width+pad)
                    temp = zeros(vr.height+pad, vr.width+pad, 3);
                    temp(1:size(write_frame.cdata,1), 1:size(write_frame.cdata,2), :) = write_frame.cdata;
                    write_frame.cdata = uint8(temp);
                end

                try
                    writeVideo(vw, write_frame);
                catch
                    disp(['improper frame ', num2str(i),' (size: ', num2str(size(write_frame.cdata)),')']);
                    keyboard
                end

                frame_counter = frame_counter + ds;

                if frame_counter > (5*60*frame_rate) % every 5 minutes worth of frames
                    disp(['processed ', num2str(100*(i/num_frames)), '%'])
                    frame_counter = 0;
                end
            end
            close(gcf);
            close(vw);
            disp(' ');
        end
    end