from picamera import PiCamera
from time import time

camera = PiCamera()

camera.start_recording('test.h264')
camera.wait_recording(5)

run_time = 30
start_time = time()

while time() < (start_time + run_time):
  print(str(camera.frame.index),':', time())
  
camera.stop_recording
camera.close()
