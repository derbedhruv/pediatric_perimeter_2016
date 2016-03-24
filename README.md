# Pediatric Perimeter 2016
## Contributors: Dhruv Joshi
## Acknowledgements: Karthik Reddy (for legacy versions)
Latest version of the code. Bugs ironed out, uses adafruit Neopixels and has less frame drop. Previous code shall be archived. 

Pediatric Perimeter is a novel device to quantify visual fields in infants. This device is presently in version 3.x and is ready to be tested on infants.

New additions in the latest code:
* Higher resolution LEDs in meridians
* Use of a higher speed camera (upto 120fps though these speeds are not accessible at the moment using Processing v2.0 and GSMovieMaker) 

TODOs:
* Read source code of GSMovieMaker
* Actual frame timestamps from the camera - how to acquire
* Speed up the program by removing unnecesarry things such as the button colour method for detecting clicks - this can easily be replaced by a polar coordinate search.
