include ../actions.make

EXE=remux
FILES=launcher.cpy

# disable parameter warning from GCC 6 -> 7
CPP_FLAGS+=-Wno-psabi
install:
	make copy
	make install_api
	make install_service

install_service:
	scp ./remux.service root@${HOST}:/etc/systemd/system/

install_api:
	scp ./remux-api root@${HOST}:${DEST}/

start_service:
	ssh root@${HOST} systemctl enable --now remux
