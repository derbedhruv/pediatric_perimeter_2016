      /**************************************************************
  //  PEDIATRIC PERIMETER ARDUINO SEGMENT FOR ADDRESSABLE LEDs
  //  SRUJANA CENTER FOR INNOVATION, LV PRASAD EYE INSTITUTE
  //
  //  AUTHORS: Dhruv Joshi
  //
  //  This code gives the user the following possible LED outputs through
  //  serial addressing:
  //  1. Hemispheres: Turning on half of the pediatric perimeter 'sphere'
  //    "h,l" for the left hemisphere
  //    "h,r" for the right hemisphere
  //    "h,a" for the left hemi without the central 30 degrees
  //    "h,b" for the right hemi without the central 30 degrees
  //
  //  2. Quadrants: Turning on a quarter of the pediatric perimeter 'sphere'
  //    "q,1" for the top left
  //    "q,2" for the top right
  //    "q,3" for the bottom left
  //    "q,4" for the bottom right hemi
  //
  //      The following are the same, but without the central 30 degrees
  //    q,5 to q,8
  //
  //  3. Meridian Sweeps (Kinetic Perimetry)
  //    "s,n", where n is the meridian number (in natural number units, same as that marked on the actual perimeter)
  //
***************************************************************/

//NeoPixel Library from Adafruit is being used here
#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
#include <avr/power.h>
#endif

#define Br 3      // This is where you define the brightness of the LEDs - this is constant for all

// Declare Integer Variables for RGB values. Define Colour of the LEDs.
// Moderately bright green color.
// reducing memory usage so making these into preprocessor directives
#define r 163
#define g 255
#define b 4

#define fixationLED 12  // the fixation LED pin


/**************************************************************************************************
  //
  //  ARDUINO PIN CONFIGURATION TO THE LED STRIPS AND HOW MANY PIXELS TO BE TURNED ON ON EACH STRIP!!
  //
  //  Arduino Pin     :  15 3 16 22 21 20 30 32 42  44  46  48  34  52  50  36  38  40  28  19  26  24  18  17  11     12
  //  Meridian Label  :  1  2  3  4  5  6  7  8  9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  daisy  fixation
  //  Meridian angle  :
  //  (in terms of the isopter)
*************************************************************************************************/
byte pinArduino[] = {15, 3,  16, 22, 21, 20, 30, 32, 42, 44, 46, 48, 50, 52, 34, 36, 38, 40, 28, 19, 26, 24, 18, 17, 11};
byte numPixels[] =  {23, 23, 23, 23, 19, 12, 11, 12, 19, 23, 23, 23, 23, 23, 23, 23, 12, 10, 10, 10, 12, 24, 23, 23, 72};    // there are 72 in the daisy chain

Adafruit_NeoPixel meridians[25];    // create meridians object array for 24 meridians + one daisy-chained central strip

/*************************************************************************************************/

// THE FOLLOWING ARE VARIABLES FOR THE ENTIRE SERIALEVENT INTERRUPT ONLY
// the variable 'breakOut' is a boolean which is used to communicate to the loop() that we need to immedietely shut everything off
String inputString = "", lat = "", longit = "";
boolean acquired = false, breakOut = false, sweep = false;
unsigned long previousMillis, currentMillis, sweep_interval = 1367 ; // the interval for the sweep in kinetic perimetry (in ms)
//int sweepIntervals [] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}; // sweep intervals for a particular meridian/strip in kinetic mode // DEPRECATED
int fixationStrength = 100;  // brightness of the fixation
byte sweepStart, longitudeInt, Slider = 255, currentSweepLED, sweepStrip, daisyStrip;
byte Respose_ClearAll;
byte meridians_turnOn[24];
char temp[25] = "";

void setup() {
  // setup serial connection
  Serial.begin(115200);
  Serial.setTimeout(500);
  Serial.println("starting..");

  for (int i = 0; i < 25; i++) {
    // When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
    meridians[i] = Adafruit_NeoPixel(numPixels[i], pinArduino[i], NEO_GRB + NEO_KHZ800);
  }
  clearAll();
}

