#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <ctime>

// for parsing virtual_size of framebuffer
#include <fstream>
#include <iostream>

#include "../defines.h"
#include "mxcfb.h"
#include "text.h"
#include <lodepng.h>

using namespace std

namespace framebuffer:
  class FBRect:
    public:
    int x0, y0, x1, y1

  class FBImageData:
    public:
    int x, y, w, h
    remarkable_color *buffer


  inline void update_dirty(FBRect &dirty_rect, int x, y):
    dirty_rect.x0 = min(x, dirty_rect.x0)
    dirty_rect.y0 = min(y, dirty_rect.y0)
    dirty_rect.x0 = max(0, dirty_rect.x0)
    dirty_rect.y0 = max(0, dirty_rect.y0)
    dirty_rect.x1 = max(dirty_rect.x1, x)
    dirty_rect.y1 = max(dirty_rect.y1, y)

    // TODO: dont use DISPLAY* here
    dirty_rect.x1 = min(dirty_rect.x1, int(DISPLAYWIDTH)-1)
    dirty_rect.y1 = min(dirty_rect.y1, int(DISPLAYHEIGHT)-1)

  inline void reset_dirty(FBRect &dirty_rect):
    dirty_rect.x0 = DISPLAYWIDTH
    dirty_rect.y0 = DISPLAYHEIGHT
    dirty_rect.x1 = 0
    dirty_rect.y1 = 0

  class FB:
    public:
    int width=0, height=0, fd=-1
    int byte_size = 0, dirty = 0
    int update_marker = 1
    int waveform_mode = WAVEFORM_MODE_DU
    remarkable_color* fbmem
    FBRect dirty_area

    FB():
      width, height = self.get_size()
      self.width = width
      self.height = height

      printf("W: %i H: %i\n", width, height)
      size = width*height*sizeof(remarkable_color)
      self.byte_size = size
      reset_dirty(dirty_area)

      return

    FB(const FB &copy):
      printf("COPY CONSTRUCTOR CALLED\n")
      throw

    ~FB():
      if self.fd != -1:
        close(self.fd)

    virtual void cleanup():
      print "CLEANING UP FB"

    virtual void wait_for_redraw(uint32_t update_marker):
      return


    void clear_screen():
      self.draw_rect(0, 0, self.width, self.height, WHITE)

    int redraw_screen(bool full_screen=false):
      if dirty == 0:
        return 0

      dirty = 0
      um = 0

      if dirty_area.y1 == 0 || dirty_area.x1 == 0:
        return 0

      return self.perform_redraw(full_screen)

    virtual int perform_redraw(bool):
      return 0


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

      #ifdef REMARKABLE
      height /= 2
      #endif
      return width, height

    virtual tuple<int, int> get_display_size():
      return self.width, self.height

    inline void do_dithering(remarkable_color *ptr, int i, j, color, float dither=1.0):
      switch color:
        case GRAY:
          if (i + j) % 2 == 0:
            ptr[i+j*self.width] = WHITE
          else:
            ptr[i+j*self.width] = BLACK
          break
        case ERASER_RUBBER:
          if (i + j) % 2 == 0 || (i + j) % 3 == 0:
            ptr[i+j*self.width] = WHITE
          else:
            ptr[i+j*self.width] = BLACK
          break
        case ERASER_STYLUS:
          if ptr[i+j*self.width] != WHITE:
            if (i + j) % 2 == 0 || (i + j) % 3 == 0:
              ptr[i+j*self.width] = WHITE
          break
        default:
          if dither != 1.0:
            if fast_rand() / float(2 << 15) < dither:
              ptr[i + j*self.width] = color
          else:
              ptr[i + j*self.width] = color

    inline void draw_pixel(remarkable_color *ptr, int x, y, color):
      ptr[y * self.width + x] = color
      update_dirty(dirty_area, x, y)

    inline void draw_rect(int o_x, o_y, w, h, color, fill=true, float dither=1.0):
      self.dirty = 1
      remarkable_color* ptr = self.fbmem
      #ifdef DEBUG_FB
      printf("DRAWING RECT X: %i Y: %i W: %i H: %i, COLOR: %i\n", o_x, o_y, w, h, color)
      #endif

      if o_y >= self.height || o_x >= self.width || o_y < 0 || o_x < 0:
        return

      ptr += (o_x + o_y * self.width)

      update_dirty(dirty_area, o_x, o_y)
      update_dirty(dirty_area, o_x+w, o_y+h)

      for j 0 h:
        if j+o_y >= self.height:
          break

        for i 0 w:
          if i+o_x >= self.width:
            break

          if fill || (j == 0 || i == 0 || j == h-1 || i == w-1):
            do_dithering(self.fbmem, i+o_x, j+o_y, color, dither)

    def draw_bitmap(image_data &image, int o_x, int o_y):
      remarkable_color* ptr = self.fbmem
      ptr += (o_x + o_y * self.width)
      src = image.buffer

      update_dirty(dirty_area, o_x, o_y)
      update_dirty(dirty_area, o_x+image.w, o_y+image.h)

      for j 0 image.h:
        if o_y + j >= self.height:
          break

        for i 0 image.w:
          if o_x + i >= self.width:
            break

          ptr[i] = (remarkable_color) src[i]
        ptr += self.width
        src += image.w

    void draw_text(string text, int x, int y, image_data &image):
      freetype::render_text((char*)text.c_str(), x, y, image)
      draw_bitmap(image, x, y)

    void save_png():
      // save the buffer to pnm format
      fd = open("fb.pnm", O_CREAT|O_RDWR, 0755)
      lseek(fd, 0, 0)
      char c[100];
      i = sprintf(c, "P6%d %d\n255\n", self.width, self.height)
      wrote = write(fd, c, i-1)
      if wrote == -1:
        printf("ERROR %i", errno)
      buf = (char *) calloc(sizeof(char), self.width * self.height * 4)
      memset(buf, 0, sizeof(buf))

      for y 0 self.height:
        for x 0 self.width:
          d = (char) self.fbmem[y*self.width + x]
          buf[i++] = (d & 0xf800) >> 8
          buf[i++] = (d & 0x7e0) >> 3
          buf[i++] = (d & 0x1f) << 3
      buf[i] = 0

      wrote = write(fd, buf, i-1)
      if wrote == -1:
        printf("ERROR %i", errno)
      close(fd)
      free(buf)

      ret = system("pnmtopng fb.pnm > fb.png 2>/dev/null")

    string get_date():
      time_t rawtime;
      struct tm * timeinfo;
      char buffer[80];

      time (&rawtime);
      timeinfo = localtime(&rawtime);

      strftime(buffer,sizeof(buffer),"%Y-%m-%d-%H:%M:%S",timeinfo);
      std::string str(buffer);

      return str

    // replace the contents of the framebuffer with the png
    void load_from_png(string filename):
      char full_path[100]
      unsigned char* buffer
      vector<unsigned char> raw
      size_t outsize
      unsigned int neww, newh

      sprintf(full_path, "%s/%s", SAVE_DIR, filename.c_str())
      load_ret = lodepng_load_file(&buffer, &outsize, full_path)
      decode_ret = lodepng::decode(raw, neww, newh, buffer, outsize)

      image = image_data{(uint32_t*) raw.data(), (int) neww, (int) newh}
      self->draw_bitmap(image, 0,0)

      free(buffer)


    string save_lodepng():
      char filename[100]
      char full_filename[100]
      char mkdir_cmd[100]

      datestr = self.get_date()
      datecstr = datestr.c_str()

      sprintf(mkdir_cmd, "mkdir %s 2>/dev/null", SAVE_DIR)
      err = system(mkdir_cmd)
      sprintf(filename, "%s/%s%s", SAVE_DIR, datecstr, ".png")
      px_w, px_h = self.get_display_size()

      buf = vector<unsigned char>(px_w * px_h * 4+1)
      i = 0
      for y 0 self.height:
        for x 0 self.width:
          d = self.fbmem[y*self.width + x] == 0 ? 0 : 0xff
          buf[i++] = d
          buf[i++] = d
          buf[i++] = d
          buf[i++] = 0xff
      buf[i] = 0

      lodepng::encode(filename, buf, self.width, self.height);
      return string(filename)

    // bresenham's outline
    def draw_circle_outline(int x0, y0, r, stroke,color):
      y = r
      x = 0;
      w = stroke
      h = stroke

      self.draw_rect(x, y, w, h, color, true);
      d = (3-2*(int)r);
      while (x <= y):
        if (d <= 0):
          d = d + (4*x + 6);
        else:
          d = d + 4*(x-y) + 10;
          y--;
        x++;

        self.draw_rect(x+x0, y+y0, w, h, color, true);

        self.draw_rect(-x+x0, y+y0, w, h, color, true);
        self.draw_rect(x+x0, -y+y0, w, h, color, true);

        self.draw_rect(-x+x0, -y+y0, w, h, color, true);
        self.draw_rect(y+x0, x+y0, w, h, color, true);
        self.draw_rect(-y+x0, x+y0, w, h, color, true);
        self.draw_rect(y+x0, -x+y0, w, h, color, true);

        self.draw_rect(-y+x0, -x+y0, w, h, color, true);

    def draw_circle_filled(int x0, y0, radius, stroke, color):
      for int x = -radius; x <= radius; x++:
        for y = -radius; y <= radius; y++:
          if (x*x+y*y) <= radius*radius:
            self.draw_rect(x+x0, y+y0, stroke, stroke, color, true)

    def draw_circle(int x0, y0, r, stroke, color, fill=false):
      if fill:
        self.draw_circle_filled(x0, y0, r, stroke, color)
      else:
        self.draw_circle_outline(x0, y0, r, stroke, color)

    def draw_line_circle(int x0,y0,x1,y1,width,color,float dither=1.0):
      #ifdef DEBUG_FB
      printf("DRAWING LINE w. CIRCLES %i %i %i %i\n", x0, y0, x1, y1)
      #endif
      self.dirty = 1
      dx =  abs(x1-x0)
      sx = x0<x1 ? 1 : -1
      dy = -abs(y1-y0)
      sy = y0<y1 ? 1 : -1
      err = dx+dy  /* error value e_xy */
      while (true):   /* loop */
        self.draw_circle(x0, y0, width/2, 1, color,true)
        // self.fbmem[y0*self.width + x0] = color
        if (x0==x1 && y0==y1) break;
        e2 = 2*err
        if (e2 >= dy):
          err += dy /* e_xy+e_x > 0 */
          x0 += sx
        if (e2 <= dx): /* e_xy+e_y < 0 */
          err += dx
          y0 += sy

    def draw_line(int x0,y0,x1,y1,width,color,float dither=1.0):
      #ifdef DEBUG_FB
      printf("DRAWING LINE %i %i %i %i\n", x0, y0, x1, y1)
      #endif
      self.dirty = 1
      dx =  abs(x1-x0)
      sx = x0<x1 ? 1 : -1
      dy = -abs(y1-y0)
      sy = y0<y1 ? 1 : -1
      err = dx+dy  /* error value e_xy */
      while (true):   /* loop */
        self.draw_rect(x0, y0, width, width, color,true,dither)
        // self.fbmem[y0*self.width + x0] = color
        if (x0==x1 && y0==y1) break;
        e2 = 2*err
        if (e2 >= dy):
          err += dy /* e_xy+e_x > 0 */
          x0 += sx
        if (e2 <= dx): /* e_xy+e_y < 0 */
          err += dx
          y0 += sy

  class HardwareFB: public FB:
    public:
    HardwareFB(): FB():
      self.fd = open("/dev/fb0", O_RDWR)
      self.fbmem = (remarkable_color*) mmap(NULL, self.byte_size, PROT_WRITE, MAP_SHARED, self.fd, 0)

      fb_var_screeninfo vinfo;
      if (ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)):
        printf("Could not get screen vinfo for %s\n", "/dev/fb0")
        return

      print "XRES", vinfo.xres, "YRES", vinfo.yres, "BPP", vinfo.bits_per_pixel, "GRAYSCALE", vinfo.grayscale

    void wait_for_redraw(uint32_t update_marker):
      mxcfb_update_marker_data mdata = { update_marker, 0 }
      ioctl(self.fd, MXCFB_WAIT_FOR_UPDATE_COMPLETE, &mdata)

    tuple<int, int> get_display_size():
      fb_var_screeninfo vinfo;
      ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)

      return vinfo.xres, vinfo.yres

    int perform_redraw(bool full_screen=false):
      um = 0
      mxcfb_update_data update_data
      mxcfb_rect update_rect

      if !full_screen:
        update_rect.top = dirty_area.y0
        update_rect.left = dirty_area.x0
        update_rect.width = dirty_area.x1 - dirty_area.x0
        update_rect.height = dirty_area.y1 - dirty_area.y0
      else:
        update_rect.top = 0
        update_rect.left = 0
        update_rect.width = DISPLAYWIDTH
        update_rect.height = DISPLAYHEIGHT

      update_data.update_marker = 0
      update_data.update_region = update_rect
      update_data.waveform_mode = self.waveform_mode
      update_data.update_mode = UPDATE_MODE_PARTIAL
      update_data.dither_mode = EPDC_FLAG_EXP1
      update_data.temp = TEMP_USE_REMARKABLE_DRAW
      update_data.flags = 0
      self.waveform_mode = WAVEFORM_MODE_DU

      if update_rect.height == 0 || update_rect.width == 0:
        return um

      ioctl(self.fd, MXCFB_SEND_UPDATE, &update_data)
      um = update_data.update_marker

      reset_dirty(self.dirty_area)
      return um

  class FileFB: public FB:
    public:
    FileFB(): FB():
      self.width = DISPLAYWIDTH
      self.height = DISPLAYHEIGHT
      self.byte_size = self.width * self.height * sizeof(remarkable_color)
      // make an empty file of the right size
      std::ofstream ofs("fb.raw", std::ios::binary | std::ios::out);
      ofs.seekp(self.byte_size);
      ofs.write("", 1);
      ofs.close()

      self.fd = open("./fb.raw", O_RDWR)
      self.fbmem = (remarkable_color*) mmap(NULL, self.byte_size, PROT_WRITE, MAP_SHARED, self.fd, 0)

    int perform_redraw(bool):
      #ifndef PERF_BUILD
      msync(self.fbmem, self.byte_size, MS_SYNC)
      self.save_png()
      #endif
      return 0

  class VirtualFB: public FB:
    public:
    VirtualFB(int w, h): FB():
      self.width = w
      self.height = h
      self.byte_size = self.width * self.height * sizeof(remarkable_color)
      self.fbmem = (remarkable_color*) malloc(self.byte_size)
      self.fd = -1

  class RemarkableFB: public HardwareFB:
    public:
    RemarkableFB():
      // if we are using remarkable, then we set it to grayscale
      fb_var_screeninfo vinfo;
      if (ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)):
        printf("Could not get screen vinfo for %s\n", "/dev/fb0")
        exit(0)

      #ifdef GRAYSCALE_8BIT
      vinfo.bits_per_pixel = 8;
      vinfo.grayscale = GRAYSCALE_8BIT;
      #else
      vinfo.bits_per_pixel = 16;
      vinfo.grayscale = 0;
      retval = ioctl(self.fd, FBIOPUT_VSCREENINFO, &vinfo);
      #endif

      auto_update_mode = AUTO_UPDATE_MODE_AUTOMATIC_MODE
      ioctl(self.fd, MXCFB_SET_AUTO_UPDATE_MODE, (pointer_size) &auto_update_mode);

    void cleanup():
      print "CLEANING UP FB"
      fb_var_screeninfo vinfo;
      if (ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)):
        printf("Could not get screen vinfo for %s\n", "/dev/fb0")
        exit(0)

      vinfo.bits_per_pixel = 16;
      vinfo.grayscale = 0
      retval = ioctl(self.fd, FBIOPUT_VSCREENINFO, &vinfo);
