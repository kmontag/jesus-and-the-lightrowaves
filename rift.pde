import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import javax.swing.Timer;

import javax.sound.midi.InvalidMidiDataException;
import javax.sound.midi.MidiMessage;
import javax.sound.midi.ShortMessage;

import java.nio.ByteBuffer;
import org.java_websocket.client.WebSocketClient;

import java.net.URI;
import java.net.URISyntaxException;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

OPC opc;
Client client;
MidiBroadcaster midiBroadcaster;
SceneManager sceneManager;

Object renderLock = new Object();
Object reconnectLock = new Object();

void setup() {
  size(600, 600);
  opc = new OPC(this, "127.0.0.1", 7890);
 
  midiBroadcaster = new MidiBroadcaster();
  try {
    client = new Client(new URI("http://localhost:6660"), midiBroadcaster);
    client.connect();
  } catch (URISyntaxException ex) {
    ex.printStackTrace();
  }
  
  sceneManager = new SceneManager(opc);
  sceneManager.changeProgram(1);
  
  midiBroadcaster.addReceiver(sceneManager);
}

void draw() {
  sceneManager.draw();
}

void reconnect(URI uri) {
  synchronized(reconnectLock) {
    client = new Client(uri, midiBroadcaster);
    client.connect();
  }
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

private class Client extends WebSocketClient {
  private MidiBroadcaster midiBroadcaster;

  public Client(URI serverURI, MidiBroadcaster midiBroadcaster) {
    super(serverURI);
    this.midiBroadcaster = midiBroadcaster;
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
      this.midiBroadcaster.transmit(bytesArray);
    } catch (InvalidMidiDataException ex) {
      ex.printStackTrace();
    }
  }

  @Override
  public void onClose(int code, String reason, boolean remote) {
    // The codecodes are documented in class org.java_websocket.framing.CloseFrame
    System.out.println("Connection closed by " + (remote ? "remote peer" : "us"));
    new Timer(5000, new ReconnectActionListener(this.getURI())).start();
  }

  @Override
  public void onError(Exception ex) {
    ex.printStackTrace();
  }
  
  private class ReconnectActionListener implements ActionListener {
    private URI uri;    
    public ReconnectActionListener(URI uri) {
      this.uri = uri;
    }
    
    public void actionPerformed(ActionEvent event) {
      reconnect(uri);
    }
  }
}