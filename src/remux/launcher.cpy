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

#define FB_NO_INIT_BPP

#include "../shared/proc.h"
#include "../build/rmkit.h"
#include "../shared/snapshot.h"
#include "../genie/gesture_parser.h"
#include "config.h"

#ifdef REMARKABLE
#define TOUCH_FLOOD_EVENT ABS_DISTANCE
#define DRAW_APP_BEHIND_MODAL
#define READ_XOCHITL_DATA
#define GRAB_INPUT
#define SUSPENDABLE
#elif KOBO
#define TOUCH_FLOOD_EVENT ABS_MT_DISTANCE
#define DYNAMIC_BPP
#define HAS_ROTATION
#define PORTRAIT_ONLY
#define USE_GRAYSCALE_32BIT
#else
#define TOUCH_FLOOD_EVENT ABS_DISTANCE
#endif

#ifdef RMKIT_FBINK
#define TOUCH_FLOOD_EVENT ABS_DISTANCE
#endif

TIMEOUT := 1
// all time is in seconds
MIN := 60
HOURS := MIN * MIN

SUSPEND_THRESHOLD := MIN * 15 // default to 15 minutes
SHUTDOWN_THRESHOLD := HOURS * 10 // 10 hours

#include "apps.h"

DIALOG_WIDTH  := 600
DIALOG_HEIGHT := 800

LAST_ACTION := 0
USE_KOREADER_WORKAROUND := false

MIN_DISPLAY_TIME := 500

string CURRENT_APP = "_"
string NAO_BIN="/opt/bin/nao"
vector<string> SICKEL = { "sickel" }

// start with Remarkable preloaded in the launch list
// so we can switch back to it quickly
deque<string> _launched = { "Remarkable", "_" }

#ifdef HAS_ROTATION
DEFAULT_LAUNCH_GESTURES := vector<string> %{
  "gesture=swipe; direction=up; zone=0 0 0.1 1",
  "gesture=swipe; direction=up; zone=0.9 0 1 1",
  "gesture=swipe; direction=down; zone=0 0 0.1 1",
  "gesture=swipe; direction=down; zone=0.9 0 1 1",
}
#else
DEFAULT_LAUNCH_GESTURES := vector<string> %{
  "gesture=swipe; direction=up; zone=0 0 0.1 1",
  "gesture=swipe; direction=up; zone=0.9 0 1 1",
}
#endif


USB_CHARGER_PATHS := %{
  "/sys/class/power_supply/max77818-charger/online",
  "/sys/class/power_supply/imx_usb_charger/present",
}


