#include "state.h"
#include "brush.h"
#include "../../shared/snapshot.h"

#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>

#ifdef REMARKABLE
#define UNDO_STACK_SIZE 10
#else
#define UNDO_STACK_SIZE 100
#endif


bool path_exists(const std::string &s):
  struct stat buffer;
  return (stat (s.c_str(), &buffer) == 0);

#define LAYER_DIR SAVE_DIR "/current"
#define UNTITLED "Untitled"
namespace app_ui:

  class Layer:
    public:
    bool visible = true
    int byte_size = 0
    int w, h
    string name = ""
    shared_ptr<framebuffer::FileFB> fb
    shared_ptr<framebuffer::Snapshot> snapshot
    bool dirty = 0

    Layer(int _w, _h, shared_ptr<framebuffer::FileFB> _fb, int _byte_size, bool _visible):
      w = _w
      h = _h
      fb = _fb
      byte_size = _byte_size
      visible = _visible
      char repr[100]
      sprintf(repr, "%p", this)
      name = repr

    string get_name():
      return name

    void set_name(string n):
      name = n

  class LayerState: public Layer:
    public:
    string filename

    LayerState(const Layer &layer): Layer(layer)
      fb = NULL
      filename = layer.fb->filename

  struct SaveState:
    vector<LayerState> layers
    int cur_layer
    string project_name
  ;


  class Canvas: public ui::Widget:
    public:
    remarkable_color *mem
    int byte_size
    int stroke_width = 1
    remarkable_color stroke_color = BLACK
    int page_idx = 0
    string project_name = UNTITLED

    bool erasing = false
    bool full_redraw = false

    shared_ptr<framebuffer::VirtualFB> vfb

    deque<SaveState> undo_stack;
    deque<SaveState> redo_stack;

    vector<Layer> layers
    int cur_layer = 0

    Brush* curr_brush
    Brush* eraser

    Canvas(int x, y, w, h): ui::Widget(x,y,w,h):
      STATE.brush(PLS_DELEGATE(self.set_brush))
      STATE.color(PLS_DELEGATE(self.set_stroke_color))
      STATE.stroke_width(PLS_DELEGATE(self.set_stroke_width))

      px_width, px_height = self.fb->get_display_size()
      self.byte_size = px_width * px_height * sizeof(remarkable_color)

      fb->dither = framebuffer::DITHER::BAYER_2
      self.load_vfb()

      self.eraser = brush::ERASER
      self.set_brush(brush::ERASER)
      self.eraser->set_stroke_width(stroke::Size::MEDIUM)

      self.set_brush(brush::PENCIL)

      if path_exists(LAYER_DIR):
        self.load_project_from_dir(LAYER_DIR)
      else:
        reset_layer_dir()
        self.select_layer(self.new_layer())

    ~Canvas():
      pass

    void set_stroke_width(int s):
      self.stroke_width = s
      self.curr_brush->set_stroke_width(s)

    void sanitize_filename(string &name):
      for i := 0; i < name.length(); i++:
        if name[i] == '/' or name[i] == ':':
          name[i] = '_'

    auto get_stroke_width():
      return self.curr_brush->stroke_val

    void set_stroke_color(int color):
      self.stroke_color = color
      self.curr_brush->color = color

    auto get_stroke_color():
      return self.curr_brush->color

    void reset():
      memset(self.fb->fbmem, WHITE, self.byte_size)
      memset(vfb->fbmem, WHITE, self.byte_size)

      // delete layers pushes an undo state onto the stack
      self.delete_layers()
      self.layers.clear()
      reset_layer_dir()
      self.select_layer(self.new_layer())
      self.project_name = UNTITLED

      self.curr_brush->reset()
      mark_redraw()

    void set_brush(Brush* brush):
      self.curr_brush = brush
      brush->reset()
      brush->color = self.stroke_color
      brush->set_stroke_width(self.stroke_width)

      if cur_layer < self.layers.size():
        brush->set_framebuffer(self.layers[cur_layer].fb.get())

    void update_eraser():
      eraser->reset()

      if cur_layer < self.layers.size():
        eraser->set_framebuffer(self.layers[cur_layer].fb.get())

    bool ignore_event(input::SynMotionEvent &ev):
      if not ui::MainLoop::in.has_stylus:
        ev.pressure = 0.5
        ev.tilt_x = 0.5
        ev.tilt_y = 0.5
        return false

      return input::is_touch_event(ev) != NULL


    void on_mouse_move(input::SynMotionEvent &ev):
      if not self.layers[cur_layer].visible:
        return
      brush := self.erasing ? self.eraser : self.curr_brush
      brush->stroke(ev.x, ev.y, ev.tilt_x, ev.tilt_y, ev.pressure)
      brush->update_last_pos(ev.x, ev.y, ev.tilt_x, ev.tilt_y, ev.pressure)
      self.dirty = 1

    void on_mouse_up(input::SynMotionEvent &ev):
      brush := self.erasing ? self.eraser : self.curr_brush
      brush->stroke_end()
      brush->update_last_pos(-1,-1,-1,-1,-1)

      // we invalidate the layer snapshot after modifying the layer
      // so the save system knows about it
      self.layers[self.cur_layer].snapshot = NULL
      self.push_undo()
      self.dirty = 1
      ui::MainLoop::refresh()

    void on_mouse_hover(input::SynMotionEvent &ev):
      pass

    void on_mouse_down(input::SynMotionEvent &ev):
      self.erasing = ev.eraser && ev.eraser != -1
      brush := self.erasing ? self.eraser : self.curr_brush
      if self.erasing:
        self.update_eraser()
      brush->stroke_start(ev.x, ev.y,ev.tilt_x, ev.tilt_y, ev.pressure)

    void mark_redraw():
      if !self.dirty:
        self.dirty = 1
        ui::MainLoop::full_refresh()

      self.full_redraw = true
      px_width, px_height = self.fb->get_display_size()
      vfb->dirty_area = {0, 0, px_width, px_height}
      if cur_layer >= 0 and cur_layer < layers.size():
        layers[cur_layer].fb->dirty_area = {0, 0, px_width, px_height}

    void render():
      render_layers(self.vfb)

      dirty_rect := self.vfb->dirty_area
      for int i = dirty_rect.y0; i < dirty_rect.y1; i++:
        memcpy(&fb->fbmem[i*fb->width + dirty_rect.x0], &vfb->fbmem[i*fb->width + dirty_rect.x0],
          (dirty_rect.x1 - dirty_rect.x0) * sizeof(remarkable_color))

      self.fb->dirty_area = vfb->dirty_area
      self.fb->dirty = 1
      vfb->reset_dirty(vfb->dirty_area)

      for i := 0; i < layers.size(); i++:
        layers[i].fb->reset_dirty(layers[i].fb->dirty_area)

    // {{{ SAVING / LOADING
    void set_project_name(string n):
      self.project_name = n
      sanitize_filename(self.project_name)

    string save_png():
      sanitize_filename(self.project_name)
      char filename[PATH_MAX]
      datestr := self.vfb->get_date()
      datecstr := datestr.c_str()
      sprintf(filename, "%s/%s-%s%s", SAVE_DIR,
        self.project_name.c_str(), datecstr, ".png")

      // render layers
      sfb := make_shared<framebuffer::VirtualFB>(self.fb->width, self.fb->height)
      sfb->draw_rect(0, 0, self.vfb->width, self.vfb->height, WHITE)

      self.render_layers(sfb)


      return sfb->save_lodepng(filename, 0, 0, w, h)

    string save_layer():
      sfb := framebuffer::VirtualFB(self.w, self.h)
      &layer := layers[cur_layer]

      // set base of sfb to white
      remarkable_color c
      remarkable_color tr = TRANSPARENT
      for int i = 0; i < self.h; i++:
        for int j = 0; j < self.w; j++:
          c = layer.fb->_get_pixel(j, i)
          if c != tr:
            sfb._set_pixel(j, i, c)
          else
            sfb._set_pixel(j, i, WHITE)

      sanitize_filename(layer.name)
      char filename[PATH_MAX]
      datestr := self.vfb->get_date()
      datecstr := datestr.c_str()
      sprintf(filename, "%s/%s-%s%s", SAVE_DIR,
        layer.name.c_str(), datecstr, ".png")
      return sfb.save_lodepng(filename, 0, 0, self.w, self.h)

    void load_from_png(string filename):
      self.select_layer(self.new_layer())
      self.layers[cur_layer].fb->load_from_png(filename)
      &layer := self.layers[cur_layer]
      for int i = 0; i < self.h; i++:
        for int j = 0; j < self.w; j++:
          if layer.fb->_get_pixel(j, i) == WHITE:
            layer.fb->_set_pixel(j, i, TRANSPARENT)

      mark_redraw()

    void load_vfb():
      if self.vfb != nullptr:
        msync(self.vfb->fbmem, self.byte_size, MS_SYNC)

      self.vfb = make_shared<framebuffer::VirtualFB>(self.fb->width, self.fb->height)
      self.vfb->dither = framebuffer::DITHER::BAYER_2
      self.vfb->draw_rect(0, 0, self.vfb->width, self.vfb->height, WHITE)

      memcpy(fb->fbmem, vfb->fbmem, self.byte_size)

      ui::MainLoop::refresh()

    void run_command(string cmd, vector<string> args):
      char *c_args[args.size()+2]
      c_args[0] = (char*) cmd.c_str()
      for i := 0; i < args.size(); i++:
        c_args[i+1] = (char*) args[i].c_str()

      c_args[args.size()+1] = NULL

      pid := fork()
      if pid == 0:
        if execvp(cmd.c_str(), c_args) == -1:
          debug "ERR", strerror(errno)
      else if pid == -1:
        debug "ERR", strerror(errno)
      else:
        wait(NULL)

    void reset_layer_dir():
      run_command("rm", {"-rf", LAYER_DIR})
      run_command("mkdir", {LAYER_DIR})

    void delete_layers():
      for int i = 0; i < layers.size(); i++:
        self.delete_layer(i, true /* allow empty */, false /* undoable */)


    void load_project(string filename):
      reset_layer_dir()
      self.delete_layers()
      self.layers.clear()

      run_command("tar", {"-xvzf", filename, "-C", LAYER_DIR})
      load_project_from_dir(LAYER_DIR)

      // set the project name to the filename minus the '.hrm' extension
      dir_tokens := str_utils::split(filename, '/')
      last_token := dir_tokens[dir_tokens.size()-1]
      file_tokens := str_utils::split(last_token, '.')
      self.project_name = file_tokens[0]

    void load_project_from_dir(string dir):
      filenames := util::lsdir(dir, ".raw")
      sort(filenames.begin(), filenames.end()) // do we really need to sort?

      for auto f : filenames:
        tokens := str_utils::split(f, '.')
        string name = unique_name("Layer")
        if tokens.size() == 4:
          name = unique_name(tokens[2], false)

        Layer layer(
          self.w, self.h,
          make_shared<framebuffer::FileFB>(string(dir) + "/" + f,
            self.fb->width, self.fb->height),
          self.byte_size,
          true)

        layer.name = name
        layer.fb->dirty_area = {0, 0, self.fb->width, self.fb->height}
        self.layers.push_back(layer)


      if layers.size() == 0:
        self.select_layer(self.new_layer())

      self.select_layer(layers.size() - 1)
      self.push_undo()
      self.mark_redraw()


    // we tack on ".[timestamp].hrm" to the filename
    void save_project(bool overwrite=false):
      sanitize_filename(self.project_name)
      debug "SAVING PROJECT", self.project_name
      out_file := "tmp.hrm"
      out_dir := string(SAVE_DIR) + "/tmp/"

      run_command("mkdir", { out_dir })
      for auto layer : self.layers:
        run_command("cp", { layer.fb->filename, out_dir })

      char curdir[PATH_MAX]
      _ := getcwd(curdir, PATH_MAX)
      if chdir(out_dir.c_str()) == -1:
        debug "ERR CHANGING DIRECTORIES", strerror(errno), out_dir
        return

      filenames := util::lsdir(".", ".raw")
      tar_args := vector<string>{"-cvzf", out_file}
      for i := 0; i < filenames.size(); i++:
        tar_args.push_back(filenames[i].c_str())
      run_command("tar", tar_args)

      datestr := self.vfb->get_date()
      datecstr := datestr.c_str()
      char filename[PATH_MAX]
      sprintf(filename, "../%s.%s.hrm", self.project_name.c_str(), datecstr)
      run_command("mv", {out_file, filename})
      __ := chdir(curdir)
      run_command("rm", {out_dir, "-rf"})

      pf := string(filename)
      pf = pf.substr(3, pf.length())
      debug "SAVED PROJECT AS", pf

    // }}}

    // {{{ UNDO / REDO STUFF
    void trim_stacks():
      while UNDO_STACK_SIZE > 0 && self.undo_stack.size() > UNDO_STACK_SIZE:
        self.undo_stack.pop_front()
      while UNDO_STACK_SIZE > 0 && self.redo_stack.size() > UNDO_STACK_SIZE:
        self.redo_stack.pop_front()

    void clear_undo():
      self.undo_stack.clear()
      self.redo_stack.clear()

    // need to go through each layer and save its snapshot
    void push_undo():
      if STATE.disable_history:
        return

      dirty_rect := self.fb->dirty_area
      debug "ADDING TO UNDO STACK, DIRTY AREA IS", \
        dirty_rect.x0, dirty_rect.y0, dirty_rect.x1, dirty_rect.y1


      ui::TaskQueue::add_task([&] {
        SaveState ss = {}
        ss.cur_layer = self.cur_layer
        ss.project_name = self.project_name
        for auto &layer : layers:
          if layer.snapshot == NULL:
            layer.snapshot = make_shared<framebuffer::Snapshot>(w, h)
            debug "COMPRESSING LAYER", layer.name, layer.fb->fbmem
            layer.snapshot->compress(layer.fb->fbmem, self.byte_size)

          LayerState ls(layer)
          ss.layers.push_back(ls)

        self.undo_stack.push_back(ss)
        self.redo_stack.clear()
        self.trim_stacks()
      })

    void restore_layers(SaveState &undofb):
      layers_modified := false

      if layers.size() != undofb.layers.size():
        layers_modified = true
      else:
        // this only verifies that the same layers exist and are in the same
        // order. TODO: smarter decisions here
        for i := 0; i < layers.size(); i++:
          &layer := layers[i]
          &sl := undofb.layers[i]
          if layer.name != sl.name:
            layers_modified = true
            break

      if layers_modified:
        self.delete_layers()
        self.layers.clear()
        debug "RESETTING LAYERS"
      else:
        debug "RE-USING LAYERS"

      for i := 0; i < undofb.layers.size(); i++:
        &sl := undofb.layers[i]

        if layers_modified:
          Layer layer(sl)
          layer.fb = make_shared<framebuffer::FileFB>(sl.filename, sl.w, sl.h)
          sl.snapshot->decompress(layer.fb->fbmem)
          self.layers.push_back(layer)
        else:
          &layer := self.layers[i]
          sl.snapshot->decompress(layer.fb->fbmem)

      self.select_layer(undofb.cur_layer)
      self.project_name = undofb.project_name

    void undo():
      if self.undo_stack.size() > 1:
        // put last fb from undo stack into fb
        self.redo_stack.push_back(self.undo_stack.back())
        self.undo_stack.pop_back()
        undofb := self.undo_stack.back()

        restore_layers(undofb)
        ui::MainLoop::full_refresh()

    void redo():
      if self.redo_stack.size() > 0:
        redofb := self.redo_stack.back()
        self.redo_stack.pop_back()

        restore_layers(redofb)

        self.undo_stack.push_back(redofb)
        ui::MainLoop::full_refresh()
    // }}}

    // {{{ LAYER STUFF
    int get_layer_idx(string name):
      idx := 0
      for auto &l: layers:
        if l.name == name:
          return idx
        idx++
      return -1

    string unique_name(string prefix, bool initial_suffix=true):
      copy := 0
      name := prefix
      if initial_suffix:
        name = prefix + " " + to_string(copy++)

      while true:
        unique := true
        for auto &layer : self.layers:
          if layer.name == name:
            unique = false
            break

        if unique:
          break

        name = prefix + " " + to_string(copy++)

      return name

    int new_layer(bool undoable=true):
      int layer_id = layers.size()
      char filename[PATH_MAX]
      layer_name := unique_name("Layer")
      sprintf(filename, "%s/layer.%03i.%s.raw", LAYER_DIR, layer_id, layer_name.c_str())
      Layer layer(
        w, h,
        make_shared<framebuffer::FileFB>(filename, self.fb->width, self.fb->height),
        self.byte_size,
        true)
      layer.fb->dirty_area = {0, 0, self.fb->width, self.fb->height}
      layer.name = layer_name

      self.layers.push_back(layer)

      self.clear_layer(layer_id)
      if undoable:
        self.push_undo()

      return layer_id

    void delete_layer(int i, bool allow_empty=false, bool undoable=true):
      self.clear_layer(i)
      run_command("rm", { self.layers[i].fb->filename})
      layers.erase(layers.begin() + i)

      if layers.size() == 0 and !allow_empty:
        self.select_layer(self.new_layer())

      if undoable:
        self.push_undo()

      mark_redraw()

    void clear_layer(int i):
      layers[i].fb->draw_rect(0, 0, layers[i].fb->width, layers[i].fb->height, TRANSPARENT)
      mark_redraw()

    void rename_layer(int layer_id, string layer_name):
      sanitize_filename(layer_name)
      &layer := self.layers[layer_id]

      char filename[PATH_MAX]
      sprintf(filename, "%s/layer.%03i.%s.raw", LAYER_DIR, layer_id, layer_name.c_str())
      run_command("mv", { layer.fb->filename, filename})
      layer.fb->filename = filename
      layer.name = layer_name

    void toggle_layer(int i):
      layers[i].visible = !layers[i].visible
      layers[i].fb->dirty_area = {0, 0, layers[i].fb->width, layers[i].fb->height}
      mark_redraw()

    bool is_layer_visible(int i):
      return layers[i].visible

    void select_layer(string name):
      select_layer(get_layer_idx(name))

    void select_layer(int i):
      if i < 0 or i >= layers.size():
        debug "CANT SELECT LAYER:", i
        return
      cur_layer = i
      if curr_brush != NULL:
        curr_brush->set_framebuffer(self.layers[cur_layer].fb.get())
      mark_redraw()

    void swap_layers(int a, b):
      if a >= layers.size() or b >= layers.size() or a < 0 or b < 0:
        debug "LAYER INDEX IS OUT OF BOUND, CAN'T SWAP:", a, b
        return

      int mx = max(a, b)
      int mn = min(a, b)

      swapped := layers[mx]
      layers.erase(layers.begin() + mx)
      layers.insert(layers.begin() + mn, swapped)

      mark_redraw()

    // merges src onto dst, overwriting existing pixels in src
    void merge_layers(int dst, src):
      if dst >= layers.size() or src >= layers.size() or dst < 0 or src < 0:
        debug "LAYER INDEX IS OUT OF BOUND, CAN'T MERGE:", dst, src
        return

      dstfb := layers[dst].fb
      srcfb := layers[src].fb
      remarkable_color c
      remarkable_color tr = TRANSPARENT
      for int i = 0; i < srcfb->height; i++:
        for int j = 0; j < srcfb->width; j++:
          c = srcfb->_get_pixel(j, i)
          if c != tr:
            dstfb->_set_pixel(j, i, c)

      clear_layer(src)
      delete_layer(src)
      mark_redraw()

    void clone_layer(int src):
      new_layer := self.new_layer()
      dstfb := layers[new_layer].fb
      srcfb := layers[src].fb
      remarkable_color c
      remarkable_color tr = TRANSPARENT
      for int i = 0; i < srcfb->height; i++:
        for int j = 0; j < srcfb->width; j++:
          c = srcfb->_get_pixel(j, i)
          if c != tr:
            dstfb->_set_pixel(j, i, c)

    void render_layers(shared_ptr<framebuffer::VirtualFB> src = nullptr):
      if src == nullptr:
        src = self.vfb

      dr := self.layers[cur_layer].fb->dirty_area
      src->update_dirty(src->dirty_area, dr.x0, dr.y0)
      src->update_dirty(src->dirty_area, dr.x1, dr.y1)

      // set base of src to white
      for int i = dr.y0; i < dr.y1; i++:
        for int j = dr.x0; j < dr.x1; j++:
            src->_set_pixel(j, i, WHITE)

      remarkable_color c
      remarkable_color tr = TRANSPARENT
      for int l = 0; l < layers.size(); l++:
        if not layers[l].visible:
          continue

        &layer := layers[l].fb
        for int i = dr.y0; i < dr.y1; i++:
          for int j = dr.x0; j < dr.x1; j++:
            c = layer->_get_pixel(j, i)
            if c != tr:
              src->_set_pixel(j, i, c)
    // }}}

