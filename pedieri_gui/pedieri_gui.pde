/***************************************
THIS IS THE LATEST VERSION AS OF 24-MAR-2016
  Project Name : Pediatric Perimeter v3.x
  Author : Dhruv Joshi

  Modifications made:
    - Video capture speed is now much faster (30 fps) though there are dropped frames
    - Removed junk code
    
  Libraries used (Processing v2.0):
    - controlp5 v2.0.4 https://code.google.com/p/controlp5/downloads/detail?name=controlP5-2.0.4.zip&can=2&q=
    - GSVideo v1.0.0 http://gsvideo.sourceforge.net/#download
    
*/
import processing.serial.*;
import codeanticode.gsvideo.*;  // Importing GS Video Library 
import controlP5.*;             // Import Control P5 Library

Serial arduino;                 // create serial object
int kk = 0;

PrintWriter output;             // The File Writing Object
byte m = 0;                     // This byte is used to send a slider value to the arduino (brightness choice)
int me = -1;             // "me" tracks the meridian number
String azimuth;                // converts "me" to the azimuth, which is used for preparing the proper isopter
boolean detailsEntered = false, videoRecording = false,timeStampDone=true;    // These booleans follow whether information's been entered and when to start the video

// These variables relate to hte ellipses that indicate current LED position.
int i = 25, xi, yi;             // Store position of the LED, but not for long.
float theta;                    // This is the azimuthal angle on the perimeter "polar diagram"
int[] perimeter = 
{ -1, -1, -1, -1,   
  -1, -1, -1, -1,   
  -1, -1, -1, -1,
  -1, -1, -1, -1,
  -1, -1, -1, -1,
  -1, -1, -1, -1};           // THe most imporftant variable in this whole project
// The perimeter shall store the radial positions (discrete) of the LEDs presently, which wil come from feedback from the arduino as it sweeps. The cardinal order of the elements indicates the azimuthal angle (discrete). There are 24 elements.
int[] hemquad = {0, 0, 0, 0, 0, 0};  // this stores the alpha value of the hemisphere and quadrants. When one is clicked, it just puts that damn value.
int sliderValue = 100;
// controlp5 related objects
ControlP5 cp5;                  // Control P5 Object Creation     
ControlTimer c;
Textlabel t;
DropdownList d1;                // Dropdown List creation

String folderName = "";           // Will store the folder name into which shit will be saved

// te following bariables shall hold the values that were entered about the patient
String textValue = "";
String textFile = "";           
String textName = "";
String textAge = "";
String textSex = "";
String textVideo="Please Fill the name and click on SAVE.";
String textDescription = "";

// These will hold the timer variables, for teh realtime clock in the video etc
String textTimer="";
String textDate="";
String textTime="";
String textMe="";

// button colour map variables...
PImage buttonm;       // image of the buttons (visible)
PImage buttoncolmap;  // colormap of the buttons (hidden)

// movie/video related variables
GSCapture cam;        // GS Video Capture Object
GSMovieMaker mm;      // GS Video Movie Maker Object  
int droppedFrames = 0, collectedFrames = 0;

int fps = 30;          // The Number of Frames per second Declaration
int ang = 0;
//Declaration of the names for the buttons and their parameters 
String[] buttonstring= {
  "37", "35", "33", "31", 
  "29", "27", "25", "23", 
  "52", "50", "48", "46", 
  "44", "42", "40", "38", 
  "36", "34", "32", "30", 
  "28", "26", "24", "22", 
  "l", "r", 
  "3", "2", "1", "4"
}; //the names of the buttons

color[] buttoncolor= {
  0xFF7D8075, 0xFF6F686F, 0xFF7E0516, 0xFFB97A57, 
  /**/ 0xFFF0202E /**/, 0xFFFEAEC7, 0xFFF78525, /**/ 0xFFFFC10A /**/,   // changed to reflect what processing sees
  0xFFCC00FF, 0xFFEFE3AF, 0xFF23B14D, 0xFFB5E51D, 
  /**/ 0xFF00A3E8 /**/, 0xFF9AD9EA, 0xFF3F47CE, 0xFF7092BF,   // changed to reflect what processing sees
  0xFFA349A3, 0xFFC7BFE6, 0xFF417B7D, /**/ 0xFFFF0080 /**/,   // changed to reflect what processing is seeing
  0xFF838ADB, 0xFFDA9D80, 0xFF86AADE, 0xFFA3D981,
  0xFF40003F, 0xFFA4A351,
  0xFF000079, 0xFF870C3A, 0xFF55761F, 0xFF457894
  
}; //the colors of the buttons
String textfield=""; // Text field String for display

