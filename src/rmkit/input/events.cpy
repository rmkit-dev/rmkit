#include <linux/input.h>
#include "../defines.h"
#include "../util/rm2fb.h"

// #define DEBUG_INPUT_EVENT 1

namespace input:
  class Event:
    public:
    static int next_id
    unsigned int id
    Event():
      self.id = Event::next_id++

    def update(input_event data):
      pass

    def print_event(input_event &data):
      #ifdef DEBUG_INPUT_EVENT
      fprintf(stderr, "Event: time %ld, type: %x, code :%x, value %d\n", \
        data.time.tv_sec, data.type, data.code, data.value)
      #endif
      return

    def finalize():
      pass

    virtual ~Event() = default
  int Event::next_id = 0

  class SynEvent: public Event:
    public:
    bool _stop_propagation = false
    void stop_propagation():
      _stop_propagation = true
    shared_ptr<Event> original

    def set_original(Event *ev):
      self.original = shared_ptr<Event>(ev)

  /// class: input::SynMotionEvent
  /// A synthetic mouse event that covers
  /// mouse events, touch events and stylus events
  class SynMotionEvent: public SynEvent:
    public:
    int x = -1, y = -1
    // variables: SynMotionEvent
    // left - is left mouse button pressed or the stylus touching the screen
    // right - is the right mouse button pressed or the stylus hovering?
    // middle - is the middle mouse button down?
    // eraser - is the eraser button pressed
    // pressure - what's the pressure of the stylus on the screen
    // tilt_x - what's the tilt x of the stylus? can be up to 4096
    // tilt_y - what's the tilt y of the stylus? can be up to 4096
    int left = 0, right = 0, middle = 0
    int eraser = 0
    int pressure = -1, tilt_x = 0xFFFF, tilt_y = 0xFFFF


  // class: input::SynKeyEvent
  // This represents a button press, can be from keyboard
  // or from the hardware button on the remarkable
  class SynKeyEvent: public SynEvent:
    public:
    // variables: SynKeyEvent
    // key - which key is pressed? look at linux/input-event-codes.h to learn more
    // is_pressed - whether the button is pressed or unpressed
    int key, is_pressed

  class ButtonEvent: public Event:
    public:
    int key = -1, is_pressed = 0
    ButtonEvent() {}
    def update(input_event data):
      if data.type == EV_KEY:
        self.key = data.code
        self.is_pressed = data.value

      self.print_event(data)

    def marshal(ButtonEvent &prev):
      SynKeyEvent key_ev
      key_ev.key = self.key
      key_ev.is_pressed = self.is_pressed
      return key_ev


  class TouchEvent: public Event:
    public:
    int x, y, left
    int slot = 0
    struct Point:
      int x=-1, y=-1, left=-1
    ;
    vector<Point> slots;
    TouchEvent():
      slots.resize(10)

    TouchEvent(const TouchEvent &t):
      self.slot = t.slot
      self.slots = t.slots
      self.x = t.x
      self.y = t.y
      self.left = t.left


    handle_abs(input_event data):
      switch data.code:
        case ABS_MT_SLOT:
          slot = data.value;

        case ABS_MT_POSITION_X:
          if not rm2fb::IN_RM2FB_SHIM:
            slots[slot].x = (MTWIDTH - data.value)*MT_X_SCALAR
          else:
            slots[slot].x = data.value
          if slot == 0:
            self.x = slots[0].x
          break
        case ABS_MT_POSITION_Y:
          if not rm2fb::IN_RM2FB_SHIM:
            slots[slot].y = (MTHEIGHT - data.value)*MT_Y_SCALAR
          else:
            slots[slot].y = (DISPLAYHEIGHT - data.value)
          if slot == 0:
            self.y = slots[0].y
          break
        case ABS_MT_TRACKING_ID:
          slots[slot].left = self.left = data.value > -1
          break


    def marshal(TouchEvent &prev):
      SynMotionEvent syn_ev;
      syn_ev.left = self.left

      // if there's no left click, we re-use the last x,y coordinate
      if !self.left:
        syn_ev.x = prev.x
        syn_ev.y = prev.y
      else:
        syn_ev.x = self.x
        syn_ev.y = self.y

      self.x = syn_ev.x
      self.y = syn_ev.y
      syn_ev.set_original(new TouchEvent(*self))

      return syn_ev

    def update(input_event data):
      self.print_event(data)
      switch data.type:
        case 3:
          self.handle_abs(data)

  class MouseEvent: public Event:
    public:
    MouseEvent() {}
    int x = 0, y = 0
    signed char dx = 0, dy = 0
    int left = 0 , right = 0 , middle = 0
    static int width, height
    static int tilt_x
    static int tilt_y
    static int pressure


    static void set_screen_size(int w, h):
      width = w
      height = h

    def update(input_event data):
      self.print_event(data)

    def marshal(MouseEvent &prev):
      self.x = prev.x + self.dx
      self.y = prev.y + self.dy

      if self.y < 0:
        self.y = 0
      if self.x < 0:
        self.x = 0

      if self.y >= self.height - 1:
        self.y = (int) self.height - 5

      if self.x >= self.width - 1:
        self.x = (int) self.width - 5

      o_x := self.x
      o_y := self.height - self.y

      if o_y >= self.height - 1:
        o_y = self.height - 5

      SynMotionEvent syn_ev;
      syn_ev.x = o_x
      syn_ev.y = o_y
      syn_ev.left = self.left
      syn_ev.right = self.right
      syn_ev.pressure = MouseEvent::pressure
      syn_ev.tilt_x = MouseEvent::tilt_x
      syn_ev.tilt_y = MouseEvent::tilt_y

      syn_ev.set_original(new MouseEvent(*self))
      return syn_ev

  int MouseEvent::width = 0
  int MouseEvent::height = 0

  class WacomEvent: public Event:
    public:
    int x = -1, y = -1, pressure = -1
    int tilt_x = 0xFFFF, tilt_y = 0xFFFF
    int btn_touch = -1
    int eraser = -1

    def marshal(WacomEvent &prev):
      SynMotionEvent syn_ev;
      syn_ev.x = self.x
      syn_ev.y = self.y

      if self.btn_touch == -1:
        self.btn_touch = prev.btn_touch
      if self.eraser == -1:
        self.eraser = prev.eraser
      if self.pressure == -1 || self.pressure == 0:
        self.pressure = prev.pressure
      if self.tilt_x == 0xFFFF:
        self.tilt_x = prev.tilt_x
      if self.tilt_y == 0xFFFF:
        self.tilt_y = prev.tilt_y

      syn_ev.pressure = self.pressure
      syn_ev.tilt_x = self.tilt_x
      syn_ev.tilt_y = self.tilt_y
      syn_ev.left = self.btn_touch
      syn_ev.eraser = self.eraser
      syn_ev.set_original(new WacomEvent(*self))

      return syn_ev

    handle_key(input_event data):
      switch data.code:
        case BTN_TOUCH:
          self.btn_touch = data.value
          break
        case BTN_TOOL_RUBBER:
          self.eraser = data.value ? ERASER_RUBBER : 0
          break
        case BTN_STYLUS:
          self.eraser = data.value ? ERASER_STYLUS : 0
          break

    handle_abs(input_event data):
      switch data.code:
        case ABS_Y:
          self.x = data.value * WACOM_X_SCALAR
          break
        case ABS_X:
          self.y = (WACOMHEIGHT - data.value) * WACOM_Y_SCALAR
          break
        case ABS_TILT_X:
          self.tilt_x = data.value
          break
        case ABS_TILT_Y:
          self.tilt_y = data.value
          break
        case ABS_PRESSURE:
          self.pressure = data.value
          break

    update(input_event data):
      self.print_event(data)
      switch data.type:
        case 1:
          self.handle_key(data)
        case 3:
          self.handle_abs(data)

  int MouseEvent::pressure = 2000
  int MouseEvent::tilt_x = 0
  int MouseEvent::tilt_y = 0
