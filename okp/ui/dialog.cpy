#include "base.h"
#include "scene.h"
#include "main_loop.h"
#include "../input/events.h"


namespace ui:
  template<class T>
  class DialogButton: public ui::Button:
    public:
    T *dialog
    DialogButton(int x, y, w, h, string t, T *d): Button(x,y,w,h,t):
      self.dialog = d

    void on_mouse_click(input::SynEvent &ev):
      print "ON MOUSE CLICK"
      self.dialog->on_button_selected(self.text)

    void on_mouse_down(input::SynEvent &ev):
      print "ON MOUSE DOWN"

  class Dialog: public Widget:
    public:
    string title
    Text *titleWidget
    DialogButton<Dialog> *yes_button, *no_button
    Scene scene


    Dialog(int x, y, w, h): Widget(x,y,w,h):
      self.scene = ui::make_scene()
      width, height = self.fb->get_display_size()
      v_layout = ui::VerticalLayout(0, 0, width, height, self.scene)
      v_layout.pack_center(self)

      h_layout = ui::HorizontalLayout(0, 0, self.fb->width, self.fb->height, self.scene)
      h_layout.pack_center(self)

      a_layout = ui::VerticalLayout(self.x, self.y, self.w, self.h, self.scene)
      self.titleWidget = new Text(0, 20, self.w, 50, self.title)
      a_layout.pack_start(self.titleWidget)

      self.scene->add(self)
      button_bar = new HorizontalLayout(0, 0, self.w, 50, self.scene)
      a_layout.pack_end(button_bar)
      button_bar->pack_start(new DialogButton<Dialog>(20, 0, 100, 50, "OK", self))
      button_bar->pack_start(new DialogButton<Dialog>(20, 0, 100, 50, "CANCEL", self))

    virtual void on_button_selected(string s):
      print "ON BUTTON SELECTED"
      pass

    void redraw():
      self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false)

    void set_title(string s):
      self.titleWidget->text = s

    void show():
      MainLoop::show_overlay(self.scene)
