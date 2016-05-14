
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
    
  Libraries used (Processing v2.0):
    - controlp5 v2.0.4 https://code.google.com/p/controlp5/downloads/detail?name=controlP5-2.0.4.zip&can=2&q=
    - GSVideo v1.0.0 http://gsvideo.sourceforge.net/#download
    
  TODO:    
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


// DECLARING A CONTROLP5 OBJECT
private ControlP5 cp5;

// HEMI AND QUAD VARIABLES
int quad_state[][] = {{1, 1}, {1, 1}, {1, 1}, {1, 1}};    // 1 means the quad has not been done yet, 2 means it has already been done, 3 means it is presently going on, negative means it is being hovered upon
int hemi_state[][] = {{1, 1}, {1, 1}, {1, 1}, {1, 1}};    // the same thing is used for the hemis
int meridian_state[] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}; 
color quad_colors[][] = {{#eeeeee, #00ff00, #ffff22, #0000ff}, {#dddddd, #00ff00, #ffff22, #0000ff}};
color meridian_color[] = {#bbbbbb,#bbbbbb,#00ff00,#ffff22};
color hover_color = #0000ff;
int quad_center[] = {700, 320}; 
int hemi_center[] = {935, 320};
int quad_diameter[] = {90, 60};
int hemi_hover_code[][] = {{0, 3}, {1, 2}};

// ISOPTER VARIABLES
// 24 meridians and their present state of testing
int meridians[] = {28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28};    // negative value means its being hovered over
color meridian_text_color[] = {};
int isopter_center[] = {820, 150};
int isopter_diameter = 250;
int current_sweep_meridian;

// VARIABLES THAT KEEP TRACK OF WHAT OBJECT (HEMI, QUAD OR ISOPTER) WE ARE HOVERING OVER AND WHICH COUNT IT IS
// THIS WILL ENABLE SENDING A SERIAL COMM TO THE ARDUINO VERY EASILY ON A MOUSE PRESS EVENT
char hovered_object;
int hovered_count;    // the current meridian which has been hovered over

// SERIAL OBJECT/ARDUINO
Serial arduino;                 // create serial object

// VIDEO FEED AND VIDEO SAVING VARIABLES
GSCapture cam;        // GS Video Capture Object
int fps = 60;          // The Number of Frames per second Declaration (used for the processing sketch framerate as well as the video that is recorded
boolean startRecording = false;

// PATIENT INFORMATION VARIABLES - THESE ARE GLOBAL
// String textName = "test", textAge, textMR, textDescription;  // the MR no is used to name the file, hence this cannot be NULL. If no MR is entered, 'test' is used
String patient_name, patient_MR, patient_dob, patient_milestone_details, patient_OTC;
int previousMillis = 0, currentMillis = 0, initialMillis, finalMillis;    // initial and final are used to calculate the FPS for the video at the verry end
int reaction_time = 0;    // intialize reaction_time to 0 otherwise it gets a weird value which will confuse the clinicians
PrintWriter isopter_text, quadHemi_text;       // the textfiles which is used to save information to text files
String base_folder;
boolean flagged_test = false;

// STATUS VARIABLES
String status = "idle";
String last_tested = "Nothing";

// AUDIO RECORDING VARIABLES
Minim minim;
AudioInput mic_input;
AudioRecorder sound_recording;

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
  size(1000, 480);  // the size of the video feed + the side bar with the controls
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
    
    for (int i = 0; i < cameras.length; i++) {  //Listing the avalibale Cameras      
      // println(cameras[i].length());
      // println(cameras[i].substring(3,6));
      if (cameras[i].length() == 13 && cameras[i].substring(3,6).equals("USB")) {
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
  
  // ADD BUTTONS TO THE MAIN UI, CHANGE DEFAULT CONTROLP5 VALUES
  cp5 = new ControlP5(this);
  cp5.setColorForeground(#eeeeee);
  cp5.setColorActive(#0000ff);
  
  // ADD A BUTTON FOR "FINISHING" WHICH WILL CLOSE AND SAVE THE VIDEO AND ALSO MAKE A POPUP APPEAR THAT SHALL ASK FOR USER INPUTS ABOUT THE TEST (NOTES)
  cp5.addBang("FINISH") //The Bang Clear and the Specifications
    .setPosition(660, 390)
      .setSize(75, 25)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          .setColor(0)
          ;
  cp5.addBang("PATIENT_INFO") //The Bang Clear and the Specifications
    .setPosition(660, 420)
      .setSize(75, 25)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          .setColor(0)
          ;  
  cp5.addBang("FLAG") //The Bang Clear and the Specifications
    .setPosition(780, 300)
      .setSize(75, 25)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          .setColor(0)
          ;
  cp5.addBang("ADD_NOTE") //The Bang Clear and the Specifications
    .setPosition(780, 330)
      .setSize(75, 25)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          .setColor(0)
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
}
  
void draw() {
  // update the millisecond counter
  currentMillis = millis();
  
  if (frameCount == 1) {
    initialMillis = currentMillis; 
  }
  
  // plain and simple background color
  background(#cccccc);
  
  // draw the video capture here
  fill(0);
  rect(0, 0, 640, 480);
  if (cam.available() == true) {
    cam.read();
  } 
  image(cam, 0, 0);    // display the image, interpolate with the previous image if this one was a dropped frame
  // Checkin
  // draw the crosshair at the center of the video feed
  stroke(#ff0000);
  line(315, 240, 325, 240);
  line(320, 235, 320, 245);
  
  // draw the hemis and quads in their present state
  colorQuads(quad_state, quad_center[0], quad_center[1], 2.5, 2.5);    // quads
  colorQuads(hemi_state, hemi_center[0], hemi_center[1], 2.5, 0);      // hemis
  
  // check if the mouse is hovering over the hemis, quads or isopter - if so, change to hover colour
  hover(mouseX, mouseY);
  
  // draw the isopter/meridians
  drawIsopter(meridians, isopter_center[0], isopter_center[1], isopter_diameter);
  
  // print reaction time and information about what was the last thing tested and the thing presently being tested
  fill(0);
  text("Reaction time is : " + str(reaction_time) + "ms", 750, 400);
  text("Last thing tested : " + last_tested, 750, 420);
  text("PRESENT STATUS : " + status, 750, 440);
  text(str(currentMillis) + "ms", 900, 460);      // milliseconds elapsed since the program began
  
  // RECORD THE FRAME, SAVE AS RECORDED VIDEO
  // THIS MUST BE THE LAST THING IN void draw() OTHERWISE EVERYTHING WON'T GET ADDED TO THE VIDEO FRAME
    saveFrame(base_folder + "/frames/frame-####.jpg");      //save each frame to disc without compression
}

// DRAW FOUR QUADRANTS - THE MOST GENERAL FUNCTION
void colorQuads(int[][] quad_state, int x, int y, float dx, float dy) {
  // float quad_positions[][] = {{52.5, 52.5}, {50, 52.5}, {50, 50}, {52.5, 50}};
  byte quad_positions[][] = {{1, 1}, {0, 1}, {0, 0}, {1, 0}};
  
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
  ellipse(x, y, 0.25*diameter, 0.25*diameter);  // the inner daisy chain
    
  // Then draw the 24 meridians
  for (int i = 0; i < 24; i++) {
    // first calculate the location of the points on the circumference of this circle, given that meridians are at 15 degree (PI/12) intervals
   // stroke(#bbbbbb);
    float xm = cos(radians(-i*15))*diameter/2 + x;
    float ym = sin(radians(-i*15))*diameter/2 + y; 
    
      if (meridian_state[i] < 0) {  //Notify That the mouse is hovering on the Meridians
      stroke(hover_color);
      meridian_state[i] = abs(meridian_state[i]);  // revert to earlier thing
      } else if (meridian_state[i] > 0 && meridian_state[i] <= 3) { //Color The Meridian If It Is Done 
      stroke(meridian_color[meridian_state[i]]); 
      }
      else  {
      stroke(#bbbbbb); 
      }
 
    // draw a line from the center to the meridian points (xm, ym)
    line(x, y, xm, ym);
    
    // draw the text at a location near the edge, which is along an imaginary circle of larger diameter - at point (xt, yt)
    float xt = cos(radians(-i*15))*(diameter + 30)/2 + x - 10;
    float yt = sin(radians(-i*15))*(diameter + 20)/2 + y + 5;
    if (meridians[i] < 0) {
      fill(#ff0000);
    } else {
      fill(0); 
    }
    text(str(i*15), xt, yt);  // draw the label of the meridian (in degrees)
    
    // NOW WE DRAW THE RED DOTS FOR THE REALTIME FEEDBACK
    fill(#ff0000);  // red colour
    if (abs(meridians[i]) < 28) {
      float xi = cos(radians(-i*15))*(10 + (diameter - 10)*abs(meridians[i])/(2*28)) + x;
      float yi = sin(radians(-i*15))*(10 + (diameter - 10)*abs(meridians[i])/(2*28)) + y;
      ellipse(xi, yi, 10, 10);
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
      }
     else {
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
  }
}

// QUICK FUNCTION TO CALCULATE HTE ANGLE SUBTENDED
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
  if (hovered_object == 'h' || hovered_object == 'q' || hovered_object == 's' || hovered_object == 'm') {
    // reset flag and start high quality high speed recording
    flagged_test = false;
    startRecording = true;
    
    // print to the console what test is going on
    print(str(hovered_object) + ",");
    println(str(hovered_count));
    
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
    case 'q': {      
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
    case 'h': {
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
  }
}

void clearHemisQuads() {
 // checks if any hemi_state or quad_state values are == 3, and makes them into 2 (done)
   for (int i = 0; i < 4; i++) {  // 4 quadrants
      for (int j = 0; j < 2; j++) {  // inner and outer
        if (quad_state[i][j] == 3) {
           quad_state[i][j] = 2;
        }
        if (hemi_state[i][j] == 3) {
           hemi_state[i][j] = 2;
        }
      }
   }
   
   for (int i = 0; i < 24; i++) {  // 24 Meridians 
   if (meridian_state[i] == 3) {
           meridian_state[i] = 2;
        }
   }
   
}


// KEYPRESS TO STOP A TEST WHICH IS ONGOING
void keyPressed() {
  final int k = keyCode;
  
  if(k == 32) {    // 32 is the ASCII code for the space key
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
  arduino.write('x');
  arduino.write('\n'); 
  
  // UI UPDATE - MAKE QUADS/HEMIS PRESENTLY IN ACTIVE STATE TO 'DONE' STATE
  clearHemisQuads();
  
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
  
  if(status == "hemi") {
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
  
  // REDRAW AND SAVE THE ISOPTER TO FILE  
  if (status == "sweep") {
    // redraw isopter image to file
    PImage isopter = get(640, 0, 360, 300);     // get that particular section of the screen where the isopter lies.
    isopter.save(base_folder + "/isopter.jpg");  // save it to a file in the same folder
  
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
    isopter_text.print(str(abs(meridians[hovered_count])) + "\t");    // print degrees at which the meridian test stopped, to the text file
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
  String inString = arduino.readStringUntil('\n');
  if (inString != null && inString.length() <= 4) {
    // string length four because it would be a 2-digit or 1-digit number with a \r\n at the end
    meridians[current_sweep_meridian] = parseInt(inString.substring(0, inString.length() - 2));
  } 
}

// THE BANG FUNCTIONS
void FINISH() {
  println("finished everything");
  finalMillis = currentMillis;
  
  float final_fps = 1000/((finalMillis - initialMillis)/frameCount);
  print("The final fps is : ");
  println(final_fps);
  
  noLoop();    // stop drawing to the window!!
  // stop the video recording, open up a popup asking for any final notes before closing
  
  JTextArea textArea = new JTextArea(10, 5);
  /*
  int okCxl = JOptionPane.showConfirmDialog(SwingUtilities.getWindowAncestor(this), textArea, "Completion Notes", JOptionPane.OK_CANCEL_OPTION);
  if (okCxl == JOptionPane.OK_OPTION) {
    String text = textArea.getText();
    // Save notes in the text files and then close the text file objects
    isopter_text.close();
    
  }
  */
  
  // stop recording the sound..
  sound_recording.endRecord();
  
  // START PROCESSING THE VIDEO AND THEN QUIT THE PROGRAM
  // send a popup message giving a message to the user
  
  String[] ffmpeg_command = {"C:\\Windows\\System32\\cmd.exe", "/c", "start", "ffmpeg", "-framerate", str(final_fps), "-start_number", "0001", "-i", sketchPath("") + base_folder + "/frames/frame-%04d.jpg", "-i", sketchPath("") + base_folder + "/recording.wav", sketchPath("") + base_folder + "/video.mp4"};
  
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
    
  } catch (IOException e) {
    e.printStackTrace(); 
    exit();
  }
  
  // ONCE THIS IS DONE, DELETE THE 'FRAME' DIRECTORY
  // TODO: DO THIS IS A BAT FILE OR THROUGH THE CMD - OTHERWISE YOU'LL DELETE THEM BEFORE THEY'RE USED
  /*
  println("video created succesfully, now deleting remaining files...");
  File frames_folder = new File(sketchPath("") + base_folder + "/frames/");
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
/**********************************************************************************************************************************/

// CODE TO MAKE THE SKETCH FULLSCREEN BY DEFAULT
boolean sketchFullScreen() {
  return true;
}
