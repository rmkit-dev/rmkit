#include "fb/fb.h"
#include "input/input.h"
#include "app_ui.h"
#include "ui/widgets.h"

using namespace std

class App:
  shared_ptr<framebuffer::FB> fb
  input::Input in

  ui::Scene notebook
  ui::Scene save_dialog
  ui::Scene open_dialog

  int x = 0
  int y = 0


  public:
  App():
    #ifndef DEV
    fb = make_shared<framebuffer::HardwareFB>()
    #else
    fb = make_shared<framebuffer::FileFB>()
    #endif

    known ui::Widget::fb = fb.get()
    known input::Input::fb = fb.get()

    fb->clear_screen()

    notebook = ui::make_scene()
    ui::MainLoop::set_scene(notebook)

    canvas = new ui::Canvas(0, 0, fb->width, fb->height)
    w, h = fb->get_display_size()
    print "FB HEIGHT", h

    topbar = new ui::HorizontalLayout(10, 10, w, 50, notebook)
    topbar->pack_end(new ui::Text(0, 0, 200, 50, "rmHarmony"))


    // because we pack end, we go in reverse order
    topbar->pack_start(new app_ui::ToolButton(0, 0, 200, 50, canvas))
    topbar->pack_start(new app_ui::UndoButton(0, 0, 200, 50, canvas))
    topbar->pack_start(new app_ui::RedoButton(0, 0, 200, 50, canvas))

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


def main():
  app = App()
  app.run()

