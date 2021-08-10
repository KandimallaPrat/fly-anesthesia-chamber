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

coeff_baseline = [];
coeff_ga = [];
coeff_recovery = [];
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
    
    dose = [];
    speed_baseline = [];
    speed_ga = [];
    speed_recovery = [];
    
    dose_well = [];
    speed_well_baseline = [];
    speed_well_ga = [];
    speed_well_recovery = [];
    
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
            
            % Speed by well
            for j = 1:size(idx_well,1)
                dose_well = [dose_well; session_dose(i)];
                
                speed_well_baseline = [speed_well_baseline; nanmean(nanmean(speed_fly(ref_ts > i2 & ref_ts < i3, idx_well(j,1):idx_well(j,2)), 2))];
                speed_well_ga = [speed_well_ga; nanmean(nanmean(speed_fly(ref_ts > i0 & ref_ts < i1, idx_well(j,1):idx_well(j,2)), 2))];
                speed_well_recovery = [speed_well_recovery; nanmean(nanmean(speed_fly(ref_ts > i4 & ref_ts < i5, idx_well(j,1):idx_well(j,2)), 2))];
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
    
    % By session
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
    
    % By well
    for m = 1:3
        switch m
            case 2
                temp_speed = speed_well_ga;
                ymax = 7; 
                S2 = ': General anesthesia';
            case 1
                temp_speed = speed_well_baseline;
                ymax = 7;
                S2 = ': Baseline';
            case 3
                temp_speed = speed_well_recovery;
                ymax = 7;
                S2 = ': Recovery';
        end
        
        figure(10+k)
        subplot(3,1,m);
        lw = 0.1;
                
        exp_a = [];
        exp_b = [];
        for n = 1:100
            % sample with replacement
            [r, r_idx] = datasample(temp_speed, length(temp_speed));
            if m == 1
                f = fit(dose_well(r_idx), r, 'poly1');
                exp_a = [exp_a; f.p1];
                exp_b = [exp_b; f.p2];
            else
                f = fit(dose_well(r_idx), r, 'exp1');
                exp_a = [exp_a; f.a];
                exp_b = [exp_b; f.b];
            end
        end
       
        
        hold on; box off;
        if m == 1
%             plot(0:0.1:9, prctile(exp_a,2.5).*(0:0.1:9) + prctile(exp_b,2.5),'k--', 'Linewidth', 1.5);
%             plot(0:0.1:9, prctile(exp_a,97.5).*(0:0.1:9) + prctile(exp_b,97.5),'k--', 'Linewidth', 1.5);
            Z = fill([0:0.1:9 fliplr(0:0.1:9)],[prctile(exp_a,0.5).*(0:0.1:9) + prctile(exp_b,0.5) fliplr(prctile(exp_a,99.5).*(0:0.1:9) + prctile(exp_b,99.5))],'b');
            set(Z,'FaceColor',[0.5 0.5 0.5],'EdgeColor',[0.5 0.5 0.5],'FaceAlpha',0.5,'EdgeAlpha',0.5);
            plot(0:0.1:9, mean(exp_a).*(0:0.1:9) + mean(exp_b),'k', 'Linewidth', 1.5);
        else
%             plot(0:0.1:9, prctile(exp_a,2.5).*exp(prctile(exp_b,2.5).*(0:0.1:9)),'k--', 'Linewidth', 1.5);
%             plot(0:0.1:9, prctile(exp_a,97.5).*exp(prctile(exp_b,97.5).*(0:0.1:9)),'k--', 'Linewidth', 1.5);
            Z = fill([0:0.1:9 fliplr(0:0.1:9)],[prctile(exp_a,0.5).*exp(prctile(exp_b,0.5).*(0:0.1:9)) fliplr(prctile(exp_a,99.5).*exp(prctile(exp_b,99.5).*(0:0.1:9)))],'b');
            set(Z,'FaceColor',[0.5 0.5 0.5],'EdgeColor',[0.5 0.5 0.5],'FaceAlpha',0.5,'EdgeAlpha',0.5);
            plot(0:0.1:9, mean(exp_a).*exp(mean(exp_b).*(0:0.1:9)),'k', 'Linewidth', 1.5);
        end
        plot(dose_well, temp_speed, 'ko', 'MarkerFaceColor', c);
       
        if m == 1
            coeff_baseline = [coeff_baseline; [mean(exp_a) prctile(exp_a, 0.5) prctile(exp_a, 99.5) mean(exp_b) prctile(exp_b, 0.5) prctile(exp_b, 99.5)]];
        elseif m == 2
            coeff_ga = [coeff_ga; [mean(exp_a) prctile(exp_a, 0.5) prctile(exp_a, 99.5) mean(exp_b) prctile(exp_b, 0.5) prctile(exp_b, 99.5)]];
        elseif m == 3
            coeff_recovery = [coeff_recovery; [mean(exp_a) prctile(exp_a, 0.5) prctile(exp_a, 99.5) mean(exp_b) prctile(exp_b, 0.5) prctile(exp_b, 99.5)]];
        end
        
