include ../actions.make

EXE=remux.exe
FILES=launcher.cpy

install_service:
	scp contrib/remux.service root@${HOST}:/etc/systemd/system/

start_service:
	ssh root@{HOST} systemctl enable --now remux
