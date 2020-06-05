function kill_remote_sketchy() {
  ssh root@${HOST} killall sketchy 2> /dev/null
}

function cleanup() {
  kill_remote_sketchy
  echo "FINISHED"
  exit 0
}

trap cleanup EXIT 
trap cleanup SIGINT 

kill_remote_sketchy
echo "RUNNING SKETCHY"
ssh root@${HOST} ./sketchy
