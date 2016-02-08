public abstract class LEDStripScene extends AbstractScene {
  public static final short PIXELS = 60;
  public static final boolean REVERSED = false;
  
  public void setup(OPC opc) {
    opc.ledStrip(0, PIXELS, width / 2, height / 2, width / (float)PIXELS, 0, REVERSED);
  }
  }