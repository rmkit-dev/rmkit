EXE=genie
FILES=main.cpy
#ASSET_DIR=assets/

include ../actions.make

install:
	make copy
	make install_config
	make install_service

install_config:
	scp ./example.conf root@${HOST}:/opt/etc/genie.example.conf

install_service:
	scp ./genie.service root@${HOST}:/etc/systemd/system/

start_service:
	ssh root@${HOST} systemctl daemon-reload
	ssh root@${HOST} systemctl enable --now genie
