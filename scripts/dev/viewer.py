import sys

try:
    import gi
except ModuleNotFoundError:
    print("Please install PyGObject")
    sys.exit()

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk as gtk
from gi.repository import Gdk as gdk
from gi.repository import GObject
from gi.repository.GdkPixbuf import Pixbuf, InterpType



import threading
import os
import sys
import time

if __name__ == "__main__":
    GObject.threads_init()

    WIN = gtk.Window()
    IMG = gtk.Image()

    WIN.add(IMG)
    WIN.connect("destroy", gtk.main_quit)
    WIN.set_size_request(1404,1872)

    WIN.show_all()

    _last_mod = None
    def update_image():
        global _last_mod
        statbuf = os.stat("./fb.png")
        mod = statbuf.st_mtime
        img = None
        if statbuf.st_size == 0:
            return True

        if mod != _last_mod:
            try:
                img = Pixbuf.new_from_file("./fb.png")
            except Exception as e:
                print(e)
                return True

        _last_mod = mod
        if not img:
            return True

        width, height = WIN.get_size()
        i_height = img.get_height()
        scalar = i_height / float(height)
        img = img.scale_simple(int(height/scalar), height, InterpType.BILINEAR)

        IMG.set_from_pixbuf(img)
        IMG.queue_draw()
        return True

    update_image()

    GObject.timeout_add(10, update_image)

    try:
        gtk.main()
    except:
        sys.exit(0)

