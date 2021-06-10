import os
import subprocess
import numpy as np
from time import sleep

if os.path.isfile('AS3DataExport.csv'):
    os.system('rm AS3DataExport.csv')

if os.path.isfile('AS3Rawoutput1.raw'):
    os.system('rm AS3Rawoutput1.raw')

monitor = subprocess.Popen(["/usr/bin/mono", "/home/jdk20/Downloads/VSCapture.exe", "-port", "/dev/ttyUSB0",
                      "-interval", "5", "-export", "1", "-waveset", "0"], stdout=subprocess.PIPE)

i = 0
for i in range(0, 100):
    if os.path.isfile('AS3DataExport.csv'):
        x = np.genfromtxt('AS3DataExport.csv', skip_header=1, usecols=(11), delimiter=',')  # also 7, 8, 9

        if x.shape != ():
            x = x[-1]

        print('Time: ' + str(i) + ', O2: ' + str(x) + '%')

    sleep(1)
    i = i + 1

monitor.kill()
