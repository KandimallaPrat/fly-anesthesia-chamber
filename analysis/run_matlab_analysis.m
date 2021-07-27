clc; clear variables; close all;

datadir = '/local/anesthesia/data/';

d = dir(datadir);

% Protocol 1 time
th = datetime('2021-07-11-12-00-00', 'InputFormat', 'yyyy-MM-dd-HH-mm-ss');

for i = 1:length(d)
     if ~strcmp(d(i).name, '.') && ~strcmp(d(i).name, '..')
        d(i).init = datetime(d(i).name, 'InputFormat', 'yyyy-MM-dd-HH-mm-ss');
        
        % Grab experiments after Protocol 1
        if d(i).init >= th
            
            % Check if tracking files exist
            cd([datadir, d(i).name]);
            dd = dir([datadir, d(i).name]);
            
            tc = 0; % tracked directory counter
            for j = 1:length(dd)
                if dd(j).isdir
                    if ~isempty(strfind(dd(j).name,'tracking-well-'))
                        tc = tc + 1;
                    end
                end
            end
            
            % if all 6 wells are tracked
            if tc == 6
                create_tracked_figure(d(i).name);
                create_tracked_video(d(i).name);
            end
        end
     end
end