void loop() {
  if (sweep == true) {

    // Decide the Sweep Interval corresponding to each LED
    // "sweepIntervals" Will Have The time intervals for the current chosen strip
    // This will change for every strip
    
    /* DEPRECATED *************************************************************************************
    if (currentSweepLED > 0) {
      /*
       * BottomMost LED is where we start the sweep from, but it's pixelNumber is the last, i.e highest,
       * while its sweepDelay comes at the very beginning
       * The below formula adjusts for that, setting the sweepInterval of LED as it should be, from the array
       *
      //sweep_interval = sweepIntervals[numPixels[sweepStrip - 1] - currentSweepLED];
    } * DEPRECATED ************************************************************************************/

    // we will poll for this variable and then sweep the same LED
    currentMillis = millis();
    // Serial.println(currentMillis - previousMillis);
    if (currentMillis - previousMillis <= sweep_interval) {

      // update the LED to be put on. Check if the current LED is less than the length of the sweeping strip
      if (currentSweepLED > 3) {
        // Writing this part in direct neopixel code because function calls are expensive and freeze the serialEvent interrupt
        meridians[sweepStrip - 1].setBrightness(Br);
        meridians[sweepStrip - 1].setPixelColor(currentSweepLED - 3, 0, 0, 0);  // set previous LED off
        meridians[sweepStrip - 1].setPixelColor(currentSweepLED - 4, r, g, b);

        meridians[sweepStrip - 1].show(); // This sends the updated pixel color to the hardware.

      } else if (currentSweepLED == 3) {
        // we're done with the present strip. switch to daisy chain.
        // clear all previous meridian stuff...
        meridians[sweepStrip - 1].clear();
        meridians[sweepStrip - 1].show();
        // sweep_interval = 1750;      // infinitely short so that we just zap off the longer strip
        meridians[24].setBrightness(Br);  // set this here to avoid wasting steps later

      } else if (currentSweepLED < 3) {
        // only need to light the daisy
        meridians[24].setPixelColor(3 * daisyStrip + 2 - currentSweepLED - 1, 0, 0, 0);
        meridians[24].setPixelColor(3 * daisyStrip + 2 - currentSweepLED, r, g, b);
        meridians[24].show(); // This sends the updated pixel color to the hardware.

        // reduce sweep interval because now we're slowing down the interrupt due to the neopixels stuff
        //   sweep_interval = 1750;    // this figure should be properly calibrated
      }

    } else {           // what to do when its within the interval
      // stop everything when the currentSweepLED is 0.
      if (currentSweepLED == 0) {
        // To Notify That The We Are Done With LED Strip;
        currentSweepLED = 28; // 28 value is to Reinitailze The Value in GUI
        Serial.println(currentSweepLED);
        previousMillis = 0;
        clearAll();
        sweep = false;
        // sweep_interval = 1750;
      }
      else
      {
        Serial.println(currentSweepLED);    // That's the iteration of the LED that's ON
        currentSweepLED = currentSweepLED - 1;    // update the LED that has to be on
        previousMillis = currentMillis;
        // We notify over serial (to processing), that the next LED has come on.
      }
    }
  }

  if (Serial.available() > 0) {
    char inChar = (char)Serial.read();
    // if there's a comma, that means the stuff before the comma is one character indicating the type of function to be performed
    // for historical reasons we will store this as variables (lat, long)
    if (inChar == ',') {
      breakOut = false;
      // Serial.println(inputString);
      lat = inputString;
      // reset the variable
      inputString = "";
    } else {
      // if its a newline, that means we've reached the end of the command. The stuff before this is a character indicating the second argument of the function to be performed.
      if (inChar == '\n') {
        breakOut = false;
        longit = inputString;
        // reset everything again..
        inputString = "";

        // we deal with 3 cases: sweeps, hemispheres and quadrants, Meridians
        switch (lat[0]) { // use only the first character, the rest is most likely garbage

          // this is the case of setting brightness of the LEDs
          case 'm': { // Choosen Meridian Will Turn On
              // Based on the number entered as longit[0], we will turn on that particular LED.
              byte chosenStrip = longit.toInt();
              if (chosenStrip <= 24 && chosenStrip > 0) {
                sweep = false;
                //Set The Sweep Interval to False

                sweepStrip = chosenStrip;

                meridians_turnOn [0] =  sweepStrip;
                turnThemOn(meridians_turnOn, true, 1);
              }
              // brightness = String(longit).toInt();
              break;
            }

          // change sweep time according to the LEDs placement in the Device
          case 't': {
              /*
               * Indicates that GUI is ready to send Sweep interval times   
               * The format sent is t, strip number (chosenStrip)
               */
              //delay(30);  //Wait some time so it can write everything //DEPRECATED
              //int chosenStrip = longit.toInt(); //DEPRECATED
              //readSweepIntervals(chosenStrip); //Start reading sweep intervals  //DEPRECATED
              sweep_interval = longit.toInt();  //every LED has same time interval
              break;
              /*// interval= longit.toInt();
                // sweepTimeIntervals
                int meridian = longit.toInt();
                int n = numPixels[meridian - 1] + 3; // No. Of LEDs 

                // Get The Time Intervals in the form of a string
                if (Serial.available()>0) {
                // sweepIntervals  = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}; // clear the prev sweep interval values
                for (int i = 0 ; i< 28; i++) {
                 sweepIntervals[i] =0;
                }
                // Get The Concated String of Time intervals
                 String inStr = Serial.readStringUntil('\n');

                // Populate the array with the time intervals for the particular meridian
                 int len = int (inStr.length());
                 int index = 0, prevIndex;

                 for ( int i =0 ; i < n-1 ; i++) {
                   prevIndex = index;
                   index = inStr.indexOf(',', index+1); // Scan For ',' one by one from the starting of te string

                // For the last time interval
                   if (index == 0){
                     index = len+1; // point to the last letter
                   }

                // Populate The Time intervals
                //  sweepIntervals [i] = atol(inStr.substring(prevIndex,index-1));

-                   inStr.substring(prevIndex,index-1).toCharArray(temp, sizeof(temp)); // Convert into Chaecter Array Before converting to Long Int
                   sweepIntervals [i] = atol(temp);

                  }
                 }
                break;*/
            }

          // choose strip to sweep
          case 's': {
              /*
               * This is the case of sweeping a single longitude.
               * Based on the number entered as longit[0], we will turn on LEDs in that particular meridian based on the sweep intervals sent earlier.
               * Refer case 't' for sweep intervals;
               */
              byte chosenStrip = longit.toInt();
              if (chosenStrip <= 24 && chosenStrip > 0) {
                sweep = true;
                //Set The Sweep Interval
                //  sweep_interval = 1750;
                sweepStrip = chosenStrip;
                daisyStrip = daisyConverter(sweepStrip);
                currentSweepLED = numPixels[sweepStrip - 1] + 3;    // adding 3 for the 3 LEDs in the daisy chain
              }
              //byte acknowledgement = 97;
              //Serial.write(acknowledgement);
              break;
            }

          case 'l': {
              //change the brightness value of fixation LEDs based on user input
              fixationStrength = longit.toInt();
              analogWrite(fixationLED, fixationStrength);
              break;
            }
          case 'h': {
              // clearAll();
              // turn off the fixation
              analogWrite(fixationLED, 0);

              // we then switch through WHICH hemisphere
              switch (longit[0]) {
                case '1': {
                    // LEFT hemisphere..
                    Serial.println("left hemi");
                    hemisphere3();
                    break;
                  }
                case '2': {
                    // RIGHT hemisphere..
                    Serial.println("right hemi");
                    hemisphere2();
                    break;
                  }
                // 30 degrees and outer case:
                case '3': {
                    // 30 degrees OFF left hemisphere
                    hemisphere1();
                    break;
                  }
                case '0': {
                    hemisphere4();
                    break;
                  }
              }
              break;
            }
          case 'q': {
              Serial.println("quadrants");
              // turn off the fixation
              analogWrite(fixationLED, 0);

              switch (longit[0]) {
                // we shall go anticlockwise. "1" shall start from the bottom right.
                case '1': {
                    quad8();
                    break;
                  }
                case '2': {
                    quad7();
                    break;
                  }
                case '3': {
                    quad6();
                    break;
                  }
                case '4': {
                    quad5();
                    break;
                  }
                case '5': {
                    // turn on only the 30 degrees and higher latitudes
                    quad4();
                    break;
                  }
                case '6': {
                    // turn on only the 30 degrees and higher latitudes
                    quad3();
                    break;
                  }
                case '7': {
                    // turn on only the 30 degrees and higher latitudes
                    quad2();
                    break;
                  }
                case '8': {
                    // turn on only the 30 degrees and higher latitudes
                    quad1();
                    break;
                  }
              }
              break;
            }
        }

        if (longit[0] == 'x') {
          // put everything off, but put the fixation back on
          // digitalWrite(fixationLED, HIGH);
          // breakOut = true;  // break out of the loops yo
          //  Serial.println("clear all");
          Respose_ClearAll = 99;
          Serial.println(Respose_ClearAll);  // Response To The Request Clear All
          clearAll();
          delay(1);
          // reset everything...
          sweep = false;
        } else {
          //digitalWrite(fixationLED, LOW);
          inputString = "";
        }
      } else {
        inputString += inChar;
      }
    }
  }
}


