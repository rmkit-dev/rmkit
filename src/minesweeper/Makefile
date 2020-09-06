EXE=mines.exe
FILES=main.cpy

include ../actions.make
run:
	ssh root@10.11.99.1 killall mines.exe || true
	ssh root@10.11.99.1 systemctl stop xochitl
	ssh root@10.11.99.1 ./apps/mines.exe
	ssh root@10.11.99.1 killall mines.exe || true

_install:
	make copy
	make _install_draft
ASSET_DIR=assets/
