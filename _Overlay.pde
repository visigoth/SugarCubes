/**
 * Overlay UI that indicates pattern control, etc. This will be moved
 * into the Processing library once it is stabilized and need not be
 * regularly modified.
 */
class OverlayUI {
  
  private final PFont titleFont = createFont("Myriad Pro", 10);
  private final PFont itemFont = createFont("Myriad Pro", 11);
  private final PFont knobFont = titleFont;
  private final int w = 140;
  private final int leftPos;
  private final int leftTextPos;
  private final int lineHeight = 20;
  private final int sectionSpacing = 12;
  private final int tempoHeight = 20;
  private final int knobSize = 28;
  private final int knobSpacing = 6;
  private final int knobLabelHeight = 14;
  private final color lightBlue = #666699;
  private final color lightGreen = #669966;
  
  private final String[] patternNames;
  private final String[] transitionNames;
  private final String[] effectNames;

  private PImage logo;
  
  private int firstPatternY;
  private int firstTransitionY;
  private int firstEffectY;
  private int firstKnobY;
  private int tempoY;
  
  private Method patternStateMethod;
  private Method transitionStateMethod;
  private Method effectStateMethod;
  
  OverlayUI() {
    leftPos = width - w;
    leftTextPos = leftPos + 4;
    logo = loadImage("logo-sm.png");
    
    patternNames = classNameArray(patterns);
    transitionNames = classNameArray(transitions);
    effectNames = classNameArray(effects);    

    try {
      patternStateMethod = getClass().getMethod("getState", LXPattern.class);
      effectStateMethod = getClass().getMethod("getState", LXEffect.class);
      transitionStateMethod = getClass().getMethod("getState", LXTransition.class);
    } catch (Exception x) {
      throw new RuntimeException(x);
    }    
  }
  
  void drawHelpTip() {
    textFont(itemFont);
    textAlign(RIGHT);
    text("Tap 'u' to restore UI", width-4, height-6);
  }
  
