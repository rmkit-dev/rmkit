#include <csignal>

#include "../build/rmkit.h"
#include "../shared/proc.h"

#include "app/ui.h"
#include "app/canvas.h"
#include "app/state.h"

using namespace std
using app_ui::STATE

class App:
  public:
  shared_ptr<framebuffer::FB> fb

  ui::Scene notebook

  app_ui::ManageButton *manage_button

  // do we accept finger touch events

  App():
    fb = framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()

    w, h = fb->get_display_size()

    notebook = ui::make_scene()
    ui::MainLoop::set_scene(notebook)

    canvas := new app_ui::Canvas(0, 0, fb->width, fb->height)
    notebook->add(canvas)

    toolbar_area := new ui::VerticalLayout(0, 0, w, h, notebook)
    minibar_area := new ui::VerticalLayout(0, 0, w, h, notebook)
    toolbar := new ui::HorizontalLayout(0, 0, w, TOOLBAR_HEIGHT, notebook)
    minibar := new ui::HorizontalLayout(0, 0, w, TOOLBAR_HEIGHT, notebook)

    // clockbar is at the top of the screen
    // clockbar = new ui::HorizontalLayout(0, 0, w, TOOLBAR_HEIGHT, notebook)
    // clockbar->pack_center(new app_ui::Clock(0, 0, ICON_WIDTH, TOOLBAR_HEIGHT))

    // aligns the toolbar to the bottom of the screen by packing end
    // inside toolbar_area
    // NOTE: this is an example of nesting layouts
    toolbar_area->pack_end(toolbar)
    minibar_area->pack_end(minibar)
    minibar->hide()


    // we always have to pack layouts in order
//    minibar->pack_start(new app_ui::HideButton(0, 0, ICON_WIDTH, TOOLBAR_HEIGHT, toolbar, minibar))
//    toolbar->pack_start(new app_ui::HideButton(0, 0, ICON_WIDTH, TOOLBAR_HEIGHT, toolbar, minibar))

    tool_button := new app_ui::ToolButton(0, 0, ICON_WIDTH*2, TOOLBAR_HEIGHT)
    tool_button->set_option_size(250, TOOLBAR_HEIGHT)
    tool_button->set_option_offset(0, -TOOLBAR_HEIGHT)
    toolbar->pack_start(tool_button)

    brush_config_button := new app_ui::BrushConfigButton(0, 0, ICON_WIDTH*2, TOOLBAR_HEIGHT)
    brush_config_button->set_option_size(200, TOOLBAR_HEIGHT)
    brush_config_button->set_option_offset(0, -TOOLBAR_HEIGHT)
    toolbar->pack_start(brush_config_button)

    toolbar->pack_center(new app_ui::LiftBrushButton(0, 0, 114, 100, canvas))

    // because we pack end, we go in reverse order
    toolbar->pack_end(manage_button = new app_ui::ManageButton(0, 0, 100, TOOLBAR_HEIGHT, canvas))
    toolbar->pack_end(new app_ui::RedoButton(0, 0, ICON_WIDTH, TOOLBAR_HEIGHT, canvas))
    toolbar->pack_end(new app_ui::UndoButton(0, 0, ICON_WIDTH, TOOLBAR_HEIGHT, canvas))
    toolbar->pack_end(new app_ui::PalmButton(0, 0, ICON_WIDTH, TOOLBAR_HEIGHT))

  def handle_key_event(input::SynKeyEvent &key_ev):
    if key_ev.is_pressed:
      switch key_ev.key:
        #ifdef DEV
        case KEY_LEFT:
          input::MouseEvent::tilt_x -= 100
          break
        case KEY_RIGHT:
          input::MouseEvent::tilt_x += 100
          break
        case KEY_DOWN:
          input::MouseEvent::tilt_y -= 100
          break
        case KEY_UP:
          input::MouseEvent::tilt_y += 100
          break
        case KEY_F1:
          input::MouseEvent::pressure -= 100
          break
        case KEY_F2:
          input::MouseEvent::pressure += 100
          break
        #elif REMARKABLE
        case KEY_LEFT:
          break
        case KEY_RIGHT:
          break
        #endif
        case KEY_POWER:
          manage_button->select_exit()
          break
        case KEY_HOME:
          fb->clear_screen()
          ui::MainLoop::refresh()
          break
        default:
          ui::MainLoop::handle_key_event(key_ev)
          return
      key_ev.stop_propagation()


  def handle_motion_event(input::SynMouseEvent &syn_ev):
    #ifdef DEBUG_INPUT
    if (auto m_ev = input::is_mouse_event(syn_ev)):
      print "MOUSE EVENT"
    else if (auto t_ev = input::is_touch_event(syn_ev)):
      print "TOUVCH EVENT"
    else if (auto w_ev = input::is_wacom_event(syn_ev)):
      print "WACOM EVENT"
    #endif

    if STATE.reject_touch && input::is_touch_event(syn_ev):
      syn_ev.stop_propagation()
      return

    ui::MainLoop::handle_motion_event(syn_ev)

  def run():
    while true:
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()

      for auto ev : ui::MainLoop::motion_events:
        self.handle_motion_event(ev)

      for auto ev : ui::MainLoop::key_events:
        self.handle_key_event(ev)


App app

void signal_handler(int signum):
  app.fb->cleanup()
  exit(signum)

def main():
  for auto s : { SIGINT, SIGTERM, SIGABRT}:
    signal(s, signal_handler)

  proc::stop_xochitl()
  app.run()
