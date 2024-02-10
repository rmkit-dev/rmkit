using namespace ui

BLANK := WHITE
WRONG_PLACE := color::gray32(25)
RIGHT_PLACE := color::gray32(15)
WRONG_LETTER := WHITE - 1

namespace wordle:
  namespace keyboard:
    Stylesheet BTN_STYLE = Stylesheet().font_size(48).valign_middle()
    using namespace ui;

    class KeyButton: public ui::Button:
      public:
      remarkable_color color = WHITE
      KeyButton(int x, y, w, h, string t): ui::Button(x, y, w, h, t):
        pass

      void before_render():
        ui::Button::before_render()
        self.mouse_inside = self.mouse_down && self.mouse_inside

      void render():
        fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)
        if self.color == WRONG_LETTER:
          fb->draw_line(self.x, self.y, self.x+self.w, self.y+self.h, 2, BLACK)
          fb->draw_line(self.x+self.w, self.y, self.x, self.y+self.h, 2, BLACK)

        else:
          fb->draw_rect(self.x, self.y, self.w, self.h, self.color, true)

        self.textWidget->render()

        color := WHITE
        if self.mouse_inside:
          color = BLACK

        fill := false
        if self.mouse_down:
          fill = true
        fb->draw_rect(self.x, self.y, self.w, self.h, color, fill)



    class Row: public Widget:
      public:
      HorizontalLayout *layout = NULL
      Scene scene

      Row(int x, y, w, h, Scene s): Widget(x,y,w,h):
        self.scene = s

      void add_key(KeyButton *key):
        if self.layout == NULL:
          debug "RENDERING ROW", self.x, self.y, self.w, self.h
          self.layout = new HorizontalLayout(self.x, self.y, self.w, self.h, self.scene)
        self.layout->pack_start(key)

      void render():
        pass // if a component is in scene, it gets rendered

    class Keyboard: public Widget:
      class KEYBOARD_EVENTS:
        public:
        KEYBOARD_EVENT changed
        KEYBOARD_EVENT done

      public:
      vector<Row*> rows
      map<char, KeyButton*> keys
      Scene scene
      string text = ""
      int btn_width
      int btn_height

      KEYBOARD_EVENTS events

      Keyboard(Scene s): Widget(0, 0, 0, 0)
        self.scene = s
        w, full_h = self.fb->get_display_size()
        h = full_h / 4
        self.w = w
        self.h = h
        self.upper_layout()

      void upper_layout():
        self.set_layout(
          "QWERTYUIOP",
          "ASDFGHJKL",
          "ZXCVBNM"
        )

      void set_layout(string row1chars, row2chars, row3chars):
        self.btn_width = w / row1chars.size()
        self.btn_height = 100
        indent := row1chars.size() > row2chars.size() ? h/8 : 0
        row1 := new Row(0,0,w,100, self.scene)
        row2 := new Row(indent,0,w,100, self.scene)
        row3 := new Row(indent,0,w,100, self.scene)

        fw, fh = self.fb->get_display_size()
        v_layout := ui::VerticalLayout(0, 0, fw, fh, self.scene)

        v_layout.pack_end(row3)
        v_layout.pack_end(row2)
        v_layout.pack_end(row1)

        for (auto c: row1chars):
          row1->add_key(self.make_char_button(c))

        for (auto c: row2chars):
          row2->add_key(self.make_char_button(c))

        backspace_key := new KeyButton(0,0,self.btn_width,btn_height,"back")
        backspace_key->set_style(BTN_STYLE)
        backspace_key->mouse.click += PLS_LAMBDA(auto &ev):
          if self.text.size() > 0:
            self.text.pop_back()
            KeyboardEvent kev(self.text)
            self.events.changed(kev)
            self.dirty = 1
        ;
        row3->add_key(backspace_key)
        for (auto c: row3chars):
          row3->add_key(self.make_char_button(c))

        enter_key := new KeyButton(0,0,self.btn_width,btn_height,"enter")
        enter_key->set_style(BTN_STYLE)
        enter_key->mouse.click += PLS_LAMBDA(auto &ev):
          KeyboardEvent kev(self.text)
          kev.text = self.text
          if self.text.length() == 5:
            self.events.done(kev)
        ;

        row3->add_key(enter_key)

      void mark_color(char c, remarkable_color color):
        key := self.keys.find(c)
        if key != self.keys.end():
          if key->second->color > color:
            key->second->color = color
            key->second->dirty = 1

      void clear_colors(remarkable_color color):
        for auto key : self.keys:
          key.second->color = color

      KeyButton* make_char_button(char c):
        string s(1, c)
        key := new KeyButton(0,0,self.btn_width,btn_height,s)
        key->set_style(BTN_STYLE)
        key->mouse.click += PLS_LAMBDA(auto &ev):
          self.dirty = 1
          if c == ' ':
            return

          if self.text.length() < 5:
            self.text.push_back(c)
            KeyboardEvent kev(self.text)
            self.events.changed(kev)
        ;

        self.keys[c] = key
        return key

      KeyButton* make_icon_button(icons::Icon icon, int w):
        key := new KeyButton(0,0,self.btn_width,btn_height,"")
        key->icon = icon
        return key

      void render():
        pass
    ;
