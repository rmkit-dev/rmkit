#include <cstddef>
#include <fstream>

#include "../build/rmkit.h"
#include "../shared/string.h"


#include "gesture_parser.h"

INFILE := "genie.conf"
using namespace std
using namespace genie

class App:
  public:

  vector<input::TouchEvent> touch_events

  def handle_key_event(input::SynKeyEvent &key_ev):
    pass

  def run():
    // disable palm touches
    palm_str := getenv("RMKIT_PALM_SIZE")
    if palm_str != NULL:
      try {
        input::TouchEvent::MIN_PALM_SIZE = stoi(palm_str)
        debug "SET MIN PALM SIZE TO", input::TouchEvent::MIN_PALM_SIZE
      } catch(...) {};

    if getenv("RMKIT_PALM_DEBUG") != NULL:
      input::TouchEvent::DEBUG_PALM_SIZE = true

    ui::MainLoop::filter_palm_events = true


    // don't listen for stylus events, saves CPU
    ui::MainLoop::in.unmonitor(ui::MainLoop::in.wacom.fd)

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
    ui::MainLoop::gestures.push_back(g)

def main(int argc, char **argv):
  App app

  if argc > 1:
    INFILE = argv[1]
    debug "USING", INFILE, "AS CONFIG FILE"

  setup_gestures(app)

  app.run()
