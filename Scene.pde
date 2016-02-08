public interface Scene extends Receiver {
  public void setup(OPC opc);
  public void draw();
  public void teardown();
}