// Pediatric Perimeter LED Addressing - Kanospa Mild - 21-12-15
// LVPEI Srujana Innovation

//NeoPixel Library from Adafruit
#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
#include <avr/power.h>
#endif


// Which pin on the Arduino is connected to the NeoPixels?
#define PIN1            4
#define PIN2            15
#define PIN3            16
#define PIN4            17
#define PIN5            18
#define PIN6            19
#define PIN7            20
#define PIN8            21
#define PIN9            22
#define PIN10           24
#define PIN11           26
#define PIN12           28
#define PIN13           30
#define PIN14           32
#define PIN15           34
#define PIN16           36
#define PIN17           38
#define PIN18           40
#define PIN19           42
#define PIN20           44
#define PIN21           46
#define PIN22           48
#define PIN23           50
#define PIN24           52
//Dasiy Pin
#define PIN25           52

#define Colour 163,255,0
#define Br 2
// How many NeoPixels are attached to the strips?
#define NUMPIXELS1      24
#define NUMPIXELS2      24
#define NUMPIXELS3      24
#define NUMPIXELS4      24
#define NUMPIXELS5      24
#define NUMPIXELS6      24
#define NUMPIXELS7      24
#define NUMPIXELS8      24
#define NUMPIXELS9      24
#define NUMPIXELS10     24
#define NUMPIXELS11     24
#define NUMPIXELS12     24
#define NUMPIXELS13     24
#define NUMPIXELS14     24
#define NUMPIXELS15     24
#define NUMPIXELS16     24
#define NUMPIXELS17     24
#define NUMPIXELS18     24
#define NUMPIXELS19     24
#define NUMPIXELS20     24
#define NUMPIXELS21     24
#define NUMPIXELS22     24
#define NUMPIXELS23     24
#define NUMPIXELS24     24

//Daisy LED's - 72
#define NUMPIXELS25     72



