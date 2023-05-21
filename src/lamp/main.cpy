#include <linux/input.h>
#include <string>
#include <vector>

#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sstream>
#include <math.h>

#include "../rmkit/input/device_id.h"
#include "../rmkit/util/machine_id.h"
#include "../rmkit/util/rotate.h"
#include "../rmkit/defines.h"
#include "../shared/string.h"
using namespace std

int offset = 0
int move_pts = 500
double denom = 360/(2*3.14)
bool bsleep = false

rm_version := util::get_remarkable_version()
#define DISPLAYWIDTH 1404
#define DISPLAYHEIGHT 1872.0

#if defined(REMARKABLE) | defined(DEV)
#define MTWIDTH 767
#define MTHEIGHT 1023
#define WACOMWIDTH 15725.0
#define WACOMHEIGHT 20967.0
#define DISPLAYWIDTH 1404
#define DISPLAYHEIGHT 1872.0
#define MT_X_SCALAR (float(DISPLAYWIDTH) / float(MTWIDTH))
#define MT_Y_SCALAR (float(DISPLAYHEIGHT) / float(MTHEIGHT))
#define WACOM_X_SCALAR (float(DISPLAYWIDTH) / float(WACOMWIDTH))
#define WACOM_Y_SCALAR (float(DISPLAYHEIGHT) / float(WACOMHEIGHT))
#elif KOBO
#define MTWIDTH DISPLAYWIDTH
#define MTHEIGHT DISPLAYHEIGHT
#define MT_X_SCALAR 1
#define MT_Y_SCALAR 1
#define WACOMWIDTH DISPLAYWIDTH
#define WACOMHEIGHT DISPLAYHEIGHT
#define WACOM_X_SCALAR 1
#define WACOM_Y_SCALAR 1
#endif

int get_pen_x(int x):
  return x / WACOM_X_SCALAR

int get_pen_y(int y):
  return WACOMHEIGHT - (y / WACOM_Y_SCALAR)

int get_touch_x(int x):
  if rm_version == util::RM_DEVICE_ID_E::RM2:
    return x
  return (MTWIDTH - x) / MT_X_SCALAR


int get_touch_y(int y):
  if rm_version == util::RM_DEVICE_ID_E::RM2:
    return DISPLAYHEIGHT - y
  return (MTHEIGHT - y) / MT_Y_SCALAR


vector<input_event> finger_clear():
  vector<input_event> ev
  ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_TRACKING_ID, value: -1 })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value: 1 })
  return ev

vector<input_event> finger_down(int x, y):
  vector<input_event> ev

  now := time(NULL) + offset++
  ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_TRACKING_ID, value: now })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_POSITION_X, value: get_touch_x(x) })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_POSITION_Y, value: get_touch_y(y) })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })
  return ev

vector<input_event> finger_move(int ox, oy, x, y, points=10):
  ev := finger_down(ox, oy)
  double dx = float(x - ox) / float(points)
  double dy = float(y - oy) / float(points)

  for int i = 0; i <= points; i++:
    ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_POSITION_X, value: get_touch_x(ox + (i*dx)) })
    ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_POSITION_Y, value: get_touch_y(oy + (i*dy)) })
    ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> finger_up()
  vector<input_event> ev
  ev.push_back(input_event{ type:EV_ABS, code:ABS_MT_TRACKING_ID, value: -1 })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })
  return ev

vector<input_event> pen_clear():
  vector<input_event> ev
  ev.push_back(input_event{ type:EV_ABS, code:ABS_X, value: -1 })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_DISTANCE, value: -1 })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_PRESSURE, value: -1})
  ev.push_back(input_event{ type:EV_ABS, code:ABS_Y, value: -1 })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> pen_down(int x, y, points=10):
  vector<input_event> ev
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })
  ev.push_back(input_event{ type:EV_KEY, code:BTN_TOOL_PEN, value: 1 })
  ev.push_back(input_event{ type:EV_KEY, code:BTN_TOUCH, value: 1 })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_Y, value: get_pen_x(x) })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_X, value: get_pen_y(y) })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_DISTANCE, value: 0 })
  ev.push_back(input_event{ type:EV_ABS, code:ABS_PRESSURE, value: 4000 })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  for int i = 0; i < points; i++:
    ev.push_back(input_event{ type:EV_ABS, code:ABS_PRESSURE, value: 4000 })
    ev.push_back(input_event{ type:EV_ABS, code:ABS_PRESSURE, value: 4001 })
    ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> pen_move(int ox, oy, x, y, int points=10):
  ev := pen_down(ox, oy)
  double dx = float(x - ox) / float(points)
  double dy = float(y - oy) / float(points)

  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })
  for int i = 0; i <= points; i++:
    ev.push_back(input_event{ type:EV_ABS, code:ABS_Y, value: get_pen_x(ox + (i*dx)) })
    ev.push_back(input_event{ type:EV_ABS, code:ABS_X, value: get_pen_y(oy + (i*dy)) })
    ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

