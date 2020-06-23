// LAUNCHER FOR HARMONY
#include <csignal>
#include <time.h>
#include <thread>
#include <chrono>

#include "input/input.h"
#include "app/proc.h"

#define TIMEOUT 2
class App:
  input::Input in
  int lastpress
  int is_pressed = false

  public:
  App():
    pass

  def handle_key_event(input::SynKeyEvent ev):
    static int lastpress = RAND_MAX
    static int event_press_id = 0
    if is_pressed && ev.is_pressed:
      return

    switch ev.key:
      case KEY_HOME:

        if ev.is_pressed:
          lastpress = time(NULL)
          event_press_id = ev.id

          thread *th = new thread([=]() {
              print "STARTING THREAD", event_press_id, ev.id
              this_thread::sleep_for(chrono::seconds(TIMEOUT));
              if is_pressed && event_press_id == ev.id
                now = time(NULL)
                if now - lastpress > 1:
                  proc::launch_harmony()
                  print "EVENT WAS HELD DOWN"
              print "ENDED THREAD", event_press_id, ev.id
          });
        else:
          event_press_id = 0

        is_pressed = ev.is_pressed
    last_ev = &ev


  def run():
    while true:
      in.listen_all()
      for auto ev : in.all_key_events:
        self.handle_key_event(ev)



App app
def main():
  app.run()
