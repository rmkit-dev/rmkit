EXE=mines.exe
FILES=main.cpy

include ../actions.make
run:
	ssh root@10.11.99.1 killall mines.exe || true
	ssh root@10.11.99.1 systemctl stop xochitl
	ssh root@10.11.99.1 ./harmony/mines.exe
	ssh root@10.11.99.1 killall mines.exe || true

reboot:
	ssh root@10.11.99.1 systemctl start xochitl