%         i0 = unique(dose_well);
%         for n = 1:length(i0)
%             plot(dose_well(dose_well == i0(n)) + linspace(-lw, lw, size(temp_speed(dose_well == i0(n)),1))', ...
%                 temp_speed(dose_well == i0(n)), 'ko', 'MarkerFaceColor', c);
%             
%             plot(i0(n), mean(temp_speed(dose_well == i0(n))), 'kd', 'MarkerFaceColor', 'k');
%                         
%             b1 = bootstrp(1000, @mean, temp_speed(dose_well == i0(n)));
%             
%             line([i0(n) i0(n)], [prctile(b1, 2.5), prctile(b1, 97.5)],'Color','k', 'Linewidth', 1.5)
%             line([i0(n)-lw i0(n)+lw],[prctile(b1, 2.5) prctile(b1, 2.5)],'Color','k', 'Linewidth', 1.5);
%             line([i0(n)-lw i0(n)+lw],[prctile(b1, 97.5) prctile(b1, 97.5)],'Color','k', 'Linewidth', 1.5);
%         end
%         
%         if m >= 2
%             if length(temp_speed) > 1
%                 f = fit(dose_well,temp_speed,'exp1');
%                 plot(0:0.1:9, f.a .* exp(f.b .* (0:0.1:9)),'k', 'Linewidth', 1.5);
%             end
%         end
        
        xlim([-0.1 8.1]);
        ylim([0 ymax]);
        set(gca,'XTick',[0 0.5 1 1.5 2 3 4 5 6 7 8],'YTick',0:1:10);
        ylabel('Mean Speed (mm/s)');
        xlabel('Sevoflurane %');
        title([S, S2]);
    end
end

for k = [1 2 4 5]
    switch k
        case 1
            S = 'w^{1118} (31+CS) 6x';
            c = [228,26,28]./255;
        case 2
            S = 'HCS';
            c = [55,126,184]./255;
        case 3
            S = 'DL+';
            c = [77,175,74]./255;
        case 4
            S = 'Phinney Ridge';
            c = [152,78,163]./255;
        case 5
            S = 'Top Banana';
            c = [255,127,0]./255;
    end
    
    figure(20);
    subplot(1,3,1);
    hold on; box off;
    Z = fill([0:0.1:9 fliplr(0:0.1:9)],[coeff_baseline(k,2).*(0:0.1:9) + coeff_baseline(k,5) fliplr(coeff_baseline(k,3).*(0:0.1:9) + coeff_baseline(k,6))],'b');
    set(Z,'FaceColor',c,'EdgeColor',c,'FaceAlpha',0.5,'EdgeAlpha',0.5);
    plot(0:0.1:9, coeff_baseline(k,1).*(0:0.1:9) + coeff_baseline(k,4),'k', 'Linewidth', 1);
    xlim([-0.1 8.1]);
    ylim([0 4]);
    set(gca,'XTick',[0 0.5 1 1.5 2 3 4 5 6 7 8],'YTick',0:1:10);
    ylabel('Mean Speed (mm/s)');
    xlabel('Sevoflurane %');
    title('Baseline');
   
    subplot(1,3,2);
    hold on; box off;
    Z = fill([0:0.1:9 fliplr(0:0.1:9)],[coeff_ga(k,2).*exp(coeff_ga(k,5).*(0:0.1:9)) fliplr(coeff_ga(k,3).*exp(coeff_ga(k,6).*(0:0.1:9)))],'b');
    set(Z,'FaceColor',c,'EdgeColor',c,'FaceAlpha',0.5,'EdgeAlpha',0.5);
    plot(0:0.1:9, coeff_ga(k,1).*exp(coeff_ga(k,4).*(0:0.1:9)),'k', 'Linewidth', 1.5);
    xlim([-0.1 8.1]);
    ylim([0 4]);
    set(gca,'XTick',[0 0.5 1 1.5 2 3 4 5 6 7 8],'YTick',0:1:10);
    ylabel('Mean Speed (mm/s)');
    xlabel('Sevoflurane %');
    title('GA');
    
    subplot(1,3,3);
    hold on; box off;
    Z = fill([0:0.1:9 fliplr(0:0.1:9)],[coeff_recovery(k,2).*exp(coeff_recovery(k,5).*(0:0.1:9)) fliplr(coeff_recovery(k,3).*exp(coeff_recovery(k,6).*(0:0.1:9)))],'b');
    set(Z,'FaceColor',c,'EdgeColor',c,'FaceAlpha',0.5,'EdgeAlpha',0.5);
    plot(0:0.1:9, coeff_recovery(k,1).*exp(coeff_recovery(k,4).*(0:0.1:9)),'k', 'Linewidth', 1.5);
    xlim([-0.1 8.1]);
    ylim([0 4]);
    set(gca,'XTick',[0 0.5 1 1.5 2 3 4 5 6 7 8],'YTick',0:1:10);
    ylabel('Mean Speed (mm/s)');
    xlabel('Sevoflurane %');
    title('Recovery');
