function kill_remote_harmony() {
  ssh root@${HOST} killall harmony.exe 2> /dev/null
}

function cleanup() {
  kill_remote_harmony
  echo "FINISHED"
  exit 0
}

trap cleanup EXIT
trap cleanup SIGINT

TARGET=arm make harmony
scp src/build/harmony.exe root@${HOST}:harmony/harmony.exe
kill_remote_harmony
echo "RUNNING HARMONY"
ssh root@${HOST} ./harmony/harmony.exe
