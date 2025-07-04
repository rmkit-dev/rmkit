#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <ctime>
#include <linux/limits.h>

// for parsing virtual_size of framebuffer
#include <fstream>
#include <iostream>

#include "../defines.h"
#include "mxcfb.h"
#include "mtk-kobo.h"
#include "stb_text.h"
#include "dither.h"
#include "../input/input.h"
#include "../util/signals.h"
#include "../util/image.h"
#include "../util/rm2fb.h"
#include "../util/rotate.h"
#include "../../vendor/stb/stb_image.h"
#include "../../vendor/stb/stb_image_write.h"

#ifdef RMKIT_FBINK
#include "../../vendor/fbink.h"
#endif

#define likely(x)      __builtin_expect(!!(x), 1)
#define unlikely(x)      __builtin_expect(!!(x), 0)

using namespace std

namespace framebuffer:
  extern int ALPHA_BLEND = 4160223223
  extern bool DEBUG_FB_INFO = 1
  // (getenv("DEBUG_FB_INFO") != NULL)

  inline bool file_exists (const std::string& name):
    struct stat buffer;
    return (stat (name.c_str(), &buffer) == 0);

  class FBRect:
    public:
    int x0, y0, x1, y1

  class FBImageData:
    public:
    int x, y, w, h
    remarkable_color *buffer

  struct ResizeEvent:
    int w
    int h
    int bpp
  ;

  inline void reset_dirty(FBRect &dirty_rect):
    dirty_rect.x0 = fb_info::display_width
    dirty_rect.y0 = fb_info::display_height
    dirty_rect.x1 = 0
    dirty_rect.y1 = 0


  PLS_DEFINE_SIGNAL(RESIZE_EVENT, ResizeEvent)

  // class: framebuffer::FB
  // FB is the main framebuffer that implements I/O primitives for the
  // framebuffer. There are several subclasses of FB: VirtualFB, FileFB,
  // HardwareFB and RemarkableFB
  //
  // - The VirtualFB uses memory as the framebuffer
  // - The FileFB is an mmap backed file, which can be used for debugging or emulating the
  //    app. It saves the current framebuffer to fb.png every time the screen is refreshed
  // - The HardwareFB interfaces with /dev/fb0, which is the linux framebuffer
  //   device. In addition to mmaping /dev/fb0, HardwareFB also sends ioctl to
  //   the FB
  // - The RemarkableFB is like the HardwareFB but specific to remarkable hardware
  class FB:
    public:
    int width=0, display_width=0, height=0, rotation=0, fd=-1
    int prev_width=-1, prev_height=-1
    int byte_size = 0, dirty = 0
    int update_marker = 1
    int waveform_mode = WAVEFORM_MODE_DU
    int update_mode = UPDATE_MODE_PARTIAL
    DITHER::MODE dither = DITHER::NONE

    RESIZE_EVENT resize


    remarkable_color* fbmem
    FBRect dirty_area = {0}

    FB():
      pass

    virtual void init():
      w, h := self.get_virtual_size()
      self.width = w

      dw, dh := self.get_display_size()
      self.display_width = dw
      self.height = dh

      if DEBUG_FB_INFO:
        fprintf(stderr, "W: %i H: %i S: %i\n", display_width, height, width)
      size := width*(height)*sizeof(remarkable_color)
      self.byte_size = size
      reset_dirty(dirty_area)

      return

    FB(const FB &copy):
      fprintf(stderr, "COPY CONSTRUCTOR CALLED\n")
      throw

    virtual ~FB():
      if self.fd != -1:
        close(self.fd)

    virtual void cleanup():
      debug "CLEANING UP FB"

    virtual void wait_for_redraw(uint32_t update_marker):
      return


    // function: clear_screen
    // blanks the framebuffer with WHITE pixels
    void clear_screen():
      self.draw_rect(0, 0, self.display_width, self.height, WHITE)

    // function: redraw_screen
    // if the framebuffer is dirty, redraws the dirty area
    // of the framebuffer.
    int redraw_screen(bool full_screen=false):
      if dirty == 0:
        return 0

      dirty = 0
      um := 0

      if dirty_area.y1 == 0 || dirty_area.x1 == 0:
        return 0

      return self.perform_redraw(full_screen)

    virtual int perform_redraw(bool):
      return 0


    inline void reset_dirty(FBRect &dirty_rect):
      dirty_rect.x0 = self.display_width
      dirty_rect.y0 = self.height
      dirty_rect.x1 = 0
      dirty_rect.y1 = 0

    inline void update_dirty(FBRect &dirty_rect, int x, y):
      self.dirty = 1
      dirty_rect.x0 = min(x, dirty_rect.x0)
      dirty_rect.y0 = min(y, dirty_rect.y0)
      dirty_rect.x0 = max(0, dirty_rect.x0)
      dirty_rect.y0 = max(0, dirty_rect.y0)
      dirty_rect.x1 = max(dirty_rect.x1, x)
      dirty_rect.y1 = max(dirty_rect.y1, y)

      // TODO: dont use DISPLAY* here
      dirty_rect.x1 = min(dirty_rect.x1, int(self.display_width)-1)
      dirty_rect.y1 = min(dirty_rect.y1, int(self.height)-1)

    def render_if_dirty():
      if self.dirty:
        self.redraw_screen()

    virtual int get_screen_depth():
      return sizeof(remarkable_color)

    virtual void set_screen_depth(int d):
      return

    virtual void set_rotation(int d):
      return

    inline void _set_pixel(remarkable_color *dst, int x, int y, remarkable_color c):
      *dst = self.dither(x, y, c);

    inline void _set_pixel(int x, int y, remarkable_color c):
      self._set_pixel(&self.fbmem[y*self.width+x], x, y, c)

    inline remarkable_color _get_pixel(int x, int y):
      return self.fbmem[y*self.width+x]

    virtual tuple<int,int> get_virtual_size():
      debug "GET VIRTUAL SIZE NOT IMPLEMENTED"
      exit(1)

    // rotation can be: 0 (normal), 1 (90), 2 (180), 3 (270)
    int get_rotation():
      return util::rotation::get()

    void check_resize():
      w,h := self.get_virtual_size()
      if self.prev_width != -1 && self.prev_height != -1:
        if w != self.prev_width || h != self.prev_height:
          ev := ResizeEvent{.w=w, .h=h,.bpp=-1}
          self.resize(ev)
      self.prev_width = w
      self.prev_height = h


    // function: get_display_size
    // get the size of the framebuffer's display
    virtual tuple<int, int> get_display_size():
      return self.display_width, self.height

    // this function actually colors in a pixel. if dithering is supplied, it
    // will try to dither the supplied color by only enabling some pixels
    inline void do_dithering(remarkable_color *ptr, int i, j, color, float dither=1.0):
      switch color:
        case GRAY:
          if (i + j) % 2 == 0:
            self._set_pixel(i, j, WHITE)
          else:
            self._set_pixel(i, j, BLACK)
          break
        case ERASER_RUBBER:
          if (i + j) % 2 == 0 || (i + j) % 3 == 0:
            self._set_pixel(i, j, WHITE)
          else:
            self._set_pixel(i, j, BLACK)
          break
        case ERASER_STYLUS:
          if ptr[i+j*self.width] != WHITE:
            if (i + j) % 2 == 0 || (i + j) % 3 == 0:
              self._set_pixel(i, j, WHITE)
          break
        default:
          if unlikely(dither != 1.0):
            if fast_rand() / float(1<<16) < dither:
              self._set_pixel(i, j, color)
          else:
              self._set_pixel(i, j, color)

    // function: draw_pixel
    // draw a pixel at the x,y position
    // of color COLOR.
    //
    // color must be one of BLACK or WHITE
    inline void draw_pixel(int x, y, color):
      self._set_pixel(x, y, color)
      update_dirty(dirty_area, x, y)

    // function: draw_rect
    // draws a rect on screen.
    //
    // Params:
    // o_x - the x offset to draw the rectangle at
    // o_y - the y offset to draw the rectangle at
    // w - the width of the rectangle
    // h - the height of the rectangle
    // color - the color of the rect, can be WHITE, BLACK, GRAY, RUBBER or ERASER
    // dither - how much dithering to apply to the pixels
    //
    // note that dithering does not work with GRAY, RUBBER or ERASER
    inline void draw_rect(int o_x, o_y, w, h, color, fill=true, float dither=1.0):
      update_dirty(dirty_area, o_x, o_y)
      update_dirty(dirty_area, o_x+w, o_y+h)

      if fill:
        _draw_rect_fast(o_x, o_y, w, h, color, dither)
      else:
        _draw_rect_fast(o_x, o_y, w, 1, color, dither)
        _draw_rect_fast(o_x, o_y+h-1, w, 1, color, dither)
        _draw_rect_fast(o_x, o_y, 1, h, color, dither)
        _draw_rect_fast(o_x+w-1, o_y, 1, h, color, dither)

    inline void _draw_rect_fast(int o_x, o_y, w, h, color, float dither=1.0):
      self.dirty = 1
      #ifdef DEBUG_FB
      fprintf(stderr, "DRAWING RECT X: %i Y: %i W: %i H: %i, COLOR: %i\n", o_x, o_y, w, h, color)
      #endif

      if o_y >= self.height || o_x >= self.width || o_y < 0 || o_x < 0:
        return

      for j 0 h:
        if j+o_y >= self.height:
          break

        for i 0 w:
          if i+o_x >= self.width:
            break

          do_dithering(self.fbmem, i+o_x, j+o_y, color, dither)

    inline remarkable_color pack_pixel(char *src, int offset):
      #ifdef RMKIT_FBINK
      r := src[offset]
      g := src[offset+1]
      b := src[offset+2]
      uint32_t out
      fbink_pack_pixel_rgba(r, g, b, 0xff, &out)
      return (remarkable_color) out
      #else
      r := src[offset]
      g := src[offset+1]
      b := src[offset+2]
      return (remarkable_color) (((r >> 3U) << 11U) | ((g >> 2U) << 5U) | (b >> 3U));
      #endif

    inline void grayscale_to_rgb32(uint8_t src, char *dst):
        uint32_t color = (src * 0x00010101);
        dst[0] = color & 0x00FF
        dst[1] = color & 0x0000FF
        dst[2] = color & 0x000000FF

    // function: draw_bitmap
    // this function draws the content of image into the framebuffer
    //
    // parameters:
    //
    // image - the image to write to the framebuffer. an image consists of a
    // buffer and a width and height
    // o_x - the x offset
    // o_y - the y offset
    // alpha - the color to treat as an alpha blend (not painted into destination)
    def draw_bitmap(image_data &image, int o_x, int o_y, int pseudo_alpha=ALPHA_BLEND, bool alpha=true):
      remarkable_color* ptr = self.fbmem
      ptr += (o_x + o_y * self.width)
      src := image.buffer

      update_dirty(dirty_area, o_x, o_y)
      update_dirty(dirty_area, o_x+image.w, o_y+image.h)

      char *src_ptr;
      char src_val[4]

      for j 0 image.h:
        if o_y + j < 0:
          src += image.w
          continue
        if o_y + j >= self.height:
          break

        for i 0 image.w:
          if o_x + i < 0:
            continue
          if o_x + i >= self.width:
            break

          if src[i] != pseudo_alpha:
            if image.channels == 4 && alpha:
              // 4th bit is alpha -- if it's 0, skip drawing
              if ((char*)src)[i*image.channels+3] != 0:
                self._set_pixel(&ptr[i], i, j, pack_pixel((char *) src, i*image.channels))
            else if image.channels >= 3:
              self._set_pixel(&ptr[i], i, j, pack_pixel((char *) src, i*image.channels))
            else if image.channels == 1:
              grayscale_to_rgb32(src[i], src_val)
              self._set_pixel(&ptr[i], i, j, pack_pixel(src_val, 0))
            else:
              self._set_pixel(&ptr[i], i, j, src[i])

        ptr += self.width
        src += image.w

    void draw_text(string text, int x, int y, image_data &image, int font_size=24):
      stbtext::render_text(text, image, font_size)
      draw_bitmap(image, x, y,WHITE)

    // function: draw_text
    // a conveniece function for drawing text to the framebuffer
    //
    // parameters:
    // x - the x offset
    // y - the y offset
    // text - the text to draw
    // fs - the font size to draw at
    void draw_text(int x, y, string text, int fs=24):
      image := stbtext::get_text_size(text, fs)

      image.buffer = (uint32_t*) malloc(sizeof(uint32_t) * image.w * image.h)
      memset(image.buffer, WHITE, sizeof(uint32_t) * image.w * image.h)
      self.draw_text(text, x, y, image, fs)

      free(image.buffer)

    void save_png():
      // save the buffer to pnm format
      fd = open("fb.pnm", O_CREAT|O_RDWR, 0755)
      lseek(fd, 0, 0)
      char c[100];
      i := sprintf(c, "P6\n%d %d\n255\n", self.display_width, self.height)
      wrote := write(fd, c, i)
      if wrote == -1:
        fprintf(stderr, "ERROR %i", errno)
      buf := (char *) calloc(sizeof(char), self.width * self.height * 4)
      memset(buf, 0, sizeof(buf))

      for y 0 self.height:
        for x 0 self.display_width:
          rgb8 := color::to_rgb8(self.fbmem[y*self.width + x])
          buf[i++] = rgb8.r
          buf[i++] = rgb8.g
          buf[i++] = rgb8.b
      buf[i] = 0

      wrote = write(fd, buf, i-1)
      if wrote == -1:
        fprintf(stderr, "ERROR %i\n", errno)
      close(fd)
      free(buf)

      if USE_RESIM:
        return

      ret := system("pnmtopng fb.pnm > fb.png 2>/dev/null")

    string get_date():
      time_t rawtime;
      struct tm * timeinfo;
      char buffer[80];

      time (&rawtime);
      timeinfo = localtime(&rawtime);

      strftime(buffer,sizeof(buffer),"%Y-%m-%d-%H_%M_%S",timeinfo);
      std::string str(buffer);

      return str

    // replace the contents of the framebuffer with the png
    void load_from_png(string filename):
      char full_path[PATH_MAX]
      int neww, newh

      if filename[0] == '/':
        sprintf(full_path, "%s", filename.c_str())
      else:
        sprintf(full_path, "%s/%s", SAVE_DIR, filename.c_str())

      int channels // an output parameter
      decoded := stbi_load(full_path, &neww, &newh, &channels, 4);
      image := image_data{(uint32_t*) decoded, (int) neww, (int) newh, 4}
      self->draw_bitmap(image,0,0,framebuffer::ALPHA_BLEND)
      free(image.buffer)

      self.waveform_mode = WAVEFORM_MODE_GC16

    void make_save_dir():
      char mkdir_cmd[100]
      sprintf(mkdir_cmd, "mkdir -p %s 2>/dev/null", SAVE_DIR)
      err := system(mkdir_cmd)

    string save_colorpng(string fname="")
      w, h := self.get_display_size()
      return self.save_colorpng(fname, 0, 0, w, h)

    string save_colorpng(string fname, int o_x,o_y,w,h):
      self.make_save_dir()
      char filename[100]
      char full_filename[100]

      datestr := self.get_date()
      datecstr := datestr.c_str()

      if fname == "":
        sprintf(filename, "%s/%s%s", SAVE_DIR, datecstr, ".png")
      else:
        memcpy(filename, fname.c_str(), fname.size())
        filename[fname.size()] = 0

      buf := vector<unsigned char>(w * h * 4+1)
      i := 0
      for y o_y h:
        for x o_x w:
          rgb8 := color::to_rgb8(self.fbmem[y*self.width + x])
          buf[i++] = rgb8.r
          buf[i++] = rgb8.g
          buf[i++] = rgb8.b
      buf[i] = 0

      debug "SAVING", filename

      stbi_write_png(filename, w, h, 3, buf.data(), w*3)
      return string(filename)

    string save_lodepng(string fname="")
      w, h := self.get_display_size()
      return self.save_lodepng(fname, 0, 0, w, h)

    string save_lodepng(string fname, int o_x,o_y,w,h):
      self.make_save_dir()
      char filename[100]
      char full_filename[100]

      datestr := self.get_date()
      datecstr := datestr.c_str()

      if fname == "":
        sprintf(filename, "%s/%s%s", SAVE_DIR, datecstr, ".png")
      else:
        memcpy(filename, fname.c_str(), fname.size())
        filename[fname.size()] = 0

      buf := vector<unsigned char>(w * h * 4+1)
      i := 0
      for y o_y h:
        for x o_x w:
          buf[i++] = self.fbmem[y*self.width + x]
      buf[i] = 0

      debug "SAVING", filename

      stbi_write_png(filename, w, h, 1, buf.data(), w)
      return string(filename)

    // Barrera4
    def draw_circle_outline(int x0, y0, radius, stroke, color):
      int x = 0;
      int y = radius;
      int d = -(radius >> 1);
      int w = stroke
      int h = stroke

      update_dirty(dirty_area, x0-radius-stroke, y0-radius-stroke)
      update_dirty(dirty_area, x0+radius+stroke, y0+radius+stroke)

      while(x <= y):
        _draw_rect_fast(x+x0, y+y0, w, h, color);
        _draw_rect_fast(-x+x0, y+y0, w, h, color);
        _draw_rect_fast(x+x0, -y+y0, w, h, color);
        _draw_rect_fast(-x+x0, -y+y0, w, h, color);
        _draw_rect_fast(y+x0, x+y0, w, h, color);
        _draw_rect_fast(-y+x0, x+y0, w, h, color);
        _draw_rect_fast(y+x0, -x+y0, w, h, color);
        _draw_rect_fast(-y+x0, -x+y0, w, h, color);

        if(d <= 0):
          x++;
          d += x;
        else:
          y--;
          d -= y;

    // bresenham's outline
    def draw_circle_outline2(int x0, y0, r, stroke, color):
      y := r
      x := 0;
      w := stroke
      h := stroke

      update_dirty(dirty_area, x0-r-stroke, y0-r-stroke)
      update_dirty(dirty_area, x0+r+stroke, y0+r+stroke)

      _draw_rect_fast(x, y, w, h, color);
      d := (3-2*(int)r);
      while (x <= y):
        if (d <= 0):
          d = d + (4*x + 6);
        else:
          d = d + 4*(x-y) + 10;
          y--;
        x++;

        _draw_rect_fast(x+x0, y+y0, w, h, color);
        _draw_rect_fast(-x+x0, y+y0, w, h, color);
        _draw_rect_fast(x+x0, -y+y0, w, h, color);
        _draw_rect_fast(-x+x0, -y+y0, w, h, color);
        _draw_rect_fast(y+x0, x+y0, w, h, color);
        _draw_rect_fast(-y+x0, x+y0, w, h, color);
        _draw_rect_fast(y+x0, -x+y0, w, h, color);

        _draw_rect_fast(-y+x0, -x+y0, w, h, color);

    def draw_circle_filled(int x0, y0, radius, stroke, color):
      update_dirty(dirty_area, x0-radius-stroke, y0-radius-stroke)
      update_dirty(dirty_area, x0+radius+stroke, y0+radius+stroke)

      for x := -radius; x <= radius; x++:
        for y := -radius; y <= radius; y++:
          if (x*x+y*y) <= radius*radius:
            _draw_rect_fast(x+x0, y+y0, stroke, stroke, color)

    // function: draw_circle
    //
    // Parameters:
    // x0 - the x origin of the circle
    // y0 - the y origin of the circle
    // r - the radius
    // stroke - the stroke size of the circle outline
    // color - the color of circle
    // fill - whether to fill the circle or not
    def draw_circle(int x0, y0, r, stroke, color, fill=false):
      if fill:
        self.draw_circle_filled(x0, y0, r, stroke, color)
      else:
        self.draw_circle_outline(x0, y0, r, stroke, color)

    def draw_line_circle(int x0,y0,x1,y1,width,color,float dither=1.0):
      #ifdef DEBUG_FB
      fprintf(stderr ,"DRAWING LINE w. CIRCLES %i %i %i %i\n", x0, y0, x1, y1)
      #endif
      self.dirty = 1
      dx :=  abs(x1-x0)
      sx := x0<x1 ? 1 : -1
      dy := -abs(y1-y0)
      sy := y0<y1 ? 1 : -1
      err := dx+dy  /* error value e_xy */
      while (true):   /* loop */
        self.draw_circle(x0, y0, width/2, 1, color,true)
        // self.fbmem[y0*self.width + x0] = color
        if (x0==x1 && y0==y1) break;
        e2 := 2*err
        if (e2 >= dy):
          err += dy /* e_xy+e_x > 0 */
          x0 += sx
        if (e2 <= dx): /* e_xy+e_y < 0 */
          err += dx
          y0 += sy

    // function: draw_line
    // draws a lne from x,0,y0 to x1,y1
    def draw_line(int x0,y0,x1,y1,width,color,float dither=1.0):
      #ifdef DEBUG_FB
      fprintf(stderr, "DRAWING LINE %i %i %i %i\n", x0, y0, x1, y1)
      #endif
      self.dirty = 1

      update_dirty(dirty_area, x0-width, y0-width)
      update_dirty(dirty_area, x0+width, y0+width)
      update_dirty(dirty_area, x1+width, y1+width)
      update_dirty(dirty_area, x1-width, y1-width)

      dx := abs(x1-x0)
      sx := x0<x1 ? 1 : -1
      dy := -abs(y1-y0)
      sy := y0<y1 ? 1 : -1
      err := dx+dy  /* error value e_xy */
      while (true):   /* loop */
        _draw_rect_fast(x0, y0, width, width, color, dither)
        // self.fbmem[y0*self.width + x0] = color
        if (x0==x1 && y0==y1) break;
        e2 := 2*err
        if (e2 >= dy):
          err += dy /* e_xy+e_x > 0 */
          x0 += sx
        if (e2 <= dx): /* e_xy+e_y < 0 */
          err += dx
          y0 += sy

    // function: draw_bezier
    // draw a bezier curve from x0,y0 to x3,y3
    // curve shape is controled by 2 points x1,y1 and x2,y2
    def draw_bezier(int x0,y0,x1,y1,x2,y2,x3,y3,width,color,float dither=1.0):
      #ifdef DEBUG_FB
      fprintf(stderr, "DRAWING BEZIER %i %i %i %i %i %i %i %i\n",
              x0, y0, x1, y1, x2, y2, x3, y3)
      #endif
      self.dirty = 1

      update_dirty(dirty_area, x0-width, y0-width)
      update_dirty(dirty_area, x0+width, y0+width)
      update_dirty(dirty_area, x3+width, y3+width)
      update_dirty(dirty_area, x3-width, y3-width)

      step := 0.001
      for t := 0.0; t <= (1.0+step); t += step:
        it := 1-t
        pointx := it*it*it*x0 + 3*t*it*it*x1 + 3*t*t*it*x2 + t*t*t*x3
        pointy := it*it*it*y0 + 3*t*it*it*y1 + 3*t*t*it*y2 + t*t*t*y3
        _draw_rect_fast(pointx, pointy, width, width, color, dither)

  class HardwareFB: public FB:
    public:
    HardwareFB(): FB():
      self.fd = open("/dev/fb0", O_RDWR)

    virtual remarkable_color* allocate_memory(int byte_size):
      debug "ALLOCATING MEMORY FROM HW FB"
      return (remarkable_color*) mmap(NULL, self.byte_size, PROT_WRITE, MAP_SHARED, self.fd, 0)

    void init():
      FB::init()
      self.fbmem = self.allocate_memory(self.byte_size)

      fb_var_screeninfo vinfo;
      if (ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)):
        fprintf(stderr, "Could not get screen vinfo for %s\n", "/dev/fb0")
        return

      if DEBUG_FB_INFO:
        debug "XRES", vinfo.xres, "YRES", vinfo.yres, "BPP", vinfo.bits_per_pixel, "GRAYSCALE", vinfo.grayscale

    void wait_for_redraw(uint32_t update_marker):
      mxcfb_update_marker_data mdata = { update_marker, 0 }
      ioctl(self.fd, MXCFB_WAIT_FOR_UPDATE_COMPLETE, &mdata)

    tuple<int, int> get_display_size():
      fb_var_screeninfo vinfo;
      ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)

      return vinfo.xres, vinfo.yres

    int perform_redraw(bool full_screen=false):
      um := 0
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
        update_rect.width = self.display_width
        update_rect.height = self.height

      update_data.update_marker = 0
      update_data.update_region = update_rect
      update_data.waveform_mode = self.waveform_mode
      update_data.update_mode = self.update_mode
      update_data.dither_mode = EPDC_FLAG_EXP1
      update_data.temp = TEMP_USE_REMARKABLE_DRAW
      update_data.flags = 0
      self.waveform_mode = WAVEFORM_MODE_DU
      self.update_mode = UPDATE_MODE_PARTIAL

      if update_rect.height == 0 || update_rect.width == 0:
        return um

      ioctl(self.fd, MXCFB_SEND_UPDATE, &update_data)
      um = update_data.update_marker

      reset_dirty(self.dirty_area)
      return um

  class FileFB: public FB:
    public:
    string filename
    FileFB(string fname="fb.raw", int w=0, h=0): FB():
      self.filename = fname
      if w != 0 and h != 0:
        self.display_width = w
        self.width = w
        self.height = h
      self.byte_size = self.display_width * self.height * sizeof(remarkable_color)
      // make an empty file of the right size

      exists := file_exists(filename)
      reset := !exists
      if not exists:
        std::ofstream ofs(filename, std::ios::binary | std::ios::out);
        ofs.seekp(self.byte_size);
        ofs.write("", 1);
        ofs.close()
      else:
        fd := open(filename.c_str(), O_RDWR)
        file_bytes := lseek(fd, 0, SEEK_END)
        close(fd)

        if file_bytes != self.byte_size:
          debug "FOUND WRONG BYTE SIZE, NEED TO RESIZE", file_bytes, self.byte_size
          reset = true
          truncate(filename.c_str(), self.byte_size)

      self.fd = open(filename.c_str(), O_RDWR)
      self.fbmem = (remarkable_color*) mmap(NULL, self.byte_size, PROT_WRITE, MAP_SHARED, self.fd, 0)

      if reset:
        memset(self.fbmem, WHITE, self.byte_size)

    virtual ~FileFB():
      msync(self.fbmem, self.byte_size, MS_ASYNC)
      munmap(self.fbmem, self.byte_size)

    virtual tuple<int,int> get_virtual_size():
      return self.width, self.height

    int perform_redraw(bool):
      #ifndef PERF_BUILD
      msync(self.fbmem, self.byte_size, MS_SYNC)
      self.save_png()
      #endif
      return 0

  class VirtualFB: public FB:
    public:
    VirtualFB(int w, h): FB():
      self.display_width = w
      self.width = w
      self.height = h
      self.byte_size = self.width * self.height * sizeof(remarkable_color)
      self.fbmem = (remarkable_color*) malloc(self.byte_size)
      self.fd = -1

    virtual tuple<int,int> get_virtual_size():
      return self.width, self.height

    ~VirtualFB():
      if self.fbmem != NULL:
        free(self.fbmem)
      self.fbmem = NULL

  class RemarkableFB: public HardwareFB:
    public:
    int o_depth
    int o_grayscale
    RemarkableFB():
      // if we are using remarkable, then we set it to grayscale
      fb_var_screeninfo vinfo;
      if (ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)):
        fprintf(stderr, "Could not get screen vinfo for %s\n", "/dev/fb0")
        exit(0)

      o_depth = vinfo.bits_per_pixel
      o_grayscale = vinfo.grayscale

      #ifndef FB_NO_INIT_BPP
      set_screen_depth(sizeof(remarkable_color)*8)
      #endif

      #ifdef REMARKABLE
      uint32_t auto_update_mode = AUTO_UPDATE_MODE_AUTOMATIC_MODE
      ioctl(self.fd, MXCFB_SET_AUTO_UPDATE_MODE, (pointer_size) &auto_update_mode);
      #endif

    tuple<int, int> get_virtual_size():
      fb_var_screeninfo vinfo;
      if (ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)):
        fprintf(stderr, "Could not get screen vinfo for %s\n", "/dev/fb0")
        exit(0)

      return vinfo.xres_virtual, vinfo.yres

    int get_screen_depth():
      fb_var_screeninfo vinfo;
      if (ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)):
        fprintf(stderr, "Could not get screen vinfo for %s\n", "/dev/fb0")
        exit(0)

      return vinfo.bits_per_pixel

    void set_rotation(int r):
      fb_var_screeninfo vinfo;
      if (ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)):
        fprintf(stderr, "Could not get screen vinfo for %s\n", "/dev/fb0")
        exit(0)

      vinfo.rotate = r
      retval := ioctl(self.fd, FBIOPUT_VSCREENINFO, &vinfo);

    void set_screen_depth(int d):
      fb_var_screeninfo vinfo;
      if (ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)):
        fprintf(stderr, "Could not get screen vinfo for %s\n", "/dev/fb0")
        exit(0)

      debug "SETTING SCREEN DEPTH", d

      switch d:
        case 8:
          vinfo.bits_per_pixel = 8;
          vinfo.grayscale = 1
          break
        case 16:
          vinfo.bits_per_pixel = 16;
          vinfo.grayscale = 0;
          break
        case 32:
          vinfo.bits_per_pixel = 32;
          vinfo.grayscale = 0;
          break
        default:
          debug "UNKNOWN BIT DEPTH", d
          break

      retval := ioctl(self.fd, FBIOPUT_VSCREENINFO, &vinfo);

    void cleanup():
      debug "CLEANING UP FB"

      fb_var_screeninfo vinfo;
      if (ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)):
        fprintf(stderr, "Could not get screen vinfo for %s\n", "/dev/fb0")
        exit(0)

      vinfo.bits_per_pixel = o_depth;
      vinfo.grayscale = o_grayscale
      retval := ioctl(self.fd, FBIOPUT_VSCREENINFO, &vinfo);

  class KoboFB: public RemarkableFB:
    public:
    KoboFB(): RemarkableFB()
      pass

