import javax.sound.midi.MidiMessage;
import javax.sound.midi.ShortMessage;

public abstract class AbstractScene implements Scene {
  public void teardown() {
    // No-op by default
  }
  
  public void close() {
    // For Receiver interface
  }

  /**
   * Default send implementation, forward to simplified functions.
   */
  public void send(MidiMessage message, long timestamp) {
    if (message instanceof ShortMessage) {
      ShortMessage m = (ShortMessage)message;
      if (m.getCommand() == ShortMessage.NOTE_ON) {
        noteOn(m.getChannel(), m.getData1(), m.getData2());
      } else if (m.getCommand() == ShortMessage.NOTE_OFF) {
        noteOff(m.getChannel(), m.getData1(), m.getData2());
      } else if (m.getCommand() == ShortMessage.CONTROL_CHANGE) {
        controllerChange(m.getCommand(), m.getData1(), m.getData2());
      }
    }
  }
  
  protected void noteOn(int channel, int pitch, int velocity) {
  }
  
  protected void noteOff(int channel, int pitch, int velocity) {
  }
  
  protected void controllerChange(int channel, int number, int value) {
  }
}