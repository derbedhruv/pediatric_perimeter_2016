/**************************************************************
  //  PEDIATRIC PERIMETER ARDUINO SEGMENT FOR ADDRESSABLE LEDs
  //  SRUJANA CENTER FOR INNOVATION, LV PRASAD EYE INSTITUTE
  //
  //  AUTHORS: CKR
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
#define Red 179
#define Green 255
#define Blue 0

// #define Br 2      // This is where you define the brightness of the LEDs - this is constant for all

// Declare Integer Variables for RGB values. Define Colour of the LEDs.
// Moderately bright green color.
// reducing memory usage so making these into preprocessor directives
byte colorSequence[10][3] ={
  {223, 75, 23 },
  {233, 204, 19 },
  {155, 233, 19 },
  {51, 233, 19  },
  {19, 181, 233 },
  {19, 233, 181 },
  {19, 45, 233  },
  {217, 19, 233 },
  {233, 19, 19  }
  }; 
#define fixationLED 12  // the fixation LED pin



//String Constants for Patterns
#define fixed "FIXED"
#define riseFixed "RISE_FIXED"
#define fixedFall "FIXED_FALL"
#define riseFixedFall "RISE_FIXED_FALL"

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
byte Br; // variable to set brightness
byte r ;
byte g ;
byte b ;

String inputString = "", lat = "", longit = "";
boolean acquired = false, breakOut = false, sweep = false;
unsigned long previousMillis, currentMillis, sweep_interval = 1367, Recieved_sweep_interval = 1367 ; // the interval for the sweep in kinetic perimetry (in ms)
int fixationStrength = 100;  // brightness of the fixation
byte sweepStart, longitudeInt, Slider = 255, currentSweepLED, LEDNumber , sweepStrip, daisyStrip;
byte Respose_ClearAll;
byte meridians_turnOn[24];
char temp[25] = "";

//Variables for Patterns
byte allMeridians[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24};
byte patternNumber = 0;
int memoryAvailable;
unsigned long patterns_interval = 500;
boolean patterns;

// Pattern - One : Fountai Model
int riseCounter = 0;
int fixedCounter = 0;
int fallCounter = 0;
boolean riseDone = false;
boolean fixedDone = false;
boolean fallDone = false;
boolean verifyTest = false;
String wayImplementFM;  // These two variables should be Global variables / Donot try to declare as constants or as a function parameters (PGM might crash)
int patternOneIndex = 2; // To start with  the one time executing sequence.
byte daisyPixelsTurnOn [75];
byte meridianNumbersRM [24];


//Rotattional Model Variables
int riseCounterRM = 0;
int fixedCounterRM = 0;
int fallCounterRM = 0;
boolean riseDoneRM = false;
boolean fixedDoneRM = false;
boolean fallDoneRM = false;
boolean verifyTestRM = false;
String  wayImplementRM;  // These two variables should be Global variables / Donot try to declare as constants or as a function parameters (PGM might crash)
int startPixelRM, endPixelRM, numOfPixRM; // To get the pixel number limits for the pattern - 2
int patternTwoIndex;
//byte meridiansPatternTwo[][6] = {{1,2,3,4,5,6},{7,8,9,10,11,12},{13,14,15,16,17,18},{19,20,21,22,23,24}};

// Variables for Third Pattern
byte meridianNumbersCKR [24];
int counterCKR;
int patternThreeIndex = 2; // To start with a one time sequence.

byte colorIndex= 0;
boolean daisyOn = false; 
boolean ledCoupletOn = false;


byte reducedNumofLEDs[] =  {14, 14, 14, 14, 14, 14, 13, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 12, 12, 12, 14, 14, 14, 14};    // Start the stimulus from 60 Deg Periphery



void setup() {
  // setup serial connection
  Serial.begin(115200);
  Serial.setTimeout(500);
  Serial.println("starting..");
  Br = 2; // Initialise to default Brightness Value Requiredx
  for (int i = 0; i < 25; i++) {
    // When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
    meridians[i] = Adafruit_NeoPixel(numPixels[i], pinArduino[i], NEO_GRB + NEO_KHZ800);
  }
  clearAll();

}


void loop() {

  /* if (fixationStrength > 0){
    Serial.println(fixationStrength);
    }*/

  // if (sweep == true) {

  // Decide the Sweep Interval corresponding to each LED
  // "sweepIntervals" Will Have The time intervals for the current chosen strip
  // This will change for every strip

  /* DEPRECATED *************************************************************************************
    if (currentSweepLED > 0) {
    /*
       BottomMost LED is where we start the sweep from, but it's pixelNumber is the last, i.e highest,
       while its sweepDelay comes at the very beginning
       The below formula adjusts for that, setting the sweepInterval of LED as it should be, from the array

    //sweep_interval = sweepIntervals[numPixels[sweepStrip - 1] - currentSweepLED];
    } * DEPRECATED ************************************************************************************/

  // we will poll for this variable and then sweep the same LED
  /*  currentMillis = millis();
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
        sweep_interval = 1;      // infinitely short so that we just zap off the longer strip
        meridians[24].setBrightness(Br);  // set this here to avoid wasting steps later

      } else if (currentSweepLED < 3) {
        // only need to light the daisy
          meridians[24].setPixelColor(3 * daisyStrip + 2 - currentSweepLED - 1, 0, 0, 0);
          meridians[24].setPixelColor(3 * daisyStrip + 2 - currentSweepLED, r, g, b);
          meridians[24].show(); // This sends the updated pixel color to the hardware.
         sweep_interval = Recieved_sweep_interval/2; // For Daisy The delay is doubled So to maintain constat through out meridian
         }

    } else {           // ToDo when its within the interval
      // stop everything when the currentSweepLED is 0.
      if (currentSweepLED == 0) {
        // To Notify That We Are Done With LED Strip;
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
  */
  // Code for Sweep
  if (sweep == true) {

    // Serial.println(currentMillis - previousMillis);
    if (millis() - currentMillis <= sweep_interval) {

    } else {
      // Serial.println(millis());
      if ((LEDNumber <= numPixels[sweepStrip - 1] + 3 - 1) && LEDNumber > 0) {
        wayImplementFM = fixed;
        byte meridiansSweep [] = {sweepStrip, 0};

       if(ledCoupletOn){ //Switch to Use LED in couplets or not
        if((sweepStrip >= 13 && sweepStrip <= 24)|| (sweepStrip == 1)){
           Serial.println(sweepStrip);
        if(LEDNumber > 1){
        verifyTest = fountainModel(LEDNumber, 2, LEDNumber-1, meridiansSweep , 1, 2);
        verifyTest = fountainModel(LEDNumber, 2, LEDNumber-1, meridiansSweep , 1, 2);
        }else {
        verifyTest = fountainModel(LEDNumber, 1, LEDNumber, meridiansSweep , 1, 2);
        verifyTest = fountainModel(LEDNumber, 1, LEDNumber, meridiansSweep , 1, 2); 
        }}else {
        verifyTest = fountainModel(LEDNumber, 1, LEDNumber, meridiansSweep , 1, 2);
        verifyTest = fountainModel(LEDNumber, 1, LEDNumber, meridiansSweep , 1, 2); 
        }
        }else{
        verifyTest = fountainModel(LEDNumber, 1, LEDNumber, meridiansSweep , 1, 2);
        verifyTest = fountainModel(LEDNumber, 1, LEDNumber, meridiansSweep , 1, 2); 
        }
        
        //Serial.println(verifyTest);
        if (verifyTest == true) {
          Serial.println(LEDNumber);
          LEDNumber = LEDNumber - 1;
          verifyTest = false;
          currentMillis = millis();

        }
      }else if (LEDNumber == 0) {
        // To Notify That We Are Done With LED Strip;
        LEDNumber = 28; // 28 value is to Reinitailze The Value in GUI [Clear the red dot on Meridian on GUI]
        Serial.println(LEDNumber);
        // previousMillis = 0;
          clearAll();
        // sweep = false;
        // sweep_interval = 1750;
      }

    }
  }
  
  // Code for patterns
  if (patterns == true) {

    // Serial.println(currentMillis - previousMillis);
    if (millis() - currentMillis <= patterns_interval) {

    } else {
  
     colorIndex += 1;
     colorIndex %= 9;

     r = colorSequence [colorIndex] [0];
     g = colorSequence [colorIndex] [1];
     b = colorSequence [colorIndex] [2];
     
      //Select the pattern
      switch (patternNumber) {

        //pattern One
        case 1:
          //CKR    Serial.println("First FM Started");
          switch (patternOneIndex) {
            case 0:
              wayImplementFM = riseFixedFall;
              verifyTest = fountainModel(3, 3, 1, allMeridians , 24, 2);
              if (verifyTest == true) {
                patternOneIndex += 1;
                patternOneIndex %= 2;
                verifyTest = false;
              }
              break;

            case 1 :
              wayImplementFM = riseFixedFall;
              verifyTest = fountainModel(8, 5, 1, allMeridians , 24, 2);
              if (verifyTest == true) {
                patternOneIndex += 1;
                patternOneIndex %= 2;
                verifyTest = false;
              }
              break;

            case 2 :
              wayImplementFM = riseFixed;
              verifyTest = fountainModel(25, 5, 4, allMeridians , 24, 2);
              //  Serial.print("Returned From The Function  ,"); Serial.println(verifyTest);
              if (verifyTest == true) {
                patternOneIndex += 1;
                patternOneIndex %= 2;
                verifyTest = false;
              }
              break;
          }

          currentMillis = millis();
          break;

        //for Pattern Two : Spiral / Rotation Model
        case 2:
          /*  if (startPixelRM >= endPixelRM - numOfPixRM - 1) {
             wayImplementRM = riseFixedFall;
             verifyTestRM =  rotationModel(startPixelRM, 4, 3, 6, 27, endPixelRM, 2 );
             if (verifyTestRM == true) {
               startPixelRM -= 3;
               if (startPixelRM == 0) {
                 startPixelRM = 12;
               }
              }
            }*/
          wayImplementRM = riseFixed;
          verifyTest = fountainModel(3, 3, 1, allMeridians, 6 * (patternTwoIndex + 1 ), 2);
          if (verifyTest == true) {
            patternTwoIndex += 1;
            patternTwoIndex %= 4;
            // Serial.print("2 Index: ");Serial.println(patternTwoIndex);
            verifyTest = false;
          }
          currentMillis = millis();
          break;

        //for Pattern Three : "The CHAKRA"
        case 3:

          switch (patternThreeIndex) {

            case 1:
              wayImplementFM = fixed;
              verifyTest = fountainModel(5, 5, 1, meridianNumbersCKR  , 20, 2);
              if (verifyTest == true) {
                counterCKR += 1;
                counterCKR %= 6;
                updateMeridianNumbersCKR();
              }
              break;

            case 2:
              wayImplementFM = riseFixed;
              verifyTest = fountainModel(5, 5, 1, allMeridians, 24, 2);
              if (verifyTest == true ) {
                patternThreeIndex = 1;
                counterCKR = 0;
                updateMeridianNumbersCKR();
              }
              break;

          }
          currentMillis = millis();
          break;
      }
    }
  }


  // Code to get serial data and process it.
  if (Serial.available() > 0) {
    char inChar = (char)Serial.read();
    // if there's a comma, that means the stuff before the comma is one character indicating the type of function to be performed
    // for historical reasons we will store this as variables (lat, long)
    if (inChar == ',') {
      breakOut = false;
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
        //  Serial.println(lat[0]);
        // we deal with 3 cases: sweeps, hemispheres and quadrants, Meridians
        switch (lat[0]) { // use only the first character, the rest is most likely garbage


            case 'd': { // sets meridian to be on / off
     
              if (longit.toInt() == 1) {
                daisyOn = true;
                 
              }else if(longit.toInt() == 0){
               daisyOn = false;
              }else {
                daisyOn = false;
              }
              break;
            }
           case 'c': { // sets meridian to be on / off
     
              if (longit.toInt() == 1) {
                ledCoupletOn = true;
                 
              }else if(longit.toInt() == 0){
               ledCoupletOn = false;
              }else {
                ledCoupletOn = false;
              }
              break;
            }
          case 'm': { // Choosen Meridian Will Turn On
              // Based on the number entered as longit[0], we will turn on that particular LED.
              Br = 1;
               //Set The Color of the LED in Strip 
                r = Red;
                g = Green;
                b= Blue;
              //   Serial.println(1);
              analogWrite(fixationLED, 0); // Fixation is very Important during kinetic perimetry.
              byte chosenStrip = longit.toInt();
              if (chosenStrip <= 24 && chosenStrip > 0) {
                sweep = false;
                //Set The Sweep Interval to False

                sweepStrip = chosenStrip;

                meridians_turnOn [0] =  sweepStrip;
                turnThemOn(meridians_turnOn, daisyOn, 1);
              }
              // brightness = String(longit).toInt();
              break;
            }
          case 'p':  {// Choose
              Br = 1;
              //     Serial.println(2);
              analogWrite(fixationLED, fixationStrength); // Fixation is very Important during kinetic perimetry.
              byte chosenStrip = longit.toInt();
              if (chosenStrip <= 5) {
                patterns = true;
                patternNumber = chosenStrip;
                if (patternNumber == 1) {
                  patterns_interval = 500;
                  patternOneIndex = 2;
                } else if (patternNumber == 2) {
                  patterns_interval = 500;
                  //  startPixelRM = 12;
                  // endPixelRM = 4;
                  //  numOfPixRM = 3;
                  patternTwoIndex = 0;
                } else if (patternNumber == 3) {
                  patternThreeIndex = 2;
                  patterns_interval = 250;
                }

                currentMillis = 0;
              }
              break;
            }
          // change sweep time according to the LEDs placement in the Device
          case 't': {
              /*
                 Indicates that GUI is ready to send Sweep interval times
                 The format sent is t, strip number (chosenStrip)
              */
              //delay(30);  //Wait some time so it can write everything //DEPRECATED
              //int chosenStrip = longit.toInt(); //DEPRECATED
              //readSweepIntervals(chosenStrip); //Start reading sweep intervals  //DEPRECATED
              if (longit.toInt() != 0) {
                Recieved_sweep_interval = longit.toInt();  //every LED has same time interval
              }
              break;
              /*// interval= longit.toInt();
                // sweepTimeIntervals
                int meridian = longit.toInt();
                int n = numPixels[meridian - 1] + 3; // No. Of LEDs
2222222222222222222222222222222222222222222222222222222222222222222222222
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
                 This is the case of sweeping a single longitude.
                 Based on the number entered as longit[0], we will turn on LEDs in that particular meridian based on the sweep intervals sent earlier.
                 Refer case 't' for sweep intervals;
              */
              byte chosenStrip = longit.toInt();
              //      Serial.println(3);
              analogWrite(fixationLED, fixationStrength / 2); // Fixation is very Important during kinetic perimetry.
              if (chosenStrip <= 24 && chosenStrip > 0) {
                sweep = true;
                Br = 2;
                //Set The Color of the LED in Strip 
                r = Red;
                g = Green;
                b= Blue;
                
                //Set The Sweep Interval
                sweep_interval = Recieved_sweep_interval;
                sweepStrip = chosenStrip;
                daisyStrip = daisyConverter(sweepStrip);
                currentSweepLED = numPixels[sweepStrip - 1] + 3;    // adding 3 for the 3 LEDs in the daisy
                //  LEDNumber = numPixels[sweepStrip - 1] + 3 - 1;
                LEDNumber = reducedNumofLEDs[sweepStrip - 1];
                // Serial.println(LEDNumber); // First LED to start
                currentMillis = 0;
              }
              //analogWrite(fixationLED, 0);
              //byte acknowledgement = 97;
              //Serial.write(acknowledgement);
              break;
            }

          case 'l': {
              //change the brightness value of fixation LEDs based on user input
              if (longit.toInt() != 0) {
                fixationStrength = longit.toInt();
                //  Serial.println(4);

                analogWrite(fixationLED, fixationStrength);
              }
              break;
            }
          case 'h': {
              // clearAll();
              // turn off the fixation
              //  Serial.println(5);
              analogWrite(fixationLED, 0);
              Br = 1;
               //Set The Color of the LED in Strip 
                r = Red;
                g = Green;
                b= Blue;
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
              //    Serial.println(6);
              analogWrite(fixationLED, 0);
              Br = 1;
               //Set The Color of the LED in Strip 
                r = Red;
                g = Green;
                b= Blue;
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
          patterns = false;
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


  // Reset the Values in the function for a new start
  riseCounter = 0 ;
  fixedCounter = 0;
  fallCounter = 0;
  riseDone = false;
  fallDone = false;
  fixedDone = false;

  // Reset the Values in the function for a new start
  riseCounterRM = 0 ;
  fixedCounterRM = 0;
  fallCounterRM = 0;
  riseDoneRM = false;
  fallDoneRM = false;
  fixedDoneRM = false;

  // No Pattern and No Sweep 
  patterns = false;
  sweep = false;

  // then put on fixation
  // Serial.println(fixationStrength);
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
  //analogWrite(fixationLED, 0);
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



boolean fountainModel(int startPixelNumberFM, int numOfPixelsInSetFM, int endPixelNumberFM,   byte meridiansToBeOnFM[], byte numOfMeridians, int  stepSizeFM ) {
  //The generalised function where you can address each and every LED at a particular instance on the Specified Meridians
  //This function is like a goto statement where it makes LEDs travel from the Start Pixel to End Pixel with Rising LED by LED to a set and travel with the set
  // towards End Pixel and Finally falls LED by LED. At the end it returns true when the patternis completed for the parameters given

  boolean fountainModelDone = false;
  byte pixelIndex ;

  // To Skip RISE if not required
  if (wayImplementFM == fixed || wayImplementFM == fixedFall) {
    riseCounter = numOfPixelsInSetFM - 1;
    riseDone = true;
  }

  // To skip FALL if not required
  if (wayImplementFM == fixed || wayImplementFM == riseFixed) { // Dont Use Substring because program might crash here.
    fallCounter = numOfPixelsInSetFM - 1;
    fallDone = true;
  }

  //Set whether Rise is completed/Not Required
  if ((riseCounter == numOfPixelsInSetFM - 1)) {
    riseDone = true;
  } else {
    riseDone = false;
  }

  //Set Whether Fixed is Not Required/ Completed
  if ((fixedCounter == (startPixelNumberFM - endPixelNumberFM - numOfPixelsInSetFM + 2)) ) {
    fixedDone = true;
  } else {
    fixedDone = false;
  }

  //Set  whether Fall is completed / Not required {This is here to maintain uniform delay through out the sequence]
  if (fallCounter == numOfPixelsInSetFM - 1) {
    fallDone = true;
  } else {
    fallDone = false;
  }

  // Code for RISE
  if (riseCounter < numOfPixelsInSetFM - 1 ) {
    pixelIndex = 0; // Initialise the index pointer to store the Pixel numbers for Daisy Chain

    meridians[24].clear();
    meridians[24].show();
    //get the meridians to be turned on
    for (int ii = 0; ii < numOfMeridians; ii++) {
      int meridian_to_be_turned_on = meridiansToBeOnFM[ii] - 1;

      //It is good to clear and on the required Pixels
      meridians[meridian_to_be_turned_on].clear();
      meridians[meridian_to_be_turned_on].setBrightness(Br);

      //Turn On the required pixels at once, starting from startPixelNumberFM
      for (int j = 0; j <= riseCounter; j++) {
        if ((startPixelNumberFM - j - 1) >= 3) {
          meridians[meridian_to_be_turned_on].setPixelColor(startPixelNumberFM - j - 4, r, g, b);
        } else {

          // Push the Pixel Numbers into an array and at the last all the pixels are turned ON at once for theat iteration.
          byte pixNum = 3 * meridian_to_be_turned_on + 3 - (startPixelNumberFM - j);
          daisyPixelsTurnOn [pixelIndex] = pixNum;
          pixelIndex = pixelIndex + 1;
        }
      }
      meridians[meridian_to_be_turned_on].show();
    }

    if (pixelIndex > 0) {
      turnOnDaisy(daisyPixelsTurnOn, pixelIndex);
    }

    riseCounter = riseCounter + 1;
  }



  //Code for Fixed
  if (fixedCounter < (startPixelNumberFM - endPixelNumberFM - numOfPixelsInSetFM + 2) && riseDone == true) {
    pixelIndex = 0;

    meridians[24].clear();
    meridians[24].show();

    for (int ii = 0; ii < numOfMeridians; ii++) {
      int meridian_to_be_turned_on = meridiansToBeOnFM[ii] - 1;

      meridians[meridian_to_be_turned_on].clear();
      meridians[meridian_to_be_turned_on].setBrightness(Br);

      // Move the Pixels Set starting from startPixelNumberFM step by step till the endPixelNumberFM
      int j;
      for ( j = 0 ; j < numOfPixelsInSetFM; j++) {
        if ((startPixelNumberFM - fixedCounter - j) > 3) {
          meridians[meridian_to_be_turned_on].setPixelColor(startPixelNumberFM - fixedCounter - 4 - j, r, g, b);
        } else {
          byte pixNum = 3 * meridian_to_be_turned_on + ( 3 - startPixelNumberFM + fixedCounter + j);
          daisyPixelsTurnOn [pixelIndex] = pixNum;
          pixelIndex = pixelIndex + 1;
        }
      }

      meridians[meridian_to_be_turned_on].show();

    }

    //Set the pixels On in Daisy Chain if required(PixelIndex > 0)
    if (pixelIndex > 0) {
      //CKR   Serial.println(pixelIndex);
      turnOnDaisy(daisyPixelsTurnOn, pixelIndex);
    }

    fixedCounter += 1;
  }


  //Code for Fall
  if (fallCounter  < numOfPixelsInSetFM - 1  && fixedDone == true) {
    pixelIndex = 0;

    meridians[24].clear();
    meridians[24].show();

    //Execute on all the meridians in the array
    for (int ii = 0; ii < numOfMeridians; ii++) {
      int meridian_to_be_turned_on = meridiansToBeOnFM[ii] - 1;

      // It is good to clear the meridians and set the pixels ON
      meridians[meridian_to_be_turned_on].clear();
      meridians[meridian_to_be_turned_on].setBrightness(Br);

      // Turn On the appropriate Pixels according to the iteration
      for (int j = fallCounter + 1; j < numOfPixelsInSetFM    ; j++) {
        if ((endPixelNumberFM  + numOfPixelsInSetFM - 1 - j) > 3) {
          meridians[meridian_to_be_turned_on].setPixelColor(endPixelNumberFM - 1 + numOfPixelsInSetFM - 1 - j - 3, r, g, b);
        } else {
          byte pixNum = 3 * meridian_to_be_turned_on + 3 - (endPixelNumberFM  + numOfPixelsInSetFM - 1 - j);
          daisyPixelsTurnOn [pixelIndex] = pixNum;
          pixelIndex = pixelIndex + 1;
        }
      }
      meridians[meridian_to_be_turned_on].show();
    }

    if (pixelIndex > 0) {
      //CKR  Serial.println(pixelIndex);
      turnOnDaisy(daisyPixelsTurnOn, pixelIndex);
    }
    fallCounter = fallCounter + 1;
  }


  //Reset the counters and different variables used to run the function
  if (riseDone == true && fixedDone == true && fallDone == true) {
    fountainModelDone = true;
    riseCounter = 0;
    fixedCounter = 0;
    fallCounter = 0;
    riseDone = false;
    fixedDone = false;
    fallDone = false;

  } else {
    fountainModelDone = false;
  }

  /*
    Serial.print("FM  :");
    Serial.print(riseCounter); Serial.print(",");
    Serial.print(fixedCounter); Serial.print(",");
    Serial.println(fallCounter);

    Serial.print("ToBeReturned  "); Serial.println(freeRam()); */
  return fountainModelDone;
}



//Function to on the required pixels in Daisy chain
void turnOnDaisy(byte pixels[], byte numOfPixels) {
  meridians [24].clear();

  meridians[24].setBrightness(Br);
  for (int i = 0; i < numOfPixels; i++) {
    //CKR    Serial.println(pixels[i]);
    //get The Daisy Equivalent pixel
    int quot = daisyConverter((pixels[i] / 3) + 1 );
    int rem = pixels[i] % 3;
    pixels[i] = 3 * quot + rem ;
    meridians[24].setPixelColor(pixels[i], r, g, b);
  }
  meridians[24].show();
}


boolean rotationModel(int startPixelNumberRM, int startMeridianNumberRM, int numOfPixelsInSetRM, int numOfMeridiansInSetRM, int endMeridianNumberRM, int endPixelNumberRM,  int  stepSizeRM ) {

  boolean rotationModelDone = false;

  if (wayImplementRM == fixed || wayImplementRM == fixedFall) {

    riseCounterRM = numOfMeridiansInSetRM - 1;
    riseDoneRM = true;
  }
  // }
  //Set the fallCounter value based on the "wayImplemented"
  if (wayImplementRM == fixed || wayImplementRM == riseFixed) { // Donot Use Substring because the program might crash
    fallCounterRM = numOfMeridiansInSetRM - 1;
    fallDoneRM = true;
  }

  //Set whether Rise is completed/Not Required
  if ((riseCounterRM == numOfMeridiansInSetRM - 1)) {
    riseDoneRM = true;
  } else {
    riseDoneRM = false;
  }

  //Set Whether Fixed is Not Required/ Completed
  if ((fixedCounterRM == ((endMeridianNumberRM % 24) + 24 - startMeridianNumberRM  - numOfMeridiansInSetRM + 2)))  {
    fixedDoneRM = true;
  } else {
    fixedDoneRM = false;
  }

  //Set  whether Fall is completed / Not required {This is here to maintain uniform delay through out the sequence]
  if (fallCounterRM == numOfMeridiansInSetRM - 1) {
    fallDoneRM = true;
  } else {
    fallDoneRM = false;
  }

  // Code for RISE
  if (riseCounterRM < numOfMeridiansInSetRM - 1 ) {
    int j;
    //Get the Meridian Number to be turned ON
    for (j = 0; j <= riseCounterRM; j++) {
      meridianNumbersRM[j] = (startMeridianNumberRM + j) % 24;
    }

    if (j > 0) {
      wayImplementFM = fixed;
      verifyTest = fountainModel(startPixelNumberRM, numOfPixelsInSetRM, startPixelNumberRM - numOfPixelsInSetRM + 1, meridianNumbersRM, j, 2);

      if (verifyTest == true) {
        riseCounterRM = riseCounterRM + 1;
      }
    }
  }

  //Code for Fixed
  if (fixedCounterRM < ((endMeridianNumberRM % 24) + 24 - startMeridianNumberRM  - numOfMeridiansInSetRM + 2) && riseDoneRM == true) {

    int j;

    for ( j = 0 ; j < numOfMeridiansInSetRM; j++) {
      meridianNumbersRM[j] = (startMeridianNumberRM + fixedCounterRM + j ) % 24;
      if (meridianNumbersRM[j] == 0) {
        meridianNumbersRM [j] = 24;
      }
    }

    //Set the pixels On in Daisy Chain if required(PixelIndex > 0)
    if (j > 0) {
      wayImplementFM = fixed;
      verifyTest = fountainModel(startPixelNumberRM, numOfPixelsInSetRM, startPixelNumberRM - numOfPixelsInSetRM + 1,  meridianNumbersRM, j, 2);
      meridians[meridianNumbersRM[0] - 1].clear();
      meridians[meridianNumbersRM[0] - 1].show();

      if (verifyTest == true) {
        fixedCounterRM = fixedCounterRM + 1;
      }
    }
  }

  //Code for Fall
  if (fallCounterRM  < numOfMeridiansInSetRM - 1  && fixedDoneRM == true) {

    int j;

    for ( j = 0; j < numOfMeridiansInSetRM - fallCounterRM - 1 ; j++) {
      meridianNumbersRM[j ] = (endMeridianNumberRM - j) % 24;
      if ((endMeridianNumberRM - j) == 24 ) {
        meridianNumbersRM [j ] = 24;
      }
    }

    for (int k = 0; k < j ; k++) {
    }

    if (j > 0) {
      wayImplementFM = fixed;
      verifyTest = fountainModel(startPixelNumberRM, numOfPixelsInSetRM, startPixelNumberRM - numOfPixelsInSetRM + 1,   meridianNumbersRM, j, 2);
      meridians[meridianNumbersRM[j - 1] - 1].clear();
      meridians[meridianNumbersRM[j - 1] - 1].show();
      if (verifyTest == true) {
        fallCounterRM = fallCounterRM + 1;
      }
    }
  }

  //Reset the counters and different variables used to run the function
  if (riseDoneRM == true && fixedDoneRM == true && fallDoneRM == true) {

    rotationModelDone = true;
    //CKR   Serial.println("One rotation Completed");
    riseCounterRM  = 0;
    fixedCounterRM = 0;
    fallCounterRM  = 0;
    riseDoneRM  = false;
    fixedDoneRM = false;
    fallDoneRM  = false;

  } else {
    rotationModelDone = false;
  }
  // Serial.print("RM ended & to be Returned");

  //CKR  Serial.print("RM  :");
  //CKR  Serial.print(riseCounterRM);Serial.print(",");
  //CKR Serial.print(fixedCounterRM);Serial.print(",");
  // CKR Serial.println(fallCounterRM);
  // Serial.print("RM End : "); Serial.println(freeRam());
  return rotationModelDone;
}

/*
  int freeRam () {
  extern int __heap_start, *__brkval;
  int v;
  return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval);
  }

*/
//function that Updates Meridian numbers to be turned ON in pattern - 3
void  updateMeridianNumbersCKR() {

  int k = 0;

  for (int i = 1; i <= 24; i++) {
    if ( (i % 6) != ((counterCKR + 1) % 6) ) {
      meridianNumbersCKR[k] = i ;
      k++;
    } else {
      meridians[i - 1]. clear();
      meridians[i - 1].show();
    }
  }
}

/* DEPRECATED ********************************************************************************************
  void readSweepIntervals(int chosenStrip) {

  /*
     Function to read sweep interval values being sent by GUI;
     It reads until it reaches '\n' i.e. endOfLine;
     A comma is a delimiter, hence, it stores the value from before the comma and then continues to read;
     At the end, it sends 98 to acknowledge that it has recieved the required number of elements

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

