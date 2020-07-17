# About

rmHarmony is a drawing app for the remarkable tablet

![](https://i.imgur.com/KJlWdAAl.png)

## Status

Approaching first release. Stay tuned!

### Implemented

* Tilt + pressure sensitive brushes
* Procedural brushes
* Drawing in 3 colors: white, gray & black
* Saving + loading pngs

## Installation

### Try it out

run `wget -O- https://raw.githubusercontent.com/raisjn/rmHarmony/master/scripts/try_harmony.sh -q | sh -` on the remarkable via SSH

To exit harmony, press the power button to bring up the exit dialog.

### Install

run `wget -O- https://raw.githubusercontent.com/raisjn/rmHarmony/master/scripts/install_harmony.sh -q | sh -` to install the harmony launcher until the next time the device is updated


to launch harmony, hold the center button for 2+ seconds. To exit harmony,
press the power button to bring up the exit dialog.

### Manual Installation

* download or build the binaries for harmony (see docs/BUILDING.md)
* copy `harmony` to /home/root/harmony/harmony on the remarkable
* launch `/home/root/harmony/harmony` through SSH

## Compilation

see docs/BUILDING.md

## License

MIT except where noted otherwise

## acknowledgements

* [fontawesome](https://fontawesome.com) for their icons
* [harmony](https://github.com/mrdoob/harmony) for the idea of procedural brushes
* [libremarkable](https://github.com/canselcik/libremarkable) for reverse engineering remarkable IO
* [stb](https://github.com/nothings/stb) for image resizing and font rendering libraries
