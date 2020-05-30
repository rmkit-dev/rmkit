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
  int update_marker = 1
  uint32_t* fbmem

  FB():
    width, height = this->get_size()
    this->width = width
    this->height = height

    printf("W: %i H: %i\n", width, height)

    this->fd = open("/dev/fb0", O_RDWR)
    fbmem = (uint32_t*) mmap(NULL, width*height*sizeof(uint32_t), PROT_WRITE, MAP_SHARED, this->fd, 0)

  ~FB():
    close(this->fd)

  def wait_for_redraw(int update_marker):
    #ifdef REMARKABLE
    mxcfb_update_marker_data mdata = { update_marker, 0 }
    ioctl(this->fd, MXCFB_WAIT_FOR_UPDATE_COMPLETE, &mdata)
    #endif
    return


  def redraw_screen(bool wait_for_refresh=false):
    um = 0
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
      update_data.update_marker = this->update_marker++

    ioctl(this->fd, MXCFB_SEND_UPDATE, &update_data)
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
    uint32_t* ptr = this->fbmem
  
    ptr += (o_x + o_y * this->width)

    for y 0 h:
      for x 0 w:
        ptr[y*this->width + x] = color

  def draw_rect(rect r, int color):
    w = r.w
    h = r.h

    #ifdef REMARKABLE
    w /= 2
    #endif

    this->draw_rect(r.x, r.y, w, h, color)

#endif
