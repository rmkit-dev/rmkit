// LAUNCHER FOR REMARKABLE
#include <csignal>
#include <time.h>
#include <thread>
#include <chrono>

#include "../shared/proc.h"
#include "../build/rmkit.h"

#define TIMEOUT 2

#include "config.launcher.h"

DIALOG_WIDTH  := 600
DIALOG_HEIGHT := 800

class AppBackground: public ui::Widget:
  public:
  char *buf
  int byte_size

  AppBackground(int x, y, w, h): ui::Widget(x, y, w, h):
    self.byte_size = w*h*sizeof(remarkable_color)
    buf = (char*) malloc(self.byte_size)

  def snapshot():
    fb := framebuffer::get()
    memcpy(buf, fb->fbmem, self.byte_size)

  void redraw():
    memcpy(fb->fbmem, buf, self.byte_size)

template<class T>
class AppDialog: public ui::Pager<AppDialog<T>>:
  public:
    vector<string> binaries
    T* app

    AppDialog(int x, y, w, h, T* a): ui::Pager<AppDialog>(x, y, w, h, self):
      self.set_title("Select an app...")
      self.app = a

    void populate():
      vector<string> apps
      for auto a : APPS:
        auto name = a.name
        if name == "":
          name = a.bin
        apps.push_back(name)

      self.options = apps

    void on_row_selected(string name):
      app->selected(name)

    void render_row(ui::HorizontalLayout *row, string option):
      d := new ui::DialogButton<ui::Dialog>(20, 0, self.w-200, self.opt_h, self, option)
      d->set_justification(ui::Text::JUSTIFY::LEFT)
      self.layout->pack_start(row)
      row->pack_start(d)

class App:
  int lastpress
  int is_pressed = false
  AppDialog<App> *app_dialog
  AppBackground *app_bg
  shared_ptr<framebuffer::FB> fb

  public:
  App():
    fb := framebuffer::get()
    w, h = fb->get_display_size()

    app_dialog = new AppDialog<App>(0, 0, DIALOG_WIDTH, DIALOG_HEIGHT, self)
    app_bg = new AppBackground(0, 0, w, h)

    notebook := ui::make_scene()
    notebook->add(app_bg)
    ui::MainLoop::set_scene(notebook)



  def handle_key_event(input::SynKeyEvent ev):
    static int lastpress = RAND_MAX
    static int event_press_id = 0
    ui::MainLoop::handle_key_event(ev)

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
                    print "SHOWING DIALOG"
                    app_bg->snapshot()
                    app_bg->visible = true
                    app_dialog->show()
                  });
          });
        else:
          event_press_id = 0

        is_pressed = ev.is_pressed

    last_ev := &ev

  def selected(string name):
    print "LAUNCHING APP", name
    string bin

    for auto a : APPS:
      if a.name == name:
        bin = a.bin

    for auto a : APPS:
      if a.name != name:
        proc::launch_process(a.term, false)

    proc::launch_process(bin, true /* check running */, true /* background */)
    app_bg->visible = false

  def run():
    ui::Text::FS = 32
    app_dialog->populate()
    app_dialog->setup_for_render()

    while true:
      ui::MainLoop::main()

      if app_bg->visible:
        ui::MainLoop::redraw()

      ui::MainLoop::read_input()

      for auto ev : ui::MainLoop::key_events:
        self.handle_key_event(ev)


App app
def main():
  app.run()
