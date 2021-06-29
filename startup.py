import os
import numpy as np
import argparse
import subprocess

from gpiozero import PWMOutputDevice
from time import time, sleep, localtime, strftime
from operator import add, sub

# ----------------------------------------------------------------------------------------------------------------------
# Arguments
# ----------------------------------------------------------------------------------------------------------------------
parser = argparse.ArgumentParser(description='fly-anesthesia')
parser.add_argument('--datadir', type=str, required=False, default='/media/pi/Elements/anesthesia-reanimation/data/')
parser.add_argument('--t_experiment', type=float, required=False, default=10)
parser.add_argument('--n_flies', type=float, nargs='+', required=False, default=[0])
parser.add_argument('--t_motor_on', type=float, nargs='+', required=False, default=[])
parser.add_argument('--motor_duration', type=float, nargs='+', required=False, default=[])
parser.add_argument('--t_led_on', type=float, nargs='+', required=False, default=[])
parser.add_argument('--led_duration', type=float, nargs='+', required=False, default=[])
parser.add_argument('--selfcheck', type=bool, required=False, default=False)
args = parser.parse_args()

# Override inputs
datadir = args.datadir
n_flies = args.n_flies
t_experiment = args.t_experiment  # all in seconds
t_motor_on = args.t_motor_on
motor_duration = args.motor_duration
t_led_on = args.t_led_on
led_duration = args.led_duration
write_data = not args.selfcheck

# ----------------------------------------------------------------------------------------------------------------------
# Argument checking
# ----------------------------------------------------------------------------------------------------------------------
# Number of flies should be in a list
if not isinstance(n_flies, list):
    n_flies = [n_flies]

# Directory does not exist
if datadir[-1] != '/':
    datadir = datadir + '/'

exp_time = strftime("%Y-%m-%d-%H-%M-%S", localtime())
datadir = datadir + exp_time + '/'
os.environ["EXP_TIME"] = exp_time

if write_data:
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
frame_rate = 30  # Hard coded for resolution
# 1920x1080 at 30
# 1280x720 at 60
# 640x480 at 90

if use_camera:
    from picamera import PiCamera
    camera = PiCamera()
    camera.color_effects = (128, 128)
    camera.framerate = frame_rate
    camera.resolution = (1920, 1080)
    # camera.awb_mode = 'off'
    # camera.zoom = (0, 0, 1.0, 1.0) # x, y, w, h
    # camera.exposure_mode = 'backlight'
    if write_data:
        camera.start_recording(datadir + 'video.h264')
    else:
        camera.start_recording('selfcheck.h264')
else:
    frame_index = 0

# ----------------------------------------------------------------------------------------------------------------------
# Start GA monitor
# ----------------------------------------------------------------------------------------------------------------------
use_monitor = True

if use_monitor:
    # Start monitor, remove any previous csv files
    if os.path.isfile('/home/pi/recording/AS3DataExport.csv'):
        os.system('rm /home/pi/recording/AS3DataExport.csv')

    if os.path.isfile('/home/pi/recording/AS3Rawoutput1.raw'):
        os.system('rm /home/pi/recording/AS3Rawoutput1.raw')

    # Start up Datex Ohmeda S/5 monitor
    # Error check here to see if /dev/ttyUSB0 is open
    dev_check = os.system('ls /dev/ttyUSB0')
    if dev_check == 0:
        log_monitor = open(datadir + 'log-monitor.txt', 'a')

        monitor = subprocess.Popen(["/usr/bin/mono", "/home/pi/recording/VSCapture.exe", "-port", "/dev/ttyUSB0",
                                    "-interval", "5", "-export", "1", "-waveset", "0"], stdout=log_monitor, stderr=subprocess.STDOUT)
    else:
        use_monitor = False
        print('No connected device found at /dev/ttyUSB0, disabling monitor readout')

    # List for holding monitor outputs
    mr = [-1, -1, -1]

