# reMux

reMux is an app switcher for remarkable. once its running, hold the middle
button down for several seconds until the reMux launcher appears

there are a couple ways to configure the list of apps that appear in reMux:

1. via code configuration - edit config.launcher.cpy
2. add a binary to the remux watch dir on the remarkable
3. using draft remarkable configuration files


## Building

run `make remux` from the root dir of rmkit to build it. then run `make
install_remux` to copy remux to the remarkable. Run `make run_remux` to run remux.

Finally, if you want to make the installation permanent, change into the
`src/remux` directory and run `make install_service` followed by `make
start_service`

