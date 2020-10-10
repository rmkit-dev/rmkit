include ../actions.make

EXE=remux
FILES=launcher.cpy
install:
	make copy
	make install_service

install_service:
	scp ./remux.service root@${HOST}:/etc/systemd/system/

start_service:
	ssh root@${HOST} systemctl enable --now remux