#ifdef RMKIT_FBINK
  class FBInk: public HardwareFB:
    public:
    FBInkConfig config_ = {0}
    FBInkState state_ = {0}
    FBInk():
      self.fd = fbink_open()
      fbink_init(self.fd, &config_)

    void init():
      FB::init()
      self.fbmem = self.allocate_memory(self.byte_size)

      #ifndef FB_NO_INIT_BPP
      set_screen_depth(sizeof(remarkable_color)*8)
      #endif

    remarkable_color* allocate_memory(int):
      size_t size
      mem := (remarkable_color*) fbink_get_fb_pointer(self.fd, &size)
      return mem

    int perform_redraw(bool full_screen=false):
      config_.wfm_mode = self.waveform_mode
      if !full_screen:
        fbink_refresh(self.fd,
          dirty_area.y0,
          dirty_area.x0,
          std::min(dirty_area.x1 - dirty_area.x0, self.display_width-1),
          std::min(dirty_area.y1 - dirty_area.y0, self.height-1),
          &config_)
      else:
        fbink_refresh(self.fd, 0, 0, self.display_width, self.height, &config_)
      return 0

    void wait_for_redraw(uint32_t update_marker):
      fbink_wait_for_complete(self.fd, update_marker);

    tuple<int, int> get_display_size():
      fbink_get_state(&config_, &state_)
      return state_.view_width, state_.view_height

    tuple<int, int> get_virtual_size():
      fbink_get_state(&config_, &state_)
      return ((state_.scanline_stride << 3U) / state_.bpp), state_.screen_height

    int get_screen_depth():
      fbink_get_state(&config_, &state_)
      return state_.bpp

    void set_screen_depth(int d):
      debug "SETTING SCREEN DEPTH", d
      fbink_get_state(&config_, &state_)
      ret := fbink_set_fb_info(self.fd, state_.current_rota, d, true, &config_);
