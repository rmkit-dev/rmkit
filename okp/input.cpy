#ifndef INPUT_CPY
#include <fcntl.h>
#include <unistd.h>
#include <sys/select.h>
#include <linux/input.h>

#include "defines.h"

using namespace std

class Event:
  public:
  def update(input_event data)
  def print_event(input_event data):
    printf("Event: time %ld, type: %x, code :%x, value %d\n", \
      data.time.tv_sec, data.type, data.code, data.value)


class ButtonEvent: Event:
  public:
  ButtonEvent() {}
  def update(input_event data):
    self.print_event(data)

class TouchEvent: Event:
  public:
  TouchEvent() {}
  def update(input_event data):
    self.print_event(data)

class MouseEvent: Event:
  public:
  MouseEvent() {}
  signed char x, y
  int left, right, middle
  def update(input_event data):
    self.print_event(data)

class WacomEvent: Event:
  public:
  int x, y, pressure
  bool pen, eraser, button

  handle_key(input_event data):
    pass

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
  unsigned char data[3]
  input_event ev_data[64]
  fd_set rdfs

  vector<WacomEvent> wacom_events
  vector<MouseEvent> mouse_events
  vector<TouchEvent> touch_events
  vector<ButtonEvent> button_events

  Input():
    printf("Initializing input\n")
    FD_ZERO(&rdfs)

    // dev only
    self.monitor(mouse_fd = open("/dev/input/mouse0", O_RDONLY))
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

  void monitor(int fd):
    FD_SET(fd,&rdfs)
    max_fd = max(max_fd, fd+1)

  // not going to use this on remarkable
  void handle_mouse():
    #ifdef REMARKABLE
    return
    #endif
$   bytes = read(mouse_fd, data, sizeof(data));
    ev = MouseEvent()
    if bytes > 0:
      ev.left = data[0]&0x1
      ev.right = data[0]&0x2
      ev.middle = data[0]&0x4
      ev.x = data[1]
      ev.y = data[2]
      printf("x=%d, y=%d, left=%d, middle=%d, right=%d\n", ev.x, ev.y, ev.left, ev.middle, ev.right)
      self.mouse_events.push_back(ev)

  template<class T>
  void handle_input_event(int fd, vector<T> &events):
$   bytes = read(self.wacom_fd, ev_data, sizeof(input_event) * 64);
    if bytes < sizeof(struct input_event) || bytes == -1:
      return

    T event
    for int i = 0; i < bytes / sizeof(struct input_event); i++:
      if ev_data[i].type == EV_SYN:
        events.push_back(event)
        event = {} // clear the event?
      else:
        event.update(ev_data[i])

    pass

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

    if retval < 0:
      print "oops, select broke"
      exit(1)





#endif
