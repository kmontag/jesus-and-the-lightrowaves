import java.net.InetSocketAddress;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import javax.sound.midi.InvalidMidiDataException;

import org.java_websocket.WebSocket;
import org.java_websocket.WebSocketImpl;
import org.java_websocket.framing.Framedata;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.server.WebSocketServer;

public class MidiServer extends WebSocketServer {
  private final MidiBroadcaster midiBroadcaster;

  public MidiServer(MidiBroadcaster midiBroadcaster, int port) throws UnknownHostException {
    super(new InetSocketAddress(port));
    this.midiBroadcaster = midiBroadcaster;
  }

  public MidiServer(MidiBroadcaster midiBroadcaster, InetSocketAddress address) {
    super(address);
    this.midiBroadcaster = midiBroadcaster;
  }

  @Override
  public void onOpen(WebSocket conn, ClientHandshake handshake) {
    System.out.println("connected: " + conn.getRemoteSocketAddress().getAddress().getHostAddress());
  }

  @Override
  public void onClose(WebSocket conn, int code, String reason, boolean remote) {
    System.out.println("disconnected: " + conn);
  }

  @Override
  public void onMessage(WebSocket conn, String message) {
  }
  
  @Override
  public void onMessage(WebSocket conn, ByteBuffer bytes) {
    byte[] bytesArray = new byte[bytes.remaining()];
    bytes.get(bytesArray);
    
    try {
      this.midiBroadcaster.transmit(bytesArray);
    } catch (InvalidMidiDataException ex) {
      ex.printStackTrace();
    }
  }


  @Override
  public void onError( WebSocket conn, Exception ex ) {
    ex.printStackTrace();
    if( conn != null ) {
      // some errors like port binding failed may not be assignable to a specific websocket
    }
  }
}
