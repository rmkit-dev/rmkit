// an event system for widgets
#include "defines.h"

typedef string Signal

class EventArgs:
  def get_args():
    pass

typedef void EventCallback(EventArgs)

class EventEmitter:
  map<Signal, vector<EventCallback>> subscriptions 

  def emit(Signal s):
    pass

  def on(Signal s, EventCallback ptr):
    pass

