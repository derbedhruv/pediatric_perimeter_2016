/***************************************
 THIS IS THE LATEST VERSION AS OF 07-Dec-2016
 Project Name : Pediatric Perimeter v3.x
 Author : CKR
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
 //  MERIDIAN numbering of Device/in Arduino  and No.of LEDs on each Meridian  
 //  Meridian Label  :  1  2  3  4  5  6  7  8  9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  
 //  No. of LEDs     : 25 25 25 25 21 14 13 14 21  25  25  25  25  25  25  25  14  12  12  12  14  26  25  25
 //  
 *************************************************************************************************/

/*  TODO:    
 - can the processing of images and audio into a video be done by a java program? This can be called by the Processing sketch as a subprocess (FFMPEG is a good option but needs to be called by java or a java wrapper)
 - remove CP5 altogether
 
 */
import java.io.*;
import java.awt.Label;
import java.awt.Font;
import java.awt.Color;
import java.awt.event.*;
import java.awt.*;
import javax.swing.*;
import java.text.DateFormat;  //For Date Validation
import java.text.SimpleDateFormat;
import java.text.NumberFormat;
import java.util.Date;
import javax.swing.text.NumberFormatter;  //For OTC Validation
import static javax.swing.JOptionPane.*;
import controlP5.*;
import processing.serial.*;
import codeanticode.gsvideo.*;
import ddf.minim.*; // the audio recording library
import org.apache.poi.ss.usermodel.Sheet; // For Importing The Data From EXcel Sheet 

// DECLARING A CONTROLP5 OBJECT
private ControlP5 cp5;

int meridian_label[] = {
 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
}; // Device Numbering 
int numberOfLEDs[] = {
 25, 25, 25, 25, 21, 14, 13, 14, 21, 25, 25, 25, 25, 25, 25, 25, 14, 12, 12, 12, 14, 26, 25, 25
}; //including Daisy Disc for time interval calculation according to the device numbering 

// Quads Variables 
int quad_state[][] = {
 {  1,  1 }, {  1,  1 }, {  1,  1 }, {  1,  1 }}; 
 // 1 means the quad has not been done yet, 2 means it has already been done, 3 means it is presently going on, negative means it is being hovered upon
