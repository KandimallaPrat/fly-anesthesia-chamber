#!/usr/bin/env bash

# Experiment
echo EXPERIMENT
/usr/bin/python3 startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 20 --n_flies 0 0 0 0 0 0 --t_motor_on 10 --motor_duration 5

# Transfer to Synology
echo TRANSFER
bash /home/pi/recording/transfer_data.sh
echo

# Run "remote" analysis
echo ANALYSIS
# /usr/bin/python3 /home/pi/recording/analysis/process_data.py
