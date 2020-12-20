#include <cstddef>
#include <fstream>

#include "../build/rmkit.h"
#include "../shared/string.h"
#include "../shared/clockwatch.h"
using namespace std

struct Point:
  int x, y

struct Rect:
  int x1, y1, x2, y2

DEBUG_GESTURES := false

INFILE := "genie.conf"

class Gesture:
  public:
  bool valid = true
  bool initialized = false
  int count = 0
  ClockWatch timer
  input::TouchEvent prev
  input::TouchEvent start

  // TODO: setup zones
  Rect zone

  PLS_DEFINE_SIGNAL(GESTURE_EVENT, void*)
  class GESTURE_EVENTS:
    public:
    GESTURE_EVENT activate;
  ;
  GESTURE_EVENTS events
  Gesture():
    zone.x1 = -1
    zone.x2 = -1
    zone.y1 = -1
    zone.y2 = -1

  void set_coordinates(float x1, y1, x2, y2):
    zone.x1 = x1
    zone.x2 = x2
    zone.y1 = y1
    zone.y2 = y2

  void reset():
    if DEBUG_GESTURES:
      debug "RESETTING"
    self.initialized = false
    self.valid = true
    self.count = 0

  void activate():
    self.events.activate()
    self.valid = false

  void init(input::TouchEvent &ev):
    timer = {}

    if zone.x1 != -1:
      if ev.x < zone.x1 || ev.x > zone.x2 || ev.y < zone.y1 || ev.y > zone.y2:
        if DEBUG_GESTURES:
          debug "NOT IN ZONE", ev.x, ev.y, zone.x1, zone.x2, zone.y1, zone.y2
        self.valid = false
    self.initialized = true
    self.start = ev

  virtual void setup(input::TouchEvent &ev):
    pass

  virtual void handle_event(input::TouchEvent &ev):
    pass

  virtual void finalize():
    pass

  virtual bool filter(input::TouchEvent &ev):
    return true

class SwipeGesture : public Gesture:
  public:
  int distance = 800
  int tolerance = 200
  int fingers = 1
  Point direction
  void setup(input::TouchEvent &ev):
    start = ev
    prev = ev

  // returns true if should handle event
  bool filter(input::TouchEvent &ev):
    fb := framebuffer::get()
    fw, fh := fb->get_display_size()
    // ignore jumpy events
    // ignore events with -1 values
    // ignore events out of bounds
    if self.initialized:
      if abs(prev.y - ev.y) > 500:
        if DEBUG_GESTURES:
          debug "FILTERED JUMP Y", ev.x, ev.y, ev.slot
        return false
      if abs(prev.x - ev.x) > 500:
        if DEBUG_GESTURES:
          debug "FILTERED JUMP X", ev.x, ev.y, ev.slot
        return false

    if ev.slot + 1 != self.fingers:
      if DEBUG_GESTURES:
        debug "FILTERED FINGERS", ev.x, ev.y, ev.slot
      return false

    if ev.y == -1 or ev.x == -1:
      if DEBUG_GESTURES:
        debug "FILTERED -1", ev.x, ev.y, ev.slot
      return false
    if ev.y > fh || ev.x > fw:
      if DEBUG_GESTURES:
        debug "FILTERED MAX", ev.x, ev.y, ev.slot
      return false

    if DEBUG_GESTURES:
      debug "ALLOWED", ev.x, ev.y, ev.slot
    return true

  void handle_event(input::TouchEvent &ev):
    if DEBUG_GESTURES:
      debug "HANDLING EVENT", ev.x, ev.y, ev.slot
    if direction.y && abs(ev.x - start.x) > self.tolerance:
      if DEBUG_GESTURES:
        debug "X TOLERANCE"
      self.valid = false

    if direction.x && abs(ev.y - start.y) > self.tolerance:
      if DEBUG_GESTURES:
        debug "Y TOLERANCE"
      self.valid = false

    if direction.x < 0 && prev.x - ev.x < 0:
      if DEBUG_GESTURES:
        debug "X DIRECTION"
      self.valid = false
    if direction.x > 0 && prev.x - ev.x > 0:
      if DEBUG_GESTURES:
        debug "X DIRECTION"
      self.valid = false

    if direction.y < 0 && prev.y - ev.y < 0:
      if DEBUG_GESTURES:
        debug "Y DIRECTION"
      self.valid = false
    if direction.y > 0 && prev.y - ev.y > 0:
      if DEBUG_GESTURES:
        debug "Y DIRECTION"
      self.valid = false
    prev = ev

  void finalize():
    if self.count < 5:
      if DEBUG_GESTURES:
        debug "FINALIZE COUNT"
      self.valid = false
    if direction.x && direction.x * (prev.x - start.x) < self.distance / 2:
      if DEBUG_GESTURES:
        debug "FINALIZE X"
      self.valid = false
    if direction.y && direction.y * (prev.y - start.y) < self.distance:
      if DEBUG_GESTURES:
        debug "FINALIZE Y"
      self.valid = false

    if self.valid:
      self.activate()

