#include "mxcfb.h"
import fb

using namespace std

def main():
  FB fb
  srand(time(NULL))

  // its the first set of bytes that determine the color?
  uint32_t color = 0x000

  printf("COLOR: %u\n", color)
  fb.draw_rect(0, 0, fb.width, fb.height, WHITE)
  fb.redraw_screen()

  rect prev_rect{0, 0, 0, 0} 
  rect cur_rect

  for i 0 10:
    cur_rect.w = 200
    cur_rect.h = 200

    cur_rect.x = rand() % (fb.width - cur_rect.w)
    cur_rect.y = rand() % (fb.height - cur_rect.h)
    
    fb.draw_rect(prev_rect, WHITE)
    fb.draw_rect(cur_rect, color)
    marker = fb.redraw_screen(true)
//    printf("WAITING FOR REDRAW: %i\n", marker)
//    fb.wait_for_redraw(marker)

    prev_rect = cur_rect
    usleep(1000000)

    color += 100