  void draw() {    
    image(logo, 4, 4);
    
    stroke(color(0, 0, 100));
    // fill(color(0, 0, 50, 50)); // alpha is bad for perf
    fill(color(0, 0, 30));
    rect(leftPos-1, -1, w+2, height+2);
    
    int yPos = 0;    
    firstPatternY = yPos + lineHeight + 6;
    yPos = drawObjectList(yPos, "PATTERN", patterns, patternNames, patternStateMethod);

    yPos += sectionSpacing;
    yPos = drawObjectList(yPos, "CONTROL", null, null, null);
    yPos += 6;
    firstKnobY = yPos;
    int xPos = leftTextPos;
    for (int i = 0; i < glucose.NUM_PATTERN_KNOBS/2; ++i) {
      drawKnob(xPos, yPos, knobSize, glucose.patternKnobs[i]);
      drawKnob(xPos, yPos + knobSize + knobSpacing + knobLabelHeight, knobSize, glucose.patternKnobs[glucose.NUM_PATTERN_KNOBS/2 + i]);
      xPos += knobSize + knobSpacing;
    }
    yPos += 2*(knobSize + knobLabelHeight) + knobSpacing;

    yPos += sectionSpacing;
    firstTransitionY = yPos + lineHeight + 6;
    yPos = drawObjectList(yPos, "TRANSITION", transitions, transitionNames, transitionStateMethod);
    
    yPos += sectionSpacing;
    firstEffectY = yPos + lineHeight + 6;
    yPos = drawObjectList(yPos, "FX", effects, effectNames, effectStateMethod);
    
    yPos += sectionSpacing;
    yPos = drawObjectList(yPos, "TEMPO", null, null, null);
    yPos += 6;
    tempoY = yPos;
    stroke(#111111);
    fill(tempoDown ? lightGreen : color(0, 0, 35 - 8*lx.tempo.rampf()));
    rect(leftPos + 4, yPos, w - 8, tempoHeight);
    fill(0);
    textAlign(CENTER);
    text("" + ((int)(lx.tempo.bpmf() * 100) / 100.), leftPos + w/2., yPos + tempoHeight - 6);
    yPos += tempoHeight;
    
    fill(#999999);
    textFont(itemFont);
    textAlign(LEFT);
    text("Tap 'u' to hide UI (~+3FPS)", leftTextPos, height-6);
  }
  
  public Knob getOrNull(List<Knob> items, int index) {
    if (index < items.size()) {
      return items.get(index);
    }
    return null;
  }
  
  public void drawFPS() {
    textFont(titleFont);
    textAlign(LEFT);
    fill(#666666);
    text("FPS: " + (((int)(frameRate * 10)) / 10.), 4, height-6);     
  }

  private final int STATE_DEFAULT = 0;
  private final int STATE_ACTIVE = 1;
  private final int STATE_PENDING = 2;

  public int getState(LXPattern p) {
    if (p == lx.getPattern()) {
      return STATE_ACTIVE;
    } else if (p == lx.getNextPattern()) {
      return STATE_PENDING;
    }
    return STATE_DEFAULT;
  }
  
  public int getState(LXEffect e) {
    return e.isEnabled() ? STATE_ACTIVE : STATE_DEFAULT;
  }
  
  public int getState(LXTransition t) {
    if (t == lx.getTransition()) {
      return STATE_PENDING;
    } else if (t == transitions[activeTransitionIndex]) {
      return STATE_ACTIVE;
    }
    return STATE_DEFAULT;
  }

  protected int drawObjectList(int yPos, String title, Object[] items, Method stateMethod) {
    return drawObjectList(yPos, title, items, classNameArray(items), stateMethod);
  }
  
  private int drawObjectList(int yPos, String title, Object[] items, String[] names, Method stateMethod) {
    noStroke();
    fill(#aaaaaa);
    textFont(titleFont);
    textAlign(LEFT);
    text(title, leftTextPos, yPos += lineHeight);    
    if (items != null) {
      textFont(itemFont);
      color textColor;      
      boolean even = true;
      for (int i = 0; i < items.length; ++i) {
        Object o = items[i];
        int state = STATE_DEFAULT;
        try {
           state = ((Integer) stateMethod.invoke(this, o)).intValue();
        } catch (Exception x) {
          throw new RuntimeException(x);
        }
        switch (state) {
          case STATE_ACTIVE:
            fill(lightGreen);
            textColor = #eeeeee;
            break;
          case STATE_PENDING:
            fill(lightBlue);
            textColor = color(0, 0, 75 + 15*sin(millis()/200.));;
            break;
          default:
            textColor = 0;
            fill(even ? #666666 : #777777);
            break;
        }
        rect(leftPos, yPos+6, width, lineHeight);
        fill(textColor);
        text(names[i], leftTextPos, yPos += lineHeight);
        even = !even;       
      }
    }
    return yPos;
  }
  
  private void drawKnob(int xPos, int yPos, int knobSize, Knob knob) {
    final float knobIndent = .4;
    final float knobValue = knob.getValuef();
    String knobLabel = knob.getLabel();
    if (knobLabel.length() > 4) {
      knobLabel = knobLabel.substring(0, 4);
    } else if (knobLabel.length() == 0) {
      knobLabel = "-";
    }
    
    ellipseMode(CENTER);
    fill(#222222);
    arc(xPos + knobSize/2, yPos + knobSize/2, knobSize, knobSize, HALF_PI + knobIndent, HALF_PI + knobIndent + (TWO_PI-2*knobIndent));

    fill(lightGreen);
    arc(xPos + knobSize/2, yPos + knobSize/2, knobSize, knobSize, HALF_PI + knobIndent, HALF_PI + knobIndent + (TWO_PI-2*knobIndent)*knobValue);

    fill(#333333);
    ellipse(xPos + knobSize/2, yPos + knobSize/2, knobSize/2, knobSize/2);
    
    fill(0);
    rect(xPos, yPos + knobSize + 2, knobSize, knobLabelHeight - 2);
    fill(#999999);
    textAlign(CENTER);
    textFont(knobFont);
    text(knobLabel, xPos + knobSize/2, yPos + knobSize + knobLabelHeight - 2);

  }
  
  private String[] classNameArray(Object[] objects) {
    if (objects == null) {
      return null;
    }
    String[] names = new String[objects.length];
    for (int i = 0; i < objects.length; ++i) {
      names[i] = className(objects[i]);
    }
    return names;
  }
  
  private String className(Object p) {
    String s = p.getClass().getName();
    int li;
    if ((li = s.lastIndexOf(".")) > 0) {
      s = s.substring(li + 1);
    }
    if (s.indexOf("SugarCubes$") == 0) {
      return s.substring("SugarCubes$".length());
    }
    return s;
  }
  
  private int knobIndex = -1;
  private int lastY;
  private int releaseEffect = -1;
  private boolean tempoDown = false;

  public void mousePressed() {
    lastY = mouseY;
    knobIndex = -1;
    releaseEffect = -1;
    if (mouseY > tempoY) {
      if (mouseY - tempoY < tempoHeight) {
        lx.tempo.tap();
        tempoDown = true;
      }
    } else if (mouseY > firstEffectY) {
      int effectIndex = (mouseY - firstEffectY) / lineHeight;
      if (effectIndex < effects.length) {
        if (effects[effectIndex].isMomentary()) {
          effects[effectIndex].enable();
          releaseEffect = effectIndex;
        } else {
          effects[effectIndex].toggle();
        }
      }
    } else if (mouseY > firstTransitionY) {
      int transitionIndex = (mouseY - firstTransitionY) / lineHeight;
      if (transitionIndex < transitions.length) {
        activeTransitionIndex = transitionIndex;
      }
    } else if ((mouseY >= firstKnobY) && (mouseY < firstKnobY + 2*(knobSize+knobLabelHeight) + knobSpacing)) {
      knobIndex = (mouseX - leftTextPos) / (knobSize + knobSpacing);
      if (mouseY >= firstKnobY + knobSize + knobLabelHeight + knobSpacing) {
        knobIndex += glucose.NUM_PATTERN_KNOBS / 2;
      }      
    } else if (mouseY > firstPatternY) {
      int patternIndex = (mouseY - firstPatternY) / lineHeight;
      if (patternIndex < patterns.length) {
        patterns[patternIndex].setTransition(transitions[activeTransitionIndex]);
        lx.goIndex(patternIndex);
      }
    }
  }
  
  public void mouseDragged() {
    int dy = lastY - mouseY;
    lastY = mouseY;
    if (knobIndex >= 0 && knobIndex < glucose.NUM_PATTERN_KNOBS) {
      Knob k = glucose.patternKnobs[knobIndex];
      k.setValue(k.getValuef() + dy*.01);
    }
  }
    
  public void mouseReleased() {
    tempoDown = false;
    if (releaseEffect >= 0) {
      effects[releaseEffect].trigger();
      releaseEffect = -1;      
    }
  }
}

void mousePressed() {
  if (mouseX > ui.leftPos) {
    ui.mousePressed();
  }
}

void mouseReleased() {
  if (mouseX > ui.leftPos) {
    ui.mouseReleased();
  }
}

void mouseDragged() {
  if (mouseX > ui.leftPos) {
    ui.mouseDragged();
  }
}