/***************************************************************************************************
  //
  //  FUNCTION DEFINITIONS
  //
***************************************************************************************************/

void clearAll() {
  // put them all off
  for (int i = 0; i < 25; i++) {
    meridians[i].clear();
    meridians[i].setBrightness(0);      // because we want to "clear all"
    meridians[i].begin();
    meridians[i].show();
  }
  // then put on fixation
  analogWrite(fixationLED, fixationStrength);
}

void sphere() {
  // Draw a sphere with all the LEDs on
  // Pixels 25 is the strip for Daisy Chain with 72 LED's on in all.
  byte meridians_turnOn[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24};
  turnThemOn(meridians_turnOn, true, sizeof(meridians_turnOn));
}

//Initialises Hemisphere 1 - Left Hemisphere: Physical Meridian numbers 7 to 19.
void hemisphere1() {
  // turn on 7 to 19, including both
  byte meridians_turnOn[] = {7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19};
  turnThemOn(meridians_turnOn, true, sizeof(meridians_turnOn));
}

//Initializes Hemisphere 2 - Right Hemisphere
void hemisphere2() {
  // turn on less than 18 and greater than 8, not including both
  byte meridians_turnOn[] = {1, 2, 3, 4, 5, 6, 7, 19, 20, 21, 22, 23, 24};

  turnThemOn(meridians_turnOn, true, sizeof(meridians_turnOn));
}

