#include <cmath>

#include "../fb/fb_info.h"
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

  class WidgetGestureEvent : public input::SynMotionEvent
    public:
    bool is_long_press = false;
    WidgetGestureEvent(const input::SynMotionEvent & ev, bool is_long_press=false) \
        : input::SynMotionEvent(ev), is_long_press(is_long_press):
      pass
  ;

  PLS_DEFINE_SIGNAL(WIDGET_GESTURE_EVENT, WidgetGestureEvent)

  class GESTURE_EVENTS:
    public:

    WIDGET_GESTURE_EVENT long_press
    WIDGET_GESTURE_EVENT single_click
    WIDGET_GESTURE_EVENT double_click
    WIDGET_GESTURE_EVENT drag_start
    WIDGET_GESTURE_EVENT dragging
    WIDGET_GESTURE_EVENT drag_end

    // The threshold that determines if this is a touch-based gesture (e.g.
    // long_press, double_click) or a motion-based gesture (e.g. drag). For
    // touch-based gestures, the x and y deltas are always < this value; once
    // the x or y delta > this value, it is considered a motion-based gesture.
    int touch_threshold = 50

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

    // == State machine ==
    // Possible state transition sequences

    // click events
    // without a double_click handler
    //   DOWN -> UP = single_click
    // with a double_click handler
    //   DOWN -> UP -> WAIT_DOUBLE_CLICK -> (timeout)         = single_click
    //   DOWN -> UP -> WAIT_DOUBLE_CLICK -> SECOND_DOWN -> UP = double_click

    // drag events
    //   DOWN -> (move) -> DRAGGING -> UP/LEAVE = drag_start + dragging + drag_end

    // long_press events
    //   DOWN -> (timeout) = long_press
    //   (from long_press) -> LONG_DOWN -> (move) -> DRAGGING -> UP/LEAVE = drag events

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
          case SECOND_DOWN: return SECOND_DOWN_move(ev)
          case LONG_DOWN:   return LONG_DOWN_move(ev)
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
    enum STATE { IDLE, DOWN, DRAGGING, WAIT_DOUBLE_CLICK, SECOND_DOWN, LONG_DOWN }
    STATE state = IDLE
    bool is_long_press = false

    inline void IDLE_down(input::SynMotionEvent &ev):
      reset()
      state = DOWN
      prev_ev = ev
      if not long_press.empty():
        long_press_timer = ui::set_timeout([=]() {
          auto ev_copy = ev
          is_long_press = true
          dispatch(long_press, ev_copy)
          // set up LONG_DOWN
          prev_ev = ev_copy
          state = LONG_DOWN
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
      if outside_tolerance(ev, touch_threshold):
        state = DRAGGING
        cancel_long_press()
        dispatch(drag_start, prev_ev)
        prev_ev = ev

    inline void LONG_DOWN_move(input::SynMotionEvent &ev):
      // DOWN_move just checks if we're ready to switch to drag, which is all
      // we need to do in LONG_DOWN as well. This LONG_DOWN_move handler is
      // only here in case we add more gestures and the state transition ends
      // up needing to be different.
      DOWN_move(ev)

    inline void WAIT_DOUBLE_CLICK_down(input::SynMotionEvent &ev):
      if outside_tolerance(ev, touch_threshold):
        // We were waiting for a double_click, but the second down event
        // happened far away from the previous click. This should trigger:
        // (1) the previous single click (at the previous position)
        finish(single_click, prev_ev)
        // (2) a new down event from IDLE
        state = IDLE
        IDLE_down(ev)
      else:
        // otherwise we got the second down event, and just need one more up
        // event to make this a double_click
        state = SECOND_DOWN
        cancel_single_click()
        prev_ev = ev

    inline void SECOND_DOWN_move(input::SynMotionEvent &ev):
      if outside_tolerance(ev, touch_threshold):
        // We were waiting for a double_click, but moved too far from the
        // second down event. This should trigger:
        // (1) the previously canceled single click
        dispatch(single_click, prev_ev)
        // (2) a new move event from DOWN
        state = DOWN
        DOWN_move(ev)
      // otherwise we're still waiting for an up event to trigger double_click

    inline void DRAGGING_move(input::SynMotionEvent &ev):
      if outside_tolerance(ev, dragging_step_size):
        dispatch(dragging, ev)
        prev_ev = ev

    // helpers
    void reset():
      cancel_long_press()
      cancel_single_click()
      is_long_press = false
      state = IDLE

    inline void dispatch(WIDGET_GESTURE_EVENT & handler, input::SynMotionEvent & syn_ev):
      WidgetGestureEvent ev(syn_ev, is_long_press);
      handler(ev)

    inline void finish(WIDGET_GESTURE_EVENT & handler, input::SynMotionEvent & ev):
      dispatch(handler, ev)
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

    GESTURE_EVENTS & get():
      if !self.gestures:
        self.gestures = std::make_unique<GESTURE_EVENTS>()
        self.gestures->attach(self.mouse)
      return *self.gestures

    template<WIDGET_GESTURE_EVENT GESTURE_EVENTS::*MEM>
    struct event_delegate:
      GESTURE_EVENTS_DELEGATE * parent;

      WIDGET_GESTURE_EVENT & get():
        return parent->get().*MEM

      void operator+=(std::function<void(WidgetGestureEvent &)> f):
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

    void set_touch_threshold(int val):
      get().touch_threshold = val
    void set_dragging_step_size(int val):
      get().dragging_step_size = val
    void set_long_press_timeout(long val):
      get().long_press_timeout = val
    void set_double_click_timeout(long val):
      get().double_click_timeout = val
  ;
