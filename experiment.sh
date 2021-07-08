#!/usr/bin/env bash

# Experiment
echo EXPERIMENT
# /usr/bin/python3 startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 300 --n_flies 0 0 0 0 0 0 # Test exp
# /usr/bin/python3 startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 30 --n_flies 0 0 0 0 0 0 --t_motor_on 15 --motor_duration 10
/usr/bin/python3 startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 4800 --n_flies 0 0 2 1 2 2 --t_motor_on 2700 --motor_duration 5
# /usr/bin/python3 startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 5400 --n_flies 6 --t_motor_on 1800 3600  --motor_duration 10 10

# Transfer to Synology
echo TRANSFER
bash /home/pi/recording/transfer_data.sh
echo

# Run "remote" analysis
echo ANALYSIS
# /usr/bin/python3 /home/pi/recording/analysis/process_data.py
