#include <fcntl.h>
#include <unistd.h>
#include <sys/select.h>
#include <linux/input.h>
#include <sys/types.h>
#include <sys/socket.h>

#include "../defines.h"
#include "events.h"

using namespace std

//#define DEBUG_INPUT_EVENT 1
namespace input:
  static int ipc_fd[2] = { -1, -1 };

  template<class T, class EV>
  class InputClass:
    public:
    int fd
    input_event ev_data[64]
    T prev_ev, event
    vector<T> events


    InputClass():
      last_ev = nullptr


    clear():
      self.events.clear()

    def marshal(T ev):
      EV syn_ev = ev.marshal(prev_ev)
      prev_ev = ev
      return syn_ev

    void handle_event_fd():
$     int bytes = read(fd, ev_data, sizeof(input_event) * 64);
      if bytes < sizeof(struct input_event) || bytes == -1:
        return

      T event
      for int i = 0; i < bytes / sizeof(struct input_event); i++:
        if ev_data[i].type == EV_SYN:
          event.finalize()
          events.push_back(event)
          #ifdef DEBUG_INPUT_EVENT
          printf("\n")
          #endif
          event = {} // clear the event?
        else:
          event.update(ev_data[i])

    // not going to use this on remarkable
    void handle_mouse_fd():
      unsigned char data[3]
  $   int bytes = read(self.fd, data, sizeof(data));

      #ifdef REMARKABLE
      // we return after reading so that the socket is not indefinitely active
      return
      #endif

      ev = T()
      if bytes > 0:
        ev.left = data[0]&0x1
        ev.right = data[0]&0x2
        ev.middle = data[0]&0x4
        ev.dx = data[1]
        ev.dy = data[2]
      self.events.push_back(ev)


  class Input:
    private:

    public:
    int max_fd
    fd_set rdfs

    InputClass<WacomEvent, SynMouseEvent> wacom
    InputClass<MouseEvent, SynMouseEvent> mouse
    InputClass<TouchEvent, SynMouseEvent> touch
    InputClass<ButtonEvent, SynKeyEvent> button

    vector<SynMouseEvent> all_motion_events
    vector<SynKeyEvent> all_key_events

    Input():
      printf("Initializing input\n")
      FD_ZERO(&rdfs)

      // dev only
      self.monitor(self.mouse.fd = open("/dev/input/mice", O_RDONLY))
      // used by remarkable
      #ifdef REMARKABLE
      self.monitor(self.wacom.fd = open("/dev/input/event0", O_RDONLY))
      self.monitor(self.touch.fd = open("/dev/input/event1", O_RDONLY))
      self.monitor(self.button.fd = open("/dev/input/event2", O_RDONLY))
      #endif

      #ifdef DEV_KBD
      self.monitor(self.button.fd = open(DEV_KBD, O_RDONLY))
      #endif

      if ipc_fd[0] == -1:
        socketpair(AF_UNIX, SOCK_STREAM, 0, ipc_fd)

      self.monitor(input::ipc_fd[0])
      return


    ~Input():
      close(self.mouse.fd)
      close(self.touch.fd)
      close(self.wacom.fd)
      close(self.button.fd)

    void reset_events():
      self.wacom.clear()
      self.mouse.clear()
      self.touch.clear()
      self.button.clear()

      all_motion_events.clear()
      all_key_events.clear()

    void monitor(int fd):
      FD_SET(fd,&rdfs)
      max_fd = max(max_fd, fd+1)

    def handle_ipc():
      char buf[1024];
      $ int bytes = read(input::ipc_fd[0], buf, 1024);

      return


    def listen_all():
      fd_set rdfs_cp
      int retval
      self.reset_events()

      rdfs_cp = rdfs

      retval = select(max_fd, &rdfs_cp, NULL, NULL, NULL)
      if retval > 0:
        if FD_ISSET(self.mouse.fd, &rdfs_cp):
          self.mouse.handle_mouse_fd()
        if FD_ISSET(self.wacom.fd, &rdfs_cp):
          self.wacom.handle_event_fd()
        if FD_ISSET(self.touch.fd, &rdfs_cp):
          self.touch.handle_event_fd()
        if FD_ISSET(self.button.fd, &rdfs_cp):
          self.button.handle_event_fd()
        if FD_ISSET(input::ipc_fd[0], &rdfs_cp):
          self.handle_ipc()

      for auto ev : self.wacom.events:
        self.all_motion_events.push_back(self.wacom.marshal(ev))

      for auto ev : self.mouse.events:
        self.all_motion_events.push_back(self.mouse.marshal(ev))

      for auto ev : self.touch.events:
        self.all_motion_events.push_back(self.touch.marshal(ev))

      for auto ev : self.button.events:
        self.all_key_events.push_back(self.button.marshal(ev))


  // TODO: should we just put this in the SynMouseEvent?
  static WacomEvent* is_wacom_event(SynMouseEvent &syn_ev):
    return dynamic_cast<WacomEvent*>(syn_ev.original.get())
  static MouseEvent* is_mouse_event(SynMouseEvent &syn_ev):
    return dynamic_cast<MouseEvent*>(syn_ev.original.get())
  static TouchEvent* is_touch_event(SynMouseEvent &syn_ev):
    return dynamic_cast<TouchEvent*>(syn_ev.original.get())


