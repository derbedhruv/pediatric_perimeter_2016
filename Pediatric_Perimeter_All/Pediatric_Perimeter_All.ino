/**************************************************************
//  PEDIATRIC PERIMETER ARDUINO SEGMENT FOR ADDRESSABLE LEDs
//  SRUJANA CENTER FOR INNOVATION, LV PRASAD EYE INSTITUTE
//
//  AUTHORS: Sankalp Modi, Darpan Sanghavi, Dhruv Joshi
//
//  This code gives the user the following possible LED outputs through
//  serial addressing:
//  1. Hemispheres: Turning on half of the pediatric perimeter 'sphere'
//    "h,l" for the left hemisphere
//    "h,r" for the right hemisphere
//    "h,a" for the left hemi without the central 30 degrees
//    "h,b" for the right hemi without the central 30 degrees
//
//
***************************************************************/

//NeoPixel Library from Adafruit is being used here
#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
#include <avr/power.h>
#endif

#define Br 20      // This is where you define the brightness of the LEDs - this is constant for all

// Declare Integer Variables for RGB values. Define Colour of the LEDs.
// Moderately bright green color.
int r = 163, g = 255, b = 4;


/**************************************************************************************************
//
//  ARDUINO PIN CONFIGURATION TO THE LED STRIPS AND HOW MANY PIXELS TO BE TURNED ON ON EACH STRIP!!
//
//  Arduino Pin     :  16 15 3  22 21 20 34 32 30 42  44  46  48  50  52  40  38  36  28  26  24  19  18  17  11     12
//  Meridian Label  :  1  2  3  4  5  6  7  8  9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  daisy  fixation
//  Meridian angle  :
//  (in terms of the isopter)
*************************************************************************************************/
short pinArduino[] = {16, 15,  3, 22, 21, 20 ,34, 32, 30, 42, 44, 46, 48, 50, 52, 40, 38, 36, 28, 26, 24, 19, 18, 17, 11};
short numPixels[] =  {24, 24, 24, 24, 24, 11, 11, 12, 23, 23, 25, 24, 24, 26, 23, 24, 11,  9,  9,  9, 11, 26, 24, 24, 72};    // there are 72 in the daisy chain

Adafruit_NeoPixel meridians[25];    // create meridians object array for 24 meridians + one daisy-chained central strip

/*************************************************************************************************/

// THE FOLLOWING ARE VARIABLES FOR THE ENTIRE SERIALEVENT INTERRUPT ONLY
// the variable 'breakOut' is a boolean which is used to communicate to the loop() that we need to immedietely shut everything off
String inputString = "", lat = "", longit = "";
boolean acquired = false, breakOut = false, sweep = false;
unsigned long currentMillis;
int sweepStart, longitudeInt, Slider = 255, currentSweepLED;
int fixationLED = 12;


void setup() {
  // setup serial connection
  Serial.begin(9600);
  Serial.println("starting..");
  
  for(int i = 0; i < 25; i++) {
    Serial.println("setting up meridian " + String(i));
    // When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
    meridians[i] = Adafruit_NeoPixel(numPixels[i], pinArduino[i], NEO_GRB + NEO_KHZ800);
  }
  clearAll();
  // daisyChainN(14);
}

void loop() {
  // keep polling for breakOut - it is because of this polling behaviour that we shouldn't use a delay() anywhere.
  if (breakOut == true) {
     clearAll(); 
  }
}

/*
void serialEvent() {
  if (Serial.available()) {
    char in = (char)Serial.read();
    Serial.println("putting on sphere");
    sphere();
  }
}
*/


