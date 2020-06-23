#include "base.h"
#include "scene.h"
#include "main_loop.h"
#include "../input/events.h"


namespace ui:
  template<class T>
  class DialogButton: public Button:
    public:
    T *dialog
    DialogButton(int x, y, w, h, T *d, string t): Button(x,y,w,h,t):
      self.dialog = d

    void on_mouse_click(input::SynMouseEvent&):
      self.dialog->on_button_selected(self.text)

  class Dialog: public Widget:
    public:
    string title
    MultiText *titleWidget
    Scene scene


    Dialog(int x, y, w, h): Widget(x,y,w,h):
      self.scene = ui::make_scene()
      width, height = self.fb->get_display_size()
      v_layout = ui::VerticalLayout(0, 0, width, height, self.scene)
      v_layout.pack_center(self)

      h_layout = ui::HorizontalLayout(0, 0, self.fb->width, self.fb->height, self.scene)
      h_layout.pack_center(self)

      a_layout = ui::VerticalLayout(self.x, self.y, self.w, self.h, self.scene)
      self.titleWidget = new MultiText(20, 20, self.w, 50, self.title)
      a_layout.pack_start(self.titleWidget, 20)

      button_bar = new HorizontalLayout(0, 0, self.w, 50, self.scene)
      a_layout.pack_end(button_bar, 10)
      button_bar->pack_start(new DialogButton<Dialog>(20, 0, 100, 50, self, "OK"))
      button_bar->pack_start(new DialogButton<Dialog>(20, 0, 100, 50, self, "CANCEL"))
      self.scene->add(self)

    bool ignore_event(input::SynMouseEvent&):
      return true

    virtual void on_button_selected(string s):
      pass

    void redraw():
      self.fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)
      self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false)

    void set_title(string s):
      self.titleWidget->text = s

    void show():
      MainLoop::show_overlay(self.scene)