end
        
% figure(20);
% subplot(1,3,m);
% hold on; box off;
% if m == 1
%     Z = fill([0:0.1:9 fliplr(0:0.1:9)],[prctile(exp_a,0.5).*(0:0.1:9) + prctile(exp_b,0.5) fliplr(prctile(exp_a,99.5).*(0:0.1:9) + prctile(exp_b,99.5))],'b');
%     set(Z,'FaceColor',[0.5 0.5 0.5],'EdgeColor',[0.5 0.5 0.5],'FaceAlpha',0.5,'EdgeAlpha',0.5);
%     plot(0:0.1:9, mean(exp_a).*(0:0.1:9) + mean(exp_b),'k', 'Linewidth', 1.5);
% else
%     Z = fill([0:0.1:9 fliplr(0:0.1:9)],[prctile(exp_a,0.5).*exp(prctile(exp_b,0.5).*(0:0.1:9)) fliplr(prctile(exp_a,99.5).*exp(prctile(exp_b,99.5).*(0:0.1:9)))],'b');
%     set(Z,'FaceColor',[0.5 0.5 0.5],'EdgeColor',[0.5 0.5 0.5],'FaceAlpha',0.5,'EdgeAlpha',0.5);
%     plot(0:0.1:9, mean(exp_a).*exp(mean(exp_b).*(0:0.1:9)),'k', 'Linewidth', 1.5);
% end 
% xlim([-0.1 8.1]);
% ylim([0 4]);
% set(gca,'XTick',[0 0.5 1 1.5 2 3 4 5 6 7 8],'YTick',0:1:10);
% ylabel('Mean Speed (mm/s)');
% xlabel('Sevoflurane %');


cd('/home/jdk20/git/fly-anesthesia-chamber/analysis/');
w = 12;
h = 8;
set(figure(1),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(1),'-dpng','dose_response_curve_ga.png');

set(figure(2),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(2),'-dpng','dose_response_curve_baseline.png');

set(figure(3),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(3),'-dpng','dose_response_curve_recovery.png');

close(figure(1))
close(figure(2))
close(figure(3))

set(figure(10),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(10),'-dpng','6x_bootstrap.png');

set(figure(11),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(11),'-dpng','HCS_bootstrap.png');

set(figure(12),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(12),'-dpng','DL_bootstrap.png');

set(figure(13),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(13),'-dpng','PR_bootstrap.png');

set(figure(14),'PaperPosition',[0 0 w*1.19 h*1.19]);
print(figure(14),'-dpng','TB_bootstrap.png');

set(figure(20),'PaperPosition',[0 0 w*1.19 4*1.19]);
print(figure(20),'-dpng','all_bootstrap.png');



