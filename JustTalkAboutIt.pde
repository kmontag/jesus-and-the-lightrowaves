public class JustTalkAboutIt extends LEDStripScene {
  PImage im;

  void setup(OPC opc)
  {
    im = loadImage("Jars.jpg");
    super.setup(opc);
  }
  
  void draw()
  {
    background(0);
    // Scale the image so that it matches the width of the window
    int imHeight = im.height * width / im.width;
  
    // Scroll down slowly, and wrap around
    float speed = 0.01;
    float y = (millis() * -speed) % imHeight;
    
    // Use two copies of the image, so it seems to repeat infinitely  
    image(im, 0, y, width, imHeight);
    image(im, 0, y + imHeight, width, imHeight);
    tint(255, 127);
  }
}