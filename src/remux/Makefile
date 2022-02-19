include ../actions.make

EXE=remux
FILES=launcher.cpy

# disable parameter warning from GCC 6 -> 7
CPP_FLAGS+=-Wno-psabi
install:
	make copy
	make install_service

install_service:
	scp ./remux.service root@${HOST}:/etc/systemd/system/

start_service:
	ssh root@${HOST} systemctl enable --now remux
