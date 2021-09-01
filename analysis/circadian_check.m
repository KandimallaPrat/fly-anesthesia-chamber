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
            
            i0 = 300;
            i1 = 2400;

            idx = [[mt(diff(mt) > 10); mt(end)], [mt(diff(mt) > 10); mt(end)] + 30];
            idx_motor = zeros(length(ref_ts),1);
            for j = 1:size(idx,1)
                idx_motor = idx_motor + double(ref_ts >= idx(j,1) & ref_ts <= idx(j,2));
            end
            idx_motor = logical(idx_motor);

            i4 = mt(end) + 300;
            i5 = 7200; % Last motor + 5 minutes

            temp_time = datetime(sessiondir{i}, 'InputFormat', 'yyyy-MM-dd-HH-mm-ss');
            temp_time_same_day = datetime([num2str(temp_time.Hour),'-',num2str(temp_time.Minute),'-',num2str(temp_time.Second)], 'InputFormat', 'HH-mm-ss');
                
            time_session_baseline = [time_session_baseline; temp_time];
    
            % Speed by well
            for j = 1:size(idx_well,1)
                dose_well = [dose_well; session_dose(i)];
                
                speed_well_baseline = [speed_well_baseline; nanmean(nanmean(speed_fly(ref_ts > i0 & ref_ts < i1, idx_well(j,1):idx_well(j,2)), 2))];
                speed_well_ga = [speed_well_ga; nanmean(nanmean(speed_fly(idx_motor, idx_well(j,1):idx_well(j,2)), 2))];
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
    
    idx = datetime('15-00-00','InputFormat','HH-mm-ss');
    
    i0 = time_well_baseline < idx; % 12:00pm
    i1 = time_well_baseline > idx; % 7:00pm
    
    for j = 1:3
        switch j
            case 1
                temp = speed_well_baseline;
                S = {'12:05pm - 12:40pm','7:05pm - 7:40pm'};
                S2 = 'Pre-Stimulus';
            case 2
                temp = speed_well_ga;
                S = {'12:40pm - 1:25pm','7:40pm - 8:25pm'};
                S2 = 'Stimulus (30s window)';
            case 3
                temp = speed_well_recovery;
                S = {'1:30pm - 2:00pm','8:30pm - 9:00pm'};
                S2 = 'Post-Stimulus';
        end
    
        figure(1);
        subplot(1,3,j);
        b1 = bootstrp(100000,@mean,temp(i0));
        b2 = bootstrp(100000,@mean,temp(i1));
        b3 = b2 - b1;

        plot([ones(sum(i0),1); 2.*ones(sum(i1),1)]+randn(length(i0),1)./10, ...
            [temp(i0); temp(i1)],'ko','MarkerSize',5); box off; hold on;
        plot([1, 2],[mean(temp(i0)), mean(temp(i1))],'kd','MarkerFaceColor','r','MarkerSize',8);
        xlim([0 3]);
        line([0.9 1.1],[prctile(b1,0.5) prctile(b1,0.5)],'Color','r')
        line([0.9 1.1],[prctile(b1,99.5) prctile(b1,99.5)],'Color','r')
        line([1.9 2.1],[prctile(b2,0.5) prctile(b2,0.5)],'Color','r')
        line([1.9 2.1],[prctile(b2,99.5) prctile(b2,99.5)],'Color','r')
        line([1 1],[prctile(b1,0.5) prctile(b1,99.5)],'Color','r')
        line([2 2],[prctile(b2,0.5) prctile(b2,99.5)],'Color','r')
        set(gca,'XTick',1:2,'XTickLabel', S)
        ylabel('Mean Speed (mm/s)');
        xlabel('Time');
        ylim([0 6]);
        title(S2);

        disp(['[',S{1},']: ',num2str(round(mean(b1),2)),' mm/s (99.5% CI: ',num2str(round(prctile(b1,0.5),2)),' mm/s to ',num2str(round(prctile(b1,99.5),2)),' mm/s)']);
        disp(['[',S{2},']: ',num2str(round(mean(b2),2)),' mm/s (99.5% CI: ',num2str(round(prctile(b2,0.5),2)),' mm/s to ',num2str(round(prctile(b2,99.5),2)),' mm/s)']);
        disp(['[Diff]: ',num2str(round(mean(b3),2)),' mm/s (99.5% CI: ',num2str(round(prctile(b3,0.5),2)),' mm/s to ',num2str(round(prctile(b3,99.5),2)),' mm/s)']);
    end
end


