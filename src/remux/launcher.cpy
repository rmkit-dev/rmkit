// LAUNCHER FOR REMARKABLE
#include <time.h>
#include <thread>
#include <chrono>

#include <time.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <dirent.h>
#include <algorithm>
#include <unordered_set>
#include <linux/input.h>
#include <chrono>

#include "../shared/proc.h"
#include "../build/rmkit.h"
#include "../genie/gesture_parser.h"
#include "config.h"

TIMEOUT := 1
SUSPEND_TIMER := 10

// all time is in seconds
// TODO: read these from remarkable.conf file

MIN := 60
HOURS := MIN * MIN

SUSPEND_THRESHOLD := MIN * 4
CHARGING_THRESHOLD := MIN * 30
TOO_MUCH_THRESHOLD := MIN * 7
SHUTDOWN_THRESHOLD := HOURS * 10 // 10 hours

#include "apps.h"

DIALOG_WIDTH  := 400
DIALOG_HEIGHT := 800

LAST_ACTION := 0
USE_KOREADER_WORKAROUND := false

string CURRENT_APP = "_"
string NAO_BIN="/opt/bin/nao"

// start with Remarkable preloaded in the launch list
// so we can switch back to it quickly
deque<string> _launched = { "Remarkable", "_" }


DEFAULT_LAUNCH_GESTURES := vector<string> %{
  "gesture=swipe; direction=up; zone=0 0 0.1 1",
  "gesture=swipe; direction=up; zone=0.9 0 1 1",
}


class IApp:
  public:
  virtual void launch(string) = 0;
  virtual void on_suspend() = 0;
  virtual void get_more() = 0;
  virtual void show_launcher() = 0;
  virtual void show_last_app() = 0;


class NaoButton: public ui::Button:
  public:
  IApp *app
  NaoButton(int x, int y, int w, int h, IApp *a): ui::Button(x, y, w, h, "Get More Apps"):
    self.app = a

  void on_mouse_click(input::SynMotionEvent &ev):
    self.app->get_more()

class SuspendButton: public ui::Button:
  public:
  IApp *app
  SuspendButton(int x, int y, int w, int h, IApp *a): ui::Button(x, y, w, h, "Suspend"):
    self.app = a

  void on_mouse_click(input::SynMotionEvent &ev):
    self.app->on_suspend()

class StatusBar: public ui::Button:
  public:
  StatusBar(int x, int y, int w, int h, string t): ui::Button(x, y, w, h, t):
    pass

  void render():
    ui::Button::render()
    self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false)

class AppBackground: public ui::Widget:
  public:
  int byte_size
  bool snapped = false
  map<string, framebuffer::VirtualFB*> app_buffers;

  AppBackground(int x, y, w, h): ui::Widget(x, y, w, h):
    self.byte_size = w*h*sizeof(remarkable_color)

  def snapshot():
    fb := framebuffer::get()
    snapped = true

    vfb := self.get_vfb()
    debug "SNAPSHOTTING", CURRENT_APP

    vfb->fbmem = (remarkable_color*) memcpy(vfb->fbmem, fb->fbmem, self.byte_size)

  framebuffer::VirtualFB* get_vfb():
    if app_buffers.find(CURRENT_APP) == app_buffers.end():
      fw, fh := fb->get_display_size()
      app_buffers[CURRENT_APP] = new framebuffer::VirtualFB(fw, fh)
      app_buffers[CURRENT_APP]->clear_screen()

    return app_buffers[CURRENT_APP]

  void render():
    if not snapped:
      return

    vfb := self.get_vfb()
    debug "RENDERING", CURRENT_APP
    if rm2fb::IN_RM2FB_SHIM:
      fb->waveform_mode = WAVEFORM_MODE_GC16
    else:
      fb->waveform_mode = WAVEFORM_MODE_AUTO
    memcpy(fb->fbmem, vfb->fbmem, self.byte_size)
    fb->perform_redraw(true)
    fb->dirty = 1

