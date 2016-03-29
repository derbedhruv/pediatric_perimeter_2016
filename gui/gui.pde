/** Modified from ControlP5 frame **/
 
import java.awt.*;
import java.awt.event.*;
import controlP5.*;
import processing.serial.*;
import codeanticode.gsvideo.*;

// DECLARING A CONTROLP5 OBJECT
private ControlP5 cp5;

// HEMI AND QUAD VARIABLES
int quad_state[][] = {{1, 1}, {1, 1}, {1, 1}, {1, 1}};    // 1 means the quad has not been done yet, 2 means it has already been done, 3 means it is presently going on, negative means it is being hovered upon
int hemi_state[][] = {{1, 1}, {1, 1}, {1, 1}, {1, 1}};    // the same thing is used for the hemis
color quad_colors[][] = {{#eeeeee, #00ff00, #ffff22, #0000ff}, {#dddddd, #00ff00, #ffff22, #0000ff}};
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
GSMovieMaker mm;      // GS Video Movie Maker Object
int fps = 30;          // The Number of Frames per second Declaration (used for the processing sketch framerate as well as the video that is recorded


// THIS IS THE MAIN FRAME
  void setup() {
    cp5 = new ControlP5( this );
    // DECLARE THE CONTROLFRAME, WHICH IS THE OTHER FRAME
    ControlFrame cf1 = addControlFrame( "hello", 200, 200, 40, 40, color( 100 ) );
    cf1.setVisible(true);  // set it to be invisible, so we can give it focus later
    
      // INITIATE SERIAL CONNECTION
      println(Serial.list()[Serial.list().length - 1]);
      if (Serial.list().length != 0) {
        String port = Serial.list()[Serial.list().length - 1];
        println("Arduino MEGA connected succesfully.");
        
        // then we open up the port.. 115200 bauds
        arduino = new Serial(this, port, 115200);
        arduino.buffer(1);
      } else {
        println("Arduino not connected or detected, please replug"); 
        // exit();
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
          println(cameras[i]);
          
          println(cameras[i].length());
          println(cameras[i].substring(3,6));
          // if (cameras[i].length() == 13 && cameras[i].substring(3,6).equals("USB")) {
            println("...success!");
            cam = new GSCapture(this, 640, 480, cameras[i]);      // Camera object will capture in 640x480 resolution
            cam.start();      // shall start acquiring video feed from the camera
            break; 
          // }
          // println("...NO. Please check the camera connected and try again."); 
          // exit();
        }  
      }
  }
  
  void draw() {
  
  }


void keyPressed() {
  switch(key) {
    case('1'):
    getFrame("hello").setVisible( true );
    break;
    case('4'):
    getFrame("hello").setVisible( false );
    break;
    case('5'):
    removeFrame("hello");
    break;
  }
}


/* no changes required below */

HashMap<String, ControlFrame> frames = new HashMap<String, ControlFrame>();

ControlFrame addControlFrame(String theName, int theWidth, int theHeight) {
  return addControlFrame(theName, theWidth, theHeight, 100, 100, color( 0 ) );
}

ControlFrame addControlFrame(final String theName, int theWidth, int theHeight, int theX, int theY, int theColor ) {
  if (frames.containsKey(theName)) {
    /* if frame already exist, a RuntimeException is thrown, please adjust to your needs if necessary. */
    throw new RuntimeException(String.format( "Sorry frame %s already exist.", theName ) );
  }
  final Frame f = new Frame( theName );
  final ControlFrame p = new ControlFrame( this, f, theName, theWidth, theHeight, theColor );
  f.add( p );
  p.init();
  f.setTitle(theName);
  f.setSize( p.w, p.h );
  f.setLocation( theX, theY );
  f.addWindowListener( new WindowAdapter() {
    @Override
      public void windowClosing(WindowEvent we) {
      removeFrame( theName );
    }
  });
  
  f.setResizable( false );
  f.setVisible( false );
  // sleep a little bit to allow p to call setup.
  // otherwise a nullpointerexception might be caused.
  try {
    Thread.sleep( 20 );
  } 
  catch(Exception e) {
  }
  frames.put( theName, p );
  return p;
}

void removeFrame( String theName ) {
  getFrame( theName ).dispose();
  frames.remove( theName );
}

ControlFrame getFrame( String theName ) {
  if (frames.containsKey( theName )) {
    return frames.get( theName );
  }  
  /* if frame does not exist anymore, a RuntimeException is thrown, please adjust to your needs if necessary. */
  throw new RuntimeException(String.format( "Sorry frame %s does not exist.", theName ) );
}


// the ControlFrame class extends PApplet, so we are creating a new processing applet inside a new frame with a controlP5 object loaded
// herein we define our new object
public class ControlFrame extends PApplet {
  int w, h;

  public void setup() {
    size(w, h);
    frameRate(30);
    cp5 = new ControlP5( this );
  }

  public void draw() {
    background(0);
  }

  public ControlFrame(Object theParent, Frame theFrame, String theName, int theWidth, int theHeight, int theColor) {
    parent = theParent;
    frame = theFrame;
    name = theName;
    w = theWidth;
    h = theHeight;
  }


  public ControlP5 control() {
    return this.cp5;
  }  
  
  
  @Override
    public void dispose() {
    frame.dispose();
    super.dispose();
  }
  
  public void setVisible( boolean b) {
    frame.setVisible(b);
  }
  
  
  final Object parent;
  final Frame frame;
  final String name;
  private ControlP5 cp5;
  private boolean isUndecorated;
}
