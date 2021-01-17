#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <iostream>
#include "../build/rmkit.h"
#include "../vendor/json/json.hpp"
#include "../shared/string.h"

#define BUF_SIZE 1024

// TODO:
// * implement TINIT
// * implement latency calculation (while drawing?)
// * implement room counter
// * implement shared clear
// * implement undrawing when server doesn't respond within time limit

// message types
#define TINIT "init"
#define TJOIN "join"
#define TDRAW "draw"
#define TCLEAR "clear"

using json = nlohmann::json

HOST := getenv("HOST") ? getenv("HOST") : "rmkit.dev"
PORT := getenv("PORT") ? getenv("PORT") : "65432"

using PLS::Observable
class AppState:
  public:
  Observable<bool> erase
  Observable<string> room
AppState STATE

class JSONSocket:
  public:
  int sockfd
  struct addrinfo hints;
  struct addrinfo *result, *rp;
  char buf[BUF_SIZE]
  string leftover
  deque<json> out_queue
  std::mutex lock
  deque<json> in_queue
  const char* host
  const char* port
  bool _connected = false

  JSONSocket(const char* host, port):
    sockfd = socket(AF_INET, SOCK_STREAM, 0)
    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_DGRAM;
    hints.ai_flags = 0;
    hints.ai_protocol = 0;
    self.host = host
    self.port = port
    self.leftover = ""

    new thread([=]() {
      s := getaddrinfo(host, port, &hints, &result)
      if s != 0:
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(s));
        exit(EXIT_FAILURE);

      self.listen()
    })

    new thread([=]() {
      self.write_loop();
    })

  void write_loop():
    while true:
      if self.sockfd < 3:
        debug "CANT WRITE TO SOCKET"
        sleep(1)
        continue

      self.lock.lock()
      if !self._connected:
        // wait for listen() to reconnect
        self.lock.unlock()
        sleep(1)
        continue

      for (i:=0;i<self.in_queue.size();i++):
        json_dump := self.in_queue[i].dump()
        msg_c_str := json_dump.c_str()
        ::send(self.sockfd, msg_c_str, strlen(msg_c_str), MSG_DONTWAIT)
        ::send(self.sockfd, "\n", 1, MSG_DONTWAIT)
      self.in_queue.clear()
      self.lock.unlock()

  void write(json &j):
    self.lock.lock()
    self.in_queue.push_back(j);
    self.lock.unlock()

  void listen():
    bytes_read := -1
    while true:
      while bytes_read <= 0:
        err := connect(self.sockfd, self.result->ai_addr, self.result->ai_addrlen)
        if err == 0 || errno == EISCONN:
            debug "(re)connected"
            self.lock.lock()
            self._connected = true
            self.lock.unlock()
            break
        debug "(re)connecting...", err, errno
        self.lock.lock()
        close(self.sockfd)
        self._connected = false
        self.lock.unlock()
        sleep(1)

      bytes_read = read(sockfd, buf, BUF_SIZE-1)
      if bytes_read <= 0:
        if bytes_read == -1 and errno == EAGAIN:
            continue

          close(self.sockfd)
          self.sockfd = socket(AF_INET, SOCK_STREAM, 0)
          sleep(1)
          continue
      buf[bytes_read] = 0
      sbuf := string(buf)
      memset(buf, 0, BUF_SIZE)

      msgs := str_utils::split(sbuf, '\n')
      if leftover != "" && msgs.size() > 0:
        msgs[0] = leftover + msgs[0]
        leftover = ""
      if sbuf[sbuf.length()-1] != '\n':
        leftover = msgs.back()
        msgs.pop_back()
      for (i:=0; i!=msgs.size(); ++i):
        try:
            msg_json := json::parse(msgs[i].begin(), msgs[i].end())
            lock.lock()
            out_queue.push_back(msg_json)
            lock.unlock()
        catch(...):
            debug "COULDNT PARSE", msgs[i]

      ui::TaskQueue::wakeup()