vector<input_event> pen_up():
  vector<input_event> ev
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })
  ev.push_back(input_event{ type:EV_KEY, code:BTN_TOOL_PEN, value: 0 })
  ev.push_back(input_event{ type:EV_KEY, code:BTN_TOUCH, value: 0 })
  ev.push_back(input_event{ type:EV_SYN, code:SYN_REPORT, value:1 })

  return ev

def btn_press(int button):
  pass

def write_events(int fd, vector<input_event> events, int sleep_time=1000):
  vector<input_event> send
  for auto event : events:
    send.push_back(event)
    if event.type == EV_SYN:
      if sleep_time:
        usleep(sleep_time)
      input_event *out = (input_event*) malloc(sizeof(input_event) * send.size())
      for int i = 0; i < send.size(); i++:
        out[i] = send[i]

      write(fd, out, sizeof(input_event) * send.size())
      send.clear()
      free(out)

  if send.size() > 0:
    debug "DIDN'T SEND", send.size(), "EVENTS"

int finger_x, finger_y, pen_x, pen_y
void act_on_line(string);
void pen_draw_rectangle(int x1, y1, x2, y2):
  if x2 == -1:
    x2 = pen_x
    y2 = pen_y
  debug "DRAWING RECT", x1, y1, x2, y2
  act_on_line("pen down " + to_string(x1) + " " + to_string(y1))
  act_on_line("pen move " + to_string(x1) + " " + to_string(y2))
  act_on_line("pen move " + to_string(x2) + " " + to_string(y2))
  act_on_line("pen move " + to_string(x2) + " " + to_string(y1))
  act_on_line("pen move " + to_string(x1) + " " + to_string(y1))
  act_on_line("pen up ")

void pen_draw_line(int x1, y1, x2, y2):
  if x2 == -1:
    x2 = pen_x
    y2 = pen_y

  debug "DRAWING LINE", x1, y1, x2, y2
  act_on_line("pen down " + to_string(x1) + " " + to_string(y1))
  act_on_line("pen move " + to_string(x2) + " " + to_string(y2))
  act_on_line("pen up")

void trace_arc(int ox, oy, r1, r2, a1=0, a2=360, step=1):
  for i := a1; i < a2+10; i+=step:
    rx := cos(i / denom) * r1 + ox
    ry := sin(i / denom) * r2 + oy
    act_on_line("fastpen move " + to_string(int(rx)) + " " + to_string(int(ry)))

void pen_draw_circle(int ox, oy, r1, r2):
  debug "DRAWING CIRCLE", ox, oy, r1, r2
  act_on_line("pen down " + to_string(int(ox + r1)) + " " + to_string(int(oy)))
  old_move_pts := move_pts
  move_pts = 10
  trace_arc(ox, oy, r1, r2, 0, 360, 1)
  move_pts = old_move_pts
  act_on_line("pen up")

void pen_draw_arc(int ox, oy, r1, r2, a1=0, a2=360):
  while a2 < a1:
    a2 += 360

  pointx := cos(a1 / denom) * r1 + ox
  pointy := sin(a1 / denom) * r2 + oy
  debug "DRAWING ARC", ox, oy, r1, r2, a1, a2
  act_on_line("pen down " + to_string(int(pointx)) + " " + to_string(int(pointy)))

  old_move_pts := move_pts
  move_pts = 10

  trace_arc(ox, oy, r1, r2, a1, a2, 2)
  
  move_pts = old_move_pts
  act_on_line("pen up")

