ROOT=${PWD}
ARCH=kobo
KOBO_ROOT=${ROOT}/${ARCH}

build_dirs() {
  echo "BUILDING KOBO DIR STRUCTURE"
  mkdir -p kobo/mnt/onboard/.adds/opt
  pushd kobo
  ln -s mnt/onboard/.adds/opt opt
  mkdir -p opt/bin/apps
  popd
}


copy_files() {
  echo "COPYING FILES TO KOBO ROOT"
  pushd artifacts/${ARCH}
  cp -v animation_demo input_demo mines remux rpncalc wordlet ${KOBO_ROOT}/mnt/onboard/.adds/opt/bin/apps/
  popd
  pushd ./kobo/opt/bin/apps/
  arm-linux-gnueabihf-strip *
  popd
}

tar_files() {
  echo "TARRING KOBO ROOT"
  pushd kobo
  tar -cvzf ${ROOT}/artifacts/${ARCH}/KoboRoot.tgz .
  popd
}

make_remux_sh() {
  cat > ${KOBO_ROOT}/opt/bin/remux.sh << REMUX_SH
#!/bin/bash
while true; do
  sleep 1;
  remux;
done
REMUX_SH
  chmod +x ${KOBO_ROOT}/opt/bin/remux.sh
}

build_dirs
make_remux_sh
copy_files
tar_files
