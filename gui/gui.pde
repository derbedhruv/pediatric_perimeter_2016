/** Modified from ControlP5 frame **/
 
import java.awt.*;
import java.awt.event.*;
import controlP5.*;
import processing.serial.*;
import codeanticode.gsvideo.*;


private ControlP5 cp5;

int bgColor;

void setup() {

  size(400, 400 );

  cp5 = new ControlP5( this );

  /* Add a controlframe */

  ControlFrame cf1 = addControlFrame( "hello", 200, 200, 40, 40, color( 100 ) );
  
  // add a slider with an EventListener. When dragging the slider, 
  // variable bgColor will change accordingly. 
  cf1.control().addSlider( "s1" ).setRange( 0, 255 ).addListener( new ControlListener() {
    public void controlEvent( ControlEvent ev ) {
      bgColor = color( ev.getValue() );
    }
  }
  );
  
  cf1.setVisible( false );
}

void draw() {
  background( bgColor );
}


void keyPressed() {
  switch(key) {
    case('1'):
    getFrame("hello").setVisible( true );
    break;
    case('2'):
    getFrame("hello").setUndecorated( true );
    break;
    case('3'):
    getFrame("hello").setUndecorated( false );
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
  } 
  );
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


// the ControlFrame class extends PApplet, so we 
// are creating a new processing applet inside a
// new frame with a controlP5 object loaded
public class ControlFrame extends PApplet {

  int w, h;

  int bg;

  public void setup() {
    size( w , h );
    frameRate( 30 );
    cp5 = new ControlP5( this );
  }

  public void draw() {
    background( bg );
  }

  public ControlFrame(Object theParent, Frame theFrame, String theName, int theWidth, int theHeight, int theColor) {
    parent = theParent;
    frame = theFrame;
    name = theName;
    w = theWidth;
    h = theHeight;
    bg = theColor;
  }


  public ControlP5 control() {
    return this.cp5;
  }  
  
  
  @Override
    public void dispose() {
    frame.dispose();
    super.dispose();
  }
  
  public boolean isUndecorated() {
    return isUndecorated;
  }
  
  public void setUndecorated( boolean theFlag ) {
    if (theFlag != isUndecorated()) {
      isUndecorated = theFlag;
      frame.removeNotify();
      frame.setUndecorated(isUndecorated);
      setSize(width, height);
      setBounds(0, 0, width, height);
      frame.setSize(width, height);
      frame.addNotify();
    }
  }
  
  public void setVisible( boolean b) {
    frame.setVisible( b );
  }
  
  
  final Object parent;
  final Frame frame;
  final String name;
  private ControlP5 cp5;
  private boolean isUndecorated;
}
