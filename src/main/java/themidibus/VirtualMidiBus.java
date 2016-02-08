package themidibus;

import javax.sound.midi.MidiMessage;

/**
 * A bus without any real inputs/outputs - allows inputting raw byte data
 * and notifying listeners.
 */
public class VirtualMidiBus extends themidibus.MidiBus {
  public VirtualMidiBus(Object parent) {
    super(parent, -1, -1);
  }
  
  // A bit hacky, we implement this on the output end instead of input
  // to take adavantage of the byte-parsing variant of sendMessage.
  public synchronized void sendMessage(MidiMessage message) {
    sendMessage(message);
    super.sendMessage(message);
    
    long timestamp = System.currentTimeMillis();
    notifyListeners(message, timestamp);
    notifyParent(message, timestamp);
  }
}
