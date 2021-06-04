import os
import numpy as np

from time import time

recordings = ['2021-05-31-17-01-41', '2021-05-31-20-27-29', '2021-05-31-23-53-30']

for r in recordings:
    datadir = '/mnt/anesthesia/data/' + r + '/'

    # -----------------------------------------------------------------
    # Convert any .h264 to .mp4 using ffmpeg
    # -----------------------------------------------------------------
    print(datadir)
    '''
    # Lazy way to read in frame rate value
    if os.path.isfile(datadir + 'info.txt'):
        info = np.genfromtxt(datadir + 'info.txt', delimiter=',')
    '''
    frame_rate = 60
    n_flies = 30

    # ffmpeg compression (about 90%)
    if os.path.isfile(datadir + 'video.h264'):  # Check for .h264 file
        if os.path.isfile(datadir + 'video-c.mp4'):  # Check for .mp4 file
            print('video-c.mp4 already exists, skipping conversion')
        else:
            print('compressing .h264 to .mp4...')
            s = time()
            os.system('ffmpeg -hide_banner -loglevel error -framerate ' + str(frame_rate) +
                      ' -i ' + datadir + 'video.h264 ' + datadir + 'video-c.mp4')
            print('converted video using ffmpeg in ' + '{:.1f}'.format(time()-s) + ' seconds')
    else:
        print('video.h264 not found, skipping compression')

    # -----------------------------------------------------------------
    # Convert .mp4 compressed to .pv using tgrabs
    # -----------------------------------------------------------------
    if os.path.isfile(datadir + 'tracking.pv'):  # Check for .pv file
        print('tracking.pv already exists')
    elif os.path.isfile(datadir + 'video-c.mp4'):  # Check for .mp4 file
        print('running tgrabs...')
        s = time()
        os.system('/home/jdk20/miniconda3/envs/tracking/bin/tgrabs -i ' + datadir +
                  'video-c.mp4 -o ' + datadir +
                  'tracking -threshold 9 -average_samples 100 -averaging_method mode ' +
                  '-meta_real_width 15 -reset_average -nowindow >> ' + datadir + 'tgrabs.log')
        print('tgrabs completed in ' + '{:.1f}'.format(time() - s) + ' seconds')
    else:
        print('video-c.mp4 not found, nothing to convert')

    # -----------------------------------------------------------------
    # Analyze .pv using trex
    # -----------------------------------------------------------------
    if os.path.isdir(datadir + 'tracking'):
        print('tracking files already found')
    else:
        print('running trex...')
        s = time()
        os.system('/home/jdk20/miniconda3/envs/tracking/bin/trex -i ' + datadir + 'tracking.pv -output_dir ' + datadir +
                  ' -track_max_individuals ' + str(n_flies) +
                  ' -individual_prefix fly -output_posture_data true -fishdata_dir tracking ' +
                  '-auto_no_results -nowindow -auto_quit >> ' + datadir + 'trex.log')
        print('trex completed in ' + '{:.1f}'.format(time() - s) + ' seconds')
