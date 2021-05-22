import os
import numpy as np
import argparse
import gpiozero

from time import time, sleep, localtime, strftime
from operator import add, sub

# ser = serial.Serial(port='/dev/ttyUSB0', baudrate=19200, parity=serial.PARITY_EVEN, stopbits=serial.STOPBITS_ONE, bytesize=serial.EIGHTBITS, timeout=60, rtscts=True)
# s = ser.read(1000)

# ----------------------------------------------------------------------------------------------------------------------
# Arguments
# ----------------------------------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='fly-anesthesia')
parser.add_argument('--datadir', type=str, required=False, default='data/')
parser.add_argument('--t_experiment', type=float, required=False, default=300)
parser.add_argument('--t_motor_on', type=float, nargs='+', required=False, default=[30, 220])
parser.add_argument('--motor_duration', type=float, nargs='+', required=False, default=[30, 20])
parser.add_argument('--t_led_on', type=float, nargs='+', required=False, default=[150])
parser.add_argument('--led_duration', type=float, nargs='+', required=False, default=[15])
args = parser.parse_args()

# Over ride inputs
datadir = args.datadir
t_experiment = args.t_experiment  # all in seconds
t_motor_on = args.t_motor_on
motor_duration = args.motor_duration
t_led_on = args.t_led_on
led_duration = args.led_duration

# ----------------------------------------------------------------------------------------------------------------------
# Argument checking
# ----------------------------------------------------------------------------------------------------------------------
# Directory does not exist
if datadir[-1] != '/':
    datadir = datadir + '/'

datadir = datadir + strftime("%Y-%m-%d-%H-%M-%S", localtime()) + '/'

if os.path.isdir(datadir):
    raise ValueError('Experiment directory already exists.')
else:
    os.mkdir(datadir)

# Non-negative
if t_experiment <= 0:
    raise ValueError('Experiment length must be non-negative.')

if t_motor_on:
    if min(t_motor_on) <= 0 or min(motor_duration) <= 0:
        raise ValueError('Time values must be non-negative.')

if t_led_on:
    if min(t_led_on) <= 0 or min(led_duration) <= 0:
        raise ValueError('Time values must be non-negative.')

# Same length
if len(t_motor_on) != len(motor_duration) or len(t_led_on) != len(led_duration):
    raise ValueError('Motor or LED start times need a matching duration.')

# Within experimental length
if t_motor_on:
    if max(t_motor_on + motor_duration) > t_experiment:
        raise ValueError('Motor start times cannot exceed experimental length.')

if t_led_on:
    if max(t_led_on + led_duration) > t_experiment:
        raise ValueError('LED start times cannot exceed experimental length.')

# In order
a = t_motor_on[:]
b = t_led_on[:]
a.sort()
b.sort()
if a != t_motor_on or b != t_led_on:
    raise ValueError('Motor or LED start times need to be in order.')

# Non-overlapping
a = list(map(add, t_motor_on, motor_duration))
b = list(map(add, t_led_on, led_duration))
if t_motor_on:
    if len(t_motor_on) > 1:
        if min(list(map(sub, t_motor_on[1::], a[0:-1]))) <= 0:
            raise ValueError('Motor times cannot overlap.')

if t_led_on:
    if len(t_led_on) > 1:
        if min(list(map(sub, t_led_on[1::], b[0:-1]))) <= 0:
            raise ValueError('LED times cannot overlap.')


# Switch to numpy
t_motor_on = np.array([t_motor_on])
motor_duration = np.array([motor_duration])
t_led_on = np.array([t_led_on])
led_duration = np.array([led_duration])

# ----------------------------------------------------------------------------------------------------------------------
# Start camera
# ----------------------------------------------------------------------------------------------------------------------
use_camera = True
if use_camera:
    from picamera import PiCamera
    camera = PiCamera()
    camera.start_recording(datadir + 'video.h264')
else:
    frame_index = 0

# Internal values
verbose = True
frame_rate = 30  # Hard coded for camera

start_time = time()
frame_time = 0
current_frame_index = -1
motor_status = 0
led_status = 0

# Start logging
log_info = open(datadir + 'info.txt', 'a')
log_info.write('Start: ' + str(start_time) + '\n')
log_info.write('Duration: ' + str(t_experiment) + '\n')
log_info.write('Motor: ' + str(t_motor_on) + '\n')
log_info.write('Motor duration: ' + str(motor_duration) + '\n')
log_info.write('LED: ' + str(t_led_on) + '\n')
log_info.write('LED duration: ' + str(led_duration) + '\n')
log_info.close()

