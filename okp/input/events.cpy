//#define DEBUG_INPUT_EVENT 1

namespace input:
  class Event:
    public:
    def update(input_event data)
    def print_event(input_event &data):
      #ifdef DEBUG_INPUT_EVENT
      printf("Event: time %ld, type: %x, code :%x, value %d\n", \
        data.time.tv_sec, data.type, data.code, data.value)
      #endif
      return

    def finalize():
      pass

    virtual ~Event() = default

  class SynEvent: public Event:
    public:
    int x, y, left, right, middle
    Event *original
    SynEvent(){}

    def set_original(Event *ev):
      self.original = ev

  class KeyEvent: public Event:
    public:
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

  class TouchEvent: public Event:
    public:
    int x, y, left
    TouchEvent() {}

    handle_abs(input_event data):
      switch data.code:
        case ABS_MT_POSITION_X:
          self.x = (MTWIDTH - data.value)*MT_X_SCALAR
          break
        case ABS_MT_POSITION_Y:
          self.y = (MTHEIGHT - data.value)*MT_Y_SCALAR
          break
        case ABS_MT_TRACKING_ID:
          self.left = data.value > -1
          break


    def update(input_event data):
      self.print_event(data)
      switch data.type:
        case 3:
          self.handle_abs(data)

  class MouseEvent: public Event:
    public:
    MouseEvent() {}
    signed char x, y
    int left, right, middle
    def update(input_event data):
      self.print_event(data)

  class WacomEvent: public Event:
    public:
    int x = -1, y = -1, pressure = 0
    int btn_touch = -1
    bool pen, eraser, button


    handle_key(input_event data):
      switch data.code:
        case BTN_TOUCH:
          self.btn_touch = data.value
          break

    handle_abs(input_event data):
      switch data.code:
        case ABS_Y:
          self.x = data.value * WACOM_X_SCALAR
          break
        case ABS_X:
          self.y = (WACOMHEIGHT - data.value) * WACOM_Y_SCALAR
          break
        case ABS_PRESSURE:
          self.pressure = data.value

    update(input_event data):
      self.print_event(data)
      switch data.type:
        case 1:
          self.handle_key(data)
        case 3:
          self.handle_abs(data)

