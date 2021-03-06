import netP5.*;
import oscP5.*;

/**
 *     DOUBLE BLACK DIAMOND        DOUBLE BLACK DIAMOND
 *
 *         //\\   //\\                 //\\   //\\  
 *        ///\\\ ///\\\               ///\\\ ///\\\
 *        \\\/// \\\///               \\\/// \\\///
 *         \\//   \\//                 \\//   \\//
 *
 *        EXPERTS ONLY!!              EXPERTS ONLY!!
 *
 * This class implements the output function to the Panda Boards. It
 * will be moved into GLucose once stabilized.
 */
public class PandaDriver {

  // IP address
  public final String ip;
  
  // Address to send to
  private final NetAddress address;
  
  // Whether board output is enabled
  private boolean enabled = false;
  
  // OSC message
  private final OscMessage message;

  // List of point indices that get sent to this board
  private final int[] points;
    
  // Packet data
  private final byte[] packet = new byte[4*352]; // magic number, our UDP packet size

  private static final int NO_POINT = -1;

  public PandaDriver(String ip) {
    this.ip = ip;
    
    // Initialize our OSC output stuff
    address = new NetAddress(ip, 9001);
    message = new OscMessage("/shady/pointbuffer");

    // Build the array of points, initialize all to nothing
    points = new int[PandaMapping.PIXELS_PER_BOARD];
    for (int i = 0; i < points.length; ++i) {
      points[i] = NO_POINT;
    }
  }

  /**
   * These constant arrays indicate the order in which the strips of a cube
   * are wired. There are four different options, depending on which bottom
   * corner of the cube the data wire comes in.
   */
  private final int[][] CUBE_STRIP_ORDERINGS = new int[][] {
    {  2,  1,  0,  3, 13, 12, 15, 14,  4,  7,  6,  5, 11, 10,  9,  8 }, // FRONT_LEFT
    {  6,  5,  4,  7,  1,  0,  3,  2,  8, 11, 10,  9, 15, 14, 13, 12 }, // FRONT_RIGHT
    { 14, 13, 12, 15,  9,  8, 11, 10,  0,  3,  2,  1,  7,  6,  5,  4 }, // REAR_LEFT
    { 10,  9,  8, 11,  5,  4,  7,  6, 12, 15, 14, 13,  3,  2,  1,  0 }, // REAR_RIGHT
  };

  public PandaDriver(String ip, Model model, PandaMapping pm) {
    this(ip);

    // Ok, we are initialized, time to build the array if points in order to
    // send out. We start at the head of our point buffer, and work our way
    // down. This is the order in which points will be sent down the wire.
    int ci = -1;
    
    // Iterate through all our channels
    for (ChannelMapping channel : pm.channelList) {
      ++ci;
      int pi = ci * ChannelMapping.PIXELS_PER_CHANNEL;
      
      switch (channel.mode) {

        case ChannelMapping.MODE_CUBES:
          // We have a list of cubes per channel
          for (int rawCubeIndex : channel.objectIndices) {
            if (rawCubeIndex < 0) {
              // No cube here, skip ahead in the buffer
              pi += Cube.POINTS_PER_CUBE;
            } else {
              // The cube exists, check which way it is wired to
              // figure out the order of strips.
              Cube cube = model.getCubeByRawIndex(rawCubeIndex);
              int stripOrderIndex = 0;
              switch (cube.wiring) {
                case FRONT_LEFT: stripOrderIndex = 0; break;
                case FRONT_RIGHT: stripOrderIndex = 1; break;
                case REAR_LEFT: stripOrderIndex = 2; break;
                case REAR_RIGHT: stripOrderIndex = 3; break;
              }
              
              // Iterate through all the strips on the cube and add the points
              for (int stripIndex : CUBE_STRIP_ORDERINGS[stripOrderIndex]) {
                // We go backwards here... in the model strips go clockwise, but
                // the physical wires are run counter-clockwise
                Strip s = cube.strips.get(stripIndex);
                for (int j = s.points.size() - 1; j >= 0; --j) {
                  points[pi++] = s.points.get(j).index;
                }
              }
            }
          }
          break;
          
        case ChannelMapping.MODE_BASS:
          // TODO(mapping): figure out how we end up connecting the bass cabinet
          break;
          
        case ChannelMapping.MODE_FLOOR:        
          // TODO(mapping): figure out how these strips are wired
          break;
          
        case ChannelMapping.MODE_SPEAKER:
          // TODO(mapping): figure out how these strips are wired
          break;
          
        case ChannelMapping.MODE_NULL:
          // No problem, nothing on this channel!
          break;
          
        default:
          throw new RuntimeException("Invalid/unhandled channel mapping mode: " + channel.mode);
      }

    }
  }

  public void toggle() {
    enabled = !enabled;
    println("PandaBoard/" + ip + ": " + (enabled ? "ON" : "OFF"));    
  }

  public final void send(int[] colors) {
    if (!enabled) {
      return;
    }
    int len = 0;
    int packetNum = 0;
    for (int index : points) {
      int c = (index < 0) ? 0 : colors[index];
      byte r = (byte) ((c >> 16) & 0xFF);
      byte g = (byte) ((c >> 8) & 0xFF);
      byte b = (byte) ((c) & 0xFF);
      packet[len++] = 0; // alpha channel, unused but makes for 4-byte alignment
      packet[len++] = r;
      packet[len++] = g;
      packet[len++] = b;

      // Flush once packet is full buffer size
      if (len >= packet.length) {
        sendPacket(packetNum++);
        len = 0;
      }
    }

    // Flush any remaining data
    if (len > 0) {
      sendPacket(packetNum++);
    }
  }
  
  private void sendPacket(int packetNum) {
    message.clearArguments();
    message.add(packetNum);
    message.add(packet.length);
    message.add(packet);
    try {
      OscP5.flush(message, address);
    } catch (Exception x) {
      x.printStackTrace();
    }
  }
}

