import java.util.*;
import punktiert.math.Vec;
import punktiert.physics.*;

public class Dissolving extends LEDStripScene {

  final int NUM_BLACK_LIGHTS = 100;  
  private VPhysics blackLightPhysics;

  Set<Note> notes = new HashSet<Note>();
  
  private class Note {
    public final int pitch, velocity;

    private final float radius = 50;
    private final PVector position;
    private final float maxOpacity;
    private final long startTime;
    private final int attackTime = 100;

    public Note(int pitch, int velocity) {
      this.pitch = pitch;
      this.velocity = velocity;
      position = new PVector(lerp(0, width, (float(pitch - 12) / 88.0)), height / 2);
      maxOpacity = lerp(0, 0.3, float(velocity) / 127.0);
      startTime = System.currentTimeMillis();
    }
    
    public void draw(){//PGraphics graphics) {
      noFill();
      long currentTime = System.currentTimeMillis();
      for (int i = 1; i < radius; i++) {
        float r = float(i) / radius;
        float sineOffset = -lerp(0, 2.0 * (float)Math.PI, (float)(currentTime % 2000) / 2000.0);
        float sine = (float)Math.pow((1.0 + (float)Math.sin(lerp(0, 4.0 * (float)Math.PI, r) + sineOffset)) / 2.0, 1);
        float sineEffect = 1.0 - lerp(Math.min(0.2, sine), sine, r); // The sine doesn't start affecting the ellipse until the outside
        sineEffect = sine;
        float opacity = lerp(maxOpacity * sineEffect, 0, r);

        // Fade in
        if (currentTime - startTime <= attackTime) {
          opacity *= lerp(0, 1, (float)(currentTime - startTime) / (float)attackTime);
        }
        stroke(color(255, 255, 255, 255.0 * opacity));
        ellipse(position.x, position.y, i, i);
      }
    }
  }
  
  public void setup(OPC opc) {
    super.setup(opc);

    //// Particle system
    // see https://github.com/djrkohler/punktiert/blob/master/examples/Behavior_BWander/Behavior_BWander.pde
    blackLightPhysics = new VPhysics();
  
    BWorldBox boxx = new BWorldBox(new Vec(), new Vec(width, height, 500));
    boxx.setWrapSpace(false);
    blackLightPhysics.addBehavior(boxx);
  
    for (int i = 0; i < NUM_BLACK_LIGHTS; i++) {
      //val for arbitrary radius
      float rad = random(2, width / 10);
      //vector for position
      Vec pos = new Vec (random(rad, width-rad), random(rad, height-rad));
      //create particle (Vec pos, mass, radius)
      VParticle particle = new VParticle(pos, 1, rad);
      //add Collision Behavior
      particle.addBehavior(new BCollision());
  
      particle.addBehavior(new BWander(13, 10, 10));
      //add particle to world
      blackLightPhysics.addParticle(particle);
    }
  }
  public synchronized void draw() {
    background(color(0, 0, 0));

    //// Basic background
    color bassColor = #731A30;
    color padColor = #301A73;
    color lickColor = #1A735D;
    
    int padBreakpoint = (int)(1.25 * width / 3);
    int lickBreakpoint = (int)((width / 3) * 2.35);
    
    noStroke();
    fill(bassColor);
    rect(0, 0, padBreakpoint, height);
    
    fill(padColor);
    rect(padBreakpoint, 0, lickBreakpoint - padBreakpoint, height);
    
    fill(lickColor);
    rect(lickBreakpoint, 0, width - lickBreakpoint, height);
    
    int gradientWidth = width / 20;
    verticalGradient(padBreakpoint, gradientWidth, bassColor, padColor);
    verticalGradient(lickBreakpoint, gradientWidth, padColor, lickColor);

    //// Moving dark spots
    blackLightPhysics.update();
    for (VParticle p : blackLightPhysics.particles) {
      for (int i = 1; i < p.getRadius(); i++) { // Increasingly transparent
        stroke(color(0, 0, 0, lerp(200, 0, float(i) / (p.getRadius() + 1))));
        ellipse(p.x, p.y, i, i);
      }
    }
    
    //if (new Random().nextInt(100) == 0) {
    //  noteOn(1, 50, 127);
    //}
    //if (new Random().nextInt(100) == 0) {
    //  noteOff(1, 50, 0);
    //}

    //PGraphics noteGraphics = createGraphics(width, height);
    //noteGraphics.beginDraw();
    //noteGraphics.blendMode(LIGHTEST);
    for (Note note : notes) {
      note.draw();//noteGraphics);
    }
    //noteGraphics.endDraw();
    //image(noteGraphics, 0, 0);
  }
  
  // Adapted from https://processing.org/examples/lineargradient.html
  private void verticalGradient(int center, int delta, color c1, color c2) {

    noFill();
  
    for (int i = center - delta; i <= center + delta; i++) {
      float inter = map(i, center - delta, center + delta, 0, 1);
      color c = lerpColor(c1, c2, inter);
      stroke(c);
      line(i, 0, i, height);
    }
  }
  
  @Override
  public synchronized void noteOn(int channel, int pitch, int velocity) {
    System.out.println(pitch);
    notes.add(new Note(pitch, velocity));
  }
  
  @Override
  public synchronized void noteOff(int channel, int pitch, int velocity) {
    for (Iterator<Note> i = notes.iterator(); i.hasNext();) {
      if (i.next().pitch == pitch) {
        i.remove();
      }
    }
  }
  
  @Override
  public synchronized void controllerChange(int channel, int number, int value) {
  }
}