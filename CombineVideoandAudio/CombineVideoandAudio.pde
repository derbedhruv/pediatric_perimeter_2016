import controlP5.*;

ControlP5 cp5;

String pathFolder;

void setup() {
  
  size(400, 160);
  noStroke();
   cp5 = new ControlP5(this);
  cp5.setColorForeground(#222288);
  cp5.setColorActive(#08BFC4);
  
    // change the trigger event, by default it is PRESSED.
  cp5.addButton("Combine")
     .setPosition(100, 120)
     .setSize(75, 25)
      .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          .setColor(0)
     ;
     
  cp5.addButton("Select_Folder")
     .setPosition(200, 120)
     .setSize(75, 25)
     .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER) //Caption and the alignment
          .setColor(0)
     ;
}

void draw(){
  background(#cccccc);
  fill(0);
 text("COMBINE VIDEO AND AUDIO", 125,20);
  text("Selected Path  :", 20,60);
 if(pathFolder != null){
 text(pathFolder , 20,90);
 } else {
   text("NA", 20,90);
 }
 
 
}
void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    pathFolder = selection.getAbsolutePath();
    pathFolder = pathFolder.replace("\\", "/");
  }
}

void Select_Folder(){
selectFolder("Select a file to write to:", "fileSelected");
}


public void Combine() {
 // String pathFolder = cp5.get(Textfield.class,"Directory").getText();
  println(pathFolder);
  
 if(pathFolder != null){
     try {
       String[] ffmpeg_command = {
    "C:\\Windows\\System32\\cmd.exe", "/c", "start", "ffmpeg", "-i", pathFolder + "/video.mpg", "-i", pathFolder+"/recording.wav", "-c:v", "copy", "-c:a", "copy", pathFolder +"/FinalVideo.avi"};
 ProcessBuilder  p = new ProcessBuilder(ffmpeg_command);
  Process  pr = p.start();
  } 
  catch (IOException e) {
    e.printStackTrace(); 
    exit();
  }
  exit();
 }
  
}


