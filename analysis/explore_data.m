clc; clear variables; close all;

datadir = '/mnt/anesthesia/data/2021-05-31-17-01-41/';
n_flies = 30;

cd([datadir, 'tracking/tracking_fly29']);

x = readNPY('SPEED#smooth#wcentroid.npy');