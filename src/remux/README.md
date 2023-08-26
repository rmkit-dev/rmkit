# remux

remux is an app switcher for the remarkable tablet. once its running, hold the
middle button down for several seconds until the remux launcher appears or
swipe up either side of the screen.

this is a small article about [how remux works](https://rmkit.dev/towards-multi-tasking/)

## Adding Apps

usually, most people install [toltec](toltec-dev.org) and the apps in toltec
all use draft format and are installed into /opt/etc/draft.

but if you are writing a new app or trying out an unpackaged app, there are a
few ways to configure the list of apps that appear in remux:

1. via code configuration - edit config.launcher.cpy and recompile remux
2. add a binary to `/home/root/apps` on the remarkable and make sure it is `chmod +x`
3. using draft remarkable configuration files. they are installed into /opt/etc/draft

## Launching

The built in ways of launching remux are:

* holding home button
* swiping up on either side of the display ([demo](https://imgur.com/a/rT94L8W))

if you want to adjust them, they can be changed - see the config section below.

## Known issues

* remux restarts xochitl at first launch, it is not crashing
* remux does not show itself after an app exits, you must activate it
* if you can not swipe in xochitl, try swiping with four fingers to reset xochitl's gesture engine

## Building

run `make remux` from the root dir of rmkit to build it. then run `make
install_remux` to copy remux to the remarkable. Run `make run_remux` to run remux.

Finally, if you want to make the installation permanent, change into the
`src/remux` directory and run `make install_service` followed by `make
start_service`

## Changelog

### Filter Palm Events (0.2.3)

* add `filter_palm_events` option to remux.conf to prevent spurious palm
  touches. Enable this is you have a custom gesture (like 3 or 4 finger) and
  keep accidentally launching remux.

### Custom dialog size (0.2.1)

* add `dialog_height` and `dialog_width` option to remux.conf for specifying
  the dialog width and heigght. Default is 600x800. The rM width is 1404,
  height is 1872.

### `launch` API (0.2.0)

* added ability to launch applications through the API: `echo 'launch xochitl' > /run/remux.api` will launch xochitl. the application name should be the name of the application as it shows up in the launch dialog

### Custom start application (0.1.9)

* added `start_app=` option to specify the app to launch. it can be blank or an
  app name as seen in the list of apps. if the app isn't found or its blank, no app
  will launch at startup and remux will require a gesture to be invoked.

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
