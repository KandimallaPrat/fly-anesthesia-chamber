import os
import shutil
from datetime import datetime

# Contains folders to backup
datadir = '/local/anesthesia/data'
backup_dir = '/local/anesthesia/data-backup'
start_date = datetime.strptime('2021-07-11-12-00-00', '%Y-%m-%d-%H-%M-%S')

for sd in os.listdir(datadir):
    # Check if video.h264 exists
    if os.path.isfile(datadir + '/' + sd + '/video.h264'):
        vs = os.path.getsize(datadir + '/' + sd + '/video.h264')/(10**6)

        sd_date = datetime.strptime(sd, '%Y-%m-%d-%H-%M-%S')

        # Check if video is >300 MB and after 7-11-2021 (Protocol 1)
        if vs > 300 and sd_date > start_date:
            print('Session:', datadir + '/' + sd)

            # RSYNC files under 10MB
            os.system('rsync -aPq --max-size=10m ' + datadir + '/' + sd + ' ' + backup_dir)

            # Transfer video.h264
            if not os.path.isfile(backup_dir + '/' + sd + '/video.h264'):
                print('Copying video.h264...')
                shutil.copy2(datadir + '/' + sd + '/video.h264', backup_dir + '/' + sd + '/video.h264')
            else:
                print('video.h264 found')

            # Compress
            if not os.path.isfile(backup_dir + '/' + sd + '.tar.gz'):
                print('Compressing .tar.gz...')
                os.system('tar -czf ' + backup_dir + '/' + sd + '.tar.gz ' + backup_dir + '/' + sd)
            else:
                print('.tar.gz found')
