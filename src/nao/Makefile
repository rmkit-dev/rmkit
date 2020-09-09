default: copy

include ../actions.make

EXE=nao.sh
APP=nao


copy:
	cp ${EXE} ../build/
	chmod +x ../build/${EXE}

	ssh root@${HOST} mkdir -p ${DEST} 2>/dev/null
	scp -C ../build/${EXE} root@${HOST}:${DEST}/${APP}

_install:
	make copy

