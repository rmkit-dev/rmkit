#include <linux/input.h>
#include "../defines.h"
#include "../util/rm2fb.h"
#include "../util/rotate.h"
#include "../fb/fb_info.h"

//#define DEBUG_INPUT_EVENT 1
//#define DEBUG_INPUT_INIT 1
namespace input:
  extern int next_id = 1234

  class Event:
    public:
    unsigned int id
    Event():
      self.id = next_id++

    def update(input_event data):
      pass

    def print_event(input_event &data):
      #ifdef DEBUG_INPUT_EVENT
      fprintf(stderr, "Event: time %ld, type: %x, code :%x, value %d\n", \
        data.time.tv_sec, data.type, data.code, data.value)
      #endif
      return

    virtual void initialize():
      pass

    virtual void finalize():
      pass

    virtual ~Event() = default


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

    def marshal():
      SynKeyEvent key_ev
      key_ev.key = self.key
      key_ev.is_pressed = self.is_pressed
      return key_ev


  class TouchEvent: public Event:
    public:
    int x=-1, y=-1
    int slot = 0, left = -1
    bool lifted=false

    static int MAX_SLOTS = 10
    static int MIN_PALM_SIZE = 10
    static bool DEBUG_PALM_SIZE = false
    struct TouchPoint:
      int x=-1, y=-1, left=-1
      int size_major=1, size_minor=1
    ;

    static float scale_x=1.0
    static float scale_y=1.0
    static int swap_xy=false
    static int invert_x=false
    static int invert_y=false
    static void set_extents(int w, h, dw, dh):
      #ifdef DEV
      scale_x = MT_X_SCALAR
      scale_y = MT_Y_SCALAR
      return
      #endif

      scale_x = float(dw) / float(w)
      scale_y = float(dh) / float(h)
      #ifdef DEBUG_INPUT_INIT
      debug "TW, TH:", w, h
      debug "SET SCALING TO", scale_x, scale_y
      #endif


    // kobo libra rot0: swap_xy, invert_x
    // kobo libra rot180: swap_xy, invert_y
    // rm1: scale_x, scale_y, invert_x, invert_y
    // rm2: invert_y
    vector<TouchPoint> slots;
    TouchEvent():
      slots.resize(MAX_SLOTS)
      set_rotation()

    static void set_rotation():
      #if defined(REMARKABLE) | defined(DEV)
      // rM1
      invert_y = true
      if not rm2fb::IN_RM2FB_SHIM:
        invert_x = true
      #elif KOBO

      version := util::get_kobo_version()
      rotation := util::rotation::get()
      invert_y = false
      invert_x = false
      swap_xy = false
      switch version:
        case util::KOBO_DEVICE_ID_E::DEVICE_KOBO_CLARA_HD:
          rotation++
          rotation %= 4
          invert_x = true
          swap_xy = true
          break
        case util::KOBO_DEVICE_ID_E::DEVICE_KOBO_LIBRA_H2O:
          invert_x = true
          swap_xy = true
          break
        default:
          break

      if rotation == util::rotation::ROT90:
        swap_xy = !swap_xy
        invert_x = !invert_x

      if rotation == util::rotation::ROT180:
        invert_x = !invert_x
        invert_y = !invert_x

      if rotation == util::rotation::ROT270:
        swap_xy = !swap_xy
        invert_y = !invert_y

      #endif

    void initialize():
      self.lifted = false

    handle_key(input_event data):
      switch data.code:
        case BTN_TOOL_FINGER:
        case BTN_TOUCH:
        case BTN_TOOL_PEN:
          if data.value == 0:
            self.lifted = true
            self.left = 0
          break

    handle_abs(input_event data):
      if swap_xy:
        if data.code == ABS_MT_POSITION_X:
          data.code = ABS_MT_POSITION_Y
        else if data.code == ABS_MT_POSITION_Y:
          data.code = ABS_MT_POSITION_X

      switch data.code:
        case ABS_MT_SLOT:
          slot = data.value;
          break
        case ABS_MT_POSITION_X:
          if invert_x:
            slots[slot].x = framebuffer::fb_info::display_width - data.value*scale_x
          else:
            slots[slot].x = data.value * scale_x
          if self.first_used_slot() == slot:
            self.x = slots[slot].x
          break
        case ABS_MT_POSITION_Y:
          if invert_y:
            slots[slot].y = framebuffer::fb_info::display_height - data.value*scale_y
          else:
            slots[slot].y = data.value * scale_y
          if self.first_used_slot() == slot:
            self.y = slots[slot].y
          break
        case ABS_MT_TRACKING_ID:
          if slot >= 0:
            slots[slot].left = self.left = data.value > -1
            if self.left == 0:
              self.lifted = true

          break
        case ABS_MT_TOUCH_MAJOR:
          slots[slot].size_major = data.value
          break
        case ABS_MT_TOUCH_MINOR:
          slots[slot].size_minor = data.value
          break

    int max_touch_area():
      size := 0
      for i := 0; i <= MAX_SLOTS; i++:
        if slots[i].left == 1:
          if slots[i].size_minor == 1:
            size = max(slots[i].size_major, size)
          else:
            size = max(slots[i].size_minor, size)
      return size

    bool is_palm():
      #ifndef REMARKABLE
      return false
      #endif


      size := max_touch_area()
      version := util::get_remarkable_version()

      if version == util::RM_DEVICE_ID_E::RM2:
        size /= 2

      if DEBUG_PALM_SIZE:
        debug "TOUCH AREA", size, (size > MIN_PALM_SIZE ? "palm" : "finger")
      return size > MIN_PALM_SIZE

    def marshal():
      SynMotionEvent syn_ev;

      syn_ev.left = self.left
      syn_ev.x = self.x
      syn_ev.y = self.y

      syn_ev.set_original(new TouchEvent(*self))

      return syn_ev

    def update(input_event data):
      self.print_event(data)
      switch data.type:
        case 1:
          self.handle_key(data)
        case 3:
          self.handle_abs(data)

    inline int count_fingers():
      fingers := 0
      for i := 0; i < MAX_SLOTS; i++:
        if slots[i].left == 1:
          fingers++

      return fingers

    inline int first_used_slot():
      for i := 0; i < MAX_SLOTS; i++:
        if slots[i].left > 0:
          return i
      return -1

    def is_multitouch():
      fingers := self.count_fingers()

      if fingers > 1:
        return true

      if fingers == 0:
        return false


  class WacomEvent: public Event:
    public:
    int x = -1, y = -1, pressure = -1
    int tilt_x = 0xFFFF, tilt_y = 0xFFFF
    int btn_touch = -1
    int eraser = -1

    // rM has swapped axis and inverted y by default
    static float scale_x=1.0
    static float scale_y=1.0
    int swap_xy=false, invert_x=false, invert_y=false
    static void set_extents(int w, h, dw, dh):
      #ifdef DEV
      scale_x = WACOM_X_SCALAR
      scale_y = WACOM_Y_SCALAR
      return
      #endif
      scale_x = float(dw) / float(w)
      scale_y = float(dh) / float(h)
      #ifdef DEBUG_INPUT_INIT
      debug "WW, WH:", w, h
      debug "SET SCALING TO", scale_x, scale_y
      #endif

    WacomEvent():
      #if defined(REMARKABLE) | defined(DEV)
      swap_xy = true
      invert_y = true
      #endif

    def marshal():
      SynMotionEvent syn_ev;
      syn_ev.x = self.x
      syn_ev.y = self.y

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
      #if defined(REMARKABLE) | defined(DEV)
      if swap_xy:
        if data.code == ABS_X:
          data.code = ABS_Y
        else if data.code == ABS_Y:
          data.code = ABS_X

      switch data.code:
        case ABS_Y:
          if invert_y:
            self.y = framebuffer::fb_info::display_height - data.value * scale_y
          else:
            self.y = data.value * scale_y
          break
        case ABS_X:
          if invert_x:
            self.x = framebuffer::fb_info::display_width - data.value * scale_x
          else:
            self.x = data.value * scale_x
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
      #endif
      return

    update(input_event data):
      self.print_event(data)
      switch data.type:
        case 1:
          self.handle_key(data)
        case 3:
          self.handle_abs(data)
