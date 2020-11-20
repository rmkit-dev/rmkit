## Hello World

The simplest app in rmkit would be a hello world. But even the
hello world app has a bit of code! 

To make your first app, create a new directory in `src/` with the name
`hello_world` and add two files: `Makefile` and `main.cpy`. From the root of
the repository, you can now run `make hello_world` (or whatever you named your
directory) and a binary will be compiled and moved to`src/build/`

```
// Makefile
include ../actions.make

EXE=hello_world
FILES=main.cpy

// main.cpy
#include "../build/rmkit.h"

using namespace rmkit
using namespace std

int main()
  // get the framebuffer
  fb := framebuffer::get()
  // clear the framebuffer using a white rect
  fb->clear_screen()

  // make a new scene
  scene := ui::make_scene()
  // set the scene
  ui::MainLoop::set_scene(scene)

  // create a new text widget with text "Hello World"
  // its absolutely positioned at 0, 0 with width 200 and height 50
  text := new ui::Text(0, 0, 200, 50, "Hello World")

  // add the text widget to our scene
  scene->add(text)

  while true:
    // main() dispatches user input handlers, runs tasks in the task queue and so on
    ui::MainLoop::main()

    // goes through all widgets that were marked as dirty since
    // the previous loop iteration and call their redraw() method
    ui::MainLoop::redraw()
    // wait for user input. the input will be handled by the next
    // iteration of this loop
    ui::MainLoop::read_input()
```

The above app does a few things:

1. it clears the screen by drawing to the framebuffer
2. it displays the words "Hello World" in the top left corner
3. it runs the main loop of the program

## Concepts

In hello world, we dealt with several concepts, including the **framebuffer**,
**widgets**, **scenes** and the **main loop**. 

The framebuffer holds what is being drawn to screen in rmkit. You can
use the framebuffer to draw to the display with simple primitives like
lines, rectangles, text and bitmaps. 

But doing so gets a bit tedious: who wants to write an application using only
drawing primitives? This is where **widgets** come in. Typical widgets are
things like text boxes and buttons, but complex UI elements like modals and
dialogs are also expressed as widgets.

In the above code, notice that the text was added to a **scene**. Scenes are
essentially collections of widgets. The main loop is told which scene is the
current scene and uses that to draw to screen as well as handle input events.

Finally, the **main loop** is how the program is actually run. The main loop
is run in a while statement and takes care of reading input, redrawing the screen
and other tasks related to the UI.
