#!/usr/bin/env bash

# Experiment
echo EXPERIMENT
/usr/bin/python3 startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 7200 --n_flies 5 5 5 5 5 5 --t_motor_on 2400 2405 2410 2415 2420 2700 2705 2710 2715 2720 3000 3005 3010 3015 3020 --motor_duration 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1

# Transfer to Synology
echo TRANSFER
bash /home/pi/recording/transfer_data.sh
echo

# Run "remote" analysis
echo ANALYSIS
/usr/bin/python3 /home/pi/recording/analysis/process_data.py
