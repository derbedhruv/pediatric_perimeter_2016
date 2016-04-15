# Pediatric Perimeter 2016
## Author: Dhruv Joshi
## (c) Srujana Center for Innovation, L V Prasad Eye Institute
Latest version of the code. Bugs ironed out, uses adafruit Neopixels and has less frame drop. Previous code shall be archived. 

Pediatric Perimeter is a novel device to quantify visual fields in infants. This device is presently in version 3.x and is ready to be tested on infants.

New additions in the latest code:
* Higher resolution LEDs in meridians
* Use of a higher speed camera (upto 120fps though these speeds are not accessible at the moment using Processing v2.0)
* Generating video through saving frames generated
* Recording audio for the duration of the test
* stitching audio and frames together to make a video using ffmpeg, which is called as a seperate process using processBuilder() in java

TODOs:
* Using ffmpeg for all camera acquisition, including fixing exposure values etc
* Incorporating image processing of the frames on the fly
* Moving the project out of processing and making it 100% java