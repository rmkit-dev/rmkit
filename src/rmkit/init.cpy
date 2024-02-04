#include <iostream>
#include <csignal>

#include "fb/fb.h"
#include "ui/widget.h"
#include "ui/main_loop.h"
#include "input/input.h"
#include "util/rm2fb.h"
#include "util/machine_id.h"
#include "util/lsdir.h"

static void _rmkit_exit() __attribute__((destructor))
static void _rmkit_exit(int signum):
  fb := framebuffer::get()
  fb->cleanup()
  ui::MainLoop::in.ungrab()

  switch signum:
    case SIGINT:
      cerr << "received SIGINT, exiting" << endl;
      break
    case SIGTERM:
      cerr << "received SIGTERM, exiting" << endl;
      break
    case SIGSEGV:
      cerr << "received SIGABRT, exiting" << endl;
      break
    case SIGABRT:
      cerr << "received SIGABRT, exiting" << endl;
      break

  ui::MainLoop::exit(signum)
  exit(signum)

static void _rmkit_init() __attribute__((constructor))
static void _rmkit_init():
  std::ios_base::Init i;

  rm_version := util::get_remarkable_version()
  in_shim := getenv("RM2FB_SHIM")
  if in_shim != NULL and strlen(in_shim) != 0:
    rm2fb::IN_RM2FB_SHIM = true
  else if rm_version == util::RM_DEVICE_ID_E::RM2:
    #ifndef RMKIT_NOWARN_RM2
    debug "*********************************************"
    debug "*** WARNING: running on rM2 without rm2fb ***"
    debug "*********************************************"
    debug ""
    #endif
    pass

  fb := framebuffer::get()
  ui::Widget::fb = fb.get()

  for auto s : { SIGINT, SIGTERM, SIGABRT, SIGSEGV}:
    signal(s, _rmkit_exit)
