# rmkit

rmkit is a framework for building remarkable apps in C++ or
[okp](https://github.com/raisjn/okp). rmkit provides widgets, layout helpers,
input handling and other features to get you started with writing your own
apps.

## How is it different?

Many apps for the remarkable that I've seen have been written using QTCreator
and the QT5 framework. This requires installing and setting up QTCreator to
build for the remarkable - an extra step in the toolchain.

rmkit is a single header file with its dependencies included and compiles with
standard g++.

## The Basics

### MainLoop

Every app usually has a main loop. rmkit's main loop is managed with the
ui::MainLoop class. In general, an app should look like the following:

```cpp
// build widgets and place them in scenes
my_scene = build_scene() // we'll talk about scenes later
ui::MainLoop::set_scene(my_scene)

while true:
  // perform app work, like dispatching events
  ui::MainLoop::main()
  // redraw any widgets that marked themselves dirty
  ui::MainLoop::redraw()
  // read input (blocking read)
  ui::MainLoop::read_input()
```

The main loop is responsible for redrawing widgets, listening for and
dispatching input events, and other core work that happens on each iteration of
the app.

see [the main loop code](src/rmkit/ui/main_loop.cpy) for more details

### Scenes & Overlays

An app is organized into scenes and the main loop displays them. A scene can be
the main scene of the app or it can be an overlay (like a modal dialog). When a
scene is the main scene or overlay, when the main loop's redraw() is called,
all the widgets from the scene are able to redraw themselves.

If you are building a mine sweeper app, you might have a few scenes:

* scene 1: The intro screen with game options
* scene 2: The game screen with a minefield and controls
* scene 3: The end screen: win / lose status and button to restart

Simple apps will usually consist of one or two scenes and a few overlays, while
a complex app may have more.

### Widgets

Every app consists of Widgets that are absolutely positioned in a scene.
Widgets are responsible for drawing themselves in their redraw() function and
have event callbacks for common touch events.

Widgets can be simple or compound - a simple widget might be a Button or
Textbox, while a compound widget may be a widget that contains several
sub-widgets, like a modal dialog or toolbar. During a compound widget's redraw
method, the widget will often have explicit calls to redraw it's children.

### Layouts

In the Widget section, it's mentioned that widgets are absolutely positioned -
meaning that they are placed on screen via their X,Y coordinates. This works
fine for simple apps, but what if you want to create an app with a complex
layout?  That's where layouts help: a layout helps position widgets on the
screen using three main functions: pack\_start, pack\_center and pack\_end.

For example, if you want to position some text on the bottom of the screen,
you may do:

```cpp
fb := framebuffer::get()
w, h := fb->get_display_size()
h_layout := ui::HorizontalLayout(0, 0, w, h)
h_layout.pack_end(new ui::Text(0, 0, 200, 50, "Hello World"))
```

Layouts can be nested, but be careful: the layout immediately changes
a widget's posiion when the pack\* functions are called. So if you nest
layouts, the ordering of operations should be that the nested layout
is packed into its parent before any children are added to the nested
layout, like so:

```cpp
parent_layout = ...
child_layout = ...
// child_layout->pack_start(...) // wrong ordering
parent_layout->pack_start(child_layout)
child_layout->pack_start(..) // correct ordering
```

### Framebuffer

The screen of the remarkable is an eink screen that is capable of displaying
shades of gray. In rmkit the framebuffer is a class that takes care of drawing
to and refreshing the display. It provides API calls for rendering pixels,
lines, squares, circles and text. In general, Widgets talk to the framebuffer
for drawing themselves to the screen.

A simple button might render itself like so:

```cpp
class MyButton : public Widget:
  public:
  string text

  MyButton(int x, y, w, h, string text): string(text), Widget(x, y, w, h):
    pass

  void redraw():
    // draw a filled white rectangle
    self.fb->draw_rectangle(x, y, w, h, WHITE, true /* filled */)
    // draw text
    self.fb->draw_text(x, y, self,text, font_size)
    // draw an outline
    self.fb->draw_rectangle(x, y, w, h, BLACK, false)
```

This is a pretty simple button, though - all it does is render a rectangle and
some text. Take a look at the [button's
implementation](src/rmkit/ui/button.cpy) to see how buttons are implemented


### Handling User Input

The remarkable has two motion devices: the touch screen and the stylus input as
well as a single button device. rmkit opens these devices through /dev/input/,
which uses the lib_event framework in the linux kernel. rmkit normalizes
the values from the events into more coherent objects and forwards them to
any widgets that are effected by them.

There's two ways of handling user input: either by implementing a one of the
built-in event handlers (f.e. on_mouse_click) or by intercepting the event
before it is dispatched to any widgets.

