#include <fcntl.h>
#include <unistd.h>
#include <sys/select.h>
#include <linux/input.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>

#include "../defines.h"
#include "../fb/fb_info.h"
#include "events.h"
#include "gestures.h"
#include "device_id.h"

using namespace std

extern bool USE_RESIM = true

// #define DEBUG_MOUSE_EVENT
// #define DEBUG_INPUT_EVENT 1
namespace input:
  extern int ipc_fd[2] = { -1, -1 };
  extern bool CRASH_ON_BAD_DEVICE = (getenv("RMKIT_CRASH_ON_BAD_DEVICE") != NULL)

  class IInputClass:
    public:
    int fd = 0
    bool reopen = false

  template<class T, class EV>
  class InputClass : public IInputClass:
    public:
    input_event ev_data[64]
    T prev_ev, event
    vector<T> events
    bool syn_dropped = false

    InputClass():
      pass

    clear():
      self.events.clear()

    def marshal(T &ev):
      return ev.marshal()

    void unlock():
      ioctl(fd, EVIOCGRAB, false)

    void lock():
      ioctl(fd, EVIOCGRAB, true)

    void set_fd(int _fd):
      fd = _fd
      T::set_fd(fd)

    bool supports_stylus():
      return input::supports_stylus(fd)



    int handle_event_fd():
      int bytes = read(fd, ev_data, sizeof(input_event) * 64);
      if bytes == -1:
        debug "ERRNO", errno, strerror(errno)
      if bytes < sizeof(input_event) || bytes == -1:
        if errno == ENODEV:
          self.reopen = true
        return bytes

      #ifndef DEV
      // in DEV mode we allow event coalescing between calls to read() for
      // resim normally evdev will do one full event per read() call instead of
      // splitting across multiple read() calls
      T event = prev_ev
      #endif
      event.initialize()

      for int i = 0; i < bytes / sizeof(input_event); i++:
