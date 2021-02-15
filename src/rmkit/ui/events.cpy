#include <cmath>

#include "../input/events.h"
#include "../util/signals.h"
#include "timer.h"

namespace ui:
  PLS_DEFINE_SIGNAL(MOUSE_EVENT, input::SynMotionEvent)
  class MOUSE_EVENTS:
    public:
    MOUSE_EVENT enter
    MOUSE_EVENT leave
    MOUSE_EVENT down
    MOUSE_EVENT up
    MOUSE_EVENT click
    MOUSE_EVENT hover
    MOUSE_EVENT move
  ;

  PLS_DEFINE_SIGNAL(KEY_EVENT, input::SynKeyEvent)
  class KEY_EVENTS:
    public:
    KEY_EVENT pressed
  ;

  class GESTURE_EVENTS:
    public:
    MOUSE_EVENT long_press
    MOUSE_EVENT single_click
    MOUSE_EVENT double_click
    MOUSE_EVENT drag_start
    MOUSE_EVENT dragging
    MOUSE_EVENT drag_end

    // The threshold area that determines if this is a touch-based gesture
    // (e.g. long_press, double_click) or a motion-based gesture (e.g. drag).
    int touch_slop_size = 50

    // Once dragging, only submit events when the x or y delta > this step.
    // This limits the number of dragging events.
    int dragging_step_size = 25

    // Length of time (in ms) between a down event and a long_press
    long long_press_timeout = 500

    // Maximum gap (in ms) between clicks for a gesture to be considered a
    // double_click. If there are any double_click handlers registered, this
    // delay must pass without another down event before single_click will be
    // triggered (otherwise single_click is triggered immediately on up).
    long double_click_timeout = 250

    // State machine
    void attach(MOUSE_EVENTS * mouse):
      mouse->down += PLS_LAMBDA(auto &ev) {
        switch state:
          case IDLE:              return IDLE_down(ev)
          case WAIT_DOUBLE_CLICK: return WAIT_DOUBLE_CLICK_down(ev)
          default:                return reset()
      }
      mouse->up += PLS_LAMBDA(auto &ev) {
        switch state:
          case DOWN:        return DOWN_up(ev)
          case DRAGGING:    return finish(drag_end, ev)
          case SECOND_DOWN: return finish(double_click, ev)
          default:          return reset()
      }
      mouse->move += PLS_LAMBDA(auto &ev) {
        switch state:
          case DOWN:        return DOWN_move(ev)
          case DRAGGING:    return DRAGGING_move(ev)
          default:          return
      }
      mouse->leave += PLS_LAMBDA(auto &ev) {
        switch state:
          case DRAGGING:    return finish(drag_end, ev)
          default:          return reset()
      }

    protected:
    input::SynMotionEvent prev_ev
    TimerPtr long_press_timer
    TimerPtr single_click_timer
    enum STATE { IDLE, DOWN, DRAGGING, WAIT_DOUBLE_CLICK, SECOND_DOWN }
    STATE state = IDLE

    inline void IDLE_down(input::SynMotionEvent &ev):
      reset()
      state = DOWN
      prev_ev = ev
      if not long_press.empty():
        long_press_timer = ui::set_timeout([=]() {
          auto ev_copy = ev
          finish(long_press, ev_copy)
        }, long_press_timeout)

    inline void DOWN_up(input::SynMotionEvent &ev):
      cancel_long_press()
      if double_click.empty():
        finish(single_click, ev)
      else:
        state = WAIT_DOUBLE_CLICK
        single_click_timer = ui::set_timeout([=]() {
          auto ev_copy = ev
          finish(single_click, ev_copy)
        }, double_click_timeout)

    inline void DOWN_move(input::SynMotionEvent &ev):
      if outside_tolerance(ev, touch_slop_size):
        state = DRAGGING
        cancel_long_press()
        drag_start(prev_ev)
        prev_ev = ev

    inline void WAIT_DOUBLE_CLICK_down(input::SynMotionEvent &ev):
      state = SECOND_DOWN
      cancel_single_click()
      prev_ev = ev

    inline void DRAGGING_move(input::SynMotionEvent &ev):
      if outside_tolerance(ev, dragging_step_size):
        dragging(ev)
        prev_ev = ev

    // helpers
    void reset():
      cancel_long_press()
      cancel_single_click()
      state = IDLE

    inline void finish(MOUSE_EVENT & handler, input::SynMotionEvent & ev):
      handler(ev)
      reset()

    void cancel_long_press()
      if long_press_timer:
        ui::cancel_timer(long_press_timer)
        long_press_timer = nullptr

    void cancel_single_click()
      if single_click_timer:
        ui::cancel_timer(single_click_timer)
        single_click_timer = nullptr

    bool outside_tolerance(const input::SynMotionEvent & ev, int tolerance):
     return std::abs(ev.x - prev_ev.x) > tolerance || std::abs(ev.y - prev_ev.y) > tolerance
  ;

  class GESTURE_EVENTS_DELEGATE:
    private:
    std::unique_ptr<GESTURE_EVENTS> gestures;
    MOUSE_EVENTS * mouse;

    template<MOUSE_EVENT GESTURE_EVENTS::*MEM>
    struct event_delegate:
      GESTURE_EVENTS_DELEGATE * parent;

      MOUSE_EVENT & get():
        if !parent->gestures:
          parent->gestures = std::make_unique<GESTURE_EVENTS>()
          parent->gestures->attach(parent->mouse)
        return (*parent->gestures).*MEM

      void operator+=(std::function<void(input::SynMotionEvent &)> f):
        get() += f

      void clear():
        if parent->gestures:
          get().clear()

      bool empty():
        return !parent->gestures || get().empty()
    ;

    public:
    GESTURE_EVENTS_DELEGATE(MOUSE_EVENTS * mouse): mouse(mouse):
      pass

    event_delegate<&GESTURE_EVENTS::long_press>   long_press   = { this }
    event_delegate<&GESTURE_EVENTS::single_click> single_click = { this }
    event_delegate<&GESTURE_EVENTS::double_click> double_click = { this }
    event_delegate<&GESTURE_EVENTS::drag_start>   drag_start   = { this }
    event_delegate<&GESTURE_EVENTS::dragging>     dragging     = { this }
    event_delegate<&GESTURE_EVENTS::drag_end>     drag_end     = { this }
  ;
