#include "../assets.h"
#include "widget.h"
#include "scene.h"
#include "main_loop.h"
#include "../input/events.h"
#include "../ui/button.h"
#include "../ui/widget.h"


namespace ui:

  class Row: public Widget:
    public:
    HorizontalLayout *layout = NULL
    Scene scene

    Row(int x, y, w, h, Scene s): Widget(x,y,w,h):
      self.scene = s

    void add_key(Button *key):
      if self.layout == NULL:
        print "RENDERING ROW", self.x, self.y, self.w, self.h
        self.layout = new HorizontalLayout(self.x, self.y, self.w, self.h, self.scene)
      self.layout->pack_start(key)

    void render():
      pass // if a component is in scene, it gets rendered


  class Keyboard: public Widget:
    public:
    vector<Row*> rows
    bool num_mode = false
    bool caps = false
    Scene scene
    Text *input_box
    int btn_width
    int btn_height
    int btn_font_size = 48

    Keyboard(int x=0,y=0,w=0,h=0): Widget(x,y,w,h):
      w, full_h = self.fb->get_display_size()
      h = full_h / 4
      self.w = w
      self.h = h

      self.scene = ui::make_scene()
      self.scene->add(self)

      string row1chars = "qwertyuoip"
      string row2chars = "asdfghjkl"
      string row3chars = "zxcvbnm"
      self.btn_width = w / row1chars.size()
      self.btn_height = 100
      row1 := new Row(0,0,w,100, self.scene)
      row2 := new Row(h/8,0,w,100, self.scene)
      row3 := new Row(h/8,0,w,100, self.scene)
      row4 := new Row(0,0,w,100, self.scene)

      v_layout := ui::VerticalLayout(0, 0, w, full_h, self.scene)

      self.input_box = new Text(0,0,w,50,"");
      self.input_box->justify = Text::JUSTIFY::LEFT;
      self.input_box->font_size = 64
      v_layout.pack_start(input_box)

      v_layout.pack_end(row4)
      v_layout.pack_end(row3)
      v_layout.pack_end(row2)
      v_layout.pack_end(row1)

      for (auto c: row1chars):
        row1->add_key(self.make_char_button(c))

      for (auto c: row2chars):
        row2->add_key(self.make_char_button(c))

      shift_key := self.make_icon_button(ICON(assets::shift_icon_png), 100)
      shift_key->textWidget->font_size = btn_font_size
      shift_key->mouse.click += PLS_LAMBDA(auto &ev):
        self.caps = !self.caps
        // TODO regenerate the layout keys with capitalized keys
      ;
      row3->add_key(shift_key)
      for (auto c: row3chars):
        row3->add_key(self.make_char_button(c))
      backspace_key := new Button(0,0,self.btn_width,btn_height,"back")
      backspace_key->textWidget->font_size = btn_font_size

      backspace_key->mouse.click += PLS_LAMBDA(auto &ev):
        if self.input_box->text.size() > 0:
          self.input_box->text.pop_back()
          self.input_box->dirty = 1
          self.dirty = 1
      ;
      row3->add_key(backspace_key)

      // TODO row 4

    Button* make_char_button(char c):
      string s(1, c)
      key := new Button(0,0,self.btn_width,btn_height,s)
      key->textWidget->font_size = btn_font_size
      key->mouse.click += PLS_LAMBDA(auto &ev):
        self.dirty = 1
        self.input_box->text.push_back(c)
        self.input_box->dirty = 1
        print "key pressed:", c
      ;
      return key

    Button* make_icon_button(icons::Icon icon, int w):
      key := new Button(0,0,self.btn_width,btn_height,"")
      key->icon = icon
      return key

    void render():
      fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

    void show():
      self.scene->pinned = true
      ui::MainLoop::show_overlay(self.scene)

    // switch between: lowercase alphabet, uppercase, nums, symbols
    void switch_mode(int mode):
      // TODO
      pass