class AppDialog: public ui::Pager:
  public:
    vector<string> binaries
    AppReader reader
    IApp* app

    AppDialog(int x, y, w, h, IApp* a): ui::Pager(x, y, w, h, self):
      self.set_title("")
      self.app = a
      self.opt_h = 60
      self.page_size = self.page_size - 4
      self.buttons = { "Get More Apps" }

    void add_shortcuts():
      // draw suspend button in bottom right
      _w, _h := fb->get_display_size()
      h_layout := ui::HorizontalLayout(0, 0, _w, _h, self.scene)
      v_layout := ui::VerticalLayout(0, 0, _w, _h, self.scene)
      b1 := new SuspendButton(0, 0, 200, 50, self.app)
      h_layout.pack_end(b1)
      v_layout.pack_end(b1)

      // draw memory info
      mem_info := proc::read_mem_total()
      if mem_info.available > 0:

        mem_str := string("Used Mem: ") + proc::join_path(%{
          to_string(mem_info.used/1024),
          to_string(mem_info.total/1024) }) + string("MB ")

        stat_str := mem_str

        cw := 350
        b3 := new StatusBar(self.x+self.w-cw, self.y-50, cw, 50, stat_str)
        b3->set_style(ui::Stylesheet().justify_right())
        self.scene->add(b3)



    void render():
      ui::Pager::render()
      self.fb->draw_line(self.x+self.w, self.y, self.x+self.w, self.y+self.h, 2, BLACK)

      // render memory stats/

    void populate():
      self.reader.populate()
      self.options = self.reader.get_binaries()

    vector<RMApp> get_apps():
      return self.reader.apps

    void on_row_selected(string name):
      CURRENT_APP = name
      ui::MainLoop::hide_overlay()

    void render_row(ui::HorizontalLayout *row, string option):
      status := string("")
      bin := string("")
      for auto app : self.reader.apps:
        if app.name == option or app.bin == option:
          bin = app.bin
          if app.is_running:
            used := app.mem_usage / 1024
            if used == 0:
              status = "?MB"
            else:
              status = to_string(app.mem_usage / 1024) + string("MB")

      c := new ui::Button(0, 0, 100, self.opt_h, status)

      if bin != "":
        c->mouse.click += PLS_LAMBDA(auto &ev) {
          if bin == "xochitl":
            return

          vector<string> bins = { bin }
          proc::groupkill(SIGKILL, bins)

          if status != "":
            c->text = "killed"
            c->dirty = 1
        }

      c->set_style(ui::Stylesheet().justify_right())
      d := new ui::DialogButton(0, 0, self.w-90, self.opt_h, self, option)
      d->x_padding = 10
      d->y_padding = 5
      d->set_style(ui::Stylesheet().justify_left())
      self.layout->pack_start(row)
      row->pack_start(d)
      row->pack_end(c)

