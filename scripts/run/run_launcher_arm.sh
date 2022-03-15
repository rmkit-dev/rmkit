function kill_remote_remux() {
  ssh root@${HOST} killall remux.exe 2> /dev/null
}

function cleanup() {
  kill_remote_remux
  echo "FINISHED"
  exit 0
}

trap cleanup EXIT 
trap cleanup SIGINT 

TARGET=arm make remux
scp src/build/remux.exe root@${HOST}:harmony/remux.exe
kill_remote_remux
echo "RUNNING LAUNCHER"
ssh root@${HOST} ./harmony/remux.exe