//        debug fd, "READ EVENT", ev_data[i].type, ev_data[i].code, ev_data[i].value
        if ev_data[i].type == EV_SYN:
          if ev_data[i].code == SYN_DROPPED:
            syn_dropped = true
            event.handle_drop(fd)
            continue

          syn_dropped = false
          event.finalize()
          events.push_back(event)
          #ifdef DEBUG_INPUT_EVENT
          fprintf(stderr, "\n")
          #endif
          prev_ev = event
          event.initialize()
        else:
          if !syn_dropped:
            event.update(ev_data[i])

      return 0

  class Input:
    private:

    public:
    int max_fd
    fd_set rdfs
    bool has_stylus

    InputClass<WacomEvent, SynMotionEvent> wacom
    InputClass<TouchEvent, SynMotionEvent> touch
    InputClass<ButtonEvent, SynKeyEvent> button

    vector<SynMotionEvent> all_motion_events
    vector<SynKeyEvent> all_key_events

    Input():
      open_devices()

    void open_devices():
      close_devices()
      FD_ZERO(&rdfs)
      // dev only
      // used by remarkable
      #ifdef REMARKABLE
      self.open_device("/dev/input/event0")
      self.open_device("/dev/input/event1")
      self.open_device("/dev/input/event2")
      self.open_device("/dev/input/event3")
      self.open_device("/dev/input/event4")
      #elif KOBO
      self.open_device("/dev/input/event0")
      self.open_device("/dev/input/event1")
      self.open_device("/dev/input/event2")
      self.open_device("/dev/input/event3")
      self.open_device("/dev/input/event4")
      #else
      if USE_RESIM:
        debug "MONITORING RESIM"
        self.monitor(self.wacom.fd = open("./event0", O_RDWR))
        self.monitor(self.touch.fd = open("./event1", O_RDWR))
        self.monitor(self.button.fd = open("./event2", O_RDWR))
      #endif

      #ifdef DEV_KBD
      if !USE_RESIM:
        self.monitor(self.button.fd = open(DEV_KBD, O_RDONLY))
      #endif

      if ipc_fd[0] == -1:
        socketpair(AF_UNIX, SOCK_STREAM, 0, ipc_fd)

      self.monitor(input::ipc_fd[0])
      self.set_scaling(framebuffer::fb_info::display_width, framebuffer::fb_info::display_height)
      self.has_stylus = supports_stylus()
      return

    void close_devices():
      vector<IInputClass> fds = { self.touch, self.wacom, self.button}
      for auto in : fds:
        if in.fd > 0:
          close(in.fd)

    ~Input():
      close_devices()

    void open_device(string fname):
      fd := open(fname.c_str(), O_RDWR)
      if fd == -1:
        debug "ERROR OPENING INPUT DEVICE", fname
        return

      debug "OPENING", fname,
      switch input::id_by_capabilities(fd):
        case STYLUS:
          self.wacom.set_fd(fd)
          debug "AS WACOM"
          break
        case BUTTONS:
          self.button.set_fd(fd)
          debug "AS BUTTONS"
          break
        case TOUCH:
          self.touch.set_fd(fd)
          debug "AS TOUCH"
          break
        case INVALID:
        case UNKNOWN:
        default:
          debug ": UNKNOWN EVENT DEVICE"
          close(fd)
          if CRASH_ON_BAD_DEVICE:
            exit(1)
          return

      self.monitor(fd)

    // adapted from https://www.linuxjournal.com/files/linuxjournal.com/linuxjournal/articles/064/6429/6429l17.html
    // NOTE: we assume that we only need max value from here and its anchored at 0,
    // this may not be true in the future
    tuple<struct input_absinfo, struct input_absinfo> read_extents(int fd, x_id, y_id):
      uint8_t abs_b[ABS_MAX/8 + 1] = {0}
      struct input_absinfo abs_feat
      abs_bit := EVIOCGBIT(EV_ABS, sizeof(abs_b))
      ioctl(fd, abs_bit, abs_b)

      struct input_absinfo x_feat, y_feat
      if (ioctl(fd, EVIOCGABS(x_id), &x_feat)):
        perror("evdev EVIOCGABS ioctl");
      if (ioctl(fd, EVIOCGABS(y_id), &y_feat)):
        perror("evdev EVIOCGABS ioctl");

      if x_feat.maximum < y_feat.maximum:
        return x_feat, y_feat
      return y_feat, x_feat

    void set_scaling(int display_width, int display_height):
      if self.wacom.fd > 0:
        xf, yf := self.read_extents(self.wacom.fd, ABS_X, ABS_Y)
        if display_width < display_height:
          WacomEvent::set_extents(xf.maximum, yf.maximum, display_width, display_height)
        else:
          WacomEvent::set_extents(xf.maximum, yf.maximum, display_height, display_width)

      if self.touch.fd > 0:
        xf, yf := self.read_extents(self.touch.fd, ABS_MT_POSITION_X, ABS_MT_POSITION_Y)
        if display_width < display_height:
          TouchEvent::set_extents(xf.maximum, yf.maximum, display_width, display_height)
        else:
          TouchEvent::set_extents(xf.maximum, yf.maximum, display_height, display_width)
      return


    void reset_events():
      self.wacom.clear()
      self.touch.clear()
      self.button.clear()

      all_motion_events.clear()
      all_key_events.clear()

    void monitor(int fd):
      FD_SET(fd,&rdfs)
      max_fd = max(max_fd, fd+1)

    void unmonitor(int fd):
      FD_CLR(fd, &rdfs)

    def handle_ipc():
      char buf[1024];
      int bytes = read(input::ipc_fd[0], buf, 1024);

      return

    void grab():
      #ifndef REMARKABLE
      return
      #endif
      for auto fd : { self.touch.fd, self.wacom.fd, self.button.fd }:
        ioctl(fd, EVIOCGRAB, true)

    void ungrab():
      #ifndef REMARKABLE
      return
      #endif
      for auto fd : { self.touch.fd, self.wacom.fd, self.button.fd }:
        ioctl(fd, EVIOCGRAB, false)

    void check_reopen():
      vector<IInputClass*> inputs = { &self.wacom, &self.touch, &self.button }
      needs_reopen := false
      for auto in : inputs:
        if in->reopen:
          needs_reopen = true
          break

      if needs_reopen:
        self.open_devices()

      for auto in : inputs:
        in->reopen = false

    void listen_all(long timeout_ms = 0):
      fd_set rdfs_cp
      int retval
      self.reset_events()

      rdfs_cp = rdfs

      #ifdef DEV
      timeout_ms = 1000
      #endif

      if timeout_ms > 0:
          struct timeval tv = {timeout_ms / 1000, (timeout_ms % 1000) * 1000}
          retval = select(max_fd, &rdfs_cp, NULL, NULL, &tv)
      else:
          retval = select(max_fd, &rdfs_cp, NULL, NULL, NULL)


      // TODO: refactor this a bit so that the error handling is cleaner
      // and we only re-open the specific device that fail
      if retval > 0:
        if FD_ISSET(self.wacom.fd, &rdfs_cp):
          self.wacom.handle_event_fd()
        if FD_ISSET(self.touch.fd, &rdfs_cp):
          self.touch.handle_event_fd()
        if FD_ISSET(self.button.fd, &rdfs_cp):
          self.button.handle_event_fd()
        if FD_ISSET(input::ipc_fd[0], &rdfs_cp):
          self.handle_ipc()

        self.check_reopen()

      for auto ev : self.wacom.events:
        self.all_motion_events.push_back(self.wacom.marshal(ev))


      for auto ev : self.touch.events:
        self.all_motion_events.push_back(self.touch.marshal(ev))

      for auto ev : self.button.events:
        self.all_key_events.push_back(self.button.marshal(ev))

      #ifdef DEBUG_MOUSE_EVENT
      for auto syn_ev : self.all_motion_events:
        debug "SYN MOUSE", syn_ev.x, syn_ev.y, syn_ev.pressure, syn_ev.left, syn_ev.eraser
      #endif
      return

    bool supports_stylus():
      return wacom.supports_stylus() || touch.supports_stylus()

  // TODO: should we just put this in the SynMotionEvent?
  static WacomEvent* is_wacom_event(SynMotionEvent &syn_ev):
    return dynamic_cast<WacomEvent*>(syn_ev.original.get())
  static TouchEvent* is_touch_event(SynMotionEvent &syn_ev):
    evt := dynamic_cast<TouchEvent*>(syn_ev.original.get())
    if evt != nullptr && evt->is_touch():
      return evt
    return nullptr

