#include "../../shared/clockwatch.h"
#include "../util/signals.h"
#include "../fb/fb_info.h"
#include "events.h"

namespace input:
  extern bool DEBUG_GESTURES = false
  extern bool DEBUG_GESTURE_FILTERS = false

  class Gesture:
    public:
    struct Point:
      int x, y
    ;

    struct Rect:
      int x1, y1, x2, y2
    ;

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
    int min_events = 15
    int fingers = 1
    Gesture::Point direction
    void setup(input::TouchEvent &ev):
      start = ev
      prev = ev

    // returns true if should handle event
    bool filter(input::TouchEvent &ev):
      // ignore jumpy events
      // ignore events with -1 values
      // ignore events out of bounds
      if self.initialized:
        if abs(prev.y - ev.y) > 500:
          if DEBUG_GESTURE_FILTERS:
            debug "FILTERED JUMP Y", ev.x, ev.y, ev.slot
          return false
        if abs(prev.x - ev.x) > 500:
          if DEBUG_GESTURE_FILTERS:
            debug "FILTERED JUMP X", ev.x, ev.y, ev.slot
          return false

      if ev.count_fingers() != self.fingers:
        if DEBUG_GESTURE_FILTERS:
          debug "FILTERED FINGERS", ev.x, ev.y, ev.slot
        return false

      if ev.y == -1 or ev.x == -1:
        if DEBUG_GESTURE_FILTERS:
          debug "FILTERED -1", ev.x, ev.y, ev.slot
        return false
      if ev.y > framebuffer::fb_info::display_height || ev.x > framebuffer::fb_info::display_width:
        if DEBUG_GESTURE_FILTERS:
          debug "FILTERED MAX", ev.x, ev.y, ev.slot
        return false

      if DEBUG_GESTURE_FILTERS:
        debug "ALLOWED", ev.x, ev.y, ev.slot
      return true

    void handle_event(input::TouchEvent &ev):
      if DEBUG_GESTURES:
        debug "HANDLING EVENT", ev.x, ev.y, ev.slot
      if direction.y && abs(ev.x - start.x) > self.tolerance:
        if DEBUG_GESTURES:
          debug "X TOLERANCE", abs(ev.x - start.x)
        self.valid = false

      if direction.x && abs(ev.y - start.y) > self.tolerance*2:
        if DEBUG_GESTURES:
          debug "Y TOLERANCE", abs(ev.y - start.y)
        self.valid = false

      if direction.x < 0 && prev.x - ev.x < 0:
        if DEBUG_GESTURES:
          debug "X DIRECTION", prev.x, ev.x
        self.valid = false
      if direction.x > 0 && prev.x - ev.x > 0:
        if DEBUG_GESTURES:
          debug "X DIRECTION", prev.x, ev.x
        self.valid = false

      if direction.y < 0 && prev.y - ev.y < 0:
        if DEBUG_GESTURES:
          debug "Y DIRECTION", prev.y, ev.y
        self.valid = false
      if direction.y > 0 && prev.y - ev.y > 0:
        if DEBUG_GESTURES:
          debug "Y DIRECTION", prev.y, ev.y
        self.valid = false
      prev = ev

    void finalize():
      if self.count < self.min_events:
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
      if abs(ev.y - start.y) > 10 or abs(ev.x - start.x) > 10:
        self.valid = false

      if ev.count_fingers() > self.fingers:
        self.valid = false
      else:
        if duration > 0:
          self.elapsed = timer.elapsed()
          if self.elapsed > duration:
            self.activate()


    bool filter(input::TouchEvent &ev):
      if ev.y == -1 or ev.x == -1:
        return false

      if ev.count_fingers() < self.fingers:
        return false

      return true
