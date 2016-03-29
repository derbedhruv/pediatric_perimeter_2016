/** Modified from ControlP5 frame **/
 
import java.awt.*;
import java.awt.event.*;
import controlP5.*;
import processing.serial.*;
import codeanticode.gsvideo.*;

// DECLARING A CONTROLP5 OBJECT
private ControlP5 cp5;

// THIS IS THE MAIN FRAME
  void setup() {
    cp5 = new ControlP5( this );
    // DECLARE THE CONTROLFRAME, WHICH IS THE OTHER FRAME
    ControlFrame cf1 = addControlFrame( "hello", 200, 200, 40, 40, color( 100 ) );
    cf1.setVisible(true);  // set it to be invisible, so we can give it focus later
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
