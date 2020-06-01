#ifndef INPUT_CPY
#include <fcntl.h>
#include <unistd.h>
#include <sys/select.h>
#include <linux/input.h>

using namespace std

class Input:
  private:

  public:
  int mouse_fd, wacom_fd, touch_fd, gpio_fd, bytes
  unsigned char data[3]
  input_event ev_data[64]

  Input():
    printf("Initializing input\n")
    // dev only
    mouse_fd = open("/dev/input/mouse0", O_RDONLY)
    // used by remarkable
    wacom_fd = open("/dev/input/event0", O_RDONLY)
    touch_fd = open("/dev/input/event1", O_RDONLY)
    gpio_fd = open("/dev/input/event2", O_RDONLY)

    printf("FDs WACOM %i TOUCH %i GPIO %i\n", wacom_fd, touch_fd, gpio_fd)

  ~Input():
    close(mouse_fd)
    close(wacom_fd)
    close(touch_fd)
    close(gpio_fd)

  // not going to use this on remarkable
  def listen_mouse():
    while 1:
      $bytes = read(mouse_fd, data, sizeof(data));
      if bytes > 0:
        left = data[0]&0x1
        right = data[0]&0x2
        middle = data[0]&0x4
        signed char x = data[1]
        signed char y = data[2]
        printf("x=%d, y=%d, left=%d, middle=%d, right=%d\n", x, y, left, middle, right)

  // wacom = pen. naming comes from libremarkable
  def listen_wacom():
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

    while 1:
      $bytes = read(wacom_fd, ev_data, sizeof(input_event) * 64);
      if bytes < sizeof(struct input_event):
        continue
      for int i = 0; i < bytes / sizeof(struct input_event); i++:
        if ev_data[i].type == EV_SYN:
          printf("SYN EVENT\n");
        else:
          printf("Event: time %ld, type: %d, code :%d, value %d\n", \
            ev_data[i].time.tv_sec, ev_data[i].type, ev_data[i].code, ev_data[i].value)




#endif
