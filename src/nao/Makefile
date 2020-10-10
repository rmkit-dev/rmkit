default: copy

include ../actions.make

EXE=nao.sh
APP=nao

DRAFT=nao.draft


copy:
	cp ${EXE} ../build/
	chmod +x ../build/${EXE}

install:
	make copy

	ssh root@${HOST} mkdir -p ${DEST} 2>/dev/null
	scp -C ../build/${EXE} root@${HOST}:${DEST}/${APP}
