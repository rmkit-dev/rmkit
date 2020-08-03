#include <iostream>
#include "fb/fb.h"
#include "ui/widget.h"
#include "input/input.h"

static void _rmkit_init() __attribute__((constructor))
static void _rmkit_init():
  std::ios_base::Init i;

  fb := framebuffer::get()
  ui::Widget::fb = fb.get()
  w, h = fb->get_display_size()
  input::MouseEvent::set_screen_size(w, h)
