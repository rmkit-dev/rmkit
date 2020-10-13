#!/usr/bin/env bash
default: build
include src/common.make

# Use `make <app>` to build any app individually
APPS=$(shell ls src/ | grep -v build | grep -Ev ".make|shared|vendor|cpp")
LINT_APPS=$(foreach app, $(APPS), lint_$(app))
CLEAN_APPS=$(foreach app, $(APPS), clean_$(app))
INSTALL_APPS=$(foreach app, $(APPS), install_$(app))
RESIM_APPS=$(foreach app, $(APPS), resim_$(app))
RUN_APPS=$(foreach app, $(APPS), run_$(app))
DOCKER_APPS=$(foreach app, $(APPS), $(app)_docker)

SHA=$(shell git rev-parse --short HEAD)

$(APPS): %: rmkit.h
	cd src/${@} && make

$(RESIM_APPS): %: rmkit.h
	cd src/$(@:resim_%=%) && make resim

$(INSTALL_APPS): %: rmkit.h
	cd src/$(@:install_%=%) && make install

$(RUN_APPS): %: rmkit.h
	cd src/$(@:run_%=%) && make run

$(DOCKER_APPS): %:
	docker build --tag rmkit:latest .
	bash scripts/build/docker_build.sh $(@:%_docker=%)

$(CLEAN_APPS): %:
	cd src/$(@:clean_%=%) && make clean

$(LINT_APPS): %:
	cd src/$(@:lint_%=%) && make lint

build: $(APPS)
	echo "BUILT ALL APPS"

dest_dir:
	ssh root@${HOST} mkdir -p /home/root/${DEST}/ > /dev/null

install: rmkit.h dest_dir
	$(foreach app, $(APPS), cd src/${app} && make copy; cd ${ROOT}; )

clean:
	$(foreach app, $(APPS), cd src/${app} && make clean; cd ${ROOT}; )

default: build

lint: $(LINT_APPS)

dev: export ARCH=dev
dev: default

arm: export ARCH=arm
arm: default

x86: export ARCH=x86
x86: default

rmkit.h:
	mkdir src/build > /dev/null || true
	cd src/rmkit && make

docker:
	docker build --tag rmkit:latest .
	bash scripts/build/docker_release.sh

docker_install: docker
	echo "Not implemented yet"

ZIP_DEST="apps"
bundle: $(APPS)
	#BUILDING V: ${VERSION} ARCH: ${ARCH}
	mkdir -p ${BUILD_DIR}/.${ZIP_DEST} 2>/dev/null || true
	cp ${BUILD_DIR}/* ${BUILD_DIR}/.${ZIP_DEST}/
	sha256sum ${BUILD_DIR}/* > ${BUILD_DIR}/sha256sum.txt
	ls -la ${BUILD_DIR} > ${BUILD_DIR}/ls.txt
	cp ${BUILD_DIR}/*.txt ${BUILD_DIR}/.${ZIP_DEST}/
	cp src/remux/remux.service ${BUILD_DIR}
	cp src/remux/remux.service ${BUILD_DIR}/.${ZIP_DEST}/

	mv ${BUILD_DIR}/.${ZIP_DEST} ${BUILD_DIR}/${ZIP_DEST}
	cd ${BUILD_DIR}; zip release.zip -r ${ZIP_DEST}/; cd ..
	rm -fr ${BUILD_DIR}/${ZIP_DEST}/

view:
	python scripts/dev/viewer.py

NATURAL_DOCS?=mono ~/tonka/apps/Natural\ Docs/NaturalDocs.exe
natural_docs:
	bash scripts/docs/augment_docs.sh
	${NATURAL_DOCS} -p docs/config/ -i src/ -o html docs/html/ -xi src/cpp/ -xi src/build
	cp docs/html/* ../rmkitDocs/ -R
watch_docs:
	find ./src/ ./config/ | while true; do entr -d make natural_docs; sleep 0.5; done


.PHONY:build view install