CONFIG := read_remux_config()
class IApp:
  public:
  virtual void launch(string) = 0;
  virtual void kill(string) = 0;
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
  bool snapped = false
  map<string, shared_ptr<framebuffer::Snapshot>> app_buffers;

  AppBackground(int x, y, w, h): ui::Widget(x, y, w, h):
    pass

  def snapshot():
    fb := framebuffer::get()
    snapped = true

    vfb := self.get_vfb()
    debug "SNAPSHOTTING", CURRENT_APP

    vfb->save_bpp()
    vfb->compress(fb->fbmem, fb->byte_size)
    vfb->rotation = util::rotation::get()

  shared_ptr<framebuffer::Snapshot> get_vfb():
    if app_buffers.find(CURRENT_APP) == app_buffers.end():
      vw, vh := fb->get_virtual_size()
      app_buffers[CURRENT_APP] = make_shared<framebuffer::Snapshot>(vw, vh)
      app_buffers[CURRENT_APP]->rotation = util::rotation::get()

    return app_buffers[CURRENT_APP]

  void remove_vfb(string name):
    if app_buffers.find(name) != app_buffers.end():
      app_buffers.erase(name)

  void render():
    if not snapped:
      return

    vfb := self.get_vfb()
    debug "RENDERING", CURRENT_APP
    if rm2fb::IN_RM2FB_SHIM:
      fb->waveform_mode = WAVEFORM_MODE_GC16
    else:
      fb->waveform_mode = WAVEFORM_MODE_AUTO

    vfb->decompress(fb->fbmem)

    #ifdef DYNAMIC_BPP
    if CURRENT_APP == APP_MAIN.name:
      fb->set_screen_depth(APP_MAIN.bpp)
    else:
      fb->set_screen_depth(vfb->bits_per_pixel)
    #endif

    #ifdef HAS_ROTATION
    if vfb->rotation != -1:
      fb->set_rotation(vfb->rotation)
    #endif

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
      self.opt_h = 55
      self.page_size = (self.h - 100) / self.opt_h
      self.buttons = { "Get More Apps" }

    void add_shortcuts():
      // draw suspend button in bottom right
      _w, _h := fb->get_display_size()
      #ifdef SUSPENDABLE
      h_layout := ui::HorizontalLayout(0, 0, _w, _h, self.scene)
      v_layout := ui::VerticalLayout(0, 0, _w, _h, self.scene)

      b1 := new SuspendButton(0, 0, 200, 50, self.app)
      h_layout.pack_end(b1)
      v_layout.pack_end(b1)
      #endif

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
      #ifndef DRAW_APP_BEHIND_MODAL
      fb->clear_screen()
      #endif
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
      self.hide()

    void render_row(ui::HorizontalLayout *row, string option):
      status := string("")
      bin := string("")
      app_name := string("")
      for auto app : self.reader.apps:
        if app.name == option or app.bin == option:
          bin = app.bin
          app_name = app.name
          if app.is_running:
            used := app.mem_usage / 1024
            if app.mem_usage == 0:
              status = "?MB"
            else:
              status = to_string(app.mem_usage / 1024) + string("MB")

      c := new ui::Button(0, 0, 100, self.opt_h, status)

      if bin != "":
        c->mouse.click += PLS_LAMBDA(auto &ev) {
          if app_name == APP_NICKEL.name:
            return

          app->kill(app_name)

          if status != "":
            c->text = "killed"
            c->dirty = 1
        }

      c->set_style(ui::Stylesheet().justify_right())
      d := new ui::DialogButton(0, 0, self.w-120, self.opt_h, self, option)
      d->x_padding = 10
      d->y_padding = 5
      d->set_style(ui::Stylesheet().justify_left())
      self.layout->pack_start(row)
      row->pack_start(d)
      row->pack_end(c)

