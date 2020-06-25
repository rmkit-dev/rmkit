# About

This repo contains code for drawing to the remarkable framebuffer.

## Status

Approaching first release. Stay tuned!

Implemented:

* Framebuffer abstractions
* Text Rendering
* Drawing primitives: line, rect, circle
* Canvas w. Procedural brushes
* Widgets and Immediate mode UI: Buttons, Dropdown, Toolbar, etc

## Development

### Install Requirements

* install okp: `sudo pip install okp`
* install arm toolchain
  * on ubuntu: `sudo apt install gcc-arm-linux-gnueabihf`
* install freetype library:
  * on ubuntu: `sudo apt install libfreetype6-dev`

### Compiling

#### Linux

with framebuffer:

* compile with real framebuffer: `make harmony_x86`
* switch to virtual terminal and run `./build/bin/harmony`

with image framebuffer:

* compile with fake framebuffer: `make harmony_dev`
* run harmony
* run local viewer: `make view`

#### Remarkable

* checkout freetype into repo: `git submodule init`
* compile freetype library: `make freetype_arm`
* compile harmony for remarkable: `make harmony_arm`
* test on remarkable: `make test_arm` - assumes that the remarkable is plugged in on USB
* test on remarkable over wifi: `HOST=192.168.1.10 make test_arm`


#### acknowledgements

* [fontawesome](https://fontawesome.com)
* [harmony](https://github.com/mrdoob/harmony)
* [libremarkable](https://github.com/canselcik/libremarkable)
