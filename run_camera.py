import numpy as np

from picamera import PiCamera
from time import time, sleep

camera = PiCamera()

camera.start_recording('data/test/video.h264')
# camera.wait_recording(1)

frame_rate = 30
run_time = 5
start_time = time()

frame_time = 0
data = np.empty([0, 4], dtype='int64')
a = time()
while frame_time < run_time*(10**6):
  frame_complete = camera.frame.complete
  frame_time = camera.frame.timestamp
  if frame_time is None:
    frame_time = 0

  frame_index = camera.frame.index
  frame_type = camera.frame.frame_type
  frame_size = camera.frame.frame_size

  # Check if current frame is finished being written
  if frame_complete:
    temp = np.array([[frame_index, frame_time, frame_type, frame_size]])

    # Initial frame
    if data.shape[0] == 0:
      # Frame Index, Frame Time (microseconds), Frame Type, Frame Size (bytes)
      # Frame Index
      #     frame = 0
      #     key_frame = 1 (I-frame)
      #     sps_header = 2 (not a frame)
      #     motion_data = 3 (not a frame)
      data = np.concatenate((data, temp), axis=0)

    else:

      if data[-1, 0] != temp[0,0]:
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

        print('[Frame ' + str(temp[0, 0]) + '] Time: ' + str(float(temp[0, 1])/(10**6)) +
              '; Type: ' + ft + '; Size: ' + str(float(temp[0, 3])/1000) + ' kB')

  sleep(1./(2*frame_rate))  # Only check camera at the nyquist rate

camera.stop_recording
camera.close()
print(time() - a)
