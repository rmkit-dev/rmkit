# rmkit

This repo contains applications for the remarkable tablet. See the README in
each application's directory to learn more about it. The general purpose of
rmkit is to make it easy to write and deploy new apps to the remarkable tablet.

### [harmony](src/harmony)

A [low latency drawing app](https://rmkit.dev/apps/harmony) with procedural brushes

### [mines](src/minesweeper)

A [minesweeper game](https://rmkit.dev/apps/minesweeper) for spending time between meetings and classes

### [remux](src/remux)

An [app switcher](https://rmkit.dev/apps/remux) for switching between apps on the remarkable that is compatible
with [draft-remarkable](https://github.com/dixonary/draft-reMarkable/)
configuration files. Hold the middle button to bring it up.

### [simple app script](src/simple)

A [simple markup language](https://rmkit.dev/apps/sas) for building apps that
follow the philosophy of unix pipes.

### [rmkit](src/rmkit)

A batteries included library for building remarkable apps. [Read the documentation](https://rmkit-dev.github.io/rmkit)

### [demo](src/demo)

A small example app to demonstrate how to build apps with rmkit


## Installation

#### Try it out

run `wget -O- https://rmkit.dev/try.sh -q | sh -` on the remarkable via SSH

To exit harmony, press the power button to bring up the exit dialog.

#### Install

run `wget -O- https://rmkit.dev/install.sh -q | sh -` to install the remux app launcher until the next time the device is updated

to launch remux and switch between apps, hold the center button for 2+ seconds.

#### Uninstalling

to remove remux, run `systemctl disable remux --now`. All the applications are
installed into /home/root/apps, so you can delete that directory safely.

## Building from source

see [BUILDING.md](docs/BUILDING.md)

## Have ideas or want to code your own apps?

[There's a list of app ideas just waiting to be built!](docs/APP_IDEAS.md). If
you have ideas for new apps or features, please open an issue or get in touch
:-D
