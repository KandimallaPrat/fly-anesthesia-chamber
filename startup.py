from time import time, sleep
from operator import add, sub

# Inputs
datadir = 'data/test/'
t_experiment = 5  # in seconds
t_motor_on = [1, 2, 3]
motor_duration = [0.1, 0.2, 0.3]
t_led_on = [2, 3, 4]
led_duration = [0.15, 0.25, 0.35]

use_camera = False
if use_camera:
    from picamera import PiCamera
    camera = PiCamera()
    camera.start_recording(datadir + 'video.h264')
else:
    frame_index = 0

# Validate inputs
# Non-negative
if t_experiment <= 0 or min(t_motor_on) <= 0 or min(t_led_on) <= 0 or \
        min(motor_duration) <= 0 or min(led_duration) <= 0:
    raise ValueError('Time values must be non-negative.')

# Same length
if len(t_motor_on) != len(motor_duration) or len(t_led_on) != len(led_duration):
    raise ValueError('Motor or LED start times need a matching duration.')

# Within experimental length
if max(t_motor_on + motor_duration) > t_experiment or max(t_led_on + led_duration) > t_experiment:
    raise ValueError('Motor or LED start times cannot exceed experimental length.')

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
if min(list(map(sub, t_motor_on[1::], a[0:-1]))) <= 0 or min(list(map(sub, t_led_on[1::], b[0:-1]))) <= 0:
    raise ValueError('Motor or LED times cannot overlap.')

# Internal values
frame_rate = 30  # Hard coded for camera
start_time = time()
frame_time = 0
current_frame_index = -1

# Start logging
log_info = open(datadir + 'info.txt', 'w')
log_index = open(datadir + 'index.txt', 'w')
log_ts = open(datadir + 'timestamps.txt', 'w')
log_frame_type = open(datadir + 'frame-type.txt', 'w')
log_motor = open(datadir + 'motor-status.txt', 'w')
log_motor_volt = open(datadir + 'motor-voltage.txt', 'w')
log_led = open(datadir + 'led-status.txt', 'w')
log_led_volt = open(datadir + 'led-voltage.txt', 'w')
log_dose = open(datadir + 'dose.txt', 'w')

while frame_time < t_experiment*(10**6):
    if use_camera:
        frame_complete = camera.frame.complete
        frame_time = camera.frame.timestamp  # in microseconds
    else:
        frame_complete = True
        frame_time = (time() - start_time)*(10**6)

    if frame_time is None:
        frame_time = 0

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

                # Verbose output
                # Write if actual frame or keyframe
                if ft == 'frame' or ft == 'keyframe':
                    t = start_time + (float(frame_time)/(10**6))  # Add Unix time

                    # Motor and LED example
                    if float(frame_time)/(10**6) > t_motor_on and float(frame_time)/(10**6) < (t_motor_on + motor_duration):
                        # Make sure motor is on
                        log_motor.write(str(1) + '\n')
                        log_motor_volt.write(str(5) + '\n')
                        log_led.write(str(1) + '\n')
                        log_led_volt.write(str(5) + '\n')
                    else:
                        # Make sure motor is off
                        log_motor.write(str(0) + '\n')
                        log_motor_volt.write(str(0) + '\n')
                        log_led.write(str(0) + '\n')
                        log_led_volt.write(str(0) + '\n')

                    log_index.write(str(frame_index) + '\n')
                    log_ts.write(str(t) + '\n')
                    log_frame_type.write(str(frame_type) + '\n')

                print('[Frame ' + str(frame_index) + '] Time: ' + str(float(frame_time)/(10**6)) +
                      '; Type: ' + ft + '; Size: ' + str(float(frame_size)/1000) + ' kB')

    sleep(1./(2*frame_rate))  # Only check camera at the nyquist rate

if use_camera:
    camera.stop_recording
    camera.close()

# End logging
log_info.close()
log_index.close()
log_ts.close()
log_frame_type.close()
log_motor.close()
log_motor_volt.close()
log_led.close()
log_led_volt.close()
log_dose.close()

print('Wall time:', time() - start_time)
