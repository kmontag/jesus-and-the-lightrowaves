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