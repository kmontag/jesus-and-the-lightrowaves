import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import javax.swing.Timer;

import javax.sound.midi.InvalidMidiDataException;
import javax.sound.midi.MidiMessage;
import javax.sound.midi.ShortMessage;

import java.nio.ByteBuffer;

import org.java_websocket.WebSocket;
import org.java_websocket.client.WebSocketClient;

import java.net.URI;
import java.net.URISyntaxException;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

OPC opc;
MidiBroadcaster midiBroadcaster;
// ConnectionManager connectionManager;
MidiServer midiServer;
SceneManager sceneManager;

void setup() {
  size(600, 600);
  opc = new OPC(this, "127.0.0.1", 7890);
 
  midiBroadcaster = new MidiBroadcaster();
  try {
    midiServer = new MidiServer(midiBroadcaster, 6660);
  } catch (UnknownHostException ex) {
    ex.printStackTrace();
  }
  midiServer.start();
  //try {
  //  connectionManager = new ConnectionManager(new URI("http://localhost:6660"), midiBroadcaster);
  //} catch (URISyntaxException ex) {
  //  ex.printStackTrace();
  //}
  
  sceneManager = new SceneManager(opc);
  sceneManager.changeProgram(1);
  
  midiBroadcaster.addReceiver(sceneManager);
}

void draw() {
  sceneManager.draw();
}

private class SceneManager implements Receiver {
  private final OPC opc;
  private final Map<Integer, Scene> programs;

  private Scene currentScene = null;
  private int currentProgramNumber;
  
  public SceneManager(OPC opc) {
    this.opc = opc;

    // Set up program list
    Map<Integer, Scene> m = new HashMap<Integer, Scene>(); // program number -> scene class name
    m.put(1, new Dissolving());  
    programs = Collections.unmodifiableMap(m); // Make immutable

    changeProgram(0);
  }
  
  synchronized public void draw() {
    if (currentScene == null) {
      background(0);
    } else {
      currentScene.draw();
    }
  }

  /**
   * Change the program and tear down the current one, if any.
   * If the current program number is given, reloads the program
   * from scratch.
   */
  synchronized public void changeProgram(int programNumber) {
    Scene scene = programs.get(programNumber);
 
    // Clean up the current program, if any
    if (currentScene != null) {
      midiBroadcaster.removeReceiver(currentScene);
      currentScene.teardown();      
      currentScene = null;
    }
    
    if (scene != null) {
      currentScene = scene;
      currentScene.setup(opc);
      midiBroadcaster.addReceiver(currentScene);
      this.currentProgramNumber = programNumber;
    } else {
      this.currentProgramNumber = 0;
    }    
  }
  
  public void close() {
  }
  
  public void send(MidiMessage message, long timestamp) {
    if (message instanceof ShortMessage) {
      ShortMessage m = (ShortMessage)message;
      if (m.getCommand() == ShortMessage.PROGRAM_CHANGE) {
        changeProgram(m.getData1());
      }
    }
    
    // Forward to the current scene
    if (currentScene != null) {
      currentScene.send(message, timestamp);
    }
  }
}



private class ConnectionManager {
  
  private static final int RECONNECT_DELAY = 5000;
  
  private Client client = null;
  protected final URI uri;
  protected final MidiBroadcaster midiBroadcaster;
  
  public ConnectionManager(URI uri, MidiBroadcaster midiBroadcaster) {
    this.uri = uri;
    this.midiBroadcaster = midiBroadcaster;

    // Spawn connection threads
    Timer timer = new Timer(RECONNECT_DELAY, new MaintainConnectionActionListener(this));
    timer.setInitialDelay(10);
    timer.start();
  }
  
  /**
   * Reconnect (synchronously) to the server.
   * @return whether the reconnect was successful.
   */
  public synchronized void checkConnection() {
    if (this.client == null || 
      this.client.getReadyState() != WebSocket.READYSTATE.CONNECTING && 
      this.client.getReadyState() != WebSocket.READYSTATE.OPEN) {    
      if (this.client != null) {
        this.client.close();
      }
      this.client = new Client(this);
      try {
        this.client.connectBlocking();
      } catch (InterruptedException ex) {
        this.client = null;
      }
    }    
  }
  
  private class Client extends WebSocketClient {
    private ConnectionManager parent;
  
    public Client(ConnectionManager parent) {
      super(parent.uri);
      this.parent = parent;
    }
  
    @Override
    public void onOpen(ServerHandshake handshakeData) {
      System.out.println("Connection opened");
    }
  
    @Override
    public void onMessage(String message) {
      System.out.println("Received: " + message);
    }
    
    @Override
    public void onMessage(ByteBuffer bytes) {
      byte[] bytesArray = new byte[bytes.remaining()];
      bytes.get(bytesArray);
      
      try {
        this.parent.midiBroadcaster.transmit(bytesArray);
      } catch (InvalidMidiDataException ex) {
        ex.printStackTrace();
      }
    }
  
    @Override
    public void onClose(int code, String reason, boolean remote) {
      // The codecodes are documented in class org.java_websocket.framing.CloseFrame
      System.out.println("Connection closed by " + (remote ? "remote peer" : "us"));
    }
  
    @Override
    public void onError(Exception ex) {
      if (ex instanceof java.net.ConnectException) {
        System.out.println("Problem connecting");
      } else {
        ex.printStackTrace();
      }
    }
  }
  
  // Reconnect class for timer.
  private class MaintainConnectionActionListener implements ActionListener {
    private final ConnectionManager parent;
    public MaintainConnectionActionListener(ConnectionManager parent) {
      this.parent = parent;
    }
    public void actionPerformed(ActionEvent event) {
      this.parent.checkConnection();
    }
  }
}