# ----------------------------------------------------------------------------------------------------------------------
# Add motors
# ----------------------------------------------------------------------------------------------------------------------
# Door
# 2_1   2_2
# 1_2   2_3
# 1_1   1_3
# Chamber back

motor_1_1 = PWMOutputDevice(12, active_high=True, initial_value=0)  # Connector 1, Red/Orange
motor_1_2 = PWMOutputDevice(1, active_high=True, initial_value=0)  # Connector 1, Yellow/Green
motor_1_3 = PWMOutputDevice(7, active_high=True, initial_value=0)  # Connector 1, Blue/Purple
motor_2_1 = PWMOutputDevice(26, active_high=True, initial_value=0)  # Connector 2, Red/Orange
motor_2_2 = PWMOutputDevice(19, active_high=True, initial_value=0)  # Connector 2, Yellow/Green
motor_2_3 = PWMOutputDevice(13, active_high=True, initial_value=0)  # Connector 2, Blue/Purple

motors = [motor_1_1, motor_1_2, motor_1_3, motor_2_1, motor_2_2, motor_2_3]

# Internal values
verbose = True
start_time = time()
frame_time = 0
current_frame_index = -1
motor_status = 0
led_status = 0

if write_data:
    # Start logging
    log_info = open(datadir + 'info.txt', 'a')
    log_info.write('start,' + str(start_time) + '\n')
    log_info.write('duration,' + str(t_experiment) + '\n')
    log_info.write('frame-rate,' + str(frame_rate) + '\n')

    snf = ''
    for nf in n_flies:
        snf = snf + str(nf) + ','
    snf = snf[0:-1]
    log_info.write('n-flies,' + snf + '\n')

    b = ''
    for a in t_motor_on[0, :]:
        b = b + ',' + str(a)
    log_info.write('motor' + b + '\n')

    b = ''
    for a in motor_duration[0, :]:
        b = b + ',' + str(a)
    log_info.write('motor-duration' + b + '\n')

    b = ''
    for a in t_led_on[0, :]:
        b = b + ',' + str(a)
    log_info.write('led' + b + '\n')

    b = ''
    for a in led_duration[0, :]:
        b = b + ',' + str(a)
    log_info.write('led-duration' + b + '\n')

    log_info.close()

    if use_monitor:
        log_mac = open(datadir + 'ga-mac.txt', 'a')
        log_mac.close()

        log_dose = open(datadir + 'dose.txt', 'a')
        log_dose.close()

        log_o2 = open(datadir + 'oxygen.txt', 'a')
        log_o2.close()

