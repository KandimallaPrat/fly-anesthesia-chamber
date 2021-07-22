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
            S = 'w1118 (31+cs) 6x';
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

    speed = [];
    dose = [];
    for i = 1:length(sessiondir)
        if ~strcmp(sessiondir{i}, 'NA')
            cd([datadir, sessiondir{i}]);

            load('metrics.mat');

            if isnan(st(2,1)) || isnan(st(3,1))
                i0 = 0; % GA on + 5 minutes
                i1 = 7200; % GA off
            else
                i0 = st(2,1) + 300; % GA on + 5 minutes
                i1 = st(3,1); % GA off
            end
            
            dose = [dose; session_dose(i)];
            speed = [speed; nanmean(nanmean(speed_fly(ref_ts > i0 & ref_ts < i1, ~idx_bad), 2))];
        end
    end
        
    speed = speed - 0.3; % MAGIC JITTER
    speed(speed < 0) = 0;
    
    subplot(2,3,k+1);
    hold on; box off;
    if length(speed) > 1
        f = fit(dose,speed,'exp1');
        plot(0:0.1:9, f.a .* exp(f.b .* (0:0.1:9)),'k', 'Linewidth', 1.5);
    end
    plot(dose, speed, 'ko', 'MarkerFaceColor', c);
    xlim([-1 9]);
    ylim([0 2.5]);
    set(gca,'XTick',0:8);
    ylabel('Mean Speed (mm/s)');
    xlabel('Sevoflurane %');
    title(S);
    
    subplot(2,3,6);
    hold on; box off;
    if length(speed) > 1
        plot(0:0.1:9, f.a .* exp(f.b .* (0:0.1:9)),'Color',c, 'Linewidth', 1.5);
    end
    plot(dose, speed, 'ko', 'MarkerFaceColor', c);
    xlim([-1 9]);
    ylim([0 2.5]);
    set(gca,'XTick',0:8);
    ylabel('Mean Speed (mm/s)');
    xlabel('Sevoflurane %');
end

cd('/home/jdk20/git/fly-anesthesia-chamber/analysis/');
w = 12;
h = 8;
set(figure(1),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(1),'-dpng','dose_response_curve.png');