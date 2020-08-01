#!/usr/bin/env bash
default: build
include src/common.make

# Use `make <app>` to build any app individually
APPS=harmony remux demo
CLEAN_APPS=$(foreach app, $(APPS), clean_$(app))
INSTALL_APPS=$(foreach app, $(APPS), install_$(app))

$(APPS): %: rmkit.h
	echo $(INSTALL_APPS)
	cd src/${@} && make

$(INSTALL_APPS): %: rmkit.h
	cd src/$(@:install_%=%) && make install

$(CLEAN_APPS): %:
	cd src/$(@:clean_%=%) && make clean

build: rmkit.h
	$(foreach app, $(APPS), cd src/${app} && make; cd ${ROOT}; )

install: rmkit.h
	$(foreach app, $(APPS), cd src/${app} && make copy; cd ${ROOT}; )

clean:
	$(foreach app, $(APPS), cd src/${app} && make clean; cd ${ROOT}; )

default: build

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
	docker build --tag rmharmony:latest .
	bash scripts/docker_release.sh

docker_install: docker
	echo "Not implemented yet"

bundle: harmony remux
	#BUILDING V: ${VERSION} ARCH: ${ARCH}
	mkdir -p ${BUILD_DIR}/harmony 2>/dev/null || true
	# TODO: use ${APPS} here
	cp ${BUILD_DIR}/harmony.exe ${BUILD_DIR}/remux.exe ${BUILD_DIR}/harmony/
	cp contrib/remux.service ${BUILD_DIR}/harmony/

	cd ${BUILD_DIR}; zip release-${VERSION}.zip -r harmony/
	cat scripts/install_harmony.sh.template | sed 's/VERSION/${VERSION}/g' > scripts/install_harmony.sh
	cat scripts/try_harmony.sh.template | sed 's/VERSION/${VERSION}/g' > scripts/try_harmony.sh

view:
	python scripts/viewer.py

NATURAL_DOCS?=mono ~/tonka/apps/Natural\ Docs/NaturalDocs.exe
natural_docs:
	${NATURAL_DOCS} -p config/ -i src/ -o html docs/html/ -xi src/cpp/ -xi src/build

.PHONY:build view install
