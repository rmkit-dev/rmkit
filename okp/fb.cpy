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
#include "text.h"

using namespace std

struct rect:
  int x, y, w, h

typedef struct rect rect

void do_nothing(int x, y):
  pass


class FB:
  private:

  public:
  int width, height, fd
  int byte_size, dirty
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

    auto_update_mode = AUTO_UPDATE_MODE_AUTOMATIC_MODE
    ioctl(self.fd, MXCFB_SET_AUTO_UPDATE_MODE, &auto_update_mode);
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

  FB(const FB &copy):
    printf("COPY CONSTRUCTOR CALLED\n")
    throw

  ~FB():
    close(self.fd)

  def wait_for_redraw(uint32_t update_marker):
    #ifdef REMARKABLE
    mxcfb_update_marker_data mdata = { update_marker, 0 }
    ioctl(self.fd, MXCFB_WAIT_FOR_UPDATE_COMPLETE, &mdata)
    #endif
    return


  def redraw_screen(bool wait_for_refresh=false, rect *redraw_area=NULL):
    if dirty == 0:
      return 0

    dirty = 0
    um = 0
    #ifdef DEV
    msync(self.fbmem, self.byte_size, MS_SYNC)
    self.save_pnm()
    #endif

    #ifdef REMARKABLE
    printf("REDRAWING SCREEN\n")
    mxcfb_update_data update_data
    mxcfb_rect update_rect

    if redraw_area != NULL:
      update_rect.top = redraw_area->y
      update_rect.left = redraw_area->x
      update_rect.width = redraw_area->w
      update_rect.height = redraw_area->h
    else:
      update_rect.top = 0
      update_rect.left = 0
      update_rect.width = 1404
      update_rect.height = 1872

    update_data.update_region = update_rect
    update_data.waveform_mode = WAVEFORM_MODE_DU
    update_data.update_mode = UPDATE_MODE_PARTIAL
    update_data.dither_mode = EPDC_FLAG_EXP1
    update_data.temp = TEMP_USE_REMARKABLE_DRAW
    update_data.flags = 0

    update_data.update_marker = 0
    if wait_for_refresh:
      update_data.update_marker = self.update_marker++

    ioctl(self.fd, MXCFB_SEND_UPDATE, &update_data)
    um = update_data.update_marker
    #endif
    return um

  def redraw_if_dirty():
    if self.dirty:
      self.redraw_screen()

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

  def draw_rect(int o_x, o_y, w, h, color, fill=true):
    self.dirty = 1
    uint32_t* ptr = self.fbmem
    printf("DRAWING RECT X: %i Y: %i W: %i H: %i, COLOR: %i\n", o_x, o_y, w, h, color)

    ptr += (o_x + o_y * self.width)

    for j 0 h:
      for i 0 w:
        if j+o_y >= self.height || i+o_x >= self.width:
          continue

        if fill || (j == 0 || i == 0 || j == h-1 || i == w-1):
          ptr[j*self.width + i] = color

  def draw_rect(rect r, int color, fill=true):
    w = r.w
    h = r.h

    self.draw_rect(r.x, r.y, w, h, color, fill)

  def draw_bitmap(freetype::image_data image, int o_x, int o_y):
    uint32_t* ptr = self.fbmem
    ptr += (o_x + o_y * self.width)
    for j 0 image.h:
      for i 0 image.w:
        ptr[j*self.width + i] = (uint32_t)image.buffer[j*image.w+i]

  def draw_text(string text, int x, int y, freetype::image_data image):
    freetype::render_text((char*)text.c_str(), x, y, image)
    draw_bitmap(image, x, y)

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

    ret = system("pnmtopng fb.pnm > fb.png 2>/dev/null")

#endif
