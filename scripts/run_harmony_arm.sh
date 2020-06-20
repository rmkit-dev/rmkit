function kill_remote_harmony() {
  ssh root@${HOST} killall harmony 2> /dev/null
}

function cleanup() {
  kill_remote_harmony
  echo "FINISHED"
  exit 0
}

trap cleanup EXIT 
trap cleanup SIGINT 

kill_remote_harmony
echo "RUNNING SKETCHY"
ssh root@${HOST} ./harmony