// When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
Adafruit_NeoPixel pixels1=  Adafruit_NeoPixel(NUMPIXELS1, PIN1, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels2=  Adafruit_NeoPixel(NUMPIXELS2, PIN2, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels3=  Adafruit_NeoPixel(NUMPIXELS3, PIN3, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels4=  Adafruit_NeoPixel(NUMPIXELS4, PIN4, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels5=  Adafruit_NeoPixel(NUMPIXELS5, PIN5, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels6=  Adafruit_NeoPixel(NUMPIXELS6, PIN6, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels7=  Adafruit_NeoPixel(NUMPIXELS7, PIN7, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels8=  Adafruit_NeoPixel(NUMPIXELS8, PIN8, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels9=  Adafruit_NeoPixel(NUMPIXELS9, PIN9, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels10= Adafruit_NeoPixel(NUMPIXELS10, PIN10, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels11= Adafruit_NeoPixel(NUMPIXELS11, PIN11, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels12= Adafruit_NeoPixel(NUMPIXELS12, PIN12, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels13= Adafruit_NeoPixel(NUMPIXELS13, PIN13, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels14= Adafruit_NeoPixel(NUMPIXELS14, PIN14, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels15= Adafruit_NeoPixel(NUMPIXELS15, PIN15, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels16= Adafruit_NeoPixel(NUMPIXELS16, PIN16, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels17= Adafruit_NeoPixel(NUMPIXELS17, PIN17, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels18= Adafruit_NeoPixel(NUMPIXELS18, PIN18, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels19= Adafruit_NeoPixel(NUMPIXELS19, PIN19, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels20= Adafruit_NeoPixel(NUMPIXELS20, PIN20, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels21= Adafruit_NeoPixel(NUMPIXELS21, PIN21, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels22= Adafruit_NeoPixel(NUMPIXELS22, PIN22, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels23= Adafruit_NeoPixel(NUMPIXELS23, PIN23, NEO_GRB + NEO_KHZ800);
Adafruit_NeoPixel pixels24= Adafruit_NeoPixel(NUMPIXELS24, PIN24, NEO_GRB + NEO_KHZ800);

//Daisy Chain Strip
Adafruit_NeoPixel pixels25= Adafruit_NeoPixel(NUMPIXELS25, PIN25, NEO_GRB + NEO_KHZ800);

auto c=pixels1.Color(255,0,0);

void setup()
{
 
sphere();
//delay(1000);
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



void sphere() {
//To draw a sphere with all the LED's on in the Perimeter, each strip is being called.
//Pixels 25 is the strip for Daisy Chain with 72 LED's on in all.
//pixels.show(); // Initialize all pixels to 'off'
  
  pixels25.begin();
//Pixels 25 is the strip for Daisy Chain with 72 LED's on in all.

  pixels1.begin();
  pixels2.begin();
  pixels3.begin();
  pixels4.begin();
  pixels5.begin();
  pixels6.begin();
  pixels7.begin();
  pixels8.begin();
  pixels9.begin();
  pixels10.begin();
  pixels11.begin();
  pixels12.begin();
  pixels13.begin();
  pixels14.begin();
  pixels15.begin();
  pixels16.begin();
  pixels17.begin();
  pixels18.begin();
  pixels19.begin();
  pixels20.begin();
  pixels21.begin();
  pixels22.begin();
  pixels23.begin();
  pixels24.begin();

}


//Initialises Hemisphere 1 - Left Hemisphere.
void hemisphere1() {
  
  pixels1.begin();
  pixels2.begin();
  pixels3.begin();
  pixels4.begin();
  pixels5.begin(); 
  pixels6.begin();
  pixels7.begin();
  pixels8.begin();
  pixels8.begin();
  pixels10.begin();
  pixels11.begin();
  pixels12.begin();
//pixels.show(); // Initialize all pixels to 'off'
}

//Initializes Hemisphere 2 - Right Hemisphere
void hemisphere2() {
  
  pixels13.begin();
  pixels14.begin();
  pixels15.begin();
  pixels16.begin();
  pixels17.begin(); 
  pixels18.begin();
  pixels19.begin();
  pixels20.begin();
  pixels21.begin();
  pixels22.begin();
  pixels23.begin();
  pixels24.begin();

//pixels.show(); 
// Initialize all pixels to 'off'
}

//Initializes Quadrant 1
void quad1() {

  pixels1.begin();
  pixels2.begin();
  pixels3.begin();
  pixels4.begin();
  pixels5.begin();
  pixels6.begin();

//pixels.show(); 
// Initialize all pixels to 'off'
}

//Initializes Quadrant 2
void quad2() {
  
  pixels7.begin();
  pixels8.begin();
  pixels9.begin();
  pixels10.begin();
  pixels11.begin();
  pixels12.begin();

//pixels.show(); 
// Initialize all pixels to 'off'
}

//Initializes Quadrant 3
void quad3() {
  
  pixels13.begin();
  pixels14.begin();
  pixels15.begin();
  pixels16.begin();
  pixels17.begin();
  pixels18.begin();

//pixels.show();
// Initialize all pixels to 'off'
}

//Initializes Quadrant 4
void quad4() {

  pixels19.begin();
  pixels20.begin();
  pixels21.begin();
  pixels22.begin();
  pixels23.begin();
  pixels24.begin();

//pixels.show();
// Initialize all pixels to 'off'
}



void loop(){
  
  strip1();
  strip2();
  strip3();
  strip4();
  strip5();
  strip6();
  strip7();
  strip8();
  strip9();
  strip10();
  strip11();
  strip12();
  strip13();
  strip14();
  strip15();
  strip16();
  strip17();
  strip18();
  strip19();
  strip20();
  strip21();
  strip22();
  strip23();
  strip24();
  
  //Daisy Chain Strip
//  strip25();
  
 }

void strip1() {
// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS1;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels1.setBrightness(Br);
    pixels1.setPixelColor(i,c); // Moderately bright green color.
    pixels1.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the first 3 LEDs of the Daisy Strip. First three LED's lie on the same Meridian - 1.
  for(int j=0;j<3;j++){

// pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

}
}





void strip2() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS2;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels1.setBrightness(Br);
    pixels1.setPixelColor(i, pixels1.Color(163,255,0)); // Moderately bright green color.
    pixels1.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }

// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 2.
  for(int j=3;j<6;j++){

// pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}
}




void strip3() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS3;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels2.setBrightness(Br);
    pixels2.setPixelColor(i, pixels2.Color(163,255,0)); // Moderately bright green color.
    pixels2.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
 }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 3.
  for(int j=6;j<9;j++){

// pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}
}





void strip4() {

  // For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS4;i++){

// pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels3.setBrightness(Br);
    pixels3.setPixelColor(i, pixels3.Color(163,255,0)); // Moderately bright green color.
    pixels3.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
  }

// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 4.
  for(int j=9;j<12;j++){

// pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}
  
}





void strip5() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS5;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels4.setBrightness(Br);
    pixels4.setPixelColor(i, pixels4.Color(163,255,0)); // Moderately bright green color.
    pixels4.show(); // This sends the updated pixel color to the hardware.

//  delay(0); // Delay for a period of time (in milliseconds).

 }

// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 5.
  for(int j=12;j<15;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}
  
}



void strip6() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS6;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels5.setBrightness(Br);
    pixels5.setPixelColor(i, pixels5.Color(163,255,0)); // Moderately bright green color.
    pixels5.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

 }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 6.
  
  for(int j=15;j<18;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}

}



void strip7() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS7;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels6.setBrightness(Br);
    pixels6.setPixelColor(i, pixels6.Color(163,255,0)); // Moderately bright green color.
    pixels6.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 7.
  for(int j=18;j<21;j++){

// pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}

}



void strip8() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS8;i++){
//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels7.setBrightness(Br);
    pixels7.setPixelColor(i, pixels7.Color(163,255,0)); // Moderately bright green color.
    pixels7.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 8.
  for(int j=21;j<24;j++){

// pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}

}




void strip9() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS9;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels8.setBrightness(Br);
    pixels8.setPixelColor(i, pixels8.Color(163,255,0)); // Moderately bright green color.
    pixels8.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 9.
  for(int j=24;j<27;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}

}




void strip10() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS10;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels9.setBrightness(Br);
    pixels9.setPixelColor(i, pixels9.Color(163,255,0)); // Moderately bright green color.
    pixels9.show(); // This sends the updated pixel color to the hardware.
    delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 10.
  for(int j=27;j<30;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}

}



void strip11() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS11;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels10.setBrightness(Br);
    pixels10.setPixelColor(i, pixels10.Color(163,255,0)); // Moderately bright green color.
    pixels10.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 11.
  for(int j=30;j<33;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}

}





void strip12() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS12;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels11.setBrightness(Br);
    pixels11.setPixelColor(i, pixels11.Color(163,255,0)); // Moderately bright green color.
    pixels11.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 12.
  for(int j=33;j<36;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}

}





void strip13() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS13;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels12.setBrightness(Br);
    pixels12.setPixelColor(i, pixels12.Color(163,255,0)); // Moderately bright green color.
    pixels12.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }

// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 13.
  for(int j=36;j<39;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}

}





void strip14() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS14;i++){

// pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels13.setBrightness(Br);
    pixels13.setPixelColor(i, pixels13.Color(163,255,0)); // Moderately bright green color.
    pixels13.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 14.
  for(int j=39;j<42;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
}

}





void strip15() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS15;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels14.setBrightness(Br);
    pixels14.setPixelColor(i, pixels14.Color(163,255,0)); // Moderately bright green color.
    pixels14.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 15.
  for(int j=42;j<45;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

}
}


void strip16() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS16;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels15.setBrightness(Br);
    pixels15.setPixelColor(i, pixels15.Color(163,255,0)); // Moderately bright green color.
    pixels15.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 16.
  for(int j=45;j<48;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
  
}
}


void strip17() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS17;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels16.setBrightness(Br);
    pixels16.setPixelColor(i, pixels16.Color(163,255,0)); // Moderately bright green color.
    pixels16.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 17.
  for(int j=48;j<51;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

}
}


void strip18() {

 // For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS18;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels17.setBrightness(Br);
    pixels17.setPixelColor(i, pixels17.Color(163,255,0)); // Moderately bright green color.
    pixels17.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 18.
  for(int j=51;j<54;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

}
}



void strip19() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS19;i++){
//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels18.setBrightness(Br);
    pixels18.setPixelColor(i, pixels18.Color(163,255,0)); // Moderately bright green color.
    pixels18.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 19.
  for(int j=54;j<57;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
  
}
}



void strip20() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS20;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels19.setBrightness(Br);
    pixels19.setPixelColor(i, pixels19.Color(163,255,0)); // Moderately bright green color.
    pixels19.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - Br.
  for(int j=57;j<60;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

}
}

void strip21() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS21;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels20.setBrightness(Br);
    pixels20.setPixelColor(i, pixels20.Color(163,255,0)); // Moderately bright green color.
    pixels20.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 21.
  for(int j=60;j<63;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

}
}

void strip22() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS22;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels21.setBrightness(Br);
    pixels21.setPixelColor(i, pixels21.Color(163,255,0)); // Moderately bright green color.
    pixels21.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 22.
  for(int j=63;j<66;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
  
}
}

void strip23() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS23;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels22.setBrightness(Br);
    pixels22.setPixelColor(i, pixels22.Color(163,255,0)); // Moderately bright green color.
    pixels22.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 23.
  for(int j=66;j<69;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).
  
}
}

void strip24() {

// For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.

  for(int i=0;i<NUMPIXELS24;i++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels23.setBrightness(20);
    pixels23.setPixelColor(i, pixels23.Color(163,255,0)); // Moderately bright green color.
    pixels23.show(); // This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

  }
// Code for lighting the Daisy Strip. Next three LED's lie on the same Meridian - 24.
  for(int j=69;j<72;j++){

//  pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels25.setBrightness(Br);
    pixels25.setPixelColor(j, pixels25.Color(163,255,0));// Moderately bright green color.
    pixels25.show();// This sends the updated pixel color to the hardware.
//  delay(0); // Delay for a period of time (in milliseconds).

}
}



/*void strip25() {

  // For a set of NeoPixels the first NeoPixel is 0, second is 1, all the way up to the count of pixels minus one.
//Numpixel =71 (72-1, LED Count starts from 0)
  for(int i=0;i<NUMPIXELS25;i++){

    // pixels.Color takes RGB values, from 0,0,0 up to 255,255,255
    pixels.setBrightness(20);
    pixels.setPixelColor(i, pixels.Color(163,255,0)); // Moderately bright green color.

    pixels.show(); // This sends the updated pixel color to the hardware.

    delay(0); // Delay for a period of time (in milliseconds).

  }
}
*/
