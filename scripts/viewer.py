import glib
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gtk as gtk
from gi.repository import Gdk as gdk
from gi.repository.GdkPixbuf import Pixbuf, InterpType



import threading
import sys
import time

if __name__ == "__main__":
    glib.threads_init()

    WIN = gtk.Window()
    IMG = gtk.Image()

    WIN.add(IMG)
    WIN.connect("destroy", gtk.main_quit)
    WIN.set_size_request(1404,1872)

    WIN.show_all()

    def update_image():
        try:
            img = Pixbuf.new_from_file("./fb.png")
        except Exception, e:
            return True

        width, height = WIN.get_size()
        i_height = img.get_height()
        scalar = i_height / float(height)
        img = img.scale_simple(int(height/scalar), height, InterpType.BILINEAR)

        IMG.set_from_pixbuf(img)
        IMG.queue_draw()
        return True

    update_image()

    glib.timeout_add(100, update_image)

    try:
        gtk.main()
    except:
        sys.exit(0)

