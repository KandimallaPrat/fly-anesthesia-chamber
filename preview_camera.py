from picamera import PiCamera

camera = PiCamera()
camera.color_effects = (128, 128)
camera.framerate = 30
camera.resolution = (1920, 1080)
camera.start_preview()
