from picamera import PiCamera

camera = PiCamera()
camera.color_effects = (128, 128)
camera.framerate = 60
camera.resolution = (1280, 720)
camera.start_preview()
