#include "widget.h"
#include "../defines.h"
#include "../fb/stb_text.h"

namespace ui:
  // class: ui::Text
  // --- Prototype ---
  // class ui::Text: public ui::Widget:
  // -----------------
  // the ui::Text class is a Widget that can render a single line of text.
  class Text: public Widget:
    public:
    string text

    // function: Constructor
    // parameters:
    //
    // x - x coord
    // y - y coord
    // w - width
    // h - height
    // t - the text to render in the widget
    Text(int x, y, w, h, string t): Widget(x, y, w, h):
      self.text = t

    tuple<int, int> get_render_size():
      image := stbtext::get_text_size(self.text, self.style.font_size)
      return image.w, image.h

    void set_text(string t):
      self.text = t
      self.dirty = 1

    // TODO: cache the image buffer
    void render():
      font_size := self.style.font_size
      image := stbtext::get_text_size(self.text, font_size)

      image.buffer = (uint32_t*) malloc(sizeof(uint32_t) * image.w * image.h)
      memset(image.buffer, WHITE, sizeof(uint32_t) * image.w * image.h)

      leftover_x := self.w - image.w
      draw_x := self.x
      draw_y := self.y

      switch self.style.justify:
        case Style::JUSTIFY::CENTER:
          if leftover_x > 0:
            draw_x += leftover_x / 2
          break
        case Style::JUSTIFY::RIGHT:
          if leftover_x > 0:
            draw_x += leftover_x
          break

      switch self.style.valign:
        case Style::VALIGN::MIDDLE:
          draw_y += (self.h - font_size) / 2
          break
        case Style::VALIGN::BOTTOM:
          draw_y += self.h - font_size
          break

      fb->draw_text(self.text, draw_x, draw_y, image, font_size)
      if self.style.underline:
        fb->draw_line(draw_x, draw_y+font_size, draw_x+image.w,
                      draw_y+font_size, 1, BLACK)

      free(image.buffer)

  // class: ui::MultiText
  // --- Prototype ---
  // class ui::MultiText: public ui::Text:
  // -----------------
  // the MultiText class is for writing multiple lines of text, as it
  // automatically inserts line breaks where appropriate when rendering
  //
  // currently, MultiText does not support justification
  class MultiText: public Text:
    public:
    // function: Constructor
    //
    // parameters:
    //
    // x - x coord
    // y - y coord
    // w - width
    // h - height
    // t - the text to render in the widget
    MultiText(int x, y, w, h, string t): Text(x, y, w, h, t):
      pass

    void render():
      cur_x := 0
      cur_y := 0
      lines := split_lines(self.text)
      font_size := self.style.font_size
      line_height := stbtext::get_line_height(font_size) * self.style.line_height
      for auto line: lines:
        cur_x = 0
        tokens := split(line, ' ')
        for auto w: tokens:
          w += " "
          image := stbtext::get_text_size(w, font_size)
          image.buffer = (uint32_t*) malloc(sizeof(uint32_t) * image.w * image.h)
          memset(image.buffer, WHITE, sizeof(uint32_t) * image.w * image.h)
          if cur_x + image.w + 10 >= self.w:
            cur_x = 0
            cur_y += line_height
          self.fb->draw_text(w, self.x + cur_x, self.y + cur_y, image, font_size)
          if self.style.underline:
            self.fb->draw_line(self.x+cur_x, self.y+cur_y+font_size, self.x+cur_x+image.w,
                               self.y + cur_y+font_size, 1, BLACK)
          free(image.buffer)
          cur_x += image.w
        cur_y += line_height

    tuple<int, int> get_render_size():
      cur_x := 0
      cur_y := 0
      ret_w := 0
      ret_h := 0
      lines := split_lines(self.text)
      font_size := self.style.font_size
      line_height := stbtext::get_line_height(font_size) * self.style.line_height
      for auto line: lines:
        cur_x = 0
        tokens := split(line, ' ')
        for auto w: tokens:
          w += " "
          image := stbtext::get_text_size(w, font_size)
          if cur_x + image.w + 10 >= self.w:
            cur_x = 0
            cur_y += line_height
          cur_x += image.w
        cur_y += line_height

        ret_h = max(ret_h, cur_y)
        ret_w = max(ret_w, cur_y)

      return ret_w, ret_h
