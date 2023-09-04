#include "../build/rmkit.h"
#include "../shared/string.h"

#include "shapes.h"
#include <sys/types.h>
#include <sys/wait.h>

pid_t _pid

class AppBackground: public ui::Widget:
  public:
  int byte_size
  framebuffer::VirtualFB *vfb = NULL

  AppBackground(int x, y, w, h): ui::Widget(x, y, w, h):
    self.byte_size = w*h*sizeof(remarkable_color)

    fw, fh := fb->get_display_size()
    vfb = new framebuffer::VirtualFB(fw, fh)
    vfb->clear_screen()
    vfb->fbmem = (remarkable_color*) memcpy(vfb->fbmem, fb->fbmem, self.byte_size)

  void render():
    if rm2fb::IN_RM2FB_SHIM:
      fb->waveform_mode = WAVEFORM_MODE_GC16
    else:
      fb->waveform_mode = WAVEFORM_MODE_AUTO

    memcpy(fb->fbmem, vfb->fbmem, self.byte_size)

    fb->perform_redraw(true)
    fb->dirty = 1


class SettingsDialog: public ui::InfoDialog:
  public:
  ui::ToggleButton* snap_enabled
  ui::ToggleButton* rows_header_enabled
  ui::ToggleButton* columns_header_enabled
  ui::RangeInput* snap_range
  ui::RangeInput* rows_range
  ui::RangeInput* columns_range

  SettingsDialog(int x, y, w, h): ui::InfoDialog(x, y, w, h):
    self.set_title(string("Settings"))
    self.contentWidget = new ui::Text(0, 0, 20, 50, "") 

  void save_settings():
    debug "SAVING SETTINGS"
    shape::Shape::set_snapping(self.snap_range->get_value())
    shape::Shape::snap_enabled = self.snap_enabled->toggled
    shape::Shape::rows_header_enabled = self.rows_header_enabled->toggled
    shape::Shape::columns_header_enabled = self.columns_header_enabled->toggled
    shape::Shape::rows = self.rows_range->get_value()
    shape::Shape::columns = self.columns_range->get_value()

  void on_button_selected(string text):
    self.hide()
    self.save_settings()

  // this function actually builds the dialog scene and necessary widgets /
  // and packings for the modal overlay
  void build_dialog():
    ui::InfoDialog::build_dialog()

    self.on_hide = self.scene->on_hide
    self.scene->on_hide += PLS_LAMBDA(auto &visible) {
      self.hide()
      self.save_settings()
    }

    a_layout := ui::VerticalLayout(self.x, self.y+50, self.w, self.h-100, self.scene)
    left := 20

    snap_section_label := new ui::Text(left, 0, self.w - 2*left, 50, "Snapping")
    snap_section_label->set_style(ui::Stylesheet()
      .valign_bottom()
      .justify_center()
      .underline())

    self.snap_enabled = new ui::ToggleButton(left, 0, self.w - 2*left, 50, "Enabled")
    self.snap_enabled->set_style(ui::Stylesheet()
      .valign_middle()
      .justify_left())

    snap_range_label := new ui::Text(left, 0, self.w - 2*left, 50, "Snap grid (mm)")
    snap_range_label->set_style(ui::Stylesheet()
      .valign_bottom()
      .justify_left())
    self.snap_range = new ui::RangeInput(left, 0, self.w - 2*left, 50)
    snap_range->set_range(1, 10)

    table_label := new ui::Text(left, 0, self.w - 2*left, 50, "Table")
    table_label->set_style(ui::Stylesheet()
      .valign_bottom()
      .justify_center()
      .underline())

    rows_label := new ui::Text(left, 0, self.w - 2*left, 50, "Rows")
    rows_label->set_style(ui::Stylesheet()
      .valign_bottom()
      .justify_left())
    self.rows_range = new ui::RangeInput(left, 0, self.w - 2*left, 50)
    rows_range->set_range(1, 10)

    self.rows_header_enabled = new ui::ToggleButton(left, 0, self.w - 2*left, 50, "Header Enabled")
    self.rows_header_enabled->set_style(ui::Stylesheet()
      .valign_middle()
      .justify_left())

    columns_label := new ui::Text(left, 0, self.w - 2*left, 50, "Columns")
    columns_label->set_style(ui::Stylesheet()
      .valign_bottom()
      .justify_left())
    self.columns_range = new ui::RangeInput(left, 0, self.w - 2*left, 50)
    columns_range->set_range(1, 10)

    self.columns_header_enabled = new ui::ToggleButton(left, 0, self.w - 2*left, 50, "Header Enabled")
    self.columns_header_enabled->set_style(ui::Stylesheet()
      .valign_middle()
      .justify_left())

    a_layout.pack_start(snap_section_label)
    a_layout.pack_start(snap_enabled)
    a_layout.pack_start(snap_range_label)
    a_layout.pack_start(snap_range)
    a_layout.pack_start(table_label)
    a_layout.pack_start(rows_label)
    a_layout.pack_start(rows_header_enabled)
    a_layout.pack_start(rows_range)
    a_layout.pack_start(columns_label)
    a_layout.pack_start(columns_header_enabled)
    a_layout.pack_start(columns_range)



