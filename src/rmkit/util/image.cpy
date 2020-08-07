#include "../../vendor/stb/image_resize.h"
#include "../../vendor/lodepng/lodepng.h"

namespace util:
  resize_image(image_data &im, int new_w, new_h):
    num_channels := 1
    resize_len := new_w*new_h*sizeof(unsigned char)*num_channels
    resize_buffer := (unsigned char*)malloc(resize_len)
    memset(resize_buffer, 0, resize_len);
    err := stbir_resize_uint8((unsigned char*) im.buffer, im.w, im.h, 0,
                       resize_buffer, new_w, new_h, 0, num_channels)

    for (int i=0; i< resize_len; i++):
      if resize_buffer[i] != 255:
        resize_buffer[i] = 0

    unsigned char* rgba_buf = (unsigned char*)malloc(4*resize_len)
    j := 0
    for (int i=0; i< resize_len; i++):
      rgba_buf[j++] = resize_buffer[i]
      rgba_buf[j++] = resize_buffer[i]
      rgba_buf[j++] = resize_buffer[i]
      rgba_buf[j++] = resize_buffer[i]

    im.w = new_w
    im.h = new_h
    im.buffer = (uint32_t*) rgba_buf

    return true
