function kill_remote_launcher() {
  ssh root@${HOST} killall launcher 2> /dev/null
}

function cleanup() {
  kill_remote_launcher
  echo "FINISHED"
  exit 0
}

trap cleanup EXIT 
trap cleanup SIGINT 

kill_remote_launcher
echo "RUNNING LAUNCHER"
ssh root@${HOST} ./launcher
