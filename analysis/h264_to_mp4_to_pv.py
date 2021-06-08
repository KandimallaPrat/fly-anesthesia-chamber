import os
import numpy as np
import argparse

from time import time

# ----------------------------------------------------------------------------------------------------------------------
# Arguments
# ----------------------------------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='fly-anesthesia-analysis')
parser.add_argument('--recordings', type=str, required=False, default=[])
args = parser.parse_args()

# Override inputs
recordings = [args.recordings]

# TODO: Create basic plots
# TODO: bash script to run this
# TODO: Redo motor placement and motor on LED
# TODO: Anesthesia monitor recording
# TODO: Fly well labels

for r in recordings:
    datadir = '/mnt/anesthesia/data/' + r + '/'

    # -----------------------------------------------------------------
    # Convert any .h264 to .mp4 using ffmpeg
    # -----------------------------------------------------------------
    print(datadir)
    # Lazy way to read in frame rate value
    if os.path.isfile(datadir + 'info.txt'):
        info = open(datadir + 'info.txt', 'r')
        for param in info:
            param = param.replace('\n', '').split(',')
            if param[0] == 'frame-rate':
                frame_rate = int(float(param[1]))
            elif param[0] == 'n-flies':
                n_flies = int(float(param[1]))

        print('framerate: ' + str(frame_rate))
        print('n_flies: ' + str(n_flies))

        # ffmpeg compression
        if os.path.isfile(datadir + 'video.h264'):  # Check for .h264 file
            if os.path.isfile(datadir + 'video-c.mp4'):  # Check for .mp4 file
                print('video-c.mp4 already exists, skipping conversion')
            else:
                print('compressing .h264 to .mp4...')
                s = time()
                os.system('/usr/bin/ffmpeg -hide_banner -loglevel error -framerate ' + str(frame_rate) +
                          ' -i ' + datadir + 'video.h264 -c:v h264_nvenc ' + datadir + 'video-c.mp4')
                print('converted video using ffmpeg in ' + '{:.1f}'.format(time()-s) + ' seconds')
        else:
            print('video.h264 not found, skipping compression')

        if n_flies > 0:
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
                          ' -individual_prefix fly -fishdata_dir tracking ' +
                          '-auto_no_results -nowindow -auto_quit >> ' + datadir + 'trex.log')
                print('trex completed in ' + '{:.1f}'.format(time() - s) + ' seconds')

            # -----------------------------------------------------------------
            # Split npz into npy
            # -----------------------------------------------------------------
            if os.path.isdir(datadir + 'tracking') and len(os.listdir(datadir + 'tracking')) > 0:
                for i in range(0, n_flies):
                    # Check for tracking files
                    if os.path.isfile(datadir + 'tracking/tracking_fly' + str(i) + '.npz'):
                        # Make tracking npz directory if it doesn't already exist
                        if not os.path.isdir(datadir + 'tracking/tracking_fly' + str(i) + '/'):
                            os.mkdir(datadir + 'tracking/tracking_fly' + str(i) + '/')

                        data = np.load(datadir + 'tracking/tracking_fly' + str(i) + '.npz')
                        for d in data:
                            if not os.path.isfile(datadir + 'tracking/tracking_fly' + str(i) + '/' + d + '.npy'):
                                np.save(datadir + 'tracking/tracking_fly' + str(i) + '/' + d + '.npy', data[d])

                    # Check for posture files
                    if os.path.isfile(datadir + 'tracking/tracking_posture_fly' + str(i) + '.npz'):
                        # Make posture npz directory if it doesn't already exist
                        if not os.path.isdir(datadir + 'tracking/tracking_posture_fly' + str(i) + '/'):
                            os.mkdir(datadir + 'tracking/tracking_posture_fly' + str(i) + '/')

                        data = np.load(datadir + 'tracking/tracking_posture_fly' + str(i) + '.npz')
                        for d in data:
                            if not os.path.isfile(datadir + 'tracking/tracking_posture_fly' + str(i) + '/' + d + '.npy'):
                                np.save(datadir + 'tracking/tracking_posture_fly' + str(i) + '/' + d + '.npy', data[d])

    print('')