#endif

  class MtkFB: public RemarkableFB:
    public:

    void init():
      FB::init()
      self.fbmem = (remarkable_color*) mmap(NULL, self.byte_size, PROT_WRITE, MAP_SHARED, self.fd, 0)

      fb_var_screeninfo vinfo;
      if (ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)):
        fprintf(stderr, "Could not get screen vinfo for %s\n", "/dev/fb0")
        return

      if DEBUG_FB_INFO:
        debug "XRES", vinfo.xres, "YRES", vinfo.yres, "BPP", vinfo.bits_per_pixel, "GRAYSCALE", vinfo.grayscale

    void wait_for_redraw(uint32_t update_marker):
      hwtcon_update_marker_data mdata = { update_marker, 0 }
      ioctl(self.fd, HWTCON_WAIT_FOR_UPDATE_COMPLETE, &mdata)

    tuple<int, int> get_display_size():
      fb_var_screeninfo vinfo;
      ioctl(self.fd, FBIOGET_VSCREENINFO, &vinfo)

      return vinfo.xres, vinfo.yres

    int perform_redraw(bool full_screen=false):
      um := 0
      hwtcon_update_data update_data
      hwtcon_rect update_rect

      if !full_screen:
        update_rect.top = dirty_area.y0
        update_rect.left = dirty_area.x0
        update_rect.width = dirty_area.x1 - dirty_area.x0
        update_rect.height = dirty_area.y1 - dirty_area.y0
      else:
        update_rect.top = 0
        update_rect.left = 0
        update_rect.width = self.display_width
        update_rect.height = self.height

      update_data.update_marker = 0
      update_data.update_region = update_rect
      update_data.waveform_mode = self.waveform_mode
      update_data.update_mode = self.update_mode
      update_data.dither_mode = 0
      update_data.flags = 0
      self.waveform_mode = WAVEFORM_MODE_DU
      self.update_mode = UPDATE_MODE_PARTIAL

      if update_rect.height == 0 || update_rect.width == 0:
        return um

      ioctl(self.fd, HWTCON_SEND_UPDATE, &update_data)
      um = update_data.update_marker

      reset_dirty(self.dirty_area)
      return um


  extern shared_ptr<FB> _FB = nullptr

  // function: framebuffer::get
  // this function returns the app's framebuffer
  //
  // NOTE: the framebuffer is a singleton
  static shared_ptr<FB> get():
    if _FB != nullptr && _FB.get() != nullptr:
      return _FB

    #ifdef RMKIT_FBINK
    _FB = make_shared<framebuffer::FBInk>()
    #elif REMARKABLE
    _FB = make_shared<framebuffer::RemarkableFB>()
    #elif KOBO
    if util::get_kobo_version() == util::KOBO_DEVICE_ID_E::DEVICE_KOBO_ELIPSA_2E:
      _FB = make_shared<framebuffer::MtkFB>()
    else:
      _FB = make_shared<framebuffer::KoboFB>()
    #elif DEV
    _FB = make_shared<framebuffer::FileFB>("fb.raw", DISPLAYWIDTH, DISPLAYHEIGHT)
    #else
    _FB = make_shared<framebuffer::HardwareFB>()
    #endif


    _FB->init()

    fb_info::display_width = _FB->display_width
    fb_info::display_height = _FB->height
    fb_info::width = _FB->width
    fb_info::height = _FB->height

    return _FB
