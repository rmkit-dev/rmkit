#include <linux/input.h>
#include <string>
#include <vector>

#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "../rmkit/input/device_id.h"
#include "../rmkit/util/machine_id.h"
#include "../rmkit/defines.h"
#include "../shared/string.h"
#include "../shared/clockwatch.h"
using namespace std

int offset = 0

rm_version := util::get_remarkable_version()

int get_pen_x(int x):
  return x / WACOM_X_SCALAR

int get_pen_y(int y):
  return (WACOMHEIGHT - y) / WACOM_Y_SCALAR

int get_touch_x(int x):
  if rm_version == util::RM_VERSION::RM2:
    return x
  return (MTWIDTH - x) / MT_X_SCALAR

int get_touch_y(int y):
  if rm_version == util::RM_VERSION::RM2:
    return DISPLAYHEIGHT - y
  return (MTHEIGHT - y) / MT_Y_SCALAR

vector<input_event> finger_clear():
  vector<input_event> ev
  ev.push_back({ type:EV_ABS, code:ABS_MT_TRACKING_ID, value: -1 })
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value: 1 })
  return ev

vector<input_event> finger_down(int x, y):
  vector<input_event> ev

  now := time(NULL) + offset++
  ev.push_back({ type:EV_ABS, code:ABS_MT_TRACKING_ID, value: now })
  ev.push_back({ type:EV_ABS, code:ABS_MT_POSITION_X, value: get_touch_x(x) })
  ev.push_back({ type:EV_ABS, code:ABS_MT_POSITION_Y, value: get_touch_y(y) })
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })
  return ev

vector<input_event> finger_move(int ox, oy, x, y, points=1):
  ev := finger_down(ox, oy)
  double dx = float(x - ox) / float(points)
  double dy = float(y - oy) / float(points)

  for int i = 0; i <= points; i++:
    ev.push_back({ type:EV_ABS, code:ABS_MT_POSITION_X, value: get_touch_x(ox + (i*dx)) })
    ev.push_back({ type:EV_ABS, code:ABS_MT_POSITION_Y, value: get_touch_y(oy + (i*dy)) })
    ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> finger_up()
  vector<input_event> ev
  ev.push_back({ type:EV_ABS, code:ABS_MT_TRACKING_ID, value: -1 })
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })
  return ev

vector<input_event> pen_clear():
  vector<input_event> ev
  ev.push_back({ type:EV_ABS, code:ABS_X, value: -1 })
  ev.push_back({ type:EV_ABS, code:ABS_DISTANCE, value: -1 })
  ev.push_back({ type:EV_ABS, code:ABS_PRESSURE, value: -1})
  ev.push_back({ type:EV_ABS, code:ABS_Y, value: -1 })
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> pen_down(int x, y):
  vector<input_event> ev
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })
  ev.push_back({ type:EV_KEY, code:BTN_TOOL_PEN, value: 1 })
  ev.push_back({ type:EV_KEY, code:BTN_TOUCH, value: 1 })
  ev.push_back({ type:EV_ABS, code:ABS_Y, value: get_pen_x(x) })
  ev.push_back({ type:EV_ABS, code:ABS_X, value: get_pen_y(y) })
  ev.push_back({ type:EV_ABS, code:ABS_DISTANCE, value: 0 })
  ev.push_back({ type:EV_ABS, code:ABS_PRESSURE, value: 2500 })
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> pen_move(int ox, oy, x, y, int points=1):
  vector<input_event> ev
  double dx = float(x - ox) / float(points)
  double dy = float(y - oy) / float(points)

  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })
  for int i = 0; i <= points; i++:
    ev.push_back({ type:EV_ABS, code:ABS_Y, value: get_pen_x(ox + (i*dx)) })
    ev.push_back({ type:EV_ABS, code:ABS_X, value: get_pen_y(oy + (i*dy)) })
    ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> pen_up():
  vector<input_event> ev
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })
  ev.push_back({ type:EV_KEY, code:BTN_TOOL_PEN, value: 0 })
  ev.push_back({ type:EV_KEY, code:BTN_TOUCH, value: 0 })
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

def btn_press(int button):
  pass

def write_events(int fd, vector<input_event> events):
  vector<input_event> send
  for auto event : events:
    send.push_back(event)
    if event.type == EV_SYN:
      usleep(1000)
      input_event *out = (input_event*) malloc(sizeof(input_event) * send.size())
      for int i = 0; i < send.size(); i++:
        out[i] = send[i]

      write(fd, out, sizeof(input_event) * send.size())
      send.clear()
      free(out)

  if send.size() > 0:
    debug "DIDN'T SEND", send.size(), "EVENTS"


def main(int argc, char **argv):
  fd0 := open("/dev/input/event0", O_RDWR)
  fd1 := open("/dev/input/event1", O_RDWR)
  fd2 := open("/dev/input/event2", O_RDWR)

  int touch_fd, pen_fd
  if input::id_by_capabilities(fd0) == input::EV_TYPE::TOUCH:
    touch_fd = fd0
  if input::id_by_capabilities(fd1) == input::EV_TYPE::TOUCH:
    touch_fd = fd1
  if input::id_by_capabilities(fd2) == input::EV_TYPE::TOUCH:
    touch_fd = fd2

  if input::id_by_capabilities(fd0) == input::EV_TYPE::STYLUS:
    pen_fd = fd0
  if input::id_by_capabilities(fd1) == input::EV_TYPE::STYLUS:
    pen_fd = fd1
  if input::id_by_capabilities(fd2) == input::EV_TYPE::STYLUS:
    pen_fd = fd2

//  write_events(pen_fd, pen_clear())
//  write_events(pen_fd, pen_down(250, 250))
//  write_events(pen_fd, pen_move(250, 250, 250, 1250))
//  write_events(pen_fd, pen_up())

  if argc == 2:
    if argv[1] == string("left"):
      write_events(touch_fd, finger_up())
      write_events(touch_fd, finger_move(200, 500, 1000, 500, 20)) // swipe right
      write_events(touch_fd, finger_up())
    if argv[1] == string("right"):
      write_events(touch_fd, finger_up())
      write_events(touch_fd, finger_move(1000, 500, 200, 500, 20)) // swipe left
      write_events(touch_fd, finger_up())


