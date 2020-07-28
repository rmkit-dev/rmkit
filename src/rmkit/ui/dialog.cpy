#include "base.h"
#include "scene.h"
#include "main_loop.h"
#include "../input/events.h"
#include "../ui/button.h"
#include "../ui/base.h"


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
    string title = "", content = ""
    MultiText *titleWidget
    Widget *contentWidget
    Scene scene
    vector<string> buttons

    Dialog(int x, y, w, h): Widget(x,y,w,h):
      self.buttons = { "OK", "CANCEL" }
      self.titleWidget = new MultiText(20, 20, self.w, 50, self.title)
      self.contentWidget = new MultiText(20, 20, self.w, self.h - 100, self.content)

    void build_dialog():
      self.scene = ui::make_scene()
      self.scene->add(self)

      width, height = self.fb->get_display_size()
      v_layout := ui::VerticalLayout(0, 0, width, height, self.scene)
      v_layout.pack_center(self)

      h_layout := ui::HorizontalLayout(0, 0, self.fb->width, self.fb->height, self.scene)
      h_layout.pack_center(self)

      a_layout := ui::VerticalLayout(self.x, self.y, self.w, self.h, self.scene)
      a_layout.pack_start(self.titleWidget)

      a_layout.pack_start(self.contentWidget)

      button_bar := new HorizontalLayout(0, 0, self.w, 50, self.scene)
      a_layout.pack_end(button_bar, 10)

      self.add_buttons(button_bar)

    bool ignore_event(input::SynMouseEvent&):
      return true

    virtual void add_buttons(HorizontalLayout *button_bar):
      for auto b : self.buttons:
        button_bar->pack_start(new DialogButton<Dialog>(20, 0, 100, 50, self, b))

    virtual void on_button_selected(string s):
      pass

    void redraw():
      self.fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)
      self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false)

    void set_title(string s):
      self.titleWidget->text = s

    void show():
      if self.scene == NULL:
        self.build_dialog()

      MainLoop::show_overlay(self.scene)

  class ConfirmationDialog: public Dialog:
    public:
    ConfirmationDialog(int x, y, w, h): Dialog(x, y, w, h):
      self.buttons = { "OK", "CANCEL" }

  class InfoDialog: public Dialog:
    public:
    InfoDialog(int x, y, w, h): Dialog(x, y, w, h):
      self.buttons = { "OK" }

    void on_button_selected(string t):
      ui::MainLoop::hide_overlay()