color quad_colors[][] = {{#eeeeee, #00ff00, #ffff22, #08BFC4}, {#dddddd, #00ff00, #ffff22, #08BFC4}}; 
 // Color Changes depending on the state 
 int quad_center[] = { 810, 435};
 int quad_diameter[] = { 90, 60};

 //Hemis Variables
 int hemi_state[][] = { {  1,  1 }, {  1,  1 }, {  1,  1 }, {  1,  1 }}; // the same thing is used for the hemis   
 int hemi_center[] = { 1110, 435};
 int hemi_hover_code[][] = { {  0,  3 }, {  1,  2 }};

 // ISOPTER VARIABLES [SWEEP]
 int meridian_state[] = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};
 color meridian_color[] = { #bbbbbb, #bbbbbb, #00ff00, #ffff22}; // Color changes depending on the state
 
 int[][] section_state = {{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1},{1,1,1}};
 color section_color[] = { #bbbbbb, #bbbbbb, #00ff00, #ffff22};
 
 int isopter_center[] = { 970, 220};
 int isopter_diameter = 360;

 // 24 meridians and their present state of testing [MERIDIANS]
 int meridians[] = { 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28}; // negative value means its being hovered over
 color meridian_text_color[] = {};

 // Patterns Variables
 int pattern_state[] = { 1, 1, 1};
 int posPatternImage[][] = { {  105,  540 }, {  255,  540 }, {  385,  540 }};
 // VARIABLES THAT KEEP TRACK OF WHAT OBJECT (HEMI, QUAD OR ISOPTER) WE ARE HOVERING OVER AND WHICH COUNT IT IS
 // THIS WILL ENABLE SENDING A SERIAL COMM TO THE ARDUINO VERY EASILY ON A MOUSE PRESS EVENT
 char hovered_object,
 lastTest_Hobject;
 int hovered_count, hovered_subcount,lastTes_Hsubcount,
 lastTest_Hcount; // the current meridian which has been hovered over
 color hover_color = #08BFC4; //  Color When hovering on Clickable objects
 color backgroundColor = #5f6171;


// VIDEO FEED AND VIDEO SAVING VARIABLES
  GSCapture cam = null; // GS Video Capture Object
   int fps = 60; // The Number of Frames per second Declaration (used for the processing sketch framerate as well as the video that is recorded
   boolean startRecording = false;

   float xi,
   yi;

   // PATIENT INFORMATION VARIABLES - THESE ARE GLOBAL
   // String textName = "test", textAge, textMR, textDescription;  // the MR no is used to name the file, hence this cannot be NULL. If no MR is entered, 'test' is used
   String patient_name,
   patient_MR,
   patient_dob,
   patient_milestone_details,
   patient_OTC;
   String patient_note = "";
   int occipitalDistance; //To store int version of patient_OTC
   PFont textView;

   int previousMillis = 0,
   currentMillis = 0,
   initialMillis,
   finalMillis,
   Sent_Time = 0,
   time_taken,
   prev_time,
   Recieve_Time = 0,
   z = 0; // initial and final are used to calculate the FPS for the video at the verry end
   int previousTime = 0,
   currentTime = 0;
   int reaction_time = 0; // intialize reaction_time to 0 otherwise it gets a weird value which will confuse the clinicians

   PrintWriter isopter_text,
   quadHemi_text,
   note_text; // the textfiles which is used to save information to text files

   String base_folder,
   workingDirectory;

   boolean flagged_test = false;
   int current_sweep_meridian,
   current_gross_test,
   imageFrameCounter;

   // STATUS VARIABLES
   String status = "idle";
   String last_tested = "Nothing";
   int Arduino_Response;
   boolean serialEventFlag = false,
   allDataSentFlag = false;
   int SpaceKey_State = 0; // 0 means it is not pressed , 1 means it is pressed 

   // Variables For Excel Sheet Importing
   SXSSFWorkbook swb = null;
   Sheet sh = null;
   InputStream inp = null;
   Workbook wb = null;
   float[][] angleData;
   float[] bottomMostAngle = new float[30];
int lowLimit,upperLimit;
   

   // SERIAL OBJECT/ARDUINO
   Serial arduino; // create serial object

   // AUDIO RECORDING VARIABLES
   Minim minim;
   AudioInput mic_input;
   AudioRecorder sound_recording;

   // PatternS Images Variables 
   PImage backwardImage,
   forwardImage,
   displayImage;
   PImage subjectIsopter;
   int imageCount;
   PImage eyeDirection;
   int imageNumber;
   public int count = 0;
   // Second window Variables to generate the final Isopter according to the subject's view
   PFrame f;
   PApplet s;
   String daisy_On_Off = "OFF";
   String ledCouplet = "OFF";
   /**********************************************************************************************************************************/
   // THIS IS THE MAIN FRAME
   void setup() {
    if (Serial.list().length != 0) {
     
     String port = Serial.list()[Serial.list().length - 1];
     println("Arduino MEGA connected succesfully.");
   println(port);
     // then we open up the port.. 115200 bauds
     arduino = new Serial(this, port, 115200);
     arduino.buffer(1);

     // send a "clear all" signal to the arduino in case some random LEDs lit up..
     arduino.write('x');
     arduino.write('\n');
     println("Cleared");
    } else {
     println("Arduino not connected or detected, please replug");
     exit();
    }

    // default background colour
    size(1200, 640); // the size of the video feed + the side bar with the controls
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

     for (int i = 0; i < cameras.length; i++) { //Listing the available Cameras      
      if (cameras[i].length() == 13 && cameras[i].substring(3, 6).equals("USB")) {
       println("...success!");
       cam = new GSCapture(this, 640, 480, cameras[i]); // Camera object will capture in 640x480 resolution
       cam.start(); // shall start acquiring video feed from the camera

       int[][] res = cam.resolutions();
       for (i = 0; i < res.length; i++) {
        println(res[i][0] + "x" + res[i][1]);
       }
       String[] fps = cam.framerates();
       for (i = 0; i < fps.length; i++) {
        println(fps[i]);
       }
       break;
      }
     }
     if (cam == null) {
      println("...NO. Please check the camera connected and try again.");
     }
    }

    // INITIATE SERIAL CONNECTION

    // SHow the First Frame to collect the Demographic data of the patient

    //Get the Working Directory of the sketch 
    workingDirectory = sketchPath("");
    //Import The Trace/ 3D - Model Of The Device For The LED Posiions 
    // Gives An Array With The Angle Subtended By The Each LED At The Center Of The Eye
    
    // ADD BUTTONS TO THE MAIN UI, CHANGE DEFAULT CONTROLP5 VALUES
    cp5 = new ControlP5(this);
    cp5.setColorForeground(#eeeeee);
    cp5.setColorActive(hover_color);

    // ADD A BUTTON FOR "FINISHING" WHICH WILL CLOSE AND SAVE THE VIDEO AND ALSO MAKE A POPUP APPEAR THAT SHALL ASK FOR USER INPUTS ABOUT THE TEST (NOTES)
    cp5.addBang("FINISH") //The Bang Clear and the Specifications
     .setPosition(980, 575)
     .setSize(75, 35)
     .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
     .setColor(0);

    cp5.addBang("PATIENT_INFO") //The Bang Clear and the Specifications
     .setPosition(850, 575)
     .setSize(75, 35)
     .setTriggerEvent(Bang.RELEASE)    //To update the hover
     .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
     .setColor(0);

    PImage[] flagImage = {
     loadImage("flagW.png"),
     loadImage("flagB.png"),
     loadImage("flagW.png")
    };
    cp5.addButton("FLAG")
     .setValue(128)
     .setPosition(730, 60)
     .setImages(flagImage)
     .updateSize();


    PImage[] notesImage = {
     loadImage("noteW.png"),
     loadImage("noteB.png"),
     loadImage("noteW.png")
    };
    cp5.addButton("ADD_NOTE")
     .setBroadcast(false)    //To stop broadcast of add button at the start
     .setValue(128)
     .setPosition(730, 100)
     .setImages(notesImage)
     .updateSize()
     .setBroadcast(true);   //To sart the broadcast again when triggered

    PImage[] captureImage = {
     loadImage("captureW.png"),
     loadImage("captureB.png"),
     loadImage("captureW.png")
    };

    cp5.addButton("CAPTURE")
     .setValue(128)
     .setPosition(730, 140)
     .setImages(captureImage)
     .updateSize();

    PImage[] patternOne = {
     loadImage("pattern1W.png"),
     loadImage("pattern1B.png"),
     loadImage("pattern1W.png")
    };
    cp5.addButton("PATTERNONE")
     .setValue(128)
     .setPosition(posPatternImage[0][0], posPatternImage[0][1])
     .setImages(patternOne)
     .updateSize();

    PImage[] patternTwo = {
     loadImage("pattern2W.png"),
     loadImage("pattern2B.png"),
     loadImage("pattern2W.png")
    };
    cp5.addButton("PATTERNTWO")
     .setValue(128)
     .setPosition(posPatternImage[1][0], posPatternImage[1][1])
     .setImages(patternTwo)
     .updateSize();

    PImage[] patternThree = {
     loadImage("pattern3W.png"),
     loadImage("pattern3B.png"),
     loadImage("pattern3W.png")
    };
    cp5.addButton("PATTERNTHREE")
     .setValue(128)
     .setPosition(posPatternImage[2][0], posPatternImage[2][1])
     .setImages(patternThree)
     .updateSize();


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
     .setFont(createFont("Georgia", 13));
    // To Indicate The Lower Range     
    cp5.addTextlabel("Low Range")
     .setText("1")
     .setPosition(745, 520)
     .setColorValue(0x00000000)
     .setFont(createFont("Georgia", 12));
    cp5.addTextlabel("High Range")
     .setText("10")
     .setPosition(890, 520)
     .setColorValue(0x00000000)
     .setFont(createFont("Georgia", 12));


    // To Define The Slider To Vary The LED Sweep Interval 
    cp5.addSlider("FIXATION") // Time Interval For LEDs Sweep
     .setPosition(1000, 510)
     .setSize(150, 10)
     .setRange(2, 75)
     .setColorValue(255)
     // .setLabel("Sweep")
     .setValue(75)
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
     .setFont(createFont("Georgia", 13));
    // To Indicate The Lower Range     
    cp5.addTextlabel("Low Range 1")
     .setText("2")
     .setPosition(995, 520)
     .setColorValue(0x00000000)
     .setFont(createFont("Georgia", 12));
    cp5.addTextlabel("High Range 1")
     .setText("75")
     .setPosition(1150, 520)
     .setColorValue(0x00000000)
     .setFont(createFont("Georgia", 12)); 
    cp5.addRadioButton("DAISY")
         .setPosition(925,425)
         .setSize(25,10)
         .setColorForeground(hover_color)
         .setColorActive(#ffff00)
         .setColorLabel(color(0))
         .setSpacingColumn(50)
         .addItem("Daisy",1)
         ;
    cp5.addRadioButton("LED_COUPLET")
         .setPosition(925,460)
         .setSize(25,10)
         .setColorForeground(hover_color)
         .setColorActive(#ffff00)
         .setColorLabel(color(0))
         .setSpacingColumn(50)
         .addItem("Led_Couplet",1)
         ;

    JPanel panel = new JPanel();
    panel.setLayout(new GridLayout(4, 1));
    JLabel ard = new JLabel("Arduino");
    JLabel camc = new JLabel("Camera");
    //198-512.png

    JPanel hd = new JPanel();
    hd.setLayout(null);

    Label cap = new Label("Patients Info", Label.CENTER);
    cap.setFont(new Font("Serif", Font.BOLD, 20));
    cap.setForeground(Color.BLACK);

    cap.setLocation(150, 10);
    cap.setSize(150, 60);
    String path1 = workingDirectory + "r.png";
    String path2 = workingDirectory + "g.png";
    ImageIcon red, grn;
    if (arduino == null) {
     red = new ImageIcon(path1);
    } else {
     red = new ImageIcon(path2);
    }

    JLabel red1 = new JLabel();
    red1.setIcon(red);
    red1.setLocation(410, 45);
    red1.setSize(10, 10);
    if (cam == null) {
     grn = new ImageIcon(path1);
    } else {
     grn = new ImageIcon(path2);
    }

    JLabel grn1 = new JLabel(grn);
    grn1.setLocation(410, 65);
    grn1.setSize(10, 10);
    hd.add(red1);
    hd.add(grn1);
    hd.add(cap);
    ard.setLocation(350, 40);
    ard.setSize(60, 20);
    camc.setLocation(350, 60);
    camc.setSize(60, 20);
    hd.add(ard);
    hd.add(camc);

    panel.add(hd);

    JLabel lbl1 = new JLabel("Patient Name");
    JLabel lbl2 = new JLabel("MR Number");
    JLabel lbl3 = new JLabel("Date of Birth (dd/mm/yy)");
    JLabel lbl4 = new JLabel("Milestone details");
    JLabel lbl5 = new JLabel("Occipital Distance (0 - 28 cm)");

    final JTextField pname = new JTextField(10);
    final JTextField pMR = new JTextField(10);
    
    DateFormat df = new SimpleDateFormat("dd/MM/yy");
    final JFormattedTextField pdob = new JFormattedTextField(df);
    
    final JTextField pmilestone_details = new JTextField(10);
    
    NumberFormat intFormat = NumberFormat.getIntegerInstance();
    NumberFormatter numberFormatter = new NumberFormatter(intFormat);
    numberFormatter.setValueClass(Integer.class); //optional, ensures you will always get a int value
    numberFormatter.setAllowsInvalid(false);
    numberFormatter.setMinimum(0); //Optional
    numberFormatter.setMaximum(28); //Optional
    final JFormattedTextField potc = new JFormattedTextField(numberFormatter);

    JPanel labels = new JPanel();
    labels.setLayout(new GridLayout(5, 2));
    labels.add(lbl1);
    labels.add(pname);
    labels.add(lbl2);
    labels.add(pMR);
    labels.add(lbl3);
    labels.add(pdob);
    labels.add(lbl4);
    labels.add(pmilestone_details);
    labels.add(lbl5);
    labels.add(potc);

    JPanel instr = new JPanel(new GridLayout(0, 1));
    Label inscap = new Label("Instructions", Label.CENTER);
    inscap.setFont(new Font("Serif", Font.BOLD, 15));
    inscap.setForeground(Color.BLACK);
    instr.add(inscap);
    JLabel l1 = new JLabel("1. Parents should be given informed consent for signing.");
    JLabel l2 = new JLabel("2. Only the parents and 3 (maximum) examiners would be allowed to stay inside the room during the testing.");
    JLabel l3 = new JLabel("3. Try re-connecting the arduino before you run the code ");
    instr.add(l1);
    instr.add(l2);
    instr.add(l3);
    panel.add(labels);
    panel.add(instr);

    int result = JOptionPane.showConfirmDialog(
     this, // use your JFrame here
     panel,
     "Enter Details",
     JOptionPane.OK_CANCEL_OPTION,
     JOptionPane.PLAIN_MESSAGE);

    boolean firstTime = true;            //For validation message
    if (result == JOptionPane.OK_OPTION) {

     //This While loop is used for validation of form
     while (pname.getText().length() == 0 || pMR.getText().length() == 0 || pdob.getText().length() == 0 || pmilestone_details.getText().length() == 0 || potc.getText().length() == 0) {
      if (firstTime) {
       JLabel l4 = new JLabel("Please fill the details correctly.");
       l4.setForeground(Color.RED);
       l4.setFont(new Font("Serif", Font.BOLD, 18));
       instr.add(l4);
       panel.add(instr);
       firstTime = false;
      }
      result = JOptionPane.showConfirmDialog(
       this, // use your JFrame here
       panel,
       "Enter Correct Details",
       JOptionPane.OK_CANCEL_OPTION,
       JOptionPane.PLAIN_MESSAGE);
      if (result == JOptionPane.CANCEL_OPTION) {
       exit();
       break;
      }
     }
     //Validation Ends here

     patient_name = pname.getText();
     patient_MR = pMR.getText();
     patient_dob = pdob.getText();
     patient_milestone_details = pmilestone_details.getText();
     patient_OTC = potc.getText();
     
     occipitalDistance = Integer.parseInt(patient_OTC.trim());
     angleData = importExcel(workingDirectory + "/AngleData.xlsx"); // Gives An Array With The Angle Subtended By The Each LED At The Center Of The Eye

     // Create files for saving patient details
     // give them useful header information
     base_folder = year() + "/" + month() + "/" + day() + "/" + patient_name + "_" + hour() + "_" + minute() + "_hrs"; // the folder into which data will be stored - categorized chronologically
     isopter_text = this.createWriter(base_folder + "/" + patient_name + "_isopter.txt");
     isopter_text.println("Isopter angles for patient " + patient_name);
     isopter_text.println("MR No : " + patient_MR);
     isopter_text.println("Date of Birth : " + patient_dob);
     isopter_text.println("Milestone Details : " + patient_milestone_details);
     isopter_text.println("Occipital to Corneal Distance (cm) : " + patient_OTC);
     isopter_text.println("Timestamp : " + hour() + ":" + minute() + ":" + second());
     isopter_text.println("Timestamp\t|Meridian\t|Angle\t|Reaction Time (ms)\t|Flag\t");
     isopter_text.flush();

     quadHemi_text = this.createWriter(base_folder + "/" + patient_name + "_quads_hemis.txt");
     quadHemi_text.println("Meridian and Quad tests for patient " + patient_name);
     quadHemi_text.println("MR No : " + patient_MR);
     quadHemi_text.println("Date of Birth : " + patient_dob);
     quadHemi_text.println("Milestone Details : " + patient_milestone_details);
     quadHemi_text.println("Occipital to Corneal Distance (cm) : " + patient_OTC);
     quadHemi_text.println("Timestamp : " + hour() + ":" + minute() + ":" + second());
     quadHemi_text.println("Timestamp\t|Test done\t|Reaction Time\t|Flag\t");
     quadHemi_text.flush();


     // AUDIO RECORDING SETTINGS
     minim = new Minim(this);
     mic_input = minim.getLineIn(); // keep this ready. This is the line-in.

     // CREATE A NEW AUDIO OBJECT
     sound_recording = minim.createRecorder(mic_input, base_folder + "/recording.wav", false); // the false means that it would save directly to disc rather than in a buffer
     sound_recording.beginRecord();


     // Start Desktop Recording as a background process
     String video_folder = workingDirectory + "/" + base_folder + "/video.mpg";
     try {
      String[] ffmpeg_command = {
       "C:\\Windows\\System32\\cmd.exe",
       "/c",
       "start",
       "ffmpeg",
       "-f",
       "gdigrab",
       "-framerate",
       "50",
       "-i",
       "desktop",
       "-vb",
       "48M",
       video_folder
      };
      ProcessBuilder p = new ProcessBuilder(ffmpeg_command);
      Process pr = p.start();

     } catch (IOException e) {
      e.printStackTrace();
      exit();
     }


     // angleDadta stores the values according to device numbering
     // Initialize the pattern_state 
     pattern_state[0] = 1;
     pattern_state[1] = 1;
     pattern_state[2] = 1;
     //arduino.write('x');
     //arduino.write('\n');
    } else {
     exit();
    }


   }

   void draw() {
    // update the millisecond counter
    currentMillis = millis();

    if (frameCount == 1) {
     initialMillis = currentMillis;
    }

    // plain and simple background color
    background(backgroundColor); //4B66A8

    // draw the video capture here
    fill(0);
    rect(80, 50, 640, 480);
    if (cam.available() == true) {
     cam.read();
    }
   image(cam, 80, 50); // display the image, interpolate with the previous image if this one was a dropped frame

    // Overlay a protractor on the live feed 
    PImage protractor = loadImage("protractor.png");
    image(protractor, 309, 203);

    // Baby's Animation


    // Draw the picture to show the patterns

    for (int i = 0; i < 3; i++) {
     if (pattern_state[i] < 0) {
      fill(hover_color);
      pattern_state[i] = abs(pattern_state[i]);
     } else if (pattern_state[i] == 2) {
      fill(#ffff00); // In Progress
     } else if (pattern_state[i] == 1) {
      fill(backgroundColor);
     }
     ellipse(posPatternImage[i][0] - 25, posPatternImage[i][1] + 60, 10, 10);
    }

    // Checkin
    // draw the crosshair at the center of the video feed
    stroke(#ff0000);
    line(395, 290, 405, 290);
    line(400, 285, 400, 295);

    // draw the hemis and quads in their present state
    colorQuads(quad_state, quad_center[0], quad_center[1], 2.5, 2.5); // quads
    colorQuads(hemi_state, hemi_center[0], hemi_center[1], 2.5, 0); // hemis

    // check if the mouse is hovering over the hemis, quads or isopter - if so, change to hover colour
    hover(mouseX, mouseY);

    // draw the isopter/meridians
    drawIsopter(meridians, isopter_center[0], isopter_center[1], isopter_diameter);
    // print reaction time and information about what was the last thing tested and the thing presently being tested
    fill(0);
    text("Reaction time is  : " + str(reaction_time) + "ms", 520, 565);
    text("Last thing tested : " + last_tested, 520, 595);
    text("Present Status    : " + status, 520, 625);
    text(str(currentMillis) + "ms", 1075, 625); // milliseconds elapsed since the program began
    text("Value :" + cp5.getController("FIXATION").getValue(), 1025, 545); // display the brightness 
    text(daisy_On_Off, 925 , 450);
    text(ledCouplet,925,485);
    // RECORD THE FRAME, SAVE AS RECORDED VIDEO
    // THIS MUST BE THE LAST THING IN void draw() OTHERWISE EVERYTHING WON'T GET ADDED TO THE VIDEO FRAME
    //  saveFrame(workingDirectory + base_folder + "/frames/frame-####.jpg");      //save each frame to disc without compression
   }



   public class PFrame extends JFrame {
    public PFrame(int width, int height) {
     setBounds(100, 100, 1366, 768);
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
    int d1 = 20, d2 = 360, d, Value = 0;

    float    collectCoordinates [][] = { 
      { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
      , { 
        0, 0, 0
      }
    };

    boolean insertOrigin = false, originIncluded = false;
    int count, index;

    int dotsCounter;
    boolean coversAllQuads[] = {
     false,
     false,
     false,
     false
    };

    public void setup() {
     background(0);
     noStroke();
    }

    public void draw() {
     background(#cccccc);
     fill(255);
     ellipse(mouseX, mouseY, 10, 10);
     fill(#cccccc);
     ellipse(x, y, 2 * d2 + d1, 2 * d2 + d1);
     drawIsopter2(meridians, 683, 380, 650);



     if (dotsCounter >= 3) {
      float swap;
      // Sort The array for red dots Joining 
      if (frameCount == 1) {
       for (int c = 0; c < dotsCounter; c++) {
        for (int d = 0; d < dotsCounter - c - 1; d++) {
         if (collectCoordinates[d][2] < collectCoordinates[d + 1][2]) {
          swap = collectCoordinates[d][2];
          collectCoordinates[d][2] = collectCoordinates[d + 1][2];
          collectCoordinates[d + 1][2] = swap;

          swap = collectCoordinates[d][1];
          collectCoordinates[d][1] = collectCoordinates[d + 1][1];
          collectCoordinates[d + 1][1] = swap;

          swap = collectCoordinates[d][0];
          collectCoordinates[d][0] = collectCoordinates[d + 1][0];
          collectCoordinates[d + 1][0] = swap;
         }
        }
       }

       count = 0;
       index = 0; // Initialising
       for (int i = 0; i < 4; i++) {
        if (!(coversAllQuads[i])) {
         index = i;
         insertOrigin = true;
         count++;
        }
       }
       println("index and count and state of quads: " + index + " " + count);
       println(coversAllQuads);

       //Update the CollectCoordinates[][] with Origin If required
       if (insertOrigin) {
        println("trying to Insert Origin");
        if (count == 3 || count == 2) {
         //Append the origin Coordinates at the end on the matrix
         collectCoordinates[dotsCounter][0] = 683;
         collectCoordinates[dotsCounter][1] = 380;
         dotsCounter++;
        } else if (count == 1) {
         // Insert the origin into the matrix
         float tempX = 683, tempY = 380;
         boolean originInserted = false;
         int j;
         for (j = 0; j < dotsCounter; j++) {
          if (collectCoordinates[j][2] < (index + 1) * 90) {
           swap = tempX;
           tempX = collectCoordinates[j][0];
           collectCoordinates[j][0] = swap;

           swap = tempY;
           tempY = collectCoordinates[j][1];
           collectCoordinates[j][1] = swap;
           originInserted = true;
          }
         }
         collectCoordinates[dotsCounter][0] = tempX;
         collectCoordinates[dotsCounter][1] = tempY;
         dotsCounter++;
        }
       }
      }


      for (int k = 0; k < dotsCounter; k++) {
       println(collectCoordinates[k][0] + " " + collectCoordinates[k][1] + "  " + collectCoordinates[k][2]);
      }


      stroke(0);
      noFill();
      beginShape();
      curveVertex(collectCoordinates[0][0], collectCoordinates[0][1]);
      int j;
      for (j = 0; j < dotsCounter; j++) {
       curveVertex(collectCoordinates[j][0], collectCoordinates[j][1]);
      }

      curveVertex(collectCoordinates[0][0], collectCoordinates[0][1]);
      curveVertex(collectCoordinates[1][0], collectCoordinates[1][1]);
      endShape();
     }

     textView = loadFont(workingDirectory + "/data/GoudyOldStyleT-Bold-48.vlw");
     textFont(textView, 40);
     fill(#ff0000);
     text("Baby's \n Right ", 975, 75);
     text("Baby's \n left ", 325, 75);
     if (frameCount == 1) {
      subjectIsopter = get(300, 25, 800, 700);
      subjectIsopter.save(workingDirectory + base_folder + "/Isopter_Report.jpg");
     }
    }


    void drawIsopter2(int[] meridians, int x, int y, int diameter) {
     // first draw the background circle
     stroke(0);
     fill(#eeeeee);
     ellipse(x, y, diameter, diameter); // the outer circle of the isopter, representing the projection of the whole dome

     for (int i = 7; i >= 1; i--) {

      float r_IsopterRange = diameter * ((i * 15.0) / 120);
      float yc = sin(radians(-90)) * (r_IsopterRange + 20) / 2 + y + 15;
      if (i == 1) {
       stroke(0);
      } else {
       stroke(#bbbbbb);
      }
      ellipse(x, y, r_IsopterRange, r_IsopterRange);
      fill(#bbbbbb);
      text(str(i * 15), x - 5, yc);
      fill(#eeeeee);
     }

     int mappingIndex; // mappingIndex  = (36 - i)% 24  [ Maps the Isopter  to the Baby's Point of View ]
     // Then draw the 24 meridians

     for (int i = 0; i < 24; i++) {
      // first calculate the location of the points on the circumference of this circle, given that meridians are at 15 degree (PI/12) intervals

      mappingIndex = (36 - i) % 24;
      float xm = cos(radians(-mappingIndex * 15)) * diameter / 2 + x;
      float ym = sin(radians(-mappingIndex * 15)) * diameter / 2 + y;

      // This will not be changed because the values are not changed with this change in orientation
      if (meridian_state[i] < 0) { //Notify That the mouse is hovering on the Meridians
       //stroke(hover_color);
       stroke(#bbbbbb);
       meridian_state[i] = abs(meridian_state[i]); // revert to earlier thing
      } else if (meridian_state[i] > 0 && meridian_state[i] <= 3) { //Color The Meridian If It Is Done 
       // stroke(meridian_color[meridian_state[i]]);
       stroke(#bbbbbb);
      } else {
       stroke(#bbbbbb);
      }

      // draw a line from the center to the meridian points (xm, ym)
      line(x, y, xm, ym);

      // draw the text at a location near the edge, which is along an imaginary circle of larger diameter - at point (xt, yt)
      // No Change in the position of the text 
      float xt = cos(radians(-i * 15)) * (diameter + 30) / 2 + x - 10;
      float yt = sin(radians(-i * 15)) * (diameter + 20) / 2 + y + 5;

      if (meridians[i] < 0) {
       fill(#ff0000);
       meridians[i] = abs(meridians[i]);
      } else {
       fill(0);
      }
      text(str(i * 15), xt, yt); // draw the label of the meridian (in degrees)

      // NOW WE DRAW THE RED DOTS FOR THE REALTIME FEEDBACK
      fill(#ff0000); // red colour
      if (abs(meridians[i]) < 28) {
       // Get The Angle of the LED 
       //  angleData[meridianNumber-1][pixelNumber-1] = finalAngleValue;
       // Check whether it is obtuse or not
       int pixelNumber = abs(meridians[i]); // LED No. if Sweep is ON 
       // int meridianNumber = (24 - (((24 - i)%24) + 12) % 24)%24;
       int meridianNumber = (24 - i) % 24; // based on Device numbering for The 
       int numberOfPixels = numberOfLEDs[(24 - i) % 24]; // Based on the device numbering 
       //println(((25 - i)%24) + " " + numberOfPixels);
       if (pixelNumber > 0 && pixelNumber <= numberOfPixels + 1) {

        if (pixelNumber > 3) { // For Meridian LEDs
         xi = (cos(radians(-mappingIndex * 15)) * (10 + (diameter - 10) / 2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber] / 120) + x;
         yi = (sin(radians(-mappingIndex * 15)) * (10 + (diameter - 10) / 2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber] / 120) + y;
        } else if (pixelNumber <= 3) { // For Daisy LEDs
         xi = (cos(radians(-mappingIndex * 15)) * (10 + (diameter - 10) / 2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber] / 120) + x;
         yi = (sin(radians(-mappingIndex * 15)) * (10 + (diameter - 10) / 2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber] / 120) + y;
        }
        ellipse(xi, yi, 10, 10);
        if (frameCount == 1) {
         collectCoordinates[dotsCounter][0] = xi;
         collectCoordinates[dotsCounter][1] = yi;
         collectCoordinates[dotsCounter][2] = mappingIndex * 15; // Re - arrange While joining the red dots

         // This has to be done to join the dots on the final report
         if (xi > x && yi >= y) {
          coversAllQuads[3] = true;
         } else if (xi > x && yi <= y) {
          coversAllQuads[0] = true;
         } else if (xi <= x && yi < y) {
          coversAllQuads[1] = true;
         } else if (xi <= x && yi > y) {
          coversAllQuads[2] = true;
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
    byte quad_positions[][] = { {  1,  1 }, {  0,  1 }, {  0,  0 }, {  1,  0 }};

    for (int i = 0; i < 4; i++) { // 4 quadrants
     for (int j = 0; j < 2; j++) { // inner and outer
      if (quad_state[i][j] > 0) {
       fill(quad_colors[j][quad_state[i][j] - 1]); // filling the corresponding quadrant
      } else {
       fill(hover_color); // fill the hover colour
       quad_state[i][j] = abs(quad_state[i][j]); // revert to earlier thing
      }
      noStroke();
      // finally, we draw the actual quads x4
      arc(x + dx * quad_positions[i][0], y + dy * quad_positions[i][1], quad_diameter[j], quad_diameter[j], i * HALF_PI, HALF_PI + i * HALF_PI);
     }
    }
   }

   // DRAW THE ISOPTER WITH THE UPDATED POSITIONS OF THE RED DOTS
   void drawIsopter(int[] meridians, int x, int y, int diameter) {
    // first draw the background circle
    stroke(0);
    fill(#eeeeee);
    ellipse(x, y, diameter, diameter); // the outer circle of the isopter, representing the projection of the whole dome

    for (int i = 7; i >= 1; i--) {
     float r_IsopterRange = diameter * ((i * 15.0) / 120);
     float yc = sin(radians(-90)) * (r_IsopterRange + 20) / 2 + y + 15;
     if (i == 1) {
      stroke(0);
     } else {
      stroke(#bbbbbb);
     }
     ellipse(x, y, r_IsopterRange, r_IsopterRange);
     fill(#bbbbbb);
     text(str(i * 15), x - 5, yc);
     fill(#eeeeee);
    }

    // Then draw the 24 meridians
    for (int i = 0; i < 24; i++) {
      
      //To On the Complete Meridian
     if( daisy_On_Off == "ON") {
     // first calculate the location of the points on the circumference of this circle, given that meridians are at 15 degree (PI/12) intervals
     float xm = cos(radians(-i * 15)) * diameter / 2 + x;
     float ym = sin(radians(-i * 15)) * diameter / 2 + y;

     if (meridian_state[i] < 0) { //Notify That the mouse is hovering on the Meridians
      strokeWeight(2);
      stroke(hover_color);
      meridian_state[i] = abs(meridian_state[i]); // revert to earlier thing
     } else if (meridian_state[i] > 0 && meridian_state[i] <= 3) { //Color The Meridian If It Is Done 
      stroke(meridian_color[meridian_state[i]]);
     } else {
      stroke(#bbbbbb);
     }

     // draw a line from the center to the meridian points (xm, ym)
     line(x, y, xm, ym);
     strokeWeight(1); // Restore the default Value 
      }
      else {   // This code is to control the  display of the each section from the tri-sected meridian
      
   float x1,y1,x2 ,y2;

   // draw a line from the center to the meridian points (xm, ym)
   x1 = x;
   y1 = y;
   
   x2 = cos(radians(-i * 15)) * (diameter/2)+ x;
   y2 =  sin(radians(-i * 15)) * (diameter/2)+y;
   
   strokeWeight(1); // Restore the default Value r
   stroke(#bbbbbb);
   line(x1, y1, x2, y2);
  
  for(int k =0; k<3 ; k++){
    //println(section_state[i][k]);
     if (section_state[i][k] < 0) { //Notify That the mouse is hovering on the Meridians
      strokeWeight(2);
      stroke(hover_color);
      //println(i);
      section_state[i][k] = abs(section_state[i][k]); // revert to earlier thing
     x1 = cos(radians(-i * 15)) *( diameter*(k+1)*30/120) / 2 + x;
     y1 = sin(radians(-i * 15)) * (diameter*(k+1)*30/120) / 2 + y;
     
     x2 =   cos(radians(-i * 15)) *( diameter*(k)*30/120) / 2 + x;
     y2 = sin(radians(-i * 15)) * (diameter*(k)*30/120) / 2 + y;
     line(x1, y1, x2, y2);
           fill(hover_color);

     text(str((k+1) * 30), x1, y1);

     } else if (section_state[i][k] ==2 || section_state[i][k] == 3) { //Color The Meridian If It Is Done 
    // println("Coloring Accordingly");
      stroke(section_color[section_state[i][k]]);
     x1 = cos(radians(-i * 15)) *( diameter*(k+1)*30/120) / 2 + x;
     y1 = sin(radians(-i * 15)) * (diameter*(k+1)*30/120) / 2 + y;
     
     x2 = cos(radians(-i * 15)) * (diameter*(k)*30/120) / 2 + x;
     y2 = sin(radians(-i * 15)) * (diameter*(k)*30/120) / 2 + y;
     line(x1, y1, x2, y2);
     } else {
      stroke(#bbbbbb);
      x1 =x;
      y1 = y;
      
      x2 = cos(radians(-i * 15)) * (diameter)+ x;
      y2 =  sin(radians(-i * 15)) * (diameter)+y;
     }
     strokeWeight(1);
  }
       
     } 
     // draw the text at a location near the edge, which is along an imaginary circle of larger diameter - at point (xt, yt)
     float xt = cos(radians(-i * 15)) * (diameter + 30) / 2 + x - 10;
     float yt = sin(radians(-i * 15)) * (diameter + 20) / 2 + y + 5;
     if (meridians[i] < 0) {
      fill(hover_color);
      meridians[i] = abs(meridians[i]);
     } else {
      fill(0); //#DADEDE
     }
     text(str(i * 15), xt, yt); // draw the label of the meridian (in degrees)
         
     
     //Boundaries of the device need to be displayed 
     float radiusLargerSide = (angleData[16][0] / 120) * diameter;
     float radiusSmallerSide = (angleData[7][0] / 120) * diameter;
     float x1 = x;
     float y1 = y;
     stroke(0);
     //fill
     noFill();
     arc(x, y, radiusLargerSide, radiusLargerSide, -2 * PI / 3, -PI / 3);
     arc(x, y, radiusSmallerSide, radiusSmallerSide, -285 * PI / 180, -255 * PI / 180);

     // NOW WE DRAW THE RED DOTS FOR THE REALTIME FEEDBACK
     fill(#ff0000); // red colour
     if (abs(meridians[i]) < 28) {
      // Get The Angle of the LED 
      //  angleData[meridianNumber-1][pixelNumber-1] = finalAngleValue;
      // Check whether it is obtuse or not
      int pixelNumber = abs(meridians[i]); // LED No. if Sweep is ON 
      int meridianNumber = (24 - i) % 24; // based on Device numbering for The 
      int numberOfPixels = numberOfLEDs[(24 - i) % 24]; // Based on the device numbering 
      if (pixelNumber > 0 && pixelNumber <= numberOfPixels + 1) {

       if (pixelNumber > 3) { // For Meridian LEDs
        xi = (cos(radians(-i * 15)) * (10 + (diameter - 10) / 2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber] / 120) + x;
        yi = (sin(radians(-i * 15)) * (10 + (diameter - 10) / 2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber] / 120) + y;
       } else if (pixelNumber <= 3) { // For Daisy LEDs
        xi = (cos(radians(-i * 15)) * (10 + (diameter - 10) / 2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber] / 120) + x;
        yi = (sin(radians(-i * 15)) * (10 + (diameter - 10) / 2)) * (angleData[meridianNumber][numberOfPixels - pixelNumber] / 120) + y;
        println(pixelNumber + "  " + angleData[meridianNumber][numberOfPixels - pixelNumber]);
       }
       ellipse(xi, yi, 10, 10);
      }
     }
    }
   }

   // CHECK IF THE MOUSE IS OVER ANYTHING IMPORTANT
   // DO THIS BY FINDING IF THE RADIAL DISTANCE FROM ANY OF THE HEMI, QUAD OR ISOPTER IS SIGNIFICANT
   void hover(float x, float y) {
    hovered_object = 'c'; // random character which has no meaning to the arduino API
    if (x > 640) { // otherwise it's over the video and therefore none of our concern
     float r_isopter = sqrt(sq(x - isopter_center[0]) + sq(y - isopter_center[1]));
     float r_quad = sqrt(sq(x - quad_center[0]) + sq(y - quad_center[1]));
     float r_hemi = sqrt(sq(x - hemi_center[0]) + sq(y - hemi_center[1]));

     // CHECK FOR ISOPTER, HEMI OR QUAD
     if (r_isopter < 0.5 * (isopter_diameter + 30)) { // larger diameter, so that the text surrounding the isopter can also be selected
      // calculate angle at which mouse is from the center
      float angle = degrees(angleSubtended(x, y, isopter_center[0], isopter_center[1]));
      meridians[hovered_count] = abs(meridians[hovered_count]); // clear out the previously hovered one
      hovered_count = int((angle + 5) / 15) % 24; // this is the actual angle on which you are hovering
      if (r_isopter < 0.5 * (isopter_diameter)) { //Check On Meridians
      
      if (daisy_On_Off == "ON"){ // For Complete Meridian
       hovered_object = 'm';
       meridian_state[hovered_count] *= -1;
       
      } else{ // For Sections on Meridian
      
      if (r_isopter >= 0.5 * (isopter_diameter*60/120) && r_isopter < 0.5 * (isopter_diameter *90/120) ) {
         hovered_object = 'z';
         section_state[hovered_count][2] *= -1;
         hovered_subcount = 2;
       }else if((r_isopter >= 0.5 * (isopter_diameter*30/120) && r_isopter < 0.5 * (isopter_diameter *60/120) )) {
         hovered_object = 'z';
         section_state[hovered_count][1] *= -1;
         hovered_subcount =1;
       }else if(( r_isopter < 0.5 * (isopter_diameter *30/120) )){
         hovered_object = 'z';
         section_state[hovered_count][0] *= -1;
         hovered_subcount =0;
       }
      }
      
      } else {
       hovered_object = 's';
       meridians[hovered_count] = -1 * abs(meridians[hovered_count]); // set the presently hovered meridian to change state
      }
      cursor(HAND); // change cursor to indicate that this thing can be clicked on
     } else if (r_quad < 0.5 * quad_diameter[0]) {
      hovered_object = 'q';
      // calculate angle at which mouse is from the center
      float angle = angleSubtended(x, y, quad_center[0], quad_center[1]);
      cursor(HAND);

      if (r_quad < 0.5 * quad_diameter[1]) {
       // inner quads
       if(((Float)angle).isNaN()) {    // For avoiding crashes due to angle = NaN if bychance
         angle = HALF_PI;
       }
       hovered_count = 4 + int((angle + HALF_PI) / HALF_PI);
       quad_state[abs(8 - hovered_count)][1] *= -1;
      } else {
       // outer quads
       hovered_count = int((angle + HALF_PI) / HALF_PI);
       quad_state[abs(4 - hovered_count)][0] *= -1;
      }
     } else if (r_hemi < 0.5 * quad_diameter[0]) {
      hovered_object = 'h';
      // calculate angle at which mouse is from the center
      float angle = angleSubtended(x, y, hemi_center[0], hemi_center[1]);
      cursor(HAND);
      // choose inner or outer hemis
      if (r_hemi < 0.5 * quad_diameter[1]) {
       // inner quads
       
       hovered_count = 2 + int((angle + HALF_PI) / PI) % 2;
       hemi_state[hemi_hover_code[hovered_count - 2][0]][1] *= -1;
       hemi_state[hemi_hover_code[hovered_count - 2][1]][1] *= -1;
      } else {
       // outer quads
       hovered_count = int((angle + HALF_PI) / PI) % 2;
       hemi_state[hemi_hover_code[hovered_count][0]][0] *= -1;
       hemi_state[hemi_hover_code[hovered_count][1]][0] *= -1;
      }
     } else {
      cursor(ARROW);
     }
    } else if ((x >= posPatternImage[0][0] && x <= posPatternImage[0][0] + 80) && (y >= posPatternImage[0][1] && y <= posPatternImage[0][1] + 80)) { // Hovering on the Image Pattern -1 
     cursor(HAND);
    } else if ((x >= posPatternImage[1][0] && x <= posPatternImage[1][0] + 80) && (y >= posPatternImage[1][1] && y <= posPatternImage[1][1] + 80)) { // Hovering on the Image  Pattern -2 
     cursor(HAND);
    } else if ((x >= posPatternImage[2][0] && x <= posPatternImage[2][0] + 80) && (y >= posPatternImage[2][1] && y <= posPatternImage[2][1] + 80)) { // Hovering on the Image  Pattern -3 
     cursor(HAND);
    } else if ((x >= 730 && x <= 760) && (y >= 60 && y <= 90)) { // Hovering on the Image  Pattern -3 
     cursor(HAND);
    } else if ((x >= 730 && x <= 760) && (y >= 100 && y <= 130)) { // Hovering on the Image  Pattern -3 
     cursor(HAND);
    } else if ((x >= 730 && x <= 760) && (y >= 140 && y <= 170)) { // Hovering on the Image  Pattern -3 
     cursor(HAND);
    } else {
     cursor(ARROW);
    }
   }

   // QUICK FUNCTION TO CALCULATE THE ANGLE SUBTENDED
   float angleSubtended(float x, float y, int c1, int c2) {
    // angle subtended by (x,y) to fixed point (c1,c2) 
      if(x == c2) {
        return HALF_PI;  // To avoid INFINITY
      }
      float angle = atan(abs(y - c2) / abs(x - c1));
      if(x <= c1 && y < c2) {
        angle = PI-angle;   // Quadrant 2
      }
      if(x < c1 && y >= c2) {
        angle = PI+angle;   // Quadrant 3
      }
      if(x >= c1 && y > c2) {
        angle = (2*PI) - angle;  // Quadrant 4
      }
      return angle;
   }
   
// QUICK FUNCTION TO CALCULATE THE ANGLE SUBTENDED
//float angleSubtended(float x, float y, int c1, int c2) {
//  // angle subtended by (x,y) to fixed point (c1,c2)
//  float angle = atan((x - c1)/(y - c2));
//  if (y > c2) {  // if the reference point is in the 3rd or 4th quadrant w.r.t. a circle with (c1,c2) as center
//    angle = PI + angle;
//  }
//  if(y == c2) {
//    angle = 0;
//  }
//  return angle + HALF_PI;
//}


   void mousePressed() {
    // really simple - just send the instruction to the arduino via serial
    // it will be of the form (hovered_object, hovered_count\n)
    if (hovered_object == 'h' || hovered_object == 'q' || hovered_object == 's' || hovered_object == 'm' || hovered_object == 'z') {
     // reset flag and start high quality high speed recording
     flagged_test = false;
     startRecording = true;

     // print to the console what test is going on
     print(str(hovered_object) + ",");
     println(str(hovered_count));

     // Send The time intervals before initiating the kinetic mode 
     if (hovered_object == 's') {
      sendTimeIntervals((24 - hovered_count) % 24 + 1); // this converts coordinates to the frame of reference of the actual system (angles inverted w.r.t. x-axis)
     }

     // send message to the arduino
     arduino.write(hovered_object);
     arduino.write(',');
     if (hovered_object == 's' || hovered_object == 'm') {
      arduino.write(str((24 - hovered_count) % 24 + 1)); // this converts coordinates to the frame of reference of the actual system (angles inverted w.r.t. x-axis)
     }else if(hovered_object == 'z'){
       println("HC :"+hovered_count);
       println("HSC :"+ hovered_subcount);
       getTheLimits(hovered_count,hovered_subcount);
       println("LL :"+lowLimit);
       println("UL :"+ upperLimit);
    
       arduino.write(str((24 - hovered_count) % 24 + 1)); 
       arduino.write('/');
       arduino.write(str(lowLimit));
       arduino.write('/');
       arduino.write(str(upperLimit));     
   } 
     else {
      arduino.write(str(hovered_count)); // this makes the char get converted into a string form, which over serial, is readable as the same ASCII char back again by the arduino [HACK]
     }
     arduino.write('\n');
     println("Original " + hovered_object + "  " + hovered_count);
     // Update these values for FLAG 
     lastTest_Hobject = hovered_object;
     lastTest_Hcount = hovered_count;
     println("Check " + lastTest_Hobject + "  " + lastTest_Hcount);
    }

    // change colour of the object to "presently being done"
    switch (hovered_object) {
     case 'q':
      {
       previousMillis = millis(); // start the timer from now
       status = "quadrant";
       current_gross_test = hovered_count;
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
       previousMillis = millis(); // start the timer from now
       status = "hemi";
       current_gross_test = hovered_count;
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
      previousMillis = millis(); // start the timer from now
      status = "Meridian";
      meridian_state[hovered_count] = 3;
      current_sweep_meridian = hovered_count; // this needs to be stored in a seperate variable    
      break;

     case 'z':
      previousMillis = millis(); // start the timer from now
      
           
     if(lowLimit == upperLimit){
     section_state[hovered_count][hovered_subcount] = 1;
      status = "Not Selected";
     }else{
      section_state[hovered_count][hovered_subcount]= 3;
       status = "Section";
       lastTes_Hsubcount = hovered_subcount;
     // println(section_state[hovered_count][hovered_subcount]);
        current_sweep_meridian = hovered_count; // this needs to be stored in a seperate variable    
     }
      break;
  
     case 's':
      previousMillis = millis(); // start the timer from now
      status = "sweep";
      current_sweep_meridian = hovered_count; // this needs to be stored in a seperate variable    
      break;
    }
   }


   
   // Update the Objects to DONE state / back to normal if it is flagged
   void clearHemisQuads() {
    // checks if any hemi_state or quad_state values are == 3, and makes them into 2 (done)
    if (flagged_test == false) {
     for (int i = 0; i < 4; i++) { // 4 quadrants
      for (int j = 0; j < 2; j++) { // inner and outer
       if (abs(quad_state[i][j]) == 3) {
        quad_state[i][j] = 2;
       }
       if (abs(hemi_state[i][j]) == 3) {
        hemi_state[i][j] = 2;
       }
      }
     }

     for (int i = 0; i < 24; i++) { // 24 Meridians 
     
      if(daisy_On_Off == "ON"){
      if (abs(meridian_state[i]) == 3) {
       meridian_state[i] = 2;
      }
      }else {
          for(int k =0; k<3 ; k++){
            if (abs(section_state[i][k]) == 3) {
               section_state[i][k] = 2;
             }
          }
      }
     }


    } else { // checks if any hemi_state or quad_state values are == 3, and makes them into 1 (flagged)

     for (int i = 0; i < 4; i++) { // 4 quadrants
      for (int j = 0; j < 2; j++) { // inner and outer
       if (abs(quad_state[i][j]) == 3) {
        quad_state[i][j] = 1;
       }
       if (abs(hemi_state[i][j]) == 3) {
        hemi_state[i][j] = 1;
       }
      }
     }

     for (int i = 0; i < 24; i++) { // 24 Meridians 
     
     if(daisy_On_Off == "ON"){
      if (abs(meridian_state[i]) == 3) {
       meridian_state[i] = 1;
      }
     }
     else{
     for(int k =0; k<3 ; k++){
            if (abs(section_state[i][k]) == 3) {
               section_state[i][k] = 1;
             }
          }
    }

    }

    // Patterns does not have flagging 
    for (int i = 0; i < 3; i++) {
     if (pattern_state[i] == 2) {
      pattern_state[i] = 1;
     }
    }
    }
   }

   // Mouse released To Notify The Slider To Update The Time Intervals And Send It To Arduino 
   void mouseReleased() {}

   // KEYPRESS TO STOP A TEST WHICH IS ONGOING
   void keyPressed() {
    final int k = keyCode;

    if (k == 32) { // 32 is the ASCII code for the space key
     imageNumber = 1;
     SpaceKey_State = 1;
     flagged_test = false;
     println("Space Bar Pressed Now");
     arduino.write('x');
     arduino.write('\n');
     println("Request sent to Ardiuno @ :" + millis());
     int Init_Time = millis();
     int interval = 0;
     // Wait For The Serial Port  
     while (interval <= 10) { // Wait For The response From Ardiuno 
      interval = millis() - Init_Time;
     }
     println(Arduino_Response);
     if (Arduino_Response != 99) {
      println("Request repeated to Ardiuno");
      arduino.write('x');
      arduino.write('\n');
      // Wait For The Serial Port  
      while (interval <= 10) { // Wait For The response From Ardiuno 
       interval = millis() - Init_Time;
      }
     }
     if (Arduino_Response == 99) {
      SpaceKey_State = 0;
      Arduino_Response = 0;
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

    // UI UPDATE - MAKE QUADS/HEMIS PRESENTLY IN ACTIVE STATE TO 'DONE' STATE / BACK to NORMAL if flagged
    clearHemisQuads();
    //imageNumber = 1;// reset the image 
    // CALCULATE REACTION TIME AND PRINT IT TO SCREEN
    reaction_time = currentMillis - previousMillis;
    println("Reaction time is " + str(reaction_time) + "ms");

    // SAVE QUADS AND HEMIS TO TEXT FILE IN PROPER FORMAT
    if (status == "quadrant") {
     quadHemi_text.println();
     quadHemi_text.print(hour() + ":" + minute() + ":");
     int s = second();
     if (s < 10) {
      quadHemi_text.print("0" + str(s) + "\t"); // so that the text formatting is proper
     } else {
      quadHemi_text.print(str(s) + "\t\t");
     }
     switch (current_gross_test) {
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

     // Check if this is flagged to discard it


    }

    if (status == "hemi") {
     quadHemi_text.println();
     quadHemi_text.print(hour() + ":" + minute() + ":");
     int s = second();
     if (s < 10) {
      quadHemi_text.print("0" + str(s) + "\t"); // so that the text formatting is proper
     } else {
      quadHemi_text.print(str(s) + "\t\t");
     }
     switch (current_gross_test) {
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
      quadHemi_text.print("0" + str(s) + "\t"); // so that the text formatting is proper
     } else {
      quadHemi_text.print(str(s) + "\t\t");
     }

     quadHemi_text.print("Meridian " + "\t" + (current_sweep_meridian) * 15);
     quadHemi_text.print("\t" + str(reaction_time) + "\t");
     quadHemi_text.flush();

    }

 //For Section on a Merdidan
 if (status == "Section") {
   
    quadHemi_text.println();
     quadHemi_text.print(hour() + ":" + minute() + ":");
     int s = second();
     if (s < 10) {
      quadHemi_text.print("0" + str(s) + "\t"); // so that the text formatting is proper
     } else {
      quadHemi_text.print(str(s) + "\t\t");
     }

     quadHemi_text.print("Section " +(lastTes_Hsubcount )*30+" - "+(lastTes_Hsubcount + 1)*30+ "\t" + (current_sweep_meridian) * 15);
     quadHemi_text.print("\t" + str(reaction_time) + "\t");
     quadHemi_text.flush();
   
 }


    // REDRAW AND SAVE THE ISOPTER TO FILE  
    if (status == "sweep") {
     // redraw isopter image to file

     // write this to the isopter text file
     isopter_text.println();
     isopter_text.print(hour() + ":" + minute() + ":");
     int s = second();
     if (s < 10) {
      isopter_text.print("0" + s + "\t"); // so that the text formatting is proper
     } else {
      isopter_text.print(s + "\t");
     }

     println("Stopped Meridian :" + current_sweep_meridian);
     isopter_text.print((current_sweep_meridian) * 15 + "\t\t");
     //CKR
     if (abs(meridians[current_sweep_meridian]) > 0 && abs(meridians[current_sweep_meridian]) <= numberOfLEDs[(24 - current_sweep_meridian) % 24]) {
      if (abs(meridians[current_sweep_meridian]) > 3) {
       isopter_text.print(str(angleData[(24 - current_sweep_meridian) % 24][numberOfLEDs[(24 - current_sweep_meridian) % 24] - abs(meridians[current_sweep_meridian])])+ "(" + meridians[current_sweep_meridian]+ ")" + "\t");
      } else if (abs(meridians[current_sweep_meridian]) <= 3) {
       isopter_text.print(str(angleData[(24 - current_sweep_meridian) % 24][numberOfLEDs[(24 - current_sweep_meridian) % 24] - abs(meridians[current_sweep_meridian])]) + "(" + meridians[current_sweep_meridian] + ")" + "\t");
      }else {
        isopter_text.print("No Response" + "\t");}
     }
     //CKR
     isopter_text.print(str(reaction_time) + "\t\t\t");
     isopter_text.flush();

     // Check if the the test is flagged or not to discard the test on GUI 
     if (flagged_test == true) {
      meridians[current_sweep_meridian] = 28;
     }
    }

    // UPDATE STATUS VARIABLES
    last_tested = status; // last tested thing becomes the previuos value of status
    status = "Test stopped. idle";
    startRecording = false; // go back to low quality recording
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
   // println("Recieved from Arduino : " + inString + inString.length());
    // Wait For The Response When Space Bar Is Pressed
   
     if (inString != null && inString.length() <= 4) {
     serialEventFlag = true;
     
     // string length four because it would be a 2-digit or 1-digit number with a \r\n at the end
     int temp_Val = Integer.parseInt(inString.substring(0, inString.length() - 2));
     if (temp_Val == 99 && SpaceKey_State == 1) { // Response For Clear All Command
      // Recieve_Time = millis ();
      //  Delay_Store [z] = Recieve_Time - Sent_Time;
      //  z= z+1;
      Arduino_Response = temp_Val;
      SpaceKey_State = 0;
      //println("Ardiuno Value Populated\n");
     } else if (temp_Val != 99 && SpaceKey_State == 0) { // Data For The LED No. In Sweep
      if (previousTime == 0) {
       println("Serial Port Value Recieved from Arduino : " + inString + " @ " + previousTime + " ms");
       previousTime = millis();
      } else {
       currentTime = millis();
       println("Serial Port Value Recieved from Arduino : " + inString + " in " + (currentTime - previousTime) + " ms");
       previousTime = currentTime;
      }
      meridians[current_sweep_meridian] = Integer.parseInt(inString.substring(0, inString.length() - 2));
     }
    }
   }


   void CAPTURE() {
     if(frameCount > 1){
     if(patient_name.length()!=0 ) {
    cam.save(workingDirectory + "/" + base_folder + "/" + patient_name + "_scale.jpg");
     }  
     }
   }



   void sendTimeIntervals(int chosenStrip) {

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

    println("Sending data");
    //Sending the Object details to arduino to recognise the action to be performed 
    arduino.write('t');
    arduino.write(',');
    println("bottomMostAngle[chosenStrip - 1] " + bottomMostAngle[chosenStrip - 1] + " Sweep value " + cp5.getController("SWEEP").getValue() + " Quotient " + bottomMostAngle[chosenStrip - 1] / cp5.getController("SWEEP").getValue());
    int valueToBeSent = round(((bottomMostAngle[chosenStrip - 1] / cp5.getController("SWEEP").getValue()) / numberOfLEDs[chosenStrip - 1]) * 1000);
    arduino.write(str(valueToBeSent));
    println(valueToBeSent);
    arduino.write('\n');
   }


   void PATTERNONE() {
     
     if(frameCount >1){
    arduino.write('p');
    arduino.write(',');
    arduino.write('1');
    arduino.write('\n');

    pattern_state[0] = 2;
     }
   }


   void PATTERNTWO() {
     
        if(frameCount >1){
    arduino.write('p');
    arduino.write(',');
    arduino.write('2');
    arduino.write('\n');

    pattern_state[1] = 2;
        }
        
   }


   void PATTERNTHREE() {
     
        if(frameCount >1){
    arduino.write('p');
    arduino.write(',');
    arduino.write('3');
    arduino.write('\n');

    pattern_state[2] = 2;
        }
   }


   void FIXATION() {
    /*
     * Function to change brightness of fixation LED in arduino.
     * Arduino uses PWM to change brightness.
     * It is sent in the form (l, fixationBrightness).
     * Triggered by Slider.PRESSED
     */
    int fixationBrightness = int(cp5.getController("FIXATION").getValue());
    println("Brtnss : " + fixationBrightness);
    arduino.write('l');
    arduino.write(',');
    arduino.write(str(fixationBrightness));
    arduino.write('\n');
   }
  
   void DAISY(int a){
   arduino.write('d');
   arduino.write(',');
   if (a == 1){
   arduino.write('1');
   daisy_On_Off = "ON";
   
   }else {
     daisy_On_Off = "OFF";
   arduino.write('0');
   
   }
   arduino.write('\n');
   }
   
   void LED_COUPLET(int a){
   arduino.write('c');
   arduino.write(',');
   if (a == 1){
   arduino.write('1');
   ledCouplet = "ON";
   
   }else {
     ledCouplet = "OFF";
   arduino.write('0');
   
   }
   arduino.write('\n');
   }
   
   // THE BANG FUNCTIONS
   void FINISH() {
    // Make Sure everything is reset in the device.
    arduino.write('x');
    arduino.write('\n');
    println("finished everything");
    finalMillis = currentMillis;

    float final_fps = 1000 / ((finalMillis - initialMillis) / frameCount);
    print("The final fps is : ");
    println(final_fps);

    PImage screenIsopter = get(760, 30, 400, 360); // get that particular section of the screen where the isopter lies. 
    screenIsopter.save(workingDirectory + "/" + base_folder + "/Reference_GUI_Isopter.jpg"); // save it to a file in the same folder


    f = new PFrame(width, height);
    f.setTitle("second window");

    // stop drawing to the window!!
    noLoop();

    // stop the video recording, open up a popup asking for any final notes before closing

    JTextArea textArea = new JTextArea(10, 5);

    // Stop the desktop recording 
    try {
     Process p = Runtime.getRuntime().exec("C:\\Windows\\System32\\cmd.exe /c start taskkill /IM ffmpeg.exe /f ");
     // StreamGobbler.StreamGobblerLOGProcess(p);
    } catch (IOException e) {
     e.printStackTrace();
    }


    // stop recording the sound..
    sound_recording.endRecord();
    sound_recording.save();
    // START PROCESSING THE VIDEO AND THEN QUIT THE PROGRAM
    delay(1000);
    println("Stitching Initiated to : " + base_folder);
    //Stitch the video and Audio 

    try {
     String[] ffmpeg_command = {
      "C:\\Windows\\System32\\cmd.exe",
      "/c",
      "start",
      "ffmpeg",
      "-i",
      workingDirectory + "/" + base_folder + "/video.mpg",
      "-i",
      workingDirectory + "/" + base_folder + "/recording.wav",
      "-c:v",
      "copy",
      "-c:a",
      "copy",
      workingDirectory + "/" + base_folder + "/FinalVideo.avi"
     };
     ProcessBuilder p = new ProcessBuilder(ffmpeg_command);
     Process pr = p.start();
    } catch (IOException e) {
     e.printStackTrace();
     exit();
    }
    // send a popup message giving a message to the user

    // ONCE THIS IS DONE, DELETE THE 'FRAME' DIRECTORY
    // TODO: DO THIS IS A BAT FILE OR THROUGH THE CMD - OTHERWISE YOU'LL DELETE THEM BEFORE THEY'RE USED
    // THEN EXIT THE PROGRAM ONCE DONE
    println("everything sucessful, closing");
    exit();
   }

   void PATIENT_INFO() {
     //Thread, because the main process shouldn't pause
    Thread t = new Thread(new Runnable() {
     public void run() {
      forPinfo();
     }
    });
    t.start();
   }

   void forPinfo() {
     //Just displays the pateint info as a Dialog
     //Similar to that of patient entry 
    JPanel panel = new JPanel();
    panel.setLayout(new GridLayout(4, 1));
    JLabel ard = new JLabel("Arduino");
    JLabel camc = new JLabel("Camera");
    //198-512.png

    JPanel hd = new JPanel();
    hd.setLayout(null);

    Label cap = new Label("Patients Info", Label.CENTER);
    cap.setFont(new Font("Serif", Font.BOLD, 20));
    cap.setForeground(Color.BLACK);

    cap.setLocation(150, 10);
    cap.setSize(150, 60);
    String path1 = workingDirectory + "r.png";
    String path2 = workingDirectory + "g.png";
    ImageIcon red, grn;
    if (arduino == null) {
     red = new ImageIcon(path1);
    } else {
     red = new ImageIcon(path2);
    }

    JLabel red1 = new JLabel();
    red1.setIcon(red);
    red1.setLocation(410, 45);
    red1.setSize(10, 10);
    if (cam == null) {
     grn = new ImageIcon(path1);
    } else {
     grn = new ImageIcon(path2);
    }

    JLabel grn1 = new JLabel(grn);
    grn1.setLocation(410, 65);
    grn1.setSize(10, 10);
    hd.add(red1);
    hd.add(grn1);
    hd.add(cap);
    ard.setLocation(350, 40);
    ard.setSize(60, 20);
    camc.setLocation(350, 60);
    camc.setSize(60, 20);
    hd.add(ard);
    hd.add(camc);

    panel.add(hd);

    JLabel lbl1 = new JLabel("Patient Name");
    JLabel lbl2 = new JLabel("MR Number");
    JLabel lbl3 = new JLabel("Date of Birth");
    JLabel lbl4 = new JLabel("Milestone details");
    JLabel lbl5 = new JLabel("Occipital Distance");

    //Label instead of TextField
    JLabel pname = new JLabel(patient_name);
    JLabel pMR = new JLabel(patient_MR);
    JLabel pdob = new JLabel(patient_dob);
    JLabel pmilestone_details = new JLabel(patient_milestone_details);
    JLabel potc = new JLabel(patient_OTC);

    JPanel labels = new JPanel();
    labels.setLayout(new GridLayout(5, 2));
    labels.add(lbl1);
    labels.add(pname);
    labels.add(lbl2);
    labels.add(pMR);
    labels.add(lbl3);
    labels.add(pdob);
    labels.add(lbl4);
    labels.add(pmilestone_details);
    labels.add(lbl5);
    labels.add(potc);

    JPanel instr = new JPanel(new GridLayout(0, 1));
    Label inscap = new Label("Instructions", Label.CENTER);
    inscap.setFont(new Font("Serif", Font.BOLD, 15));
    inscap.setForeground(Color.BLACK);
    instr.add(inscap);
    JLabel l1 = new JLabel("1. Parents should be given informed consent for signing.");
    JLabel l2 = new JLabel("2. Only the parents and 3 (maximum) examiners would be allowed to stay inside the room during the testing.");
    JLabel l3 = new JLabel("3. Try re-connecting the arduino before you run the code ");
    instr.add(l1);
    instr.add(l2);
    instr.add(l3);
    panel.add(labels);
    panel.add(instr);
    int result = JOptionPane.showConfirmDialog(
     this, // use your JFrame here
     panel,
     "Current Patient's Information",
     JOptionPane.DEFAULT_OPTION,
     JOptionPane.PLAIN_MESSAGE);
   }

   void ADD_NOTE() {
     //Thread, beacuse main process shouldn't pause
    Thread t = new Thread(new Runnable() {
     public void run() {
      forAnote();
     }
    });
    t.start();
   }

   void forAnote() {
     //Makes it possible to add special notes with time stamp, specific to the patient, in patient_note.txt
    //If note is not present, text file is not created 
    JPanel panel = new JPanel();
    panel.setLayout(new GridLayout(2, 1));
    JLabel lbl1 = new JLabel("Add Note");


    final JTextField pnote = new JTextField(50);
    JPanel labels = new JPanel();
    labels.setLayout(new GridLayout(2, 1));
    labels.add(lbl1);
    labels.add(pnote);

    panel.add(labels);
    int result = JOptionPane.showConfirmDialog(
     this, // use your JFrame here
     panel,
     "Special Note for " + patient_name,
     JOptionPane.OK_CANCEL_OPTION,
     JOptionPane.PLAIN_MESSAGE);

    if (result == JOptionPane.OK_OPTION) {
      //Add only if not empty
     if (pnote.getText().length() != 0) {
       //This if condition works only for the first time
      if (patient_note.length() == 0) {
       note_text = this.createWriter(base_folder + "/" + patient_name + "_note.txt");
       note_text.println("Note for patient " + patient_name);
       note_text.println("MR No : " + patient_MR);
       note_text.println("Milestone Details : " + patient_milestone_details);
       note_text.println("Note - ");
      }
      //Appends everytime
      note_text.println();
      note_text.println("Timestamp : " + hour() + ":" + minute() + ":" + second());
      patient_note = pnote.getText();
      note_text.println("" + patient_note);
      note_text.println("________________\n");
      note_text.flush();
     }
    }
   }

   void FLAG() {
    //First clear all the meridians 
    arduino.write('x');
    arduino.write('\n');
    println("All Cleared");

    if (flagged_test == false) {
     if (status == "quadrant" || status == "hemi" || status == "Meridian" || status == "Section") {
      flagged_test = true;
      Stop();
     } else if (status == "sweep") {
      flagged_test = true;
      Stop();
     } else {
      flagged_test = true;
      println(lastTest_Hobject + "  " + lastTest_Hcount);
      // Reset the state to normal as it is flagged 
      switch (lastTest_Hobject) {
       case 'q':
        {
         previousMillis = millis(); // start the timer from now
         status = "Flagged Quad";
         current_gross_test = lastTest_Hcount;
         quadHemi_text.print("flagged");
         quadHemi_text.flush();
         if (lastTest_Hcount <= 4) {
          quad_state[abs(4 - lastTest_Hcount)][0] = 1;
          break;
         } else {
          quad_state[abs(8 - lastTest_Hcount)][1] = 1;
          break;
         }

        }
       case 'h':
        {
         previousMillis = millis(); // start the timer from now
         status = "Flagged Hemi";
         current_gross_test = lastTest_Hcount;
         quadHemi_text.print("flagged");
         quadHemi_text.flush();
         if (lastTest_Hcount < 2) {
          hemi_state[hemi_hover_code[lastTest_Hcount][0]][0] = 1;
          hemi_state[hemi_hover_code[lastTest_Hcount][1]][0] = 1;
          break;
         } else {
          hemi_state[hemi_hover_code[lastTest_Hcount - 2][0]][1] = 1;
          hemi_state[hemi_hover_code[lastTest_Hcount - 2][1]][1] = 1;
          break;
         }

        }
       case 'm':
        previousMillis = millis(); // start the timer from now
        status = "Flagged Meridian";
        meridian_state[lastTest_Hcount] = 1;
        quadHemi_text.print("flagged");
        quadHemi_text.flush();
        break;
        
        case 'z':
        previousMillis = millis(); // start the timer from now
        status = "Flagged Section";
        section_state[lastTest_Hcount][lastTes_Hsubcount] = 1;
        quadHemi_text.print("flagged");
        quadHemi_text.flush();
        break;

       case 's':
        previousMillis = millis(); // start the timer from now
        status = "Flagged sweep";
        meridians[lastTest_Hcount] = 28; // this needs to be stored in a seperate variable    
        isopter_text.print("flagged");
        isopter_text.flush();
        break;

      }
      flagged_test = false;

      //Reset the values preventing from re-functioning
      lastTest_Hobject = 'c';
      lastTest_Hcount = 0;
     }
    }
    //Call the stop function so that We can Update the files

    println("Stopped");

    // just update hte flag variable to "flagged"
    if (flagged_test == true) {
     if (last_tested == "quadrant" || last_tested == "hemi" || last_tested == "Meridian" || last_tested == "Section") {
      status = "Flagged " + last_tested;
      quadHemi_text.print("flagged");
      quadHemi_text.flush();
      flagged_test = false;
     } else if (last_tested == "sweep") {
      isopter_text.print("flagged");
      status = "Flagged " + last_tested;
      isopter_text.flush();
      flagged_test = false;
     }
    }
    println("Flagged Completely");
   }



   //Find the Upper & Lower Limits of LED Numbders 
   void getTheLimits(int Hcount,int Hscount){
          // Get the Array elements
    
     int lenOfArray = 30 ;
     //lenOfArray = angleData[(24 - Hcount) % 24].length;
     // Switch to the appropriate Section
     switch (Hscount){
     case 0:{
     lowLimit = 0;
     upperLimit = 0;
     for (int i = 0; i < lenOfArray -1;i++){
      println(i);
      //Check for Low Limit 
      if(angleData[(24 - Hcount) % 24][i] >  0 && angleData[(24 - Hcount) % 24][i+1] == 0) {
      lowLimit = i;
      break;
      }else if(angleData[(24 - Hcount) % 24][i] >= 30 && angleData[(24 - Hcount) % 24][i+1]<30){
      upperLimit = i+1;   
      }
     }
     break;
     }
   
     case 1:{
      lowLimit = 0;
     upperLimit = 0;
     for (int i = 0; i < lenOfArray -1;i++){
      
      //Check for Low Limit 
      if(angleData[(24 - Hcount) % 24][i+1] < 30 && angleData[(24 - Hcount) % 24][i]>=30) {
      lowLimit = i;
      break;
      }else if(angleData[(24 - Hcount) % 24][i] >= 60 && angleData[(24 - Hcount) % 24][i+1]<60){
      upperLimit = i+1;
      }
      }
     
     break;
     }
     case 2:{
       
     lowLimit = 0;
     upperLimit = 0;
     for (int i = 0; i < lenOfArray -1;i++){
      
      //Check for Low Limit 
      if(angleData[(24 - Hcount) % 24][i+1] < 60 && angleData[(24 - Hcount) % 24][i]>=60) {
      lowLimit = i;
      break;
      } else if(angleData[(24 - Hcount) % 24][i] >= 90 && angleData[(24 - Hcount) % 24][i+1]<90){
      upperLimit = i+1;
      }
     }
     break;
     }
     
     }
          //update the values to the real world numbering 
     lowLimit = numberOfLEDs[(24 - Hcount) % 24]  - lowLimit;
     upperLimit =numberOfLEDs[(24 - Hcount) % 24] - upperLimit;
     
     //Reset The state of the section if both the lower limit and Upper Limit are equal

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
    } catch (Exception e) {}
    try {
     //Opens The Workbook
     wb = WorkbookFactory.create(inp);
    } catch (Exception e) {}
    // Opens The First Sheet 
    Sheet sheet = wb.getSheetAt(0);
    int sizeX = sheet.getLastRowNum(); // Get The Number of rows in the sheet 

    int sizeY = 5; // 5 columns : Meridian <-> LED No. <-> X_value <-> Y_value <-> Z_value
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
    for (int rowNumber = 1; rowNumber <= numberOfRows; rowNumber++) {
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

     float zdash = z - (7 + occipitalDistance);
     boolean flag = (zdash < 0) ? true : false;
     zdash = Math.abs(zdash);
     float finalAngleValue = (float) Math.toDegrees(Math.atan(zdash / ((float) Math.sqrt(x * x + y * y))));
     if (flag) {
      finalAngleValue += 90;
     } else {
      finalAngleValue = 90 - finalAngleValue;
     }
     if (pixelNumber == 1) {
      bottomMostAngle[meridianNumber - 1] = finalAngleValue;
      println((meridianNumber - 1) + " " + bottomMostAngle[meridianNumber - 1]);
     }
     data[meridianNumber - 1][pixelNumber - 1] = finalAngleValue;
    }


    //println("Data input done");
    for (int i = 0; i < 30; i++) {
     print(i + " ");
     for (int j = 0; j < 30; j++) {
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
