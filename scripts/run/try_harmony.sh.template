# run with wget -O- https://raw.githubusercontent.com/rmkit-dev/rmkit/master/scripts/run/try_harmony.sh -q | bash -

function cleanup() {
  killall harmony
  systemctl restart xochitl
  echo "FINISHED"
  exit 0
}

trap cleanup EXIT
trap cleanup SIGINT

killall harmony
rm rmkit-release.zip
wget https://build.rmkit.dev/stable/latest/release.zip -O rmkit-release.zip
yes | unzip rmkit-release.zip
./apps/remux.exe
