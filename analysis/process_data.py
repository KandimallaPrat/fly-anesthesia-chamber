import os
print("Processing data...")
datadir = '/media/pi/Elements/anesthesia-reanimation/data/'
recordings = os.listdir(datadir)
r = recordings[-1]  # Should be latest directory

# t = []
# for r in recordings:
#     t.append(os.path.getmtime(datadir + r))
print("Sending ssh command...")
# Send to HAL
os.system('ssh toor@10.0.0.5 "/home/toor/miniconda3/envs/tracking/bin/python ' +
          '/home/jdk20/git/fly-anesthesia-chamber/analysis/h264_to_mp4_to_pv.py --recordings ' + r + '"')

# Create figures
# os.system('ssh toor@10.0.0.5 "/usr/local/MATLAB/R2021a/bin/matlab -nodisplay -nosplash -nodesktop -r "try, cd(\'/home/jdk20/git/fly-anesthesia-chamber/analysis\'), create_tracked_figure(\'' + r + '\'), catch, exit, end, exit""')

# Create tracked video
# os.system('ssh toor@10.0.0.5 "/usr/local/MATLAB/R2021a/bin/matlab -nodisplay -nosplash -nodesktop -r "try, cd(\'/home/jdk20/git/fly-anesthesia-chamber/analysis\'), create_tracked_video(\'' + r + '\'), catch, exit, end, exit""')
