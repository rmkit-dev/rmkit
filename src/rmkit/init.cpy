#include <iostream>
#include <csignal>

#include "fb/fb.h"
#include "ui/widget.h"
#include "ui/main_loop.h"
#include "input/input.h"

static void _rmkit_exit() __attribute__((destructor))
static void _rmkit_exit(int signum):
  fb := framebuffer::get()
  fb->cleanup()
  ui::MainLoop::in.ungrab()

  switch signum:
    case SIGINT:
      cerr << "received SIGINT, exiting" << endl;
      break
    case SIGKILL:
      cerr << "received SIGKILL, exiting" << endl;
      break
    case SIGSEGV:
      cerr << "received SIGABRT, exiting" << endl;
      break
    case SIGABRT:
      cerr << "received SIGABRT, exiting" << endl;
      break
  exit(signum)

static void _rmkit_init() __attribute__((constructor))
static void _rmkit_init():
  std::ios_base::Init i;

  fb := framebuffer::get()
  ui::Widget::fb = fb.get()
  w, h = fb->get_display_size()
  input::MouseEvent::set_screen_size(w, h)

  for auto s : { SIGINT, SIGTERM, SIGABRT, SIGSEGV}:
    signal(s, _rmkit_exit)
