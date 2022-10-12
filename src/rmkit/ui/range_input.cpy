#include "widget.h"

namespace ui:
  // class: ui::RangeInput
  // --- Prototype ---
  // class ui::RangeInput: public ui::Widget:
  // -----------------
  class RangeInput: public ui::Widget:
    public:
    int low=0, high=100
    float percent=0.5
    PLS_DEFINE_SIGNAL(RANGEINPUT_EVENT, float)
    class RANGEINPUT_EVENTS:
      public:
      RANGEINPUT_EVENT change
      RANGEINPUT_EVENT done
    ;
    RANGEINPUT_EVENTS events

    // function: RangeInput
    // Parameters
    //
    // x - x
    // y - y
    // w - width
    // h - height
    RangeInput(int x, y, w, h): ui::Widget(x, y, w, h):
      pass

    void on_mouse_down(input::SynMotionEvent &ev):
      pass

    void on_mouse_up(input::SynMotionEvent &ev):
      self.events.done(self.percent)
      pass

    void on_mouse_move(input::SynMotionEvent &ev):
      if !ev.left:
        return

      self.percent = ((ev.x - self.x) / float(self.w))
      self.dirty = true
      self.events.change(self.percent)

    // function: set_range
    // sets the boundaries of the range input
    // Parameters
    //
    // l - the low value in the range
    // h = the high value of the range
    void set_range(int l, h):
      self.low = l
      self.high = h

    void set_value(int value):
       self.percent = (value - self.low) / float(self.high - self.low)

    int get_value():
      return self.percent * (self.high - self.low) + self.low

    void render():
      self.fb->draw_rect(self.x-5, self.y, self.w+10, self.h, WHITE, 1 /* fill */)
      self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, 0 /* fill */)

      offset := self.percent * self.w
      self.fb->draw_rect(self.x + offset - 5, self.y, 10, self.h, BLACK, 1 /* fill */)

      self.fb->draw_text(self.x, self.y, to_string(int(self.get_value())), 32)
