clc; clear variables; close all;

listdir = '/home/jdk20/git/fly-anesthesia-chamber/analysis/circadian-inventory.csv';
datadir = '/local/anesthesia/data/';

opts = delimitedTextImportOptions("NumVariables", 3);
opts.DataLines = [1, Inf];
opts.Delimiter = ",";
opts.VariableNames = ["VarName1", "VarName2", "VarName3"];
opts.VariableTypes = ["char", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts = setvaropts(opts, "VarName1", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "VarName1", "EmptyFieldRule", "auto");
s = readtable(listdir, opts);
s = table2cell(s);
numIdx = cellfun(@(x) ~isnan(str2double(x)), s);
s(numIdx) = cellfun(@(x) {str2double(x)}, s(numIdx));
clear opts

coeff_baseline = [];
coeff_ga = [];
coeff_recovery = [];
for k = 0
    switch k
        case 0
            S = 'w^{1118} (31+CS) 6x';
            c = [228,26,28]./255;
    end
    
    idx = (cell2mat(s(:,3)) == k);

    sessiondir = s(idx, 1);
    session_dose = cell2mat(s(idx, 2));
    
    dose = [];
    speed_baseline = [];
    speed_ga = [];
    speed_recovery = [];
    
    dose_well = [];
    speed_well_baseline = [];
    speed_well_ga = [];
    speed_well_recovery = [];
    
    time_session_baseline = [];
    time_session_ga = [];
    time_session_recovery = [];
    
    time_well_baseline = [];
    time_well_ga = [];
    time_well_recovery = [];
    
    for i = 1:length(sessiondir)
        if ~strcmp(sessiondir{i}, 'NA')
            cd([datadir, sessiondir{i}]);

            load('metrics.mat');
            
            if isnan(st(2,1)) || isnan(st(3,1))
                i0 = 300;
                i1 = mt(end) + 300; % Last motor + 5 minutes
                
                i2 = 300;
                i3 = mt(end) + 300; % Last motor + 5 minutes
                
                i4 = 300;
                i5 = mt(end) + 300; % Last motor + 5 minutes
            else
                i0 = st(2,1) + 300; % GA on + 5 minutes
                i1 = st(3,1); % GA off
                
                i2 = 300;
                i3 = st(2,1) - 60; % One minute before GA
                
                i4 = st(3,1); % GA off
                i5 = mt(end) + 300; % Last motor + 5 minutes
            end
                        
            % Speed by session
            dose = [dose; session_dose(i)];
            speed_baseline = [speed_baseline; nanmean(nanmean(speed_fly(ref_ts > i2 & ref_ts < i3, ~idx_bad), 2))];
            speed_ga = [speed_ga; nanmean(nanmean(speed_fly(ref_ts > i0 & ref_ts < i1, ~idx_bad), 2))];
            speed_recovery = [speed_recovery; nanmean(nanmean(speed_fly(ref_ts > i4 & ref_ts < i5, ~idx_bad), 2))];
            
            temp_time = datetime(sessiondir{i}, 'InputFormat', 'yyyy-MM-dd-HH-mm-ss');
            temp_time_same_day = datetime([num2str(temp_time.Hour),'-',num2str(temp_time.Minute),'-',num2str(temp_time.Second)], 'InputFormat', 'HH-mm-ss');
                
            time_session_baseline = [time_session_baseline; temp_time];
    
            % Speed by well
            for j = 1:size(idx_well,1)
                dose_well = [dose_well; session_dose(i)];
                
                speed_well_baseline = [speed_well_baseline; nanmean(nanmean(speed_fly(ref_ts > i2 & ref_ts < i3, idx_well(j,1):idx_well(j,2)), 2))];
                speed_well_ga = [speed_well_ga; nanmean(nanmean(speed_fly(ref_ts > i0 & ref_ts < i1, idx_well(j,1):idx_well(j,2)), 2))];
                speed_well_recovery = [speed_well_recovery; nanmean(nanmean(speed_fly(ref_ts > i4 & ref_ts < i5, idx_well(j,1):idx_well(j,2)), 2))];
                
                time_well_baseline = [time_well_baseline; temp_time_same_day];
                time_well_ga = [time_well_ga; temp_time_same_day + minutes(35)];
                time_well_recovery = [time_well_recovery; temp_time_same_day + minutes(55)];
            end
            
        end
    end
    
    mj = 0.3; % MAGIC JITTER
    
    speed_well_baseline = speed_well_baseline - mj;
    speed_well_baseline(speed_well_baseline < 0) = 0;
    speed_well_ga = speed_well_ga - mj;
    speed_well_ga(speed_well_ga < 0) = 0;
    speed_well_recovery = speed_well_recovery - mj;
    speed_well_recovery(speed_well_recovery < 0) = 0;
    
    speed_ga = speed_ga - mj; % MAGIC JITTER
    speed_ga(speed_ga < 0) = 0;
    speed_baseline = speed_baseline - mj; % MAGIC JITTER
    speed_baseline(speed_baseline < 0) = 0;
    speed_recovery = speed_recovery - mj; % MAGIC JITTER
    speed_recovery(speed_recovery < 0) = 0;
    
    % Time figure
    figure(30+k);
    hold on; box off;
    plot(time_well_baseline, speed_well_baseline,'ko', 'MarkerFaceColor', c)
    ylim([0 7]);
    ylabel('Mean Speed (mm/s)');
    xlabel('Time (Hour/Minute)');
    title('Baseline');
    
    figure(70+k);
    hold on; box off;
    plot(time_well_ga, speed_well_ga,'ko', 'MarkerFaceColor', c)
    ylim([0 7]);
    ylabel('Mean Speed (mm/s)');
    xlabel('Time (Hour/Minute)');
    title('Sevoflurane');
    
    figure(80+k);
    hold on; box off;
    plot(time_well_recovery, speed_well_recovery,'ko', 'MarkerFaceColor', c)
    ylim([0 7]);
    ylabel('Mean Speed (mm/s)');
    xlabel('Time (Hour/Minute)');
    title('Recovery');
   
    figure(41);
    hold on; box off;
    plot(time_session_baseline, speed_baseline,'ko', 'MarkerFaceColor', c)
    ylim([0 7]);
    ylabel('Mean Speed (mm/s)');
    xlabel('Date (Hour/Minute)');
end


