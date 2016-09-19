/***************************************
 THIS IS THE LATEST VERSION AS OF 14-APR-2016
 Project Name : Pediatric Perimeter v3.x
 Author : Dhruv Joshi
 Modifications made:
 - removed the cp5 controlform, replace with the JOptionPane
 - Saving of audio for the duration of the test
 - Video capture speed is 25 fps, image files being saved at that rate
 - Not using GSMovieMaker for video, instead a workaround "hack"
 - Removed junk code
 - used ControlP5 frames to add a second window for patient data entry
 - cleaner and more responsive UI
 - No image sprites used, all UI elements generated through code
 - aligned the hemis and quads in the UI w.r.t. the frame of reference of the camera feed
 - Added Concentric Circles to estimate the visual angles
 - Feature Added to Light up the whole LED strip / cardinial meridian 
 - hovering on meridians also included
 - slider to change the angular velocity of the LEDs in kinetic mode 
 
 Serial Communication :  [Because Adafruit Neopixel Library disables all the interrupts in Arduino When communicating to LEDs]
 Request <--> Response 
 - Space Bar :  'x'   <-->   99
 - slider    :  't'   <-->   98
 Libraries used (Processing v2.0):
 - controlp5 v2.0.4 https://code.google.com/p/controlp5/downloads/detail?name=controlP5-2.0.4.zip&can=2&q=
 - GSVideo v1.0.0 http://gsvideo.sourceforge.net/#download
 - Apache POI - https://poi.apache.org/download.html
 Note: Apache POI is a Java library and not a processing library. To add it, go to Sketch->Add File and add all files one by one.
 
/**************************************************************************************************
 //
 d//  MERIDIAN numbering of Device/in Arduino  and No.of LEDs on each Meridian  
 //  Meridian Label  :  1  2  3  4  5  6  7  8  9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  
 //  No. of LEDs     : 25 25 25 25 21 14 13 14 21  25  25  25  25  25  25  25  14  12  12  12  14  26  25  25
 //  
 *************************************************************************************************/

/*  TODO:    
 - can the processing of images and audio into a video be done by a java program? This can be called by the Processing sketch as a subprocess (FFMPEG is a good option but needs to be called by java or a java wrapper)
 - remove CP5 altogether
 
 */
import java.io.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import static javax.swing.JOptionPane.*;
import controlP5.*;
import processing.serial.*;
import codeanticode.gsvideo.*;
import ddf.minim.*;  // the audio recording library
import org.apache.poi.ss.usermodel.Sheet;  // For Importing The Data From EXcel Sheet 
import gifAnimation.*;


// DECLARING A CONTROLP5 OBJECT
private ControlP5 cp5;

int meridian_label [] = {  
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
}; // Device Numbering 
int numberOfLEDs[]     = {  
  25, 25, 25, 25, 21, 14, 13, 14, 21, 25, 25, 25, 25, 25, 25, 25, 14, 12, 12, 12, 14, 26, 25, 25
}; //including Daisy Disc for time interval calculation according to the device numbering 

// Quads Variables 
int quad_state[][]     = { 
  { 
    1, 1
  }
  , { 
    1, 1
  }
  , { 
    1, 1
  }
  , { 
    1, 1
  }
};    // 1 means the quad has not been done yet, 2 means it has already been done, 3 means it is presently going on, negative means it is being hovered upon
color quad_colors[][]  = { 
  { 
    #eeeeee, #00ff00, #ffff22, #08BFC4
  }
  , { 
    #dddddd, #00ff00, #ffff22, #08BFC4
  }
};  // Color Changes depending on the state 
int quad_center[]      = { 
  810, 435
}; 
int quad_diameter[]    = { 
  90, 60
};

//Hemis Variables
int hemi_state[][]      = { 
  { 
    1, 1
  }
  , { 
    1, 1
  }
  , { 
    1, 1
  }
  , { 
    1, 1
  }
};    // the same thing is used for the hemis   
int hemi_center[]       = { 
  1110, 435
};
int hemi_hover_code[][] = { 
  { 
    0, 3
  }
  , { 
    1, 2
  }
};

// ISOPTER VARIABLES [SWEEP]
int meridian_state[] = { 
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
}; 
color meridian_color[] = { 
  #bbbbbb, #bbbbbb, #00ff00, #ffff22
};  // Color changes depending on the state
int isopter_center[] = { 
  960, 210
}; 
int isopter_diameter = 300;

// 24 meridians and their present state of testing [MERIDIANS]
int meridians[] = { 
  28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28
};    // negative value means its being hovered over
color meridian_text_color[] = {
};


// Patterns Variables
int pattern_state [] = {1,1,1};
int posPatternImage [][] = {{105,540},{255,540}, {385,540}};
// VARIABLES THAT KEEP TRACK OF WHAT OBJECT (HEMI, QUAD OR ISOPTER) WE ARE HOVERING OVER AND WHICH COUNT IT IS
// THIS WILL ENABLE SENDING A SERIAL COMM TO THE ARDUINO VERY EASILY ON A MOUSE PRESS EVENT
char hovered_object;
int hovered_count;    // the current meridian which has been hovered over
color hover_color = #08BFC4; //  Color When hovering on Clickable objects
color backgroundColor = #5f6171;


// VIDEO FEED AND VIDEO SAVING VARIABLES
GSCapture cam = null;        // GS Video Capture Object
int fps = 60;          // The Number of Frames per second Declaration (used for the processing sketch framerate as well as the video that is recorded
boolean startRecording = false;


float xi, yi;

// PATIENT INFORMATION VARIABLES - THESE ARE GLOBAL
// String textName = "test", textAge, textMR, textDescription;  // the MR no is used to name the file, hence this cannot be NULL. If no MR is entered, 'test' is used
String patient_name, patient_MR, patient_dob, patient_milestone_details, patient_OTC;
int occipitalDistance; //To store int version of patient_OTC
PFont textView;

int previousMillis = 0, currentMillis = 0, initialMillis, finalMillis, Sent_Time = 0, time_taken, prev_time, Recieve_Time = 0, z = 0;    // initial and final are used to calculate the FPS for the video at the verry end
int previousTime = 0, currentTime = 0;
int reaction_time = 0;    // intialize reaction_time to 0 otherwise it gets a weird value which will confuse the clinicians

PrintWriter isopter_text, quadHemi_text;       // the textfiles which is used to save information to text files

String base_folder, workingDirectory;

boolean flagged_test = false;
int current_sweep_meridian;

// STATUS VARIABLES
String status = "idle";
String last_tested = "Nothing";
int Arduino_Response;
boolean serialEventFlag = false, allDataSentFlag = false;
int SpaceKey_State = 0; // 0 means it is not pressed , 1 means it is pressed 

// Variables For Excel Sheet Importing
SXSSFWorkbook swb=null;
Sheet sh=null;
InputStream inp=null;
Workbook wb= null;
float[][] angleData;
float[] bottomMostAngle =new float[30];


// SERIAL OBJECT/ARDUINO
Serial arduino;                 // create serial object

// AUDIO RECORDING VARIABLES
Minim minim;
AudioInput mic_input;
AudioRecorder sound_recording;

// PatternS Images Variables 
PImage  backwardImage, forwardImage, displayImage;
PImage  subjectIsopter;
int imageCount;
PImage eyeDirection;
int imageNumber;

