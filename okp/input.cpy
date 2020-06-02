#ifndef INPUT_CPY
#include <fcntl.h>
#include <unistd.h>
#include <sys/select.h>
#include <linux/input.h>

using namespace std

class Input:
  private:

  public:
  int mouse_fd, wacom_fd, touch_fd, gpio_fd, bytes, max_fd
  unsigned char data[3]
  input_event ev_data[64]
  fd_set rdfs

  Input():
    printf("Initializing input\n")
    // dev only
    mouse_fd = open("/dev/input/mouse0", O_RDONLY)
    // used by remarkable
    wacom_fd = open("/dev/input/event0", O_RDONLY)
    touch_fd = open("/dev/input/event1", O_RDONLY)
    gpio_fd = open("/dev/input/event2", O_RDONLY)

    FD_ZERO(&rdfs)

    printf("FDs MOUSE %i WACOM %i TOUCH %i GPIO %i\n", mouse_fd, wacom_fd, touch_fd, gpio_fd)

    // input events (for wacom,touch,gpio) have:
    // type (u16)
    // code (u16)
    // value (i32)

    // event codes for EV_ABS
    WACOM_EVCODE_PRESSURE = 24 // goes up to 4095
    WACOM_EVCODE_DISTANCE = 25 // distance from screen? up to 255
    WACOM_EVCODE_XTILT = 26 // -9000 to 9000
    WACOM_EVCODE_YTILT = 27 // -9000 to 9000
    // note: x and y are inverted on remarkable
    WACOM_EVCODE_XPOS = 0
    WACOM_EVCODE_YPOS = 1

    // tool types (event codes for EV_KEY)
    // these mean the pen is hovering
    ToolPen = 320
    ToolRubber = 321
    // these mean the pen is touching the display
    Touch = 330
    Stylus = 331
    Stylus2 = 332


  ~Input():
    close(mouse_fd)
    close(wacom_fd)
    close(touch_fd)
    close(gpio_fd)

  def read_mouse():
    $bytes = read(mouse_fd, data, sizeof(data));
    if bytes > 0:
      left = data[0]&0x1
      right = data[0]&0x2
      middle = data[0]&0x4
      signed char x = data[1]
      signed char y = data[2]
      printf("x=%d, y=%d, left=%d, middle=%d, right=%d\n", x, y, left, middle, right)

  // not going to use this on remarkable
  def listen_mouse():
    while 1:
      read_mouse()

  def read_wacom():
    $bytes = read(wacom_fd, ev_data, sizeof(input_event) * 64);
    if bytes < sizeof(struct input_event):
      return
    for int i = 0; i < bytes / sizeof(struct input_event); i++:
      if ev_data[i].type == EV_SYN:
        printf("SYN EVENT\n");
      else:
        printf("Event: time %ld, type: %x, code :%x, value %d\n", \
          ev_data[i].time.tv_sec, ev_data[i].type, ev_data[i].code, ev_data[i].value)

  // wacom = pen. naming comes from libremarkable
  def listen_wacom():
    print "listening for pen input"
    while 1:
      self.read_wacom()

  def read_touch():
    // TODO
    pass

  def read_gpio():
    // TODO
    pass

  def monitor(int fd):
    FD_SET(fd,&rdfs)
    max_fd = max(max_fd, fd)

  def listen_all():
    fd_set rdfs_cp
    int retval

    // should probably remove mouse_fd from rdfs for remarkable
    // it was the only way I could test on ubuntu
    monitor(mouse_fd)
    monitor(wacom_fd)
    monitor(touch_fd)
    monitor(gpio_fd)

    while 1:
      rdfs_cp = rdfs
      retval = select(max_fd+1, &rdfs_cp, NULL, NULL, NULL)
      if retval > 0:
        if FD_ISSET(mouse_fd, &rdfs_cp):
          read_mouse()
        if FD_ISSET(wacom_fd, &rdfs_cp):
          read_wacom()
        if FD_ISSET(touch_fd, &rdfs_cp):
          read_touch()
        if FD_ISSET(gpio_fd, &rdfs_cp):
          read_gpio()
      if retval < 0:
        print "oops, select broke"
        exit(1)





#endif
