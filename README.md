# About

This repo contains code for drawing to the remarkable framebuffer.


## Status

Almost nothing is implemented yet. But future plans is to create helper classes for the following:

* Framebuffer abstraction
* Drawing primitives: line, rect, circle, etc
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

* compile with real framebuffer: `make sketchy_x86`
* switch to virtual terminal and run `./sketchy`

with image framebuffer:

* compile with fake framebuffer: `make sketchy_dev`
* run sketchy
* run local viewer: `make view`



#### Remarkable

* checkout freetype into repo: `git submodule init`
* compile freetype library: `make freetype_arm`
* compile sketchy for remarkable: `make sketchy_arm`
* test on remarkable: `make test_arm` - assumes that the remarkable is plugged in on USB
* test on remarkable over wifi: `HOST=192.168.1.10 make test_arm`
