# reMux

reMux is an app switcher for remarkable. once its running, hold the middle
button down for several seconds until the reMux launcher appears

there are a couple ways to configure the list of apps that appear in reMux:

1. via code configuration - edit config.launcher.cpy
2. add a binary to the remux watch dir on the remarkable
3. using draft remarkable configuration files

## Launching

The built in ways of launching remux are:

* holding home button
* swiping up on either side of the display

if you want to adjust them, they can be changed - see the config section below.

## Known issues

* remux restarts xochitl at first launch, it is not crashing
* remux does not show itself after an app exits, you must swipe to show it
* after dismissing remux UI, you need to tap the touch screen before swiping again to show remux
* if the UI is hard to bring up, try tapping with finger first and then launching it

## Building

run `make remux` from the root dir of rmkit to build it. then run `make
install_remux` to copy remux to the remarkable. Run `make run_remux` to run remux.

Finally, if you want to make the installation permanent, change into the
`src/remux` directory and run `make install_service` followed by `make
start_service`

## Changelog

### Disable Power Management (0.1.8)

* added `manage_power=` boolean option to configuration. setting to `false` or `no` tells remux to not enter suspend mode automatically - this lets you use xochitl solely for power management. useful if remux is messing up drawing your suspend screen

### Config (0.1.7)

As of remux 0.1.7, remux supports configuration kept in `/home/root/.config/remux/remux.conf`. The configuration is kept as key=value lines. As of right now, the two main config options are `launch_gesture` and `back_gesture`. They can be used to configure the gestures in remux. The format is the same as genie, except semi-colons (`;`) are used to separate directives instead of newlines.

For example, the below will show remux when three fingers are tapped and switch
to last app on a four finger tap.

```
launch_gesture=gesture=tap;fingers=3
back_gesture=gesture=tap;fingers=4
```

You can repeat a key in order to setup multiple gestures for the same action, like so:

```
launch_gesture=gesture=tap;fingers=3
launch_gesture=gesture=tap;fingers=4
```

### API (0.1.6)

remux opens `/run/remux.api` as a FIFO and listens for incoming commands. The supported commands are `show`, `hide`, and `back`.

Using the API and [genie](../genie), one can setup their own gestures for remux. To disable the built in gestures in remux, set `launch_gesture=`, then verify that no gestures were created in remux's output.