void setup() {
  // going to initiate serial connection...
  if (Serial.list().length != 0) {
    println("Arduino MEGA connected succesfully.");
    String port = Serial.list()[0];
    // then we open up the port.. 9600 bauds
    arduino = new Serial(this, port, 115200);
    arduino.buffer(1);
  } else {
    println("Arduino not connected or detected, please replug"); 
    // exit();
  }
  
  size(1300, 600);  //The Size of the Panel 
  
   
  cp5 = new ControlP5(this);
  t = new Textlabel(cp5,"--",840,20);
  buttonm = loadImage("buttonm.png");//Front End
  buttoncolmap=loadImage("buttoncolmap.png"); //Backend
  c = new ControlTimer();
  c.setSpeedOfTime(1);
  cp5.setColorLabel(0xff000000);
  d1 = cp5.addDropdownList("Sex") //The DropDown List With name Se
    .setPosition(20, 450)
      ;
  customize(d1); // customize the first list
  
  cp5.addTextfield("Name") //Text Field Name and the Specifications
    .setPosition(20, 100)
      .setSize(200, 30)
        //.setFont(font)
        .setFocus(true)
          .setFont(createFont("arial", 16))
            .setAutoClear(false)
              //.setColorCursor(0)
              ;
  // the next one is the serial no of the patient.. added 30-10-2014 on Sourav's suggestion.
  // changed on 26-feb-2015 to EMR No.
  cp5.addTextfield("EMR No")
    .setPosition(20, 250)
      .setSize(200, 30)
          .setFont(createFont("arial", 16))
            .setAutoClear(false)
              ;

  cp5.addTextfield("Age") //Text Field Age and the Specifications
    .setPosition(20, 170)
      .setSize(200, 30)
        .setFont(createFont("arial", 16))
          .setAutoClear(false)
              ;

  cp5.addTextfield("Description") //Text Field Description and the Specifications
    .setPosition(20, 340)
      .setSize(200, 30)
        .setFont(createFont("arial", 16))
          .setAutoClear(false)
           ;

  cp5.addBang("clear") //The Bang Clear and the Specifications
    .setPosition(110, 20)
      .setSize(80, 40)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          ;  
 
  cp5.addBang("Save")  //The Bang Save and the Specifications
    .setPosition(20, 20)
      .setSize(80, 40)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
          ;    
  cp5.addBang("Stop")
    .setPosition(120, 540)
      .setSize(80, 40)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
          //.setColor(0)
            ;    
           cp5.addSlider("sliderValue")
     .setPosition(500,550)
     .setSize(220,20)
     .setRange(0,255)
     .setNumberOfTickMarks(10)
     ;
     
  // the fixation button...
  cp5.addBang("Fixation") //The Bang Fixation and the Specifications
    .setPosition(1075, 545)
      .setSize(40, 40)
        .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          ; 
     
  frameRate(fps);  //The Frames per second of the Video
  String[] cameras = GSCapture.list(); //The avaliable Cameras
     
  // We check if the right camera is plugged in, and if so only then do we proceed, otherwise we exit the program.
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    //exit();
  } else {
    println("Checking if correct camera has been plugged in ...");
    
    for (int i = 0; i < cameras.length; i++) {  //Listing the avalibale Cameras
      println(cameras[i]);
      
      println(cameras[i].length());
      println(cameras[i].substring(3,6));
      if (cameras[i].length() == 13 && cameras[i].substring(3,6).equals("USB")) {
        print("...success!");
        cam = new GSCapture(this, 640, 480, cameras[i]);      // Camera object will capture in 640x480 resolution
        cam.start();      // shall start acquiring video feed from the camera
        break; 
      }
      println("...NO. Please check the camera connected!"); 
      exit();
    }  
  }
}

