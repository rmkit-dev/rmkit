genie is a config based gesture launcher. the point of genie is to setup your
own gestures and configure them to do what you want. The config file is located
at `/opt/etc/genie.conf`.

## config file format

the config file is a list of gestures separated by one or more blanklines. all
options must be specified in lowercase.

```
gesture=swipe
direction=up
command=echo "swipe up on left side of screen"
fingers=1
zone=0 0 0.1 1

gesture=tap
command=echo "tap on right side of screen"
fingers=1
zone=0.9 0 1 1
```

common config items:

* **gesture** - type of gesture, can be **swipe** or **tap**
* **command** - command to run when gesture is activated
* **fingers** - number of fingers to use in the swipe or tap
* **zone** - rectangle where the gesture must start in. specified as space separated list of floats from 0 to 1. 0, 0 is the top left corner, the default is 0 0 1 1

swipe specific config:

* **direction** direction of swipe, can be **up**, **down**, **left** or **right**
* **distance** activation distance for swipe in pixels. should be 100 - 800 or so

tap specific config:

* **duration** - minimum length of time before activating command. 0.5 means hold down for 0.5 seconds before activation.
