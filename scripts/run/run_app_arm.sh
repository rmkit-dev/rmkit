APP=${1}
BASE_DIR=harmony

function kill_remote_app() {
  ssh root@${HOST} killall ${APP} 2> /dev/null
}

function cleanup() {
  kill_remote_app
  echo "FINISHED"
  exit 0
}

trap cleanup EXIT
trap cleanup SIGINT

TARGET=arm make ${APP}
scp src/build/${APP} root@${HOST}:${BASE_DIR}/${APP}
kill_remote_app
echo "RUNNING ${APP}"
ssh root@${HOST} ${BASE_DIR}/${APP}
