EXE=genie
FILES=main.cpy
#ASSET_DIR=assets/

include ../actions.make

install:
	make copy
	make install_config

install_config:
	scp ./example.conf root@${HOST}:/opt/etc/genie.example.conf