void pen_draw_rounded_rectangle(int x1, y1, x2, y2, r):
  if x2 == -1:
    x2 = pen_x
    y2 = pen_y
  debug "DRAWING ROUNDED RECT", x1, y1, x2, y2, r
  step:=10

  if x2 < x1:
    temp := x1
    x1 = x2
    x2 = temp
  if y2 < y1:
    temp := y1
    y1 = y2
    y2 = temp

  segmentx := abs(x2 - x1)
  segmenty := abs(y2 - y1)
  if (r > (0.5 * segmentx))
    r = 0.5 * segmentx
  if (r > (0.5 * segmenty))
    r = 0.5 * segmenty

  pointx := x1 + segmentx - r
  pointy := y1 + r
  degreesx := 270
  degreesy := 360
  act_on_line("pen down " + to_string(pointx) + " " + to_string(y1))
  trace_arc(pointx, pointy, r, r, degreesx, degreesy, step)
  pointx = x1 + segmentx - r
  pointy = y1 + segmenty - r
  degreesx = 0
  degreesy = 90
  trace_arc(pointx, pointy, r, r, degreesx, degreesy, step)
  pointx = x1 + r
  pointy = y1 + segmenty - r
  degreesx = 90
  degreesy = 180
  trace_arc(pointx, pointy, r, r, degreesx, degreesy, step)
  pointx = x1 + r
  pointy = y1 + r
  degreesx = 180
  degreesy = 270
  trace_arc(pointx, pointy, r, r, degreesx, degreesy, step)

  pointx = x1 + segmentx - r
  act_on_line("pen move " + to_string(pointx) + " " + to_string(y1))
  act_on_line("pen up")

void trace_bezier(vector<int> coors):
  double pointx, pointy
  step := 0.01
  if (len(coors) == 6):
    for t := step; t <= (1.0 + step); t = t + step:
      it := 1 - t
      pointx = it * it * coors[0] + 2 * t * it * coors[2] + t * t * coors[4];
      pointy = it * it * coors[1] + 2 * t * it * coors[3] + t * t * coors[5];
      act_on_line("fastpen move " + to_string(int(pointx)) + " " + to_string(int(pointy)))
  else if (len(coors) == 8)
    for t := step; t <= (1.0 + step); t = t + step:
      it := 1 - t
      pointx = it * it * it * coors[0] + 3 * t * it * it * coors[2] + 3 * t * t * it * coors[4] + t * t * t * coors[6];
      pointy = it * it * it * coors[1] + 3 * t * it * it * coors[3] + 3 * t * t * it * coors[5] + t * t * t * coors[7];
      act_on_line("fastpen move " + to_string(int(pointx)) + " " + to_string(int(pointy)))

void pen_draw_bezier(vector<int> coors):
  act_on_line("pen down " + to_string(coors[0]) + " " + to_string(coors[1]))
  trace_bezier(coors)
  act_on_line("pen up")