class App: public IApp:
  int lastpress
  int is_pressed = false
  AppDialog *app_dialog
  AppBackground *app_bg
  shared_ptr<framebuffer::FB> fb
  mutex suspend_m
  thread* idle_thread
  thread* ipc_thread

  input_event *touch_flood
  input_event *button_flood
  vector<input::TouchEvent> touch_events

  public:
  App():
    fb = framebuffer::get()

    // on resize, we exit and trust our service to restart us
    fb->resize += [=](auto &e):
      exit(1)
    ;

    w, h = fb->get_display_size()

    if app_dialog != NULL:
      delete app_dialog
    if app_bg != NULL:
      delete app_bg

    app_dialog = new AppDialog(0, 0, 600, 800, self)
    app_dialog->populate()
    get_current_app()

    app_dialog->on_hide += PLS_LAMBDA(auto &d):
      self.render_bg()
      launch(CURRENT_APP)
      if USE_KOREADER_WORKAROUND and CURRENT_APP != "KOReader":
        ui::MainLoop::in.ungrab()
    ;

    app_bg = new AppBackground(0, 0, w, h)

    touch_flood = build_touch_flood()
    button_flood = build_button_flood()

    notebook := ui::make_scene()
    notebook->add(app_bg)
    ui::MainLoop::set_scene(notebook)

    #ifdef REMARKABLE
    self.update_thresholds()
    #endif
    return

  void update_thresholds():
    debug "READING TIMEOUTS FOR SLEEP/SHUTDOWN FROM XOCHITL"
    ifstream f("/home/root/.config/remarkable/xochitl.conf")
    string line
    while getline(f, line):
      // TODO: switch this to using str_utils::split?
      // search line by line for IdleSuspendDelay, SuspendPowerOffDelay
      if line.find("IdleSuspendDelay") != -1:
        eq_sign_pos := line.find("=")
        if eq_sign_pos != -1:
          try:
            SUSPEND_THRESHOLD = std::stoi(line.substr(eq_sign_pos+1, -1)) / 1000 - 10
            debug "SUSPEND UPDATED", SUSPEND_THRESHOLD
          catch (...):
            debug "COULDNT PARSE FOR SUSPEND:", line
      if line.find("SuspendPowerOffDelay") != -1:
        eq_sign_pos := line.find("=")
        if eq_sign_pos != -1:
          try:
            SHUTDOWN_THRESHOLD = std::stoi(line.substr(eq_sign_pos+1, -1)) / 1000
            debug "SHUTDOWN UPDATED", SHUTDOWN_THRESHOLD
          catch (...):
            debug "COULDNT PARSE FOR SHUTDOWN:", line

  void get_more():
    launch(NAO_BIN)

  void get_current_app():
    RMApp active

    vector<string> binaries;
    for auto a : app_dialog->get_apps():
      if proc::is_running(a.which):
        active = a
        debug "CURRENT APP IS", active.name
        CURRENT_APP = active.name
        return


  def handle_api_line(string line):
    str_utils::trim(line)
    if line == "":
      return

    if line == "show":
      self.show_launcher()
    else if line == "hide":
      ui::MainLoop::hide_overlay()
    else if line == "back":
      ui::MainLoop::hide_overlay()
      self.show_last_app()
    else:
      debug "UNKNOWN API LINE:", line

  def open_input_fifo():
    #ifndef REMARKABLE
    return
    #endif

    debug "STARTING FIFO THREAD"

    _ := system("/usr/bin/mkfifo /run/remux.api 2>/dev/null")
    self.ipc_thread = new thread([=]() {
      fd := open("/run/remux.api", O_RDONLY)

      string remainder = ""
      char buf[4096]
      while true:
        bytes := read(fd, buf, 4096)

        if bytes > 0:
          buf[bytes] = 0
          summed := remainder + string(buf)
          lines := str_utils::split(summed, '\n')
          remainder = ""

          if lines.size() > 0 && buf[bytes-1] != '\n':
            remainder = lines.back()
            lines.pop_back()

          for auto line : lines:
            ui::TaskQueue::add_task([=]() {
              handle_api_line(line)
            })

        usleep(50 * 1000)
    })

  def suspend_on_idle():
    version := util::get_remarkable_version()
    self.idle_thread = new thread([=]() {
      while true:
        now := time(NULL)
        usb_in := false
        string usb_str
        if version == util::RM_VERSION::RM2:
          usb_str = string(exec("cat /sys/class/power_supply/max77818-charger/online"))
        else:
          usb_str = string(exec("cat /sys/class/power_supply/imx_usb_charger/present"))
        str_utils::trim(usb_str)
        usb_in = usb_str == string("1")

        suspend_m.lock()
        if LAST_ACTION == 0 or usb_in:
          LAST_ACTION = now
        last_action := LAST_ACTION
        suspend_m.unlock()

        if last_action > 0 and SUSPEND_THRESHOLD > 0:
          if now - last_action > SUSPEND_THRESHOLD and now - LAST_ACTION < 2*SUSPEND_THRESHOLD:
            if not ui::MainLoop::overlay_is_visible:
              app_bg->snapshot()
            on_suspend()


        this_thread::sleep_for(chrono::seconds(10));

    });

  def handle_motion_event(input::SynMotionEvent ev):
    suspend_m.lock()
    LAST_ACTION = time(NULL)
    suspend_m.unlock()

  void render_bg():
    app_bg->render()
    ui::MainLoop::redraw()

  void show_last_app():
    debug "SHOWING LAST APP", CURRENT_APP
    for auto app : _launched:
      if app != CURRENT_APP && app != "_":
        self.term_apps()
        self.app_bg->snapshot()
        self.launch(app)
        self.render_bg()
        break

  void show_launcher():
    if ui::MainLoop::overlay_is_visible:
      return

    ClockWatch cz

    ClockWatch c0
    get_current_app()
    debug "current app", c0.elapsed()

    // this is really backgrounding apps, not terminating
    ClockWatch c1
    term_apps()
    debug "term apps", c1.elapsed()

    app_bg->snapshot()

    app_dialog->populate()
    app_dialog->setup_for_render()
    app_dialog->add_shortcuts()
    app_dialog->show()
    app_dialog->scene->on_hide += app_dialog->on_hide

    ui::MainLoop::in.grab()

  def handle_key_event(input::SynKeyEvent ev):
    static int lastpress = RAND_MAX
    static int event_press_id = 0

    suspend_m.lock()
    LAST_ACTION = time(NULL)
    suspend_m.unlock()

    if is_pressed && ev.is_pressed:
      return

    switch ev.key:
      case KEY_HOME:

        if ev.is_pressed:
          lastpress = time(NULL)
          event_press_id = ev.id

          thread *th = new thread([=]() {
              this_thread::sleep_for(chrono::seconds(TIMEOUT));
              now := time(NULL)
              if now - lastpress >= TIMEOUT:
                if is_pressed && event_press_id == ev.id
                  self.show_launcher()
                  ui::TaskQueue::wakeup()
          });
        else:
          event_press_id = 0

        is_pressed = ev.is_pressed

    last_ev := &ev

  void term_apps(string name=""):
    vector<string> term
    for auto a : app_dialog->get_apps():
      tokens := str_utils::split(a.bin, ' ')
      cstr := tokens[0].c_str()
      base := basename((char *) cstr)
      if a.name != name:
        term.push_back(string(base))

    if term.size() > 0:
      proc::groupkill(SIGSTOP, term)

  bool file_exists(string s):
    struct stat buffer;
    return (stat (s.c_str(), &buffer) == 0);

  // TODO: power button will cause suspend screen, why not?
  void on_suspend():
    #ifndef REMARKABLE
    return
    #endif

    debug "SUSPENDING"
    ui::MainLoop::hide_overlay()

    _w, _h := fb->get_display_size()

    #ifdef REMARKABLE
    if file_exists("/usr/share/remarkable/sleeping.png"):
      fb->load_from_png("/usr/share/remarkable/sleeping.png")
    else:
      fb->load_from_png("/usr/share/remarkable/suspended.png")
    #else
    text := ui::Text(0, _h-64, _w, 100, "Press any button to wake")
    text.set_style(ui::Stylesheet().font_size(64).justify_center())

    text.undraw()
    text.render()
    #endif


    fb->redraw_screen()
    ui::MainLoop::in.grab()

    #ifdef REMARKABLE
    if rm2fb::IN_RM2FB_SHIM:
      sleep(1)
      _ := system("systemctl suspend")
      sleep(1)

      if system("lsmod | grep brcmfmac") == 0:
        debug "RELOADING WIFI DRIVERS"
        _ = system("modprobe -r brcmfmac brcmutil")
        _ = system("modprobe brcmfmac brcmutil")
    else:
      now := time(NULL)
      if SHUTDOWN_THRESHOLD > 0:
        cmd := "echo " + to_string(SHUTDOWN_THRESHOLD + now) + " > /sys/class/rtc/rtc0/wakealarm"

        _ := system(cmd.c_str())
      sleep(1)
      _ := system("systemctl suspend")
      sleep(1)

      now = time(NULL)
      if SHUTDOWN_THRESHOLD > 0 && now - LAST_ACTION >= SHUTDOWN_THRESHOLD:
        debug "RESUMING FROM SUSPEND -> SHUTDOWN"
        _ := system("systemctl poweroff")
        return

      // reset LAST_ACTION after wake so we don't go into sleep loop
      LAST_ACTION = time(NULL)

      _ = system("echo 0 > /sys/class/rtc/rtc0/wakealarm")
    #endif

    debug "RESUMING FROM SUSPEND"
    ui::MainLoop::in.ungrab()

    fb->clear_screen()
    app_bg->render()
    fb->redraw_screen(true)

  inline void write_input_event(int fd, type, code, value):
    input_event ev;
    memset(&ev, 0, sizeof(ev));

    ev.type = type
    ev.code = code
    ev.value = value

    if write(fd, &ev, sizeof(ev)) != sizeof(ev):
      debug "COULDNT WRITE EV", errno


  input_event* build_touch_flood():
    n := 512 * 8
    num_inst := 4
    input_event *ev = (input_event*) malloc(sizeof(struct input_event) * n * num_inst)
    memset(ev, 0, sizeof(input_event) * n * num_inst)

    i := 0
    while i < n:
      ev[i++] = input_event{ type:EV_ABS, code:ABS_DISTANCE, value:1 }
      ev[i++] = input_event{ type:EV_SYN, code:0, value:0 }
      ev[i++] = input_event{ type:EV_ABS, code:ABS_DISTANCE, value:2 }
      ev[i++] = input_event{ type:EV_SYN, code:0, value:0 }

    return ev

  input_event* build_button_flood():
    n := 512 * 8
    num_inst := 2
    input_event *ev = (input_event*) malloc(sizeof(struct input_event) * n * num_inst)
    memset(ev, 0, sizeof(input_event) * n * num_inst)

    i := 0
    while i < n:
      ev[i++] = input_event{ type:EV_SYN, code:1, value:0 }
      ev[i++] = input_event{ type:EV_SYN, code:0, value:1 }

    return ev



  void flood_touch_queue():
    fd := ui::MainLoop::in.touch.fd
    bytes := write(fd, touch_flood, 512 * 8 * 4 * sizeof(input_event))

  // TODO: figure out the right events here to properly flood this device
  void flood_button_queue():
    fd := ui::MainLoop::in.button.fd
    bytes := write(fd, button_flood, 512 * 8 * 2 * sizeof(input_event))



  void launch(string name):
    if name == "":
      return

    debug "LAUNCHING APP", name, CURRENT_APP
    string bin
    string which

    if name != "_" && _launched[0] != name:
      _launched.push_front(name)
      if _launched.size() > 100:
        _launched.pop_back()

    RMApp app
    for auto a : app_dialog->get_apps():
      if a.name == name or a.bin == name:
        app = a
        CURRENT_APP = string(a.name)


    ui::MainLoop::in.ungrab()
    flood_touch_queue()
    flood_button_queue()
    // flood_button_queue()

    if app.resume != "" and proc::check_process(app.which):
      proc::launch_process(app.resume)
    else:
      proc::launch_process(app.bin, true /* check running */, true /* background */)

    // TODO: remove KOReader special codings
    if USE_KOREADER_WORKAROUND and CURRENT_APP == "KOReader":
      ui::MainLoop::in.grab()
      debug "FYI, GRABBING KOREADER INPUTS AWAY AND RESETTING SCREEN DEPTH"
      ui::TaskQueue::add_task([=]() {
        this_thread::sleep_for(chrono::seconds(3));
        fb->set_screen_depth(16)
        ui::MainLoop::in.ungrab()
      })
    else:
      ioctl(ui::MainLoop::in.button.fd, EVIOCGRAB, false)

    ui::MainLoop::hide_overlay()

  // we save the touch input until the finger lifts up
  // so we can analyze whether its a gesture or not
  def save_touch_events():
    for auto ev: ui::MainLoop::in.touch.events:
      if ev.slots[0].left == 0:
        self.check_gesture()
        self.touch_events.clear()
      else:
        // we only track 200 events or so for now
        // simple swipes are about 40 - 50 events
        if self.touch_events.size() < 200:
          self.touch_events.push_back(ev)


  void check_gesture():
    fb := framebuffer::get()
    fw, fh := fb->get_display_size()
    left := -1
    max_y := self.touch_events[0].slots[0].y
    min_y := self.touch_events[0].slots[0].y
    for auto ev: self.touch_events:
      if ev.slots[0].y != -1:
        min_y = min(min_y, ev.slots[0].y)

      if ev.slots[0].x != -1:

        if left == -1:
          if ev.slots[0].x < 100:
            left = true
          else if ev.slots[0].x > fw - 100:
            left = false
          else:
            return

        if left && ev.slots[0].x > 100:
          return
        if !left && ev.slots[0].x < fw - 100:
          return

    if min_y == -1 or max_y == -1:
      return

    y_delta := max_y - min_y
    if y_delta >= 800:
      self.show_launcher()
      return

  string get_xochitl_cmd():
    ifstream f("/lib/systemd/system/xochitl.service")
    string line
    find := "ExecStart"
    default_cmd := "xochitl --system"
    while getline(f, line):
      if line.find(find) != -1:
        tokens := str_utils::split(line, '=')
        if tokens.size() == 1:
          return default_cmd
        tokens.erase(tokens.begin())

        cmd := str_utils::join(tokens, '=')
        debug "XOCHITL CMD IS", cmd
        return cmd

    return default_cmd

  void setup_gestures():
    // TODO: read gesture config from remux.conf file
    // since we want it to be backward compatible, what shall we do?
    // launch_gesture=
    // launch_gesture=
    // launch_gesture=
    // last_app_gesture=

    debug "SETTING UP GESTURES"
    config := read_remux_config()
    launch_gestures := config.get_array("launch_gesture")
    if launch_gestures.size() == 0:
      debug "SETTING LAUNCH GESTURES TO DEFAULT"
      launch_gestures = DEFAULT_LAUNCH_GESTURES

    for auto l : launch_gestures:
      lines := str_utils::split(l, ';')
      gestures := genie::parse_config(lines)
      for auto g : gestures:
        g->events.activate += PLS_LAMBDA(auto d):
          self.show_launcher()
        ;
        ui::MainLoop::gestures.push_back(g)

    back_gestures := config.get_array("back_gesture")
    for auto l : back_gestures:
      lines := str_utils::split(l, ';')
      gestures := genie::parse_config(lines)
      for auto g : gestures:
        g->events.activate += PLS_LAMBDA(auto d):
          self.show_last_app()
        ;
        ui::MainLoop::gestures.push_back(g)

  def run():
    // for koreader
    putenv((char*) "KO_DONT_SET_DEPTH=1")
    putenv((char*) "KO_DONT_GRAB_INPUT=1")


    #ifdef REMARKABLE
    _ := system("systemctl stop xochitl")
    // read the xochitl command line from the systemd file
    xochitl_cmd := get_xochitl_cmd()
    proc::launch_process(xochitl_cmd, true /* check running */, true /* background */)
    #endif

    ui::Style::DEFAULT.font_size = 32

    // launches a thread that suspends on idle
    self.suspend_on_idle()
    self.open_input_fifo()
    self.setup_gestures()


    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)
    // ui::MainLoop::gesture_event += PLS_DELEGATE(self.handle_gesture_event)

    while true:
      ui::MainLoop::main()
      ui::MainLoop::check_resize()
      if ui::MainLoop::overlay_is_visible:
        ui::MainLoop::redraw()

      ui::MainLoop::read_input()
      ui::MainLoop::handle_gestures()

App app
static void _remux_show(int signum):
  app.show_launcher()

def main():
  LAST_ACTION = time(NULL)
  signal(SIGWINCH, _remux_show)
  app.run()
