import glib
import gtk
import threading
import sys
import time

if __name__ == "__main__":
    WIN = gtk.Window()
    IMG = gtk.Image()

    WIN.add(IMG)
    WIN.connect("destroy", gtk.main_quit)

    WIN.show_all()

    def update_image():
        try:
            img = gtk.gdk.pixbuf_new_from_file("./fb.png")
        except:
            return True

        width, height = WIN.get_size()
        i_width = img.get_width()
        scalar = i_width / float(width)
        img = img.scale_simple(width, int(height/scalar), gtk.gdk.INTERP_BILINEAR)

        IMG.set_from_pixbuf(img) 
        IMG.queue_draw()
        return True

    update_image()

    glib.timeout_add(100, update_image)

    try:
        gtk.main()
    except:
        sys.exit(0)

