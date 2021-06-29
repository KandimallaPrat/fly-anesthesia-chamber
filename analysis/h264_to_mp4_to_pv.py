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
# recordings = ['2021-06-10-19-23-34']

for r in recordings:
    datadir = '/local/anesthesia/data/' + r + '/'

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
                n_flies = [int(float(p)) for p in param[1::]]

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

        # ffmpeg cropping wells
        if os.path.isfile(datadir + 'video.h264'):  # Check for .h264 file
            for w in range(1, 7):
                if os.path.isfile(datadir + 'video-c-well-' + str(w) + '.mp4'):  # Check for .mp4 file
                    print('video-c-well-' + str(w) + '.mp4 already exists, skipping conversion')
                else:
                    print('compressing well ' + str(w) + ' from .h264 to .mp4...')

                    if w == 1:
                        x = '0'
                        y = '0'
                    elif w == 2:
                        x = 'in_w/3'
                        y = '0'
                    elif w == 3:
                        x = 'in_w/(2/3)'
                        y = '0'
                    elif w == 4:
                        x = '0'
                        y = 'in_h/2'
                    elif w == 5:
                        x = 'in_w/3'
                        y = 'in_h/2'
                    elif w == 6:
                        x = 'in_w/(2/3)'
                        y = 'in_h/2'

                    s = time()
                    os.system('/usr/bin/ffmpeg -hide_banner -loglevel error -framerate ' + str(frame_rate) +
                              ' -i ' + datadir + 'video.h264 -vf "crop=in_w/3:in_h/2:'
                              + x + ':' + y + '" -c:v h264_nvenc ' + datadir +
                              'video-c-well-' + str(w) + '.mp4')
                    print('converted video using ffmpeg in ' + '{:.1f}'.format(time()-s) + ' seconds')
        else:
            print('video.h264 not found, skipping well compression')

        w = 1
        for nf in n_flies:
            if nf > 0:
                # -----------------------------------------------------------------
                # Convert .mp4 compressed to .pv using tgrabs
                # -----------------------------------------------------------------
                if os.path.isfile(datadir + 'tracking-well-' + str(w) + '.pv'):  # Check for .pv file
                    print('tracking-well-' + str(w) + '.pv already exists')
                elif os.path.isfile(datadir + 'video-c-well-' + str(w) + '.mp4'):  # Check for .mp4 file
                    print('running tgrabs on video-c-well-' + str(w) + '...')
                    s = time()
                    os.system('/home/toor/miniconda3/envs/tracking/bin/tgrabs -i ' + datadir +
                              'video-c-well-' + str(w) + '.mp4 -o ' + datadir +
                              'tracking-well-' + str(w) + ' -threshold 9 -average_samples 100 -averaging_method mode ' +
                              '-meta_real_width 5 -reset_average -nowindow >> ' + datadir + 'tgrabs-' + str(w) + '.log')
                    print('tgrabs completed in ' + '{:.1f}'.format(time() - s) + ' seconds')
                else:
                    print('video-c-well-' + str(w) + '.mp4 not found, nothing to convert')

                # -----------------------------------------------------------------
                # Analyze .pv using trex
                # -----------------------------------------------------------------
                if os.path.isdir(datadir + 'tracking-well-' + str(w)):
                    print('tracking-well-' + str(w) + ' files already found')
                else:
                    print('running trex on video-c-well-' + str(w) + '...')
                    s = time()
                    os.system('/home/toor/miniconda3/envs/tracking/bin/trex -i ' + datadir +
                              'tracking-well-' + str(w) + '.pv -output_dir ' + datadir +
                              ' -track_max_individuals ' + str(nf) +
                              ' -individual_prefix fly -fishdata_dir tracking-well-' + str(w) + ' ' +
                              '-auto_no_results -nowindow -auto_quit >> ' + datadir + 'trex-' + str(w) + '.log')
                    print('trex completed in ' + '{:.1f}'.format(time() - s) + ' seconds')

                # -----------------------------------------------------------------
                # Split npz into npy
                # -----------------------------------------------------------------
                if os.path.isdir(datadir + 'tracking-well-' + str(w)) and len(os.listdir(datadir + 'tracking-well-' + str(w))) > 0:
                    for i in range(0, nf):
                        # Check for tracking files
                        if os.path.isfile(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_fly' + str(i) + '.npz'):
                            # Make tracking npz directory if it doesn't already exist
                            if not os.path.isdir(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_fly' + str(i) + '/'):
                                os.mkdir(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_fly' + str(i) + '/')

                            data = np.load(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_fly' + str(i) + '.npz')
                            for d in data:
                                if not os.path.isfile(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_fly' + str(i) + '/' + d + '.npy'):
                                    np.save(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_fly' + str(i) + '/' + d + '.npy', data[d])

                        # Check for posture files
                        if os.path.isfile(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_posture_fly' + str(i) + '.npz'):
                            # Make posture npz directory if it doesn't already exist
                            if not os.path.isdir(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_posture_fly' + str(i) + '/'):
                                os.mkdir(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_posture_fly' + str(i) + '/')

                            data = np.load(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_posture_fly' + str(i) + '.npz')
                            for d in data:
                                if not os.path.isfile(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_posture_fly' + str(i) + '/' + d + '.npy'):
                                    np.save(datadir + 'tracking-well-' + str(w) + '/tracking-well-' + str(w) + '_posture_fly' + str(i) + '/' + d + '.npy', data[d])
            w = w + 1

    print('')