while frame_time < t_experiment:
    if use_camera:
        frame_complete = camera.frame.complete
        frame_time = camera.frame.timestamp  # in microseconds

        if frame_time is None:
            frame_time = 0

        frame_time = (float(frame_time)/(10**6))  # convert from long us to float s
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
                        for motor in motors:
                            motor.on()

                        motor_status = 1
                        motor_voltage = 3.3
                    else:
                        # Make sure motor is off
                        for motor in motors:
                            motor.off()

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

                    if use_monitor:
                        # Only every 2.5 seconds
                        # Check time since last sample, if >10 seconds, kill process and restart vscapture
                        if (frame_index % int(2.5*frame_rate)) == 0:
                            if os.path.isfile('/home/pi/recording/AS3DataExport.csv'):
                                # Check if monitor hasn't produced a sample in 20 seconds
                                if (time() - os.path.getmtime('/home/pi/recording/AS3DataExport.csv')) < 20:
                                    os.system('cp /home/pi/recording/AS3DataExport.csv ' + datadir + 'AS3DataExport.csv')
                                    os.system('cp /home/pi/recording/AS3Rawoutput1.raw ' + datadir + 'AS3Rawoutput1.raw')

                                    # Will return nan values for header strings
                                    mr = np.genfromtxt('/home/pi/recording/AS3DataExport.csv', skip_header=1,
                                                       usecols=(9, 11, 8), delimiter=',')  # MAC, O2, Dose

                                    # Lazy numpy array check
                                    try:
                                        mr = mr[-1, :]
                                    except:
                                        pass
                                else:
                                    # Kill monitor process and restart
                                    monitor.kill()

                                    dev_check = os.system('ls /dev/ttyUSB0')
                                    if dev_check == 0:
                                        log_monitor.write('Monitor crash detected, killing process and restarting...\n')
                                        print('Monitor crash detected, killing process and restarting...')
                                        monitor = subprocess.Popen(
                                            ["/usr/bin/mono", "/home/pi/recording/VSCapture.exe", "-port", "/dev/ttyUSB0",
                                             "-interval", "5", "-export", "1", "-waveset", "0"], stdout=log_monitor, stderr=subprocess.STDOUT)
                                    else:
                                        log_monitor.write('Monitor not responding, killing process. ' +
                                                          '/dev/ttyUSB0 not found, monitor disconnected?\n')
                                        print('Monitor not responding, killing process. ' +
                                              '/dev/ttyUSB0 not found, monitor disconnected?')
                                        use_monitor = False

                            else:
                                # Monitor not writing correctly, check if /dev/ttyUSB0 exists
                                mr = [-1, -1, -1]

                    if write_data:
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

                        if use_monitor:
                            log_mac = open(datadir + 'ga-mac.txt', 'a')
                            log_mac.write(str(mr[0]) + '\n')
                            log_mac.close()

                            log_dose = open(datadir + 'dose.txt', 'a')
                            log_dose.write(str(mr[2]) + '\n')
                            log_dose.close()

                            log_o2 = open(datadir + 'oxygen.txt', 'a')
                            log_o2.write(str(mr[1]) + '\n')
                            log_o2.close()

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

                        if use_monitor:
                            print('(Frame ' + str(frame_index) + ')' + ' Time ' + '{:.1f}'.format(frame_time) +
                                  ', Remaining ' + '{:.1f}'.format(t_experiment - frame_time) +
                                  ', Motor ' + ms + ', LED ' + leds + ', O2 ' +
                                  str(mr[1]) + ', MAC ' + str(mr[0]) + ', Dose ' + str(mr[2]))
                        else:
                            print('(Frame ' + str(frame_index) + ')' + ' Time ' + '{:.1f}'.format(frame_time) +
                                  ', Remaining ' + '{:.1f}'.format(t_experiment - frame_time) +
                                  ', Motor ' + ms + ', LED ' + leds)

    sleep(1./(2*frame_rate))  # Only check camera at the nyquist rate

if use_camera:
    camera.stop_recording
    camera.close()

if use_monitor:
    os.system('mv /home/pi/recording/AS3DataExport.csv ' + datadir + 'AS3DataExport.csv')
    os.system('mv /home/pi/recording/AS3Rawoutput1.raw ' + datadir + 'AS3Rawoutput1.raw')
    monitor.kill()
    log_monitor.close()

if write_data:
    log_info = open(datadir + 'info.txt', 'a')
    log_info.write('end,' + str(time()) + '\n')
    log_info.close()

    no_errors = open(datadir + 'no_errors.txt', 'a')
    no_errors.close()

if verbose:
    print('Wall time ' + '{:.1f}'.format(time() - start_time))
    print('\n')

# Convert txt files to numpy arrays
if write_data:
    for i in ['index', 'timestamps', 'frame-type', 'motor-status', 'motor-voltage', 'led-status', 'led-voltage']:
        temp = np.loadtxt(datadir + i + '.txt', dtype=float)
        np.save(datadir + i + '.npy', temp)

    if use_monitor:
        for i in ['oxygen', 'ga-mac', 'dose']:
            temp = np.loadtxt(datadir + i + '.txt', dtype=float)
            np.save(datadir + i + '.npy', temp)
