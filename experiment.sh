#!/usr/bin/env bash

# python startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 10
# --t_motor_on --motor_duration --t_led_on --led_duration

python startup.py --datadir /media/pi/Elements/anesthesia-reanimation/data/ --t_experiment 10800 --t_motor_on 1800 3600 5400 6300 7200 8100 8400 8700 9000 --motor_duration 30 30 30 30 30 30 30 30 30