class App: public IApp:
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
  std::chrono::system_clock::time_point last_display_time

  static int lastpress = RAND_MAX
  static int event_press_id = 0


  public:
  App():
    fb = framebuffer::get()

    // on resize, we exit and trust our service to restart us
    fb->resize += [=](auto &e):
      debug "EXITING BECAUSE OF RESOLUTION CHANGE"
      exit(1)
    ;

    w, h = fb->get_display_size()

    if app_dialog != NULL:
      delete app_dialog
    if app_bg != NULL:
      delete app_bg

    dh := CONFIG.get_value("dialog_height", to_string(DIALOG_HEIGHT))
    dw := CONFIG.get_value("dialog_width", to_string(DIALOG_WIDTH))
    try {
      DIALOG_HEIGHT = stoi(dh.c_str())
    } catch(...) {};

    try {
      DIALOG_WIDTH = stoi(dw.c_str());
    } catch(...) {};
    app_dialog = new AppDialog(0, 0, DIALOG_WIDTH, DIALOG_HEIGHT, self)
    app_dialog->populate()
    get_current_app()
    debug "CURRENT APP IS", CURRENT_APP

    app_dialog->on_hide += PLS_LAMBDA(auto &d):
      now := std::chrono::system_clock::now();
      int_ms := std::chrono::duration_cast<std::chrono::milliseconds>(now - last_display_time);

      debug "DISPLAYED LAUNCHER FOR", int_ms.count(), "MS"
      if int_ms.count() < MIN_DISPLAY_TIME:
        debug "NOT HIDING LAUNCHER BECAUSE INTERVAL < ", MIN_DISPLAY_TIME
        app_dialog->show()
        return

      launch(CURRENT_APP)
      self.render_bg()
      // we put the unmonitor in a timeout to prevent
      // pen events from interrupting remux from displaying
      ui::set_timeout([=]() {
        ui::MainLoop::in.unmonitor(ui::MainLoop::in.wacom.fd)
      }, 10)
      if USE_KOREADER_WORKAROUND and CURRENT_APP != "KOReader":
        ui::MainLoop::in.ungrab()
    ;

    app_bg = new AppBackground(0, 0, w, h)

    touch_flood = build_touch_flood()
    button_flood = build_button_flood()

    notebook := ui::make_scene()
    #ifdef DRAW_APP_BEHIND_MODAL
    notebook->add(app_bg)
    #endif
    ui::MainLoop::set_scene(notebook)

    #ifdef READ_XOCHITL_DATA
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
        CURRENT_APP = active.name
        return


  RMApp get_app_by_name(string name):
    RMApp active

    vector<string> binaries;
    for auto a : app_dialog->get_apps():
      if a.name == name:
        active = a
        return active

    active.name = "<NO APP>"
    active.bin = "/bin/false"
    active.manage_power = true
    return active



  def handle_api_line(string line):
    str_utils::trim(line)
    debug "HANDLING API LINE", line
    if line == "":
      return

    if line == "show":
      self.show_launcher()
    else if line == "hide":
      app_dialog->hide()
    else if line == "back":
      app_dialog->hide()
      self.show_last_app()
    else if line == "suspend":
      if not ui::MainLoop::overlay_is_visible():
        app_bg->snapshot()
      on_suspend()
    else if line.find("launch ") == 0:
      tokens := str_utils::split(line, ' ')
      if len(tokens) > 1:
        name := tokens[1]
        api_launch_app(name)
    else if line.find("pause ") == 0:
      tokens := str_utils::split(line, ' ')
      if len(tokens) > 1:
        name := tokens[1]
        api_pause_app(name)
    else if line.find("stop ") == 0:
      tokens := str_utils::split(line, ' ')
      if len(tokens) > 1:
        name := tokens[1]
        api_stop_app(name)

    else:
      debug "UNKNOWN API LINE:", line

  def open_input_fifo():
    #if !defined(REMARKABLE) && !defined(KOBO)
    return
    #endif

    debug "STARTING FIFO THREAD"

    _ := system("mkdir /run/ 2> /dev/null")
    _ = system("/usr/bin/mkfifo /run/remux.api 2>/dev/null")
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
    debug "STARTING SUSPEND THREAD"
    version := util::get_remarkable_version()
    self.idle_thread = new thread([=]() {
      last_wake := 0
      while true:
        now := time(NULL)
        // if its been more than 2 minute since our last loop iteration,
        // we may have just woken up. in this case, we reset the idle timer
        // so we don't fall back asleep immediately
        if now - last_wake > 2*MIN:
          debug "LAST SUSPEND LOOP WAS", (now - last_wake), "AGO, RESETTING IDLE TIMER"
          suspend_m.lock()
          LAST_ACTION = now
          suspend_m.unlock()
        last_wake = now

        usb_in := false
        string usb_str


        for auto fname : USB_CHARGER_PATHS:
          usb_cmd := "cat " + string(fname) + " 2>/dev/null"

          usb_str = string(exec(usb_cmd.c_str()))
          str_utils::trim(usb_str)
          usb_in = usb_str == string("1")
          if usb_in:
            break

        app := get_app_by_name(CURRENT_APP)

        suspend_m.lock()
        if LAST_ACTION == 0 or usb_in:
          LAST_ACTION = now

        // check if we should manage this app's power
        // an app can turn this off by using manage_power=false in its draft file
        if !app.manage_power:
          LAST_ACTION = now
        last_action := LAST_ACTION
        suspend_m.unlock()

        if last_action > 0 and SUSPEND_THRESHOLD > 0:
          if now - last_action > SUSPEND_THRESHOLD and now - last_action < 2*SUSPEND_THRESHOLD:
            if not ui::MainLoop::overlay_is_visible():
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

  void api_launch_app(string name):
    app := find_app(name)
    if app.bin != "":
      debug "USING API TO LAUNCH", name
      app_dialog->hide()
      self.term_apps()
      self.app_bg->snapshot()
      self.launch(name)
      self.render_bg()
    else:
      debug "NO SUCH APP:", name


  void api_pause_app(string name):
    app := find_app(name)
    get_current_app()
    if app.name == CURRENT_APP:
      debug "USING API TO PAUSE", name
      self.show_launcher()

  void api_stop_app(string name):
    app := find_app(name)
    if app.bin != "":
      debug "USING API TO STOP", name
      get_current_app()
      self.kill(name)
      if name == CURRENT_APP:
        self.show_launcher()
      #ifdef REMARKABLE
      else if name == "xochitl" and CURRENT_APP == APP_XOCHITL.name:
        self.show_launcher()
      #elif KOBO
      else if name == "nickel" and CURRENT_APP == APP_NICKEL.name:
        self.show_launcher()
      #endif


  void show_launcher():
    if ui::MainLoop::overlay_is_visible():
      return

    #ifdef PORTRAIT_ONLY
    if fb->width > fb->height:
      debug "NOT SHOWING LAUNCHER IN LANDSCAPE"
      return
    #endif

    #ifdef HAS_ROTATION
    util::rotation::reset()
    input::TouchEvent::set_rotation()
    #endif

    last_display_time = std::chrono::system_clock::now();

    ui::MainLoop::in.monitor(ui::MainLoop::in.wacom.fd)
    ClockWatch cz

    ClockWatch c0
    get_current_app()
    debug "CURRENT APP IS", CURRENT_APP
    debug "current app took", c0.elapsed()

    // this is really backgrounding apps, not terminating
    ClockWatch c1
    term_apps()
    debug "stopping apps took", c1.elapsed()

    app_bg->snapshot()

    app_dialog->populate()
    app_dialog->setup_for_render()
    app_dialog->add_shortcuts()
    app_dialog->show()

    // TODO: do we really need to grab?
    #ifdef GRAB_INPUT
    ui::MainLoop::in.grab()
    #endif

    #ifdef DYNAMIC_BPP
    fb->set_screen_depth(sizeof(remarkable_color)*8)
    #endif

  def handle_key_event(input::SynKeyEvent ev):
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
    #ifdef KOBO
    proc::groupkill(SIGSTOP, SICKEL)
    #endif

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
    // suspend only works on REMARKABLE
    #ifndef SUSPENDABLE
    return
    #endif

    debug "SUSPENDING"
    app_dialog->hide()

    _w, _h := fb->get_display_size()

    if file_exists("/usr/share/remarkable/sleeping.png"):
      fb->load_from_png("/usr/share/remarkable/sleeping.png")
    else:
      fb->load_from_png("/usr/share/remarkable/suspended.png")


    fb->redraw_screen()
    #ifdef GRAB_INPUT
    ui::MainLoop::in.grab()
    #endif

    if rm2fb::IN_RM2FB_SHIM:
      sleep(1)
      _ := system("systemctl suspend")
      sleep(1)

      if system("lsmod | grep brcmfmac") == 0:
        debug "RELOADING WIFI DRIVERS"
        _ = system("modprobe -r brcmfmac brcmutil")
        _ = system("modprobe brcmfmac brcmutil")
    else:
      slept_at := time(NULL)
      if SHUTDOWN_THRESHOLD > 0:
        cmd := "echo " + to_string(SHUTDOWN_THRESHOLD + slept_at) + " > /sys/class/rtc/rtc0/wakealarm"

        _ := system(cmd.c_str())
      sleep(1)
      _ := system("systemctl suspend")
      sleep(1)

      now := time(NULL)
      if SHUTDOWN_THRESHOLD > 0 && now - slept_at >= SHUTDOWN_THRESHOLD:
        debug "RESUMING FROM SUSPEND -> SHUTDOWN"
        _ := system("systemctl poweroff")
        return

      // reset LAST_ACTION after wake so we don't go into sleep loop
      LAST_ACTION = time(NULL)

      _ = system("echo 0 > /sys/class/rtc/rtc0/wakealarm")

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
      ev[i++] = input_event{ type:EV_ABS, code:TOUCH_FLOOD_EVENT, value:1 }
      ev[i++] = input_event{ type:EV_SYN, code:0, value:0 }
      ev[i++] = input_event{ type:EV_ABS, code:TOUCH_FLOOD_EVENT, value:2 }
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

    ui::MainLoop::reset_gestures()

  // TODO: figure out the right events here to properly flood this device
  void flood_button_queue():
    fd := ui::MainLoop::in.button.fd
    bytes := write(fd, button_flood, 512 * 8 * 2 * sizeof(input_event))


  void kill(string name):
    bin := string("")
    for auto app : app_dialog->get_apps():
      if app.name == name:
        bin = app.bin
      #ifdef REMARKABLE
      else if name == "xochitl" and app.name == APP_XOCHITL.name:
        bin = app.bin
      #elif KOBO
      else if (name == "Nickel" or name == "nickel") and app.name == APP_NICKEL.name:
        bin = app.bin
      #endif

    if bin == "":
      return

    vector<string> bins = { bin }
    proc::groupkill(SIGKILL, bins)
    app_bg->remove_vfb(name)

  RMApp find_app(string name):
    RMApp app
    app.bin = ""
    app.name = ""
    for auto a : app_dialog->get_apps():
      if a.name == name or a.bin == name:
        app = a

    return app


  void launch(string name):
    if name == "":
      return

    debug "LAUNCHING APP", name, CURRENT_APP

    app := find_app(name)
    if app.name == "" && app.bin == "":
      debug "CANT LAUNCH APP", name
      return
    CURRENT_APP = string(app.name)
    debug "POWER MANAGEMENT:", app.manage_power

    if name != "_" && _launched[0] != name:
      _launched.push_front(name)
      if _launched.size() > 100:
        _launched.pop_back()


    ui::MainLoop::in.ungrab()
    flood_touch_queue()
    flood_button_queue()
    // flood_button_queue()

    bin := app.bin
    if app.which == APP_XOCHITL.which:
      bin = get_xochitl_cmd()

    if app.which == APP_NICKEL.which:
      proc::groupkill(SIGCONT, SICKEL)

    if app.resume != "" and proc::check_process(app.which):
      proc::launch_process(app.resume)
    else:
      proc::launch_process(bin, true /* check running */, true /* background */)

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

    app_dialog->hide()


  string get_xochitl_cmd():
    location := "/tmp/remux.xochitl_cmd"
    if system("systemctl cat xochitl.service > /tmp/remux.xochitl_cmd") != 0:
      // if we failed reading with systemctl, use hardcoded path
      debug "COULDNT READ XOCHITL CMD FROM SYSTEMCTL, DEFAULTING TO /LIB"
      location = "/lib/systemd/system/xochitl.service"

    ifstream f(location)
    string line
    find := "ExecStart"
    default_cmd := string("xochitl --system")
    cmd := string(default_cmd)
    while getline(f, line):
      if line.find(find) != -1:
        tokens := str_utils::split(line, '=')
        if tokens.size() == 1:
          continue
        tokens.erase(tokens.begin())

        cmd = str_utils::join(tokens, '=')

    debug "XOCHITL CMD IS", cmd
    return cmd

  void setup_gestures():
    // launch_gesture=
    // last_app_gesture=

    debug "SETTING UP GESTURES"
    launch_gestures := CONFIG.get_array("launch_gesture")
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

    back_gestures := CONFIG.get_array("back_gesture")
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

    #if defined(REMARKABLE)
    _ := system("systemctl stop xochitl")
    self.term_apps()
    startup_cmd := CONFIG.get_value("start_app", "xochitl")
    launch(startup_cmd)
    #endif

    #ifdef DYNAMIC_BPP
    get_current_app()
    if APP_MAIN.name == CURRENT_APP:
      debug "RESETTING BPP TO", APP_MAIN.bpp
      fb->set_screen_depth(APP_MAIN.bpp)
    #endif

    ui::Style::DEFAULT.font_size = 32

    // launches a thread that suspends on idle
    handle_power_mgmt := CONFIG.get_bool("manage_power", true)
    if handle_power_mgmt:
      self.suspend_on_idle()
    else:
      debug "NOT HANDLING POWER MANAGEMENT"
    self.open_input_fifo()
    self.setup_gestures()

    filter_palm_events := CONFIG.get_bool("filter_palm_events", false)
    if filter_palm_events:
      debug "ENABLED PALM EVENT FILTER"
      ui::MainLoop::filter_palm_events = true

    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)

    ui::MainLoop::in.unmonitor(ui::MainLoop::in.wacom.fd)

    while true:
      ui::MainLoop::main()
      ui::MainLoop::check_resize()
      if ui::MainLoop::overlay_is_visible():
        ui::MainLoop::redraw()

      ui::MainLoop::read_input(1000)
      ui::MainLoop::handle_gestures()

  vector<RMApp> get_apps():
    return self.app_dialog->get_apps()

App app
def main(int argc, char **argv):
  if argc > 1:
    std::string flag(argv[1])
    str_utils::trim(flag)
    if flag == "--all-apps":
      vector<string> apps
      for auto a : app.get_apps():
        #ifdef REMARKABLE
        if a.name == APP_XOCHITL.name:
          apps.push_back("xochitl")
        else:
          apps.push_back(a.name)
        #elif KOBO
        if a.name == APP_NICKEL.name:
          apps.push_back("nickel")
        else:
          apps.push_back(a.name)
        #else
        apps.push_back(a.name)
        #endif

      for auto name : apps:
        print name

    else if flag == "--current-app":
      for auto a : app.get_apps():
        // Only if it is running
        if !a.is_running or (!proc::is_running(a.which) and !proc::is_running(a.bin)):
          continue

        #ifdef REMARKABLE
        if a.name == APP_XOCHITL.name:
          print "xochitl"
        else:
          print a.name
        #elif KOBO
        if a.name == APP_NICKEL.name:
          print "nickel"
        else:
          print a.name
        #else
        print a.name
        #endif
        break

    else if flag == "--paused-apps":
      vector<string> apps
      for auto a : app.get_apps():
        // Only if not in the list, and if it is currently running
        if !a.is_running or std::find(apps.begin(), apps.end(), a.name) != apps.end():
          continue

        // Ignore current application
        if proc::is_running(a.which) or proc::is_running(a.bin):
          continue

        #ifdef REMARKABLE
        if a.name == APP_XOCHITL.name:
          apps.push_back("xochitl")
        else:
          apps.push_back(a.name)
        #elif KOBO
        if a.name == APP_NICKEL.name:
          apps.push_back("nickel")
        else:
          apps.push_back(a.name)
        #else
        apps.push_back(a.name)
        #endif

      for auto name : apps:
        print name

    else:
      print "Usage:", argv[0], "[--help|--current-app|--paused-apps|--all-apps]"

  else:
    LAST_ACTION = time(NULL)
    app.run()
