ROOT=${PWD}
TARGET=kobo
KOBO_ROOT=${ROOT}/${TARGET}
PLUGIN_DIR=${KOBO_ROOT}/mnt/onboard/.adds/rmkit
CROSS_TC=${CROSS_TC:-arm-linux-gnueabihf}

build_dirs() {
  echo "BUILDING KOBO DIR STRUCTURE"
  cd ${ROOT}
  mkdir -p kobo/mnt/onboard/.adds/rmkit
  pushd ${KOBO_ROOT}
  ln -s /mnt/onboard/.adds/rmkit ./opt
  mkdir -p ${PLUGIN_DIR}/bin/apps
  popd
}


copy_files() {
  echo "COPYING FILES TO KOBO ROOT"
  pushd artifacts/${TARGET}
  cp -v animation_demo input_demo dithering_demo dumbskull eclear harmony mines remux rpncalc wordlet ${PLUGIN_DIR}/bin/apps/
  cp -v genie simple ${PLUGIN_DIR}/bin/

  popd
  pushd ${PLUGIN_DIR}/bin/apps/
  ${CROSS_TC}-strip *
  popd
}

tar_files() {
  echo "TARRING KOBO ROOT"
  pushd kobo
  tar -cvzf ${ROOT}/artifacts/${TARGET}/KoboRoot.tgz .
  popd
}

make_remux_sh() {
  cat > ${PLUGIN_DIR}/bin/remux.sh << REMUX_SH
#!/bin/sh
while true; do
  sleep 1;
  /opt/bin/apps/remux;
done
REMUX_SH
  chmod +x ${PLUGIN_DIR}/bin/remux.sh
}

make_nickelmenu_entry() {
  pushd ${KOBO_ROOT}
  mkdir -p ./mnt/onboard/.adds/nm/
  cat > ./mnt/onboard/.adds/nm/remux << REMUX_NM
menu_item :main :Toggle Remux :cmd_spawn :/bin/sh /usr/local/rmkit/toggle_remux.sh
REMUX_NM

  mkdir -p ./usr/local/rmkit
  cat > ./usr/local/rmkit/toggle_remux.sh << ENABLE_REMUX_SH
#!/bin/sh
echo "STARTING REMUX" > /tmp/remux.log
pgrep remux
if ! pgrep /opt/bin/apps/remux; then
  /opt/bin/apps/remux &
  sleep 1 && echo show > /run/remux.api
else
  killall remux
fi
ENABLE_REMUX_SH
  chmod +x ./usr/local/rmkit/toggle_remux.sh
  popd
}

make_udev_rules() {
  pushd ${KOBO_ROOT}
  mkdir -p ./etc/udev/rules.d/
  mkdir -p ./usr/local/rmkit/
  cat > ./etc/udev/rules.d/99-rmkit.rules << RMKIT_RULES
# $Id: 99-rmkit.rules 11379 2015-01-10 23:58:00Z NiLuJe $
# Runs early at boot... (onboard *might* be mounted at that point)
KERNEL=="loop0", RUN+="/usr/local/rmkit/startup.sh"
RMKIT_RULES
  chmod 644 ./etc/udev/rules.d/99-rmkit.rules

  cat > ./usr/local/rmkit/start_remux.sh << STARTUP_SH
#!/bin/sh
if [[ -f /mnt/onboard/.adds/rmkit/enable_remux ]]; then
  echo "ENABLING REMUX" > /tmp/rmkit.log
  sh /opt/bin/remux.sh &
else
  echo "NOT ENABLING REMUX" > /tmp/rmkit.log
fi

if [[ -f /usr/bin/usbnet-toggle ]]; then
  echo "#!/bin/sh" > /opt/bin/apps/usbnet.sh
  echo "/usr/bin/usbnet-toggle" >> /opt/bin/apps/usbnet.sh
  echo "echo back > /run/remux.api" >> /opt/bin/apps/usbnet.sh
fi
STARTUP_SH
  chmod +x ./usr/local/rmkit/start_remux.sh

  cat > ./usr/local/rmkit/startup.sh << STARTUP_SH
#!/bin/sh

# Start by renicing ourselves to a neutral value, to avoid any mishap...
renice 0 -p $$

# Launch in the background, with a clean env, after a setsid call to make very very sure udev won't kill us ;).
env -i -- setsid /usr/local/rmkit/start_remux.sh &

# Done :)
exit 0
STARTUP_SH
  chmod +x ./usr/local/rmkit/startup.sh

  echo "Delete this file to disable remux" > ${PLUGIN_DIR}/enable_remux
  popd
}


build_dirs
make_remux_sh
# make_nickelmenu_entry
make_udev_rules
copy_files
tar_files
