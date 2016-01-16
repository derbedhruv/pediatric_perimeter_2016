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

#define Br 30      // This is where you define the brightness of the LEDs - this is constant for all

// Declare Integer Variables for RGB values. Define Colour of the LEDs.
// Moderately bright green color.
int r = 163, g = 255, b = 4;

/**************************************************************************************************
//
//  ARDUINO PIN CONFIGURATION TO THE LED STRIPS AND HOW MANY PIXELS TO BE TURNED ON ON EACH STRIP!!
//
//  Arduino Pin     :  16 15 3  22 21 20 34 32 30 42  44  46  48  50  52  40  38  36  28  6   24  19  18  12  11     13
//  Meridian Label  :  1  2  3  4  5  6  7  8  9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  daisy  fixation
//  Meridian angle  :
//  (in terms of the isopter)
*************************************************************************************************/
short pinArduino[] = {16, 15, 3, 22, 21, 20 ,34, 32, 30, 42, 44, 46, 48, 50, 52, 40, 38, 36, 28, 26, 24, 19, 18, 17, 00};
short numPixels[] = {24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24};

Adafruit_NeoPixel meridians[25];    // create meridians object array for 24 meridians + one daisy-chained central strip

/*************************************************************************************************/

void setup() {
  for(int i = 0; i < sizeof(pinArduino); i++) {
    // When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
    meridians[i] = Adafruit_NeoPixel(numPixels[i], pinArduino[i], NEO_GRB + NEO_KHZ800);
  }
}

void loop() {
  // we don't really do anything here.. for now
  fullStripAll();
  delay(2000);
  clearAll();
  delay(3000);
}


void sweepStripN(int n){
  // kinetic sweep of a strip, starting from the last
}

void clearAll() {
  // put them all off
  for(int i = 0; i<25; i++) {
    clearN(i);
  }
}

void clearN(int n) {
  // put off a particular meridian specified by n
  meridians[n].clear();
  meridians[n].show();
} 

void sphere() {
  //To draw a sphere with all the LED's on in the Perimeter, each strip is being called.
  //Pixels 25 is the strip for Daisy Chain with 72 LED's on in all.
  for(int i = 0; i < 25; i++) {
    meridians[i].begin();
  }
}

//Initialises Hemisphere 1 - Left Hemisphere: Physical Meridian numbers 7 to 19.
void hemisphere1() {
  for(int i = 6; i < 19; i++) { //take a full 25 loop, and clear() all the other ones? --------------------
    meridians[i].begin();
  }
}

//Initializes Hemisphere 2 - Right Hemisphere
void hemisphere2() {
  for(int i = 0; i < 25; i++) { 
    if( (i>18 && i!=24) || (i<7) ){ //between physical meridians 19 and 24, or 1 to 7. Not the daisy chain "meridian".
      meridians[i].begin();
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

void lightPixelStripN(int n, int pixel) {
  // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
  meridians[n-1].setBrightness(Br);
  meridians[n-1].setPixelColor(pixel, meridians[24].Color(r,g,b));
  meridians[n-1].show(); // This sends the updated pixel color to the hardware.
  meridians[n-1].begin();
}

void onlyStripN(int n) {
  // For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.
  for(int j=0; j < numPixels[n-1]; j++) {
    lightPixelStripN(n, j);
  }
}

void daisyChainN(int n){
  n = n - 1;    // so that we can continue using natural numbers for referring to the meridians - easy to debug
  // Code for lighting the appropriate LEDs for the Nth meridian. For Physical meridian 1 (j=0), Daisy strips' 1st ,2nd and 3rd LEDs are switched on.
  for(int j = n*3; j < 3*(n + 1); j++) {
    lightPixelStripN(24, j);
  }
}

void fullStripN(int n) { //HERE, n starts from 0. 
  onlyStripN(n-1);
  daisyChainN(n-1);
}
