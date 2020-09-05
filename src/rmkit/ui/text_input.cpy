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
    // function: TextInput
    // Parameters
    //
    // x - x
    // y - y
    // w - width
    // h - height
    // t - the content of the text input
    TextInput(int x, y, w, h, string t=""): ui::Text(x, y, w, h, t):
      self.justify = ui::Text::JUSTIFY::CENTER

    void on_mouse_click(input::SynMouseEvent &ev):
      keyboard := new ui::Keyboard()
      keyboard->set_text(self.text)
      keyboard->show()

      keyboard->events.changed += PLS_LAMBDA(auto &ev):
        self.text = ev.text
        self.on_text_changed(ev.text)
      ;

      ui::MainLoop::refresh()

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

    void on_mouse_click(input::SynMouseEvent &ev):
      keyboard := new ui::Keyboard()
      keyboard->set_text(self.text)
      keyboard->show()

      keyboard->events.changed += PLS_LAMBDA(auto &ev):
        self.text = ev.text
        self.on_text_changed(ev.text)
      ;

      ui::MainLoop::refresh()

    void on_text_changed(string):
      self.dirty=1
    void render():
      self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, 0 /* fill */)
      ui::MultiText::render()