void draw() {
  // println(frameRate);
  // The shit that has to be done each time...
  background(buttonm);//BackgEnd
  fill(0);
  textFont(createFont("arial", 16), 16);
  text(textVideo, 320, 530); 
  text(textValue, 320, 510);
  fill(0);
  // text(textfield, 1050, 440); 
  // text(textMe, 1110, 440);
  text(textTimer, 700, 530);
    
  // The following is the red ellipse being printed to indicate which LED is on
  for (int p = 0; p < 24; p++) {
    if (perimeter[p] > 1) {
      fill(255,0,0);  // set the color to RED
      // We will calculate the x,y position that the particular LED is supposed to be at...
      ang = int(((p + 1)*15));    // we will be re-drawing each time for all meridians. This is due to the refresh-methodology on which processing operates.
      float multipler = 25 + (perimeter[p] - 2)*22 ;
      int x = int(1096.00 + cos(radians(ang))* multipler);    
      int y = int(201.00  - sin(radians(ang))* multipler);
      ellipse(x, y, 10, 10);                                      // LED PRINT ON THE PERIMETER
    }
  }
  // drawing a rectangle on top of the quadrants which are done
  stroke(195, 195, 195, 255);    // 0 < alpha < 255
  fill(195, 195, 195, hemquad[2]);
  rect(923,452,66,62);
  fill(195, 195, 195, hemquad[1]);
  rect(991,452,66,62);
  fill(195, 195, 195, hemquad[3]);
  rect(923,516,66,62);
  fill(195, 195, 195, hemquad[0]);
  rect(991,516,66,62);
  
  // drawing a rectangle on top of the hemispheres which are done..
  stroke(195, 195, 195, 255);
  fill(195, 195, 195, hemquad[4]);
  rect(1123,450,66,125);
  fill(195, 195, 195, hemquad[5]);
  rect(1192,450,66,125);
  
  textName = cp5.get(Textfield.class, "Name").getText();
  textAge = cp5.get(Textfield.class, "Age").getText();
  textDescription = cp5.get(Textfield.class, "Description").getText();

 
  // Here we continuously update the timedate on the screen...
  t.setValue(day()+ "-" + month() + "-" + year() + "\n" + hour() + ":" + minute() + ":" + second());
  t.draw(this);
  t.setPosition(20,480);
  t.setColorValue(0x000000);
  t.setFont(createFont("Arial",14));
 
  if(kk >= 1){
    // c.reset();
    textTimer = c.toString() + " : " + str(c.millis());
  }
  
  if(detailsEntered == true) {    // Has the doctor entered the details which are required?
        
    // start showing the camera feed...
    if (cam.available() == true) {
      collectedFrames = collectedFrames + 1;
      cam.read();    // read only if available, otherwise interpolate with previous frame
    } else {
      // that's a dropped frame...
      droppedFrames = droppedFrames + 1;
    }
    image(cam, 245, 0);    // display the image
      
    PImage videoSection = get(245, 0, 1055, 600);    // crop our section of interest of the page
    videoSection.loadPixels();    // Loads the pixel data for the *CROPPED* display window into the pixels[] array. This function must always be called before reading from or writing to pixels[].
    
    if (videoRecording == true) {
      mm.addFrame(videoSection.pixels);  // Array containing the values for all the pixels in the display window.
    } 
  }
  // println("collected: " + collectedFrames + " ,dropped: " + droppedFrames);
}

public void clear() {    //Bang Function for the Button Clear
  // This function deals with what happens when you click on "CLEAR"
  cp5.get(Textfield.class, "Name").clear();
  cp5.get(Textfield.class, "Age").clear();
  //cp5.get(Textfield.class,"Sex").clear();
  cp5.get(Textfield.class, "Description").clear();
}


public void Save() {//Bang Function for the Button Save
  // Clicking SAVE
  if (textName.isEmpty()){//Do not Create a file if there is no name assigned to the File
    textValue="No File Created" ;
    textVideo="Please Enter the File Name to see the Video";
    detailsEntered = false;
  } else {
    // First, create the folder name into which everything will be stored (including the subsequent videos)...
    folderName = year()+"/"+month()+"/"+textName;
    
    //Writing the input texts to a .txt file 
    output = createWriter(folderName + "/" + textName+".txt"); 
    output.print("Date: " + day() + "/" + month() + "/" + year() + "\t\t\t");
    output.println("Time: " + hour() + ":" + minute() +":" + second() + "\n\n");
    output.println("Patient Name :" + textName);
    output.println("Patient Age :" + textAge);
    output.println("Patient Sex :" + textSex);
    output.println("Patient Description :" + textDescription);
    output.println("\n\r\n\r\n\r" + "##############################" + "\n\r\n\r" + "PATIENT RESULTS" + "\n\r\n\r" + "##############################");
    output.println("TEST\t\t\tSTART\t\t\tStop\t\t\tDuration\t\tAngle Stopped");
    output.flush(); // Writes the remaining data to the file
    // output.close(); // File written, all's well
    
    // notify the user..
    textValue = "File Created with "+textName+".txt  as the Name";
    textVideo = "Thank you. Video is ON. Please click on a test..";
    detailsEntered = true;      // Details have been entered. Awesome. Show the video.
    
    mm = new GSMovieMaker(this, width-245, height, folderName + "/" + year() + "" + month() + "" + day() + "_" + textName + ".ogg", GSMovieMaker.THEORA, GSMovieMaker.MEDIUM, fps); // the Mavie Maker Object
    mm.setQueueSize(0, 60);
    videoRecording = true;        // start recording the video.
    // then we start the video..
    mm.start();               // Starting the Pictures
  }
}

