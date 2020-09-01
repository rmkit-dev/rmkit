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

#include "../shared/proc.h"
#include "../build/rmkit.h"

TIMEOUT := 1
SUSPEND_TIMER := 10
SUSPEND_THRESHOLD := 60 * 4 // 4 mins
//SUSPEND_THRESHOLD := 20
TOO_MUCH_THRESHOLD := 60 * 7 // 7 mins

#include "apps.h"

DIALOG_WIDTH  := 400
DIALOG_HEIGHT := 800

LAST_ACTION := 0

string CURRENT_APP = "_"

class IApp:
  public:
  virtual void launch(string) = 0;
  virtual void on_suspend() = 0;

class SuspendButton: public ui::Button:
  public:
  IApp *app
  SuspendButton(int x, int y, int w, int h, IApp *a): ui::Button(x, y, w, h, "Suspend"):
    self.app = a

  void on_mouse_click(input::SynMouseEvent &ev):
    self.app->on_suspend()

class AppBackground: public ui::Widget:
  public:
  int byte_size
  bool snapped = false
  map<string, framebuffer::FileFB*> app_buffers;

  AppBackground(int x, y, w, h): ui::Widget(x, y, w, h):
    self.byte_size = w*h*sizeof(remarkable_color)

  def snapshot():
    fb := framebuffer::get()
    snapped = true

    vfb := self.get_vfb()
    print "SNAPSHOTTING", CURRENT_APP
    vfb->fbmem = (remarkable_color*) memcpy(vfb->fbmem, fb->fbmem, self.byte_size)

  framebuffer::FileFB* get_vfb():
    if app_buffers.find(CURRENT_APP) == app_buffers.end():
      fw, fh := fb->get_display_size()
      fname := string(BIN_DIR) + "." + CURRENT_APP + ".fb"
      app_buffers[CURRENT_APP] = new framebuffer::FileFB(fname, fw, fh)
      app_buffers[CURRENT_APP]->clear_screen()

    return app_buffers[CURRENT_APP]

  void render():
    if not snapped:
      return

    vfb := self.get_vfb()
    print "RENDERING", CURRENT_APP
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

    void add_shortcuts():
      _w, _h := fb->get_display_size()
      h_layout := ui::HorizontalLayout(0, 0, _w, _h, self.scene)
      v_layout := ui::VerticalLayout(0, 0, _w, _h, self.scene)
      b1 := new SuspendButton(0, 0, 200, 50, self.app)
      h_layout.pack_end(b1)
      v_layout.pack_end(b1)


    void render():
      ui::Pager::render()
      self.fb->draw_line(self.x+self.w, self.y, self.x+self.w, self.y+self.h, 2, BLACK)

    void populate():
      self.reader.populate()
      self.options = self.reader.get_binaries()

    vector<RMApp> get_apps():
      return self.reader.apps

    void on_row_selected(string name):
      CURRENT_APP = name
      ui::MainLoop::hide_overlay()

    void render_row(ui::HorizontalLayout *row, string option):
      d := new ui::DialogButton(0, 0, self.w-80, self.opt_h, self, option)
      d->x_padding = 50
      d->y_padding = 5
      d->set_justification(ui::Text::JUSTIFY::LEFT)
      self.layout->pack_start(row)
      row->pack_start(d)

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
    RMApp active
    app_dialog->populate()
    for auto a : app_dialog->get_apps():
      print "CHECKING", a.which
      if proc::is_running(a.which):
        active = a

    print "CURRENT APP IS", active.name
    CURRENT_APP = active.name

    app_bg = new AppBackground(0, 0, w, h)

    touch_flood = build_touch_flood()
    button_flood = build_button_flood()

    notebook := ui::make_scene()
    notebook->add(app_bg)
    ui::MainLoop::set_scene(notebook)

  def do_suspend():
    #ifdef REMARKABLE
    self.on_suspend()
    #endif
    return

  def suspend_on_idle():
    self.idle_thread = new thread([=]() {
      while true:
        now := time(NULL)
        usb_in := false
        // usb_in = system("ifconfig usb0 > /dev/null 2>/dev/null") == 0

        suspend_m.lock()
        if LAST_ACTION == 0 or usb_in:
          LAST_ACTION = now
        last_action := LAST_ACTION
        suspend_m.unlock()

        if last_action > 0:
          if now - last_action > SUSPEND_THRESHOLD and now - LAST_ACTION < TOO_MUCH_THRESHOLD:
            suspend_m.lock()
            LAST_ACTION = 0
            suspend_m.unlock()
            if not ui::MainLoop::overlay_is_visible:
              app_bg->snapshot()
            do_suspend()
        this_thread::sleep_for(chrono::seconds(10));

    });

  def handle_motion_event(input::SynMouseEvent ev):
    suspend_m.lock()
    LAST_ACTION = time(NULL)
    suspend_m.unlock()

  void render_bg():
    app_bg->render()
    ui::MainLoop::redraw()

  def show_launcher():
    if ui::MainLoop::overlay_is_visible:
      return


    // this is really backgrounding apps, not terminating
    term_apps()

    app_bg->snapshot()
    this_thread::sleep_for(chrono::milliseconds(200));
    app_dialog->populate()
    app_dialog->setup_for_render()
    app_dialog->add_shortcuts()
    app_dialog->show()
    app_dialog->scene->on_hide += PLS_LAMBDA(auto &d):
      self.render_bg()
      launch(CURRENT_APP)
      ui::MainLoop::in.ungrab()
    ;

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
    for auto a : app_dialog->get_apps():
      if a.name != name:
        if a.term != "":
          proc::launch_process(a.term, false)
        else:
          cstr := a.bin.c_str()
          base := basename((char *) cstr)
          stop_cmd := "killall -SIGSTOP " + string(base) + " 2>/dev/null"
          proc::launch_process(stop_cmd)

  // TODO: power button will cause suspend screen, why not?
  void on_suspend():
    print "SUSPENDING"
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
    _ := system("systemctl suspend")
    #endif
    sleep(1)

    print "RESUMING FROM SUSPEND"
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
      print "COULDNT WRITE EV", errno


  input_event* build_touch_flood():
    n := 512 * 8
    num_inst := 4
    input_event *ev = (input_event*) malloc(sizeof(struct input_event) * n * num_inst)
    memset(ev, 0, sizeof(input_event) * n * num_inst)

    i := 0
    while i < n:
      ev[i++] = { .type=EV_ABS, .code=ABS_DISTANCE, .value=1 }
      ev[i++] = { .type=EV_SYN, .code=0, .value=0 }
      ev[i++] = { .type=EV_ABS, .code=ABS_DISTANCE, .value=0 }
      ev[i++] = { .type=EV_SYN, .code=0, .value=0 }

    return ev

  input_event* build_button_flood():
    n := 512 * 8
    num_inst := 2
    input_event *ev = (input_event*) malloc(sizeof(struct input_event) * n * num_inst)
    memset(ev, 0, sizeof(input_event) * n * num_inst)

    i := 0
    while i < n:
      ev[i++] = { .type=EV_SYN, .code=1, .value=0 }
      ev[i++] = { .type=EV_SYN, .code=0, .value=1 }

    return ev



  void flood_touch_queue():
    fd := ui::MainLoop::in.touch.fd
    bytes := write(fd, touch_flood, 512 * 8 * 4 * sizeof(input_event))

  // TODO: figure out the right events here to properly flood this device
  void flood_button_queue():
    fd := ui::MainLoop::in.button.fd
    bytes := write(fd, button_flood, 512 * 8 * 2 * sizeof(input_event))



  void launch(string name):
    print "LAUNCHING APP", name
    string bin

    for auto a : app_dialog->get_apps():
      if a.name == name:
        bin = a.bin
        CURRENT_APP = string(a.name)

    term_apps(name)

    ui::MainLoop::in.ungrab()
    flood_touch_queue()
    flood_button_queue()
    // flood_button_queue()
    proc::launch_process(bin, true /* check running */, true /* background */)
    ui::MainLoop::hide_overlay()

  // we save the touch input until the finger lifts up
  // so we can analyze whether its a gesture or not
  def save_input():
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
    y_delta := self.touch_events[0].slots[0].y - self.touch_events.back().slots[0].y
    print self.touch_events.size()
    for auto ev: self.touch_events:
      if ev.slots[0].x == -1:
        continue

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

    if y_delta >= 300:
      self.show_launcher()
      return
    print "no", y_delta


  def run():
    system("systemctl xochitl stop")
    proc::launch_process("xochitl", true /* check running */, true /* background */)

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
      self.save_input()

App app
def main():
  app.run()
