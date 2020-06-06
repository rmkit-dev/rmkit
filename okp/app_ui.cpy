import ui

class ToolButton: public Button:
  public:
  Canvas *canvas
  vector<string> tools = { "simple", "sketchy", "chrome" }
  int tool = 0
  ToolButton(int x, y, w, h, Canvas *c): Button(x,y,w,h,"tool"):
    self.canvas = c
    self.text = tools[tool]
    self.dirty = 1

  void on_mouse_click(SynEvent):
    printf("TOOL CLICKED\n")
    tool++
    tool %= tools.size()
    self.text = tools[tool]

class UndoButton: public Button:
  public:
  Canvas *canvas
  UndoButton(int x, y, w, h, Canvas *c): Button(x,y,w,h,"undo"):
    self.canvas = c

  void on_mouse_click(SynEvent ev):
    self.dirty = 1
    self.canvas->undo()

class RedoButton: public Button:
  public:
  Canvas *canvas
  RedoButton(int x, y, w, h, Canvas *c): Button(x,y,w,h,"redo"):
    self.canvas = c

  void on_mouse_click(SynEvent ev):
    self.dirty = 1
    self.canvas->redo()

