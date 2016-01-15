// Pediatric Perimeter LED Addressing - Kanospa Mild - 21-12-15
// LVPEI Srujana Innovation

//NeoPixel Library from Adafruit
#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
#include <avr/power.h>
#endif

#define Br 10

// Declare Integer Variables for RGB values. Define Colour of the LEDs.
// Moderately bright green color.
int r=163; int g=255; int b=0;

//The number of LEDs corresponding to each meridian. Note that array index 0 is actually 
//the physical meridian labelled 1. Edit the values accordingly.

//__int8 is the best choice. No other complications right? --------
// Which pin on the Arduino is connected to the NeoPixels?
short pinArduino[] = {16, 15, 3, 22, 21, 20 ,34, 32, 30, 42, 44, 46, 48, 50, 52, 40, 38, 36, 28, 26, 24, 19, 18, 17, 00};
// How many NeoPixels are attached to the strips?
short numPixels[] = {24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24};
Adafruit_NeoPixel meridians[25];

void setup() {
  for(int i = 0;i<25;i++) {
    // When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
    meridians[i] = Adafruit_NeoPixel(numPixels[i], pinArduino[i], NEO_GRB + NEO_KHZ800);
  }

  sphere();
  delay(1000);
  clearAll();
  //hemisphere1();
  //delay(1000);
  //hemisphere2();
  //delay(1000);
  //quad1();
  //delay(1000);
  //quad2();
  //delay(1000);
  //quad3();
  //delay(1000);
  //quad4();
  //delay(1000);
  //strip1();
  //delay(1000);
  ///strip2();
  //delay(1000);
  //strip3();
  //delay(1000);
  //strip4();
  //delay(1000);
  //strip5();
  //delay(1000);
}

void clearAll() {
  for(int i = 0; i<25; i++) {
    clearN(i);
  }
}

void clearN(int n) {
  meridians[n].clear();
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

void loop() {
  fullStripAll();
  // Daisy Chain Strip
  // strip25();
}

void fullStripAll() {
  for(int i = 0; i<24; i++) {
    fullStripN(i);
  }
}

void onlyStripN(int n) {
  // For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.
  for(int j=0; j<numPixels[n]; j++) {
    // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    meridians[n].setBrightness(Br);
    meridians[n].setPixelColor(j, meridians[24].Color(r,g,b)); //--------------why meridians[24].color???
    meridians[n].show(); // This sends the updated pixel color to the hardware.
    //  delay(0); // Delay for a period of time (in milliseconds).
  }
}

void daisyChainN(int n){
  // Code for lighting the appropriate LEDs for the Nth meridian. For Physical meridian 1 (j=0), Daisy strips' 1,2 and 3 are switched on
  for(int j=n*3;j<(n*3+3);j++) {
    meridians[24].setBrightness(Br);
    meridians[24].setPixelColor(j, meridians[24].Color(r,g,b));
    meridians[24].show();// This sends the updated pixel color to the hardware.
    //  delay(0); // Delay for a period of time (in milliseconds).
  }
}

void fullStripN(int n) { //HERE, n starts from 0. ------------------------------------------------
  onlyStripN(n);
  daisyChain(n);
}
/*void strip25() {

  // For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.
//Numpixel =71 (72-1, LED Count starts from 0)
  for(int i=0;i<NUMPIXELS25;i++){

    // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels.setBrightness(20);
    pixels.setPixelColor(i, pixels.Color(r,g,b)); // Moderately bright green color.

    pixels.show(); // This sends the updated pixel color to the hardware.

    delay(0); // Delay for a period of time (in milliseconds).

  }
}
*/