int touch_fd, pen_fd
void act_on_line(string line):
  stringstream ss(line)
  string action, tool
  ss >> tool >> action;
  int x, y, ox=-1, oy=-1, a1=0, a2=360, r=10
  vector<int> coors
  tokens := str_utils::split(line, ' ')

  if tool == "swipe":
    if action == "left":
      write_events(touch_fd, finger_up())
      write_events(touch_fd, finger_move(200, 500, 1000, 500, 20)) // swipe right
      write_events(touch_fd, finger_up())
      usleep(100 * 1000)
    else if action == "right":
      write_events(touch_fd, finger_up())
      write_events(touch_fd, finger_move(1000, 500, 200, 500, 20)) // swipe right
      write_events(touch_fd, finger_up())
      usleep(100 * 1000)
    else if  action == "up":
      write_events(touch_fd, finger_up())
      write_events(touch_fd, finger_move(500, 800, 500, 200, 20)) // swipe up
      write_events(touch_fd, finger_up())
      usleep(100 * 1000)
    else if  action == "down":
      write_events(touch_fd, finger_up())
      write_events(touch_fd, finger_move(500, 200, 500, 800, 20)) // swipe down
      write_events(touch_fd, finger_up())
      usleep(100 * 1000)
    else:
      debug "UNKNOWN SWIPE DIRECTION", action
    return

  if action == "move":
    if len(tokens) == 4:
      ss >> x >> y
    else if len(tokens) == 6:
      ss >> ox >> oy >> x >> y
    else:
      debug "UNRECOGNIZED MOVE LINE", line, "REQUIRES 2 or 4 COORDINATES"
  if action == "rectangle" || action == "line":
    if len(tokens) == 6:
      ss >> ox >> oy >> x >> y
    else:
      debug "UNRECOGNIZED DRAW LINE", line, "REQUIRES 4 COORDINATES"
  if action == "circle":
    if len(tokens) == 6:
      ss >> ox >> oy >> x >> y
    else if len(tokens) == 5:
      ss >> ox >> oy >> x
      y = x
    else:
      debug "UNRECOGNIZED DRAW CIRCLE", line, "REQUIRES 2 COORDINATES AND 1 OR 2 RADIUS"
  if action == "arc":
    if len(tokens) == 8:
      ss >> ox >> oy >> x >> y >> a1 >> a2
    else:
      debug "UNRECOGNIZED DRAW ARC", line, "REQUIRES 4 COORDINATES AND 2 ANGLES"
  if action == "roundedrectangle":
    if len(tokens) == 7:
      ss >> ox >> oy >> x >> y >> r
    else:
      debug "UNRECOGNIZED DRAW ROUNDED RECTANGLE", line, "REQUIRES 4 COORDINATES AND 1 RADIUS"
  if action == "bezier":
    while (ss >> ox):
      coors.push_back(ox);
    if !(len(coors) == 6 || len(coors) == 8)
      debug "UNRECOGNIZED DRAW BEZIER", line, "REQUIRES 6 OR 8 COORDINATES"

  if action == "down":
    if len(tokens) == 4:
      ss >> x >> y
    else:
      debug "UNRECOGNIZED DOWN LINE", line, "REQUIRES 2 COORDINATES"

  bsleep := 10
  if tool == "fastpen":
    bsleep = 2
  if tool == "pen" || tool == "fastpen":
    if action == "up":
      write_events(pen_fd, pen_up())
    else if action == "down":
      write_events(pen_fd, pen_down(x, y))
      pen_x = x
      pen_y = y
    else if action == "move":
      if ox != -1 && oy != -1:
        write_events(pen_fd, pen_move(ox, oy, x, y, move_pts), bsleep)
      else:
        write_events(pen_fd, pen_move(pen_x, pen_y, x, y, move_pts), bsleep)
      pen_x = x
      pen_y = y
    else if action == "line":
      pen_draw_line(ox, oy, x, y)
      usleep(200 * 1000)
    else if action == "rectangle":
      pen_draw_rectangle(ox, oy, x, y)
      usleep(200 * 1000)
    else if action == "circle":
      pen_draw_circle(ox, oy, x, y)
      usleep(200 * 1000)
    else if action == "arc":
      pen_draw_arc(ox, oy, x, y, a1, a2)
      usleep(200 * 1000)
    else if action == "roundedrectangle":
      pen_draw_rounded_rectangle(ox, oy, x, y, r)
      usleep(200 * 1000)
    else if action == "bezier":
      pen_draw_bezier(coors)

    else:
      debug "UNKNOWN ACTION", action, "IN", line
  else if tool == "finger":
    if action == "up":
      write_events(touch_fd, finger_up())
    else if action == "down":
      write_events(touch_fd, finger_down(x, y))
      finger_x = x
      finger_y = y
    else if action == "move":
      if ox != -1 && oy != -1:
        write_events(touch_fd, finger_move(ox, oy, x, y))
      else:
        write_events(touch_fd, finger_move(finger_x, finger_y, x, y))
      finger_x = x
      finger_y = y
    else:
      debug "UNKNOWN ACTION", action, "IN", line
  else if tool == "sleep":
    int val = strtol(action.c_str(), NULL, 10) 
    if action == "on"
      bsleep = true
    else if action == "off"
      bsleep = false
    else if bsleep == false:
      pass
    else if 1 <= val && val <= 10000:
      usleep(val * 1000)
      debug "SLEEP FOR" val "ms"
    else:
      debug "UNKNOWN ACTION", action, "IN", line
  else:
    debug "UNKNOWN TOOL", tool, "IN", line




def main(int argc, char **argv):
  #ifndef REMARKABLE
  debug "lamp is not supported on this platform"
  exit(1)
  #endif
  fd0 := open("/dev/input/event0", O_RDWR)
  fd1 := open("/dev/input/event1", O_RDWR)
  fd2 := open("/dev/input/event2", O_RDWR)

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

  write_events(touch_fd, finger_up())
  write_events(pen_fd, pen_clear())

  string line
  while getline(cin, line):
    act_on_line(line)

  write_events(touch_fd, finger_up())
  write_events(pen_fd, pen_up())

