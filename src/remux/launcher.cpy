// LAUNCHER FOR REMARKABLE
#include <time.h>
#include <thread>
#include <chrono>

#include <time.h>
#include <sys/types.h>
#include <sys/time.h>
#include <dirent.h>
#include <algorithm>
#include <unordered_set>
#include <linux/input.h>
#include <chrono>

#include "../shared/proc.h"
#include "../build/rmkit.h"

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

class IApp:
  public:
  virtual void launch(string) = 0;
  virtual void on_suspend() = 0;
  virtual void get_more() = 0;


class ClockWatch:
  public:
  chrono::high_resolution_clock::time_point t1

  ClockWatch():
    t1 = chrono::high_resolution_clock::now();

  def elapsed():
    t2 := chrono::high_resolution_clock::now();
    chrono::duration<double> time_span = chrono::duration_cast<chrono::duration<double>>(t2 - t1)
    return time_span.count()

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
    fb->waveform_mode = WAVEFORM_MODE_AUTO
    memcpy(fb->fbmem, vfb->fbmem, self.byte_size)
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
        b3->set_justification(ui::Text::JUSTIFY::RIGHT)
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
      for auto app : self.reader.apps:
        if app.name == option or app.bin == option:
          if app.is_running:
            status = to_string(app.mem_usage / 1024) + string("MB")

      c := new ui::Text(0, 10, 100, self.opt_h, status)
      c->justify = ui::Text::JUSTIFY::RIGHT
      d := new ui::DialogButton(0, 0, self.w-90, self.opt_h, self, option)
      d->x_padding = 10
      d->y_padding = 5
      d->set_justification(ui::Text::JUSTIFY::LEFT)
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


  def suspend_on_idle():
    self.idle_thread = new thread([=]() {
      while true:
        now := time(NULL)
        usb_in := false
        usb_str := string(exec("cat /sys/class/power_supply/imx_usb_charger/present"))
        str_utils::trim(usb_str)
        usb_in = usb_str == string("1")
        threshold := SUSPEND_THRESHOLD
        if usb_in:
          threshold = CHARGING_THRESHOLD

        suspend_m.lock()
        if LAST_ACTION == 0 or usb_in:
          LAST_ACTION = now
        last_action := LAST_ACTION
        suspend_m.unlock()

        if last_action > 0:
          if now - last_action > SUSPEND_THRESHOLD and now - LAST_ACTION < TOO_MUCH_THRESHOLD:
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

  def show_launcher():
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

  // TODO: power button will cause suspend screen, why not?
  void on_suspend():
    #ifndef REMARKABLE
    return
    #endif

    debug "SUSPENDING"
    ui::MainLoop::hide_overlay()

    _w, _h := fb->get_display_size()

    #ifdef REMARKABLE
    fb->load_from_png("/usr/share/remarkable/sleeping.png")
    #else
    text := ui::Text(0, _h-64, _w, 100, "Press any button to wake")
    text.font_size = 64
    text.justify = ui::Text::JUSTIFY::CENTER

    text.undraw()
    text.render()
    #endif


    fb->redraw_screen()
    ui::MainLoop::in.grab()

    #ifdef REMARKABLE
    cmd := "/usr/sbin/rtcwake -m no --seconds " + to_string(SHUTDOWN_THRESHOLD)
    _ := system(cmd.c_str())
    _ = system("systemctl suspend")
    sleep(1)

    now := time(NULL)
    if now - LAST_ACTION >= SHUTDOWN_THRESHOLD:
      debug "RESUMING FROM SUSPEND -> SHUTDOWN"
      _ := system("systemctl poweroff")
      return

    _ = system("/usr/sbin/rtcwake --seconds 0 -m disable")
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
      ev[i++] = input_event{ type:EV_ABS, code:ABS_DISTANCE, value:0 }
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

    debug "LAUNCHING APP", name
    string bin
    string which

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

    ui::Text::DEFAULT_FS = 32

    // launches a thread that suspends on idle
    self.suspend_on_idle()

    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)
    // ui::MainLoop::gesture_event += PLS_DELEGATE(self.handle_gesture_event)

    while true:
      ui::MainLoop::main()
      ui::MainLoop::check_resize()
      if ui::MainLoop::overlay_is_visible:
        ui::MainLoop::redraw()

      ui::MainLoop::read_input()
      self.save_touch_events()

App app
def main():
  app.run()
