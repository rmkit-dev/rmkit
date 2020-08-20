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

    void add_key(char c):
      if self.layout == NULL:
        print "RENDERING ROW", self.x, self.y, self.w, self.h
        self.layout = new HorizontalLayout(self.x, self.y, self.w, self.h/4, self.scene)

      string s(1, c)
      key := new Button(0,0,self.h,self.h,s)
      self.layout->pack_start(key)
      print "BUTTON", s, key->x, key->y, key->w, key->h

    void render():
      pass // if a component is in scene, it gets rendered

  class Keyboard: public Widget:
    public:
    vector<Row*> rows
    bool num_mode = false
    ui::Scene scene

    Keyboard(int x=0,y=0,w=0,h=0): Widget(x,y,w,h):
      w, full_h = self.fb->get_display_size()
      h = full_h / 4

      self.scene = ui::make_scene()
      self.scene->add(self)

      string row1chars = "qwertyuoip"
      string row2chars = "asdfghjkl"
      string row3chars = "zxcvbnm"
      row1 := new Row(0,0,w,50, self.scene)
      row2 := new Row(0,0,w,50, self.scene)
      row3 := new Row(0,0,w,50, self.scene)
      row4 := new Row(0,0,w,50, self.scene)

      v_layout := ui::VerticalLayout(0, 0, w, h, self.scene)
      v_layout.pack_start(row1)
      v_layout.pack_start(row2)
      v_layout.pack_start(row3)
      v_layout.pack_start(row4)

      for (auto c: row1chars):
        row1->add_key(c)
      for (auto c: row2chars):
        row2->add_key(c)
      // TODO add button with shift icon to row3
      for (auto c: row3chars):
        row3->add_key(c)
      // TODO add button with backspace icon to row3
      // TODO row 4

    void render():
      fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

    void show():
      ui::MainLoop::show_overlay(self.scene)

    void switch_mode():
      // TODO
      pass
