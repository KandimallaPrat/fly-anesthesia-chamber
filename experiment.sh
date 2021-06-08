#!/usr/bin/env bash

# python startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 10

python startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 21600 --n_flies 30 --t_motor_on 3600 5400 7200 9000 12600 16200 19800  --motor_duration 5 5 5 5 10 10 10

bash /home/pi/anesthesia-reanimation/transfer_data.sh
# ssh jdk20@10.0.0.7 "bash /home/remy/Documents/fly-anesthesia-chamber/analysis/process_data.sh"