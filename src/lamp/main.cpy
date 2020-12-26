#include <linux/input.h>
#include <string>
#include <vector>

#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "../rmkit/defines.h"
#include "../shared/string.h"
#include "../shared/clockwatch.h"
using namespace std


vector<input_event> finger_clear():
  vector<input_event> ev
  ev.push_back({ type:EV_SYN, code:0, value:1 })
  ev.push_back({ type:EV_SYN, code:0, value:1 })
  return ev

vector<input_event> finger_down(int x, y):
  vector<input_event> ev

  now := time(NULL)
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })
  ev.push_back({ type:EV_ABS, code:ABS_MT_TRACKING_ID, value: now })
  ev.push_back({ type:EV_ABS, code:ABS_MT_PRESSURE, value: 78 })
  ev.push_back({ type:EV_ABS, code:ABS_MT_SLOT, value: 0 })
  ev.push_back({ type:EV_ABS, code:ABS_MT_POSITION_X, value: x })
  ev.push_back({ type:EV_ABS, code:ABS_MT_POSITION_Y, value: DISPLAYHEIGHT - y })
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })
  return ev

vector<input_event> finger_move(int ox, oy, x, y, points=1):
  vector<input_event> ev
  double dx = float(x - ox) / float(points)
  double dy = float(y - oy) / float(points)

  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })
  for int i = 0; i <= points; i++:
    ev.push_back({ type:EV_ABS, code:ABS_MT_POSITION_X, value: (ox + (i*dx)) })
    ev.push_back({ type:EV_ABS, code:ABS_MT_POSITION_Y, value: DISPLAYHEIGHT - (oy + (i*dy)) })
    ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> finger_up()
  vector<input_event> ev
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })
  ev.push_back({ type:EV_ABS, code:ABS_MT_TRACKING_ID, value: -1 })
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })
  return ev

vector<input_event> pen_clear():
  vector<input_event> ev
  ev.push_back({ type:EV_SYN, code:SYN_REPORT, value:1 })
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
  ev.push_back({ type:EV_ABS, code:ABS_Y, value: x / WACOM_X_SCALAR })
  ev.push_back({ type:EV_ABS, code:ABS_X, value: y / WACOM_Y_SCALAR})
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
    ev.push_back({ type:EV_ABS, code:ABS_Y, value: (ox + (i*dx)) / WACOM_X_SCALAR  })
    ev.push_back({ type:EV_ABS, code:ABS_X, value: (oy + (i*dy)) / WACOM_Y_SCALAR  })
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



def main(int argc, char **argv):
  pen_fd := open("/dev/input/event1", O_RDWR)
  write_events(pen_fd, pen_clear())
  write_events(pen_fd, pen_down(250, 250))
  write_events(pen_fd, pen_move(250, 250, 250, 1250))
  write_events(pen_fd, pen_up())

  touch_fd := open("/dev/input/event2", O_RDWR)
  write_events(touch_fd, finger_clear())
  write_events(touch_fd, finger_down(200, 500))
  // write_events(touch_fd, finger_move(1000, 500, 200, 500, 20)) // swipe left
  write_events(touch_fd, finger_move(200, 500, 1000, 500, 30)) // swipe right
  write_events(touch_fd, finger_up())


