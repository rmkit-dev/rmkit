class App;

class ToolButton: public Button:
  public:
  App *app
  vector<string> tools = { "simple", "sketchy", "chrome" }
  int tool = 0
  ToolButton(int x, y, w, h, App *a): Button(x,y,w,h,"tool"):
    self.app = a
    self.text = tools[tool]
    self.dirty = 1

  void on_mouse_click(SynEvent):
    printf("TOOL CLICKED\n")
    tool++
    tool %= tools.size()
    self.text = tools[tool]

class UndoButton: public Button:
  public:
  App *app
  UndoButton(int x, y, w, h, App *a): Button(x,y,w,h,"undo"):
    self.app = a

  void on_mouse_click(SynEvent ev):
    self.dirty = 1

class RedoButton: public Button:
  public:
  App *app
  RedoButton(int x, y, w, h, App *a): Button(x,y,w,h,"redo"):
    self.app = a

  void on_mouse_click(SynEvent ev):
    self.dirty = 1

