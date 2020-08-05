#include <iostream>
#include <csignal>
#include "fb/fb.h"
#include "ui/widget.h"
#include "input/input.h"

static void _rmkit_exit() __attribute__((destructor))
static void _rmkit_exit(int signum):
  fb := framebuffer::get()
  fb->cleanup()
  exit(signum)

static void _rmkit_init() __attribute__((constructor))
static void _rmkit_init():
  std::ios_base::Init i;

  fb := framebuffer::get()
  ui::Widget::fb = fb.get()
  w, h = fb->get_display_size()
  input::MouseEvent::set_screen_size(w, h)

  for auto s : { SIGINT, SIGTERM, SIGABRT}:
    signal(s, _rmkit_exit)