public void Stop(){
  // this function stops the video taking and also stops the present operation on the arduino.
  // mm.finish(); // Completes the Video at this Instant
  int milliseconds_passed = c.millis();    // the milliseconds reading of the timer
  textVideo = "Test has stopped. All lights OFF.";
  kk = 0;
  c.reset();
  arduino.write('x');
  arduino.write('\n');
  if(timeStampDone == false) {
    output.print("\t\t" + hour() + ":" + minute() +":" + second()); 
    output.print("\t\t" + textTimer + " : " + milliseconds_passed + "\t");
    // write the presently completed meridian to the file...
    if (me > 1) {  // checking if it's a meridian or not...
      output.print( "\t\t" + (perimeter[me] - 1)*10);
    } else {  // the case where it's not a meridian
      output.print( "\t\t-");
    }
    output.println();
    output.flush();
    timeStampDone = true;
  }
  
  // overwrite the isopter image to reflect what's currently been done...
  PImage isopter = get(890, 0, 410, 380);     // get that particular section of the screen where the isopter lies.
  isopter.save(folderName + "/isopter.jpg");  // save it to a file in the same folder
}

void mousePressed() {
  //println(mouseX+" "+mouseY);
  // This part presumable deals with the LED indication being printed on the screen...
  // When one clicks on the perimeter sweep diagram, of course...
  float r = sqrt(sq(mouseX - 1096) + sq(mouseY - 200));    // radial distance from the center of the perimeter and the mouse 
  // println(r);
  
  if (r <= 207 && r > 25) {  // If the mouse hath clicked in the general sweep region.. remember we're just trying to find theta here
    // println("chose a semi-meridian");
    
    // The next 3 lines simply find the azimuthal angle
    theta = (float(mouseY) - 200)/ (float(mouseX) - 1096);
    theta = atan(theta);
    theta = degrees(theta);
    
    // Then we choose the sign of theta based on standard polar coordinates convention
    if(mouseX>1096  && mouseY<200)
      theta= -1*theta;
    else if(mouseX<1096)// && mouseY<200)
      theta = 180 - theta; 
    else if(mouseX>1096 && mouseY>200)
      theta = 360 - theta;
    
    // What's next? discretization of theta into a variable that represents which LED is on..  
    float a = ((theta  - 7.5)/15);
    
    if (a < 0) {
      a = 23;                    // The single meridian which is at the end is numbered 23
    }
    
     
    me = int(a);    // The variable "me" tracks the meridian number, by discretizing "a"
    azimuth = str(((me + 1)*15)%360);    // calculate the azimuth angle which has actually been mentioned from the 'me' variable
    println(azimuth);
    // Now we know whch meridian's been selected.
    // println("Meridian" + me);
    textMe = ("Angle: " + theta + " degrees");    // print to the textfield indicating which meridian was selected
    // ang = int(((me+1)*15) /*+ 7.5*/);    // The 7.5 degrees has been removed so that the red dot will come in the center of the meridian, which is more representative of reality
        
  } else textMe = "None";
}
  
  
void mouseReleased() {
  // The Mouse event the tests for the Buttons for the Sectors
  color testcolor = buttoncolmap.get(mouseX, mouseY); // get the color in the hidden image 
  // println(hex(testcolor, 6));    /******** USE THIS TO DEBUG WHAT COLOUR PROCESSING IS ACTUALLY SEEING!****/
      
  for (i=0; i<buttonstring.length; ++i) { //check the color and copy the name of the button
    if (testcolor == buttoncolor[i]) {
      textfield = buttonstring[i];
      // println(buttonstring[i]);
      
      if (detailsEntered == true) {
        m = byte(sliderValue);
        textVideo="The test has Started"; 
      } else {
        textVideo="Please Enter the Patient name";
      }
      
      // we will check the different cases for i...
      if (int(buttonstring[i]) >= 22) {  
        // the following resets the timer..
        kk++;
        if (kk == 1) {
          c.reset();
        }
        
        // println("sweep");
        // this is the case of the sweeps..

        arduino.write('s');
        arduino.write(',');
        arduino.write(buttonstring[i]);
        arduino.write('.');
        arduino.write(m);
        arduino.write('\n');
        textValue = "kinetic perimetry, Meridian " + azimuth + " degrees";
        if (timeStampDone == true) {
          output.print("Meridian " + azimuth); 
          output.print("\t\t"+hour() + ":" + minute() +":" + second());
          timeStampDone = false;  
        }
      } else if (buttonstring[i] == "l" || buttonstring[i] == "r") {
        // the following resets the timer..
        kk++;
        if (kk == 1) {
          c.reset();
        }
        
        // println("hemi");
        arduino.write('h');
        arduino.write(',');
        arduino.write(buttonstring[i]);
        arduino.write('.');
        arduino.write(m);
        arduino.write('\n');
        textValue = "Hemisphere " + buttonstring[i];
        if (timeStampDone == true) {
          output.print("Hemisphere");
          if (buttonstring[i] == "l") {
            output.print(" left");
          } else {
            output.print(" right"); 
          }
          output.print("\t\t" + hour() + ":" + minute() +":" + second());
          timeStampDone = false;  
        }
        if (buttonstring[i] == "l") {
          hemquad[4] = 200;
        } else {
          hemquad[5] = 200;
        }
      
      } else if (int(buttonstring[i]) < 22) {
        // the following resets the timer..
        kk++;
        if (kk == 1) {
          c.reset();
        }
        
        // println("quadrant");
        arduino.write('q');
        arduino.write(',');
        arduino.write(buttonstring[i]);
        arduino.write('.');
        arduino.write(m);
        arduino.write('\n');
        textValue = "Quadrant " + buttonstring[i];
         if (timeStampDone == true) {
          output.print("Quadrant");
          if (buttonstring[i] == "2") {
            output.print(" top right");
          } else if (buttonstring[i] == "3") {
            output.print(" top left");
          } else if (buttonstring[i] == "4") {
            output.print(" bottom left"); 
          } else if (buttonstring[i] == "1") {
            output.print(" bottom right"); 
          } 
          output.print("\t" + hour() + ":" + minute() +":" + second());
          timeStampDone = false;  
        }
        hemquad[int(buttonstring[i]) - 1] = 200;  // set that particular quadrant to 'done' 
      }
      break;  //Break statement is essential else would lead to a number of bugs
    }
  }
}

