using input::Gesture
using input::SwipeGesture
using input::TapGesture

namespace genie:

  struct GestureConfigData:
    string command = ""
    string gesture = ""
    string fingers = ""
    string zone = ""
    string direction = ""
    string duration = ""
    string min_events = ""
    string distance = ""
  ;

  void run_command(string command):
    debug "RUNNING COMMAND", command
    string cmd = command + "&"
    c_str := cmd.c_str()
    _ := system(c_str)

    ui::TaskQueue::add_task([=]() {
      usleep(1e3 * 50)
      ui::MainLoop::reset_gestures()
    })

  input::SwipeGesture* build_swipe_gesture(GestureConfigData gcd):
    fb := framebuffer::get()
    fw, fh := fb->get_display_size()
    g := new input::SwipeGesture()
    if gcd.fingers != "":
      g->fingers = atoi(gcd.fingers.c_str())
    if gcd.zone != "":
      tokens := str_utils::split(gcd.zone, ' ')
      if tokens.size() != 4:
        debug "ZONE MUST BE 4 FLOATS", gcd.zone

      else:
        x1 := int(atof((const char*) tokens[0].c_str()) * fw)
        y1 := int(atof((const char*) tokens[1].c_str()) * fh)
        x2 := int(atof((const char*) tokens[2].c_str()) * fw)
        y2 := int(atof((const char*) tokens[3].c_str()) * fh)

        g->set_coordinates(x1, y1, x2, y2)

    if gcd.direction == "left":
      g->direction = {-1, 0}
    if gcd.direction == "right":
      g->direction = {1, 0}
    if gcd.direction == "up":
      g->direction = {0, -1}
    if gcd.direction == "down":
      g->direction = {0, 1}

    if gcd.distance != "":
      g->distance = atof(gcd.distance.c_str())

    if gcd.min_events != "":
      g->min_events = atof(gcd.min_events.c_str())

    g->events.activate += PLS_LAMBDA(auto d) {
      if gcd.command == "":
        return

      run_command(gcd.command)

    }

    debug "ADDED SWIPE GESTURE:"
    debug "  command:", gcd.command
    debug "  gesture:", gcd.gesture
    debug "  fingers:", gcd.fingers
    debug "  min_events:", gcd.min_events
    debug "  zone:", g->zone.x1, g->zone.y1, g->zone.x2, g->zone.y2
    debug "  direction:", gcd.direction
    debug "  distance:", gcd.distance
    return g

  input::TapGesture* build_tap_gesture(GestureConfigData gcd):
    fb := framebuffer::get()
    fw, fh := fb->get_display_size()
    g := new input::TapGesture()
    if gcd.fingers != "":
      g->fingers = atoi(gcd.fingers.c_str())

    if gcd.duration != "":
      g->duration = atof(gcd.duration.c_str())

    if gcd.zone != "":
      tokens := str_utils::split(gcd.zone, ' ')
      if tokens.size() != 4:
        debug "ZONE MUST BE 4 FLOATS", gcd.zone

      else:
        x1 := int(atof((const char*) tokens[0].c_str()) * fw)
        y1 := int(atof((const char*) tokens[1].c_str()) * fh)
        x2 := int(atof((const char*) tokens[2].c_str()) * fw)
        y2 := int(atof((const char*) tokens[3].c_str()) * fh)

        g->set_coordinates(x1, y1, x2, y2)

    g->events.activate += PLS_LAMBDA(auto d) {
      if gcd.command == "":
        return

      run_command(gcd.command)
    }

    debug "ADDED TAP GESTURE:"
    debug "  command:", gcd.command
    debug "  gesture:", gcd.gesture
    debug "  fingers:", gcd.fingers
    debug "  zone:", g->zone.x1, g->zone.y1, g->zone.x2, g->zone.y2
    debug "  duration:", g->duration
    return g

  void create_gesture(GestureConfigData gcd, vector<Gesture*> &gestures):
    fb := framebuffer::get()
    fw, fh := fb->get_display_size()
    if gcd.gesture != "":
      if gcd.gesture == "swipe":
        gestures.push_back(build_swipe_gesture(gcd))
      else if gcd.gesture == "tap":
        gestures.push_back(build_tap_gesture(gcd))
      else:
        debug "Unknown gesture type:", gcd.gesture

  vector<Gesture*> parse_config(vector<string> &lines):
    GestureConfigData gcd

    vector<Gesture*> gestures;


    for auto line : lines:
      str_utils::trim(line)
      if line == "":
        create_gesture(gcd, gestures)
        gcd = {}
      else if line[0] == '#':
        continue
      else:
        tokens := str_utils::split(line, '=')
        while tokens.size() > 2:
          tokens[tokens.size()-2] += "=" + tokens[tokens.size()-1]
          tokens.pop_back()

        if tokens[0] == "gesture":
          gcd.gesture = tokens[1]
        if tokens[0] == "command":
          gcd.command = tokens[1]
        if tokens[0] == "count":
          gcd.min_events = tokens[1]
        if tokens[0] == "fingers":
          gcd.fingers = tokens[1]
        if tokens[0] == "zone":
          gcd.zone = tokens[1]
        if tokens[0] == "distance":
          gcd.distance = tokens[1]
        if tokens[0] == "duration":
          gcd.duration = tokens[1]
        if tokens[0] == "direction":
          gcd.direction = tokens[1]

    create_gesture(gcd, gestures)
    return gestures

