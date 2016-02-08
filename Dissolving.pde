public class Dissolving extends LEDStripScene {
  public void setup(OPC opc) {
    super.setup(opc);
    colorMode(HSB);
  }
  public void draw() {
    background(color((System.currentTimeMillis() / 30) % 255, 150, 150));
  }
  
  @Override
  public void noteOn(int channel, int pitch, int velocity) {
    System.out.println("Note on: " + pitch);
  }
  
  @Override
  public void noteOff(int channel, int pitch, int velocity) {
  }
  
  @Override
  public void controllerChange(int channel, int number, int value) {
  }
}