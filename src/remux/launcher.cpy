// LAUNCHER FOR REMARKABLE
#include <time.h>
#include <thread>
#include <chrono>

#include <time.h>
#include <sys/types.h>
#include <dirent.h>
#include <algorithm>
#include <unordered_set>

#include "../shared/proc.h"
#include "../build/rmkit.h"

TIMEOUT := 2
SUSPEND_TIMER := 10
SUSPEND_THRESHOLD := 60 * 4 // 4 mins
TOO_MUCH_THRESHOLD := 60 * 7 // 7 mins

#include "apps.h"

DIALOG_WIDTH  := 400
DIALOG_HEIGHT := 800

LAST_ACTION := 0

class IApp:
  public:
  virtual void selected(string) = 0;
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
  char *buf
  int byte_size
  bool snapped = false
  framebuffer::VirtualFB *vfb

  AppBackground(int x, y, w, h): ui::Widget(x, y, w, h):
    self.byte_size = w*h*sizeof(remarkable_color)
    fw, fh := fb->get_display_size()
    self.vfb = new framebuffer::VirtualFB(fw, fh)

    buf = (char*) self.vfb->fbmem

  def load_from_file():
    self.vfb->load_from_png("/usr/share/remarkable/suspended.png")

  def snapshot():
    fb := framebuffer::get()
    snapped = true
    memcpy(buf, fb->fbmem, self.byte_size)

  void render():
    if not snapped:
      return

    fb->waveform_mode = WAVEFORM_MODE_AUTO
    memcpy(fb->fbmem, buf, self.byte_size)
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

    void add_shortcuts():
      _w, _h := fb->get_display_size()
      h_layout := ui::HorizontalLayout(0, 0, _w, _h, self.scene)
      v_layout := ui::VerticalLayout(0, 0, _w, _h, self.scene)
      b1 := new SuspendButton(0, 0, 200, 50, self.app)
      h_layout.pack_end(b1)
      v_layout.pack_end(b1)

      self.scene->on_hide += PLS_LAMBDA(auto &d):
        ui::MainLoop::in.ungrab()
      ;

    void render():
      ui::Pager::render()
      self.fb->draw_line(self.x+self.w, self.y, self.x+self.w, self.y+self.h, 2, BLACK)

    void position_dialog():
      print "NOT POSITIONING APP DIALOG"
      return

    void populate():
      self.reader.populate()
      self.options = self.reader.get_binaries()

    vector<RMApp> get_apps():
      return self.reader.apps

    void on_row_selected(string name):
      app->selected(name)
      ui::MainLoop::hide_overlay()

    void render_row(ui::HorizontalLayout *row, string option):
      d := new ui::DialogButton(0, 0, self.w, self.opt_h, self, option)
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

    app_dialog = new AppDialog(0, 0, 400, h, self)
    app_bg = new AppBackground(0, 0, w, h)

    notebook := ui::make_scene()
    notebook->add(app_bg)
    ui::MainLoop::set_scene(notebook)

  def do_suspend():
    print "SUSPENDING"
    #ifdef REMARKABLE
    self.on_suspend()
    #endif
    return

  def suspend_on_idle():
    thread *th = new thread([=]() {
      while true:
        suspend_m.lock()
        last_action := LAST_ACTION
        suspend_m.unlock()
        now := time(NULL)
        if last_action > 0:
          if now - last_action > SUSPEND_THRESHOLD and now - LAST_ACTION < TOO_MUCH_THRESHOLD:
            suspend_m.lock()
            LAST_ACTION = 0
            suspend_m.unlock()
            if not app_bg->visible:
              app_bg->snapshot()
            do_suspend()
        this_thread::sleep_for(chrono::seconds(10));
    });

  def handle_motion_event(input::SynMouseEvent ev):
    suspend_m.lock()
    LAST_ACTION = time(NULL)
    suspend_m.unlock()

  def handle_key_event(input::SynKeyEvent ev):
    static int lastpress = RAND_MAX
    static int event_press_id = 0
    ui::MainLoop::handle_key_event(ev)

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
              if is_pressed && event_press_id == ev.id
                now := time(NULL)
                if now - lastpress > 1:
                  ui::TaskQueue::add_task([=] {
                    app_bg->visible = true
                    app_bg->snapshot()
                    app_dialog->populate()
                    app_dialog->setup_for_render()
                    app_dialog->add_shortcuts()
                    app_dialog->show()
                    ui::MainLoop::in.grab()
                  });
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
    ui::MainLoop::hide_overlay()
    app_bg->render()
    ui::MainLoop::redraw()

    print "SUSPENDING"
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

    #ifdef REMARKABLE
    _ := system("systemctl suspend")
    #endif
    sleep(1)

    print "RESUMING FROM SUSPEND"
    ui::MainLoop::in.ungrab()

    fb->clear_screen()
    app_bg->render()
    fb->redraw_screen(true)


  void selected(string name):
    print "LAUNCHING APP", name
    string bin

    for auto a : app_dialog->get_apps():
      if a.name == name:
        bin = a.bin

    term_apps(name)

    ui::MainLoop::in.ungrab()
    proc::launch_process(bin, true /* check running */, true /* background */)
    ui::MainLoop::hide_overlay()

    app_bg->render()
    ui::MainLoop::redraw()

    app_bg->visible = false

  def run():
    ui::Text::DEFAULT_FS = 32

    self.suspend_on_idle()

    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)
    while true:
      ui::MainLoop::main()
      ui::MainLoop::check_resize()
      if app_bg->visible:
        ui::MainLoop::redraw()

      ui::MainLoop::read_input()

App app
def main():
  app.run()
