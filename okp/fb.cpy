#ifndef FB_CPY
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

// for parsing virtual_size of framebuffer
#include <fstream>
#include <iostream>

#include "defines.h"
#include "mxcfb.h"

using namespace std

struct rect:
  int x, y, w, h

typedef struct rect rect

class FB:
  private:

  public:
  int width, height, fd
  int byte_size
  int update_marker = 1
  uint32_t* fbmem

  FB():
    width, height = self.get_size()
    self.width = width
    self.height = height

    printf("W: %i H: %i\n", width, height)
    size = width*height*sizeof(uint32_t)
    self.byte_size = size

    #ifndef DEV
    self.fd = open("/dev/fb0", O_RDWR)
    fbmem = (uint32_t*) mmap(NULL, size, PROT_WRITE, MAP_SHARED, self.fd, 0)
    #else
    // make an empty file of the right size
    std::ofstream ofs("fb.raw", std::ios::binary | std::ios::out);
    ofs.seekp(size);
    ofs.write("", 1);
    ofs.close()



    self.fd = open("./fb.raw", O_RDWR)
    fbmem = (uint32_t*) mmap(NULL, size, PROT_WRITE, MAP_SHARED, self.fd, 0)
    #endif
    return

  ~FB():
    close(self.fd)

  def wait_for_redraw(uint32_t update_marker):
    #ifdef REMARKABLE
    mxcfb_update_marker_data mdata = { update_marker, 0 }
    ioctl(self.fd, MXCFB_WAIT_FOR_UPDATE_COMPLETE, &mdata)
    #endif
    return


  def redraw_screen(bool wait_for_refresh=false):
    um = 0
    #ifdef DEV
    msync(self.fbmem, self.byte_size, MS_SYNC)
    self.save_pnm()
    #endif

    #ifdef REMARKABLE
    mxcfb_update_data update_data
    mxcfb_rect update_rect

    update_rect.top = 0
    update_rect.left = 0
    update_rect.width = 1404
    update_rect.height = 1872

    update_data.update_region = update_rect
    update_data.waveform_mode = WAVEFORM_MODE_AUTO
    update_data.update_mode = UPDATE_MODE_PARTIAL
    update_data.temp = TEMP_USE_AMBIENT
    update_data.flags = 0

    update_data.update_marker = 0
    if wait_for_refresh:
      update_data.update_marker = self.update_marker++

    ioctl(self.fd, MXCFB_SEND_UPDATE, &update_data)
    printf("REDRAWING SCREEN\n")
    um = update_data.update_marker
    #endif
    return um

  tuple<int,int> get_size():
    size_f = ifstream("/sys/class/graphics/fb0/virtual_size")
    string width_s, height_s
    char delim = ',';
    getline(size_f, width_s, delim)
    getline(size_f, height_s, delim)

    width = stoi(width_s)
    height = stoi(height_s)

    f = 1
    #ifdef REMARKABLE
    f = 2
    #endif

    return width/f, height/f

  def draw_rect(int o_x, o_y, w, h, color):
    printf("DRAWING RECT: %i %i %i %i COLOR: %i\n", o_x, o_y, w, h, color)
    uint32_t* ptr = self.fbmem

    ptr += (o_x + o_y * self.width)

    for y 0 h:
      for x 0 w:
        ptr[y*self.width + x] = color

  def draw_rect(rect r, int color):
    w = r.w
    h = r.h

    #ifdef REMARKABLE
    w /= 2
    #endif

    self.draw_rect(r.x, r.y, w, h, color)

  void save_pnm():
    // save the buffer to pnm format
    fd = open("fb.pnm", O_CREAT|O_RDWR, 0755)
    lseek(fd, 0, 0)
    char c[100];
    i = sprintf(c, "P6%d %d\n255\n", self.width, self.height)
    wrote = write(fd, c, i-1)
    if wrote == -1:
      printf("ERROR %i", errno)
    char buf[self.width * self.height * 4]
    ptr = &buf[0]

    for y 0 self.height:
      for x 0 self.width:
        d = (short) self.fbmem[y*self.width + x]
        buf[i++] = (d & 0xf800) >> 8
        buf[i++] = (d & 0x7e0) >> 3
        buf[i++] = (d & 0x1f) << 3
    buf[i] = 0

    wrote = write(fd, buf, i-1)
    if wrote == -1:
      printf("ERROR %i", errno)
    close(fd)

    ret = system("pnmtopng fb.pnm > fb.png")

#endif