void customize(DropdownList ddl) {
  // This part changes the properties of the MALE/FEMALE dropdown
  ddl.setBackgroundColor(color(190));
  ddl.setColorLabel(color(190));
  ddl.setItemHeight(40);
  ddl.setBarHeight(35);
  ddl.captionLabel().set("Sex");
  ddl.captionLabel().style().marginTop = 3;
  ddl.captionLabel().style().marginLeft = 3;
  ddl.valueLabel().style().marginTop = 3;
  ddl.addItem("Male", 0);
  ddl.addItem("Female", 1);
  ddl.scroll(0);
  ddl.setColorBackground(color(28,59,107));
  ddl.setColorActive(color(255, 128));
}

void controlEvent(ControlEvent theEvent) {
  // This part changes the value of variable textSex based on what's selected on the dropdown
  if (theEvent.isGroup()) {
    // check if the Event was triggered from a ControlGroup
    if (theEvent.getGroup().getValue()==0.0)
      textSex="Male";
    else
      textSex="Female";
  } else if (theEvent.isController()) {
    //println("event from controller : "+theEvent.getController().getValue()+" from "+theEvent.getController());
  }
}

void serialEvent(Serial arduino) { 
  String inString = arduino.readStringUntil('\n');
  if (inString != null) {
    // if (parseInt(inString.substring(0,1)) > 0) {    // we want to reject the last value "9" the arduino spits out from serial
      perimeter[me] = parseInt(inString.substring(0,1));  // write the number to the perimeter variable.
    // } 
  } 
}

// last but not least: we need to add a keypress functionality which checks if any key has been pressed and stops the test if so...
void keyPressed() {
  if (detailsEntered == true) {    // after the patient's data's been entered, ofc
    // println("key pressed");
    Stop();
    println("stopped");
  } 
}

// the code that puts the fixation OFF..
public void Fixation(){
  arduino.write('x');
  arduino.write('\n');
}
