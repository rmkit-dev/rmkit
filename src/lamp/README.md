lamp is a simple program for injecting touch and stylus events. it can be used
to programatically draw shapes or insert swipe gestures passed on stdin.


## Example commands

an example lamp program might look like:

```
pen rectangle 250 250 1300 1300
pen line 250 250 1300 1300
pen line 250 1300 1300 250
pen circle 600 600 500 50
pen circle 900 900 200 50
pen circle 1100 1100 100 50
pen circle 1200 1200 50 50
```

and used like `lamp < example.in`

## Commands

* pen rectangle x1 y1 x2 y2
* pen line x1 y2 x2 y2
* pen circle x1 y1 r1 n2 (the n2 does nothing yet)
* pen down x1 y1
* pen move x1 y1
* pen up
* finger down x1 y1
* finger move x1 y1
* finger up
* swipe up
* swipe down
* swipe left
* swipe right
