// hack made during the creative code jam 15.3.14 berlin co.up
// every 2 seconds a osc is modulated or a new oscs are created
// modulation creates an osc and patches it to the frequency or amplitude 
// of an osc
// INTERACTION: 
// press left mouse to turn an osc on or off
// press left mouse and q to modulate its amplitude 
// press left mouse and w to modulate its frequency 
// press right mouse to create a new osc

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;
import java.util.*;

Minim minim;
AudioOutput out;

int numToOut = 1;
ArrayList<Oscil> toOut = new ArrayList<Oscil>();
ArrayList<Oscil> availableForChange = new ArrayList<Oscil>();
ArrayList<Integer> types = new ArrayList<Integer>();

int maxOut = 10;

ArrayList<Boolean> on = new ArrayList<Boolean>();

float[] soundfreqRange = { 
  200, 1000
};
float[] soundFreqExtremes = { 
  200, 1000
};
float[] ampExtremes = { 
  0, 1
};
String[] typeNames = { 
  "sine", "triangle", "square", "noise", "pulse", 
  "phasor"
};

public void setup() {
  super.setup();
  minim = new Minim(this);
  out = minim.getLineOut();
  newToOut(numToOut);
  stroke(255);
  size(800, 600);
  strokeWeight(3);
  textAlign(CENTER, CENTER);
}

@Override
public void mousePressed() {
  if (mouseButton == LEFT)
    if (keyPressed)
      changeOsc();
    else
      mute();
  else
    addOut();
}


// changes one oscilators frequency or amplitude depending on the key
// q: amp, w:freq
private void changeOsc() {
  int p = (int) ((float) mouseX / width * toOut.size());
  Oscil pick = toOut.get(p);
  if (key == 'q') {
    rndAmpOsc().patch(pick.amplitude);
  } 
  else if (key == 'w') {
    rndFreqOsc().patch(pick.frequency);
  }
}

// mutes a oscilator
private void mute() {
  int p = (int) ((float) mouseX / width * toOut.size());
  if (on.get(p)) {
    on.set(p, false);
    toOut.get(p).unpatch(out);
  } 
  else {
    on.set(p, true);
    toOut.get(p).patch(out);
  }
}

// adds a number oscilator to play
private void newToOut(int toOut) {
  if (this.toOut.size() >= maxOut)
    return;
  System.out.println("new " + toOut);
  for (int i = 0; i < toOut; i++)
    addOut();
}

// creates and adds a new oscilator
private void addOut() {
  if (this.toOut.size() >= maxOut)
    return;
  int type = (int) random(6);
  Oscil osc = new Oscil(rndToneFreq(), 1, randomWt());
  this.types.add(type);
  osc.patch(out);
  toOut.add(osc);
  on.add(true);
  availableForChange.add(osc);
}

// a random frequency in the defined frequency range 
private float rndToneFreq() {
  return random(soundfreqRange[0], soundfreqRange[1]);
}

// a random wavetable
private Waveform randomWt() {
  return getWaveTable((int) random(6));
}

// next second to add an osc or modulate an osc
int nextE = 0;

public void draw() {
  // background fade
  fill(0, 20);
  rect(-5, -5, width + 10, height + 10);
  // adding an osc or modulating, every 2 seconds
  if (millis() > 1000 * nextE) {
    nextE += 2;
    addModOsc();
  }
  // draw them
  // width per osc
  int oscW = width / toOut.size();
  for (int i = 0; i < toOut.size(); i++) {
    Oscil osc = toOut.get(i);
    float freq = osc.frequency.getLastValue();
    // frequency: red line
    // get the values and adapt global mins and max for correct mapping
    soundFreqExtremes[0] = min(soundFreqExtremes[0], freq);
    soundFreqExtremes[1] = max(soundFreqExtremes[1], freq);
    freq = map(freq, soundFreqExtremes[0], soundFreqExtremes[1], 
    height, 0);
    stroke(255, 0, 0);
    line(oscW * i, freq, oscW * (i + 1), freq);
    // adaot min,max
    float amp = osc.getLastValues()[0];
    ampExtremes[0] = min(ampExtremes[0], amp);
    ampExtremes[1] = max(ampExtremes[1], amp);
    amp = map(amp, ampExtremes[0], ampExtremes[1], height, 0);
    stroke(255);
    line(oscW * i, amp, oscW * (i + 1), amp);
    // write the basic type at the top
    fill(255);
    text(typeNames[types.get(i)], oscW * i + oscW / 2, 10);
    // draw a grey rectangle if its off
    if (!on.get(i)) {
      noStroke();
      fill(0, 150);
      rect(oscW * i, 0, oscW, height);
    }
  }
}


// creates and add a modulation osc(freq or amp) or creates
// a new osc if all are modulated
private void addModOsc() {
  if (availableForChange.size() == 0) {
    newToOut((int) random(1, 3));
    return;
  }
  int p = (int) random(availableForChange.size());
  System.out.println("pick " + p);
  Oscil pick = availableForChange.get(p);
  boolean fp = pick.frequency.isPatched();
  boolean ap = pick.amplitude.isPatched();
  if (!fp && !ap || (fp && ap && random(1) < 0.3f)) {
    if (random(1) < .5) {
      rndFreqOsc().patch(pick.frequency);
      System.out.println("freq");
    } 
    else {
      rndAmpOsc().patch(pick.amplitude);
      System.out.println("amp");
    }
  } 
  else if (!fp) {
    rndFreqOsc().patch(pick.frequency);
    System.out.println("freq");
    availableForChange.remove(pick);
  } 
  else if (!ap) {
    rndAmpOsc().patch(pick.amplitude);
    System.out.println("amp");
    availableForChange.remove(pick);
  } 
  else
    System.out.println("boring. no change");
}

Summer rndFreqOsc() {
  return oscAround(rndToneFreq(), random(0.1f, 4), random(60, 400), 
  randomWt());
}

Summer rndAmpOsc() {
  return oscAround(random(0.5f) + 0.5f, random(0.01f, 0.2f), 
  random(0.5f), randomWt());
}

// create a osc that oscilates around a center frequency instead of 0
Summer oscAround(float center, float freq, float amp, Waveform form) {
  Summer sum = new Summer();

  Oscil freqOsc = new Oscil(freq, amp, form);
  Line ampEnv = new Line(center, center);

  ampEnv.patch(sum);
  freqOsc.patch(sum);

  return sum;
}

Wavetable getWaveTable(int simpleType) {
  switch (simpleType) {
  case 0:
    return Waves.SINE;
  case 1:
    return Waves.TRIANGLE;
  case 2:
    return Waves.SQUARE;
  case 3:
    return Waves.randomNoise();
  case 4:
    return Waves.pulse(random(1));
  case 5:
    return Waves.PHASOR;
  default:
    return Waves.SINE;
  }
}

