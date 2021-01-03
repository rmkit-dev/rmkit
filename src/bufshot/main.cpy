#include <cstddef>
#include <fstream>

#include "../build/rmkit.h"
#include "../rmkit/util/machine_id.h"
using namespace std

rm_version := util::get_remarkable_version()
def main(int argc, char **argv):

  framebuffer::FileFB *fb
  if rm_version == util::RM_VERSION::RM2:
    fb = new framebuffer::FileFB("/dev/shm/swtfb.01", DISPLAYWIDTH, DISPLAYHEIGHT)
  else if rm_version == util::RM_VERSION::RM1:
    fb = new framebuffer::FileFB("/dev/fb", DISPLAYWIDTH, DISPLAYHEIGHT)
  else:
    debug "UNKNOWN REMARKABLE TABLET"
    exit(1)

  string fname
  if argc > 1:
    fname = argv[1]
  else:
    fname = "fb.png"
  fb->save_lodepng(fname)
