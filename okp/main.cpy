#include <csignal>

#include "fb/fb.h"
#include "input/input.h"
#include "app_ui.h"
#include "ui/text.h"


using namespace std

class App:
  public:
  shared_ptr<framebuffer::FB> fb
  input::Input in

  ui::Scene notebook
  ui::Scene save_dialog
  ui::Scene open_dialog

  int x = 0
  int y = 0


  App():
    #ifdef REMARKABLE
    fb = make_shared<framebuffer::RemarkableFB>()
    #elif DEV
    fb = make_shared<framebuffer::FileFB>()
    #else
    fb = make_shared<framebuffer::HardwareFB>()
    #endif

    known ui::Widget::fb = fb.get()
    known input::Event::fb = fb.get()

    fb->clear_screen()
    fb->redraw_screen()

    notebook = ui::make_scene()
    ui::MainLoop::set_scene(notebook)

    canvas = new ui::Canvas(0, 0, fb->width, fb->height)
    w, h = fb->get_display_size()

    toolbar_area = new ui::VerticalLayout(0, 0, w, h, notebook)
    minibar_area = new ui::VerticalLayout(0, 0, w, h, notebook)
    topbar = new ui::HorizontalLayout(0, 0, w, 50, notebook)
    minibar = new ui::HorizontalLayout(0, 0, w, 50, notebook)


    // aligns the topbar to the bottom of the screen by packing end
    // this is an example of nesting a layout
    toolbar_area->pack_end(topbar)
    minibar_area->pack_end(minibar)
    minibar->hide()


    // we always have to pack layouts in order, i believe
    minibar->pack_start(new app_ui::HideButton(0, 0, 50, 50, topbar, minibar), 20)

    // because we pack end, we go in reverse order
    topbar->pack_start(new app_ui::HideButton(0, 0, 50, 50, topbar, minibar), 20)
    topbar->pack_start(new app_ui::ToolButton(0, 0, 200, 50, canvas))
    topbar->pack_start(new app_ui::BrushSizeButton(0, 0, 200, 50, canvas))
    topbar->pack_end(new app_ui::RedoButton(0, 0, 100, 50, canvas))
    topbar->pack_end(new app_ui::UndoButton(0, 0, 100, 50, canvas))

    notebook->add(canvas)

    save_dialog = ui::make_scene()
    save_dialog->add(new ui::Text(w / 2 - 100, 10, w, 50, "SAVE DIALOG"))

    open_dialog = ui::make_scene()
    open_dialog->add(new ui::Text(w / 2 - 100, 10, w, 50, "OPEN DIALOG"))


  def handle_key_event(input::KeyEvent &key_ev):
    if key_ev.is_pressed:
      switch key_ev.key:
        case KEY_HOME:
          fb->clear_screen()
          ui::MainLoop::refresh()
          break
        case KEY_LEFT:
          ui::MainLoop::toggle_overlay(save_dialog)
          break
        case KEY_RIGHT:
          ui::MainLoop::toggle_overlay(open_dialog)
          break


  def handle_motion_event(input::SynEvent &syn_ev):
    #ifdef DEBUG_INPUT
    if (auto m_ev = input::is_mouse_event(syn_ev)):
      print "MOUSE EVENT"
    else if (auto t_ev = input::is_touch_event(syn_ev)):
      print "TOUVCH EVENT"
    else if (auto w_ev = input::is_wacom_event(syn_ev)):
      print "WACOM EVENT"
    #endif

    ui::MainLoop::handle_motion_event(syn_ev)

  def run():
    ui::MainLoop::main()
    self.fb->redraw_screen()

    printf("HANDLING RUN\n")
    while true:
      in.listen_all()
      for auto ev : in.all_motion_events:
        self.handle_motion_event(ev)

      for auto ev : in.all_key_events:
        self.handle_key_event(ev)

      ui::MainLoop::main()
      self.fb->redraw_screen()

App app

void signal_handler(int signum):
  app.fb->cleanup()
  exit(signum)

def main():
  signal(SIGINT, signal_handler)
  signal(SIGTERM, signal_handler)
  signal(SIGABRT, signal_handler)
  app.run()
