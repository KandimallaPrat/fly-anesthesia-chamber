import os

datadir = '/media/pi/Elements/anesthesia-reanimation/data/'
recordings = os.listdir(datadir)
r = recordings[-1]  # Should be latest directory

# t = []
# for r in recordings:
#     t.append(os.path.getmtime(datadir + r))

os.system('ssh jdk20@10.0.0.7 "/home/jdk20/miniconda3/envs/tracking/bin/python ' +
          '/home/jdk20/Documents/MATLAB/fly-anesthesia-chamber/analysis/h264_to_mp4_to_pv.py --recordings ' + r + '"')
