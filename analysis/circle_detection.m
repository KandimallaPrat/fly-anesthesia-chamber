clc; close all;

cd('/local/anesthesia/data/2021-07-09-15-41-47');

vr = VideoReader('video-c.mp4');
a = read(vr,1);

rng(42);
[centers, radii, metric] = imfindcircles(a, [150 200],'Sensitivity',0.97,'Method','TwoStage');

i0 = [5 4 3 6 1 2];
centers = centers(i0,:);
radii = radii(i0,:);
metric = metric(i0,:);

k1 = 175;
k2 = 2*k1;

tl = centers - k1;

image(a); hold on;
viscircles(centers, radii,'Color','b');
for i = 1:size(centers,1)
    text(centers(i,1),centers(i,2),num2str(i));
    rectangle('Position',[tl(i,1),tl(i,2),k2,k2]);
end

for i = 1:size(centers,1)
    if i == 1
        disp('if w == 1');
    else
        disp(['elif w == ', num2str(i)]);
    end
    
    disp(['    x = ''', num2str(round(tl(i,1))),''''])
    disp(['    y = ''', num2str(round(tl(i,2))),''''])
    disp(['    wi = ''', num2str(k2),''''])
    disp(['    he = ''', num2str(k2),''''])
end