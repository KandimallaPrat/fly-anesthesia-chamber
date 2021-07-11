#!/usr/bin/env bash

# Experiment
echo EXPERIMENT
/usr/bin/python3 startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 7200 --n_flies 3 3 3 3 3 3 --t_motor_on 2400 2405 2410 2415 2420 2700 2705 2710 2715 2720 3000 3005 3010 3015 3020 3600 3605 3610 3615 3620 3900 3905 3910 3915 3920 4200 4205 4210 4215 4220 4500 4505 4510 4515 4520 4800 4805 4810 4815 4820 5100 5105 5110 5115 5120 --motor_duration 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1

# Transfer to Synology
echo TRANSFER
bash /home/pi/recording/transfer_data.sh
echo

# Run "remote" analysis
echo ANALYSIS
/usr/bin/python3 /home/pi/recording/analysis/process_data.py
