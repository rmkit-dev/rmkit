// LAUNCHER FOR HARMONY
#include <csignal>
#include <time.h>

#include "input/input.h"
#include "app/proc.h"

#define TIMEOUT 2
class App:
  input::Input in
  public:
  App():
    pass

  def handle_key_event(input::KeyEvent &ev):
    static int lastpress = RAND_MAX
    switch ev.key:
      case KEY_HOME:
        if ev.is_pressed:
          lastpress = time(NULL)
        else:
          now = time(NULL)
          if now - lastpress > TIMEOUT:
            proc::launch_harmony()

  def run():
    while true:
      in.listen_all()
      for auto ev : in.all_key_events:
        self.handle_key_event(ev)



App app
def main():
  app.run()
