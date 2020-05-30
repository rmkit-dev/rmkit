#ifndef INPUT_CPY
#include <fcntl.h>
#include <unistd.h>
#include <sys/select.h>

using namespace std

class Input:
  private:

  public:
  int fd, bytes
  unsigned char data[3]

  Input():
    printf("Initializing input\n")
    fd = open("/dev/input/mouse0", O_RDONLY)

  ~Input():
    close(fd)

  def listen():
    while 1:
      $bytes = read(fd, data, sizeof(data));
      if bytes > 0:
        left = data[0]&0x1
        right = data[0]&0x2
        middle = data[0]&0x4
        x = data[1]
        y = data[2]
        printf("x=%d, y=%d, left=%d, middle=%d, right=%d\n", x, y, left, middle, right)

#endif
