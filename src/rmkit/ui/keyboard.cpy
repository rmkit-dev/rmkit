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
    HorizontalLayout *layout
    Scene scene

    Row(int x, y, w, h, Scene s): Widget(x,y,w,h):
      self.scene = s

    void add_key(Button *key):
      if self.layout == NULL:
        print "RENDERING ROW", self.x, self.y, self.w, self.h
        self.layout = new HorizontalLayout(self.x, self.y, self.w, self.h/4, self.scene)
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

    Keyboard(int x=0,y=0,w=0,h=0): Widget(x,y,w,h):
      self.input_box = new Text(500,500,200,50,"");
      w, full_h = self.fb->get_display_size()
      h = full_h / 4
      self.w = w
      self.h = h

      self.scene = ui::make_scene()
      self.scene->add(self)

      string row1chars = "qwertyuoip"
      string row2chars = "asdfghjkl"
      string row3chars = "zxcvbnm"
      row1 := new Row(0,0,w,50, self.scene)
      row2 := new Row(h/8,0,w,50, self.scene)
      row3 := new Row(0,0,w,50, self.scene)
      row4 := new Row(0,0,w,50, self.scene)

      v_layout := ui::VerticalLayout(0, 0, w, h, self.scene)
      v_layout.pack_start(row1)
      v_layout.pack_start(row2)
      v_layout.pack_start(row3)
      v_layout.pack_start(row4)

      for (auto c: row1chars):
        row1->add_key(self.make_char_button(c))

      for (auto c: row2chars):
        row2->add_key(self.make_char_button(c))

      shift_key := self.make_icon_button(ICON(assets::shift_icon_png), 100)
      shift_key->mouse.click += PLS_LAMBDA(auto &ev):
        self.caps = !self.caps
        // TODO regenerate the layout keys with capitalized keys
      ;
      row3->add_key(shift_key)
      for (auto c: row3chars):
        row3->add_key(self.make_char_button(c))
      backspace_key := new Button(0,0,100,self.h/4,"back")
      backspace_key->mouse.click += PLS_LAMBDA(auto &ev):
        self.input_box->text.pop_back()
      ;
      row3->add_key(backspace_key)

      // TODO row 4

    Button* make_char_button(char c):
      string s(1, c)
      key := new Button(0,0,self.h/4,self.h/4,s)
      key->mouse.click += PLS_LAMBDA(auto &ev):
        self.input_box->text.push_back(c)
        print "key pressed:", c
      ;
      return key

    Button* make_icon_button(icons::Icon icon, int w):
      key := new Button(0,0,w,self.h/4,"")
      key->icon = icon
      return key

    void render():
      fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

    void show():
      ui::MainLoop::show_overlay(self.scene)

    // switch between: lowercase alphabet, uppercase, nums, symbols
    void switch_mode(int mode):
      // TODO
      pass
