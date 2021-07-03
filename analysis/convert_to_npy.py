import numpy as np

r = '2021-07-02-15-08-59'

datadir = '/local/anesthesia/data/' + r + '/'
for i in ['index', 'timestamps', 'frame-type', 'motor-status', 'motor-voltage', 'led-status', 'led-voltage']:
    temp = np.loadtxt(datadir + i + '.txt', dtype=float)
    np.save(datadir + i + '.npy', temp)

use_monitor = True
if use_monitor:
    for i in ['oxygen', 'ga-mac', 'dose']:
        temp = np.loadtxt(datadir + i + '.txt', dtype=float)
        np.save(datadir + i + '.npy', temp)
