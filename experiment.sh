#!/usr/bin/env bash

# Experiment
echo EXPERIMENT
python startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 10 --n_flies 0 # Test exp.
# python startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 21600 --n_flies 30 --t_motor_on 3600 5400 7200 9000 12600 16200 19800  --motor_duration 5 5 5 5 10 10 10

# Transfer to Synology
echo TRANSFER
bash /home/pi/anesthesia-reanimation/transfer_data.sh

# Run "remote" analysis
ssh jdk20@10.0.0.7 "/home/jdk20/miniconda3/envs/tracking/bin/python /home/remy/Documents/fly-anesthesia-chamber/analysis/h264_to_mp4_to_pv.py"