class Note: public ui::Widget:
  public:
  int prevx = -1, prevy = -1
  framebuffer::VirtualFB *vfb
  bool full_redraw
  JSONSocket *socket

  Note(int x, y, w, h, JSONSocket* s): Widget(x, y, w, h):
    vfb = new framebuffer::VirtualFB(self.fb->width, self.fb->height)
    vfb->clear_screen()
    self.full_redraw = true
    self.socket = s
    self.mouse_down = false

  void on_mouse_up(input::SynMotionEvent &ev):
    prevx = prevy = -1

  bool ignore_event(input::SynMotionEvent &ev):
    return input::is_touch_event(ev) != NULL

  void on_mouse_move(input::SynMotionEvent &ev):
    width := STATE.erase ? 20 : 5
    if prevx != -1:
      vfb->draw_line(prevx, prevy, ev.x, ev.y, width, GRAY)
      self.dirty = 1

      json j
      j["type"] = TDRAW
      j["prevx"] = prevx
      j["prevy"] = prevy
      j["x"] = ev.x
      j["y"] = ev.y
      j["width"] = width
      j["color"] = STATE.erase ? WHITE : BLACK

      self.socket->write(j)

    prevx = ev.x
    prevy = ev.y

  void render():
    if self.full_redraw:
      self.full_redraw = false
      memcpy(self.fb->fbmem, vfb->fbmem, vfb->byte_size)
      return

    dirty_rect := self.vfb->dirty_area
    for int i = dirty_rect.y0; i < dirty_rect.y1; i++:
      memcpy(&fb->fbmem[i*fb->width + dirty_rect.x0], &vfb->fbmem[i*fb->width + dirty_rect.x0],
        (dirty_rect.x1 - dirty_rect.x0) * sizeof(remarkable_color))
    self.fb->dirty_area = vfb->dirty_area
    self.fb->dirty = 1
    framebuffer::reset_dirty(vfb->dirty_area)


class EraseButton: public ui::Button:
  public:
  EraseButton(int x, y, w, h): Button(x, y, w, h, "erase"):
    pass

  void on_mouse_down(input::SynMotionEvent &ev):
    STATE.erase = !STATE.erase
    debug "SETTING ERASER TO", STATE.erase
    self.dirty = 1
    if STATE.erase:
      self.text = "pen"
    else:
      self.text = "eraser"

class RoomInput: public ui::TextInput:
  public:

  RoomInput(int x, y, w, h, JSONSocket *sock): TextInput(x, y, w, h, "default"):
    self->events.done += PLS_LAMBDA(string &s):
      self.join(s)
    ;

  void join(string room):
    debug "SETTING ROOM TO", room
    STATE.room = room


class App:
  public:
  Note *note
  JSONSocket *socket
  ui::HorizontalLayout *button_bar

  App():
    demo_scene := ui::make_scene()
    ui::MainLoop::set_scene(demo_scene)

    fb := framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()
    w, h = fb->get_display_size()

    socket = new JSONSocket(HOST, PORT)
    note = new Note(0, 0, w, h-50, socket)
    demo_scene->add(note)

    button_bar = new ui::HorizontalLayout(0, 0, w, 50, demo_scene)
    hbar := new ui::VerticalLayout(0, 0, w, h, demo_scene)
    hbar->pack_end(button_bar)

    erase_button := new EraseButton(0, 0, 200, 50)
    room_label := new ui::Text(0, 0, 200, 50, "room: ")
    room_label->style->justify = ui::TextStyle::JUSTIFY::RIGHT
    room_button := new RoomInput(0, 0, 200, 50, socket)

    button_bar->pack_start(erase_button)
    button_bar->pack_end(room_button)
    button_bar->pack_end(room_label)

    STATE.room(PLS_DELEGATE(self.join_room))
    room_button->join("default")


  void join_room(string room):
    // we are not connected to socket just yet
    json j
    j["type"] = TJOIN
    j["room"] = room
    socket->write(j)
    // hit URL for downloading room image
    url := "http://rmkit.dev:65431/room/" + room
    room_file := "/tmp/room_" + room
    curl_cmd := "curl " + url  + " > " + room_file
    ret := system(curl_cmd.c_str())

    if ret != 0:
        debug "ERROR WITH CURL?"
    else:
        debug "DISPLAYING IMAGE"
        self.note->vfb->load_from_png(room_file)
        ui::MainLoop::full_refresh()

  def handle_key_event(input::SynKeyEvent ev):
    // pressing any button will clear the screen
    if ev.key == KEY_LEFT:
      debug "CLEARING SCREEN"
      note->vfb->clear_screen()
      ui::MainLoop::fb->clear_screen()
      button_bar->refresh()

  def handle_server_response():
    socket->lock.lock()
    for (i:=0; i < socket->out_queue.size(); i++):
      j := socket->out_queue[i]
      try:
        if j["type"] == TDRAW:
          note->vfb->draw_line(j["prevx"], j["prevy"], j["x"], j["y"], j["width"], j["color"])
          note->dirty = 1
          button_bar->refresh()
        else if j["type"] == TCLEAR:
          // TODO
          pass
        else:
          debug "unknown message type"
      catch(...):
        debug "COULDN'T PARSE RESPONSE FROM SERVER", j
    socket->out_queue.clear()
    socket->lock.unlock()

  def run():
    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)

    while true:
      self.handle_server_response()
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()

app := App()
int main():
  app.run()