log_dose = open(datadir + 'dose.txt', 'a')
log_dose.close()

while frame_time < t_experiment:
    if use_camera:
        frame_complete = camera.frame.complete
        frame_time = camera.frame.timestamp  # in microseconds

        if frame_time is None:
            frame_time = 0

        frame_time = float(frame_time)/(10**6)  # convert from long us to float s
    else:
        frame_complete = True
        frame_time = (time() - start_time)

    if use_camera:
        frame_index = camera.frame.index
        frame_type = camera.frame.frame_type  # 0 frame, 1 keyframe, 2 SPS, 3 motion
        frame_size = camera.frame.frame_size  # in bytes
    else:
        frame_index += 1
        frame_type = 0
        frame_size = 5

    # Camera
    # Check if current frame is finished being written
    if frame_complete:
        # Initial frame
        if current_frame_index == -1:
            current_frame_index = frame_index

        else:
            if current_frame_index != frame_index:
                current_frame_index = frame_index

                if frame_type == 0:
                    ft = 'frame'
                elif frame_type == 1:
                    ft = 'keyframe'
                elif frame_type == 2:
                    ft = 'SPS'
                elif frame_type == 3:
                    ft = 'motion'
                else:
                    ft = 'unknown'

                # Sync all actions with frame or keyframe
                if ft == 'frame' or ft == 'keyframe':
                    t = start_time + frame_time  # Add Unix time

                    # Motor on/off
                    if np.any(np.logical_and(frame_time > t_motor_on, frame_time < (t_motor_on + motor_duration))):
                        # Make sure motor is on
                        motor_status = 1
                        motor_voltage = 5
                    else:
                        # Make sure motor is off
                        motor_status = 0
                        motor_voltage = 0

                    # LED on/off
                    if np.any(np.logical_and(frame_time > t_led_on, frame_time < (t_led_on + led_duration))):
                        # Make sure motor is on
                        led_status = 1
                        led_voltage = 3
                    else:
                        # Make sure motor is off
                        led_status = 0
                        led_voltage = 0

                    # Logging
                    log_index = open(datadir + 'index.txt', 'a')
                    log_index.write(str(frame_index) + '\n')
                    log_index.close()

                    log_ts = open(datadir + 'timestamps.txt', 'a')
                    log_ts.write(str(t) + '\n')
                    log_ts.close()

                    log_frame_type = open(datadir + 'frame-type.txt', 'a')
                    log_frame_type.write(str(frame_type) + '\n')
                    log_frame_type.close()

                    log_motor = open(datadir + 'motor-status.txt', 'a')
                    log_motor.write(str(motor_status) + '\n')
                    log_motor.close()

                    log_motor_volt = open(datadir + 'motor-voltage.txt', 'a')
                    log_motor_volt.write(str(motor_voltage) + '\n')
                    log_motor_volt.close()

                    log_led = open(datadir + 'led-status.txt', 'a')
                    log_led.write(str(led_status) + '\n')
                    log_led.close()

                    log_led_volt = open(datadir + 'led-voltage.txt', 'a')
                    log_led_volt.write(str(led_voltage) + '\n')
                    log_led_volt.close()

                # Verbose output
                if verbose:
                    if (frame_index % frame_rate) == 0:
                        if motor_status == 1:
                            ms = 'on'
                        else:
                            next_event = t_motor_on[t_motor_on > frame_time]
                            if next_event.size == 0:
                                ms = 'off'
                            else:
                                ms = 'in ' + '{:.1f}'.format(next_event[0] - frame_time)

                        if led_status == 1:
                            leds = 'on'
                        else:
                            next_event = t_led_on[t_led_on > frame_time]
                            if next_event.size == 0:
                                leds = 'off'
                            else:
                                leds = 'in ' + '{:.1f}'.format(next_event[0] - frame_time)

                        print('(Frame ' + str(frame_index) + ')' + ' Time ' + '{:.1f}'.format(frame_time) +
                              ', Remaining ' + '{:.1f}'.format(t_experiment - frame_time) +
                              ', Dose N/A, Motor ' + ms + ', LED ' + leds)

    sleep(1./(2*frame_rate))  # Only check camera at the nyquist rate

if use_camera:
    camera.stop_recording
    camera.close()

if verbose:
    print('Wall time ' + '{:.1f}'.format(time() - start_time))