// CATCH SERIAL EVENTS AND THEN RUN THE APPROPRIATE FUNCTIONS
void serialEvent() {
  if (Serial.available()) {
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
        
      // we deal with 3 cases: sweeps, hemispheres and quadrants
     switch(lat[0]) {  // use only the first character, the rest is most likely garbage
         
       // this is the case of setting brightness of the LEDs
       case 'm':{
         // brightness = String(longit).toInt();
         break;
       }
       
       // change sweep time
       case 't':{
         // interval= longit.toInt();
         break;
       }
       
       // choose strip to sweep
       case 's': {
         // this is the case of sweeping a single longitude. 
         // remember to serial.print the present LED which is on - this will be reflected in the processing program (with the delay removed as much as possible)
       }
 
       case 'l':{
           // put on the fixation LED
       }
       
       case 'h': {     
         digitalWrite(fixationLED,LOW);
         // we then switch through WHICH hemisphere
         switch(longit[0]){
           case 'l': {
             // THis is the hemisphere case. Turn on all the latitudes..
             // LEFT hemisphere.. 
             Serial.println("left hemi");
             hemisphere1();
             break;
           }
           case 'r': { 
             // THis is the hemisphere case. Turn on all the latitudes..
             
             break;  
           }
           // 30 degrees and outer case:
           case 'a': {
             
             break;
           }
           case 'b': { 
             
             break;  
           }
         }
         break;
       }
       case 'q': {
         // quadrants..
         digitalWrite(fixationLED,LOW);
         switch(longit[0]) {
           // we shall go anticlockwise. "1" shall start from the bottom right. 
          case '1': {
            // latitudes.. all on
            
            break;
          } 
          case '2': {
            // latitudes.. all on
            
            break;
          } 
          case '3': {
            // latitudes.. all on
            
            break;
          } 
          case '4': {
            // latitudes.. all on
            
            break;
          } 
          case '5': {
            // turn on only the 30 degrees and higher latitudes
            
            break;
          }
          case '6': {
            // turn on only the 30 degrees and higher latitudes
            
            break;
          }
          case '7': {
            // turn on only the 30 degrees and higher latitudes
            
            break;
          }
         case '8': {
            // turn on only the 30 degrees and higher latitudes
            
            break;
          } 
         }
         break;
       }
     } 
        
        if (longit[0] == 'x') {
          // put everything off, but put the fixation back on
          digitalWrite(fixationLED, HIGH);
          // breakOut = true;  // break out of the loops yo
          clearAll();
          delay(1);
          // reset everything...
          sweep = false;
        } else {
          digitalWrite(fixationLED,LOW);
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

void sweepStripN(int n){
  // kinetic sweep of a strip, starting from the last
}

void clearAll() {
  // put them all off
  for(int i = 1; i <= 25; i++) {
    clearN(i);
  }
}

void clearN(int n) {
  // put off a particular meridian specified by n
    meridians[n-1].clear();
    meridians[n-1].setBrightness(0);      // because we want to "clear all"
    meridians[n-1].begin();
    meridians[n-1].show();
} 

void sphere() {
  //To draw a sphere with all the LED's on in the Perimeter, each strip is being called.
  //Pixels 25 is the strip for Daisy Chain with 72 LED's on in all.
  for(int i = 0; i < 25; i++) {
    // meridians[i].clear();
    fullStripN(i);
  }
}

//Initialises Hemisphere 1 - Left Hemisphere: Physical Meridian numbers 7 to 19.
void hemisphere1() {
  for(int i = 7; i <= 19; i++) { //take a full 25 loop, and clear() all the other ones? --------------------
    fullStripN(i);
  }
}

//Initializes Hemisphere 2 - Right Hemisphere
void hemisphere2() {
  for(int i = 0; i < 25; i++) { 
    if( (i > 18 && i != 24) || (i < 7) ){ //between physical meridians 19 and 24, or 1 to 7. Not the daisy chain "meridian".
      
    }
  }
}

//Initializes Quadrant 1
void quad1() {
  for(int i = 0; i < 6; i++) { 
    meridians[i].begin();
  }
}

//Initializes Quadrant 2
void quad2() {
  for(int i = 6; i < 12; i++) { 
    meridians[i].begin();
  }
}

//Initializes Quadrant 3
void quad3() {
  for(int i = 12; i < 18; i++) { 
    meridians[i].begin();
  }
}

//Initializes Quadrant 4
void quad4() {
  for(int i = 18; i < 24; i++) { 
    meridians[i].begin();
  }
}

void fullStripAll() {
  for(int i = 1; i <= sizeof(pinArduino); i++) {
     // turn on all strips 
    fullStripN(i);
  }
}

void lightPixelStripN(int strip, int Pixel) {
  // light up the 'n' meridian
  meridians[strip].setBrightness(Br);
  meridians[strip].setPixelColor(Pixel, r,g,b);
  meridians[strip].show(); // This sends the updated pixel color to the hardware.
  meridians[strip].begin();
}

void onlyStripN(int strip) {
  // For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.
  meridians[strip-1].setBrightness(Br);
  setStripColorN(strip-1);
  meridians[strip-1].show(); // This sends the updated pixel color to the hardware.
  meridians[strip-1].begin();
}

void daisyChainN(int n){
  // first we need to convert the "real world" meridians into "daisy chain" coordinate meridians.
  if (n < 8) {
    n = 7 - n;
  } else {
    n = -n + 31;
  }
  
  // Code for lighting the appropriate LEDs for the Nth meridian. For Physical meridian 1 (j=0), Daisy strips' 1st ,2nd and 3rd LEDs are switched on.
  for(int j = 3*n; j < 3*n + 3; j++) {
    lightPixelStripN(24, j);
  }
}

void fullStripN(int n) {
  // this is a debugging mechanism to turn on all the strips and the daisy chain strip as well
  onlyStripN(n);
  daisyChainN(n);
}

void setStripColorN(int n) {
  // set colour on all LEDs for a strip 'n'
  for (int j = 0; j < numPixels[n]; j++) {
      meridians[n].setPixelColor(j, r,g,b);
  }
}
