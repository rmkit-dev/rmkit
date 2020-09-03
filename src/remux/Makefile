include ../actions.make

EXE=remux.exe
FILES=launcher.cpy
_install:
	make copy
	make install_service

install_service:
	scp ./remux.service root@${HOST}:/etc/systemd/system/

start_service:
	ssh root@${HOST} systemctl enable --now remux
