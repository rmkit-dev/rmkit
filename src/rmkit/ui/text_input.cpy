#include "keyboard.h"

namespace ui:
  // class: ui::TextInput
  // --- Prototype ---
  // class ui::TextInput: public ui::Text:
  // -----------------
  // A TextInput is an area of text that is editable. A TextInput spans one line,
  // while a TextArea spans multiple
  class TextInput: public ui::Text:
    public:
    struct TextInputEvent:
      string s
    ;
    PLS_DEFINE_SIGNAL(TEXTINPUT_EVENT, string)
    class TEXTINPUT_EVENTS:
      public:
      TEXTINPUT_EVENT done
    ;
    TEXTINPUT_EVENTS events

    static Stylesheet DEFAULT_STYLE = Stylesheet().justify_center()


    // function: TextInput
    // Parameters
    //
    // x - x
    // y - y
    // w - width
    // h - height
    // t - the content of the text input
    TextInput(int x, y, w, h, string t=""): ui::Text(x, y, w, h, t):
      self.set_style(DEFAULT_STYLE)

    void on_mouse_click(input::SynMotionEvent &ev):
      keyboard := new ui::Keyboard()
      keyboard->set_text(self.text)
      keyboard->show()

      keyboard->events.changed += PLS_LAMBDA(auto &ev):
        self.text = ev.text
        self.on_text_changed(ev.text)
      ;
      keyboard->events.done += PLS_LAMBDA(auto &ev):
        self.text = ev.text
        self.on_done(ev.text)
      ;


      ui::MainLoop::refresh()

    virtual void on_done(string &s):
      self.dirty = 1
      self.events.done(s)
    ;

    void on_text_changed(string):
      self.dirty=1
    void render():
      self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, 0 /* fill */)
      ui::Text::render()


  // class: ui::TextArea
  // --- Prototype ---
  // class ui::TextArea: public ui::MultiText:
  // -----------------
  // A TextArea is an area of text that is editable, it spans multiple lines
  // and will bring up a keyboard when clicked.
  class TextArea: public ui::MultiText:
    public:
    struct TextAreaEvent:
      string s
    ;
    PLS_DEFINE_SIGNAL(TEXTAREA_EVENT, string)
    class TEXTAREA_EVENTS:
      public:
      TEXTAREA_EVENT done
    ;

    TEXTAREA_EVENTS events

    // function: TextArea
    //
    // Parameters
    //
    // x - x
    // y - y
    // w - width
    // h - height
    // t - the content of the text input
    TextArea(int x, y, w, h, string t=""): ui::MultiText(x, y, w, h, t):
      pass

    void on_mouse_click(input::SynMotionEvent &ev):
      keyboard := new ui::Keyboard()
      keyboard->set_text(self.text)
      keyboard->show()

      keyboard->events.changed += PLS_LAMBDA(auto &ev):
        self.text = ev.text
        self.on_text_changed(ev.text)
      ;

      keyboard->events.done += PLS_LAMBDA(auto &ev):
        self.text = text
        self.on_done(ev.text)
      ;

      ui::MainLoop::refresh()

    virtual void on_text_changed(string):
      self.dirty=1

    virtual void on_done(string &s):
      self.dirty = 1
      self.events.done(s)
    ;

    void render():
      self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, 0 /* fill */)
      ui::MultiText::render()

  ;