class App:
  public:
  AppBackground* app_bg
  SettingsDialog *settings

  shared_ptr<framebuffer::FB> fb
  App():
    fb = framebuffer::get()
    w, h = fb->get_display_size()

    fb->dither = framebuffer::DITHER::BAYER_2
    fb->waveform_mode = WAVEFORM_MODE_DU

    scene := ui::make_scene()
    ui::MainLoop::set_scene(scene)
    app_bg = new AppBackground(0, 0, w, h)
    scene->add(app_bg)

    settings = new SettingsDialog(0, 0, 400,  650)

    style := ui::Stylesheet() \
      .valign(ui::Style::VALIGN::MIDDLE) \
      .justify(ui::Style::JUSTIFY::CENTER)

    h_layout := ui::HorizontalLayout(0, h-60, w, 50, scene)

    no_button := new ui::Button(0, 0, 200, 50, "cancel")
    ok_button := new ui::Button(0, 0, 200, 50, "ok")
    settings_btn := new ui::Button(0, 0, 200, 50, "settings")

    h_layout.pack_start(settings_btn)
    h_layout.pack_end(ok_button)
    h_layout.pack_end(no_button)

    shape_dropdown := new ui::TextDropdown(0, 0, 250, 50, "add")
    shape_dropdown->dir = ui::DropdownButton::DIRECTION::UP

    // TODO: pull these from the list of available shapes
    shape_dropdown->add_section("add shape")->add_options(%{
      "line",
      "v. line",
      "h. line",
      "rect",
      "circle",
      "bezier",
      "table"})

    h_layout.pack_center(shape_dropdown)

    no_button->set_style(style)
    ok_button->set_style(style)
    no_button->mouse.click += PLS_LAMBDA(auto &ev) {
      self.cleanup()
      exit(0)
    }

    settings_btn->mouse.click += PLS_LAMBDA(auto &ev) {
      settings->show();
    }

    ok_button->mouse.click += PLS_LAMBDA(auto &ev) {
      self.cleanup()

      ui::MainLoop::in.touch.lock()

      shape_strs := vector<string>{}
      for auto sh : shape::to_draw:
        str := sh->to_lamp()
        cmd := "echo '"+ str + "' | /opt/bin/lamp"
        debug "RUNNING", cmd
        _ := system("sleep 0.1")
        _ = system(cmd.c_str())
      _ := system("sleep 0.5")

      ui::MainLoop::in.ungrab()
      exit(0)
    }

    // TODO: this should use Shape to get the shape to use
    shape_dropdown->events.selected += PLS_LAMBDA(int i) {
      val := shape_dropdown->options[i]->name
      r := 100
      if val == "circle":
        s := new shape::Circle(w/2-r/2, h/2-r/2, r, r, scene)
      if val == "h. line":
        s := new shape::HLine(w/2-r/2, h/2-r/2, r, r, scene)
      if val == "v. line":
        s := new shape::VLine(w/2-r/2, h/2-r/2, r, r, scene)
      if val == "line":
        s := new shape::Line(w/2-r/2, h/2-r/2, r, r, scene)
      if val == "rect":
        s := new shape::Rectangle(w/2-r/2, h/2-r/2, r, r, scene)
      if val == "bezier":
        r = 300
        s := new shape::Bezier(w/2-r/2, h/2-r/2, r, r, scene)
      if val == "table":
        s := new shape::Table(w/2-r/2, h/2-r/2, r, r, scene)
    }

  void redraw(bool skip_shape=false):
    app_bg->render()

  void redraw(input::SynMotionEvent &ev):
    redraw(false)

  void cleanup():
    debug "CLEANING UP", _pid
    ui::MainLoop::in.ungrab()
    app_bg->render()

  void run():
    ui::MainLoop::in.grab()
    ui::MainLoop::refresh()
    // just to kick off the app, we do a full redraw
    ui::MainLoop::redraw()
    while true:
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()

App app
did_clean := false
void cleanup():
  if did_clean:
    return
  did_clean = true

  app.cleanup()
  exit(0)

void catch_sigint(int):
  debug "CAUGHT SIGINT", _pid
  cleanup()

def main():
  signal(SIGINT, catch_sigint);

  // we fork just to be a little bit extra safe with
  // unlocking the input file descriptors
  _pid = fork()
  if _pid:
    wait(NULL)
    ui::MainLoop::in.ungrab()
  else:
    app.run()
