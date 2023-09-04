#include "widget.h"
#include "scene.h"
#include "main_loop.h"
#include "../input/events.h"
#include "../ui/button.h"
#include "../ui/widget.h"


namespace ui:
  PLS_DEFINE_SIGNAL(DIALOG_EVENT, string)
  class DIALOG_EVENTS:
    public:
    DIALOG_EVENT close
  ;

  // interface for dialogs
  class IDialog:
    public:
    virtual void on_button_selected(string) = 0

  class DialogButton: public Button:
    public:
    IDialog *dialog
    DialogButton(int x, y, w, h, IDialog *d, string t): Button(x,y,w,h,t):
      self.dialog = d

    void on_mouse_click(input::SynMotionEvent&):
      self.dialog->on_button_selected(self.text)

  // class: ui::DialogBase
  // --- Prototype ---
  // class ui::DialogBase: public ui::Widget:
  // -----------------
  // All dialogs inherit from DialogBase, which handles basic overlay
  // functions, like managing an overlay Scene, drawing a background,
  // positioning, and events.
  class DialogBase: public Widget:
    public:
    Scene scene
    ui::InnerScene::DIALOG_VIS_EVENT on_hide
    DIALOG_EVENTS events

    DialogBase(int x, y, w, h): Widget(x,y,w,h):
      self.install_signal_handlers()

    bool ignore_event(input::SynMotionEvent&):
      return true

    virtual Scene create_scene():
      self.scene = ui::make_scene()
      self.scene->on_hide = self.on_hide
      self.scene->add(self)
      self->position_dialog()
      return self.scene

    // function: position_dialog
    // override position_dialog if you want to control where the dialog is
    // placed on the page. by default, the dialog will be centered
    virtual void position_dialog():
      self.restore_coords()
      width, height = self.fb->get_display_size()
      v_layout := ui::VerticalLayout(0, 0, width, height, self.scene)
      v_layout.pack_center(self)
      h_layout := ui::HorizontalLayout(0, 0, width, height, self.scene)
      h_layout.pack_center(self)

    // function: build_dialog
    // override build_dialog to add widgets to the dialog's scene.
    // build_dialog overrides should typically call create_scene() to set up
    // the dialog's scene.
    virtual void build_dialog() = 0;

    // function: before_show
    // override before_show to update widgets before the overlay is shown (but
    // after build_dialog)
    virtual void before_show():
      pass

    virtual void render():
      self.fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)
      self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false)

    void show():
      if self.scene == NULL:
         self.build_dialog()
      self.before_show()

      MainLoop::replace_overlay(self.scene)

    void hide():
      ui::MainLoop::hide_overlay(self.scene)

  // class: ui::Dialog
  // --- Prototype ---
  // class ui::Dialog: public ui::DialogBase, public ui::IDialog:
  // -----------------
  // A dialog is used to display a frame on the screen.  The normal way to use
  // a dialog is to instantiate it, then set its title and content widget
  // values
  //
  // there are two defaut dialog types that supply buttons:
  //
  // - InfoDialog supplies an "OK" button only
  // - ConfirmationDialog supplies an "OK" and "CANCEL" button
  //
  // To setup custom buttons, `buttons` can be modified before the dialog is
  // first shown.
  //
  // When these buttons are clicked, the on_button_selected callback in the
  // Dialog will be called
  class Dialog: public DialogBase, public IDialog:
    public:
    string title = "", content = ""
    MultiText *titleWidget
    Widget *contentWidget
    vector<string> buttons

    Dialog(int x, y, w, h): DialogBase(x,y,w,h):
      self.buttons = { "OK", "CANCEL" }
      self.titleWidget = new MultiText(20, 20, self.w, 50, self.title)
      self.contentWidget = new MultiText(20, 20, self.w, self.h - 100, self.content)

    // this function actually builds the dialog scene and necessary widgets /
    // and packings for the modal overlay
    void build_dialog():
      self.create_scene()

      width, height = self.fb->get_display_size()
      a_layout := ui::VerticalLayout(self.x, self.y, self.w, self.h, self.scene)
      a_layout.pack_start(self.titleWidget)
      a_layout.pack_start(self.contentWidget)

      button_bar := HorizontalLayout(0, 0, self.w, 50, self.scene)
      a_layout.pack_end(button_bar)
      button_bar.y -= 2

      self.add_buttons(&button_bar)

    virtual void add_buttons(HorizontalLayout *button_bar):
      default_fs := ui::Style::DEFAULT.font_size
      for auto b : self.buttons:
        image := stbtext::get_text_size(b, default_fs)

        button_bar->pack_start(new DialogButton(20, 0, image.w + default_fs, 50, self, b))

    // function: on_button_selected
    // this is called when the dialog's buttons are pressed
    virtual void on_button_selected(string s):
      self.events.close(s)

    void set_title(string s):
      self.titleWidget->text = s

  class ConfirmationDialog: public Dialog:
    public:
    ConfirmationDialog(int x, y, w, h): Dialog(x, y, w, h):
      self.buttons = { "OK", "CANCEL" }

  class InfoDialog: public Dialog:
    public:
    InfoDialog(int x, y, w, h): Dialog(x, y, w, h):
      self.buttons = { "OK" }

    void on_button_selected(string t):
      hide()
