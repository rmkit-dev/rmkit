#include "../assets.h"
#include "widget.h"
#include "scene.h"
#include "main_loop.h"
#include "../input/events.h"
#include "../ui/button.h"
#include "../ui/widget.h"


namespace ui:
  class KeyboardEvent:
    public:
    string text
    KeyboardEvent(string t): text(t):
      pass
  ;

  PLS_DEFINE_SIGNAL(KEYBOARD_EVENT, KeyboardEvent)

  class KeyButton: public ui::Button:
    public:
    KeyButton(int x, y, w, h, string t): ui::Button(x, y, w, h, t):
      pass

    void before_render():
      ui::Button::before_render()
      self.mouse_inside = self.mouse_down && self.mouse_inside

    void set_justification(Text::JUSTIFY j):
      self.set_justification(j)


  class Row: public Widget:
    public:
    HorizontalLayout *layout = NULL
    Scene scene

    Row(int x, y, w, h, Scene s): Widget(x,y,w,h):
      self.scene = s

    void add_key(KeyButton *key, bool right=true):
      if self.layout == NULL:
        debug "RENDERING ROW", self.x, self.y, self.w, self.h
        self.layout = new HorizontalLayout(self.x, self.y, self.w, self.h, self.scene)
      if right:
        self.layout->pack_end(key)
      else:
        self.layout->pack_start(key)

    void render():
      pass // if a component is in scene, it gets rendered

  class Keyboard: public Widget:
    class KEYBOARD_EVENTS:
      public:
      KEYBOARD_EVENT changed
      KEYBOARD_EVENT done

    public:
    bool shifted = false
    bool numbers = false
    vector<Row*> rows
    Scene scene
    Scene prev_overlay
    MultiText *input_box = NULL
    string text = ""
    string original_text
    int btn_width
    int btn_height
    int btn_font_size = 48

    KEYBOARD_EVENTS events

    Keyboard(int x=0,y=0,w=0,h=0): Widget(x,y,w,h):
      w, full_h = self.fb->get_display_size()
      h = full_h / 4
      self.w = w
      self.h = h
      self.lower_layout()

    void set_text(string t):
      self.original_text = t
      self.text = t
      if self.input_box != NULL:
        self.input_box->text = t


    void lower_layout():
      self.numbers = false
      self.shifted = false
      self.set_layout(
        "qwertyuoip",
        "asdfghjkl",
        "zxcvbnm"
      )

    void upper_layout():
      self.numbers = false
      self.shifted = true
      self.set_layout(
        "QWERTYUOIP",
        "ASDFGHJKL",
        "ZXCVBnm"
      )

    void number_layout():
      self.numbers = true
      self.shifted = false
      self.set_layout(
        "1234567890",
        "-/:;() &@\"",
        "  ,.?!'  "
      )

    void symbol_layout():
      self.numbers = true
      self.shifted = true
      self.set_layout(
        "[]{}#%^*+=",
        "_\\|~<> $  ",
        "  ,.?!'  "
      )

    void set_layout(string row1chars, row2chars, row3chars):
      self.scene = ui::make_scene()
      self.scene->add(self)

      self.btn_width = w / row1chars.size()
      self.btn_height = 100
      indent := row1chars.size() > row2chars.size() ? h/8 : 0
      row0 := new Row(0,0,w,100, self.scene)
      row1 := new Row(0,0,w,100, self.scene)
      row2 := new Row(indent,0,w,100, self.scene)
      row3 := new Row(indent,0,w,100, self.scene)
      row4 := new Row(0,0,w,100, self.scene)

      fw, fh = self.fb->get_display_size()
      v_layout := ui::VerticalLayout(0, 0, fw, fh, self.scene)

      self.input_box = new MultiText(0,0,w,50,self.text)
      self.input_box->font_size = 64
      v_layout.pack_start(input_box)

      v_layout.pack_end(row4)
      v_layout.pack_end(row3)
      v_layout.pack_end(row2)
      v_layout.pack_end(row1)
      v_layout.pack_end(row0)

      cancel := new KeyButton(0,0,fw/2,self.btn_height,"cancel")
      cancel->set_justification(ui::Text::JUSTIFY::LEFT)
      cancel->mouse.click += PLS_LAMBDA(auto &ev):
        ui::MainLoop::refresh()
        kev := KeyboardEvent {text:self.original_text}
        self.events.changed(kev)

        self.events.done(kev)

        ui::MainLoop::hide_kbd()
      ;
      row0->add_key(cancel)
      clear := new KeyButton(0,0,fw/2,self.btn_height,"clear")
      clear->set_justification(ui::Text::JUSTIFY::RIGHT)
      clear->mouse.click += PLS_LAMBDA(auto &ev):
        self.text = ""
        self.dirty = 1
      ;
      row0->add_key(clear, true)

      for (auto c: row1chars):
        row1->add_key(self.make_char_button(c))

      for (auto c: row2chars):
        row2->add_key(self.make_char_button(c))

      shift_key := new KeyButton(0, 0, self.btn_width, btn_height, "shift")
      shift_key->textWidget->font_size = btn_font_size
      shift_key->mouse.click += PLS_LAMBDA(auto &ev):
        if !numbers and !shifted:
          self.upper_layout()
        else if !numbers and shifted:
          self.lower_layout()
        else if numbers and !shifted:
          self.symbol_layout()
        else:
          self.number_layout()
      ;
      row3->add_key(shift_key)
      for (auto c: row3chars):
        row3->add_key(self.make_char_button(c))
      backspace_key := new KeyButton(0,0,self.btn_width,btn_height,"back")
      backspace_key->textWidget->font_size = btn_font_size


      backspace_key->mouse.click += PLS_LAMBDA(auto &ev):
        if self.text.size() > 0:
          self.text.pop_back()
          self.input_box->text = self.text
          self.input_box->dirty = 1
          self.dirty = 1
      ;
      row3->add_key(backspace_key)

      kbd := new KeyButton(0,0,self.btn_width,btn_height,"kbd")
      kbd->mouse.click += PLS_LAMBDA(auto &ev):
        if numbers:
          self.lower_layout()
        else:
          self.number_layout()
      ;
      space_key := new KeyButton(0,0,self.btn_width*8,btn_height,"space")
      space_key->textWidget->font_size = btn_font_size
      space_key->mouse.click += PLS_LAMBDA(auto &ev):
        self.text += " "
        self.input_box->text = text
        self.input_box->dirty = 1
        self.dirty = 1
      ;

      enter_key := new KeyButton(0,0,self.btn_width,btn_height,"done")
      enter_key->textWidget->font_size = btn_font_size
      enter_key->mouse.click += PLS_LAMBDA(auto &ev):
        ui::MainLoop::refresh()
        kev := KeyboardEvent {text:self.text}
        self.events.changed(kev)

        self.events.done(kev)

        ui::MainLoop::hide_kbd()
      ;

      row4->add_key(kbd)
      row4->add_key(space_key)
      row4->add_key(enter_key)

      self.show()
      ui::MainLoop::refresh()

      // TODO row 4

    KeyButton* make_char_button(char c):
      string s(1, c)
      key := new KeyButton(0,0,self.btn_width,btn_height,s)
      key->textWidget->font_size = btn_font_size
      key->mouse.click += PLS_LAMBDA(auto &ev):
        self.dirty = 1
        if c == ' ':
          return

        self.text.push_back(c)
        self.input_box->text = self.text
        self.input_box->dirty = 1
        debug "key pressed:", c
      ;
      return key

    KeyButton* make_icon_button(icons::Icon icon, int w):
      key := new KeyButton(0,0,self.btn_width,btn_height,"")
      key->icon = icon
      return key

    void render():
      fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

    void show():
      self.scene->pinned = true
      ui::MainLoop::show_kbd(self.scene)

    // switch between: lowercase alphabet, uppercase, nums, symbols
    void switch_mode(int mode):
      // TODO
      pass
