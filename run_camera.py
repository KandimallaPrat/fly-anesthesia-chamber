import numpy as np

from picamera import PiCamera
from time import time, sleep

camera = PiCamera()

camera.start_recording('data/test/video.h264')
# camera.wait_recording(1)

frame_rate = 30
run_time = 30
stim_on = 10
stim_duration = 5


start_time = time()
frame_time = 0
data = np.empty([0, 4], dtype='int64')

video_log = open('data/test/video-log.txt', 'w')
motor_log = open('data/test/motor-log.txt', 'w')
led_log = open('data/test/led-log.txt', 'w')

while frame_time < run_time*(10**6):
  frame_complete = camera.frame.complete
  frame_time = camera.frame.timestamp
  if frame_time is None:
    frame_time = 0

  frame_index = camera.frame.index
  frame_type = camera.frame.frame_type
  frame_size = camera.frame.frame_size


  # Camera
  # Check if current frame is finished being written
  if frame_complete:
    temp = np.array([[frame_index, frame_time, frame_type, frame_size]])

    # Initial frame
    if data.shape[0] == 0:
      # Frame Index, Frame Time (microseconds), Frame Type, Frame Size (bytes)
      data = np.concatenate((data, temp), axis=0)

    else:
      if data[-1, 0] != temp[0, 0]:
        data = np.concatenate((data, temp), axis=0)

        if temp[0, 2] == 0:
          ft = 'frame'
        elif temp[0, 2] == 1:
          ft = 'keyframe'
        elif temp[0, 2] == 2:
          ft = 'SPS'
        elif temp[0, 2] == 3:
          ft = 'motion'
        else:
          ft = 'unknown'

        # Verbose output
        # Write if actual frame or keyframe
        if ft == 'frame' or ft == 'keyframe':
          t = start_time + (float(temp[0, 1])/(10**6))  # Add Unix time

          # Motor and LED example
          if float(frame_time)/(10**6) > stim_on and float(frame_time)/(10**6) < (stim_on + stim_duration):
            # Make sure motor is on
            motor_log.write(str(temp[0, 0]) + '\t' + str(t) + '\t' + str(1) + '\n')
            led_log.write(str(temp[0, 0]) + '\t' + str(t) + '\t' + str(1) + '\n')
          else:
            # Make sure motor is off
            motor_log.write(str(temp[0, 0]) + '\t' + str(t) + '\t' + str(0) + '\n')
            led_log.write(str(temp[0, 0]) + '\t' + str(t) + '\t' + str(0) + '\n')

          video_log.write(str(temp[0, 0]) + '\t' + str(t) + '\t' + str(temp[0, 2]) + '\n')

        print('[Frame ' + str(temp[0, 0]) + '] Time: ' + str(float(temp[0, 1])/(10**6)) +
              '; Type: ' + ft + '; Size: ' + str(float(temp[0, 3])/1000) + ' kB')

  sleep(1./(2*frame_rate))  # Only check camera at the nyquist rate

camera.stop_recording
camera.close()
video_log.close()
motor_log.close()
led_log.close()

print('Wall time:', time() - start_time)