// Recognizes tapping with two or three fingers for an amount of time
class TapGesture : public Gesture:
  public:
  int fingers = 2
  float duration = 0
  float elapsed = 0

  void finalize():
    if !self.initialized:
      self.valid = false

    if self.count > 10 || self.count == 0:
      self.valid = false

    if duration == 0:
      if timer.elapsed() > 0.2:
        self.valid = false
    else:
      if self.elapsed < duration:
        self.valid = false

    if self.valid:
      self.activate()

  void setup(input::TouchEvent &ev):
    handle_event(ev)

  void handle_event(input::TouchEvent &ev):
    if ev.slot >= self.fingers:
      self.valid = false
    else:
      if duration > 0:
        self.elapsed = timer.elapsed()
        if self.elapsed > duration:
          self.activate()


  bool filter(input::TouchEvent &ev):
    if ev.slot + 1 < self.fingers:
      return false

    return true

class App:
  public:

  vector<input::TouchEvent> touch_events
  vector<Gesture*> gestures

  def handle_key_event(input::SynKeyEvent &key_ev):
    pass

  // we save the touch input until the finger lifts up
  // so we can analyze whether its a gesture or not
  def handle_gestures():
    for auto ev: ui::MainLoop::in.touch.events:
      for auto g : gestures:
        lifted := false
        for int s = 0; s <= ev.slot; s++:
          if ev.slots[s].left == 0:
            lifted = true
            break

        if lifted:
          if g->valid:
            g->finalize()
          g->reset()
        else:
          if g->filter(ev):
            if !g->initialized:
              if DEBUG_GESTURES:
                debug "INITIALIZING", ev.x, ev.y, ev.slot
              g->init(ev)
              g->setup(ev)
              g->count++
            else if g->valid:
              g->handle_event(ev)
              g->count++

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
      self.handle_gestures()

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

SwipeGesture* build_swipe_gesture(GestureConfigData gcd):
  fb := framebuffer::get()
  fw, fh := fb->get_display_size()
  g := new SwipeGesture()
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

TapGesture* build_tap_gesture(GestureConfigData gcd):
  fb := framebuffer::get()
  fw, fh := fb->get_display_size()
  g := new TapGesture()
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
  vector<Gesture*> gestures
  GestureConfigData gcd


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
      if tokens[0] == "fingers":
        gcd.fingers = tokens[1]
      if tokens[0] == "zone":
        gcd.zone = tokens[1]
      if tokens[0] == "duration":
        gcd.duration = tokens[1]
      if tokens[0] == "direction":
        gcd.direction = tokens[1]

  create_gesture(gcd, gestures)
  return gestures

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

  for auto g : gestures:
    app.gestures.push_back(g)

def main(int argc, char **argv):
  App app

  if argc > 1:
    INFILE = argv[1]
    debug "USING", INFILE, "AS CONFIG FILE"

  setup_gestures(app)

  app.run()
