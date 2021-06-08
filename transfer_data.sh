#!/usr/bin/env bash

# From USB3 external to Synology
rsync -aP /media/pi/Elements/anesthesia-reanimation/data/ admin@10.0.0.3:/volume1/anesthesia/data/