/**
 *           +-+-+-+-+-+               +-+-+-+-+-+
 *          /         /|               |\         \
 *         /         / +               + \         \
 *        +-+-+-+-+-+  |   +-+-+-+-+   |  +-+-+-+-+-+
 *        |         |  +  /         \  +  |         |
 *        +   THE   + /  /           \  \ +  CUBES  +
 *        |         |/  +-+-+-+-+-+-+-+  \|         |
 *        +-+-+-+-+-+   |             |   +-+-+-+-+-+
 *                      +             +
 *                      |    SUGAR    |
 *                      +             +
 *                      |             |
 *                      +-+-+-+-+-+-+-+
 *
 * Welcome to the Sugar Cubes! This Processing sketch is a fun place to build
 * animations, effects, and interactions for the platform. Most of the icky
 * code guts are embedded in the GLucose library extension. If you're an
 * artist, you shouldn't need to worry about any of that.
 *
 * Below, you will find definitions of the Patterns, Effects, and Interactions.
 * If you're an artist, create a new tab in the Processing environment with
 * your name. Implement your classes there, and add them to the list below.
 */ 

LXPattern[] patterns(GLucose glucose) {
  return new LXPattern[] {
    new SpaceTime(glucose),
    new Swarm(glucose),
    new CubeEQ(glucose),
    
    // Basic test patterns for reference, not art
//    new TestHuePattern(glucose),
//    new TestXPattern(glucose),
//    new TestYPattern(glucose),
//    new TestZPattern(glucose),
  };
}

LXTransition[] transitions(GLucose glucose) {
  return new LXTransition[] {
    new DissolveTransition(lx).setDuration(3000),
    new SwipeTransition(glucose),
    new FadeTransition(lx).setDuration(2000),
  };
}

LXEffect[] effects(GLucose glucose) {
  return new LXEffect[] {
    new FlashEffect(lx),
    new DesaturationEffect(lx),
  };
}
