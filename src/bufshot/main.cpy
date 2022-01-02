#include <cstddef>
#include <fstream>

#define RMKIT_NOWARN_RM2 1
#include "../build/rmkit.h"
using namespace std

#define RM1_DWIDTH 1408
#define RM2_DWIDTH 1404

rm_version := util::get_remarkable_version()
def main(int argc, char **argv):
  framebuffer::FileFB *fb

  // using this for the sideeffect of setting up framebuffer::fb_info
  framebuffer::get()

  #ifdef REMARKABLE
  if rm_version == util::RM_VERSION::RM2:
    fb = new framebuffer::FileFB("/dev/shm/swtfb.01", framebuffer::fb_info::display_width, framebuffer::fb_info::display_height)
  else if rm_version == util::RM_VERSION::RM1:
    fb = new framebuffer::FileFB("/dev/fb0", framebuffer::fb_info::display_width, framebuffer::fb_info::display_height)
  else:
    debug "UNKNOWN REMARKABLE TABLET"
    exit(1)
  #endif

  #ifdef KOBO
  fb = new framebuffer::FileFB("/dev/fb0", framebuffer::fb_info::display_width, framebuffer::fb_info::display_height)
  #endif

  string fname
  if argc > 1:
    fname = argv[1]
  else:
    fname = "fb.png"
  fb->save_colorpng(fname)