//Initialises Hemisphere a - Left Hemisphere without the central 30 degrees (or the central daisy)
void hemisphere3() {
  // turn on 7 to 19, including both
  byte meridians_turnOn[] = {7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19};
  turnThemOn(meridians_turnOn, false, sizeof(meridians_turnOn));
}

//Initializes Hemisphere b - Right Hemisphere without central 30 degrees
void hemisphere4() {
  byte meridians_turnOn[] = {1, 2, 3, 4, 5, 6, 7, 19, 20, 21, 22, 23, 24};
  turnThemOn(meridians_turnOn, false, sizeof(meridians_turnOn));
}

//Initializes Quadrant 1
void quad1() {
  // meridian 1 to 7
  byte meridians_turnOn[] = {1, 2, 3, 4, 5, 6, 7};
  turnThemOn(meridians_turnOn, true, sizeof(meridians_turnOn));
}

//Initializes Quadrant 2
void quad2() {
  // 7 to 13
  byte meridians_turnOn[] = {7, 8, 9, 10, 11, 12, 13};
  turnThemOn(meridians_turnOn, true, sizeof(meridians_turnOn));
}

//Initializes Quadrant 3
void quad3() {
  // meridian 13 to 19
  byte meridians_turnOn[] = {13, 14, 15, 16, 17, 18, 19};
  turnThemOn(meridians_turnOn, true, sizeof(meridians_turnOn));
}

//Initializes Quadrant 4
void quad4() {
  // 19 to 24
  byte meridians_turnOn[] = {19, 20, 21, 22, 23, 24};
  turnThemOn(meridians_turnOn, true, sizeof(meridians_turnOn));
}

//Initializes Quadrant 5 - which is quad 1 without the central 30
void quad5() {
  // meridian 1 to 7, without central LEDs
  byte meridians_turnOn[] = {1, 2, 3, 4, 5, 6, 7};
  turnThemOn(meridians_turnOn, false, sizeof(meridians_turnOn));
}

//Initializes Quadrant 6
void quad6() {
  // meridian 7 to 13, without central LEDs
  byte meridians_turnOn[] = {7, 8, 9, 10, 11, 12, 13};
  turnThemOn(meridians_turnOn, false, sizeof(meridians_turnOn));
}

