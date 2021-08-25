# Initial Check (before daily experiments)
## Location
1. Chamber-1 is located in **Beckman Biology Building Room 211** on the second floor. Make sure the door is unlocked before beginning experiments by pressing the unlock button on the door knob.
## Monitor, air, vaporizer, and humidifier
1. Turn on the Datex-Ohmeda S/5 anesthesia monitor by holding down the power button for a few seconds. The system will need 3 minutes or so to fully boot up and calibrate.
2. Inspect the delivery air tubing, make sure the vaporizer is off and it is disconnected from the humidifier. **If the vaporizer is connected to the humidifier the next step can flood the chamber with water**. Open the flow meter on the anesthesia station (green knob) and then open the large air tank canister until the outlet pressure is stable. You may now close the green flow meter.
3. Fill the humidifier about halfway with distilled water from the nearby sink. Tightly screw it together and attach the inlet cable from the vaporizer. Make sure the outlet from the humidifier is connected to the inlet to the chamber.
4. Check the vaporizer to see if it contains adequate anesthesia, if the level is less than 1/3 full, consider adding more volatile anesthesia.
## Outside the chamber
1. Make sure the raspberry pi is powered on, if it is not on the white power block connected behind the chamber can be reset by pressing the red on/off button on the power switch.
2. On the raspberry pi, open the Thonny application and run the python script `/home/pi/recording/preview_camera.py` to check the camera. **Ensure the chamber LEDs are on.** **Close the script when done because the camera can only be utilized by one script at a time.**
3. Make sure the external HDD is connected to the raspberry pi over USB, it should be automatically mounted at /media/pi/Elements. If it not connected, gently disconnect and reconnect the USB cable from the raspberry pi.
## Inside the chamber
1. **When working inside the chamber be extra careful to not hit the camera.**
2. Carefully open the chamber door, making sure to not knock it over.
3. Check the inside of the chamber to make sure there are no escaped flies inside.
4. Check the tubing is secured to the walls of the chamber and won't impair the camera.
5. Run the self-check at `/home/pi/recording/selfcheck.sh`, by running `./selfcheck.sh` when in the /home/pi/recording/ directory. This script will turn the motors on and off over the course of 40 seconds and then transfer the files over the VPN to the Synology. If the VPN step fails, you can check if you're on the VPN by using `ping 10.0.0.1`, if that fails you can restart the VPN using `sudo service openvpn restart`. If the motors fail, ensure that the leads are properly connected on top of the chamber. Also check the monitor is connected and returning valid oxygen readings. If the monitor does not appear to be connected you can disconnect and reconnect its gray USB cable.

# Experiments
## Flies
1. Check the "General anesthesia fly experiments" Google Sheet to see which genotype and anesthesia doses have not been completed.
2. **Pick a genotype that is four days old. For example if the date is 7-20, use a vial labeled 7-16. Do not use flies that are younger or older.**
3. Keep a detailed record of the genotype, number of flies you've used, and the amount of anesthesia you want to apply.
## Wells
1. Select a well plate and ensure that is clean and devoid of fly bits. You can clean it with water, but avoid using ethanol as that is an anesthetic.
2. Ensure that the components of the well plate are in order, the layer labeled 1 should be on top and correctly orientated with layer 2 so that the holes are aligned.
3. You can tape the sides of the well plate to stop them from sliding.
4. Turn on the vacuum and breathing air (BA) for the aspirator, you may need three turns of the BA to get it to sufficient strength.
5. Check that the aspirator tip is not clogged with any obstructions.
6. Use your preferred method to transfer 3 flies into each well, if flies appear injured or dead, try your best to remove them from the well and replace them with healthy flies. If you accidently transfer more than 3 flies, remove the extra ones. Try to avoid transferring any male flies into the wells.
7. Once transfer is complete, you can tape the top lid down to hold it in place.
## Session
1. Bring the flies to Room 211 and place them within the chamber. **Ensure that the inlet (vertical side) is on the left, and the outlet is on the right.** Tighten the chamber down with hex bolts and firmly attach the inlet and outlet lines until they are finger tight.
2. Close the chamber door and create a seal by pushing down on the Velcro. You may wish to do a final LED check and fly count by running the preview_camera.py script in Thonny. If you do make sure to stop the script before you start the experiment.
3. Make sure the air is on at 0.5 L/min.
## Computer
1. The raspberry pi can be accessed from any computer on the VPN over ssh. The IP of the chamber is 10.0.1.128 and the login is pi, for example you can connect using `ssh pi@10.0.1.128`.
2. Once connected you can open a tmux session by either attaching to the last used session by running `tmux a`, or by creating a new session by typing `tmux`.
3. Once in tmux you can navigate to the `/home/pi/recording` directory.
4. If the number of flies per well is not 3, you'll have to adjust that the experiment.sh script using `nano experiment.sh`. The argument `-n_flies 3 3 3 3 3 3`, references the number of flies within the top left, top center, top right, bottom left, bottom center, and bottom right wells. You can change the number and save the file using ctrl+o, and then exit using ctrl+x. Nothing else should be adjusted.
5. You can start the experiment by running `./experiment.sh` from within the /home/pi/recording.
## Anesthesia
1. **Anesthesia is administered at 2070 seconds after the start of the experiment and discontinued at 3270 seconds.**
2. The vaporizer is not perfectly calibrated. In general it supplies more than the indicator implies, for example to administer 6.0% sevoflurane you would turn the dial to around the 5.0% marker. This effect is diminished, but still present, at lower doses.
3. It takes about 20 seconds for a change in the vaporizer to be reflected on the anesthesia monitor.
4. Try to maintain anesthesia within +/- 0.1% of the target dose.
5. After discontinuing the anesthesia, you may need to flush the well plate at a higher air flow of 1 L/min, make sure all of the anesthesia is gone from the well plate (The monitor should read 0.00, not 0.10).
## Completion
1. Turn off the air.
2. Open the chamber door and unscrew the well plate. The well plate can be taken to the fly room and the flies can be purged.
2. If this is the final experiment for the day, you can power off the anesthesia monitor, turn off the LEDs, and disconnect the tubing from the humidifier. You can then open the green flow meter and close the air tank.

# Sevoflurane Calibration Log (08-25-21)
| Dial Dose | Actual Dose |
| ------- | ------- |
| 0.5% | 0.65% |
| 1% | 1.10% |
| 2% | 2.18% |
| 3% | 3.18% |
| 4% | 4.28% |
| 5% | 5.30% |
| 6% | 6.35% |
| 7% | 7.45% |
| 8% | 8.50% |