// Second window Variables to generate the final Isopter according to the subject's view
PFrame f;
PApplet s;
Gif myAnimation;
/**********************************************************************************************************************************/
// THIS IS THE MAIN FRAME
void setup() {

  // INITIATE SERIAL CONNECTION
  if (Serial.list().length != 0) {
    String port = Serial.list()[Serial.list().length - 1];
    println("Arduino MEGA connected succesfully.");

    // then we open up the port.. 115200 bauds
    arduino = new Serial(this, port, 115200);
    arduino.buffer(1);

    // send a "clear all" signal to the arduino in case some random LEDs lit up..
    arduino.write('x');
    arduino.write('\n');
  } else {
    println("Arduino not connected or detected, please replug"); 
    exit();
  }

  // default background colour
  size(1200, 640);  // the size of the video feed + the side bar with the controls
  frameRate(fps);

  // CONNECT TO THE CAMERA
  String[] cameras = GSCapture.list(); //The avaliable Cameras
  println(cameras);

  // We check if the right camera is plugged in, and if so only then do we proceed, otherwise we exit the program.
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    //exit();
  } else {
    println("Checking if correct camera has been plugged in ...");

    for (int i = 0; i < cameras.length; i++) {  //Listing the available Cameras      
      // println(cameras[i].length());
      // println(cameras[i].substring(3,6));
      if (cameras[i].length() == 13 && cameras[i].substring(3, 6).equals("USB")) {
        println("...success!");
        cam = new GSCapture(this, 640, 480, cameras[i]);      // Camera object will capture in 640x480 resolution
        cam.start();      // shall start acquiring video feed from the camera
        break;
      }
    }  
    if (cam == null) {
      println("...NO. Please check the camera connected and try again."); 
      exit();
    }
  }

 //Get the Working Directory of the sketch 
  workingDirectory = sketchPath("");
  
 
  // ADD BUTTONS TO THE MAIN UI, CHANGE DEFAULT CONTROLP5 VALUES
  cp5 = new ControlP5(this);
  cp5.setColorForeground(#eeeeee);
  cp5.setColorActive(hover_color);

  // ADD A BUTTON FOR "FINISHING" WHICH WILL CLOSE AND SAVE THE VIDEO AND ALSO MAKE A POPUP APPEAR THAT SHALL ASK FOR USER INPUTS ABOUT THE TEST (NOTES)
  cp5.addBang("FINISH") //The Bang Clear and the Specifications
    .setPosition(980, 575)
      .setSize(75, 35)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          .setColor(0)
            ;

  cp5.addBang("PATIENT_INFO") //The Bang Clear and the Specifications
    .setPosition(850, 575)
      .setSize(75, 35)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          .setColor(0)
            ;  
  
  PImage[] flagImage = {loadImage("flagW.png"),loadImage("flagB.png"),loadImage("flagW.png")};
  cp5.addButton("FLAG")
    .setValue(128)
      .setPosition(730, 60)
        .setImages(flagImage)
          .updateSize()
          ;
          
/*  cp5.addBang("FLAG") //The Bang Clear and the Specifications
    .setPosition(925, 400)
      .setSize(75, 25)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          .setColor(0)
            ;*/  
            
  PImage[] notesImage = {loadImage("noteW.png"),loadImage("noteB.png"),loadImage("noteW.png")};
  cp5.addButton("ADD_NOTE")
    .setValue(128)
      .setPosition(730,100)
        .setImages(notesImage)
          .updateSize()
             ;   
/*  cp5.addBang("ADD_NOTE") //The Bang Clear and the Specifications
    .setPosition(925, 430)
      .setSize(75, 25)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          .setColor(0)
            ; */
  PImage[] captureImage = {loadImage("captureW.png"),loadImage("captureB.png"),loadImage("captureW.png")};
  cp5.addButton("CAPTURE")
    .setValue(128)
      .setPosition(730,140)
        .setImages(captureImage)
          .updateSize()
             ;      
  
  /*
  cp5.addBang("CAPTURE") //The Bang Clear and the Specifications
    .setPosition(925, 460)
      .setSize(75, 25)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          .setColor(0)
            ;*/
  
 /* println(workingDirectory);
  backwardImage = loadImage(workingDirectory + "backward.jpg");
  cp5.addButton("BACKWARD")
    .setValue(128)
      .setPosition(235, 592)
        .setImage(backwardImage)
          .updateSize()
            ;

  forwardImage = loadImage(workingDirectory +"forward.jpg");
  cp5.addButton("FORWARD")
    .setValue(128)
      .setPosition(235, 542)
        .setImages(forwardImage)
          .updateSize()
            ; */

  PImage[] patternOne = {loadImage("pattern1W.png"),loadImage("pattern1B.png"),loadImage("pattern1W.png")};
  cp5.addButton("PATTERNONE")
    .setValue(128)
      .setPosition(posPatternImage[0][0],posPatternImage[0][1])
        .setImages(patternOne)
          .updateSize()
             ;
             
  PImage[] patternTwo = {loadImage("pattern2W.png"),loadImage("pattern2B.png"),loadImage("pattern2W.png")};
  cp5.addButton("PATTERNTWO")
    .setValue(128)
      .setPosition(posPatternImage[1][0],posPatternImage[1][1])
        .setImages(patternTwo)
          .updateSize()
             ;
             
  PImage[] patternThree = {loadImage("pattern3W.png"),loadImage("pattern3B.png"),loadImage("pattern3W.png")};
  cp5.addButton("PATTERNTHREE")
    .setValue(128)
      .setPosition(posPatternImage[2][0],posPatternImage[2][1])
        .setImages(patternThree)
          .updateSize()
             ;
             
             
  // To Define The Slider To Vary The LED Sweep Interval 
  cp5.addSlider("SWEEP") // Time Interval For LEDs Sweep
    .setPosition(750, 510)
      .setSize(150, 10)
        .setRange(1, 10)
          .setColorValue(255) 
            // .setLabel("Sweep")
            .setValue(3)
              .setNumberOfTickMarks(10)
                .setSliderMode(Slider.FLEXIBLE)
                  .setLabelVisible(false) 
                    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
                      ;       
  // To Label The Slider  
  cp5.addTextlabel("Time Interval")
    .setText("LED Speed (deg/sec):")
      .setPosition(745, 495)
        .setColorValue(0x00000000)
          .setFont(createFont("Georgia", 13))
            ;    
  // To Indicate The Lower Range     
  cp5.addTextlabel("Low Range")
    .setText("1")
      .setPosition(745, 520)
        .setColorValue(0x00000000)
          .setFont(createFont("Georgia", 12))
            ;     
  cp5.addTextlabel("High Range")
    .setText("10")
      .setPosition(890, 520)
        .setColorValue(0x00000000)
          .setFont(createFont("Georgia", 12))
            ;     


  // To Define The Slider To Vary The LED Sweep Interval 
  cp5.addSlider("FIXATION") // Time Interval For LEDs Sweep
    .setPosition(1000, 510)
      .setSize(150, 10)
        .setRange(2, 75    )
          .setColorValue(255) 
            // .setLabel("Sweep")
            .setValue(100)
              .setNumberOfTickMarks(10)
                .setSliderMode(Slider.FLEXIBLE)
                  .setLabelVisible(false) 
                    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
                      ;

  //cp5.getController("FIXATION").setTriggerEvent(Slider.RELEASE);       
  // To Label The Slider  
  cp5.addTextlabel("Brightness")
    .setText("Fix. LED Brightness (cd/sq.mt):")
      .setPosition(995, 495)
        .setColorValue(0x00000000)
          .setFont(createFont("Georgia", 13))
            ;    
  // To Indicate The Lower Range     
  cp5.addTextlabel("Low Range 1")
    .setText("2")
      .setPosition(995, 520)
        .setColorValue(0x00000000)
          .setFont(createFont("Georgia", 12))
            ;     
  cp5.addTextlabel("High Range 1")
    .setText("75")
      .setPosition(1150, 520)
        .setColorValue(0x00000000)
          .setFont(createFont("Georgia", 12))
            ;     





  // AUDIO RECORDING SETTINGS
  minim = new Minim(this);
  mic_input = minim.getLineIn();    // keep this ready. This is the line-in.

  // TAKE PATIENT DETAILS AS INPUT
  // String patient_stuff = javax.swing.JOptionPane.showInputDialog(this, "Patient Name:");
  JTextField pname = new JTextField();
  JTextField pMR = new JTextField();
  JTextField pdob = new JTextField();
  JTextField pmilestone_details = new JTextField();
  JTextField padditional_info = new JTextField();
  Object[] message = {
    "Patient Name:", pname, 
    "MR Number:", pMR, 
    "Date of Birth:", pdob, 
    "Milestone Notes:", pmilestone_details, 
    "Occipital to Corneal Distance (mm):", padditional_info,
  };

  // TODO: change showconfirmDialog to something else that only shows an OK option
  int option = JOptionPane.showConfirmDialog(this, message, "Please enter patient information", JOptionPane.OK_CANCEL_OPTION);

  if (option == JOptionPane.OK_OPTION)
  {
    patient_name = pname.getText();
    patient_MR = pMR.getText();
    patient_dob = pdob.getText();
    patient_milestone_details = pmilestone_details.getText();
    patient_OTC = padditional_info.getText();
    occipitalDistance = Integer.parseInt(patient_OTC.trim());

    // Create files for saving patient details
    // give them useful header information
    base_folder = year() + "/" + month() + "/" + day() + "/" + patient_name + "_" + hour() + "_" + minute() + "_hrs";    // the folder into which data will be stored - categorized chronologically
    isopter_text = this.createWriter(base_folder + "/" + patient_name + "_isopter.txt");
    isopter_text.println("Isopter angles for patient " + patient_name);
    isopter_text.println("MR No : " + patient_MR);
    isopter_text.println("Milestone Details : " + patient_milestone_details);
    isopter_text.println("Occipital to Corneal Distance (mm) : " + patient_OTC);
    isopter_text.println("Timestamp : " + hour() + ":" + minute() + ":" + second());
    isopter_text.println("Timestamp\t|Meridian\t|Angle\t|Reaction Time (ms)\t|Flag\t|Notes\t|");
    isopter_text.flush();

    quadHemi_text = this.createWriter(base_folder + "/" + patient_name + "_quads_hemis.txt");
    quadHemi_text.println("Meridian and Quad tests for patient " + patient_name);
    quadHemi_text.println("MR No : " + patient_MR);
    quadHemi_text.println("Milestone Details : " + patient_milestone_details);
    quadHemi_text.println("Timestamp : " + hour() + ":" + minute() + ":" + second());
    quadHemi_text.println("Timestamp\t|Test done\t|Reaction Time\t|Flag\t|Notes");
    quadHemi_text.flush();
    // 
    // CREATE A NEW AUDIO OBJECT
    sound_recording = minim.createRecorder(mic_input, base_folder + "/recording.wav", false);    // the false means that it would save directly to disc rather than in a buffer
    sound_recording.beginRecord();

    // RECALCULATE PRECISE ANGLES BASED ON THE OCCIPITAL TO CORNEAL DISTANCE ENTERED
    // OTHERWISE USE DEFAULT
  } else {
    exit();    // quit the program
  }

  //Import The Trace/ 3D - Model Of The Device For The LED Posiions 
  angleData = importExcel("E:/GitRepositories/pediatric_perimeter_2016/gui/AngleData.xlsx");       // Gives An Array With The Angle Subtended By The Each LED At The Center Of The Eye
  // angleData stores the values according to device numbering

// Initialize the pattern_state 
pattern_state [0] = 1;
pattern_state [1] = 1;
pattern_state [2] = 1;


arduino.write('x');
arduino.write('\n');
 
}

