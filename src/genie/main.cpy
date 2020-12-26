#include <cstddef>
#include <fstream>

#include "../build/rmkit.h"
#include "../shared/string.h"
using namespace std

INFILE := "genie.conf"

using input::Gesture
using input::SwipeGesture
using input::TapGesture

class App:
  public:

  vector<input::TouchEvent> touch_events

  def handle_key_event(input::SynKeyEvent &key_ev):
    pass

  def run():
    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    // ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)

    // just to kick off the app, we do a full redraw
    ui::MainLoop::refresh()
    ui::MainLoop::redraw()
    while true:
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()
      ui::MainLoop::handle_gestures()

// gesture=swipe
// direction=left
// coordinates=[0 100 90 100]
// fingers=2
// command="/home/root/swipes/swipeup.sh"

struct GestureConfigData:
  string command = ""
  string gesture = ""
  string fingers = ""
  string zone = ""
  string direction = ""
  string duration = ""

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

  g->events.activate += PLS_LAMBDA(auto d) {
    debug "RUNNING COMMAND", gcd.command
    string cmd = gcd.command + string(" &")
    c_str := cmd.c_str()
    system(c_str)
  }

  debug "ADDED SWIPE GESTURE:"
  debug "  command:", gcd.command
  debug "  gesture:", gcd.gesture
  debug "  fingers:", gcd.fingers
  debug "  zone:", g->zone.x1, g->zone.y1, g->zone.x2, g->zone.y2
  debug "  direction:", gcd.direction
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
    debug "RUNNING COMMAND", gcd.command
    string cmd = gcd.command + string(" &")
    c_str := cmd.c_str()
    system(c_str)
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
  if gcd.gesture != "" && gcd.command != "":
    if gcd.gesture == "swipe":
      gestures.push_back(build_swipe_gesture(gcd))
    else if gcd.gesture == "tap":
      gestures.push_back(build_tap_gesture(gcd))
    else:
      debug "Unknown gesture type:", gcd.gesture

vector<Gesture*> parse_config(vector<string> &lines):
  GestureConfigData gcd


  for auto line : lines:
    str_utils::trim(line)
    if line == "":
      create_gesture(gcd, ui::MainLoop::gestures)
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
      if tokens[0] == "fingers":
        gcd.fingers = tokens[1]
      if tokens[0] == "zone":
        gcd.zone = tokens[1]
      if tokens[0] == "duration":
        gcd.duration = tokens[1]
      if tokens[0] == "direction":
        gcd.direction = tokens[1]

  create_gesture(gcd, ui::MainLoop::gestures)
  return ui::MainLoop::gestures

def setup_gestures(App &app):
  string line
  ifstream infile(INFILE)
  vector<string> lines

  while getline(infile, line):
    lines.push_back(line)

  gestures := parse_config(lines)
  if gestures.size() == 0:
    debug "NO GESTURES"
    exit(0)

def main(int argc, char **argv):
  App app

  if argc > 1:
    INFILE = argv[1]
    debug "USING", INFILE, "AS CONFIG FILE"

  setup_gestures(app)

  app.run()
