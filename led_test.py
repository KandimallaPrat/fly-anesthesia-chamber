from gpiozero import PWMOutputDevice
from time import time, sleep

led = PWMOutputDevice(18, active_high=True, initial_value=0)
led.on()
sleep(10)
led.off()
sleep(5)
led.on()
sleep(5)
led.off()
