#include <cstddef>
#include <fstream>

#define RMKIT_NOWARN_RM2 1
#include "../build/rmkit.h"
using namespace std

rm_version := util::get_remarkable_version()
def main(int argc, char **argv):
  framebuffer::FileFB *fb

  #ifdef REMARKABLE
  if rm_version == util::RM_DEVICE_ID_E::RM2:
    fb = new framebuffer::FileFB("/dev/shm/swtfb.01", framebuffer::fb_info::width, framebuffer::fb_info::height)
  else if rm_version == util::RM_DEVICE_ID_E::RM1:
    fb = new framebuffer::FileFB("/dev/fb0", framebuffer::fb_info::width, framebuffer::fb_info::height)
  else:
    debug "UNKNOWN REMARKABLE TABLET"
    exit(1)
  #endif

  #ifdef KOBO
  fb = new framebuffer::FileFB("/dev/fb0", framebuffer::fb_info::width, framebuffer::fb_info::height)
  #endif

  string fname
  if argc > 1:
    fname = argv[1]
  else:
    fname = "fb.png"
  fb->save_colorpng(fname)