void draw() {
  // update the millisecond counter
  currentMillis = millis();

  if (frameCount == 1) {
    initialMillis = currentMillis;
  }

  // plain and simple background color
  background(backgroundColor);//4B66A8

  // draw the video capture here
  fill(0);
  rect(80, 50, 640, 480); 
  if (cam.available() == true) {
    cam.read();
  } 
  // cam.save(base_folder + "/isopter.jpg");  
  image(cam, 80, 50);    // display the image, interpolate with the previous image if this one was a dropped frame
  
  // Overlay a protractor on the live feed 
  PImage protractor = loadImage("protractor.png");
  image(protractor, 309, 203);
  
//  image(myAnimation, 1180,30);// Baby's Animation
  
 // eyeDirection = loadImage(workingDirectory + "/Images/" + imageNumber + ".jpg");
  
 // image(eyeDirection,1180, 200);
  //Draw the picture to show the patterns
  //String path ="E:/GitRepositories/pediatric_perimeter_2016/gui/";
//  String path = workingDirectory;
 // displayImage = loadImage(path+"pattern"+str(imageCount + 1)+ ".png");
  // println(pattern_state);
  
  for (int i =0; i < 3; i++){
  if (pattern_state[i] < 0) {
    fill(hover_color);
    pattern_state[i] = abs(pattern_state[i]);
  } else if (pattern_state[i] == 2) {
    fill(#ffff00); // In Progress
  } else if (pattern_state[i] == 1) {
    fill(backgroundColor);
  } 
 // stroke(backgroundColor);
//  rect(125, 535, 90, 90 );
 // image(displayImage, 130, 540);
 ellipse(posPatternImage[i][0] - 25, posPatternImage[i][1] + 60, 10, 10);
  }
  // Checkin
  // draw the crosshair at the center of the video feed
  stroke(#ff0000);
  line(395, 290, 405, 290);  
  line(400, 285, 400, 295);

  // draw the hemis and quads in their present state
  colorQuads(quad_state, quad_center[0], quad_center[1], 2.5, 2.5);    // quads
  colorQuads(hemi_state, hemi_center[0], hemi_center[1], 2.5, 0);      // hemis

  // check if the mouse is hovering over the hemis, quads or isopter - if so, change to hover colour
  hover(mouseX, mouseY);

  // draw the isopter/meridians
  drawIsopter(meridians, isopter_center[0], isopter_center[1], isopter_diameter);
  textView = loadFont("E:/GitRepositories/pediatric_perimeter_2016/gui/data/Calibri-Bold-48.vlw");
  textFont(textView, 15);
  // print reaction time and information about what was the last thing tested and the thing presently being tested
  fill(0);
  text("Reaction time is  : " + str(reaction_time) + "ms", 520, 565);
  text("Last thing tested : " + last_tested, 520, 595);
  text("Present Status    : " + status, 520, 625);
  textFont(textView, 25);
  text(str(currentMillis) + "ms", 1075, 625);      // milliseconds elapsed since the program began
  textFont(textView, 15);
  text( "Value :" + cp5.getController("FIXATION").getValue(), 1025, 545);  // display the brightness 

  // RECORD THE FRAME, SAVE AS RECORDED VIDEO
  // THIS MUST BE THE LAST THING IN void draw() OTHERWISE EVERYTHING WON'T GET ADDED TO THE VIDEO FRAME
  saveFrame(workingDirectory + base_folder + "/frames/frame-####.jpg");      //save each frame to disc without compression
}



public class PFrame extends JFrame {
  public PFrame(int width, int height) {
    setBounds(100, 100, 1366, 768 );
    s = new SecondApplet();
    s.frame = this;
    add(s);
    s.init();
    s.setVisible(true);
    show();
  }
}


public class SecondApplet extends PApplet {
  float x = 683, y = 375, xi, yi;
  int d1 = 20, d2 = 360, d, Value=0;

  float    collectCoordinates [][] =  { 
  { 
    0, 0,0
  }
  , { 
    0, 0,0
  }
  ,{ 
   0, 0,0
  },  { 
    0, 0,0
  }
  , { 
    0, 0,0
  }
  ,{ 
   0, 0,0
  },  { 
    0, 0,0
  }
  , { 
    0, 0,0
  }
  ,{ 
   0, 0,0
  },  { 
    0, 0,0
  }
  , { 
    0, 0,0
  }
  ,{ 
   0, 0,0
  },  { 
    0, 0,0
  }
  , { 
    0, 0,0
  }
  ,{ 
   0, 0,0
  },  { 
    0, 0,0
  }
  , { 
    0, 0,0
  }
  ,{ 
   0, 0,0
  },  { 
    0, 0,0
  }
  , { 
    0, 0,0
  }
  ,{ 
   0, 0,0
  },  { 
    0, 0,0
  }
  , { 
    0, 0,0
  }
  ,{ 
   0, 0,0
  }  };
  
   boolean insertOrigin = false, originIncluded = false;
   int count, index;
  
  int dotsCounter; 
  boolean coversAllQuads [] = {false, false, false, false};
  
  public void setup() {
    background(0);
    noStroke();
  }

  public void draw() {

    background(#cccccc);

    fill(255);
    ellipse(mouseX, mouseY, 10, 10);
    fill(#cccccc);
    // ellipse(ghostX, ghostY, 10, 10);
    ellipse(x, y, 2*d2 +d1, 2*d2+d1 );
    drawIsopter2(meridians, 683, 380, 650);  
    

  
    if(dotsCounter >= 3){
    float swap;
    /*
    for(int k=0; k< dotsCounter; k++)
    {
      println(collectCoordinates[k][0] +" " + collectCoordinates[k][1] +" " + collectCoordinates[k][2]);
    }*/
     //println(collectCoordinates);
     // Sort The array for red dots Joining 
     if (frameCount ==1){
   for (int c = 0; c < dotsCounter; c++) {
      for (int d = 0; d < dotsCounter - c - 1; d++) {
        if (collectCoordinates[d][2] < collectCoordinates[d+1][2]) 
        {
          swap       = collectCoordinates[d][2];
          collectCoordinates[d][2]   = collectCoordinates[d+1][2];
          collectCoordinates[d+1][2] = swap;
         
          swap       = collectCoordinates[d][1];
          collectCoordinates[d][1]   = collectCoordinates[d+1][1];
          collectCoordinates[d+1][1] = swap;
          
          swap       = collectCoordinates[d][0];
          collectCoordinates[d][0]   = collectCoordinates[d+1][0];
          collectCoordinates[d+1][0] = swap;
        }
      }
   }
   
  
   /*float sum = int(coversALlQuads[0])*pow(2,0) +  int(coversALlQuads[1])*pow(2,1) + int(coversALlQuads[2])*pow(2,2) + int(coversALlQuads[3])*pow(2,3);
   if(sum < 15 && sum > 0){ 
   float index = log(15 - sum )/ log(2);
   if(index - int(index) == 0){
   insertOrigin = true;
   }
   }*/
   count = 0; 
   index =0; // Initialising
   for (int i = 0; i < 4 ; i++ ){
   if (!(coversAllQuads[i])){
   index = i; 
   insertOrigin = true;
   count++; 
   }
   }
   println("index and count and state of quads: "+index+" "+ count);
   println(coversAllQuads);
   
   //Update the CollectCoordinates[][] with Origin If required
   if(insertOrigin){
    println("trying to Insert Origin");
     if(count == 3 || count ==2){
     //Append the origin Coordinates at the end on the matrix
       collectCoordinates[dotsCounter][0] = 683;
       collectCoordinates[dotsCounter][1] = 380;
       dotsCounter++;
     }else if(count ==1){
      // Insert the origin into the matrix
     float tempX = 683, tempY = 380; 
     boolean originInserted = false;
     int j;
     for (j=0; j < dotsCounter; j++){
       if(collectCoordinates[j][2] < (index+1)*90){
          swap       = tempX;
          tempX   = collectCoordinates[j][0];
          collectCoordinates[j][0] = swap;
          
          swap       = tempY;
          tempY   = collectCoordinates[j][1];
          collectCoordinates[j][1] = swap;
          originInserted = true;
      }  
    }
   
   // if(!originInserted){          
     collectCoordinates[dotsCounter][0] = tempX;
     collectCoordinates[dotsCounter][1] = tempY;
     dotsCounter++;
  //  }
 }
 }  

}

    
  // println("After");

  for(int k=0; k < dotsCounter; k++)
    {
      println(collectCoordinates[k][0] +" " + collectCoordinates[k][1] +"  " + collectCoordinates[k][2]);
    }  
    
    
    stroke(0);
    noFill();
    beginShape();   
    curveVertex(collectCoordinates[0][0],collectCoordinates[0][1]);
    int j;
    for (j=0; j < dotsCounter; j++){
      curveVertex(collectCoordinates[j][0],collectCoordinates[j][1]);
    }

    // curveVertex(collectCoordinates[j-1][0],collectCoordinates[j-1][1]);
    curveVertex(collectCoordinates[0][0],collectCoordinates[0][1]);
    curveVertex(collectCoordinates[1][0],collectCoordinates[1][1]);
    // curveVertex(collectCoordinates[j-1][0],collectCoordinates[j-1][1]);
    endShape();
   }
    
    textView = loadFont(workingDirectory + "data/GoudyOldStyleT-Bold-48.vlw");
    textFont(textView, 40);
    fill(#ff0000);
    text("Baby's \n Right ", 975, 75);
    text("Baby's \n left ", 325, 75);
    if (frameCount == 1) {
      subjectIsopter = get(300, 25, 800, 700);      
      //image(isopter3,0,0);
      subjectIsopter.save(workingDirectory+base_folder+"/Isopter_Report.jpg");
    }
  }


  void drawIsopter2(int[] meridians, int x, int y, int diameter) {
    // first draw the background circle
    stroke(0);
    fill(#eeeeee);
    ellipse(x, y, diameter, diameter);    // the outer circle of the isopter, representing the projection of the whole dome
    /* ellipse(x, y, 0.25*diameter, 0.25*diameter);  // the inner daisy chain
     ellipse(x, y, 0.75*diameter, 0.75*diameter);  // the inner daisy chain
     
     float r_IsopterRange1 = abs(cos(radians(30)))*diameter/2;
     stroke(#bbbbbb);
     ellipse(x, y, r_IsopterRange1, r_IsopterRange1); 
     Concentric Circles For different ranges of the visual field  
     fill(0);
     fill(#eeeeee); */

    for (int i = 7; i >=1; i--) {

      /*float xc = cos(radians(-i*30))*diameter/2 + x;
       float yc = sin(radians(-i*30))*diameter/2 + y; 
       float r_IsopterRange = sin(radians(i*10))*diameter;// Finding the diameter for the range
       float xc = sin(radians(i*15))*(r_IsopterRange)/02 + x + 5; */

      float r_IsopterRange = diameter * ((i*15.0)/120);
      float yc = sin(radians(-90))*(r_IsopterRange+20)/2 + y + 15 ;
      if (i==1) {
        stroke(0);
      } else {
        stroke(#bbbbbb);
      }
      // stroke(#bbbbbb);
      ellipse(x, y, r_IsopterRange, r_IsopterRange); 
      fill(#bbbbbb);
      text(str(i*15), x-5, yc);
      fill(#eeeeee);
    }

    // stroke(#bbbbbb);
    int mappingIndex;          // mappingIndex  = (36 - i)% 24  [ Maps the Isopter  to the Baby's Point of View ]
    // Then draw the 24 meridians
   //  dotsCounter =0; // Initialising the counter 
  
    for (int i = 0; i < 24; i++) {
      // first calculate the location of the points on the circumference of this circle, given that meridians are at 15 degree (PI/12) intervals
      // stroke(#bbbbbb);

      mappingIndex = (36 - i) % 24;
      float xm = cos(radians(-mappingIndex*15))*diameter/2 + x;
      float ym = sin(radians(-mappingIndex*15))*diameter/2 + y; 

      // This will not be changed because the values are not changed with this change in orientation
      if (meridian_state[i] < 0) {  //Notify That the mouse is hovering on the Meridians
        stroke(hover_color);
        meridian_state[i] = abs(meridian_state[i]);  // revert to earlier thing
      } else if (meridian_state[i] > 0 && meridian_state[i] <= 3) { //Color The Meridian If It Is Done 
        stroke(meridian_color[meridian_state[i]]);
      } else {
        stroke(#bbbbbb);
      }

      // draw a line from the center to the meridian points (xm, ym)
      line(x, y, xm, ym);

      // draw the text at a location near the edge, which is along an imaginary circle of larger diameter - at point (xt, yt)
      // No Change in the position of the text 
      float xt = cos(radians(-i*15))*(diameter + 30)/2 + x - 10;
      float yt = sin(radians(-i*15))*(diameter + 20)/2 + y + 5;

      /*cartesianCoordinates[mappingIndex][0] = xt;
       cartesianCoordinates[mappingIndex][1] = yt;*/


      if (meridians[i] < 0) {
        fill(#ff0000);
        meridians[i] = abs(meridians[i]);
      } else {
        fill(0);
      }
      text(str(i*15), xt, yt);  // draw the label of the meridian (in degrees)

      // NOW WE DRAW THE RED DOTS FOR THE REALTIME FEEDBACK
      fill(#ff0000);  // red colour
      // println(abs(meridians[i]));
      /*if (abs(meridians[i]) < 28 ) {
       float xi = cos(radians(-i*15))*(10 + (diameter - 10)*abs(meridians[i])/(2*28)) + x;
       float yi = sin(radians(-i*15))*(10 + (diameter - 10)*abs(meridians[i])/(2*28)) + y;
       ellipse(xi, yi, 10, 10);
       }*/
      if (abs(meridians[i]) < 28 ) {
        // Get The Angle of the LED 
        //  angleData[meridianNumber-1][pixelNumber-1] = finalAngleValue;
        // Check whether it is obtuse or not
        int pixelNumber = abs(meridians[i]); // LED No. if Sweep is ON 
        // int meridianNumber = (24 - (((24 - i)%24) + 12) % 24)%24;
        int meridianNumber = (24 - i)%24;  // based on Device numbering for The 
        int numberOfPixels = numberOfLEDs[(24 - i)%24 ]; // Based on the device numbering 
        //println(((25 - i)%24) + " " + numberOfPixels);
        if (pixelNumber > 0 && pixelNumber <= numberOfPixels + 1) {
          /*if (angleData[i][numberOfPixels - pixelNumber + 1] > 90) {
           fill(#00ffff);// Use  different color to indicate it
           // Indicate the dot on the periphery of the circle 
           float xi = cos(radians(-i*15))*(10 + (diameter - 10)/2) + x;
           float yi = sin(radians(-i*15))*(10 + (diameter - 10)/2) + y;
           ellipse(xi, yi, 10, 10);
           } else {
           float xi = cos(radians(-i*15))*(10 + (diameter - 10)*sin(radians(angleData[i][numberOfPixels - pixelNumber + 1] ))/2) + x;
           float yi = sin(radians(-i*15))*(10 + (diameter - 10)*sin(radians(angleData[i][numberOfPixels - pixelNumber + 1] ))/2) + y;
           ellipse(xi, yi, 10, 10);
           }*/

          if (pixelNumber > 3) { // For Meridian LEDs
            xi = (cos(radians(-mappingIndex*15))*(10 + (diameter - 10)/2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber +1  ]/120) + x;
            yi = (sin(radians(-mappingIndex*15))*(10 + (diameter - 10)/2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber +1  ]/120) + y;
            
          } else if (pixelNumber <= 3 ) { // For Daisy LEDs
            xi = (cos(radians(-mappingIndex*15))*(10 + (diameter - 10)/2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber]/120) + x;
            yi = (sin(radians(-mappingIndex*15))*(10 + (diameter - 10)/2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber]/120) + y;
            // println(angleData[meridianNumber][numberOfPixels - pixelNumber]);  
           //  println(pixelNumber +"  " + angleData[meridianNumber][numberOfPixels - pixelNumber] );
          }
          //  println(xi,yi);
          ellipse(xi, yi, 10, 10);
          if (frameCount == 1){
          collectCoordinates[dotsCounter][0]=xi;
          collectCoordinates[dotsCounter][1]=yi;
          collectCoordinates[dotsCounter][2] = mappingIndex*15; // Re - arrange While joining the red dots
         
          // This has to be done to join the dots on the final report
          if(xi > x && yi >= y ){
            coversAllQuads [3] = true;
          }else if(xi > x && yi <= y){
            coversAllQuads [0] = true;
          }else if(xi <= x && yi < y){
            coversAllQuads [1] = true;
          }else if(xi <= x && yi > y){
            coversAllQuads [2] = true;
          }
          
          dotsCounter++;
        }
        }
      }
    }
   println(dotsCounter);
  }
}



// DRAW FOUR QUADRANTS - THE MOST GENERAL FUNCTION
void colorQuads(int[][] quad_state, int x, int y, float dx, float dy) {
  // float quad_positions[][] = {{52.5, 52.5}, {50, 52.5}, {50, 50}, {52.5, 50}};
  byte quad_positions[][] = {
    {
      1, 1
    }
    , {
      0, 1
    }
    , {
      0, 0
    }
    , {
      1, 0
    }
  };

  for (int i = 0; i < 4; i++) {  // 4 quadrants
    for (int j = 0; j < 2; j++) {  // inner and outer
      if (quad_state[i][j] > 0) {
        fill(quad_colors[j][quad_state[i][j] - 1]);    // filling the corresponding quadrant
      } else {
        fill(hover_color);  // fill the hover colour
        quad_state[i][j] = abs(quad_state[i][j]);  // revert to earlier thing
      } 
      noStroke();
      // finally, we draw the actual quads x4
      arc(x + dx*quad_positions[i][0], y + dy*quad_positions[i][1], quad_diameter[j], quad_diameter[j], i*HALF_PI, HALF_PI + i*HALF_PI);
    }
  }
}

// DRAW THE ISOPTER WITH THE UPDATED POSITIONS OF THE RED DOTS
void drawIsopter(int[] meridians, int x, int y, int diameter) {
  // first draw the background circle
  stroke(0);
  fill(#eeeeee);
  ellipse(x, y, diameter, diameter);    // the outer circle of the isopter, representing the projection of the whole dome
  /* ellipse(x, y, 0.25*diameter, 0.25*diameter);  // the inner daisy chain
   ellipse(x, y, 0.75*diameter, 0.75*diameter);  // the inner daisy chain
   
   float r_IsopterRange1 = abs(cos(radians(30)))*diameter/2;
   stroke(#bbbbbb);
   ellipse(x, y, r_IsopterRange1, r_IsopterRange1); 
   Concentric Circles For different ranges of the visual field  
   fill(0);
   fill(#eeeeee); */

  for (int i = 7; i >=1; i--) {

    /*float xc = cos(radians(-i*30))*diameter/2 + x;
     float yc = sin(radians(-i*30))*diameter/2 + y; 
     float r_IsopterRange = sin(radians(i*10))*diameter;// Finding the diameter for the range
     float xc = sin(radians(i*15))*(r_IsopterRange)/02 + x + 5; */

    float r_IsopterRange = diameter * ((i*15.0)/120);
    float yc = sin(radians(-90))*(r_IsopterRange+20)/2 + y + 15 ;
    if (i==1) {
      stroke(0);
    } else {
      stroke(#bbbbbb);
    }
    // stroke(#bbbbbb);
    ellipse(x, y, r_IsopterRange, r_IsopterRange); 
    fill(#bbbbbb);
    text(str(i*15), x-5, yc);
    fill(#eeeeee);
  }

  // stroke(#bbbbbb);
  // Then draw the 24 meridians
  for (int i = 0; i < 24; i++) {
    // first calculate the location of the points on the circumference of this circle, given that meridians are at 15 degree (PI/12) intervals
    // stroke(#bbbbbb);
    float xm = cos(radians(-i*15))*diameter/2 + x;
    float ym = sin(radians(-i*15))*diameter/2 + y; 

    if (meridian_state[i] < 0) {  //Notify That the mouse is hovering on the Meridians
      strokeWeight(2);
      stroke(hover_color);
      meridian_state[i] = abs(meridian_state[i]);  // revert to earlier thing
    } else if (meridian_state[i] > 0 && meridian_state[i] <= 3) { //Color The Meridian If It Is Done 
      stroke(meridian_color[meridian_state[i]]);
    } else {
      stroke(#bbbbbb);
    }

    // draw a line from the center to the meridian points (xm, ym)
    line(x, y, xm, ym);
    strokeWeight(1); // Restore the default Value 
    
    // draw the text at a location near the edge, which is along an imaginary circle of larger diameter - at point (xt, yt)
    float xt = cos(radians(-i*15))*(diameter + 30)/2 + x - 10;
    float yt = sin(radians(-i*15))*(diameter + 20)/2 + y + 5;
    if (meridians[i] < 0) {
      fill(hover_color);
      meridians[i] = abs(meridians[i]);
    } else {
      fill(0);//#DADEDE
    }
    text(str(i*15), xt, yt);  // draw the label of the meridian (in degrees)

  //Boundaries of the device need to be displayed 
  float radiusLargerSide = (angleData[16][0]/120)*diameter;
  float radiusSmallerSide = (angleData[7][0]/120)*diameter;
  float x1=x;
  float y1=y;
  stroke(0);
  //fill
  noFill();
  arc(x,y,radiusLargerSide,radiusLargerSide,-2*PI/3,-PI/3);
  arc(x,y,radiusSmallerSide,radiusSmallerSide,-285*PI/180,-255*PI/180);
  
    // NOW WE DRAW THE RED DOTS FOR THE REALTIME FEEDBACK
    fill(#ff0000);  // red colour
    // println(abs(meridians[i]));
    /*if (abs(meridians[i]) < 28 ) {
     float xi = cos(radians(-i*15))*(10 + (diameter - 10)*abs(meridians[i])/(2*28)) + x;
     float yi = sin(radians(-i*15))*(10 + (diameter - 10)*abs(meridians[i])/(2*28)) + y;
     ellipse(xi, yi, 10, 10);
     }*/
    if (abs(meridians[i]) < 28 ) {
      // Get The Angle of the LED 
      //  angleData[meridianNumber-1][pixelNumber-1] = finalAngleValue;
      // Check whether it is obtuse or not
      int pixelNumber = abs(meridians[i]); // LED No. if Sweep is ON 
      // int meridianNumber = (24 - (((24 - i)%24) + 12) % 24)%24;
      int meridianNumber = (24 - i)%24;  // based on Device numbering for The 
      int numberOfPixels = numberOfLEDs[(24 - i)%24 ]; // Based on the device numbering 
      //println(((25 - i)%24) + " " + numberOfPixels);
      if (pixelNumber > 0 && pixelNumber <= numberOfPixels + 1) {
        /*if (angleData[i][numberOfPixels - pixelNumber + 1] > 90) {
         fill(#00ffff);// Use  different color to indicate it
         // Indicate the dot on the periphery of the circle 
         float xi = cos(radians(-i*15))*(10 + (diameter - 10)/2) + x;
         float yi = sin(radians(-i*15))*(10 + (diameter - 10)/2) + y;
         ellipse(xi, yi, 10, 10);
         } else {
         float xi = cos(radians(-i*15))*(10 + (diameter - 10)*sin(radians(angleData[i][numberOfPixels - pixelNumber + 1] ))/2) + x;
         float yi = sin(radians(-i*15))*(10 + (diameter - 10)*sin(radians(angleData[i][numberOfPixels - pixelNumber + 1] ))/2) + y;
         ellipse(xi, yi, 10, 10);
         }*/

        if (pixelNumber > 3) { // For Meridian LEDs
          xi = (cos(radians(-i*15))*(10 + (diameter - 10)/2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber +1  ]/120) + x;
          yi = (sin(radians(-i*15))*(10 + (diameter - 10)/2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber +1  ]/120) + y;
        } else if (pixelNumber <= 3 ) { // For Daisy LEDs
          xi = (cos(radians(-i*15))*(10 + (diameter - 10)/2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber]/120) + x;
          yi = (sin(radians(-i*15))*(10 + (diameter - 10)/2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber]/120) + y;
          // println(angleData[meridianNumber][numberOfPixels - pixelNumber]);  
          println(pixelNumber +"  " + angleData[meridianNumber][numberOfPixels - pixelNumber] );
        }
        //  println(xi,yi);
        ellipse(xi, yi, 10, 10);
      }
    }
  }
}

// CHECK IF THE MOUSE IS OVER ANYTHING IMPORTANT
// DO THIS BY FINDING IF THE RADIAL DISTANCE FROM ANY OF THE HEMI, QUAD OR ISOPTER IS SIGNIFICANT
void hover(float x, float y) {
  hovered_object = 'c';    // random character which has no meaning to the arduino API
  if (x > 640) {  // otherwise it's over the video and therefore none of our concern
    float r_isopter = sqrt(sq(x - isopter_center[0]) + sq(y - isopter_center[1]));
    float r_quad = sqrt(sq(x - quad_center[0]) + sq(y - quad_center[1]));
    float r_hemi = sqrt(sq(x - hemi_center[0]) + sq(y - hemi_center[1]));

    // CHECK FOR ISOPTER, HEMI OR QUAD
    if (r_isopter < 0.5*(isopter_diameter + 30)) {    // larger diameter, so that the text surrounding the isopter can also be selected
      // calculate angle at which mouse is from the center
      float angle = degrees(angleSubtended(x, y, isopter_center[0], isopter_center[1]));
      meridians[hovered_count] = abs(meridians[hovered_count]);    // clear out the previously hovered one
      hovered_count = int((angle + 5)/15)%24;    // this is the actual angle on which you are hovering
      if (r_isopter < 0.5*(isopter_diameter)) {   //Check On Meridians
        hovered_object = 'm';
        meridian_state[hovered_count] *=  -1;
      } else {
        hovered_object = 's';
        meridians[hovered_count] = -1*abs(meridians[hovered_count]);      // set the presently hovered meridian to change state
      }
      cursor(HAND);     // change cursor to indicate that this thing can be clicked on
    } else if (r_quad < 0.5*quad_diameter[0]) {
      hovered_object = 'q';
      // calculate angle at which mouse is from the center
      float angle = angleSubtended(x, y, quad_center[0], quad_center[1]);
      cursor(HAND);

      if (r_quad < 0.5*quad_diameter[1]) {
        // inner quads
        hovered_count = 4 + int((angle + HALF_PI)/HALF_PI);
        quad_state[abs(8 - hovered_count)][1] *= -1;
      } else {
        // outer quads
        hovered_count = int((angle + HALF_PI)/HALF_PI);
        quad_state[abs(4 - hovered_count)][0] *= -1;
      }
    } else if (r_hemi < 0.5*quad_diameter[0]) {
      hovered_object = 'h';
      // calculate angle at which mouse is from the center
      float angle = angleSubtended(x, y, hemi_center[0], hemi_center[1]);
      cursor(HAND);
      // choose inner or outer hemis
      if (r_hemi < 0.5*quad_diameter[1]) {
        // inner quads
        hovered_count = 2 + int((angle + HALF_PI)/PI)%2;
        hemi_state[hemi_hover_code[hovered_count - 2][0]][1] *= -1;
        hemi_state[hemi_hover_code[hovered_count - 2][1]][1] *= -1;
      } else {
        // outer quads
        hovered_count = int((angle + HALF_PI)/PI)%2;
        hemi_state[hemi_hover_code[hovered_count][0]][0] *= -1;
        hemi_state[hemi_hover_code[hovered_count][1]][0] *= -1;
      }
    } else {
      cursor(ARROW);
    }
  } else if ((x >= posPatternImage[0][0] && x<= posPatternImage[0][0] + 80 ) && (y>= posPatternImage[0][1] && y<= posPatternImage[0][1] + 80)) {  // Hovering on the Image Pattern -1 
    cursor(HAND);
  }else if ((x >= posPatternImage[1][0]  && x<= posPatternImage[1][0] + 80 ) && (y>= posPatternImage[1][1] && y<= posPatternImage[1][1] + 80)) {  // Hovering on the Image  Pattern -2 
    cursor(HAND);
  }else if ((x >= posPatternImage[2][0] && x<= posPatternImage[2][0]  + 80 ) && (y>= posPatternImage[2][1] && y<= posPatternImage[2][1] + 80)) {  // Hovering on the Image  Pattern -3 
    cursor(HAND);
  }else if ((x >= 730 && x<= 760 ) && (y>= 60 && y<= 90)) {  // Hovering on the Image  Pattern -3 
    cursor(HAND);
  } else if ((x >= 730 && x<= 760 ) && (y>= 100 && y<= 130)) {  // Hovering on the Image  Pattern -3 
    cursor(HAND);
  } else if ((x >= 730 && x<= 760 ) && (y>= 140 && y<= 170)) {  // Hovering on the Image  Pattern -3 
    cursor(HAND);
  }  else {
    cursor(ARROW);
  }
}

// QUICK FUNCTION TO CALCULATE THE ANGLE SUBTENDED
float angleSubtended(float x, float y, int c1, int c2) {
  // angle subtended by (x,y) to fixed point (c1,c2)
  float angle = atan((x - c1)/(y - c2));
  if (y >= c2) {  // if the reference point is in the 3rd or 4th quadrant w.r.t. a circle with (c1,c2) as center
    angle = PI + angle;
  }
  return angle + HALF_PI;
}

void mousePressed() {
  // println(str(mouseX) + "," + str(mouseY));
  // really simple - just send the instruction to the arduino via serial
  // it will be of the form (hovered_object, hovered_count\n)
  if (hovered_object == 'h' || hovered_object == 'q' || hovered_object == 's' || hovered_object == 'm'  ) {
    // reset flag and start high quality high speed recording
    flagged_test = false;
    startRecording = true;

    // print to the console what test is going on
    print(str(hovered_object) + ",");
    println(str(hovered_count));

    // Send The time intervals before initiating the kinetic mode 
    if (hovered_object == 's') {
      sendTimeIntervals((24 - hovered_count)%24 + 1);  // this converts coordinates to the frame of reference of the actual system (angles inverted w.r.t. x-axis)
    } 

    // send message to the arduino
    arduino.write(hovered_object);
    arduino.write(',');
    if (hovered_object == 's' || hovered_object == 'm') {
      arduino.write(str((24 - hovered_count)%24 + 1));    // this converts coordinates to the frame of reference of the actual system (angles inverted w.r.t. x-axis)
    } else {
      arduino.write(str(hovered_count));    // this makes the char get converted into a string form, which over serial, is readable as the same ASCII char back again by the arduino [HACK]
    }
    arduino.write('\n');
 
  }

  // change colour of the object to "presently being done"
  switch(hovered_object) {
  case 'q': 
    {      
      previousMillis = millis();      // start the timer from now
      status = "quadrant";
      if (hovered_count <= 4) {
        quad_state[abs(4 - hovered_count)][0] = 3;
        break;
      } else {
        quad_state[abs(8 - hovered_count)][1] = 3;
        break;
      }
    }
  case 'h': 
    {
      previousMillis = millis();      // start the timer from now
      status = "hemi";
      if (hovered_count < 2) {
        hemi_state[hemi_hover_code[hovered_count][0]][0] = 3;
        hemi_state[hemi_hover_code[hovered_count][1]][0] = 3;
        break;
      } else {
        hemi_state[hemi_hover_code[hovered_count - 2][0]][1] = 3;
        hemi_state[hemi_hover_code[hovered_count - 2][1]][1] = 3;
        break;
      }
    }
  case 'm':
    previousMillis = millis();      // start the timer from now
    status = "Meridian";
    meridian_state[hovered_count] = 3;
    current_sweep_meridian = hovered_count;  // this needs to be stored in a seperate variable    
    break;


  case 's':
    previousMillis = millis();      // start the timer from now
    status = "sweep";
    current_sweep_meridian = hovered_count;  // this needs to be stored in a seperate variable    
    break;

 /* case 'p':      // Start the patterns
    previousMillis = millis();      // start the timer from now
    status = "pattern";
    pattern_state = 2;  // To Identify that test is in progress    
    break;*/
  }
 /* if (hovered_object == 'h' || hovered_object == 'q' || hovered_object == 's' || hovered_object == 'm' || hovered_object == 'p') {
imageNumber = getImageNumber(status , hovered_count);// to display the eye direction for the user[respond only for valid clicks]
  }*/
}


 
void clearHemisQuads() {
  // checks if any hemi_state or quad_state values are == 3, and makes them into 2 (done)
  for (int i = 0; i < 4; i++) {  // 4 quadrants
    for (int j = 0; j < 2; j++) {  // inner and outer
      if (abs(quad_state[i][j]) == 3) {
        quad_state[i][j] = 2;
      }
      if (abs(hemi_state[i][j]) == 3) {
        hemi_state[i][j] = 2;
      }
    }
  }

  for (int i = 0; i < 24; i++) {  // 24 Meridians 
    if (abs(meridian_state[i]) == 3) {
      meridian_state[i] = 2;
    }
  }

for(int i=0; i<3; i++){
  if (pattern_state[i] == 2) {
    pattern_state[i] = 1;
  }
}

}

// Mouse released To Notify The Slider To Update The Time Intervals And Send It To Arduino 
void mouseReleased() {

  /*
  //Check Only The Status Of The Slider 
   if ((mouseX >= 740 && mouseX <= 890) && (mouseY >= 485 && mouseY <= 500))
   {
   
   // Get The Value Of The Slider 
   float angularVelocity =  int(cp5.getController("SWEEP").getValue());
   
   //Update The time intervals meridian by meridian in the array
   for (int i =1; i<=24; i++) {    
   
   // Get The index of the last entry corresponding to a meridian in the EXCEL sheet
   // Last Entry Corresponds to 180 deg visual field 
   int index = 0;  // Initialse The Value For the next Meridian 
   for (int j = 0; j <= i-1; j++) {
   index = index + numberOfLEDs[j];
   } 
   
   // Update The Time Intervals For The corresponding Meridian 
   int timeTaken = 0; // Initialise The Value For The Next Meridian 
   int preceedTimeTaken;
   for (int k = numberOfLEDs[i-1]; k>0; k--) {
   
   if (saving [index][5] != null) { // Do NOt Consider The NUll Values in the EXCEL sheet 
   // int prevTimeTaken = timeTaken;
   
   timeTaken = int(((round(degrees(HALF_PI - (float(saving[index ][5]))))/angularVelocity))*1000);
   
   // timeTaken = int(degrees(HALF_PI - radians(float(saving[index][5])))/angularVelocity*1000); // Calculate The Time At which this LED gets ON from the start
   if (k != 1) {
   preceedTimeTaken      = int(((round(degrees(HALF_PI - (float(saving[index-1][5]))))/angularVelocity))*1000);
   } else {d
   preceedTimeTaken =  int((((round(degrees(HALF_PI )))/angularVelocity))*1000);               // Time taken for the preceeding LED to turn ON from The start
   }
   saving[index][6]  =  str(timeTaken - preceedTimeTaken);                             // Update The Time Interval for an LED to be in ON state 
   index = index - 1;
   }
   }
   }
   }*/
}

// KEYPRESS TO STOP A TEST WHICH IS ONGOING
void keyPressed() {
  final int k = keyCode;

  if (k == 32) {    // 32 is the ASCII code for the space key
    imageNumber = 1;
    SpaceKey_State = 1;
    /// println(Delay_Store);
    println("Space Bar Pressed Now");
    arduino.write('x');
    arduino.write('\n'); 
    //  Sent_Time = millis();
    println("Request sent to Ardiuno @ :" + millis());
    //delay(100);
    int Init_Time = millis();
    int interval = 0;
    // Wait For The Serial Port  
    while (interval <= 10) {  // Wait For The response From Ardiuno 
      interval = millis() - Init_Time;
    }
    println(Arduino_Response);
    // while (Arduino_Response != 99 && interval <= 1000) {
    if ( Arduino_Response != 99 ) {
      println("Request repeated to Ardiuno");
      arduino.write('x');
      arduino.write('\n'); 
      // Wait For The Serial Port  
      while (interval <= 10) {  // Wait For The response From Ardiuno 
        interval = millis() - Init_Time;
      }
    }
    //  else {               //  interval = millis() - Init_Time;
    // Reset The Values 
    if ( Arduino_Response == 99 ) { 
      SpaceKey_State = 0;
      Arduino_Response = 0;
      //  }
    }
    Stop();
    println("stopped");
  }
}

// ALL THE STUFF THAT HAPPENS WHEN YOU STOP A TEST
// 1. REACTION TIME CALCULATION
// 2. SEND SIGNAL TO ARDUINO TO "STOP" ('x\n')
// 3. DRAW/UPDATE ISOPTER
// 4. WRITE ISOPTER ANGLE VALUES TO FILE AND ALSO QUAD/HEMI VALUES
public void Stop() {
  // SIGNAL ARDUINO TO STOP
  // arduino.write('x');
  //  arduino.write('\n'); 
  //  println("Clear All Command Sent To Ardiuno");

  // UI UPDATE - MAKE QUADS/HEMIS PRESENTLY IN ACTIVE STATE TO 'DONE' STATE
  clearHemisQuads();
 imageNumber = 1;// reset the image 
  // CALCULATE REACTION TIME AND PRINT IT TO SCREEN
  reaction_time = currentMillis - previousMillis;  
  println("Reaction time is " + str(reaction_time) + "ms");

  // SAVE QUADS AND HEMIS TO TEXT FILE IN PROPER FORMAT
  if (status == "quadrant") {
    quadHemi_text.println();
    quadHemi_text.print(hour() + ":" + minute() + ":");
    int s = second();
    if (s < 10) {
      quadHemi_text.print("0" + str(s) + "\t");      // so that the text formatting is proper
    } else {
      quadHemi_text.print(str(s) + "\t\t");
    }
    switch (hovered_count) {
    case 1:
      quadHemi_text.print("TR Quad Outer");
      break;

    case 2:
      quadHemi_text.print("TL Quad Outer");
      break;

    case 3:
      quadHemi_text.print("BL Quad Outer");
      break;

    case 4:
      quadHemi_text.print("BR Quad Outer");
      break;

    case 5:
      quadHemi_text.print("TR Quad Full");
      break;

    case 6:
      quadHemi_text.print("TL Quad Full");
      break;

    case 7:
      quadHemi_text.print("BL Quad Full");
      break;

    case 8:
      quadHemi_text.print("BR Quad Full");
      break;
    }
    quadHemi_text.print("\t" + str(reaction_time) + "\t");
    quadHemi_text.flush();
  }

  if (status == "hemi") {
    quadHemi_text.println();
    quadHemi_text.print(hour() + ":" + minute() + ":");
    int s = second();
    if (s < 10) {
      quadHemi_text.print("0" + str(s) + "\t");      // so that the text formatting is proper
    } else {
      quadHemi_text.print(str(s) + "\t\t");
    }
    switch(hovered_count) {
    case 0:
      quadHemi_text.print("R Hemi Outer");
      break;
    case 1:
      quadHemi_text.print("L Hemi Outer");
      break;
    case 2:
      quadHemi_text.print("R Hemi Full");
      break;
    case 3:
      quadHemi_text.print("L Hemi Full");
      break;
    }
    quadHemi_text.print("\t" + str(reaction_time) + "\t");
    quadHemi_text.flush();
  }

  //Save Meridians to a Text File in a Proper Format
  if (status == "Meridian") {
    quadHemi_text.println();
    quadHemi_text.print(hour() + ":" + minute() + ":");
    int s = second();
    if (s < 10) {
      quadHemi_text.print("0" + str(s) + "\t");      // so that the text formatting is proper
    } else {
      quadHemi_text.print(str(s) + "\t\t");
    }
    quadHemi_text.print("Meridian "+(current_sweep_meridian)*15 );

    quadHemi_text.print("\t" + str(reaction_time) + "\t");
    quadHemi_text.flush();
  }




  // REDRAW AND SAVE THE ISOPTER TO FILE  
  if (status == "sweep") {
    // redraw isopter image to file
    PImage isopter = get(760, 30, 400, 360);     // get that particular section of the screen where the isopter lies. 
    isopter.save(workingDirectory + base_folder + "/isopter.jpg");  // save it to a file in the same folder

    // write this to the isopter text file
    isopter_text.println();
    isopter_text.print(hour() + ":" + minute() + ":");
    int s = second();
    if (s < 10) {
      isopter_text.print("0" + s + "\t");      // so that the text formatting is proper
    } else {
      isopter_text.print(s + "\t");
    }
    isopter_text.print((hovered_count)*15 + "\t\t");
    //CKR
    if(abs(meridians[hovered_count]) >0 && abs(meridians[hovered_count]) <= numberOfLEDs[(24 - hovered_count)%24 ] + 1 ) {
    if (abs(meridians[hovered_count]) > 3) { 
      isopter_text.print(str(angleData[(24 - hovered_count)%24][numberOfLEDs[(24 - hovered_count)%24 ] - abs(meridians[hovered_count]) +1  ]) + "\t");
    }
    else if (abs(meridians[hovered_count]) <= 3 ) {
      isopter_text.print(str(angleData[(24 - hovered_count)%24][numberOfLEDs[(24 - hovered_count)%24 ] - abs(meridians[hovered_count])  ]) + "\t");
    }
    }
  //CKR
   // isopter_text.print(str(abs(meridians[hovered_count])) + "\t");    // print degrees at which the meridian test stopped, to the text file
    isopter_text.print(str(reaction_time) + "\t\t\t");
    isopter_text.flush();
  }

  // UPDATE STATUS VARIABLES
  last_tested = status;    // last tested thing becomes the previuos value of status
  status = "Test stopped. idle";
  startRecording = false;  // go back to low quality recording
}

// GET FEEDBACK FROM THE ARDUINO ABOUT THE ISOPTER
void serialEvent(Serial arduino) {

  /*
   * Inbuilt function which is called whenever there is a serial event, i.e 
   * arduino writes something on the serial port.
   * Use this function to handle all serial communication to be recieved from arduino.
   * Response 99 acknowledges that the clearAll function has been executed.
   * Response 98 acknowledges that all data for sweep has been recieved correctly by the arduino. 
   * Any other response is usually the pixel Number the arduino is currently sweeping.
   */

  String inString = arduino.readStringUntil('\n');
  //println("Time in ms :" + millis());
  //println("Serial Port Value Recieved from Arduino : " + inString + " @ " + millis());
  // Wait For The Response When Space Bar Is Pressed
  //if (SpaceKey_State != 1) {

  if (inString != null && inString.length() <= 4) {
    serialEventFlag = true;
    // string length four because it would be a 2-digit or 1-digit number with a \r\n at the end
    int temp_Val = Integer.parseInt(inString.substring(0, inString.length() - 2));
    if (temp_Val == 99 && SpaceKey_State == 1) {  // Response For Clear All Command
      // Recieve_Time = millis ();
      //  Delay_Store [z] = Recieve_Time - Sent_Time;
      //  z= z+1;
      Arduino_Response = temp_Val;
      SpaceKey_State = 0; 
      //println("Ardiuno Value Populated\n");
    } else if (temp_Val != 99 && SpaceKey_State == 0) {  // Data For The LED No. In Sweep
      if (previousTime == 0) {
        println("Serial Port Value Recieved from Arduino : " + inString + " @ " + previousTime + " ms");
        previousTime = millis();
      } else {
        currentTime = millis();
        println("Serial Port Value Recieved from Arduino : " + inString + " in " + (currentTime - previousTime) + " ms");
        previousTime = currentTime;
      }
      meridians[current_sweep_meridian] = Integer.parseInt(inString.substring(0, inString.length() - 2));
      //println(meridians[current_sweep_meridian] );
    }
  }
}


void CAPTURE() {
  cam.save(workingDirectory + base_folder + "/ScaleReading/Scale.jpg");
}


/*
// Returns the image number to be displayed for the eye direction according to the present status of the test
int getImageNumber(String object, int countNumber){
int returnNumber= 1;
 if (object == "quadrant") {

    switch (countNumber) {
    case 1:
      returnNumber = 6;
      break;

    case 2:
      
    returnNumber =8;
      break;

    case 3:
      
      returnNumber = 7;
      break;

    case 4:
     returnNumber = 9;
      break;

    case 5:
     returnNumber = 6;
      break;

    case 6:
      returnNumber = 8;
      break;

    case 7:
     returnNumber = 7;
      break;

    case 8:
     returnNumber = 9;
      break;
    } 
  }

  if (object == "hemi") {

    switch(countNumber) {
    case 0:
     returnNumber = 3;
      break;
    case 1:
      returnNumber = 2;
      break;
    case 2:
      returnNumber = 3;
      break;
    case 3:
     returnNumber = 2;
      break;
    }

  }

  //Save Meridians to a Text File in a Proper Format
  if (object == "Meridian" || object == "sweep") {
   if(countNumber >= 1 && countNumber <= 5){
     returnNumber = 6;
   }else if(countNumber >= 7 && countNumber <= 11){
      returnNumber = 8;
   }else if(countNumber >= 13 && countNumber <= 17){
      returnNumber = 7;
   }else if(countNumber >= 19 && countNumber <= 23){
      returnNumber = 9;
   }else if(countNumber == 0){
      returnNumber = 3;
   }else if(countNumber == 6){
     returnNumber = 5;
   }else if(countNumber == 12){
     returnNumber =2;
   }else if(countNumber == 18){
      returnNumber = 4;
   }else {
      returnNumber = 1;
   }
  }
 
if (object == "pattern") {
returnNumber = 1;
}

return returnNumber ;
}
*/
// Send The Sweep Interval Value To Ardiuno 
/*void SWEEP() {
 // cam.save(base_folder + "/ScaleReading/Scale.jpg");
 arduino.write("t");
 arduino.write(',');
 int  sweepValue = int (cp5.getController("SWEEP").getValue());
 arduino.write( sweepValue);
 println("Sweep Value Sent to Ardiuno :" + sweepValue);
 }*/


void FIXATION() {
  /*
   * Function to change brightness of fixation LED in arduino.
   * Arduino uses PWM to change brightness.
   * It is sent in the form (l, fixationBrightness).
   * Triggered by Slider.PRESSED
   */
  int fixationBrightness =  int(cp5.getController("FIXATION").getValue());
  arduino.write('l');
  arduino.write(','); 
  arduino.write(str(fixationBrightness));
  arduino.write('\n');
}


void  sendTimeIntervals(int chosenStrip) {

  /*
   * Function to send time intervals values to arduino.
   * The arduino is notified of incoming data by t, meridian number.
   * After that the values are concatened into a string seperated by commas. The last value is followed by a \n to indicate end of data.
   * The characters in string are sent one by one, byte by byte.
   * At a time only 30 characters have been kept in the stream. After every 30 characters, a delay occurs.
   * This is done because the size of the Serial stream is at max, 64 bytes. We have 30 at a time for safety.
   * Once all data is sent, an acknowledgement is recieved.
   * The acknowledgement 28 indicates that all data was recieved by the arduino.
   * If the acknowledgement is incorrect, it sends the whole data again.
   * @param chosenStrip - meridian Numberon which sweep is to be performed. 
   */

  //int[] sweepIntervals = new int[numberOfLEDs[chosenStrip-1]];
  //calculateSweepIntervalsForStrip(chosenStrip, sweepIntervals);
  println("Sending data");
  //Sending the Object details to arduino to recognise the action to be performed 
  arduino.write('t'); 
  arduino.write(',');
  println("bottomMostAngle[chosenStrip - 1] " + bottomMostAngle[chosenStrip - 1] + " Sweep value " + cp5.getController("SWEEP").getValue() + " Quotient " + bottomMostAngle[chosenStrip - 1]/cp5.getController("SWEEP").getValue());  
  int valueToBeSent = round(((bottomMostAngle[chosenStrip - 1]/cp5.getController("SWEEP").getValue())/numberOfLEDs[chosenStrip - 1])*1000);  
  arduino.write(str(valueToBeSent));
  println(valueToBeSent);
  arduino.write('\n');
  //arduino.write(str(numberOfLEDs[chosenStrip-1]));     // No. of LEDs to corresponding to the Meridian 
  /* DEPRECATED *************************************************************************************  
   arduino.write(str(chosenStrip));                      // Send The chosen Meridian to process  
   arduino.write('\n');
   String valuesToBeSent = "";
   for (int pixelNumber = 0; pixelNumber< numberOfLEDs[chosenStrip - 1]; pixelNumber++) {
   valuesToBeSent+=sweepIntervals[pixelNumber];
   if (pixelNumber <numberOfLEDs[chosenStrip-1] - 1) {
   valuesToBeSent+=",";
   } else {
   valuesToBeSent+="\n";
   }
   }
   int count = 0;
   int len = valuesToBeSent.length();
   println(valuesToBeSent);
   int index = 0;
   arduino.write(valuesToBeSent);
   //delay(10);
   //    while (index<len) {
   //      char characterToBeWritten = valuesToBeSent.charAt(index);
   //      arduino.write(characterToBeWritten);
   //      count++;
   //      index++;
   //      if (count >= 30) {
   //        println("One batch sent");
   //        delay(100);
   //        count = 0;
   //      }
   //    }
   //    delay(100);
   //    int numberOfPixelsToBeSent = numberofLEDs[chosenStrip - 1];
   //    for(int pixelNumber = 0; pixelNumber<numberOfPixelsToBeSent; pixelNumber++) {
   //      arduino.write(str())
   //    }
  /*
   // wait For the response 
   // //   delay(10);
   
   // Repeat  updating the The time intervals before initiating the kinetic mode 
   if(Arduino_Response != 98) {  
   arduino.write('t');  
   arduino.write(',');
   arduino.write(Pixels[chosenStrip]);     // No. of LEDs to corresponding to the Meridian 
   arduino.write('\n'); 
   delay(10); 
   // 
   }
   
   //Check For The response from Arduino and Send the time intervals 
   // // if(Arduino_Response == 98) {
   // Send The Time intervals from the array 
   // Get The index of the last entry corresponding to a meridian in the EXCEL sheet
   // Last Entry for a chosen  Corresponds to a value nearer to 180 deg visual field 
   int index1 = 0;  // Initialse The Value For the next Meridian 
   for (int j = 0; j < chosenStrip-1; j++) {
   index1 = index1 + numberOfLEDs[j];
   } 
   
   // Write the time intervales into the serial port 
   for (int k = 1; k<= numberOfLEDs[chosenStrip-1]; k++) {
   arduino.write(saving[index1][6]);
   if (k!=numberOfLEDs[chosenStrip-1]) {
   arduino.write(",");
   }
   }
   arduino.write("\n");  // Notify The End Of The String 
   // //  }
   println("All data sent"); 
   DEPRECATED*************************************************************************/
}

/* DEPRECATED *************************************************************************
 //Function to calculate delays for pixels;
 void calculateSweepIntervalsForStrip(int chosenStrip, int sweepInterval[]) {
 
/*
 * Function to calculate Sweep intervals for a strip.
 * It uses the data we've taken from the Excel sheet
 * The formula used: (angleOfNextPixel - angleOfCurrentPixel)/degreesPerSecond
 * degreesPerSecond value is obtained from the slider "SWEEP".
 * @param chosenStrip - number of meridian chosen
 * @param sweepInterval[] - array to store calculated values
 
 
 //Number of rows in excel sheet
 int numberOfRows = angleData.length;
 //index counter
 int valueNumber = 0;
 //degrees to move per second as per Slider
 float degreesPerSecond = cp5.getController("SWEEP").getValue();
 
 int rowNumber;
 int pixelNumber;
 
 for (pixelNumber = 0; pixelNumber < numberOfLEDs[chosenStrip-1] - 1; pixelNumber++) {
 sweepInterval[pixelNumber] = (int) round(((angleData[chosenStrip-1][pixelNumber + 1] - angleData[chosenStrip-1][pixelNumber])/degreesPerSecond)*1000);
 //println(angleData[chosenStrip-1][pixelNumber + 1] + " " + angleData[chosenStrip-1][pixelNumber] + " " + sweepInterval[pixelNumber]);
 }
 
 sweepInterval[pixelNumber] = (int) round(((90.00 - angleData[chosenStrip-1][pixelNumber])/degreesPerSecond)*1000);  //Calculate delay value for last LED; x1000 for milliseconds
 println(sweepInterval[pixelNumber]);
 println("All data calculated");
 } DERECATED ************************************************************************************/
/*void FORWARD() {
  imageCount = (imageCount+1)%5;
}
void BACKWARD() {
  if (imageCount == 0) {
    imageCount = 4;
  } else {
    imageCount = (imageCount-1)%5;
  }
}*/ 

void PATTERNONE () {
arduino.write('p');
arduino.write(',');
arduino.write('1');
arduino.write('\n');

pattern_state[0] = 2;
}


void PATTERNTWO () {
arduino.write('p');
arduino.write(',');
arduino.write('2');
arduino.write('\n');

pattern_state[1] = 2;
}


void PATTERNTHREE () {
arduino.write('p');
arduino.write(',');
arduino.write('3');
arduino.write('\n');

pattern_state[2] = 2;
}

// THE BANG FUNCTIONS
void FINISH() {
  println("finished everything");
  finalMillis = currentMillis;

  float final_fps = 1000/((finalMillis - initialMillis)/frameCount);
  print("The final fps is : ");
  println(final_fps);

  PImage screenIsopter = get(760, 30, 400, 360);     // get that particular section of the screen where the isopter lies. 
  screenIsopter.save(workingDirectory + base_folder + "/Reference_GUI_Isopter.jpg");  // save it to a file in the same folder


  f = new PFrame(width, height);
  f.setTitle("second window");

  // stop drawing to the window!!
  noLoop(); 

  // stop the video recording, open up a popup asking for any final notes before closing

  JTextArea textArea = new JTextArea(10, 5);


  /*
  int okCxl = JOptionPane.showConfirmDialog(SwingUtilities.getWindowAncestor(this), textArea, "Completion Notes", JOptionPane.OK_CANCEL_OPTION);
   if (okCxl == JOptionPane.OK_OPTION) {
   String text = textArea.getText();
   // Save notes in the text files and then close the text file objectsd
   isopter_text.close();
   
   }
   */


  // stop recording the sound..
  sound_recording.endRecord();

  // START PROCESSING THE VIDEO AND THEN QUIT THE PROGRAM
  // send a popup message giving a message to the user

  String[] ffmpeg_command = {
    "C:\\Windows\\System32\\cmd.exe", "/c", "start", "ffmpeg", "-framerate", str(final_fps), "-start_number", "0001", "-i", sketchPath("") + base_folder + "/frames/frame-%04d.jpg", "-i", sketchPath("") + base_folder + "/recording.wav", sketchPath("") + base_folder + "/video.mp4"
  };

  // handling the exception IOException - which happens when the command cannot find a file
  // Using Processbuilder to call the ffmpeg process
  try {
    ProcessBuilder p = new ProcessBuilder(ffmpeg_command);
    Process pr = p.start();

    /*
    // printing the output of the process to the console of processing
     String line = null;
     BufferedReader input = new BufferedReader(new InputStreamReader(pr.getInputStream()));
     while((line=input.readLine()) != null){
     System.out.println(line);
     }
     */
  } 
  catch (IOException e) {
    e.printStackTrace(); 
    exit();
  }

  // ONCE THIS IS DONE, DELETE THE 'FRAME' DIRECTORY
  // TODO: DO THIS IS A BAT FILE OR THROUGH THE CMD - OTHERWISE YOU'LL DELETE THEM BEFORE THEY'RE USED
  /*
  println("video created succesfully, now deleting remaining files...");
   File frames_folder = new File(sketchPath("") +  + "/frames/");
   File[] frames_list = frames_folder.listFiles();
   for (int i = 0; i < frames_list.length; i++) {
   frames_list[i].delete();
   }
   frames_folder.delete();    // delete the folder as well after that
   */

  // THEN EXIT THE PROGRAM ONCE DONE
  println("everything sucessful, closing");
  exit();
}

void PATIENT_INFO() {
  // TODO: show the option pane again, but populate it with existing values so that they may be changed if needed
}

void FLAG() {
  // just update hte flag variable to "flagged"
  if (flagged_test == false) {
    if (last_tested == "quadrant" || last_tested == "hemi") {
      quadHemi_text.print("flagged");
      quadHemi_text.flush();
      flagged_test = true;
    } else if (last_tested == "sweep") {
      isopter_text.print("flagged");
      isopter_text.flush();
      flagged_test = true;
    }
  }
}


// This Function Imports The Values From Excel Sheet And Calculates The Angle Subtedted by Each LED 
float[][] importExcel(String filepath) {

  /*
   * Function to read angle data from Excel sheet.
   * It uses apache poi library.
   * The format in which the data is stored in excel is as follows:
   * ------------------------------------------------------------->
   * | Meridian Number | Pixel Number | Angle in Degrees |
   * ------------------------------------------------------------->
   * We store the values in the 2 array of floats - data.
   * The row index i represents the meridian number, and the column index j represents pixel number in data[i][j]
   * Since arrays are 0 indexed, the actual index corresponding to a meridian will be meridian number -1; Same for pixels.
   * @param filepath - path to Excel Sheet (should be absolute path). 
   */
  //String[][] temp;
  float[][] data;
  try {
    inp = new FileInputStream(filepath);
  }
  catch(Exception e) {
  }
  try {
    //Opens The Workbook
    wb = WorkbookFactory.create(inp);
  }
  catch(Exception e) {
  }
  // Opens The First Sheet 
  Sheet sheet = wb.getSheetAt(0);
  int sizeX = sheet.getLastRowNum(); // Get The Number of rows in the sheet 

  int sizeY = 5;                    // 5 columns : Meridian <-> LED No. <-> X_value <-> Y_value <-> Z_value
  /*
  for (int i=0;i<sizeX;++i) {
   Row row = sheet.getRow(i);
   for (int j=0;j<sizeY;++j) {
   try {
   Cell cell = row.getCell(j);
   }
   catch(Exception e) {
   if (j>sizeY) {
   sizeY = j;
   }
   }
   }
   }*/
  /*temp = new String[sizeX][sizeY+2];
   for (int i=0;i<sizeX;++i) {
   for (int j=0;j<sizeY;++j) {
   //  for (int j=0;j< 1;++j) { 
   // Get The Row (Reading The Row) 
   Row row = sheet.getRow(i);
   try {
   Cell cell = row.getCell(j);
   if (cell.getCellType()==0 || cell.getCellType()==2 || cell.getCellType()==3)cell.setCellType(1);
   temp[i][j] = cell.getStringCellValue();
   // Get The Cell Values And Populate Them Into An Array 
                           /* Cell cell0 = row.getCell(0);
   if (cell0.getCellType()==0 || cell0.getCellType()==2 || cell0.getCellType()==3)cell0.setCellType(1);
   temp[i][0] = cell0.getStringCellValue();
   Cell cell1 = row.getCell(1);
   if (cell1.getCellType()==0 || cell1.getCellType()==2 || cell1.getCellType()==3)cell1.setCellType(1);
   temp[i][1] = cell1.getStringCellValue();
   Cell cell2 = row.getCell(2);
   if (cell2.getCellType()==0 || cell2.getCellType()==2 || cell2.getCellType()==3)cell2.setCellType(1);
   temp[i][2] = cell2.getStringCellValue();
   Cell cell3 = row.getCell(3);
   if (cell3.getCellType()==0 || cell3.getCellType()==2 || cell3.getCellType()==3)cell3.setCellType(1);
   temp[i][3] = cell3.getStringCellValue();
   Cell cell4 = row.getCell(4);
   if (cell4.getCellType()==0 || cell4.getCellType()==2 || cell4.getCellType()==3)cell4.setCellType(1);
   temp[i][4] = cell4.getStringCellValue();*/

  // Calculate The Angle Subtended 
  /*  float x= float (cell2.getStringCellValue());
   // println("x :" + x);
   float y= float (cell3.getStringCellValue());
   float z= float (cell4.getStringCellValue());
   d= 550; // Distance Calculated From The ForeHead To The Center Of The Camera 
   
   // Substitute In The Formulae To Calculate The Angle Subtended to The Y-axis   
   float  Val = (y-d)/ sqrt(sq(x) + sq(y-d) + sq(z));
   float  Deg = acos(Val);
   
   //Populate The Angle Calculated In to The Array
   temp[i][5] = str(Deg);
   println( "Angle Subtended :"+ Deg);*/
  /*   if (cell.getCellType()==0 || cell.getCellType()==2 || cell.getCellType()==3)cell.setCellType(1);
   temp[i][j] = cell.getStringCellValue();
   }
   catch(Exception e) {
   }
   }
   float x= float (temp[i][2]);
   // println("x :" + x);
   float y= float (temp[i][3]);
   float z= float (temp[i][4]);
   d= 550; // Distance Calculated From The ForeHead To The Center Of The Camera 
   
   // Substitute In The Formulae To Calculate The Angle Subtended to The Y-axis   
   float  Val = (y+d)/ sqrt(sq(x) + sq(y+d) + sq(z));
   float  Deg = acos(Val);
   
   //Populate The Angle Calculated In to The Array
   temp[i][5] = str(Deg);
   println( "Angle Subtended :"+ Deg);
   }
   println("No. Of Rows:" + sizeX);
   println("Excel file imported: " + filepath + " successfully!");
   // println(temp);
   return temp;*/
  int numberOfRows = sheet.getLastRowNum();
  int numberOfColumns = 3; 

  /*******************************************
   *        C o l u m n s
   *   -------------------------------------->
   * R |      |      |      |      |      |
   * o |-------------------------------------
   * w |      |      |      |      |      |
   * s |-------------------------------------
   *   |      |      |      |      |      |
   *   v
   ********************************************/

  data = new float[30][30];
  println("OccipitalDistance: " + occipitalDistance);
  for (int rowNumber = 1; rowNumber <=numberOfRows; rowNumber++) {
    Row row = sheet.getRow(rowNumber);
    // println(rowNumber);
    Cell cell = row.getCell(0);
    cell.setCellType(Cell.CELL_TYPE_NUMERIC);
    int meridianNumber = (int)(cell.getNumericCellValue());
    cell = row.getCell(2);
    cell.setCellType(Cell.CELL_TYPE_NUMERIC);
    int pixelNumber = (int)(cell.getNumericCellValue());
    cell = row.getCell(3);
    cell.setCellType(Cell.CELL_TYPE_NUMERIC);
    float angleValue = (float)(cell.getNumericCellValue());

    cell = row.getCell(10);
    cell.setCellType(Cell.CELL_TYPE_NUMERIC);
    float x = (float)(cell.getNumericCellValue());

    cell = row.getCell(11);
    cell.setCellType(Cell.CELL_TYPE_NUMERIC);
    float y = (float)(cell.getNumericCellValue());

    cell = row.getCell(12);
    cell.setCellType(Cell.CELL_TYPE_NUMERIC);
    float z = (float)(cell.getNumericCellValue());

    float zdash = z-(7+occipitalDistance);
    boolean flag = (zdash < 0)?true:false;
    zdash = Math.abs(zdash);
    float finalAngleValue = (float)Math.toDegrees(Math.atan(zdash/((float)Math.sqrt(x*x + y*y))));
    if (flag) {
      finalAngleValue += 90;
    } else {
      finalAngleValue = 90 - finalAngleValue;
    }
    if (pixelNumber == 1) {
      bottomMostAngle[meridianNumber - 1] = finalAngleValue;
      println((meridianNumber - 1) + " " + bottomMostAngle[meridianNumber - 1]);
    }
    data[meridianNumber-1][pixelNumber-1] = finalAngleValue;
  }


  //println("Data input done");
  for (int i = 0; i<30; i++) {
    print(i + " ");
    for (int j =0; j<30; j++) {
      print(data[i][j] + " ");
    }
    println("");
  }
  return data;
}
/**********************************************************************************************************************************/

// CODE TO MAKE THE SKETCH FULLSCREEN BY DEFAULT
boolean sketchFullScreen() {
  return true;
}
