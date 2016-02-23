import java.util.Set;
import java.util.HashSet;
import javax.sound.midi.*;

public class MidiBroadcaster {
  private Set<Receiver> receivers = new HashSet<Receiver>();

  public boolean addReceiver(Receiver receiver) {
    return receivers.add(receiver);
  }
  
  public boolean removeReceiver(Receiver receiver) {
    return receivers.remove(receiver);    
  }
  
  /**
   * Send a raw-bytes message to all receivers with the current system timestamp.
   */
  public void transmit(byte[] bytes) throws InvalidMidiDataException {
    transmit(bytes, System.currentTimeMillis());
  }
  
  /**
   * Send a raw-bytes message with timestamp to all receivers.
   */
  public void transmit(byte[] bytes, long timestamp) throws InvalidMidiDataException {
    MidiMessage message = this.midiMessage(bytes);
    for (Receiver receiver : receivers) {
      receiver.send(message, timestamp);
    }
  }

  /**
   * Get the message for the given bytes list. Yanked from themidibus.
   */
  protected MidiMessage midiMessage(byte[] data) throws InvalidMidiDataException {
    if ((int)((byte)data[0] & 0xFF) == MetaMessage.META) {
      MetaMessage message = new MetaMessage();
      byte[] payload = new byte[data.length-2];
      System.arraycopy(data, 2, payload, 0, data.length-2);
      message.setMessage((int)((byte)data[1] & 0xFF), payload, data.length-2);
      return message;
    } else if((int)((byte)data[0] & 0xFF) == SysexMessage.SYSTEM_EXCLUSIVE || (int)((byte)data[0] & 0xFF) == SysexMessage.SPECIAL_SYSTEM_EXCLUSIVE) {
      SysexMessage message = new SysexMessage();
      message.setMessage(data, data.length);
      return message;
    } else {
      ShortMessage message = new ShortMessage();
      if (data.length > 2) {
        message.setMessage((int)((byte)data[0] & 0xFF), (int)((byte)data[1] & 0xFF), (int)((byte)data[2] & 0xFF));
      } else if (data.length > 1) {
        message.setMessage((int)((byte)data[0] & 0xFF), (int)((byte)data[1] & 0xFF), 0);
      } else {
        message.setMessage((int)((byte)data[0] & 0xFF));
      }
      return message;
    }    
  }
}