//Initializes Quadrant 7 -
void quad7() {
  // meridian 13 to 19 without cental LEDs
  byte meridians_turnOn[] = {13, 14, 15, 16, 17, 18, 19};
  turnThemOn(meridians_turnOn, false, sizeof(meridians_turnOn));
}

//Initializes Quadrant 8
void quad8() {
  // 19 to 24, without central
  byte meridians_turnOn[] = {19, 20, 21, 22, 23, 24};
  turnThemOn(meridians_turnOn, false, sizeof(meridians_turnOn));
}

int daisyConverter(int n) {
  // converts the given meridian into the daisy "meridian"
  if (n < 8) {
    return 7 - n;
  } else {
    return -n + 31;
  }
}

void setStripColorN(int n) {
  // set colour on all LEDs for a strip 'n'
  for (int j = 0; j < numPixels[n]; j++) {
    meridians[n].setPixelColor(j, r, g, b);
  }
}

void turnThemOn (byte meridian_range[], boolean daisy_on, byte number_of_meridians) {
  // This generalized function turns on entire meridian strips (1 to 24), given an array of which ones to turn on
  // It also turns on particular "meridians" in the daisy, but only if the daisy_on is set to true, default false

  // First the meridians
  for (int ii = 0; ii < number_of_meridians; ii++) {
    int meridian_to_be_turned_on = meridian_range[ii] - 1;

    meridians[meridian_to_be_turned_on].setBrightness(Br);
    setStripColorN(meridian_to_be_turned_on);
    meridians[meridian_to_be_turned_on].show();
  }

  // then cycling through the daisy
  if (daisy_on == true) {
    for (int ii = 0; ii < number_of_meridians ; ii++) {
      meridians[24].setBrightness(Br);

      int m = daisyConverter(meridian_range[ii]);

      for (int j = 3 * m; j < 3 * (m + 1); j++) {
        meridians[24].setPixelColor(j, r, g, b);
      }
    }
    meridians[24].show();
  }
}

/* DEPRECATED ********************************************************************************************
void readSweepIntervals(int chosenStrip) {

  /*
   * Function to read sweep interval values being sent by GUI;
   * It reads until it reaches '\n' i.e. endOfLine;
   * A comma is a delimiter, hence, it stores the value from before the comma and then continues to read;
   * At the end, it sends 98 to acknowledge that it has recieved the required number of elements
   *
  int pixelNumber = 0;
  byte acknowledgement;
  while (pixelNumber != numPixels[chosenStrip - 1]) {
    inputString = "";
    pixelNumber = 0;
    char inputCharacter;
    byte acknowledgement;
    boolean endOfString = false;
    while(!endOfString) {
      if(Serial.available() <= 0) {
        while(Serial.available()<=0);
        continue;
      }
      inputCharacter = (char)Serial.read();
      if(inputCharacter == ',') {
        sweepIntervals[pixelNumber++] = inputString.toInt();
        inputString = "";
      } else if(inputCharacter == '\n') {
        sweepIntervals[pixelNumber++] = inputString.toInt();
        inputString = "";
        endOfString = true;
      } else {
        inputString+=inputCharacter;
      }
    }
    if(pixelNumber == numPixels[chosenStrip - 1]){
      acknowledgement = 98;
      Serial.println(acknowledgement);
    } else {
      acknowledgement = 97;
      Serial.println(acknowledgement);
    }
  } 
  
  inputString = Serial.readStringUntil('\n');

  int len = inputString.length();

  String numString = "";
  
  for(int characterNumber = 0; characterNumber < len; characterNumber++ ) {

    if(inputString.charAt(characterNumber) == '\n') {
      sweepIntervals[pixelNumber++] = numString.toInt();
      numString = ""; 
      break;
    }
    else if(inputString.charAt(characterNumber) == ',') {
      sweepIntervals[pixelNumber++] = numString.toInt();
      numString = "";
    }
    else {
      numString+=inputString.charAt(characterNumber);
    }
    
  }

  if(!numString.equals("")) {
    sweepIntervals[pixelNumber++] = numString.toInt();
  }

  if(pixelNumber >= (numPixels[chosenStrip - 1])){
    acknowledgement = 98;
    Serial.println(acknowledgement);
  }
  
} DEPRECATED ******************************************************************************/
