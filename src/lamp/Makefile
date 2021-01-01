EXE=lamp
FILES=main.cpy
#ASSET_DIR=assets/

include ../actions.make

install:
	make copy
	make install_example

install_example:
	scp ./example.in root@${HOST}:/opt/etc/lamp.input
