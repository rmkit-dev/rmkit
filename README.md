# rMkit

This repo contains applications for the remarkable tablet. See the README in
each application's directory to learn more.

### [harmony](src/harmony)

A low latency drawing app with procedural brushes.

### [mines](src/minesweeper)

A minesweeper game for time between meetings and classes

### [remux](src/remux)

An app switcher for switching between apps on the remarkable. Hold down the
middle button to bring it up.

### [rMkit](src/rmkit)

A batteries included library for building remarkable apps. [Read the documentation](https://rmkit-dev.github.io/rmkit)

### [demo](src/demo)

A small example app to demonstrate how to build apps with rMkit


## Installation

#### Try it out

run `wget -O- https://raw.githack.com/rmkit-dev/rmkit/master/scripts/run/try_harmony.sh -q | sh -` on the remarkable via SSH

To exit harmony, press the power button to bring up the exit dialog.

#### Install

run `wget -O- https://raw.githack.com/rmkit-dev/rmkit/master/scripts//run/install_harmony.sh -q | sh -` to install the remux app launcher until the next time the device is updated

to launch remux and switch between apps, hold the center button for 2+ seconds.

## Building from source

see [BUILDING.md](docs/BUILDING.md)

## Have ideas or want to code your own apps?

If you have ideas for new apps or features for the remarkable, please open an issue
or get in touch
