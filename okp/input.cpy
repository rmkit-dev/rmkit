#ifndef INPUT_CPY
#include <fcntl.h>
#include <unistd.h>
#include <sys/select.h>
#include <linux/input.h>

#include "defines.h"

using namespace std

// #define DEBUG_INPUT_EVENT 0

class Event:
  public:
  def update(input_event data)
  def print_event(input_event data):
    #ifdef DEBUG_INPUT_EVENT
    printf("Event: time %ld, type: %x, code :%x, value %d\n", \
      data.time.tv_sec, data.type, data.code, data.value)
    #endif
    return

  virtual ~Event() = default

class SynEvent: public Event:
  public:
  int x, y, left, right, middle
  shared_ptr<Event> original
  SynEvent(){}

  def set_original(Event *ev):
    self.original = shared_ptr<Event>(ev)


class ButtonEvent: public Event:
  public:
  ButtonEvent() {}
  def update(input_event data):
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

class Input:
  private:

  public:
  int mouse_fd, wacom_fd, touch_fd, gpio_fd, bytes, max_fd
  int mouse_x, mouse_y
  int wacom_btn_touch = 0
  unsigned char data[3]
  input_event ev_data[64]
  fd_set rdfs
  static FB *fb

  vector<WacomEvent> wacom_events
  vector<MouseEvent> mouse_events
  vector<TouchEvent> touch_events
  vector<ButtonEvent> button_events
  vector<SynEvent> all_events

  Input():
    printf("Initializing input\n")
    FD_ZERO(&rdfs)

    self.mouse_x = 0
    self.mouse_y = 0

    // dev only
    self.monitor(mouse_fd = open("/dev/input/mice", O_RDONLY))
    // used by remarkable
    self.monitor(wacom_fd = open("/dev/input/event0", O_RDONLY))
    self.monitor(touch_fd = open("/dev/input/event1", O_RDONLY))
    self.monitor(gpio_fd = open("/dev/input/event2", O_RDONLY))

    printf("FDs MOUSE %i WACOM %i TOUCH %i GPIO %i\n", mouse_fd, wacom_fd, touch_fd, gpio_fd)


  ~Input():
    close(mouse_fd)
    close(wacom_fd)
    close(touch_fd)
    close(gpio_fd)

  void reset_events():
    wacom_events.clear()
    mouse_events.clear()
    touch_events.clear()
    button_events.clear()
    all_events.clear()

  void monitor(int fd):
    FD_SET(fd,&rdfs)
    max_fd = max(max_fd, fd+1)

  // not going to use this on remarkable
  void handle_mouse():
$   bytes = read(mouse_fd, data, sizeof(data));

    #ifdef REMARKABLE
    // we return after reading so that the socket is not indefinitely active
    return
    #endif

    ev = MouseEvent()
    if bytes > 0:
      ev.left = data[0]&0x1
      ev.right = data[0]&0x2
      ev.middle = data[0]&0x4
      ev.x = data[1]
      ev.y = data[2]
      self.mouse_events.push_back(ev)

  template<class T>
  void handle_input_event(int fd, vector<T> &events):
$   bytes = read(fd, ev_data, sizeof(input_event) * 64);
    if bytes < sizeof(struct input_event) || bytes == -1:
      return

    T event
    for int i = 0; i < bytes / sizeof(struct input_event); i++:
      if ev_data[i].type == EV_SYN:
        events.push_back(event)
        #ifdef DEBUG_INPUT_EVENT
        printf("\n")
        #endif
        event = {} // clear the event?
      else:
        event.update(ev_data[i])

    pass


  def marshal_touch(TouchEvent ev):
    SynEvent syn_ev;
    syn_ev.x = ev.x
    syn_ev.y = ev.y
    syn_ev.left = 1
    syn_ev.set_original(new TouchEvent(ev))

    self.all_events.push_back(syn_ev)


  // TODO: these marshalrs should be somewhere else, not in the App class,
  // maybe in input.cpy. They need access to FB though
  def marshal_wacom(WacomEvent ev):
    SynEvent syn_ev;
    syn_ev.x = ev.x
    syn_ev.y = ev.y

    if ev.btn_touch != -1:
      self.wacom_btn_touch = ev.btn_touch

    syn_ev.left = self.wacom_btn_touch
    syn_ev.right = !self.wacom_btn_touch
    syn_ev.set_original(new WacomEvent(ev))
    self.all_events.push_back(syn_ev)

  def marshal_mouse(MouseEvent ev):
    self.mouse_x += ev.x
    self.mouse_y += ev.y

    if self.mouse_y < 0:
      self.mouse_y = 0
    if self.mouse_x < 0:
      self.mouse_x = 0

    if self.mouse_y >= self.fb->height - 1:
      self.mouse_y = (int) self.fb->height - 5

    if self.mouse_x >= self.fb->width - 1:
      self.mouse_x = (int) self.fb->width - 5

    o_x = self.mouse_x
    o_y = self.fb->height - self.mouse_y

    if o_y >= self.fb->height - 1:
      o_y = self.fb->height - 5

    SynEvent syn_ev;
    syn_ev.x = o_x
    syn_ev.y = o_y
    syn_ev.left = ev.left
    syn_ev.right = ev.right
    syn_ev.set_original(new MouseEvent(ev))

    self.all_events.push_back(syn_ev)

  // wacom = pen. naming comes from libremarkable
  void handle_wacom():
    self.handle_input_event<WacomEvent>(self.wacom_fd, self.wacom_events)

  void handle_touchscreen():
    self.handle_input_event<TouchEvent>(self.touch_fd, self.touch_events)

  void handle_gpio():
    self.handle_input_event<ButtonEvent>(self.gpio_fd, self.button_events)

  def listen_all():
    fd_set rdfs_cp
    int retval
    self.reset_events()

    rdfs_cp = rdfs

    retval = select(max_fd, &rdfs_cp, NULL, NULL, NULL)
    if retval > 0:
      if FD_ISSET(mouse_fd, &rdfs_cp):
        self.handle_mouse()
      if FD_ISSET(wacom_fd, &rdfs_cp):
        self.handle_wacom()
      if FD_ISSET(touch_fd, &rdfs_cp):
        self.handle_touchscreen()
      if FD_ISSET(gpio_fd, &rdfs_cp):
        self.handle_gpio()

    for auto ev : self.wacom_events:
      self.marshal_wacom(ev)

    for auto ev : self.mouse_events:
      self.marshal_mouse(ev)

    for auto ev : self.touch_events:
      self.marshal_touch(ev)

    if retval < 0:
      print "oops, select broke"
      exit(1)

  static WacomEvent* is_wacom_event(SynEvent &syn_ev):
    return dynamic_cast<WacomEvent*>(syn_ev.original.get())
  static MouseEvent* is_mouse_event(SynEvent &syn_ev):
    return dynamic_cast<MouseEvent*>(syn_ev.original.get())
  static TouchEvent* is_touch_event(SynEvent &syn_ev):
    return dynamic_cast<TouchEvent*>(syn_ev.original.get())

FB* Input::fb = NULL
#endif
