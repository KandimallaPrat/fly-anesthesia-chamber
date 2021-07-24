clc; clear variables; close all;

listdir = '/home/jdk20/git/fly-anesthesia-chamber/analysis/session-inventory.csv';
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

% 0 = w1118 (31+cs) 6x
% 1 = HCS
% 2 = DL+
% 3 = Phinney Ridge
% 4 = Top Banana

for k = 0:4
    switch k
        case 0
            S = 'w^{1118} (31+CS) 6x';
            c = [228,26,28]./255;
        case 1
            S = 'HCS';
            c = [55,126,184]./255;
        case 2
            S = 'DL+';
            c = [77,175,74]./255;
        case 3
            S = 'Phinney Ridge';
            c = [152,78,163]./255;
        case 4
            S = 'Top Banana';
            c = [255,127,0]./255;
    end
    
    idx = (cell2mat(s(:,3)) == k);

    sessiondir = s(idx, 1);
    session_dose = cell2mat(s(idx, 2));
    
    speed_baseline = [];
    speed_ga = [];
    speed_recovery = [];
    dose = [];
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
            
            dose = [dose; session_dose(i)];
            speed_baseline = [speed_baseline; nanmean(nanmean(speed_fly(ref_ts > i2 & ref_ts < i3, ~idx_bad), 2))];
            speed_ga = [speed_ga; nanmean(nanmean(speed_fly(ref_ts > i0 & ref_ts < i1, ~idx_bad), 2))];
            speed_recovery = [speed_recovery; nanmean(nanmean(speed_fly(ref_ts > i4 & ref_ts < i5, ~idx_bad), 2))];
        end
    end
        
    speed_ga = speed_ga - 0.3; % MAGIC JITTER
    speed_ga(speed_ga < 0) = 0;
    
    speed_baseline = speed_baseline - 0.3; % MAGIC JITTER
    speed_baseline(speed_baseline < 0) = 0;
    
    speed_recovery = speed_recovery - 0.3; % MAGIC JITTER
    speed_recovery(speed_recovery < 0) = 0;
    
    for m = 1:3
        switch m
            case 1
                temp_speed = speed_ga;
                ymax = 4.5;
            case 2
                temp_speed = speed_baseline;
                ymax = 4.5;
            case 3
                temp_speed = speed_recovery;
                ymax = 4.5;
        end
        
        figure(m)
        subplot(2,3,k+1);
        hold on; box off;
        if length(temp_speed) > 1
            f = fit(dose,temp_speed,'exp1');
            plot(0:0.1:9, f.a .* exp(f.b .* (0:0.1:9)),'k', 'Linewidth', 1.5);
        end
        plot(dose, temp_speed, 'ko', 'MarkerFaceColor', c);
        xlim([-1 9]);
        ylim([0 ymax]);
        set(gca,'XTick',0:8);
        ylabel('Mean Speed (mm/s)');
        xlabel('Sevoflurane %');
        title(S);

        subplot(2,3,6);
        hold on; box off;
        if length(temp_speed) > 1
            plot(0:0.1:9, f.a .* exp(f.b .* (0:0.1:9)),'Color',c, 'Linewidth', 1.5);
        end
        plot(dose, temp_speed, 'ko', 'MarkerFaceColor', c);
        xlim([-1 9]);
        ylim([0 ymax]);
        set(gca,'XTick',0:8);
        ylabel('Mean Speed (mm/s)');
        xlabel('Sevoflurane %');
    end
end

cd('/home/jdk20/git/fly-anesthesia-chamber/analysis/');
w = 12;
h = 8;
set(figure(1),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(1),'-dpng','dose_response_curve_ga.png');

set(figure(2),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(2),'-dpng','dose_response_curve_baseline.png');

set(figure(3),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(3),'-dpng','dose_response_curve_recovery.png');
